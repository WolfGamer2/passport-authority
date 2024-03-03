//
//  SignIn.swift
//  Passport Authority
//
//  Created by Jack Hogan on 1/3/24.
//

import SwiftUI

struct SignIn: View {
    @KeychainStorage("oauth") private var token: OAuth?
    @Environment(\.webAuthenticationSession) private var webAuthSession
    @State private var isSigningIn = false
    @State private var lastError: String?
    
    var body: some View {
        VStack {
            Image("PassportIcon")
                .resizable()
                .frame(width: 200, height: 200)
                .padding([.bottom], 32)
            Button(action: {
                Task {
                    await doSignIn()
                }
            }) {
                ZStack {
                    Text("Sign in with passport")
                        .opacity(isSigningIn ? 0 : 1)
                        .bold()
                        .font(.title2)
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle(tint: .black))
                        .opacity(isSigningIn ? 1 : 0)
                }
            }
            .padding()
            .padding([.horizontal], 32)
            .background(Color.white)
            .foregroundColor(.black)
            .cornerRadius(4)
            if let lastError = lastError {
                Text(lastError)
                    .foregroundStyle(.red)
                    .padding([.horizontal])
            }
            
        }
        .animation(.default, value: lastError)
        .animation(.default, value: isSigningIn)
    }
    
    func doSignIn() async {
        isSigningIn = true
        defer { isSigningIn = false }
        
        do {
            let res = try await webAuthSession.authenticate(using: URL(string: "https://id.purduehackers.com/api/authorize?client_id=authority&response_type=code")!, callbackURLScheme:"authority")
            
            let kv = res.query()!.split(separator: "=")
            if kv[0] == "code" {
                token = try await tokenExchange(code: String(kv[1]))
                lastError = nil
            } else {
                lastError = "Auth session failed: " + String(kv[1])
            }
        } catch {
            lastError = error.localizedDescription
        }
    }
}

#Preview {
    SignIn()
}
