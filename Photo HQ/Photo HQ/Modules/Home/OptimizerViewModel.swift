//
//  OptimizerViewModel.swift
//  ImageOptimize
//
//  Created by Oscar Castillo on 11/22/22.
//

import UIKit
import Vision
import ImageIO

enum RatioType {
    case width
    case height
}

class OptimizerViewModel: NSObject, ObservableObject {
    @Published var convertedImage: UIImage?
    @Published var isOptimizing: Bool = false
    @Published var hasAlert: Bool = false
    @Published var originalImage: UIImage? {
        didSet {
            convertedImage = nil
        }
    }
    
    let configuration = MLModelConfiguration()
    var imageCropAndScaleOption: VNImageCropAndScaleOption = .scaleFill
    var originalImageRatio: CGSize = .zero
    var imageRatio: [RatioType: CGFloat] = [:]
    var alertMessage: String = ""
    
    // MARK: - Image Results
    
    lazy var visionRequest: VNCoreMLRequest = {
        do {
            let visionModel = try VNCoreMLModel(for: Realesrgan512(configuration: configuration).model)
            
            let request = VNCoreMLRequest(model: visionModel, completionHandler: { request, error in
                // I take the main thread again after getting a result or an error. The Cacao way.
                DispatchQueue.main.async { [weak self] in
                    guard let self = self else { return }
                    
                    self.isOptimizing = true
                    
                    if let results = request.results as? [VNPixelBufferObservation],
                       let pixelBuffer = results.first?.pixelBuffer {
                        let ciImage = CIImage(cvPixelBuffer: pixelBuffer)
                        
                        let ciContext = CIContext()
                        guard let safeCGImage = ciContext.createCGImage(ciImage, from: ciImage.extent) else { return }
                        let resultImage = UIImage(cgImage: safeCGImage)
                        self.resizeImageProportions(image: resultImage)
                        self.isOptimizing = false
                    } else {
                        self.isOptimizing = false
                    }
                }
            })
            
            request.imageCropAndScaleOption = imageCropAndScaleOption
            return request
        } catch {
            fatalError("Failed to create VNCoreMLModel: \(error)")
        }
    }()
    
    // MARK: Image Optimization
    
    func optimizeImage(_ image: UIImage) {
        guard let ciImage = CIImage(image: image) else { return }
        setImageProportions(for: image)
        isOptimizing = true
        let orientation = CGImagePropertyOrientation(image.imageOrientation)
        
        // I decided to use this to not block the Users UI because Vision uses Main Thread.
        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            guard let self = self else { return }
            let handler = VNImageRequestHandler(ciImage: ciImage, orientation: orientation)
            do {
                try handler.perform([self.visionRequest])
                
            } catch {
                self.alertMessage = "Failed to perform prediction: \(error)"
                self.hasAlert = true
            }
        }
    }
    
    func execute() {
        
    }
    
    // I save the old image proportions
    func setImageProportions(for image: UIImage) {
        if image.size.width > image.size.height {
            let ratio = image.size.height / image.size.width
            imageRatio = [.height: ratio]
        }
        
        if image.size.height > image.size.width {
            let ratio = image.size.width / image.size.height
            imageRatio = [.width: ratio]
        }
        
        if image.size.width == image.size.height {
            imageRatio = [ : ]
        }
    }
    
    // MARK: - Image Results Resize
    
    func resizeImageProportions(image: UIImage) {
        guard let ratio = Array(imageRatio.keys).first, let value = imageRatio[ratio] else { return }
        switch ratio {
        case .width:
            let width = image.size.width
            let targetWidth = width * value
            convertedImage = ImageResizer.resizeImage(image: image, targetSize: CGSize(width: targetWidth, height: image.size.height))
        case .height:
            let height = image.size.height
            let targetHeight = height * value
            convertedImage = ImageResizer.resizeImage(image: image, targetSize: CGSize(width: image.size.width, height: targetHeight))
        }
    }
    
    // MARK: - Save Image
    
    func saveImage(image: UIImage) {
        UIImageWriteToSavedPhotosAlbum(image, self, #selector(image(_:didFinishSavingWithError:contextInfo:)), nil)
    }
    
    @objc func image(_ image: UIImage, didFinishSavingWithError error: Error?, contextInfo: UnsafeRawPointer) {
        if error != nil {
            alertMessage = "Your Image could not be saved, please try again."
        } else {
            alertMessage = "Your Image was saved successfully!"
        }
        
        hasAlert = true
    }
}

extension CGImagePropertyOrientation {
    /**
     Converts a `UIImageOrientation` to a corresponding
     `CGImagePropertyOrientation`. The cases for each
     orientation are represented by different raw values.
     
     - Tag: ConvertOrientation
     */
    init(_ orientation: UIImage.Orientation) {
        switch orientation {
        case .up:
            self = .up
        case .upMirrored:
            self = .upMirrored
        case .down:
            self = .down
        case .downMirrored:
            self = .downMirrored
        case .left:
            self = .left
        case .leftMirrored:
            self = .leftMirrored
        case .right:
            self = .right
        case .rightMirrored:
            self = .rightMirrored
        @unknown default:
            fatalError()
        }
    }
}
