////
///  FakeStreamTextCellSizeCalculator.swift
//

@testable import Ello


class FakeStreamTextCellSizeCalculator: StreamTextCellSizeCalculator {

    override func processCells(_ cellItems: [StreamCellItem], withWidth: CGFloat, columnCount: Int, completion: @escaping Block) {
        for item in cellItems {
            item.calculatedCellHeights.oneColumn = ElloConfiguration.Size.calculatorHeight
            item.calculatedCellHeights.multiColumn = ElloConfiguration.Size.calculatorHeight
        }
        completion()
    }
}
