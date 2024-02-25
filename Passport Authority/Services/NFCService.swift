//
//  NFCService.swift
//  Passport Writer
//
//  Created by Matthew Stanciu on 2/25/24.
//

import CoreNFC

class NFCService: NSObject, NFCNDEFReaderSessionDelegate {
    var session: NFCNDEFReaderSession?
    var ndefMessage: NFCNDEFMessage?
    var completion: ((Result<String, Error>) -> Void)?
    
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
    
    func writeToTag(url: String, id: String, secret: String) {
        guard let url = URL(string: url),
              let urlRecord = NFCNDEFPayload.wellKnownTypeURIPayload(url: url),
              let idTextRecord = constructTextPayload(string: id),
              let secretTextRecord = constructTextPayload(string: secret) else {
            print("Error creating NFCNDEFPayload")
            return
        }

        let ndefMessage = NFCNDEFMessage(records: [urlRecord, idTextRecord, secretTextRecord])

        self.beginSession(with: ndefMessage)
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
            return
        }
        
        session.connect(to: tag) { (error) in
            if let error = error {
                session.invalidate(errorMessage: "Connection to the NFC tag failed: \(error.localizedDescription)")
                return
            }
            
            tag.queryNDEFStatus() { (status: NFCNDEFStatus, capacity: Int, error: Error?) in
                if error != nil {
                    session.invalidate(errorMessage: "Fail to determine NDEF status.  Please try again.")
                    return
                }
                
                if status == .readOnly {
                    session.invalidate(errorMessage: "Tag is not writable.")
                } else if status == .readWrite {
                    tag.writeNDEF(self.ndefMessage!) { (error: Error?) in
                        if error != nil {
                            session.invalidate(errorMessage: "Write failed. Please try again.")
                        } else {
//                            session.alertMessage = "Passport updated!"
                            session.invalidate()
                        }
                    }
                } else {
                    session.invalidate(errorMessage: "Tag is not NDEF formatted.")
                }
            }
        }
    }
}
