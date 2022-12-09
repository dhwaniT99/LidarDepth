/*
See LICENSE folder for this sample’s licensing information.

Abstract:
An object that connects the CameraController and the views.
*/

import Foundation
import SwiftUI
import Combine
import simd
import AVFoundation
import UIKit

class CameraManager: ObservableObject, CaptureDataReceiver {

    var capturedData: CameraCapturedData
    @Published var isFilteringDepth: Bool {
        didSet {
            controller.isFilteringEnabled = isFilteringDepth
        }
    }
    @Published var orientation = UIDevice.current.orientation
    @Published var waitingForCapture = false
    @Published var processingCapturedResult = false
    @Published var dataAvailable = false
    @Published var brightestPoint = (0, 0)
    @Published var brightestPoint3D:(Float, Float, Float, Float) = (0.0, 0.0, 0.0, 0.0)
    @Published var imageSize = (0, 0)
    @Published var shadow = UIImage()
    
    let controller: CameraController
    var cancellables = Set<AnyCancellable>()
    var session: AVCaptureSession { controller.captureSession }
    
    init() {
        // Create an object to store the captured data for the views to present.
        capturedData = CameraCapturedData()
        controller = CameraController()
        controller.isFilteringEnabled = true
        controller.startStream()
        isFilteringDepth = controller.isFilteringEnabled
        
        NotificationCenter.default.publisher(for: UIDevice.orientationDidChangeNotification).sink { _ in
            self.orientation = UIDevice.current.orientation
        }.store(in: &cancellables)
        controller.delegate = self
    }
    
    func startPhotoCapture() {
        controller.capturePhoto()
        waitingForCapture = true
    }
    
    func resumeStream() {
        controller.startStream()
        processingCapturedResult = false
        waitingForCapture = false
    }
    
    func onNewPhotoData(capturedData: CameraCapturedData) {
        // Because the views hold a reference to `capturedData`, the app updates each texture separately.
        self.capturedData.depth = capturedData.depth
        self.capturedData.colorY = capturedData.colorY
        self.capturedData.colorCbCr = capturedData.colorCbCr
        self.capturedData.cameraIntrinsics = capturedData.cameraIntrinsics
        self.capturedData.cameraReferenceDimensions = capturedData.cameraReferenceDimensions
        self.capturedData.ciImage = capturedData.ciImage
        self.capturedData.depthMap = capturedData.depthMap
        getBrightestPoint()
        highlightShadow()
        waitingForCapture = false
        processingCapturedResult = true
    }
    
    func onNewData(capturedData: CameraCapturedData) {
        DispatchQueue.main.async {
            if !self.processingCapturedResult {
                // Because the views hold a reference to `capturedData`, the app updates each texture separately.
                self.capturedData.depth = capturedData.depth
                self.capturedData.colorY = capturedData.colorY
                self.capturedData.colorCbCr = capturedData.colorCbCr
                self.capturedData.cameraIntrinsics = capturedData.cameraIntrinsics
                self.capturedData.cameraReferenceDimensions = capturedData.cameraReferenceDimensions
                self.capturedData.ciImage = capturedData.ciImage
                self.capturedData.depthMap = capturedData.depthMap
                if self.dataAvailable == false {
                    self.dataAvailable = true
                }
            }
        }
    }
    
    func highlightShadow() {
        let ciimage = self.capturedData.ciImage
        let context = CIContext.init(options: nil)
        let cgImage = context.createCGImage(ciimage!, from: ciimage!.extent)!
        let uiimage = UIImage.init(cgImage: cgImage)
        shadow = uiimage.highlightShadow()
    }
    
