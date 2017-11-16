////
///  UIImagePickerController.swift
//

import ImagePickerSheetController
import Photos
import MobileCoreServices
import Photos
import PromiseKit


enum ImagePickerSheetResult {
    case controller(UIImagePickerController)
    case images([PHAsset])
}

extension UIImagePickerController {
    static let elloPhotoLibraryPickerController: UIImagePickerController = createPhotoLibraryPickerController()
    static let elloCameraPickerController: UIImagePickerController = createCameraPickerController()

    static private func createImagePickerController() -> UIImagePickerController {
        let controller = UIImagePickerController()
        controller.mediaTypes = [kUTTypeImage as String]
        controller.allowsEditing = false
        controller.modalPresentationStyle = .fullScreen
        controller.navigationBar.tintColor = .greyA
        return controller
    }

    static private func createPhotoLibraryPickerController() -> UIImagePickerController {
        let controller = createImagePickerController()
        controller.sourceType = .photoLibrary
        return controller
    }

    static private func createCameraPickerController() -> UIImagePickerController {
        let controller = createImagePickerController()
        controller.sourceType = .camera
        return controller
    }

    static func alreadyDeterminedStatus() -> PHAuthorizationStatus? {
        let status = PHPhotoLibrary.authorizationStatus()
        return status == .notDetermined ? nil : status
    }

    @discardableResult
    static func requestStatus() -> Promise<PHAuthorizationStatus> {
        let (promise, resolve, _) = Promise<PHAuthorizationStatus>.pending()
        if let status = alreadyDeterminedStatus() {
            resolve(status)
        }
        else {
            PHPhotoLibrary.requestAuthorization { status in
                resolve(status)
            }
        }
        return promise
    }

    static func alertControllerForImagePicker(callback: @escaping (UIImagePickerController) -> Void) -> AlertViewController? {
        let alertController: AlertViewController

        if UIImagePickerController.isSourceTypeAvailable(.camera) {
            alertController = AlertViewController(message: InterfaceString.ImagePicker.ChooseSource)

            let cameraAction = AlertAction(title: InterfaceString.ImagePicker.Camera, style: .dark) { _ in
                Tracker.shared.imageAddedFromCamera()
                callback(.elloCameraPickerController)
            }
            alertController.addAction(cameraAction)

            let libraryAction = AlertAction(title: InterfaceString.ImagePicker.Library, style: .dark) { _ in
                Tracker.shared.imageAddedFromLibrary()
                callback(.elloPhotoLibraryPickerController)
            }
            alertController.addAction(libraryAction)

            let cancelAction = AlertAction(title: InterfaceString.Cancel, style: .light) { _ in
                Tracker.shared.addImageCanceled()
            }
            alertController.addAction(cancelAction)
        } else if UIImagePickerController.isSourceTypeAvailable(.photoLibrary) {
            Tracker.shared.imageAddedFromLibrary()
            callback(.elloPhotoLibraryPickerController)
            return nil
        } else {
            alertController = AlertViewController(message: InterfaceString.ImagePicker.NoSourceAvailable)

            let cancelAction = AlertAction(title: InterfaceString.OK, style: .light, handler: .none)
            alertController.addAction(cancelAction)
        }

        return alertController
    }

    static func imagePickerSheetForImagePicker(
        config: ImagePickerSheetConfig = ImagePickerSheetConfig(),
        callback: @escaping (ImagePickerSheetResult) -> Void
        ) -> ImagePickerSheetController
    {
        let controller = ImagePickerSheetController(mediaType: config.mediaType)

        if UIImagePickerController.isSourceTypeAvailable(.camera) {
            controller.addAction(
                ImagePickerAction(
                    title: config.cameraAction,
                    handler: { _ in
                        Tracker.shared.imageAddedFromCamera()
                        callback(.controller(.elloCameraPickerController))
                    })
            )
        }
        controller.addAction(
            ImagePickerAction(
                title: config.photoLibrary,
                secondaryTitle: config.addImage,
                handler: { _ in
                    Tracker.shared.imageAddedFromLibrary()
                    callback(.controller(.elloPhotoLibraryPickerController))
                }, secondaryHandler: { [weak controller] _, numberOfPhotos in
                    guard let controller = controller else { return }
                    callback(.images(controller.selectedAssets))
                })
        )
        controller.addAction(ImagePickerAction(title: InterfaceString.Cancel, style: .cancel, handler: { _ in
            Tracker.shared.addImageCanceled()
        }))

        return controller
    }

}
