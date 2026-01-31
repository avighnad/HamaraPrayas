//
//  HapticManager.swift
//  HamaraPrayas_build
//
//  Created by Avighna Daruka on 31/01/26.
//

import SwiftUI
import UIKit

/// A centralized manager for haptic feedback throughout the app
final class HapticManager {
    
    static let shared = HapticManager()
    
    private init() {}
    
    // MARK: - Impact Feedback
    
    /// Light impact - for subtle UI interactions like toggles, small buttons
    func lightImpact() {
        let generator = UIImpactFeedbackGenerator(style: .light)
        generator.prepare()
        generator.impactOccurred()
    }
    
    /// Medium impact - for standard button taps, selections
    func mediumImpact() {
        let generator = UIImpactFeedbackGenerator(style: .medium)
        generator.prepare()
        generator.impactOccurred()
    }
    
    /// Heavy impact - for significant actions like submit, confirm
    func heavyImpact() {
        let generator = UIImpactFeedbackGenerator(style: .heavy)
        generator.prepare()
        generator.impactOccurred()
    }
    
    /// Soft impact - for gentle feedback
    func softImpact() {
        let generator = UIImpactFeedbackGenerator(style: .soft)
        generator.prepare()
        generator.impactOccurred()
    }
    
    /// Rigid impact - for firm feedback
    func rigidImpact() {
        let generator = UIImpactFeedbackGenerator(style: .rigid)
        generator.prepare()
        generator.impactOccurred()
    }
    
    // MARK: - Notification Feedback
    
    /// Success feedback - for successful operations (login, submission complete)
    func success() {
        let generator = UINotificationFeedbackGenerator()
        generator.prepare()
        generator.notificationOccurred(.success)
    }
    
    /// Warning feedback - for warnings or caution states
    func warning() {
        let generator = UINotificationFeedbackGenerator()
        generator.prepare()
        generator.notificationOccurred(.warning)
    }
    
    /// Error feedback - for errors or failed operations
    func error() {
        let generator = UINotificationFeedbackGenerator()
        generator.prepare()
        generator.notificationOccurred(.error)
    }
    
    // MARK: - Selection Feedback
    
    /// Selection changed - for picker changes, tab switches, segment changes
    func selectionChanged() {
        let generator = UISelectionFeedbackGenerator()
        generator.prepare()
        generator.selectionChanged()
    }
    
    // MARK: - Custom Patterns
    
    /// Double tap pattern - two quick light impacts
    func doubleTap() {
        lightImpact()
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) { [weak self] in
            self?.lightImpact()
        }
    }
    
    /// Celebration pattern - for achievements, milestones
    func celebration() {
        success()
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) { [weak self] in
            self?.mediumImpact()
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) { [weak self] in
            self?.lightImpact()
        }
    }
    
    /// Emergency pattern - for urgent actions
    func emergency() {
        heavyImpact()
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) { [weak self] in
            self?.heavyImpact()
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) { [weak self] in
            self?.heavyImpact()
        }
    }
}

// MARK: - SwiftUI View Extension for Easy Haptics

extension View {
    /// Adds haptic feedback on tap
    func hapticOnTap(_ style: HapticStyle = .medium) -> some View {
        self.simultaneousGesture(
            TapGesture().onEnded { _ in
                switch style {
                case .light:
                    HapticManager.shared.lightImpact()
                case .medium:
                    HapticManager.shared.mediumImpact()
                case .heavy:
                    HapticManager.shared.heavyImpact()
                case .success:
                    HapticManager.shared.success()
                case .warning:
                    HapticManager.shared.warning()
                case .error:
                    HapticManager.shared.error()
                case .selection:
                    HapticManager.shared.selectionChanged()
                }
            }
        )
    }
}

enum HapticStyle {
    case light
    case medium
    case heavy
    case success
    case warning
    case error
    case selection
}
