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
    let ownerId: Int32
    let version: Int32;
    let surname: String;
    let name: String;
    let dateOfBirth: String;
    let dateOfIssue: String;
    let placeOfOrigin: String;
    let secret: String;
    let activated: Bool;
}

enum NetworkError: Error {
    case noApiToken
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

//func fetchData(completion: @escaping ([Passport]?) -> Void) {
//    guard let token = getAPIToken() else {
//        completion(nil)
//        return
//    }
//    
//    let headers: HTTPHeaders = [
//        "Authorization": "Bearer \(token)",
//        "Accept": "application/json"
//    ]
//    
//    AF.request("https://api.purduehackers.com/passports", headers: headers).responseDecodable(of: [Passport].self) { response in
//        switch response.result {
//        case .success(let data):
//            completion(data)
//        case .failure(let error):
//            print(error)
//            completion(nil)
//        }
//    }
//}

func fetchData(withToken token: String) async throws -> [Passport] {
    let headers: HTTPHeaders = [
        "Authorization": "Bearer \(token)",
        "Accept": "application/json"
    ]
    
    let resp = AF.request("https://id.purduehackers.com/api/passport", headers: headers)
    
    let s =  try await resp.serializingString(automaticallyCancelling: true).response.result.get()
    if s.contains("Unauthorized") {
        throw NetworkError.noApiToken
    }
    return try standardDecoder.decode([Passport].self, from: Data(s.utf8))
}

func activatePassport(withId id: String, withToken token: String) async throws {
    print(token)
    let headers: HTTPHeaders = [
        "Authorization": "Bearer \(token)",
        "Accept": "application/json"
    ]
    
    let url = "https://id.purduehackers.com/api/passport/\(id)"
    
    do {
        let res = await AF.request(url, method: .post, encoding: JSONEncoding.default, headers: headers)
            .serializingString(emptyResponseCodes: Set([200]))
            .response
        
        if res.response?.statusCode != 200 {
            throw res.error!
        }
    } catch {
        throw error
    }
}

fileprivate struct CustomKey: CodingKey {
    var stringValue: String
    
    init?(stringValue: String) {
        self.stringValue = stringValue
    }
    
    var intValue: Int?
    
    init?(intValue: Int) {
        return nil
    }
}

extension String {
    func snakeCaseToCamelCase() -> Self {
        self.split(separator: "_")
            .enumerated()
            .map { $0 == 0 ? String($1) : $1.capitalized }
            .joined()
    }
}

class OptionalFractionalSecondsDateFormatter: DateFormatter {

     // NOTE: iOS 11.3 added fractional second support to ISO8601DateFormatter,
     // but it behaves the same as plain DateFormatter. It is either enabled
     // and required, or disabled and... anti-required
     // let formatter = ISO8601DateFormatter()
     // formatter.timeZone = TimeZone(secondsFromGMT: 0)
     // formatter.formatOptions = [.withInternetDateTime ] // .withFractionalSeconds

    static let withoutSeconds: DateFormatter = {
        let formatter = DateFormatter()
        formatter.calendar = Calendar(identifier: .iso8601)
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.timeZone = TimeZone(identifier: "UTC")
        formatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ssXXX"
        return formatter
    }()

    func setup() {
        self.calendar = Calendar(identifier: .iso8601)
        self.locale = Locale(identifier: "en_US_POSIX")
        self.timeZone = TimeZone(identifier: "UTC")
        self.dateFormat = "yyyy-MM-dd'T'HH:mm:ss.SSSSSSXXX" // handle up to 6 decimal places, although iOS currently only preserves 2 digits of precision
    }

    override init() {
        super.init()
        setup()
    }

    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        setup()
    }

    override func date(from string: String) -> Date? {
        if let result = super.date(from: string) {
            return result
        }
        return OptionalFractionalSecondsDateFormatter.withoutSeconds.date(from: string)
    }
}

extension DateFormatter {
    static let iso8601 = OptionalFractionalSecondsDateFormatter()
}

var standardDecoder: JSONDecoder {
    let dec = JSONDecoder()
    dec.keyDecodingStrategy = .custom { keys in
        let lastKey = keys.last! // If only there was a non-empty array type...
        if lastKey.intValue != nil {
            return lastKey // It's an array key, we don't need to change anything
        }
        
        if lastKey.stringValue.first?.isUppercase ?? false {
            return CustomKey(stringValue: lastKey.stringValue)!
        }
        
        return CustomKey(stringValue: lastKey.stringValue.snakeCaseToCamelCase())!
    }
    dec.dateDecodingStrategy = .formatted(.iso8601)
    return dec
}

struct OAuth: Codable, Equatable {
    let accessToken: String
}

func tokenExchange(code: String) async throws -> OAuth {
    let response = await AF.request("https://id.purduehackers.com/api/token", method: .post, parameters: ["grant_type": "authorization_code", "code": code, "client_id": "authority", "redirect_uri": "authority://callback"], encoding: URLEncoding.default)
        .validate()
        .serializingString(automaticallyCancelling: true)
        .response
    
    return try standardDecoder.decode(OAuth.self, from: Data(response.result.get().utf8))
}
