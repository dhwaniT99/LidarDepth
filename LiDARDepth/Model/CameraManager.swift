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
            
            brightestPoint.0 = Int(pointSums.0 / pointCounts)
            brightestPoint.1 = Int(pointSums.1 / pointCounts)
        }
        
        // calculate 3D brightest point center
        let point = CGPoint(x: max(brightestPoint.0 - 30, 0), y: max(brightestPoint.1 - 30, 0))
        
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
