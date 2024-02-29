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
    enum SortOption: String, CaseIterable {
        case idAscending = "Ascending"
        case idDescending = "Descending"
        
        var id: String { self.rawValue }
    }
    
    enum StatusOption: String, CaseIterable {
        case all = "All"
        case activated = "Activated"
        case notActivated = "Not Activated"
        
        var id: String { self.rawValue }
        
        var icon: String {
            switch self {
            case .all:
                "bolt"
            case .activated:
                "bolt.fill"
            case .notActivated:
                "bolt.slash.fill"
            }
        }
    }
    
    @StateObject private var viewModel = PassportViewModel()
    
    @State private var searchText: String = ""
    @State private var sortOption: SortOption = .idAscending
    @State private var statusOption: StatusOption = .all
    @State private var activationColor: Color = .secondary
    
    var filteredPassports: [Passport] {
        var viewModelPassports = viewModel.passports
        
        switch sortOption {
        case .idAscending:
            viewModelPassports = viewModel.passports.sorted { $0.id < $1.id }
        case .idDescending:
            viewModelPassports = viewModel.passports.sorted { $0.id > $1.id }
        }
        
        switch statusOption {
        case .activated:
            viewModelPassports = viewModelPassports.filter { $0.activated }
        case .notActivated:
            viewModelPassports = viewModelPassports.filter { !$0.activated }
        case .all:
            break
        }
        
        if searchText.isEmpty {
            return viewModelPassports
        } else {
            return viewModelPassports.filter { passport in
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
                        .id(passport.id)
                    }
                }
                .animation(.easeInOut, value: filteredPassports)
                .refreshable {
                    viewModel.load()
                }
                .navigationTitle("Passports")
                .toolbar {
                    ToolbarItemGroup {
                        Button("Sort", image: ImageResource(name: sortOption == .idAscending ? "NumberUp" : "NumberDown", bundle: Bundle.main), action: {
                            sortOption = sortOption == .idAscending ? .idDescending : .idAscending
                        })
                        Picker("Activation", systemImage: statusOption.icon, selection: $statusOption, content: {
                            ForEach(StatusOption.allCases, id: \.self) { option in
                                Label(option.rawValue, systemImage: option.icon).tag(option)
                            }
                        })
                    }
                }
            }
        }.onAppear {
            viewModel.load()
        }
        .searchable(text: $searchText)
        .autocorrectionDisabled(true)
        .onChange(of: statusOption) {
            switch statusOption {
            case .activated:
                activationColor = .green
            case .notActivated:
                activationColor = .yellow
            case .all:
                activationColor = .secondary
            }
        }
    }
}

#Preview {
    PassportListView()
}
