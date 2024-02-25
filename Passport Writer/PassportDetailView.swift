//
//  PassportDetailView.swift
//  Passport Writer
//
//  Created by Matthew Stanciu on 2/24/24.
//

import SwiftUI

struct PassportDetailView: View {
    let passport: Passport
    
    let mono = Font
        .system(size: 16)
        .monospaced()
    
    let IMAGE_WIDTH = 314.6666666667
    let IMAGE_HEIGHT = 221.3333333333
    
    @State private var nfcService = NFCService()
    
    var body: some View {
        VStack(alignment: .leading, content: {
            Text("\(passport.name) \(passport.surname)").font(.largeTitle).bold()
                .padding([.top], 24)
                .padding([.bottom], 10)
                .multilineTextAlignment(.leading)
                .frame(maxWidth: .infinity, alignment: .leading)
            AsyncImage(url: URL(string: "https://pub-84077b41cf284cf3a74ef394a9226674.r2.dev/\(String(passport.id)).png")) { image in
                image.resizable()
                    .scaledToFit()
                    .frame(width: IMAGE_WIDTH, height: IMAGE_HEIGHT)
                    .clipShape(RoundedRectangle(cornerRadius: 8))
            } placeholder: {
                ProgressView().frame(width: IMAGE_WIDTH, height: IMAGE_HEIGHT)
                    .background(Color.gray)
                    .clipShape(RoundedRectangle(cornerRadius: 8))
            }
            VStack(alignment: .leading, spacing: 6, content: {
                Label(String(passport.id), systemImage: "person.text.rectangle.fill")
                Label(passport.secret, systemImage: "key.horizontal.fill").font(mono)
                StatusView(activated: passport.activated, size: 16)
            })
            VStack {
                Button(action: {
                    let url = "https://id.purduehackers.com/scan?id=\(String(passport.id))&secret=\(passport.secret)"
                    
                    nfcService.writeToTag(url: url, id: String(passport.id), secret: passport.secret)
                }) {
                    HStack {
                        Image(systemName: "pencil.line")
                            .resizable()
                            .frame(width: 20, height: 20)
                        Text("Write to passport")
                            .fontWeight(.semibold)
                    }
                }.padding()
                 .background(Color.yellow)
                 .foregroundColor(.black)
                 .cornerRadius(8)
                 .shadow(color: .gray, radius: 3, x: 0, y: 3)
            }.padding([.top])
            Spacer()
        }).padding([.leading], 24)
    }
}

struct PassportDetailView_Previews: PreviewProvider {
    static var previews: some View {
        
        let mockPassport = Passport(id: 12, owner_id: 12, version: 0, surname: "Stanciu", name: "Matthew", date_of_birth: "2002-02-17T00:00:00.000Z", date_of_issue: "2024-02-09T00:00:00.000Z", place_of_origin: "The woods", secret: "cUWnYREMmNdvOQI2M9uhTczeRStj0fmq", activated: true)

        PassportDetailView(passport: mockPassport)
    }
}
