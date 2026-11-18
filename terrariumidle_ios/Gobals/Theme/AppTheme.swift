//
//  AppTheme.swift
//  AI.Wallet
//
//  Created by AI.Wallet on 18/12/25.
//

import SwiftUI

// MARK: - App Colors
struct AppColors {
    // Primary Colors (from logo - teal to emerald gradient)
    static let primary = Color(hex: "2d6824")         // Emerald Green
    static let primaryLight = Color(hex: "34D399")    // Light Emerald
    static let primaryDark = Color(hex: "059669")     // Dark Emerald
    
    // Secondary Colors (teal/mint from logo)
    static let secondary = Color(hex: "14B8A6")       // Teal
    static let secondaryLight = Color(hex: "5EEAD4")  // Light Teal/Mint
    static let secondaryDark = Color(hex: "0D9488")   // Dark Teal
    
    // Accent Colors (using primary for consistency)
    static let accent = Color(hex: "10B981")          // Emerald
    static let accentLight = Color(hex: "10B981").opacity(0.2)
    
    // Background Colors
    static let background = Color(.systemGray6)
    static let backgroundLogin = Color(hex: "faf3e1")
    static let cardBackground = Color.white
    static let secondaryBackground = Color(.systemGray5)
    
    // Text Colors
    static let textPrimary = Color.primary
    static let textSecondary = Color.gray
    static let textMuted = Color(.systemGray3)
    static let textOnPrimary = Color.white            // Text on primary color
    
    // Status Colors
    static let success = Color(hex: "10B981")         // Use primary green
    static let warning = Color.orange
    static let error = Color.red
    static let info = Color.blue
    
    // Category Colors
    struct Category {
        static let food = Color(hex: "F59E0B")        // Amber - Ăn uống
        static let transport = Color(hex: "14B8A6")   // Teal - Di chuyển
        static let shopping = Color(hex: "8B5CF6")    // Purple - Mua sắm
        static let entertainment = Color(hex: "EC4899") // Pink - Giải trí
        static let bills = Color(hex: "F97316")       // Orange - Hóa đơn
        static let health = Color(hex: "EF4444")      // Red - Sức khỏe
        static let education = Color(hex: "3B82F6")   // Blue - Giáo dục
        static let savings = Color(hex: "10B981")     // Emerald - Tiết kiệm
        static let other = Color(hex: "6B7280")       // Gray - Khác
    }
    
    // Gradient Colors (matching logo)
    struct Gradient {
        static let primary = LinearGradient(
            colors: [Color(hex: "5EEAD4"), Color(hex: "10B981")],  // Mint to Emerald
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
        
        static let secondary = LinearGradient(
            colors: [Color(hex: "14B8A6"), Color(hex: "059669")],  // Teal to Dark Emerald
            startPoint: .top,
            endPoint: .bottom
        )
        
        static let card = LinearGradient(
            colors: [Color.white, Color(.systemGray6)],
            startPoint: .top,
            endPoint: .bottom
        )
        
        static let hero = LinearGradient(
            colors: [Color(hex: "5EEAD4"), Color(hex: "10B981"), Color(hex: "059669")],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }
}

// MARK: - App Typography
struct AppTypography {
    // Headings
    static let largeTitle = Font.largeTitle.weight(.bold)
    static let title1 = Font.title.weight(.bold)
    static let title2 = Font.title2.weight(.semibold)
    static let title3 = Font.title3.weight(.semibold)
    
    // Body
    static let bodyLarge = Font.body.weight(.regular)
    static let bodyMedium = Font.subheadline.weight(.regular)
    static let bodySmall = Font.footnote.weight(.regular)
    
    // Labels
    static let labelLarge = Font.headline.weight(.semibold)
    static let labelMedium = Font.subheadline.weight(.medium)
    static let labelSmall = Font.caption.weight(.medium)
    
    // Caption
    static let caption1 = Font.caption.weight(.regular)
    static let caption2 = Font.caption2.weight(.regular)
}

// MARK: - App Spacing
struct AppSpacing {
    static let xxxs: CGFloat = 2
    static let xxs: CGFloat = 4
    static let xs: CGFloat = 8
    static let sm: CGFloat = 12
    static let md: CGFloat = 16
    static let lg: CGFloat = 20
    static let xl: CGFloat = 24
    static let xxl: CGFloat = 32
    static let xxxl: CGFloat = 40
}

// MARK: - App Corner Radius
struct AppCornerRadius {
    static let xs: CGFloat = 4
    static let sm: CGFloat = 8
    static let md: CGFloat = 12
    static let lg: CGFloat = 16
    static let xl: CGFloat = 20
    static let xxl: CGFloat = 24
    static let full: CGFloat = 9999
}

// MARK: - App Shadows
struct AppShadow {
    static let small = Color.black.opacity(0.03)
    static let medium = Color.black.opacity(0.05)
    static let large = Color.black.opacity(0.1)
    
    static let smallRadius: CGFloat = 5
    static let mediumRadius: CGFloat = 10
    static let largeRadius: CGFloat = 20
}

// MARK: - App Icon Sizes
struct AppIconSize {
    static let xs: CGFloat = 16
    static let sm: CGFloat = 20
    static let md: CGFloat = 24
    static let lg: CGFloat = 32
    static let xl: CGFloat = 44
    static let xxl: CGFloat = 56
}

// MARK: - View Extensions
extension View {
    func cardStyle() -> some View {
        self
            .padding(AppSpacing.md)
            .background(AppColors.cardBackground)
            .cornerRadius(AppCornerRadius.lg)
            .shadow(color: AppShadow.medium, radius: AppShadow.mediumRadius)
    }
    
    func primaryButtonStyle() -> some View {
        self
            .font(AppTypography.labelMedium)
            .foregroundColor(.black)
            .padding(.horizontal, AppSpacing.md)
            .padding(.vertical, AppSpacing.xs)
            .background(AppColors.accent)
            .clipShape(Capsule())
    }
    
    func secondaryButtonStyle() -> some View {
        self
            .font(AppTypography.labelMedium)
            .foregroundColor(AppColors.textSecondary)
            .padding(.horizontal, AppSpacing.md)
            .padding(.vertical, AppSpacing.xs)
            .background(AppColors.secondaryBackground)
            .clipShape(Capsule())
    }
    
    func iconButton(size: CGFloat = AppIconSize.xl, background: Color = AppColors.cardBackground) -> some View {
        self
            .frame(width: size, height: size)
            .background(background)
            .clipShape(Circle())
            .shadow(color: AppShadow.small, radius: AppShadow.smallRadius)
    }
}

// MARK: - Color Extensions
extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3: // RGB (12-bit)
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6: // RGB (24-bit)
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8: // ARGB (32-bit)
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (255, 0, 0, 0)
        }
        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue: Double(b) / 255,
            opacity: Double(a) / 255
        )
    }
}
