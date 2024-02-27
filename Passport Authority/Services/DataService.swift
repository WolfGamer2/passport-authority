//
//  DataService.swift
//  Passport Writer
//
//  Created by Matthew Stanciu on 2/24/24.
//

import Foundation
import Alamofire

struct Passport: Identifiable, Decodable, Equatable {
    let id: Int32;
    let owner_id: Int32
    let version: Int32;
    let surname: String;
    let name: String;
    let date_of_birth: String;
    let date_of_issue: String;
    let place_of_origin: String;
    let secret: String;
    let activated: Bool;
}

func getAPIToken() -> String? {
    guard let path = Bundle.main.path(forResource: "Config", ofType: "plist"),
          let plist = NSDictionary(contentsOfFile: path),
          let value = plist.object(forKey: "API_TOKEN") as? String else {
        print("Error: Unable to retrieve API_TOKEN from Config.plist")
        return nil
    }
    return value
}

func fetchData(completion: @escaping ([Passport]?) -> Void) {
    guard let token = getAPIToken() else {
        completion(nil)
        return
    }
    
    let headers: HTTPHeaders = [
        "Authorization": "Bearer \(token)",
        "Accept": "application/json"
    ]
    
    AF.request("https://api.purduehackers.com/passports", headers: headers).responseDecodable(of: [Passport].self) { response in
        switch response.result {
        case .success(let data):
            completion(data)
        case .failure(let error):
            print(error)
            completion(nil)
        }
    }
}

func activatePassport(id: String) async throws -> Passport? {
    guard let token = getAPIToken() else {
        throw NSError(domain: "me.matthewstanciu.Passport-Writer", code: 0, userInfo: [NSLocalizedDescriptionKey: "Cannot read API token"])
    }
    
    let headers: HTTPHeaders = [
        "Authorization": "Bearer \(token)",
        "Accept": "application/json"
    ]
    
    let parameters: [String: Any] = ["id": id]
    let url = "https://api.purduehackers.com/passports/activate"
    
    do {
        let response = try await AF.request(url, method: .post, parameters: parameters, encoding: JSONEncoding.default, headers: headers)
            .validate()
            .serializingDecodable(Passport.self)
            .value
        return response
    } catch {
        print(error)
        throw error
    }
}
