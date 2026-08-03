//
//  PHPhotoPicker.swift
//  Photo HQ
//
//  Created by Oscar Castillo on 11/24/22.
//

import PhotosUI
import SwiftUI

struct PhotoPicker: UIViewControllerRepresentable {
    @Environment(\.dismiss) var dismiss
    
    @Binding var showLoadingOverlay: Bool
    
    private let photoLibrary = PHPhotoLibrary.shared()
    
    let closeAfterSelection: Bool = true
    let selectionLimit: Int = 1
    let completion: (_ selectedImages: [UIImage]) -> Void
    
    func makeUIViewController(context: Context) -> PHPickerViewController {
        var configuration = PHPickerConfiguration(photoLibrary: photoLibrary)
        configuration.filter = PHPickerFilter.any(of: [.images, .livePhotos])
        configuration.selectionLimit = self.selectionLimit
        configuration.preferredAssetRepresentationMode = .current
        let controller = PHPickerViewController(configuration: configuration)
        controller.delegate = context.coordinator
        return controller
    }
    
    func updateUIViewController(_: PHPickerViewController, context _: Context) {}
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    class Coordinator: PHPickerViewControllerDelegate {
        let parent: PhotoPicker
        
        init(_ parent: PhotoPicker) {
            self.parent = parent
        }
        
        func picker(_ picker: PHPickerViewController, didFinishPicking results: [PHPickerResult]) {
            var selectedImages: [UIImage] = []
            parent.showLoadingOverlay = true
            let dispatchGroup = DispatchGroup()
            
            for result in results {
                dispatchGroup.enter()
                var photoType: NSItemProviderReading.Type = UIImage.self
                let resultItemProvider = result.itemProvider
                
                if resultItemProvider.hasItemConformingToTypeIdentifier(UTType.livePhoto.identifier) {
                    photoType = PHLivePhoto.self
                }
                
                if resultItemProvider.hasItemConformingToTypeIdentifier(UTType.image.identifier) {
                    photoType = UIImage.self
                }
                
                if resultItemProvider.canLoadObject(ofClass: photoType) {
                    resultItemProvider.loadObject(ofClass: photoType) { resultImage, error in
                        if let error = error {
                            print(error.localizedDescription)
                        }
                        
                        if let image = resultImage as? UIImage {
                            selectedImages.append(image)
                            dispatchGroup.leave()
                        }
                    }
                } else {
                    dispatchGroup.leave()
                }
            }
            
            dispatchGroup.notify(queue: .main) {
                self.parent.completion(selectedImages)
                
                if self.parent.closeAfterSelection {
                    self.parent.showLoadingOverlay = false
                    self.parent.dismiss()
                }
            }
        }
    }
}
