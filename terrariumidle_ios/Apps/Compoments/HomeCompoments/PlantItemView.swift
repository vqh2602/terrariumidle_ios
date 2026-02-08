//
//  PlantItemView.swift
//  terrariumidle_ios
//
//  Created by vương quang huy on 6/2/26.
//

@_spi(RiveExperimental) import RiveRuntime
import SwiftUI

/// Widget hiển thị plant/pot với logic cho hanging và normal layout
struct PlantItemView: View {
    let itemWidth: CGFloat
    let plantData: GardenModel.Plant?
    let rowIndex: Int
    let columnIndex: Int
    
    var body: some View {
        // Kiểm tra xem có phải sticker không
        let isSticker = (plantData?.idPlant.contains("sticker") == true &&
                         plantData?.idPlant == plantData?.idPot)
        
        // Kiểm tra xem cây có treo không (isHanging = 1)
        let isHanging = plantData?.isHanging == 1
        
        // Nếu KHÔNG phải sticker, check xem có plantId hoặc potId trống không
        let hasEmptyIds = !isSticker && (
            plantData?.idPlant.isEmpty == true ||
            plantData?.idPot.isEmpty == true ||
            plantData?.idPlant == nil ||
            plantData?.idPot == nil
        )
        
        Group {
            
            // MARK: - Layout Logic
            
            // Nếu không phải sticker và có ID trống → hiển thị widget trong suốt chiều cao 150
            if hasEmptyIds {
                Color.clear
                    .frame(width: itemWidth, height: 150)
            } else if isSticker {
                // STICKER LAYOUT
                if isHanging {
                    // Sticker treo - hiển thị như pot treo
                    ZStack(alignment: .top) {
                        PotRiveView(
                            width: itemWidth * 1.0,
                            height: itemWidth + itemWidth * 0.2, // Chiều cao pot treo
                            potId: plantData?.idPot ?? "pot15"
                        )
                        .frame(maxWidth: .infinity)
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
                } else {
                    // Sticker không treo - chiều cao 155
                    VStack(spacing: 0) {
                        PotRiveView(
                            width: itemWidth,
                            height: 155, // Fixed height cho sticker không treo
                            potId: plantData?.idPot ?? "pot1"
                        )
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
                }
            } else if isHanging {
                // HANGING PLANT LAYOUT - Cây treo
                // Pot ở trên, Plant phủ xuống dưới
                ZStack(alignment: .top) {
                    // Pot ở trên cùng (topCenter)
                    PotRiveView(
                        width: itemWidth * 1.0,
                        height: itemWidth + itemWidth * 0.2, // Fixed height cho pot treo
                        potId: plantData?.idPot ?? "pot15"
                    )
                    .frame(maxWidth: .infinity)
                    
                    // Plant phủ xuống - full width
                    PlantRiveView(
                        width: itemWidth, // full width
                        height: itemWidth + itemWidth * 0.5, // Chiều cao như normal plant
                        plantId: plantData?.idPlant ?? "plant12",
                        plantLevel: plantData?.plantLevel ?? 3
                    )
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
            } else {
                // NORMAL PLANT LAYOUT
                VStack(spacing: 0) {
                    // Hiển thị Plant với idPlant từ data
                    PlantRiveView(
                        width: itemWidth,
                        height: itemWidth + itemWidth * 0.35,
                        plantId: plantData?.idPlant ?? "plant1",
                        plantLevel: plantData?.plantLevel ?? 1
                    )
                    
                    // Hiển thị Pot với idPot từ data
                    PotRiveView(
                        width: itemWidth,
                        height: itemWidth * 0.6,
                        potId: plantData?.idPot ?? "pot1"
                    )
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
            }
        }
        .customContextMenu(menuItems: isSticker ? [] : [
            MenuItem(title: "Tưới cây", icon: "drop.fill") {
                print("water at \(rowIndex),\(columnIndex)")
            },
            MenuItem(title: "Bón phân", icon: "leaf.fill") {
                print("fertilize at \(rowIndex),\(columnIndex)")
            },
            MenuItem(title: "Thu hoạch", icon: "basket.fill") {
                print("harvest at \(rowIndex),\(columnIndex)")
            },
            MenuItem(title: "Xóa", icon: "trash", role: .destructive) {
                print("remove at \(rowIndex),\(columnIndex)")
            },
        ])
    }
}
