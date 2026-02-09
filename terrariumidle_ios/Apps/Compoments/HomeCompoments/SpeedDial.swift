//
//  SpeedDial.swift
//  terrariumidle_ios
//
//  Created by vương quang huy on 8/2/26.
//


import SwiftUI

struct SpeedDial: View {
    @State private var isOpen = false
    @Binding var isEditing: Bool
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
                    DialItem(title: "Tưới cây", systemImage: "drop.fill",color: Color.blue) {
                        print("water")
                        close()
                    }
                    DialItem(title: "Phong cảnh", systemImage: "leaf.fill", color: Color.yellow) {
                        print("fertilize")
                        close()
                    }
                    DialItem(title: "Hiệu ứng", systemImage: "scissors", color: Color.orange) {
                        print("harvest")
                        close()
                    }
                    DialItem(title: "Cửa hàng", systemImage: "scissors", color: Color.orange) {
                        print("harvest")
                        router.push(.storeView)
                        close()
                    }
                    DialItem(title: "Sự kiện", systemImage: "scissors", color: Color.orange) {
                        print("harvest")
                        close()
                    }
                    DialItem(title: "Bố cục", systemImage: "scissors", color: Color.orange) {
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
                    .textStyle(.bodyMedium).foregroundColor(color)
                Image(systemName: systemImage)
                    .font(.system(size: 16, weight: .semibold)).foregroundColor(color)
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 10)
            .background(RoundedRectangle(cornerRadius: 14).fill(Color.white.opacity(0.7)))
            .shadow(radius: 3)
        }
        .buttonStyle(.plain)
        .transition(.move(edge: .trailing).combined(with: .opacity))
    }
}
