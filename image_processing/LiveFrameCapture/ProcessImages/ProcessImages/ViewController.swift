
//  ViewController.swift
//  ProcessingCameraFeed
//
//  Created by Anurag Ajwani on 02/05/2020.
//  Copyright © 2020 Anurag Ajwani. All rights reserved.

// Modified by Dhwani Trivedi 
//

import UIKit
import AVFoundation

extension UIImage {
    /**
    Extracts and highlights the shadows within a region of interest
     */
    func highlightShadow() -> UIImage {
        guard let imageRef = self.cgImage else {
            return self
        }

        let width = imageRef.width
        let height = imageRef.height
        
        let bytesPerPixel = 4
        let bytesPerRow = bytesPerPixel * width
        let bitmapByteCount = bytesPerRow * height
        
        let rawData = UnsafeMutablePointer<UInt8>.allocate(capacity: bitmapByteCount)
        defer {
            rawData.deallocate()
        }
        
        guard let colorSpace = CGColorSpace(name: CGColorSpace.genericRGBLinear) else {
            return self
        }
        
        guard let context = CGContext(
            data: rawData,
            width: width,
            height: height,
            bitsPerComponent: 8,
            bytesPerRow: bytesPerRow,
            space: colorSpace,
            bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue
                | CGBitmapInfo.byteOrder32Big.rawValue
        ) else {
            return self
        }
        
        let rc = CGRect(x: 0, y: 0, width: width, height: height)
        // Draw source image on created context.
        context.draw(imageRef, in: rc)
        var byteIndex = 0
        // Iterate through pixels
        for y in 550 ..< 2450 {
            for x in 2330 ..< 2800 {
                let byteIndex = (y * bytesPerRow) + (x * bytesPerPixel)
                if rawData[byteIndex + 1] < 10 {
                    rawData[byteIndex] = 255
                } 
        }
        
        // Retrieve image from memory context.
        guard let image = context.makeImage() else {
            return self
        }
        let result = UIImage(cgImage: image)
        return result
    }

    func extractShadow() -> Array<Any> {
        guard let imageRef = self.cgImage else {
            return []
        }
        var shadowPts = [Any]()

        let width = imageRef.width
        let height = imageRef.height
        
        let bytesPerPixel = 4
        let bytesPerRow = bytesPerPixel * width
        let bitmapByteCount = bytesPerRow * height
        
        let rawData = UnsafeMutablePointer<UInt8>.allocate(capacity: bitmapByteCount)
        defer {
            rawData.deallocate()
        }
        
        guard let colorSpace = CGColorSpace(name: CGColorSpace.genericRGBLinear) else {
            return []
        }
        
        // Iterate through pixels
        for y in 550 ..< 2450 {
            for x in 2330 ..< 2800 {
                let byteIndex = (y * bytesPerRow) + (x * bytesPerPixel)
                if rawData[byteIndex + 1] < 10 {
                    shadowPts.append((x, y))
                } 
        }
        return shadowPts
    }
}

class ViewController: UIViewController, AVCaptureVideoDataOutputSampleBufferDelegate {
    
    private let captureSession = AVCaptureSession()
    private lazy var previewLayer: AVCaptureVideoPreviewLayer = {
        let preview = AVCaptureVideoPreviewLayer(session: self.captureSession)
        preview.videoGravity = .resizeAspect
        return preview
    }()
    private let videoOutput = AVCaptureVideoDataOutput()

    override func viewDidLoad() {
        super.viewDidLoad()
        self.addCameraInput()
        self.addPreviewLayer()
        self.addVideoOutput()
        self.captureSession.startRunning()
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        self.previewLayer.frame = self.view.bounds
    }
    
    func convertToGrayScale(image: UIImage) -> UIImage? {
        let imageRect:CGRect = CGRect(x:0, y:0, width:image.size.width, height: image.size.height)
        let colorSpace = CGColorSpaceCreateDeviceGray()
        let width = image.size.width
        let height = image.size.height
        let bitmapInfo = CGBitmapInfo(rawValue: CGImageAlphaInfo.none.rawValue)
        let context = CGContext(data: nil, width: Int(width), height: Int(height), bitsPerComponent: 8, bytesPerRow: 0, space: colorSpace, bitmapInfo: bitmapInfo.rawValue)
        if let cgImg = image.cgImage {
            context?.draw(cgImg, in: imageRect)
            if let makeImg = context?.makeImage() {
                let imageRef = makeImg
                let newImage = UIImage(cgImage: imageRef)
                return newImage
            }
        }
        return UIImage()
    }
    
    func addBlurTo(_ image: UIImage) -> UIImage? {
        if let ciImg = CIImage(image: image) {
            let ciImg = ciImg.applyingFilter("CIGaussianBlur")
            return UIImage(ciImage: ciImg)
        }
        return nil
    }
    
    func getBrightestPoint(image: UIImage) -> [(Int, Int)]? {
        var pointSums = (0, 0)
        var pointCounts = 1
        var maxBrightness = 0
        
        let context = CIContext(options: nil)
        if (context != nil){
            // convert to CGImage
            guard let cgImage = context.createCGImage(image.ciImage!, from: image.ciImage!.extent),
                  let data = cgImage.dataProvider?.data,
                  let bytes = CFDataGetBytePtr(data) else {
                fatalError("Couldn't access image data")
            }
            
            // loop through all pixels to find the center
            let bytesPerPixel = cgImage.bitsPerPixel / cgImage.bitsPerComponent
            print(cgImage.width)
            print(cgImage.height)
            for x in 0...(cgImage.width-1) {
                for y in 0...(cgImage.height-1) {
                    let offset = (y * cgImage.bytesPerRow) + (x * bytesPerPixel)
                    let components = (r: bytes[offset], g: bytes[offset + 1], b: bytes[offset + 2])
                    if (components.r > maxBrightness) {
                        maxBrightness = Int(components.r)
                        pointSums.0 = x
                        pointSums.1 = y
                        pointCounts = 1
                    }
                    else if (components.r == maxBrightness) {
                        pointSums.0 += x
                        pointSums.1 += y
                        pointCounts += 1
                    }
                }
            }
            
            let center = (Int(pointSums.0 / pointCounts), Int(pointSums.1 / pointCounts))
            print("Brightest point center: ", center.0, center.1)
            return [center]
            
            /*
            // draw point on image
            UIGraphicsBeginImageContext(image.size)
            image.draw(at: CGPoint.zero)
            
            let context = UIGraphicsGetCurrentContext()!
            context.setStrokeColor(UIColor.green.cgColor)
            context.setAlpha(0.5)
            context.setLineWidth(5.0)
            context.addEllipse(in: CGRect(x: center.0 - 2, y: center.1 - 2, width: 4, height: 4))
            context.drawPath(using: .fillStroke)
            
            let myImage = UIGraphicsGetImageFromCurrentImageContext()
            UIGraphicsEndImageContext()
            
            // return modified image
            return myImage
            */
        }
        return nil
    }
    
    func convert(cmage:CIImage) -> UIImage {       
        let context:CIContext = CIContext.init(options: nil)
        let cgImage:CGImage = context.createCGImage(cmage, from: cmage.extent)!        
        let image:UIImage = UIImage.init(cgImage: cgImage)        
        return image
    }

    func extractShadowSegmentation(image: UIImage) -> Array[Any] {
        let input_image = = CIImage(image: image)
        let filter = CIFilter(name: "CIColorThresholdOtsu")
        filter?.setValue(inputImage, forKey: "inputImage")
        let output = filter?.outputImage
        let toMask = convert(cmage: output!)
        return toMask.extractShadow()
    }

    func captureOutput(_ output: AVCaptureOutput,
                       didOutput sampleBuffer: CMSampleBuffer,
                       from connection: AVCaptureConnection) {
        guard let frame = CMSampleBufferGetImageBuffer(sampleBuffer) else {
            debugPrint("unable to get image from sample buffer")
            return
        }
        print("did receive image frame")
        // process image here
        
        // get UIImage from buffer
        let ciimage = CIImage(cvPixelBuffer: frame)
        let context = CIContext(options: nil)
        let cgImage = context.createCGImage(ciimage, from: ciimage.extent)!
        let image = UIImage(cgImage: cgImage)
        
        let greyscaleImage = convertToGrayScale(image: image)
        let blurImage = addBlurTo(greyscaleImage!)
        let brightestPoint = getBrightestPoint(image: blurImage!)
    }

    private func addCameraInput() {
        let device = AVCaptureDevice.default(for: .video)!
        let cameraInput = try! AVCaptureDeviceInput(device: device)
        self.captureSession.addInput(cameraInput)
    }
    
    private func addPreviewLayer() {
        self.view.layer.addSublayer(self.previewLayer)
    }
    
    private func addVideoOutput() {
        self.videoOutput.videoSettings = [(kCVPixelBufferPixelFormatTypeKey as NSString) : NSNumber(value: kCVPixelFormatType_32BGRA)] as [String : Any]
        self.videoOutput.setSampleBufferDelegate(self, queue: DispatchQueue(label: "my.image.handling.queue"))
        self.captureSession.addOutput(self.videoOutput)
    }
}
