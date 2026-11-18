//
//  SpeedDial.swift
//  terrariumidle_ios
//
//  Created by vương quang huy on 8/2/26.
//

import SwiftUI

struct SpeedDial: View {
    @State private var isOpen = false
    @State private var showMusicSheet = false
    @State private var showEffectsSheet = false
    @Binding var isEditing: Bool
    @Binding var backgroundRive: String
    @Binding var overlayRive: String?
    @EnvironmentObject var router: AppRouter

    var body: some View {
        ZStack(alignment: .bottomTrailing) {
            // nền mờ để bấm ra ngoài đóng lại
            if isOpen {
                Color.black.opacity(0.25)
                    .ignoresSafeArea()
                    .onTapGesture { withAnimation(.spring()) { isOpen = false } }
            }

            VStack(alignment: .trailing, spacing: 12) {
                if isOpen {
//                    DialItem(title: "Tưới cây", systemImage: "drop.fill", color: Color.blue) {
//                        print("water")
//                        close()
//                    }
                    DialItem(title: "Phong cảnh", systemImage: "sun.max", color: Color.brown) {
                        showEffectsSheet = true
                        close()
                    }
                    DialItem(title: "Âm nhạc", systemImage: "music.note", color: Color.orange) {
                        showMusicSheet = true
                        close()
                    }
                    DialItem(title: "Cửa hàng", systemImage: "camera.macro", color: Color.green) {
                        print("harvest")
                        router.push(.storeView)
                        close()
                    }
                    DialItem(title: "Sự kiện", systemImage: "carrot.fill", color: Color.purple) {
                        print("harvest")
                        close()
                    }
                    DialItem(title: "Bố cục", systemImage: "environments.fill", color: Color.blue) {
                        isEditing.toggle()
                        close()
                    }
                }

                Button {
                    withAnimation(.spring(response: 0.25, dampingFraction: 0.75)) {
                        isOpen.toggle()
                    }
                } label: {
                    Image(systemName: "plus")
                        .font(.system(size: 20, weight: .bold))
                        .rotationEffect(.degrees(isOpen ? 45 : 0))
                        .foregroundColor(.white)
                        .frame(width: 56, height: 56)
                        .background(Circle().fill(Color.green.opacity(0.3)))
                        .shadow(radius: 6)
                }
            }
            .padding(16)
            .sheet(isPresented: $showMusicSheet) {
                MusicSheetView()
            }
            .sheet(isPresented: $showEffectsSheet) {
                EffectsSheetView(backgroundRive: $backgroundRive, overlayRive: $overlayRive)
            }
        }
    }

    private func close() {
        withAnimation(.spring()) { isOpen = false }
    }
}

private struct DialItem: View {
    let title: String
    let systemImage: String
    let color: Color?
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 10) {
                Text(title)
                    .textStyle(.bodyMedium).foregroundColor(color).fontWeight(.bold)
                Image(systemName: systemImage)
                    .font(.system(size: 16, weight: .semibold)).foregroundColor(color)
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 10)
            .background(RoundedRectangle(cornerRadius: 14).fill(Color.white.opacity(0.9)))
            .shadow(radius: 1)
        }
        .buttonStyle(.plain)
        .transition(.move(edge: .trailing).combined(with: .opacity))
    }
}
