//
//  StatusView.swift
//  Passport Writer
//
//  Created by Matthew Stanciu on 2/24/24.
//

import SwiftUI

struct StatusTextView: View {
    let text: String
    let size: CGFloat
    let textColor: Color
    let borderColor: Color

    var body: some View {
        Text(text)
            .font(.system(size: size))
            .padding(EdgeInsets(top: 2, leading: 4, bottom: 2, trailing: 4))
            .foregroundColor(textColor)
            .clipShape(RoundedRectangle(cornerRadius: 5))
            .overlay(
                RoundedRectangle(cornerRadius: 5)
                    .stroke(borderColor, lineWidth: 1)
            )
    }
}

enum ActivationState {
    case notActivated, activated, superseded
    
    var text: String {
        switch self {
        case .notActivated:
            return "Not Activated"
        case .activated:
            return "Activated"
        case .superseded:
            return "Superseded"
        }
    }
    
    var color: Color {
        switch self {
        case .notActivated:
            return .yellow
        case .activated:
            return .green
        case .superseded:
            return .secondary
        }
    }
}

struct StatusView: View {
    let activation: ActivationState
    let size: CGFloat
    
    var body: some View {
        StatusTextView(text: activation.text, size: size, textColor: activation.color, borderColor: activation.color)
    }
}
