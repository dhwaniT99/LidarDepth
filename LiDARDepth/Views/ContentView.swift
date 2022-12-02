/*
See LICENSE folder for this sample’s licensing information.

Abstract:
The app's main user interface.
*/

//Modified by Dhwani Trivedi

import SwiftUI
import MetalKit
import Metal

struct ContentView: View {
    
    @StateObject private var manager = CameraManager()
    
    @State private var maxDepth = Float(15.0)
    @State private var minDepth = Float(0)
    @State private var scaleMovement = Float(1.0)
    @State var buttonStyles = [CustomStyle(), CustomStyle(), CustomStyle(), CustomStyle()]
    
    let maxRangeDepth = Float(5)
    let minRangeDepth = Float(0)
    
    var body: some View {
        VStack {
            HStack {
                Button {
                    manager.processingCapturedResult ? manager.resumeStream() : manager.startPhotoCapture()
                } label: {
                    Image(systemName: manager.processingCapturedResult ? "play.circle" : "camera.circle")
                        .font(.largeTitle)
                }
                
                Text("Depth Filtering")
                Toggle("Depth Filtering", isOn: $manager.isFilteringDepth).labelsHidden()
                Spacer()
            }
            
            HStack{
                Text("Brightest Point: ")
                Text(LocalizedStringKey(String(manager.brightestPoint.0)))
                Text(LocalizedStringKey(String(manager.brightestPoint.1)))
            }
            
            HStack{
                Text("Brightest Point 3D: ")
                Text(LocalizedStringKey(String(manager.brightestPoint3D.0)))
                Text(LocalizedStringKey(String(manager.brightestPoint3D.1)))
                Text(LocalizedStringKey(String(manager.brightestPoint3D.2)))
                Text(LocalizedStringKey(String(manager.brightestPoint3D.3)))
            }
            
            HStack{
                Text("Image Size: ")
                Text(LocalizedStringKey(String(manager.imageSize.0)))
                Text(LocalizedStringKey(String(manager.imageSize.1)))
            }
            
            //SliderDepthBoundaryView(val: $maxDepth, label: "Max Depth", minVal: minRangeDepth, maxVal: maxRangeDepth)
            //SliderDepthBoundaryView(val: $minDepth, label: "Min Depth", minVal: minRangeDepth, maxVal: maxRangeDepth)
            
            HStack {
                ForEach(1..<5) { minDepth in
                    Button {
                        self.minDepth = Float(0.70)
                        self.maxDepth = Float(minDepth + 1)
                        self.buttonStyles = [CustomStyle(), CustomStyle(), CustomStyle(), CustomStyle()]
                        self.buttonStyles[minDepth - 1].isSelected = true
                        
                        
                    } label: {
                        Text("\(minDepth)-\(minDepth+1)")
                    }
                    .padding()
                    .foregroundColor(.white)
                    .background(.blue)
                    .cornerRadius(12)
                    .buttonStyle(buttonStyles[minDepth - 1])
                    
                    Spacer()
                }
            }
            
            ScrollView {
                LazyVGrid(columns: [GridItem(.flexible(maximum: 600)), GridItem(.flexible(maximum: 600))]) {
                    
                    if manager.dataAvailable {
                        ZoomOnTap {
                            MetalTextureColorThresholdDepthView(
                                rotationAngle: rotationAngle,
                                maxDepth: $maxDepth,
                                minDepth: $minDepth,
                                capturedData: manager.capturedData
                            )
                            .aspectRatio(calcAspect(orientation: viewOrientation, texture: manager.capturedData.depth), contentMode: .fit)
                        }
                        ZoomOnTap {
                            MetalTextureColorZapView(
                                rotationAngle: rotationAngle,
                                maxDepth: $maxDepth,
                                minDepth: $minDepth,
                                capturedData: manager.capturedData
                            )
                            .aspectRatio(calcAspect(orientation: viewOrientation, texture: manager.capturedData.depth), contentMode: .fit)
                        }
                        ZoomOnTap {
                            MetalPointCloudView(
                                rotationAngle: rotationAngle,
                                maxDepth: $maxDepth,
                                minDepth: $minDepth,
                                scaleMovement: $scaleMovement,
                                brightestPoint3D: $manager.brightestPoint3D,
                                brightestPoint: $manager.brightestPoint,
                                capturedData: manager.capturedData
                            )
                            .aspectRatio(calcAspect(orientation: viewOrientation, texture: manager.capturedData.depth), contentMode: .fit)
                        }
                        ZoomOnTap {
                            DepthOverlay(manager: manager,
                                         maxDepth: $maxDepth,
                                         minDepth: $minDepth
                            )
                                .aspectRatio(calcAspect(orientation: viewOrientation, texture: manager.capturedData.depth), contentMode: .fit)
                        }
                    }
                }
            }
        }
    }
}

//struct SliderDepthBoundaryView: View {
//    @Binding var val: Float
//    var label: String
//    var minVal: Float
//    var maxVal: Float
//    let stepsCount = Float(200.0)
//    var body: some View {
//        HStack {
//            Text(String(format: " %@: %.2f", label, val))
//            Slider(
//                value: $val,
//                in: minVal...maxVal,
//                step: (maxVal - minVal) / stepsCount
//            ) {
//            } minimumValueLabel: {
//                Text(String(minVal))
//            } maximumValueLabel: {
//                Text(String(maxVal))
//            }
//        }
//    }
//}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
            .previewDevice("iPhone 12 Pro Max")
    }
}


struct CustomStyle: ButtonStyle {
    
    var isSelected = false
    
    func makeBody(configuration: Self.Configuration) -> some View {
        configuration.label
            .clipShape(RoundedRectangle(cornerRadius: isSelected ? 4.0 : 0.0))
            .overlay(RoundedRectangle(cornerRadius: isSelected ? 4.0 : 0.0).stroke(lineWidth: isSelected ? 2.0 : 0.0).foregroundColor(Color.pink))
            .animation(.linear)
    }
}




