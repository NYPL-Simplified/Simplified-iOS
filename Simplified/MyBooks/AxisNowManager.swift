//
//  AxisNowManager.swift
//  Open eBooks
//
//  Created by Raman Singh on 2021-03-29.
//  Copyright © 2021 NYPL Labs. All rights reserved.
//

import Foundation

struct DummyDeviceIDProvider: DeviceIdProvider {
    var deviceID: String? {
        return UUID().uuidString
    }
}

@objc
class AxisNowManager: NSObject {
    
    let isbn: String
    let bookVaultId: String
    let directoryURL: URL
    
    @objc
    init(isbn: String, bookVaultId: String, directoryURL: URL) {
        self.isbn = isbn
        self.bookVaultId = bookVaultId
        self.directoryURL = directoryURL
        super.init()
    }
    
    @objc
    func downloadLicenseFromFile(at fileURL: URL, completion: @escaping (URL?)->Void) {
        let licenseDownloader = AxisLicenseDownloader(deviceIdProvider: DummyDeviceIDProvider(),
                                                      networkRequestExecutor: NYPLNetworkExecutor.shared)
        
        licenseDownloader.downloadLicenseFromFile(at: directoryURL, completion: completion)
    }
    
    @objc
    func execute() {
        let directoryPath = self.directoryURL.path
        if FileManager.default.fileExists(atPath: directoryPath) {
            try? FileManager.default.removeItem(atPath: directoryPath)
        }
        
        try? FileManager.default.createDirectory(atPath: directoryPath,
                                                 withIntermediateDirectories: false,
                                                 attributes: nil)
        
        let baseURL = URL(string: "https://node.axisnow.com/content/stream/\(self.isbn)/")!
        let containerURL = baseURL.appendingPathComponent("META-INF/container.xml")
        let encryptionURL = baseURL.appendingPathComponent("META-INF/encryption.xml")
        
        downloadItem(withURL: containerURL,
                     to: directoryURL.appendingPathComponent("container.xml")) { (result) in
            
                        switch result {
                        case .success(let data):
                            let xml = NYPLXML(data: data)!
                            print(xml)
                            let rootfiles = xml.children[0] as! NYPLXML
                            print(rootfiles)
                            let rootfile = rootfiles.children[0] as! NYPLXML
                            let mediatype = rootfile.attributes["media-type"] as! String
                            let fullpath = rootfile.attributes["full-path"] as! String
                            print(mediatype)
                            print(fullpath)
                            
                            
                            
                            
                        case .failure(let error):
                            print(error)
                        }
                        
        }
        
    }
    
    
    private func downloadItem(withURL url: URL, to destination: URL, completion: @escaping (Result<Data, Error>) -> Void) {
        let executor = NYPLNetworkExecutor.shared
        _ = executor.GET(url) { (data, _, error) in
            if let data = data {
                completion(.success(data))
            } else if let error = error {
                completion(.failure(error))
            } else {
                let wtfError = NSError(domain: "wtf", code: 999, userInfo: nil)
                completion(.failure(wtfError))
            }
        }
    }
    
    /*
     val exponent = (keypair.public as RSAPublicKey).publicExponent.encodeUnsignedBase64()
     val deviceId = UUID.randomUUID().toString()
     val clientIp = "192.168.0.1"
     val uriStr = "https://node.axisnow.com/license/$bookVaultUuid/$deviceId/$clientIp/$isbn/$modulus/$exponent"
     */

}



