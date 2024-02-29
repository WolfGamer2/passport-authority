//
//  PassportDetailView.swift
//  Passport Writer
//
//  Created by Matthew Stanciu on 2/24/24.
//

import SwiftUI
import ConfettiSwiftUI

struct PassportDetailView: View {

    
    let system = Font
        .system(size: 15)
    let mono = Font
        .system(size: 15)
        .monospaced()
    
    @ObservedObject var viewModel: PassportViewModel
    
    @State private var nfcService = NFCService()
    @State private var passport: Passport
    @State private var showErrorUpdatingAlert = false
    @State private var confettiCounter = 0
    
    init(passport: Passport, viewModel: PassportViewModel) {
        self._passport = State(initialValue: passport)
        self._viewModel = ObservedObject(wrappedValue: viewModel)
    }
    
    let IMAGE_HEIGHT = 235.3333333333
    
    var body: some View {
        VStack(alignment: .leading, content: {
            Text("\(passport.name) \(passport.surname)").font(.largeTitle).bold()
                .padding([.top], 24)
                .padding([.bottom], 10)
                .multilineTextAlignment(.leading)
                .frame(maxWidth: .infinity, alignment: .leading)
            AsyncImage(url: URL(string: "https://data.passports.purduehackers.com/\(String(passport.id)).png")) { image in
                image.resizable()
                    .scaledToFit()
                    .clipShape(RoundedRectangle(cornerRadius: 8))
            } placeholder: {
                ProgressView().frame(maxWidth: .infinity, maxHeight: IMAGE_HEIGHT)
                    .background(Color.gray)
                    .clipShape(RoundedRectangle(cornerRadius: 8))
            }
            VStack(alignment: .leading, spacing: 6, content: {
                Label(String(passport.id), systemImage: "person.text.rectangle.fill")
                    .font(system)
                Label(passport.secret, systemImage: "key.horizontal.fill").font(mono)
                StatusView(activated: passport.activated, size: 16).padding([.top], 6)
            }).padding([.top], 6)
            VStack {
                if (!passport.activated) {
                    Button(action: {
                        Task {
                            do {
                                let url = "https://id.purduehackers.com/scan?id=\(String(passport.id))&secret=\(passport.secret)"
                                let writeSuccess = try await nfcService.writeToTag(url: url, id: String(passport.id), secret: passport.secret)
                                
                                switch writeSuccess {
                                case .success:
                                    do {
                                        if let updatedPassport = try await activatePassport(id: String(passport.id)) {
                                            self.passport = updatedPassport
                                            if let index = viewModel.passports.firstIndex(where: { $0.id == updatedPassport.id }) {
                                                viewModel.passports[index] = updatedPassport
                                                viewModel.load()
                                                
                                                confettiCounter += 1
                                            }
                                        } else {
                                            self.showErrorUpdatingAlert = true
                                        }
                                    } catch {
                                        self.showErrorUpdatingAlert = true
                                    }
                                case .canceledByUser:
                                    print("NFC write canceled by user")
                                case .error(let errorMessage):
                                    print("Error writing to NFC: \(errorMessage)")
                                    self.showErrorUpdatingAlert = true
                                }
                            } catch {
                                self.showErrorUpdatingAlert = true
                            }
                        }
                    }) {
                        HStack {
                            Image(systemName: "bolt.fill")
                                .resizable()
                                .scaledToFit()
                                .frame(width: 20)
                            Text("Activate passport")
                                .fontWeight(.semibold)
                        }
                    }
                    .padding()
                        .frame(maxWidth: .infinity)
                        .background(Color.yellow)
                        .foregroundColor(.black)
                        .cornerRadius(2)
                        .shadow(color: .yellow, radius: 3, x: 3, y: 3)
                        .alert(isPresented: $showErrorUpdatingAlert) {
                            Alert(title: Text("Error activating"), message: Text("There was an error activating the passport."))
                     }
                }
            }                   .padding([.top])
            Spacer()
        })
        .padding([.horizontal], 24)
        .confettiCannon(counter: $confettiCounter, num: 50, repetitions: 4, repetitionInterval: 0.2)
    }
}

struct PassportDetailView_Previews: PreviewProvider {
    static var previews: some View {
        
        let mockPassport = Passport(id: 12, owner_id: 12, version: 0, surname: "Stanciu", name: "Matthew", date_of_birth: "2002-02-17T00:00:00.000Z", date_of_issue: "2024-02-09T00:00:00.000Z", place_of_origin: "The woods", secret: "cUWnYREMmNdvOQI2M9uhTczeRStj0fmq", activated: false)
        
        let mockViewModel = PassportViewModel()

        PassportDetailView(passport: mockPassport, viewModel: mockViewModel)
    }
}
