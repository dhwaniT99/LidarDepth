import UIKit

let image = UIImage(named: "Test2.jpg")!


let imageRect:CGRect = CGRect(x:0, y:0, width:image.size.width, height: image.size.height)

let bitmapInfo = CGBitmapInfo(rawValue: CGImageAlphaInfo.none.rawValue)


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


let newImage = convertToGrayScale(image: image)

//Apply gaussian blur filter

func addBlurTo(_ image: UIImage) -> UIImage? {
    if let ciImg = CIImage(image: newImage!) {
        let ciImg = ciImg.applyingFilter("CIGaussianBlur")
        return UIImage(ciImage: ciImg)
    }
    return nil
}

let blurImage = addBlurTo(newImage!)

func getBrightestPoint(image: UIImage) -> UIImage? {
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
    }
    return nil
}

let brightestPointImage = getBrightestPoint(image: blurImage!)


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


