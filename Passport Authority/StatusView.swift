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
            .background(Color.black)
            .clipShape(RoundedRectangle(cornerRadius: 5))
            .overlay(
                RoundedRectangle(cornerRadius: 5)
                    .stroke(borderColor, lineWidth: 1)
            )
    }
}

struct StatusView: View {
    let activated: Bool
    let size: CGFloat
    
    var body: some View {
        if activated {
            StatusTextView(text: "Activated", size: size, textColor: Color.green, borderColor: Color.green)
        } else {
            StatusTextView(text: "Not Activated", size: size, textColor: Color.yellow, borderColor: Color.yellow)
        }
    }
}
