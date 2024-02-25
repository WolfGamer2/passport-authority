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
    
    func writeToTag(url: String, text1: String, text2: String) {
        guard let url = URL(string: url),
              let urlRecord = NFCNDEFPayload.wellKnownTypeURIPayload(url: url),
              let textRecord1 = NFCNDEFPayload.wellKnownTypeTextPayload(string: text1, locale: Locale(identifier: "en")),
              let textRecord2 = NFCNDEFPayload.wellKnownTypeTextPayload(string: text2, locale: Locale(identifier: "en")) else {
            print("Error creating NFCNDEFPayload")
            return
        }

        let ndefMessage = NFCNDEFMessage(records: [urlRecord, textRecord1, textRecord2])

        self.beginSession(with: ndefMessage)
    }
    
    private func beginSession(with message: NFCNDEFMessage) {
        self.session = NFCNDEFReaderSession(delegate: self, queue: nil, invalidateAfterFirstRead: false)
        self.session?.alertMessage = "Hold your iPhone up to the passport."
        self.ndefMessage = message
        self.session?.begin()
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
                            session.alertMessage = "Passport updated!"
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
