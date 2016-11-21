//
//  NNYPLAnnotations.swift
//  Simplified
//
//  Created by Aferdita Muriqi on 10/18/16.
//  Copyright © 2016 NYPL Labs. All rights reserved.
//

import UIKit
import Alamofire
import ReachabilitySwift

class NYPLAnnotations: NSObject {
    static let maxRetryCount: Int = 3
    static var reachability: Reachability!
    static var isReachable: Bool {return reachability.isReachable()}
    
    private static var annotationsQueue:NSOperationQueue = {
        var queue = NSOperationQueue()
        queue.name = "AnnotationsQueue"
        queue.maxConcurrentOperationCount = 1
        queue.qualityOfService = .Utility
        //suspend queued operations if server is not reachable
        queue.suspended = !isReachable
        return queue
    }()
    
    private static var lastReadBookQueue:NSOperationQueue = {
        var queue = NSOperationQueue()
        queue.name = "lastReadBookQueue"
        queue.maxConcurrentOperationCount = 1
        queue.qualityOfService = .Utility
        //suspend queued operations if server is not reachable
        queue.suspended = !isReachable
        return queue
    }()
    
    override class func initialize () {
        //this host could change, we may need to observe for chage and reinitialize
        var host: String { return NYPLConfiguration.mainFeedURL().host!}
        
        do {
            reachability = try Reachability(hostname: host)
        } catch {
            Log.error(#file,"Unable to create Reachability")
        }
        
        NSNotificationCenter.defaultCenter().addObserver(self, selector: #selector(self.reachabilityChanged),name: ReachabilityChangedNotification,object: reachability)
        NSNotificationCenter.defaultCenter().addObserver(self, selector: #selector(applicationDidEnterBackground), name: UIApplicationDidEnterBackgroundNotification, object: nil)
        NSNotificationCenter.defaultCenter().addObserver(self, selector: #selector(applicationDidEnterForeground), name: UIApplicationWillEnterForegroundNotification, object: nil)
        
        do {
            
            try reachability?.startNotifier()
        } catch {
            Log.error(#file,"Unable to start notifier")
        }
        
    }
    
    @objc private class func reachabilityChanged(note: NSNotification) {
        
        let reachability = note.object as! Reachability
        
        if reachability.isReachable() {
            if reachability.isReachableViaWiFi() {
                Log.debug(#file,"Reachable via WiFi")
            } else {
                Log.debug(#file,"Reachable via Cellular")
            }
            
        } else {
            Log.debug(#file,"Network not reachable")
        }
        //suspend queued operations if server is not reachable
        annotationsQueue.suspended = !reachability.isReachable()
        lastReadBookQueue.suspended = !reachability.isReachable()
    }
    
    func applicationDidEnterBackground() {
        //Currently only writing lastreadqueue, placeholder for annotation queue
        
        Log.debug(#file,"App moved to background!")
        Log.debug(#file,"Suspending analyticsQueue")
        
        //suspend current operations while we attempt to write the contents to file
        NYPLAnnotations.annotationsQueue.suspended = true
        NYPLAnnotations.lastReadBookQueue.suspended = true
        
        //write operations to file if there are any still queued
        if(NYPLAnnotations.lastReadBookQueue.operations.count == 0) {
            return;
        }
        
        do {
            
            let file = NYPLAnnotations.lastReadBookQueue.name! + ".plist" //this is the file. we will write to and read from it
            
            if let dir = NSSearchPathForDirectoriesInDomains(NSSearchPathDirectory.DocumentDirectory, NSSearchPathDomainMask.AllDomainsMask, true).first {
                let path = NSURL(fileURLWithPath: dir).URLByAppendingPathComponent(file)
                NSKeyedArchiver.archiveRootObject(NYPLAnnotations.lastReadBookQueue.operations, toFile: (path?.path)!)            }
        }
        
        //we have archived the operations, so remove them all from the active queue
        NYPLAnnotations.lastReadBookQueue.cancelAllOperations()
        
        //TODO: future state handle annotation queue in the same mannor
        
    }
    
    func applicationDidEnterForeground() {
        //read file into queue if it exists, then enable queues if needed
        
        let file = NYPLAnnotations.lastReadBookQueue.name! + ".plist" //this is the file we will read from
        let fileManager = NSFileManager.defaultManager()
        
        if let dir = NSSearchPathForDirectoriesInDomains(NSSearchPathDirectory.DocumentDirectory, NSSearchPathDomainMask.AllDomainsMask, true).first {
            let path = NSURL(fileURLWithPath: dir).URLByAppendingPathComponent(file)
            
            if(fileManager.fileExistsAtPath((path?.path)!)) {
                
                do {
                    let operations: [NYPLLastReadBookOperation] = NSKeyedUnarchiver.unarchiveObjectWithFile((path?.path)!) as! [NYPLLastReadBookOperation]
                    NYPLAnnotations.lastReadBookQueue.addOperations(operations, waitUntilFinished: true)
                    //we have sucessfully read the file back in, remove it
                    try! fileManager.removeItemAtURL(path!)
                    
                }
                
            }
            
        }
        
        NYPLAnnotations.lastReadBookQueue.suspended = !NYPLAnnotations.isReachable
        
        Log.debug(#file,"App moved to foreground!")
        
        //TODO: future state handle annotation queue in the same mannor
        NYPLAnnotations.annotationsQueue.suspended = !NYPLAnnotations.isReachable
        
    }
    
    class func postLastRead(book:NYPLBook, cfi:NSString) {
        self.postLastRead(book, retryCount: 0, cfi:cfi)
    }
    
    class func postLastRead(book:NYPLBook, retryCount: Int, cfi:NSString)
    {
        
        let lastReadBookOperation = NYPLLastReadBookOperation(cfi: cfi as String, book: book)
        
        lastReadBookOperation.completionBlock = {
            
            //added max retry count just in case the failure was not do to loss of internet, possible mailformation
            //of the url or server side issues
            if(!lastReadBookOperation.success && !reachability.isReachable() && lastReadBookOperation.retryCount < maxRetryCount) {
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
    
    class func syncLastRead(book:NYPLBook, completionHandler: (responseObject: String?,
        error: NSError?) -> ()) {
        
        func convertDataToDictionary(data: NSData) -> [String:AnyObject]? {
            do {
                return try NSJSONSerialization.JSONObjectWithData(data, options: []) as? [String:AnyObject]
            } catch let error as NSError {
                print(error)
            }
            return nil
        }
        
        if (NYPLAccount.sharedAccount().hasBarcodeAndPIN())
        {
            if book.annotationsURL != nil {
                
                Alamofire.request(.GET, book.annotationsURL.absoluteString!, headers: NYPLAnnotations.headers).response { (request, response, data, error) in
                    
                    if error == nil
                    {
                        let json = convertDataToDictionary(data!)
                        
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
                                    
                                    completionHandler(responseObject: value as String!, error: error)
                                    print(value)
                                }
                            }
                        }
                        else
                        {
                            completionHandler(responseObject: nil, error: error)
                        }
                    }
                    else
                    {
                        completionHandler(responseObject: nil, error: error)
                    }
                }
            }
        }
    }
    
    class func sync(book:NYPLBook, completionHandler: (responseObject: String?, error: NSError?) -> ()) {
        syncLastRead(book, completionHandler: completionHandler)
    }
    
    // Server currently not validating authentication in header, but including
    // with call in case that changes in the future
    class var headers:[String:String]
    {
        let authenticationString = "\(NYPLAccount.sharedAccount().barcode):\(NYPLAccount.sharedAccount().PIN)"
        let authenticationData:NSData = authenticationString.dataUsingEncoding(NSASCIIStringEncoding)!
        let authenticationValue = "Basic \(authenticationData.base64EncodedStringWithOptions(NSDataBase64EncodingOptions.Encoding64CharacterLineLength)))"
        
        let headers = [
            "Authorization": "\(authenticationValue)"      ]
        
        return headers
    }
    
}

final class NYPLLastReadBookOperation: NSOperation, NSCoding {
    
    let book: NYPLBook
    let cfi:NSString
    private(set) var success: Bool = true
    private(set) var statusCode: Int = 0
    private(set) var retryCount: Int
    
    init(cfi: String, book: NYPLBook) {
        self.book = book
        self.cfi = cfi
        self.retryCount = 0
        super.init()
    }
    
    init(cfi: String, book: NYPLBook, retryCount: Int) {
        self.book = book
        self.cfi = cfi
        self.retryCount = retryCount
        super.init()
    }
    
    convenience init?(coder aDecoder: NSCoder) {
        
        guard let book = aDecoder.decodeObjectForKey("book") as? NYPLBook,
            let cfi = aDecoder.decodeObjectForKey("cfi") as? String
            else { return nil }
        
        self.init(
            cfi: cfi,
            book: book
        )
        
    }
    
    func encodeWithCoder(aCoder: NSCoder) {
        
        aCoder.encodeObject(self.cfi, forKey: "cfi")
        aCoder.encodeObject(self.book, forKey: "book")
        
    }
    
    override var asynchronous: Bool {
        return true
    }
    
    private var _executing = false {
        willSet {
            willChangeValueForKey("isExecuting")
        }
        didSet {
            didChangeValueForKey("isExecuting")
        }
    }
    
    override var executing: Bool {
        return _executing
    }
    
    private var _finished = false {
        willSet {
            willChangeValueForKey("isFinished")
        }
        
        didSet {
            didChangeValueForKey("isFinished")
        }
    }
    
    override var finished: Bool {
        return _finished
    }
    
    override func start() {
        
        if cancelled {
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
        
        if (NYPLAccount.sharedAccount().hasBarcodeAndPIN())
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
            ]
            
            Alamofire.request(.POST, NYPLConfiguration.circulationURL().URLByAppendingPathComponent("annotations/")!, parameters:parameters, encoding: .JSON, headers:NYPLAnnotations.headers).response(completionHandler: { (request, response, data, error) in
                
                if response?.statusCode == 200
                {
                    print("post last read successful")
                }
            })
            
        }
        
    }
    
    func finish() {
        // Notify the completion of async task and hence the completion of the operation
        _executing = false
        _finished = true
    }
    
}

