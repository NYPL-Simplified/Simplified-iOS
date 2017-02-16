//
//  NNYPLAnnotations.swift
//  Simplified
//
//  Created by Aferdita Muriqi on 10/18/16.
//  Copyright © 2016 NYPL Labs. All rights reserved.
//

import UIKit
import Alamofire


class NYPLAnnotations: NSObject {
    static let maxRetryCount: Int = 3
    static var reachability: NetworkReachabilityManager!
    static var isReachable: Bool {return reachability.isReachable}
    
    fileprivate static var annotationsQueue:OperationQueue = {
        var queue = OperationQueue()
        queue.name = "AnnotationsQueue"
        queue.maxConcurrentOperationCount = 1
        queue.qualityOfService = .utility
        //suspend queued operations if server is not reachable
        queue.isSuspended = !isReachable
        return queue
    }()
    
    fileprivate static var lastReadBookQueue:OperationQueue = {
        var queue = OperationQueue()
        queue.name = "lastReadBookQueue"
        queue.maxConcurrentOperationCount = 1
        queue.qualityOfService = .utility
        //suspend queued operations if server is not reachable
        queue.isSuspended = !isReachable
        return queue
    }()
    
    override class func initialize () {
        //this host could change, we may need to observe for chage and reinitialize
        var host: String { return NYPLConfiguration.mainFeedURL().host!}
        
        reachability = NetworkReachabilityManager(host: host)
        
        NotificationCenter.default.addObserver(self, selector: #selector(applicationDidEnterBackground), name: NSNotification.Name.UIApplicationDidEnterBackground, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(applicationDidEnterForeground), name: NSNotification.Name.UIApplicationWillEnterForeground, object: nil)
        
        reachability?.listener = { status in
            NYPLAnnotations.reachabilityChanged()
        }
        
        reachability?.startListening()
        
    }
    
    @objc fileprivate class func reachabilityChanged() {
        
        if reachability.isReachable {
            Log.debug(#file,"isReachable true")
        } else {
            Log.debug(#file,"not reachable")
        }
        
        annotationsQueue.isSuspended = !reachability.isReachable
        lastReadBookQueue.isSuspended = !reachability.isReachable
        
    }
    
    func applicationDidEnterBackground() {
        //Currently only writing lastreadqueue, placeholder for annotation queue
        
        Log.debug(#file,"App moved to background!")
        Log.debug(#file,"Suspending analyticsQueue")
        
        //suspend current operations while we attempt to write the contents to file
        NYPLAnnotations.annotationsQueue.isSuspended = true
        NYPLAnnotations.lastReadBookQueue.isSuspended = true
        
        //write operations to file if there are any still queued
        if(NYPLAnnotations.lastReadBookQueue.operations.count == 0) {
            return;
        }
        
        do {
            
            let file = NYPLAnnotations.lastReadBookQueue.name! + ".plist" //this is the file. we will write to and read from it
            
            if let dir = NSSearchPathForDirectoriesInDomains(FileManager.SearchPathDirectory.documentDirectory, FileManager.SearchPathDomainMask.allDomainsMask, true).first {
                let path = URL(fileURLWithPath: dir).appendingPathComponent(file)
                NSKeyedArchiver.archiveRootObject(NYPLAnnotations.lastReadBookQueue.operations, toFile: (path.path))            }
            
        }
        
        //we have archived the operations, so remove them all from the active queue
        NYPLAnnotations.lastReadBookQueue.cancelAllOperations()
        
        //TODO: future state handle annotation queue in the same mannor
        
    }
    
    func applicationDidEnterForeground() {
        //read file into queue if it exists, then enable queues if needed
        
        let file = NYPLAnnotations.lastReadBookQueue.name! + ".plist" //this is the file we will read from
        let fileManager = FileManager.default
        
        if let dir = NSSearchPathForDirectoriesInDomains(FileManager.SearchPathDirectory.documentDirectory, FileManager.SearchPathDomainMask.allDomainsMask, true).first {
            let path = URL(fileURLWithPath: dir).appendingPathComponent(file)
            
            if(fileManager.fileExists(atPath: (path.path))) {
                
                do {
                    let operations: [NYPLLastReadBookOperation] = NSKeyedUnarchiver.unarchiveObject(withFile: (path.path)) as! [NYPLLastReadBookOperation]
                    NYPLAnnotations.lastReadBookQueue.addOperations(operations, waitUntilFinished: true)
                    //we have sucessfully read the file back in, remove it
                    try! fileManager.removeItem(at: path)
                    
                }
                
            }
            
        }
        
        NYPLAnnotations.lastReadBookQueue.isSuspended = !NYPLAnnotations.isReachable
        
        Log.debug(#file,"App moved to foreground!")
        
        //TODO: lastbopok read fully impl'd, annotation queue is mearly here waiting for the impl to use it
        NYPLAnnotations.annotationsQueue.isSuspended = !NYPLAnnotations.isReachable
        
    }
    
    class func postLastRead(_ book:NYPLBook, cfi:NSString) {
        self.postLastRead(book, retryCount: 0, cfi:cfi)
    }
    
    class func postLastRead(_ book:NYPLBook, retryCount: Int, cfi:NSString)
    {
        
        let lastReadBookOperation = NYPLLastReadBookOperation(cfi: cfi as String, book: book)
        
        lastReadBookOperation.completionBlock = {
            
            //added max retry count just in case the failure was not do to loss of internet, possible mailformation
            //of the url or server side issues
            if(!lastReadBookOperation.success && !reachability.isReachable && lastReadBookOperation.retryCount < maxRetryCount) {
                //we need to add this operation back into the queue, internet was lost while in progress
                //we only need the latest, so if there is another allready in queue, drop this one on the floor
                if(lastReadBookQueue.operationCount == 0) {
                    self.postLastRead(lastReadBookOperation.book, retryCount: lastReadBookOperation.retryCount+1, cfi: lastReadBookOperation.cfi)
                }
                
            } else {
                Log.error(#file, "Error posting event, retry count exceeds maximum or error occured on server side")
            }
            
        }
        
        lastReadBookQueue.addOperation(lastReadBookOperation)
    }
    
    class func syncLastRead(_ book:NYPLBook, completionHandler: @escaping (_ responseObject: String?,
        _ error: NSError?) -> ()) {
        
        func convertDataToDictionary(_ data: Data) -> [String:AnyObject]? {
            do {
                return try JSONSerialization.jsonObject(with: data, options: []) as? [String:AnyObject]
            } catch let error as NSError {
                print(error)
            }
            return nil
        }
        
        if (NYPLAccount.shared().hasBarcodeAndPIN())
        {
            if book.annotationsURL != nil {
                
                
                Alamofire.request(book.annotationsURL.absoluteString, method: .get, parameters: ["":""], encoding: URLEncoding.default, headers: NYPLAnnotations.headers).responseJSON { (response:DataResponse<Any>) in
                    
                    switch(response.result) {
                    case .success(_):
                        if let data = response.result.value{
                            let json = convertDataToDictionary(data as! Data)
                            
                            let total:Int = json!["total"] as! Int
                            if total > 0
                            {
                                let first = json!["first"] as! [String:AnyObject]
                                let items = first["items"] as! [AnyObject]
                                for item in items
                                {
                                    let target = item["target"] as! [String:AnyObject]
                                    let source = target["source"] as! String
                                    if source == book.identifier
                                    {
                                        
                                        let selector = target["selector"] as! [String:AnyObject]
                                        let value = selector["value"] as! String
                                        
                                        completionHandler(value as String!, response.result.error as NSError?)
                                        print(value)
                                    }
                                }
                            }
                            else
                            {
                                completionHandler(nil, response.result.error as NSError?)
                            }
                            
                        }
                        break
                        
                    case .failure(_):
                        completionHandler(nil, response.result.error as NSError?)
                        break
                        
                    }
                }
                
            }
        }
    }
    
    class func sync(_ book:NYPLBook, completionHandler: @escaping (_ responseObject: String?, _ error: NSError?) -> ()) {
        syncLastRead(book, completionHandler: completionHandler)
    }
    
    // Server currently not validating authentication in header, but including
    // with call in case that changes in the future
    class var headers:[String:String]
    {
        let authenticationString = "\(NYPLAccount.shared().barcode):\(NYPLAccount.shared().pin)"
        let authenticationData:Data = authenticationString.data(using: String.Encoding.ascii)!
        let authenticationValue = "Basic \(authenticationData.base64EncodedString(options: NSData.Base64EncodingOptions.lineLength64Characters)))"
        
        let headers = [
            "Authorization": "\(authenticationValue)"      ]
        
        return headers
    }
    
}

final class NYPLLastReadBookOperation: Operation, NSCoding {
    
    let book: NYPLBook
    let cfi:NSString
    fileprivate(set) var success: Bool = true
    fileprivate(set) var statusCode: Int = 0
    fileprivate(set) var retryCount: Int
    
    init(cfi: String, book: NYPLBook) {
        self.book = book
        self.cfi = cfi as NSString
        self.retryCount = 0
        super.init()
    }
    
    init(cfi: String, book: NYPLBook, retryCount: Int) {
        self.book = book
        self.cfi = cfi as NSString
        self.retryCount = retryCount
        super.init()
    }
    
    convenience init?(coder aDecoder: NSCoder) {
        
        guard let book = aDecoder.decodeObject(forKey: "book") as? NYPLBook,
            let cfi = aDecoder.decodeObject(forKey: "cfi") as? String
            else { return nil }
        
        self.init(
            cfi: cfi,
            book: book
        )
        
    }
    
    func encode(with aCoder: NSCoder) {
        
        aCoder.encode(self.cfi, forKey: "cfi")
        aCoder.encode(self.book, forKey: "book")
        
    }
    
    override var isAsynchronous: Bool {
        return true
    }
    
    fileprivate var _executing = false {
        willSet {
            willChangeValue(forKey: "isExecuting")
        }
        didSet {
            didChangeValue(forKey: "isExecuting")
        }
    }
    
    override var isExecuting: Bool {
        return _executing
    }
    
    fileprivate var _finished = false {
        willSet {
            willChangeValue(forKey: "isFinished")
        }
        
        didSet {
            didChangeValue(forKey: "isFinished")
        }
    }
    
    override var isFinished: Bool {
        return _finished
    }
    
    override func start() {
        
        if isCancelled {
            return
        }
        
        _executing = true
        execute()
    }
    
    override func cancel() {
        super.cancel()
        self.finish()
    }
    
    func execute() {
        
        if (NYPLAccount.shared().hasBarcodeAndPIN())
        {
            
            let parameters = [
                "@context": "http://www.w3.org/ns/anno.jsonld",
                "type": "Annotation",
                "motivation": "http://librarysimplified.org/terms/annotation/idling",
                "target":[
                    "source": book.identifier,
                    "selector": [
                        "type": "oa:FragmentSelector",
                        "value": cfi
                    ]
                ]
                ] as [String : Any]
            
            //
            
            let url: NSURL = NYPLConfiguration.circulationURL().appendingPathComponent("annotations/") as NSURL
            
            Alamofire.request(url.absoluteString!, method: .post, parameters: parameters, encoding: JSONEncoding.default, headers: nil).responseJSON { (response:DataResponse<Any>) in
                
                self.statusCode = (response.response?.statusCode)!
                
                switch(response.result) {
                case .success(_):
                    if(response.response?.statusCode == 200) {
                        self.success = true
                    } else {
                        self.success = false
                    }
                    break
                    
                case .failure(_):
                    self.success = false
                    break
                    
                }
            }
            
        }
        
        //default completion block is called on finish
        if !self.isCancelled {
            self.finish()
        }
        
    }
    
    func finish() {
        // Notify the completion of async task and hence the completion of the operation
        _executing = false
        _finished = true
    }
    
}

