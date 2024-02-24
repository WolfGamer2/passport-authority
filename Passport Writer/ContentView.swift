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
}

/// these secrets are fake, just for testing
var passports = [
    Passport(name: "Jack", surname: "Hogan", id: 1, secret: "2eV78TKypsBGgNZG7aX"),
    Passport(name: "Matthew", surname: "Stanciu", id: 12, secret: "Ot935wO9KEnV4fdFLGLxl")
]

struct PersonRowView: View {
    var passport: Passport

    var body: some View {
        VStack(alignment: .leading, spacing: 3) {
            Text(passport.name + " " + passport.surname)
                .foregroundColor(.primary)
                .font(.headline)
            HStack(spacing: 3) {
                Label(String(passport.id), systemImage: "person.text.rectangle.fill")
            }
            .foregroundColor(.secondary)
            .font(.subheadline)
        }
    }
}

struct StaffList: View {
    var body: some View {
        NavigationSplitView {
            List {
                ForEach(passports) { person in
                    NavigationLink {
                        SinglePassportView()
                    } label: {
                        PersonRowView(passport: person)
                    }
                }
            }
        } detail: {
            Text("idk")
        }
    }
}

struct ContentView: View {
    var body: some View {
        VStack {
            Image(systemName: "globe")
                .imageScale(.large)
                .foregroundStyle(.tint)
            Text("Hello, world!")
                .foregroundColor(.green)
        }
        .padding()
    }
}

#Preview {
    StaffList()
}
