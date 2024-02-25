//
//  ContentView.swift
//  Passport Writer
//
//  Created by Matthew Stanciu on 2/24/24.
//

import SwiftUI

class PassportViewModel: ObservableObject {
    @Published var passports = [Passport]()
    
    func load() {
        fetchData { [weak self] data in
            DispatchQueue.main.async {
                self?.passports = data ?? []
            }
        }
    }
}

struct PassportRowView: View {
    var passport: Passport

    var body: some View {
        VStack(alignment: .leading, spacing: 3) {
            Text("\(passport.name) \(passport.surname)")
                .foregroundColor(.primary)
                .font(.headline)
            HStack(spacing: 22) {
                Label(String(passport.id), systemImage: "person.text.rectangle.fill")
                StatusView(activated: passport.activated, size: 12)
            }
            .foregroundColor(.secondary)
            .font(.subheadline)
        }
    }
}

struct PassportListView: View {
    @StateObject private var viewModel = PassportViewModel()
    
    var body: some View {
        NavigationSplitView {
            List {
                ForEach(viewModel.passports) { passport in
                    NavigationLink {
                        PassportDetailView(passport: passport)
                    } label: {
                        PassportRowView(passport: passport)
                    }
                }
            }
        } detail: {
            Text("Passport details")
        }.onAppear {
            viewModel.load()
        }
    }
}

#Preview {
    PassportListView()
}
