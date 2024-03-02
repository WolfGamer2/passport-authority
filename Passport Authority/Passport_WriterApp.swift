//
//  Passport_WriterApp.swift
//  Passport Writer
//
//  Created by Matthew Stanciu on 2/24/24.
//

import SwiftUI
import Combine
import KeychainSwift

@main
struct Passport_WriterApp: App {
    var body: some Scene {
        WindowGroup {
            PassportListView()
        }
    }
}

// Helper code for keychain management
final class PublisherObservableObject: ObservableObject {
    var subscriber: AnyCancellable?
    
    init(publisher: AnyPublisher<Void, Never>) {
        subscriber = publisher.sink(receiveValue: { [weak self] _ in
            self?.objectWillChange.send()
        })
    }
}

fileprivate let keychainSubject = PassthroughSubject<String, Never>()

@propertyWrapper
struct KeychainStorage<Value: Codable & Equatable>: DynamicProperty {
    @ObservedObject private var observer: PublisherObservableObject
    private let key: String
    private let chain: KeychainSwift
    @State private var value: Value?
    
    init(wrappedValue: Value? = nil, _ key: String, accessGroup: String? = nil) {
        self.key = key
        self.chain = KeychainSwift()
        self.observer = .init(publisher: keychainSubject.filter { k in k == key }.map { _ in () }.eraseToAnyPublisher())
        if let accessGroup = accessGroup {
            self.chain.accessGroup = accessGroup
        }
        
        // Attempt to load keychain value first
        if let data = chain.getData(key) {
            self._value = State(initialValue: try? JSONDecoder().decode(Value.self, from: data))
        } else if let wrappedValue = wrappedValue {
            self._value = State(initialValue: wrappedValue)
            
            // Write new value
            chain.set(try! JSONEncoder().encode(wrappedValue), forKey: key)
            keychainSubject.send(key)
        } else {
            self._value = State(initialValue: nil)
        }
    }
    
    func update() {
        if let data = chain.getData(key), let decoded = try? JSONDecoder().decode(Value.self, from: data) {
            if decoded != value {
                Task { @MainActor in
                    value = decoded
                }
            }
        } else {
            Task { @MainActor in
                value = nil
            }
        }
    }
    
    var wrappedValue: Value? {
        get {
            value
        }
        
        nonmutating set {
            value = newValue
            
            // Delete old value
            chain.delete(key)
            
            if let value = value {
                // Write new value
                chain.set(try! JSONEncoder().encode(value), forKey: key)
            }
            keychainSubject.send(key)
        }
    }
    
    var projectedValue: Binding<Value?> {
        get {
            $value
        }
    }
}
