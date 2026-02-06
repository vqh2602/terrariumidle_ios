//
//  RivePlantCompoment.swift
//  terrariumidle_ios
//
//  Created by vương quang huy on 2/2/26.
//

import Foundation

import Combine
@_spi(RiveExperimental) import RiveRuntime
import SwiftUI

// struct PlantRiveView: View {
//  var geometry: GeometryProxy
//
//  var body: some View {
//    RiveViewRepresentable(urlString: "https://vqh2602.github.io/terrarium_data.github.io/rive/plants/plant13.riv")
//      .frame(width: geometry.size.width * 0.3, height: 200)
//  }
// }
//
// struct RiveViewRepresentable: UIViewRepresentable {
//  let urlString: String
//
//  func makeUIView(context: Context) -> RiveView {
//    let riveView = RiveView()
//    Task {
//      do {
//        let url = URL(string: urlString)!
//        let file = try await RiveFile()              // nếu initializer khác, giữ ý tưởng: load file
//        let artboard = try file.artboard()                   // lấy default artboard (hoặc theo tên)
//        let smi = try artboard.stateMachineInstance(name: "plant")
//
//        // ✅ IN RA TẤT CẢ INPUT NAMES
//        print("=== INPUT NAMES ===")
//        for name in smi.inputNames {                         // property có thật trên iOS runtime
//          print("•", name)
//        }
//
//        // ✅ SET NUMBER INPUT "level" = 1
//        if let level = smi.numberInput(withName: "level") {  // trả về RiveSMINumber
//          level.value = 1
//        } else if let level = smi.numberInput(withName: "Level") {
//          level.value = 1
//        } else {
//          print("❌ Không tìm thấy Number input 'level'/'Level'")
//        }
//
//        riveView.setModel(RiveModel(artboard: artboard, stateMachine: smi))
//      } catch {
//        print("Rive load error:", error)
//      }
//    }
//    return riveView
//  }
//
//  func updateUIView(_ uiView: RiveView, context: Context) {}
// }

struct PlantRiveView: View {
    var width: Double?
    var height: Double?
    var plantId: String // ID của plant (ví dụ: "plant1", "plant24", "sticker1")
    var plantLevel: Int // Level của plant (ví dụ: 1, 3, 5)
    
    @StateObject private var vm: RiveViewModel
    
    /// Khởi tạo PlantRiveView với các tham số động
    /// - Parameters:
    ///   - width: Chiều rộng của view
    ///   - height: Chiều cao của view (optional)
    ///   - plantId: ID của plant để load animation tương ứng (mặc định "plant1")
    ///   - plantLevel: Level của plant để hiển thị trạng thái phù hợp (mặc định 1)
    init(width: Double, height: Double? = nil, plantId: String = "plant1", plantLevel: Int = 1) {
        self.width = width
        self.height = height
        self.plantId = plantId
        self.plantLevel = plantLevel
        
        // Kiểm tra xem có phải là plant hay không (sticker, decoration, etc.)
        let isPlant = plantId.lowercased().contains("plant")
        
        // Tạo RiveViewModel với fileName từ plantId
        // Chỉ gắn stateMachine "plant" nếu ID là plant, không gắn cho sticker
        _vm = StateObject(wrappedValue: RiveViewModel(
            fileName: plantId, // Sử dụng plantId làm fileName (ví dụ: "plant24", "sticker1")
            stateMachineName: isPlant ? "plant" : nil, // nil cho sticker/decoration
            fit: .contain,
            alignment: .bottomCenter
        ))
    }
    
    var body: some View {
        VStack {
            vm.view()
                .frame(width: width ?? 100, height: height ?? 200, alignment: .bottomLeading)
                .background(.black.opacity(0.1))
                .onAppear {
                    //                //                vm.play()
                    //                var    riveFile = RiveFile(httpUrl:"https://vqh2602.github.io/terrarium_data.github.io/rive/plants/plant24.riv" , loadCdn: true, with: .self)
                    //                vm.riveFileDidLoad(riveFile)
                    
                }.task {
                    print("ℹ️ Plant View did appear - ID: \(plantId), Level: \(plantLevel)")
                    try? await Task.sleep(nanoseconds: 50_000_000) // 50ms
                    
                    // Chỉ set level cho plant, không set cho sticker/decoration
                    if plantId.lowercased().contains("plant") {
                        vm.setInput("level", value: Double(plantLevel))
                    }
                    vm.setPreferredFramesPerSecond(preferredFramesPerSecond: 120)
                }
            //            Button( "Text2")
            //            {
            //                vm.setInput("level", value: 2.0)
            //            }
            //            Button( "Text1")
            //            {
            //                vm.setInput("level", value: 1.0)
            //            }
            //            Button( "Text3")
            //            {
            //                vm.setInput("level", value: 3.0)
            //            }
        }
    }
}

#Preview {
    PlantRiveView(width: 100)
}
