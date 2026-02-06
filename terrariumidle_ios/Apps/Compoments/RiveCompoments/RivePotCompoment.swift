
//
//  RivePotCompoment.swift
//  terrariumidle_ios
//
//  Created by vương quang huy on 2/2/26.
//

import Foundation

@_spi(RiveExperimental) import RiveRuntime
import SwiftUI

// struct PotRiveView: View {
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

struct PotRiveView: View {
    var width: Double
    var height: Double?
    var potId: String // ID của pot (ví dụ: "pot1", "pot4", "sticker1")

    @StateObject private var vm: RiveViewModel

    /// Khởi tạo PotRiveView với các tham số động
    /// - Parameters:
    ///   - width: Chiều rộng của view
    ///   - height: Chiều cao của view (optional)
    ///   - potId: ID của pot để load animation tương ứng (mặc định "pot1")
    init(width: Double, height: Double? = nil, potId: String = "pot1") {
        self.width = width
        self.height = height
        self.potId = potId

        // Tạo RiveViewModel với fileName từ potId
        _vm = StateObject(wrappedValue: RiveViewModel(
            fileName: potId, // Sử dụng potId làm fileName (ví dụ: "pot4", "pot7")
            fit: .fitHeight
        ))
    }

    var body: some View {
        vm.view()
            .frame(width: width, height: height ?? 100)
            .background(Color.black.opacity(0.1))
            .onAppear {
//                vm.play()
            }.task {
                print("ℹ️ Pot View did appear - ID: \(potId)")
                try? await Task.sleep(nanoseconds: 50_000_000) // 50ms

                // Play pot animation
                vm.pause()
                vm.play()
            }
    }
}

struct PotRiveView2: View {
    var width: Double
    var height: Double?
    var body: some View {
        RiveUIView(rive: {
            let worker = Worker()
            let file = try await File(
                source: .url(URL(string: "https://vqh2602.github.io/terrarium_data.github.io/rive/pots/pot5.riv")!),
                worker: worker
            )

            // ✅ Let Rive pick default artboard + default state machine + auto-bind VM if available
            let rive = try await Rive(file: file, dataBind: .auto, fit: .fitHeight(alignment: .center))

            return rive
        }).view().onAppear()
            .frame(width: width, height: height ?? 100)
    }
}

#Preview {
    PotRiveView(width: 200)
}
