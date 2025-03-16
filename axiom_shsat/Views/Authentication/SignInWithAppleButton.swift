//
//  SignInWithAppleButton.swift
//  axiom_shsat
//
//  Created by Imran Ahmed on 3/16/25.
//


import SwiftUI
import AuthenticationServices

struct SignInWithAppleButton: View {
    let onCompletion: (Result<ASAuthorization, Error>) -> Void
    var buttonStyle: ASAuthorizationAppleIDButton.Style = .white
    var buttonType: ASAuthorizationAppleIDButton.ButtonType = .signIn
    var cornerRadius: CGFloat = 10
    
    var body: some View {
        SignInWithAppleButtonRepresentable(
            buttonStyle: buttonStyle,
            buttonType: buttonType,
            cornerRadius: cornerRadius,
            onCompletion: onCompletion
        )
        .frame(height: 50)
        .accessibility(label: Text("Sign in with Apple"))
    }
}

struct SignInWithAppleButtonRepresentable: UIViewRepresentable {
    let buttonStyle: ASAuthorizationAppleIDButton.Style
    let buttonType: ASAuthorizationAppleIDButton.ButtonType
    let cornerRadius: CGFloat
    let onCompletion: (Result<ASAuthorization, Error>) -> Void
    
    func makeUIView(context: Context) -> ASAuthorizationAppleIDButton {
        let button = ASAuthorizationAppleIDButton(type: buttonType, style: buttonStyle)
        button.cornerRadius = cornerRadius
        button.addTarget(
            context.coordinator,
            action: #selector(Coordinator.buttonTapped),
            for: .touchUpInside
        )
        return button
    }
    
    func updateUIView(_ uiView: ASAuthorizationAppleIDButton, context: Context) {}
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    class Coordinator: NSObject, ASAuthorizationControllerDelegate, ASAuthorizationControllerPresentationContextProviding {
        let parent: SignInWithAppleButtonRepresentable
        
        init(_ parent: SignInWithAppleButtonRepresentable) {
            self.parent = parent
        }
        
        @objc func buttonTapped() {
            let appleIDProvider = ASAuthorizationAppleIDProvider()
            let request = appleIDProvider.createRequest()
            request.requestedScopes = [.fullName, .email]
            
            let authorizationController = ASAuthorizationController(authorizationRequests: [request])
            authorizationController.delegate = self
            authorizationController.presentationContextProvider = self
            authorizationController.performRequests()
        }
        
        func authorizationController(controller: ASAuthorizationController, didCompleteWithAuthorization authorization: ASAuthorization) {
            parent.onCompletion(.success(authorization))
        }
        
        func authorizationController(controller: ASAuthorizationController, didCompleteWithError error: Error) {
            parent.onCompletion(.failure(error))
        }
        
        func presentationAnchor(for controller: ASAuthorizationController) -> ASPresentationAnchor {
            let scenes = UIApplication.shared.connectedScenes
            let windowScene = scenes.first as? UIWindowScene
            let window = windowScene?.windows.first
            return window ?? UIWindow()
        }
    }
}

struct SignInWithAppleButtonStyle {
    enum ButtonColor {
        case white
        case black
        
        var appleButtonStyle: ASAuthorizationAppleIDButton.Style {
            switch self {
            case .white: return .white
            case .black: return .black
            }
        }
    }
}

extension View {
    func signInWithAppleButtonStyle(_ style: SignInWithAppleButtonStyle.ButtonColor) -> some View {
        self.environment(\.signInWithAppleButtonStyle, style.appleButtonStyle)
    }
}

private struct SignInWithAppleButtonStyleKey: EnvironmentKey {
    static let defaultValue = ASAuthorizationAppleIDButton.Style.white
}

extension EnvironmentValues {
    var signInWithAppleButtonStyle: ASAuthorizationAppleIDButton.Style {
        get { self[SignInWithAppleButtonStyleKey.self] }
        set { self[SignInWithAppleButtonStyleKey.self] = newValue }
    }
}

#Preview {
    VStack {
        SignInWithAppleButton { result in
            print("Sign in result: \(result)")
        }
        .padding()
        
        SignInWithAppleButton(
            onCompletion: { _ in },
            buttonStyle: .black,
            buttonType: .continue
        )
        .padding()
    }
    .padding()
    .background(Color.gray.opacity(0.2))
    .previewLayout(.sizeThatFits)
}
