func extractIlluminationIndex(imageStack: [UIImage]) -> [[Double]] {
    let numFrames = imageStack.count
    var illuminationIndex = [[Double]](repeating: [0, 0], count: numFrames)

    for (ii, image) in imageStack.enumerated() {
        let cgImage = image.cgImage
        let width = cgImage!.width
        let height = cgImage!.height
        let bytesPerPixel = 4
        let bytesPerRow = bytesPerPixel * width
        let bitsPerComponent = 8

        let colorSpace = CGColorSpaceCreateDeviceRGB()
        let bitmapInfo = CGBitmapInfo(rawValue: CGImageAlphaInfo.premultipliedLast.rawValue)
        let context = CGContext(data: nil, width: width, height: height, bitsPerComponent: bitsPerComponent, bytesPerRow: bytesPerRow, space: colorSpace, bitmapInfo: bitmapInfo.rawValue)!
        let imageRect = CGRect(x: 0, y: 0, width: width, height: height)
        context.draw(cgImage!, in: imageRect)
        let data = context.data

        var maxValue = 0.0
        for y in 0..<height {
            for x in 0..<width {
                let offset = y * width + x
                let red = data![offset * bytesPerPixel]
                let green = data![offset * bytesPerPixel + 1]
                let blue = data![offset * bytesPerPixel + 2]
                let alpha = data![offset * bytesPerPixel + 3]
                let intensity = 0.2126 * Double(red) + 0.7152 * Double(green) + 0.0722 * Double(blue)
                maxValue = max(maxValue, intensity)
            }
        }

        
