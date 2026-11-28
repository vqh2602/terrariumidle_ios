import SwiftUI
import Testing
import UIKit
@testable import terrariumidle_ios

@MainActor
struct PestAttackModalTests {
    private func hasNonTransparentPixels(_ view: some View, size: CGSize) -> Bool {
        let renderer = ImageRenderer(content: view.frame(width: size.width, height: size.height))
        renderer.scale = 1.0
        guard let cgImage = renderer.cgImage,
              let data = cgImage.dataProvider?.data,
              let ptr = CFDataGetBytePtr(data) else {
            return false
        }
        let length = CFDataGetLength(data)
        var nonZero = 0
        var i = 0
        while i < length {
            if ptr[i] != 0 {
                nonZero += 1
                if nonZero > 10 { return true }
            }
            i += 1
        }
        return false
    }

    @Test func pestAssetsRenderViaBundleImageHelper() {
        #expect(GardenModel.pestKillOxygenReward == 50)
        #expect(UIImage(named: "bug1@2.083x") != nil)
        #expect(UIImage(named: "grasshopper@2.083x") != nil)

        #expect(hasNonTransparentPixels(
            Image.bundle("bug1@2.083x").resizable().scaledToFit(),
            size: CGSize(width: 40, height: 40)
        ))
        #expect(hasNonTransparentPixels(
            Image.bundle("grasshopper@2.083x").resizable().scaledToFit(),
            size: CGSize(width: 40, height: 40)
        ))
    }
}
