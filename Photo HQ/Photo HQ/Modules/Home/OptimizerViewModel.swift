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

class OptimizerViewModel: ObservableObject {
    @Published var convertedImage: UIImage?
    @Published var isOptimizing: Bool = false
    @Published var originalImage: UIImage?
    
    var imageCropAndScaleOption: VNImageCropAndScaleOption = .scaleFill
    let configuration = MLModelConfiguration()
    
    var originalImageRatio: CGSize = .zero
    
    var imageRatio: [RatioType: CGFloat] = [:]
    
    lazy var visionRequest: VNCoreMLRequest = {
        do {
            let visionModel = try VNCoreMLModel(for: Realesrgan512(configuration: configuration).model)
            
            let request = VNCoreMLRequest(model: visionModel, completionHandler: { request, error in
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
    
    func transformImage(image: UIImage) {
        guard let ciImage = CIImage(image: image) else { return }
        setImageProportions(for: image)
        isOptimizing = true
        let orientation = CGImagePropertyOrientation(image.imageOrientation)
        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            guard let self = self else { return }
            let handler = VNImageRequestHandler(ciImage: ciImage, orientation: orientation)
            do {
                try handler.perform([self.visionRequest])
                
            } catch {
                print("Failed to perform prediction: \(error)")
            }
        }
    }
    
    func resizeImageProportions(image: UIImage) {
        guard let ratio = Array(imageRatio.keys).first, let value = imageRatio[ratio] else { return }
        switch ratio {
        case .width:
            let width = image.size.width
            let targetWidth = width * value
            convertedImage = resizeImage(image: image, targetSize: CGSize(width: targetWidth, height: image.size.height))
        case .height:
            let height = image.size.height
            let targetHeight = height * value
            convertedImage = resizeImage(image: image, targetSize: CGSize(width: image.size.width, height: targetHeight))
        }
    }
    
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
    
    func resizeImage(image: UIImage, targetSize: CGSize) -> UIImage {
       let size = image.size
       
       let widthRatio  = targetSize.width  / size.width
       let heightRatio = targetSize.height / size.height
       
       // Figure out what our orientation is, and use that to form the rectangle
       var newSize: CGSize
       if(widthRatio > heightRatio) {
           newSize = CGSize(width: size.width * widthRatio, height: size.height * heightRatio)
       } else {
           newSize = CGSize(width: size.width * heightRatio,  height: size.height * widthRatio)
       }
       
       // This is the rect that we've calculated out and this is what is actually used below
       let rect = CGRect(x: 0, y: 0, width: newSize.width, height: newSize.height)
       
       // Actually do the resizing to the rect using the ImageContext stuff
       UIGraphicsBeginImageContextWithOptions(newSize, false, 1.0)
       image.draw(in: rect)
       let newImage = UIGraphicsGetImageFromCurrentImageContext()
       UIGraphicsEndImageContext()
       
       return newImage!
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
