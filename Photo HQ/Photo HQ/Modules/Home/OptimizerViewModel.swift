//
//  OptimizerViewModel.swift
//  ImageOptimize
//
//  Created by Oscar Castillo on 11/22/22.
//

import UIKit
import Vision
import ImageIO

class OptimizerViewModel: ObservableObject {
    @Published var convertedImage: UIImage?
    @Published var isOptimizing: Bool = false
    @Published var originalImage: UIImage?
    
    var imageCropAndScaleOption: VNImageCropAndScaleOption = .scaleFill
    let configuration = MLModelConfiguration()
    
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
                        
                        self.convertedImage = resultImage
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
        
        isOptimizing = true
        let orientation = CGImagePropertyOrientation(image.imageOrientation)
        
        // To see what happens when the image orientation is wrong,
        // choose a fixed orientation value here:
        //let orientation = CGImagePropertyOrientation.up
        //    DispatchQueue.global(qos: .background).async { [weak self] in
        //       guard let self = self else { return }
        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            guard let self = self else { return }
            let handler = VNImageRequestHandler(ciImage: ciImage, orientation: orientation)
            do {
                
                try handler.perform([self.visionRequest])
                
            } catch {
                print("Failed to perform prediction: \(error)")
            }
        }
        //    }
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
        case .up: self = .up
        case .upMirrored: self = .upMirrored
        case .down: self = .down
        case .downMirrored: self = .downMirrored
        case .left: self = .left
        case .leftMirrored: self = .leftMirrored
        case .right: self = .right
        case .rightMirrored: self = .rightMirrored
        @unknown default:
            fatalError()
        }
    }
}
