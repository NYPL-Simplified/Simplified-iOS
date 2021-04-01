//
//  AxisLicenseDownloader.swift
//  Simplified
//
//  Created by Raman Singh on 2021-03-29.
//  Copyright © 2021 NYPL Labs. All rights reserved.
//

import Foundation

protocol DeviceIdProvider {
    var deviceID: String? { get }
}



@objc
class AxisLicenseDownloader: NSObject {
    
    private let deviceIdProvider: DeviceIdProvider
    private let networkRequestExecutor: NYPLRequestExecuting
    
    
    init(deviceIdProvider: DeviceIdProvider, networkRequestExecutor: NYPLRequestExecuting) {
        self.deviceIdProvider = deviceIdProvider
        self.networkRequestExecutor = networkRequestExecutor
        super.init()
    }
    
    @objc
    func downloadBookFile(fromURL url: URL) {
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        URLSession.shared.dataTask(with: url) { (data, response, error) in
            print(data)
        }.resume()
        
        
//        networkRequestExecutor.executeRequest(request) { (result) in
//            switch result {
//            case .success(let data, let response):
//                print(data)
//                print(response)
//            case .failure(let error, let response):
//                print(error)
//                print(response)
//            }
//        }
    }
    
    
    @objc
    func downloadLicenseFromFile(at fileURL: URL, completion: @escaping (URL?)->Void) {
        guard
            let licenseData = try? Data(contentsOf: fileURL),
            let jsonObject = try? JSONSerialization
                .jsonObject(with: licenseData,
                            options: .allowFragments),
            let jsonDictionary = jsonObject as? [String: String],
            let isbn = jsonDictionary["isbn"],
            let bookVaultId = jsonDictionary["book_vault_uuid"]
            else {
                completion(nil)
                return
        }
        
//        let bookDownloadURL = URL(string: "https://node.axisnow.com/content/stream/\(isbn)/")!
//        self.downloadBookFile(fromURL: bookDownloadURL)
        
        let request = URLRequest(url: generateLicenseURL(isbn: isbn, bookVaultId: bookVaultId))
        
        self.networkRequestExecutor.executeRequest(request) { (result) in
            switch result {
            case .success(let data, _):
                print(data)
                let destinationURL = fileURL
                    .deletingLastPathComponent()
                    .appendingPathComponent("license.json")
                do {
                    try data.write(to: destinationURL, options: .atomic)
                    completion(destinationURL)
                } catch {
                    completion(nil)
                }
            case .failure(let error, _):
                print(error)
                completion(nil)
            }
        }
    }
    
    func generateLicenseURL(isbn: String, bookVaultId: String) -> URL {
        let rsa = RSAManager()!
        
        
        let modulus = rsa.getPublicKey().replacingOccurrences(of: "/", with: "-")
        let exponent = "AQAB"
        
        let baseURL = URL(string: "https://node.axisnow.com/license")!
        let deviceId: String = UUID().uuidString
        let clientIp = "192.168.0.1"
        let licenseURL = baseURL
            .appendingPathComponent(bookVaultId)
            .appendingPathComponent(deviceId)
        .appendingPathComponent(clientIp)
            .appendingPathComponent(isbn)
            .appendingPathComponent(modulus)
        .appendingPathComponent(exponent)
        
        return licenseURL
    }
    
    
    
    
}


/*
 NSData *licenseData = [NSData dataWithContentsOfURL:fileUrl];
     id jsonObject = [NSJSONSerialization JSONObjectWithData:licenseData options:0 error:nil];


     NSString *isbn = [jsonObject objectForKey:@"isbn"];
     NSString *bookVaultId = [jsonObject objectForKey:@"book_vault_uuid"];

     if (isbn && bookVaultId) {
         NSURL *bookDirectory = [[fileUrl URLByDeletingLastPathComponent] URLByAppendingPathComponent:isbn];
         AxisNowManager *manager = [[AxisNowManager alloc] initWithIsbn:isbn bookVaultId:bookVaultId directoryURL:bookDirectory];

 //        [manager execute];
         [manager generateLicenseURL];

         
 //        NSURL *baseURL = [NSURL URLWithString:@"https://node.axisnow.com/license"];
 //        NSURL *licenseURL = [licenseURL URLByAppendingPathComponent:bookVaultId]
 //    URLByAppendingPathComponent:<#(nonnull NSString *)#>



     } else {
         NSLog(@"wtf!!!");
     }
 */
