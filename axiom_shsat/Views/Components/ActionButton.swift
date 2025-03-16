import SwiftUI

struct ActionButton: View {
    // MARK: - Properties
    
    enum ButtonStyle {
        case primary
        case secondary
        case success
        case danger
        case ghost
        case outline
        case custom(background: Color, foreground: Color)
        
        var backgroundColor: Color {
            switch self {
            case .primary:
                return .blue
            case .secondary:
                return Color(.systemGray3)
            case .success:
                return .green
            case .danger:
                return .red
            case .ghost, .outline:
                return .clear
            case .custom(let background, _):
                return background
            }
        }
        
        var foregroundColor: Color {
            switch self {
            case .primary, .success, .danger:
                return .white
            case .secondary:
                return .primary
            case .ghost:
                return .blue
            case .outline:
                return .blue
            case .custom(_, let foreground):
                return foreground
            }
        }
        
        var border: Color? {
            switch self {
            case .outline:
                return .blue
            default:
                return nil
            }
        }
    }
    
    enum ButtonSize {
        case small
        case medium
        case large
        case custom(height: CGFloat, padding: EdgeInsets)
        
        var height: CGFloat {
            switch self {
            case .small:
                return 32
            case .medium:
                return 44
            case .large:
                return 56
            case .custom(let height, _):
                return height
            }
        }
        
        var padding: EdgeInsets {
            switch self {
            case .small:
                return EdgeInsets(top: 6, leading: 12, bottom: 6, trailing: 12)
            case .medium:
                return EdgeInsets(top: 10, leading: 16, bottom: 10, trailing: 16)
            case .large:
                return EdgeInsets(top: 12, leading: 24, bottom: 12, trailing: 24)
            case .custom(_, let padding):
                return padding
            }
        }
        
        var font: Font {
            switch self {
            case .small:
                return .caption
            case .medium:
                return .body
            case .large:
                return .headline
            case .custom:
                return .body
            }
        }
    }
    
    // Button properties
    let title: String
    let action: () -> Void
    let style: ButtonStyle
    let size: ButtonSize
    let icon: String?
    let iconPosition: IconPosition
    let isFullWidth: Bool
    let isLoading: Bool
    let isDisabled: Bool
    let cornerRadius: CGFloat
    
    enum IconPosition {
        case leading
        case trailing
    }
    
    // MARK: - Initializers
    
    init(
        title: String,
        action: @escaping () -> Void,
        style: ButtonStyle = .primary,
        size: ButtonSize = .medium,
        icon: String? = nil,
        iconPosition: IconPosition = .leading,
        isFullWidth: Bool = false,
        isLoading: Bool = false,
        isDisabled: Bool = false,
        cornerRadius: CGFloat = 10
    ) {
        self.title = title
        self.action = action
        self.style = style
        self.size = size
        self.icon = icon
        self.iconPosition = iconPosition
        self.isFullWidth = isFullWidth
        self.isLoading = isLoading
        self.isDisabled = isDisabled
        self.cornerRadius = cornerRadius
    }
    
    // MARK: - Body
    
    var body: some View {
        Button(action: {
            if !isLoading && !isDisabled {
                action()
            }
        }) {
            Group {
                if isLoading {
                    loadingContent
                } else {
                    buttonContent
                }
            }
            .frame(height: size.height)
            .padding(size.padding)
            .background(backgroundColor)
            .foregroundColor(foregroundColor)
            .cornerRadius(cornerRadius)
            .overlay(
                RoundedRectangle(cornerRadius: cornerRadius)
                    .stroke(borderColor, lineWidth: borderColor == .clear ? 0 : 1)
            )
            .frame(maxWidth: isFullWidth ? .infinity : nil)
        }
        .disabled(isDisabled || isLoading)
    }
    
    // MARK: - Helper Views
    
    private var buttonContent: some View {
        HStack(spacing: 8) {
            if let icon = icon, iconPosition == .leading {
                Image(systemName: icon)
                    .font(iconFont)
            }
            
            Text(title)
                .font(size.font)
                .fontWeight(style == .ghost ? .regular : .medium)
            
            if let icon = icon, iconPosition == .trailing {
                Image(systemName: icon)
                    .font(iconFont)
            }
        }
    }
    
    private var loadingContent: some View {
        HStack(spacing: 8) {
            ProgressView()
                .progressViewStyle(CircularProgressViewStyle(tint: foregroundColor))
                .scaleEffect(0.8)
            
            Text("Loading...")
                .font(size.font)
                .fontWeight(.medium)
        }
    }
    
    // MARK: - Computed Properties
    
    private var backgroundColor: Color {
        if isDisabled {
            return Color(.systemGray5)
        } else {
            return style.backgroundColor
        }
    }
    
