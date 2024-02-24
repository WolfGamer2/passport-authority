//
//  StatusView.swift
//  Passport Writer
//
//  Created by Matthew Stanciu on 2/24/24.
//

import SwiftUI

struct StatusTextView: View {
    let text: String
    let textColor: Color
    let borderColor: Color

    var body: some View {
        Text(text)
            .font(.system(size: 12))
            .padding(EdgeInsets(top: 2, leading: 4, bottom: 2, trailing: 4))
            .foregroundColor(textColor)
            .background(Color.white)
            .clipShape(RoundedRectangle(cornerRadius: 5))
            .overlay(
                RoundedRectangle(cornerRadius: 5)
                    .stroke(borderColor, lineWidth: 1)
            )
    }
}
