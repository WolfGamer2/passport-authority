//
//  NFCService.swift
//  Passport Writer
//
//  Created by Matthew Stanciu on 2/25/24.
//

import CoreNFC

enum NFCWriteResult {
    case success
    case canceledByUser
    case error(String)
}

class NFCService: NSObject, NFCNDEFReaderSessionDelegate {
    var session: NFCNDEFReaderSession?
    var ndefMessage: NFCNDEFMessage?
    private var completion: ((Result<Bool, Error>) -> Void)?
    
    func constructTextPayload(string: String) -> NFCNDEFPayload? {
        var payloadData = Data([0x02,0x65,0x6E])
        payloadData.append(string.data(using: .utf8)!)

        let payload = NFCNDEFPayload.init(
            format: NFCTypeNameFormat.nfcWellKnown,
            type: "T".data(using: .utf8)!,
            identifier: Data.init(count: 0),
            payload: payloadData,
            chunkSize: 0)
        return payload
    }
    
    func writeToTag(url: String, id: String, secret: String) async throws -> NFCWriteResult {
        guard let url = URL(string: url),
              let urlRecord = NFCNDEFPayload.wellKnownTypeURIPayload(url: url),
              let idTextRecord = constructTextPayload(string: id),
              let secretTextRecord = constructTextPayload(string: secret) else {
            print("Error creating NFCNDEFPayload")
            return .error("Error creating NFCNDEFPayload")
        }

        let ndefMessage = NFCNDEFMessage(records: [urlRecord, idTextRecord, secretTextRecord])
        
        return await withCheckedContinuation { [weak self] continuation in
            var isContinuationHandled = false

            self?.completion = { result in
                guard !isContinuationHandled else { return }
                isContinuationHandled = true
                switch result {
                case .success:
                    continuation.resume(returning: .success)
                case .failure(let error):
                    let nsError = error as NSError
                    if nsError.code == 200 {
                        continuation.resume(returning: .canceledByUser)
                    } else {
                        continuation.resume(returning: .error(nsError.localizedDescription))
                    }
                }
            }
            self?.beginSession(with: ndefMessage)
        }
    }
    
    private func beginSession(with message: NFCNDEFMessage) {
        self.session = NFCNDEFReaderSession(delegate: self, queue: nil, invalidateAfterFirstRead: false)
        self.session?.alertMessage = "Hold your iPhone up to the passport."
        self.ndefMessage = message
        self.session?.begin()
    }
    
    func readerSessionDidBecomeActive(_ session: NFCNDEFReaderSession) {
    }
    
    func readerSession(_ session: NFCNDEFReaderSession, didInvalidateWithError error: Error) {
        completion?(.failure(error))
    }
    
    func readerSession(_ session: NFCNDEFReaderSession, didDetectNDEFs messages: [NFCNDEFMessage]) {
    }
    
    func readerSession(_ session: NFCNDEFReaderSession, didDetect tags: [NFCNDEFTag]) {
        guard let tag = tags.first else {
            session.invalidate(errorMessage: "No NFC tag detected.")
            self.completion?(.failure(NSError(domain: "NFCServiceError", code: 1, userInfo: [NSLocalizedDescriptionKey: "No NFC tag detected"])))
            return
        }
        
        session.connect(to: tag) { (error) in
            if let error = error {
                session.invalidate(errorMessage: "Connection to the NFC tag failed: \(error.localizedDescription)")
                self.completion?(.failure(NSError(domain: "NFCServiceError", code: 1, userInfo: [NSLocalizedDescriptionKey: "Connection to the NFC tag failed: \(error.localizedDescription)"])))
                return
            }
            
            tag.queryNDEFStatus() { (status: NFCNDEFStatus, capacity: Int, error: Error?) in
                if error != nil {
                    session.invalidate(errorMessage: "Fail to determine NDEF status. Please try again.")
                    self.completion?(.failure(NSError(domain: "NFCServiceError", code: 1, userInfo: [NSLocalizedDescriptionKey: "Failed to determine NDEF status. Please try again."])))
                    return
                }
                
                if status == .readOnly {
                    session.invalidate(errorMessage: "Tag is read-only.")
                    self.completion?(.failure(NSError(domain: "NFCServiceError", code: 1, userInfo: [NSLocalizedDescriptionKey: "Tag is read-only."])))
                } else if status == .readWrite {
                    tag.writeNDEF(self.ndefMessage!) { (error: Error?) in
                        if error != nil {
                            session.invalidate(errorMessage: "Write failed. Please try again.")
                            self.completion?(.failure(NSError(domain: "NFCServiceError", code: 1, userInfo: [NSLocalizedDescriptionKey: "Write failed. Please try again."])))
                        } else {
                            session.invalidate()
                            self.completion?(.success(true))
                        }
                    }
                } else {
                    session.invalidate(errorMessage: "Tag is not NDEF formatted.")
                    self.completion?(.failure(NSError(domain: "NFCServiceError", code: 1, userInfo: [NSLocalizedDescriptionKey: "Tag is not NDEF formatted."])))
                }
            }
        }
    }
}
