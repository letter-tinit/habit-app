//
//  BaseScreen.swift
//  Habit
//
//  Created by TiniT on 28/4/26.
//

import SwiftUI
import Combine

struct BaseScreen<Content: View>: View {
    // MARK: - ENUM
    enum BackgroundGradientType {
        case mintCyan
        case lightPink
        case mint
        case cyan
        case custom(LinearGradient)
    }
    
    private var backgroundHighlights: [Color] {
        switch backgroundType {
        case .mintCyan:
            [.turquoise, .skyBlue, .rosePink]
        case .mint:
            [.emeraldGreen, .turquoise, .goldenYellow]
        case .cyan:
            [.skyBlue, .turquoise, .royalBlue]
        case .lightPink:
            [.rosePink, .skyBlue, .sunsetOrange]
        case .custom:
            [.turquoise, .rosePink, .goldenYellow]
        }
    }
    
    private var customBackgroundWash: LinearGradient? {
        guard case let .custom(gradient) = backgroundType else {
            return nil
        }

        return gradient
    }

    // MARK: - Property
    @Binding private var title: String
    private var backgroundType: BackgroundGradientType
    private var content: () -> Content
    private var didTapOnTitle: (() -> Void)?
    
    init(
        _ title: Binding<String> = .constant(""),
        backgroundType: BackgroundGradientType = .cyan,
        @ViewBuilder content: @escaping () -> Content,
        didTapOnTitle: (() -> Void)? = nil
    ) {
        self._title = title
        self.backgroundType = backgroundType
        self.content = content
        self.didTapOnTitle = didTapOnTitle
    }
    
    var body: some View {
        ZStack {
            LiquidGlassBackdrop(
                highlights: backgroundHighlights,
                customWash: customBackgroundWash
            )
            
            content()
                .dismissKeyboardOnTap()
        }
        .toolbarTitleDisplayMode(.inline)
        .toolbar {
            if !title.isEmpty {
                ToolbarItem(placement: .title) {
                    Button {
                        didTapOnTitle?()
                    } label: {
                        Text(title)
                            .font(.headline)
                            .fontWeight(.semibold)
                            .fontDesign(.rounded)
                    }
                    .allowsHitTesting(didTapOnTitle != nil)
                }
            }
        }
    }
}

private struct LiquidGlassBackdrop: View {
    let highlights: [Color]
    let customWash: LinearGradient?
    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        ZStack {
            baseColor

            LinearGradient(
                colors: baseGradientColors,
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )

            MeshGradient(
                width: 3,
                height: 3,
                points: [
                    [0.0, 0.0], [0.5, 0.0], [1.0, 0.0],
                    [0.0, 0.44], [0.48, 0.36], [1.0, 0.52],
                    [0.0, 1.0], [0.58, 0.92], [1.0, 1.0]
                ],
                colors: [
                    meshTint(highlights[0], darkOpacity: 0.46, lightOpacity: 0.32),
                    meshNeutral,
                    meshTint(highlights[1], darkOpacity: 0.34, lightOpacity: 0.26),
                    meshBase,
                    meshTint(highlights[2], darkOpacity: 0.26, lightOpacity: 0.20),
                    meshBase,
                    meshTint(highlights[1], darkOpacity: 0.14, lightOpacity: 0.12),
                    meshBase,
                    meshTint(highlights[0], darkOpacity: 0.22, lightOpacity: 0.16)
                ]
            )
            .blur(radius: 18)
            .saturation(1.25)

            if let customWash {
                customWash
                    .blendMode(.screen)
                    .opacity(0.32)
            }

            LinearGradient(
                colors: [
                    Color.white.opacity(0.22),
                    Color.clear,
                    Color.white.opacity(0.04),
                    Color.clear
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .blendMode(.screen)
            .mask {
                Rectangle()
                    .rotationEffect(.degrees(-14))
                    .padding(.horizontal, -80)
            }
            .opacity(0.48)

            backdropShade
        }
        .ignoresSafeArea()
    }

    private var baseColor: Color {
        colorScheme == .dark ? .black : Color(red: 0.93, green: 0.96, blue: 0.99)
    }

    private var baseGradientColors: [Color] {
        if colorScheme == .dark {
            [
                Color(red: 0.14, green: 0.15, blue: 0.19),
                Color(red: 0.03, green: 0.03, blue: 0.05),
                .black
            ]
        } else {
            [
                Color.white,
                Color(red: 0.91, green: 0.96, blue: 0.99),
                Color(red: 0.97, green: 0.94, blue: 0.98)
            ]
        }
    }

    private var meshBase: Color {
        colorScheme == .dark ? .black : Color.white.opacity(0.72)
    }

    private var meshNeutral: Color {
        colorScheme == .dark ? Color.white.opacity(0.10) : Color.white.opacity(0.82)
    }

    private var backdropShade: Color {
        colorScheme == .dark ? Color.black.opacity(0.24) : Color.white.opacity(0.12)
    }

    private func meshTint(_ color: Color, darkOpacity: Double, lightOpacity: Double) -> Color {
        color.opacity(colorScheme == .dark ? darkOpacity : lightOpacity)
    }
}
