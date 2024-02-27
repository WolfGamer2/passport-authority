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
            HStack(spacing: 16) {
                HStack(spacing: 4) {
                    Image(systemName: "person.text.rectangle.fill")
                    Text(String(passport.id))
                }
                StatusView(activated: passport.activated, size: 12)
            }
            .foregroundColor(.secondary)
            .font(.subheadline)
        }
    }
}

struct SkeletonView: View {
    var body: some View {
        List {
            ForEach(1...11, id: \.self) { i in
                VStack(alignment: .leading, spacing: 3) {
                    Text("Loading").font(.headline)
                    Text("Loading longer").font(.headline)
                }
            }
        }.redacted(reason: .placeholder)
            .navigationTitle("Passports")
    }
}

struct PassportListView: View {
    @StateObject private var viewModel = PassportViewModel()
    
    @State private var searchText: String = ""
    
    var filteredPassports: [Passport] {
        if searchText.isEmpty {
            return viewModel.passports
        } else {
            return viewModel.passports.filter { passport in
                passport.name.lowercased().contains(searchText.lowercased()) ||
                passport.surname.lowercased().contains(searchText.lowercased()) ||
                "\(passport.id)".contains(searchText)
            }
        }
    }
    
    var body: some View {
        NavigationStack {
            if viewModel.passports == [] {
                SkeletonView()
            } else {
                List {
                    ForEach(filteredPassports) { passport in
                        NavigationLink {
                            PassportDetailView(passport: passport, viewModel: viewModel)
                                .navigationBarTitleDisplayMode(.inline)
                        } label: {
                            PassportRowView(passport: passport)
                        }
                    }
                }
                .refreshable {
                    viewModel.load()
                }
                .navigationTitle("Passports")
            }
        }.onAppear {
            viewModel.load()
        }
        .searchable(text: $searchText)
        .autocorrectionDisabled(true)
    }
}

#Preview {
    PassportListView()
}
