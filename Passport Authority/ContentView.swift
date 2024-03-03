//
//  ContentView.swift
//  Passport Writer
//
//  Created by Matthew Stanciu on 2/24/24.
//

import SwiftUI
import AuthenticationServices

//class PassportViewModel: ObservableObject {
//    @Published var passports = [Passport]()
//    
//    func load() {
//        fetchData { [weak self] data in
//            DispatchQueue.main.async {
//                self?.passports = data ?? []
//            }
//        }
//    }
//}

struct PassportRowView: View {
    var passport: Passport
    var status: ActivationState

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
                StatusView(activation: status, size: 12)
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
        case superseded = "Superseded"
        
        var id: String { self.rawValue }
        
        var icon: String {
            switch self {
            case .all:
                "bolt"
            case .activated:
                "bolt.fill"
            case .notActivated:
                "bolt.slash.fill"
            case .superseded:
                "bolt.xmark"
            }
        }
    }
    
    @KeychainStorage("oauth") private var oauth: OAuth?
    @State private var passports = [Passport]()
    @State private var showAuthSheet = false
    
    @State private var searchText: String = ""
    @State private var sortOption: SortOption = .idAscending
    @State private var statusOption: StatusOption = .all
    @State private var showSignOutAlert = false
    
    var passportReferences: [Int32: Int32] {
        var current = [Int32: Int32]()
        for passport in passports {
            if let entry = current[passport.ownerId], passport.id > entry {
                current[passport.ownerId] = passport.id
            } else if current[passport.ownerId] == nil {
                current[passport.ownerId] = passport.id
            }
        }
        
        return current
    }
    
    func stateForPassport(_ passport: Passport) -> ActivationState {
        if !passport.activated && passportReferences[passport.ownerId] ?? -1 > passport.id {
            return ActivationState.superseded
        } else if passport.activated {
            return ActivationState.activated
        } else {
            return ActivationState.notActivated
        }
    }
    
    var filteredPassports: [Passport] {
        var viewModelPassports = passports
        
        switch sortOption {
        case .idAscending:
            viewModelPassports = passports.sorted { $0.id < $1.id }
        case .idDescending:
            viewModelPassports = passports.sorted { $0.id > $1.id }
        }
        
        switch statusOption {
        case .activated:
            viewModelPassports = viewModelPassports.filter { stateForPassport($0) == .activated }
        case .notActivated:
            viewModelPassports = viewModelPassports.filter { stateForPassport($0) == .notActivated }
        case .superseded:
            viewModelPassports = viewModelPassports.filter { stateForPassport($0) == .superseded }
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
            if passports == [] {
                SkeletonView()
            } else {
                List {
                    ForEach(filteredPassports) { passport in
                        NavigationLink {
                            PassportDetailView(passport: passport, state: stateForPassport(passport), onUpdate: {
                                Task {
                                    await refreshData()
                                }
                            })
                                .navigationBarTitleDisplayMode(.inline)
                        } label: {
                            PassportRowView(passport: passport, status: stateForPassport(passport))
                        }
                        .id(passport.id)
                    }
                }
                .animation(.easeInOut, value: filteredPassports)
                .refreshable {
                    await refreshData()
                }
                .navigationTitle("Passports")
                .toolbar {
                    ToolbarItemGroup {
                        Button("Sort", image: ImageResource(name: sortOption == .idAscending ? "NumberUp" : "NumberDown", bundle: Bundle.main), action: {
                            sortOption = sortOption == .idAscending ? .idDescending : .idAscending
                        })
                        Picker("Activation", image: ImageResource(name: statusOption.icon == "bolt.xmark" ? "bolt.xmark" : statusOption.icon, bundle: Bundle.main), selection: $statusOption, content: {
                            ForEach(StatusOption.allCases, id: \.self) { option in
                                Label(option.rawValue, image: ImageResource(name: option.icon, bundle: Bundle.main)).tag(option)
                            }
                        })
                        Button("Sign Out", systemImage: "rectangle.portrait.and.arrow.right") {
                            showSignOutAlert = true
                        }
                    }
                }
            }
        }
        .alert(isPresented: $showSignOutAlert) {
            Alert(
                title: Text("Sign out?"),
                primaryButton: .destructive(Text("Sign Out")) {
                    oauth = nil
                },
                secondaryButton: .cancel()
            )
        }
        .task(id: oauth?.accessToken == nil) {
            await refreshData()
        }
        .fullScreenCover(isPresented: .constant(oauth == nil), content: {
            SignIn()
        })
        .searchable(text: $searchText)
        .autocorrectionDisabled(true)
    }
    
    private func refreshData() async {
        guard let token = oauth?.accessToken else { return }
        do {
            passports = try await fetchData(withToken: token)
        } catch {
            print("Network error: \(error)")
        }
    }
    
    private func getHostingViewController() -> UIViewController {
        let scene = UIApplication.shared.connectedScenes.first as? UIWindowScene
        return scene!.keyWindow!.rootViewController!
    }
}

#Preview {
    PassportListView()
}
