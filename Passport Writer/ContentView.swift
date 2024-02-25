//
//  ContentView.swift
//  Passport Writer
//
//  Created by Matthew Stanciu on 2/24/24.
//

import SwiftUI
struct Passport: Identifiable {
    let name: String
    let surname: String
    let id: Int32
    let secret: String
    let activated: Bool
}

/// these secrets are fake, just for testing
var passports = [
    Passport(name: "Jack", surname: "Hogan", id: 1, secret: "2eV78TKypsBGgNZG7aX", activated: true),
    Passport(name: "Matthew", surname: "Stanciu", id: 12, secret: "Ot935wO9KEnV4fdFLGLxl", activated: false)
]

struct PassportRowView: View {
    var passport: Passport

    var body: some View {
        VStack(alignment: .leading, spacing: 3) {
            Text(passport.name + " " + passport.surname)
                .foregroundColor(.primary)
                .font(.headline)
            HStack(spacing: 22) {
                Label(String(passport.id), systemImage: "person.text.rectangle.fill")
                if passport.activated {
                    StatusTextView(text: "Activated", textColor: Color.green, borderColor: Color.green)
                } else {
                    StatusTextView(text: "Not Activated", textColor: Color.red, borderColor: Color.red)
                }
            }
            .foregroundColor(.secondary)
            .font(.subheadline)
        }
    }
}

struct PassportListView: View {
    var body: some View {
        NavigationSplitView {
            List {
                ForEach(passports) { passport in
                    NavigationLink {
                        SinglePassportView(passport: passport)
                    } label: {
                        PassportRowView(passport: passport)
                    }
                }
            }
        } detail: {
            Text("Passport details")
        }
    }
}

#Preview {
    PassportListView()
}
