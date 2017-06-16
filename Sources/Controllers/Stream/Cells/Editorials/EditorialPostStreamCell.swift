////
///  EditorialPostStreamCell.swift
//

import SnapKit


class EditorialPostStreamCell: EditorialCell {
    fileprivate let pageControl = UIPageControl()
    fileprivate let scrollView = UIScrollView()
    fileprivate var postCells: [EditorialPostCell] = []
    fileprivate let titleLabel = StyledLabel(style: .giantBoldWhite)
    fileprivate let bg = UIView()
    fileprivate var autoscrollTimer: Timer?

    deinit {
        autoscrollTimer = nil
    }

    override func style() {
        super.style()

        bg.backgroundColor = .black
        titleLabel.numberOfLines = 0
        scrollView.isPagingEnabled = true
        scrollView.showsVerticalScrollIndicator = false
        scrollView.alwaysBounceVertical = false
        scrollView.scrollsToTop = false
        editorialContentView.isHidden = true
    }

    override func bindActions() {
        super.bindActions()
        pageControl.addTarget(self, action: #selector(pageTapped), for: .valueChanged)
        scrollView.delegate = self
    }

    override func updateConfig() {
        super.updateConfig()
        titleLabel.text = config.title

        let postStreamConfigs: [EditorialCell.Config] = config.postStreamConfigs ?? []
        updatePostViews(configs: postStreamConfigs)
        pageControl.numberOfPages = postStreamConfigs.count
        pageControl.isHidden = postStreamConfigs.count <= 1
        moveToPage(0)
        startAutoscroll()
    }

    override func arrange() {
        super.arrange()

        contentView.addSubview(bg)
        contentView.addSubview(scrollView)
        contentView.addSubview(pageControl)
        contentView.addSubview(titleLabel)

        bg.snp.makeConstraints { make in
            make.edges.equalTo(contentView).inset(Size.bgMargins)
        }
        scrollView.snp.makeConstraints { make in
            make.edges.equalTo(contentView)
        }
        pageControl.snp.makeConstraints { make in
            make.top.equalTo(contentView).inset(Size.pageControlMargin)
            make.centerX.equalTo(contentView)
        }

        titleLabel.snp.makeConstraints { make in
            make.top.equalTo(pageControl.snp.centerY).inset(Size.postStreamLabelMargin)
            make.leading.trailing.equalTo(contentView).inset(Size.defaultMargin)
        }
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        for view in postCells {
            view.snp.updateConstraints { make in
                make.size.equalTo(frame.size)
            }
        }
    }
}

extension EditorialPostStreamCell {
    @objc
    func pageTapped() {
        moveToPage(pageControl.currentPage)
        stopAutoscroll()
    }

    fileprivate func moveToPage(_ page: Int) {
        guard scrollView.frame.width > 0 else {
            scrollView.contentOffset = .zero
            return
        }

        let destPage = min(pageControl.numberOfPages - 1, max(0, page))
        let destX = scrollView.frame.width * CGFloat(destPage)
        scrollView.setContentOffset(CGPoint(x: destX, y: scrollView.contentOffset.y), animated: true)
    }

    fileprivate func startAutoscroll() {
        guard autoscrollTimer == nil else { return }

        autoscrollTimer = Timer.scheduledTimer(timeInterval: 5, target: self, selector: #selector(nextPage), userInfo: nil, repeats: true)
    }

    fileprivate func stopAutoscroll() {
        autoscrollTimer?.invalidate()
        autoscrollTimer = nil
    }

    @objc
    fileprivate func nextPage() {
        let nextPage = pageControl.currentPage + 1
        guard nextPage < pageControl.numberOfPages else { return }
        moveToPage(nextPage)
    }
}

extension EditorialPostStreamCell {
    func updatePostViews(configs: [EditorialCell.Config]) {
        for view in postCells {
            view.removeFromSuperview()
        }

        postCells = configs.map { config in
            let cell = EditorialPostCell()
            cell.config = config
            return cell
        }

        postCells.eachPair { prevView, view, isLast in
            scrollView.addSubview(view)
            view.snp.makeConstraints { make in
                make.top.bottom.equalTo(scrollView)
                make.size.equalTo(frame.size)

                if let prevView = prevView {
                    make.leading.equalTo(prevView.snp.trailing)
                }
                else {
                    make.leading.equalTo(scrollView)
                }

                if isLast {
                    make.trailing.equalTo(scrollView)
                }
            }

            view.contentView.snp.makeConstraints { make in
                make.edges.equalTo(view)
            }
        }
    }
}

extension EditorialPostStreamCell: EditorialCellResponder {
    @objc
    func editorialTapped(cell: EditorialCell) {
        guard
            let cell = cell as? EditorialPostCell,
            let index = postCells.index(of: cell)
        else { return }

        let responder: EditorialPostStreamResponder? = findResponder()
        responder?.editorialTapped(index: index, cell: self)
    }
}

extension EditorialPostStreamCell: UIScrollViewDelegate {
    func scrollViewWillBeginDragging(_ scrollView: UIScrollView) {
        stopAutoscroll()
    }

    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        guard scrollView.contentSize.width > 0 else { return }

        let pageFloat: CGFloat = round(map(
            scrollView.contentOffset.x,
            fromInterval: (0, scrollView.contentSize.width),
            toInterval: (0, CGFloat(postCells.count))))
        pageControl.currentPage = max(0, min(postCells.count - 1, Int(pageFloat)))
    }
}