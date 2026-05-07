//
//  Color+Extension.swift
//  Habit
//
//  Created by TiniT on 28/4/26.
//

import SwiftUI

extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        
        let a, r, g, b: UInt64
        switch hex.count {
        case 3: // RGB (12-bit)
            (a, r, g, b) = (255,
                            (int >> 8) * 17,
                            (int >> 4 & 0xF) * 17,
                            (int & 0xF) * 17)
        case 6: // RGB (24-bit)
            (a, r, g, b) = (255,
                            int >> 16,
                            int >> 8 & 0xFF,
                            int & 0xFF)
        case 8: // ARGB (32-bit)
            (a, r, g, b) = (int >> 24,
                            int >> 16 & 0xFF,
                            int >> 8 & 0xFF,
                            int & 0xFF)
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
    
    // Blues
    static let skyBlue = Color(hex: "#87CEEB")
    static let royalBlue = Color(hex: "#4169E1")
    static let midnightBlue = Color(hex: "#191970")
    static let iceBlue = Color(hex: "#D6F6FF")
    
    // Greens
    static let emeraldGreen = Color(hex: "#50C878")
    static let forestGreen = Color(hex: "#228B22")
    static let limeGreen = Color(hex: "#32CD32")
    static let sageGreen = Color(hex: "#9CAF88")
    
    // Reds / Pinks
    static let rubyRed = Color(hex: "#E0115F")
    static let rosePink = Color(hex: "#FF66B2")
    static let blushPink = Color(hex: "#F8C8DC")
    static let crimsonRed = Color(hex: "#DC143C")
    
    // Oranges / Yellows
    static let sunsetOrange = Color(hex: "#FD5E53")
    static let peachOrange = Color(hex: "#FFCBA4")
    static let goldenYellow = Color(hex: "#FFD700")
    static let mustardYellow = Color(hex: "#E1AD01")
    
    // Purples
    static let lavenderPurple = Color(hex: "#E6E6FA")
    static let deepPurple = Color(hex: "#673AB7")
    static let violetPurple = Color(hex: "#8F00FF")
    static let plumPurple = Color(hex: "#8E4585")
    
    // Neutral
    static let charcoalGray = Color(hex: "#36454F")
    static let warmGray = Color(hex: "#A89F91")
    static let creamWhite = Color(hex: "#FFFDD0")
    static let richBlack = Color(hex: "#0D0D0D")
    
    // Teal / Cyan
    static let oceanTeal = Color(hex: "#008080")
    static let aquaCyan = Color(hex: "#00FFFF")
    static let turquoise = Color(hex: "#40E0D0")
    
    // Brown
    static let coffeeBrown = Color(hex: "#6F4E37")
    static let caramelBrown = Color(hex: "#C68E17")
    static let chocolateBrown = Color(hex: "#7B3F00")
}

