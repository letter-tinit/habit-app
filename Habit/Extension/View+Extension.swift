//
//  View+Extension.swift
//  Habit
//
//  Created by TiniT on 29/4/26.
//

import SwiftUI

extension View {
    func baseAnimation(_ changes: @escaping () -> Void) {
        withAnimation(.spring(duration: 0.3)) {
            changes()
        }
    }
    
    func clearDefaultConfigure() -> some View {
        self
            .listRowBackground(Color.clear)
            .listRowSeparator(.hidden)
    }
    
    func dismissKeyboardOnTap() -> some View {
        self.onTapGesture {
            UIApplication.shared.dismissKeyboard()
        }
    }

    func liquidGlassSurface(
        cornerRadius: CGFloat = 18,
        interactive: Bool = false
    ) -> some View {
        modifier(
            LiquidGlassSurfaceModifier(
                cornerRadius: cornerRadius,
                interactive: interactive
            )
        )
    }

}

private struct LiquidGlassSurfaceModifier: ViewModifier {
    let cornerRadius: CGFloat
    let interactive: Bool
    @Environment(\.colorScheme) private var colorScheme
    
    @ViewBuilder
    func body(content: Content) -> some View {
        if interactive {
            surface(content)
                .glassEffect(.regular.interactive(), in: .rect(cornerRadius: cornerRadius))
        } else {
            surface(content)
                .glassEffect(.regular, in: .rect(cornerRadius: cornerRadius))
        }
    }

    private func surface(_ content: Content) -> some View {
        content
            .background {
                RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                    .fill(surfaceFill)
                    .overlay {
                        RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                            .fill(
                                LinearGradient(
                                    colors: surfaceHighlights,
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                    }
            }
            .overlay {
                RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                    .strokeBorder(surfaceStroke, lineWidth: 0.8)
            }
            .shadow(color: surfaceShadow, radius: 16, y: 10)
    }

    private var surfaceFill: Color {
        colorScheme == .dark ? Color.white.opacity(0.035) : Color.white.opacity(0.20)
    }

    private var surfaceHighlights: [Color] {
        if colorScheme == .dark {
            [Color.white.opacity(0.16), .clear, Color.white.opacity(0.03)]
        } else {
            [Color.white.opacity(0.72), Color.white.opacity(0.08), Color.black.opacity(0.03)]
        }
    }

    private var surfaceStroke: Color {
        colorScheme == .dark ? Color.white.opacity(0.18) : Color.white.opacity(0.62)
    }

    private var surfaceShadow: Color {
        colorScheme == .dark ? Color.black.opacity(0.34) : Color.black.opacity(0.12)
    }
}

struct AppList<Content: View>: View {
    let content: Content
    
    init(@ViewBuilder content: () -> Content) {
        self.content = content()
    }
    
    var body: some View {
        List {
            content
                .listRowInsets(EdgeInsets(top: 0, leading: 0, bottom: 0, trailing: 0))
                .listRowBackground(Color.clear)
                .listRowSeparator(.hidden)
        }
        .listStyle(.plain)
        .scrollContentBackground(.hidden)
        .background(Color.clear)
        .scrollBounceBehavior(.basedOnSize)
    }
}