    private var foregroundColor: Color {
        if isDisabled {
            return Color(.systemGray)
        } else {
            return style.foregroundColor
        }
    }
    
    private var borderColor: Color {
        if isDisabled {
            return .clear
        } else if let border = style.border {
            return border
        } else {
            return .clear
        }
    }
    
    private var iconFont: Font {
        switch size {
        case .small:
            return .system(size: 12)
        case .medium:
            return .system(size: 16)
        case .large:
            return .system(size: 20)
        case .custom:
            return .system(size: 16)
        }
    }
}

// MARK: - Convenience Initializers

extension ActionButton {
    init(
        title: String,
        action: @escaping () -> Void,
        style: ButtonStyle = .primary,
        size: ButtonSize = .medium,
        isFullWidth: Bool = false,
        isLoading: Bool = false,
        isDisabled: Bool = false
    ) {
        self.init(
            title: title,
            action: action,
            style: style,
            size: size,
            icon: nil,
            iconPosition: .leading,
            isFullWidth: isFullWidth,
            isLoading: isLoading,
            isDisabled: isDisabled
        )
    }
    
    // Button with leading icon
    static func withLeadingIcon(
        title: String,
        icon: String,
        action: @escaping () -> Void,
        style: ButtonStyle = .primary,
        size: ButtonSize = .medium,
        isFullWidth: Bool = false,
        isLoading: Bool = false,
        isDisabled: Bool = false
    ) -> ActionButton {
        ActionButton(
            title: title,
            action: action,
            style: style,
            size: size,
            icon: icon,
            iconPosition: .leading,
            isFullWidth: isFullWidth,
            isLoading: isLoading,
            isDisabled: isDisabled
        )
    }
    
    // Button with trailing icon
    static func withTrailingIcon(
        title: String,
        icon: String,
        action: @escaping () -> Void,
        style: ButtonStyle = .primary,
        size: ButtonSize = .medium,
        isFullWidth: Bool = false,
        isLoading: Bool = false,
        isDisabled: Bool = false
    ) -> ActionButton {
        ActionButton(
            title: title,
            action: action,
            style: style,
            size: size,
            icon: icon,
            iconPosition: .trailing,
            isFullWidth: isFullWidth,
            isLoading: isLoading,
            isDisabled: isDisabled
        )
    }
}

// MARK: - Additional Button Varieties

struct IconButton: View {
    let icon: String
    let action: () -> Void
    let style: ActionButton.ButtonStyle
    let size: CGFloat
    let isDisabled: Bool
    let isLoading: Bool
    
    init(
        icon: String,
        action: @escaping () -> Void,
        style: ActionButton.ButtonStyle = .primary,
        size: CGFloat = 44,
        isDisabled: Bool = false,
        isLoading: Bool = false
    ) {
        self.icon = icon
        self.action = action
        self.style = style
        self.size = size
        self.isDisabled = isDisabled
        self.isLoading = isLoading
    }
    
    var body: some View {
        Button(action: {
            if !isLoading && !isDisabled {
                action()
            }
        }) {
            ZStack {
                if isLoading {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle(tint: foregroundColor))
                } else {
                    Image(systemName: icon)
                        .font(.system(size: size / 2.5))
                }
            }
            .frame(width: size, height: size)
            .background(backgroundColor)
            .foregroundColor(foregroundColor)
            .cornerRadius(size / 2)
            .overlay(
                RoundedRectangle(cornerRadius: size / 2)
                    .stroke(borderColor, lineWidth: borderColor == .clear ? 0 : 1)
            )
        }
        .disabled(isDisabled || isLoading)
    }
    
    private var backgroundColor: Color {
        if isDisabled {
            return Color(.systemGray5)
        } else {
            return style.backgroundColor
        }
    }
    
    private var foregroundColor: Color {
        if isDisabled {
            return Color(.systemGray)
        } else {
            return style.foregroundColor
        }
    }
    
    private var borderColor: Color {
        if isDisabled {
            return .clear
        } else if let border = style.border {
            return border
        } else {
            return .clear
        }
    }
}

struct GradientButton: View {
    let title: String
    let action: () -> Void
    let gradient: LinearGradient
    let size: ActionButton.ButtonSize
    let icon: String?
    let iconPosition: ActionButton.IconPosition
    let isFullWidth: Bool
    let isLoading: Bool
    let isDisabled: Bool
    let cornerRadius: CGFloat
    
