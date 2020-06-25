//
//  ACSLicense.swift
//  SimplyE
//
//  Created by Vladimir Fedorov on 13.05.2020.
//  Copyright © 2020 NYPL Labs. All rights reserved.
//

import Foundation
import R2Shared

class AdobeDRMLicense: DRMLicense {
    
    var container: AdobeDRMContainer?
    
    init(with fileURL: URL) {
        container = AdobeDRMContainer(url: fileURL) // ACSContainer(url: fileURL)
    }
    
    /*
     
     /// Encryption profile, if available.
     var encryptionProfile: String? { get }

     /// Depichers the given encrypted data to be displayed in the reader.
     func decipher(_ data: Data) throws -> Data?

     /// Returns whether the user can copy extracts from the publication.
     var canCopy: Bool { get }
     
     /// Processes the given text to be copied by the user.
     /// For example, you can save how much characters was copied to limit the overall quantity.
     /// - Parameter consumes: If true, then the user's copy right is consumed accordingly to the `text` input. Sets to false if you want to peek at the processed text without debiting the rights straight away.
     /// - Returns: The (potentially modified) text to put in the user clipboard, or nil if the user is not allowed to copy it.
     func copy(_ text: String, consumes: Bool) -> String?

     */

    var encryptionProfile: String? {
        return nil
    }
    
    func decipher(_ data: Data) throws -> Data? {
        guard let container = container else { return data }
        return container.decode(data)
    }

    var canCopy: Bool {
        return true
    }

    func copy(_ text: String, consumes: Bool) -> String? {
        return text
    }
    
}