    func getBrightestPoint() {
        let ciimage = self.capturedData.ciImage
        let context = CIContext(options: nil)
        let cgImage = context.createCGImage(ciimage!, from: ciimage!.extent)!
        let image = UIImage(cgImage: cgImage)
        
        // convert to greyscale
        var greyscaleImage = UIImage()
        
        let imageRect:CGRect = CGRect(x:0, y:0, width:image.size.width, height: image.size.height)
        let colorSpace = CGColorSpaceCreateDeviceGray()
        let width = image.size.width
        let height = image.size.height
        let bitmapInfo = CGBitmapInfo(rawValue: CGImageAlphaInfo.none.rawValue)
        let cgcontext = CGContext(data: nil, width: Int(width), height: Int(height), bitsPerComponent: 8, bytesPerRow: 0, space: colorSpace, bitmapInfo: bitmapInfo.rawValue)
        if let cgImg = image.cgImage {
            cgcontext?.draw(cgImg, in: imageRect)
            if let makeImg = cgcontext?.makeImage() {
                let imageRef = makeImg
                let newImage = UIImage(cgImage: imageRef)
                greyscaleImage = newImage
            }
        }
        
        // blur greyscale image - adds 30 pixels on each side
        var blurredImage = UIImage()
        if let ciImg = CIImage(image: greyscaleImage) {
            let ciImg = ciImg.applyingFilter("CIGaussianBlur")
            blurredImage = UIImage(ciImage: ciImg)
        }
        
        // calculate 2D brightest point center
        var pointSums = (0, 0)
        var pointCounts = 1
        var maxBrightness = 0
        
        let cicontext = CIContext(options: nil)
        if (cicontext != nil){
            // convert to CGImage
            guard let cgImage = cicontext.createCGImage(blurredImage.ciImage!, from: blurredImage.ciImage!.extent),
                  let data = cgImage.dataProvider?.data,
                  let bytes = CFDataGetBytePtr(data) else {
                fatalError("Couldn't access image data")
            }
            
            // Actual display seems to show that height and width are flipped?
            imageSize.0 = cgImage.width
            imageSize.1 = cgImage.height
            
            // loop through all pixels to find the center
            let bytesPerPixel = cgImage.bitsPerPixel / cgImage.bitsPerComponent
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
            
            // Offesets to account for changes in image size due to Gaussian blur
            brightestPoint.0 = max(min(Int(pointSums.0 / pointCounts), imageSize.0 - 30) - 30, 0)
            brightestPoint.1 = max(min(Int(pointSums.1 / pointCounts), imageSize.1 - 30) - 30, 0)
        }
        
        // calculate 3D brightest point center - may need to flip x and y?
        let point = CGPoint(x: brightestPoint.0, y: brightestPoint.1)
        
        CVPixelBufferLockBaseAddress(self.capturedData.depthMap!, CVPixelBufferLockFlags(rawValue: 0))
        let depthPointer = unsafeBitCast(CVPixelBufferGetBaseAddress(self.capturedData.depthMap!), to: UnsafeMutablePointer<Float16>.self)
        
        let newWidth = CVPixelBufferGetWidth(self.capturedData.depthMap!)
        let depth = Float(depthPointer[Int(point.y * CGFloat(newWidth) + point.x)]) * 1000
        
        let depthResolution = simd_float2(x: Float(self.capturedData.depth!.width), y: Float(self.capturedData.depth!.height))
        let scaleRes = simd_float2(x: Float( self.capturedData.cameraReferenceDimensions.width) / depthResolution.x,
                                   y: Float(self.capturedData.cameraReferenceDimensions.height) / depthResolution.y )
        
        var xrw = Float(max(brightestPoint.0 - 30, 0)) - (self.capturedData.cameraIntrinsics[2][0] / scaleRes.x)
        xrw = xrw * depth / (self.capturedData.cameraIntrinsics[0][0] / scaleRes.x);
        var yrw = Float(max(brightestPoint.1 - 30, 0)) - (self.capturedData.cameraIntrinsics[2][1] / scaleRes.y)
        yrw = yrw * depth / (self.capturedData.cameraIntrinsics[1][1] / scaleRes.y);
        brightestPoint3D.0 = Float(xrw)
        brightestPoint3D.1 = Float(yrw)
        brightestPoint3D.2 = Float(depth)
        brightestPoint3D.3 = 1
    }
   
}

class CameraCapturedData {
    
    var depth: MTLTexture?
    var colorY: MTLTexture?
    var colorCbCr: MTLTexture?
    var cameraIntrinsics: matrix_float3x3
    var cameraReferenceDimensions: CGSize
    var ciImage: CIImage?
    var depthMap: CVPixelBuffer?

    init(depth: MTLTexture? = nil,
         colorY: MTLTexture? = nil,
         colorCbCr: MTLTexture? = nil,
         cameraIntrinsics: matrix_float3x3 = matrix_float3x3(),
         cameraReferenceDimensions: CGSize = .zero,
         ciImage: CIImage? = nil,
         depthMap: CVPixelBuffer? = nil) {
        
        self.depth = depth
        self.colorY = colorY
        self.colorCbCr = colorCbCr
        self.cameraIntrinsics = cameraIntrinsics
        self.cameraReferenceDimensions = cameraReferenceDimensions
        self.ciImage = ciImage
        self.depthMap = depthMap
    }
}

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
        //        var byteIndex = 0
        // Iterate through pixels
        for y in 0 ..< height {
            for x in 0 ..< width {
                let byteIndex = (y * bytesPerRow) + (x * bytesPerPixel)
                if rawData[byteIndex + 1] < 10 {
                    rawData[byteIndex] = 255
                }
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
        
        //        guard let colorSpace = CGColorSpace(name: CGColorSpace.genericRGBLinear) else {
        //            return []
        //        }
        
        // Iterate through pixels
        for y in 550 ..< 2450 {
            for x in 2330 ..< 2800 {
                let byteIndex = (y * bytesPerRow) + (x * bytesPerPixel)
                if rawData[byteIndex + 1] < 10 {
                    shadowPts.append((x, y))
                }
            }
        }
        return shadowPts
    }
}