    init(
        title: String,
        action: @escaping () -> Void,
        colors: [Color] = [.blue, .purple],
        size: ActionButton.ButtonSize = .medium,
        icon: String? = nil,
        iconPosition: ActionButton.IconPosition = .leading,
        isFullWidth: Bool = false,
        isLoading: Bool = false,
        isDisabled: Bool = false,
        cornerRadius: CGFloat = 10
    ) {
        self.title = title
        self.action = action
        self.gradient = LinearGradient(
            gradient: Gradient(colors: colors),
            startPoint: .leading,
            endPoint: .trailing
        )
        self.size = size
        self.icon = icon
        self.iconPosition = iconPosition
        self.isFullWidth = isFullWidth
        self.isLoading = isLoading
        self.isDisabled = isDisabled
        self.cornerRadius = cornerRadius
    }
    
    var body: some View {
        Button(action: {
            if !isLoading && !isDisabled {
                action()
            }
        }) {
            Group {
                if isLoading {
                    HStack(spacing: 8) {
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle(tint: .white))
                            .scaleEffect(0.8)
                        
                        Text("Loading...")
                            .font(size.font)
                            .fontWeight(.medium)
                    }
                } else {
                    HStack(spacing: 8) {
                        if let icon = icon, iconPosition == .leading {
                            Image(systemName: icon)
                                .font(iconFont)
                        }
                        
                        Text(title)
                            .font(size.font)
                            .fontWeight(.medium)
                        
                        if let icon = icon, iconPosition == .trailing {
                            Image(systemName: icon)
                                .font(iconFont)
                        }
                    }
                }
            }
            .frame(height: size.height)
            .padding(size.padding)
            .frame(maxWidth: isFullWidth ? .infinity : nil)
            .foregroundColor(.white)
            .background(
                RoundedRectangle(cornerRadius: cornerRadius)
                    .fill(isDisabled ? Color(.systemGray4) : gradient)
            )
        }
        .disabled(isDisabled || isLoading)
    }
    
    private var iconFont: Font {
        switch size {
        case .small:
            return .system(size: 12)
        case .medium:
            return .system(size: 16)
        case .large:
            return .system(size: 20)
        case .custom:
            return .system(size: 16)
        }
    }
}

// MARK: - Previews

#Preview("Button Styles") {
    VStack(spacing: 20) {
        ActionButton(
            title: "Primary Button",
            action: {},
            style: .primary
        )
        
        ActionButton(
            title: "Secondary Button",
            action: {},
            style: .secondary
        )
        
        ActionButton(
            title: "Success Button",
            action: {},
            style: .success
        )
        
        ActionButton(
            title: "Danger Button",
            action: {},
            style: .danger
        )
        
        ActionButton(
            title: "Ghost Button",
            action: {},
            style: .ghost
        )
        
        ActionButton(
            title: "Outline Button",
            action: {},
            style: .outline
        )
        
        ActionButton(
            title: "Custom Button",
            action: {},
            style: .custom(background: .purple, foreground: .white)
        )
    }
    .padding()
}

#Preview("Button Sizes") {
    VStack(spacing: 20) {
        ActionButton(
            title: "Small Button",
            action: {},
            size: .small
        )
        
        ActionButton(
            title: "Medium Button",
            action: {},
            size: .medium
        )
        
        ActionButton(
            title: "Large Button",
            action: {},
            size: .large
        )
        
        ActionButton(
            title: "Full Width Button",
            action: {},
            isFullWidth: true
        )
        
        ActionButton(
            title: "Custom Size Button",
            action: {},
            size: .custom(
                height: 60,
                padding: EdgeInsets(top: 15, leading: 30, bottom: 15, trailing: 30)
            )
        )
    }
    .padding()
}

#Preview("Button with Icons") {
    VStack(spacing: 20) {
        ActionButton.withLeadingIcon(
            title: "Leading Icon",
            icon: "plus",
            action: {}
        )
        
        ActionButton.withTrailingIcon(
            title: "Trailing Icon",
            icon: "arrow.right",
            action: {}
        )
        
        HStack {
            IconButton(
                icon: "plus",
                action: {}
            )
            
            IconButton(
                icon: "trash",
                action: {},
                style: .danger
            )
            
            IconButton(
                icon: "checkmark",
                action: {},
                style: .success
            )
        }
        
        GradientButton(
            title: "Gradient Button",
            action: {}
        )
        
        GradientButton(
            title: "Custom Gradient",
            action: {},
            colors: [.red, .orange, .yellow],
            icon: "star.fill",
            isFullWidth: true
        )
    }
    .padding()
}

#Preview("Button States") {
    VStack(spacing: 20) {
        ActionButton(
            title: "Normal Button",
            action: {}
        )
        
        ActionButton(
            title: "Loading Button",
            action: {},
            isLoading: true
        )
        
        ActionButton(
            title: "Disabled Button",
            action: {},
            isDisabled: true
        )
        
        GradientButton(
            title: "Disabled Gradient",
            action: {},
            isDisabled: true
        )
    }
    .padding()
}
