import UIKit
import CoreImage

let context = CIContext()
var image = UIImage(named: "test.jpeg")!

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
let grey_image = convertToGrayScale(image: image)!

//func addBlurTo(_ image: UIImage) -> UIImage? {
//    if let ciImg = CIImage(image: image) {
//        let ciImg = ciImg.applyingFilter("CIGaussianBlur")
//        return UIImage(cgImage: ciImg)
//    }
//    return nil
//}

//image = addBlurTo(image)!

//let green_image = image.greenify()
//let inputImage = CIImage(image: green_image)
let inputImage2 = CIImage(image: image)

func convert(cmage:CIImage) -> UIImage
{       
    let context:CIContext = CIContext.init(options: nil)
    let cgImage:CGImage = context.createCGImage(cmage, from: cmage.extent)!        
    let image:UIImage = UIImage.init(cgImage: cgImage)        
    return image
}

let filter = CIFilter(name: "CIColorThresholdOtsu")
filter?.setValue(inputImage2, forKey: "inputImage")
let output2 = filter?.outputImage
var toMask = convert(cmage: output2!)
//image.greenify()
print(toMask.cgImage)
toMask = toMask.greenify()

func writeImage(_ image: UIImage, name: String) {
    if name.isEmpty || name.count < 3 {
        print("Name cannot be empty or less than 3 characters.")
        return
    }
    guard let documentsDirectory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first else {
        print("No documents directory found.")
        return
    }
    let imagePath = documentsDirectory.appendingPathComponent("\(name).png")
    let imagedata = image.jpegData(compressionQuality: 1.0)
    do {
        try imagedata?.write(to: imagePath)
        print("Image successfully written to path:\n\n \(documentsDirectory) \n\n")
    } catch {
        print("Error writing image: \(error)")
    }
}

writeImage(toMask, name: "export")
//filter?.setValue(inputImage, forKey: "inputImage")
//let output = filter?.outputImage

//
//let new_inputImage = CIImage(image: image)
//filter?.setValue(new_inputImage, forKey: "inputImage")
//let new_output = filter?.outputImage


extension UIImage {
    /**
     Replaces a color in the image with a different color.
     - Parameter color: color to be replaced.
     - Parameter with: the new color to be used.
     - Parameter tolerance: tolerance, between 0 and 1. 0 won't change any colors,
     1 will change all of them. 0.5 is default.
     - Returns: image with the replaced color.
     */
    func greenify() -> UIImage {
        guard let imageRef = self.cgImage else {
            print("yes")
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
//                else {
//                    rawData[byteIndex] = 0
//                }
            }
//            
//        while byteIndex < bitmapByteCount {
            

            
//            rawData[byteIndex + 0] <<= 1
//            rawData[byteIndex + 1] <<= 1
//            rawData[byteIndex + 2] <<= 1
//            byteIndex += 4
        }
        
        // Retrieve image from memory context.
        guard let image = context.makeImage() else {
            return self
        }
        let result = UIImage(cgImage: image)
        return result
    }
}

//let ctx = CIContext(options:nil)
//let cgImage = ctx.createCGImage(filter.outputImage, fromRect:filter.outputImage.extent())!

//let image = UIImage(named: "shadow.jpeg")!
//
//
//let imageRect:CGRect = CGRect(x:0, y:0, width:image.size.width, height: image.size.height)
//
//let bitmapInfo = CGBitmapInfo(rawValue: CGImageAlphaInfo.none.rawValue)
//
//
//func convertToGrayScale(image: UIImage) -> UIImage? {
//        let imageRect:CGRect = CGRect(x:0, y:0, width:image.size.width, height: image.size.height)
//        let colorSpace = CGColorSpaceCreateDeviceGray()
//        let width = image.size.width
//        let height = image.size.height
//        let bitmapInfo = CGBitmapInfo(rawValue: CGImageAlphaInfo.none.rawValue)
//        let context = CGContext(data: nil, width: Int(width), height: Int(height), bitsPerComponent: 8, bytesPerRow: 0, space: colorSpace, bitmapInfo: bitmapInfo.rawValue)
//        if let cgImg = image.cgImage {
//            context?.draw(cgImg, in: imageRect)
//            if let makeImg = context?.makeImage() {
//                let imageRef = makeImg
//                let newImage = UIImage(cgImage: imageRef)
//                return newImage
//            }
//        }
//        return UIImage()
//    }
//
//
//let newImage = convertToGrayScale(image: image)
//
////Apply gaussian blur filter
//
//func addBlurTo(_ image: UIImage) -> UIImage? {
//    if let ciImg = CIImage(image: newImage!) {
//        let ciImg = ciImg.applyingFilter("CIGaussianBlur")
//        return UIImage(ciImage: ciImg)
//    }
//    return nil
//}
//
//addBlurTo(newImage!)
//
//
//let blurImage = addBlurTo(newImage!)






//func image(fromPixelValues pixelValues: [UInt8]?, width: Int, height: Int) -> CGImage?
//{
//    var imageRef: CGImage?
//    if var pixelValues = pixelValues {
//        let bitsPerComponent = 8
//        let bytesPerPixel = 1
//        let bitsPerPixel = bytesPerPixel * bitsPerComponent
//        let bytesPerRow = bytesPerPixel * width
//        let totalBytes = height * bytesPerRow
//
//        imageRef = withUnsafePointer(to: &pixelValues, {
//            ptr -> CGImage? in
//            var imageRef: CGImage?
//            let colorSpaceRef = CGColorSpaceCreateDeviceGray()
//            let bitmapInfo = CGBitmapInfo(rawValue: CGImageAlphaInfo.none.rawValue).union(CGBitmapInfo())
//            let data = UnsafeRawPointer(ptr.pointee).assumingMemoryBound(to: UInt8.self)
//            let releaseData: CGDataProviderReleaseDataCallback = {
//                (info: UnsafeMutableRawPointer?, data: UnsafeRawPointer, size: Int) -> () in
//            }
//
//            if let providerRef = CGDataProvider(dataInfo: nil, data: data, size: totalBytes, releaseData: releaseData) {
//                imageRef = CGImage(width: width,
//                                   height: height,
//                                   bitsPerComponent: bitsPerComponent,
//                                   bitsPerPixel: bitsPerPixel,
//                                   bytesPerRow: bytesPerRow,
//                                   space: colorSpaceRef,
//                                   bitmapInfo: bitmapInfo,
//                                   provider: providerRef,
//                                   decode: nil,
//                                   shouldInterpolate: false,
//                                   intent: CGColorRenderingIntent.defaultIntent)
//            }
//            let imageRef = makeimg
//            let newImage = UIImage(cgImage: imageRef)
//            return newImage
//
//        })
//    }
//
//    return imageRef
//}


