import Foundation
import Alamofire

// This class encapsulates analytic events sent to the server.
final class NYPLCirculationAnalytics : NSObject {
    static let maxRetryCount: Int = 3
    static var reachability: NetworkReachabilityManager!
    
    static var isReachable: Bool {return reachability.isReachable}
    private static var analyticsQueue:OperationQueue = {
        var queue = OperationQueue()
        queue.name = "AnalyticsQueue"
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
            NYPLCirculationAnalytics.reachabilityChanged()
        }

        reachability?.startListening()
        
    }
    
    @objc fileprivate class func reachabilityChanged() {
        
       if reachability.isReachable {
            Log.debug(#file,"Reachable true")
        } else {
            Log.debug(#file,"Network not reachable")
        }
        //suspend queued operations if server is not reachable
        analyticsQueue.isSuspended = !reachability.isReachable

}
    
    func applicationDidEnterBackground() {
        Log.debug(#file,"App moved to background!")
        Log.debug(#file,"Suspending analyticsQueue")
        
        //suspend current operations while we attempt to write the contents to file
        NYPLCirculationAnalytics.analyticsQueue.isSuspended = true
        
        //write operations to file if there are any still queued
        if(NYPLCirculationAnalytics.analyticsQueue.operations.count == 0) {
            return;
        }
        
        do {
            
            let file = NYPLCirculationAnalytics.analyticsQueue.name! + ".plist" //this is the file. we will write to and read from it
            
            if let dir = NSSearchPathForDirectoriesInDomains(FileManager.SearchPathDirectory.documentDirectory, FileManager.SearchPathDomainMask.allDomainsMask, true).first {
                let path = URL(fileURLWithPath: dir).appendingPathComponent(file)
                NSKeyedArchiver.archiveRootObject(NYPLCirculationAnalytics.analyticsQueue.operations, toFile: (path.path))
            }
        }
        
        //we have archived the operations, so remove them all from the active queue
        NYPLCirculationAnalytics.analyticsQueue.cancelAllOperations()
        
    }
    
    func applicationDidEnterForeground() {
        
        //read file into queue if it exists, then enable queues if needed
        
        let file = NYPLCirculationAnalytics.analyticsQueue.name! + ".plist" //this is the file we will read from
        let fileManager = FileManager.default
        
        if let dir = NSSearchPathForDirectoriesInDomains(FileManager.SearchPathDirectory.documentDirectory, FileManager.SearchPathDomainMask.allDomainsMask, true).first {
            let path = URL(fileURLWithPath: dir).appendingPathComponent(file)
            
            if(fileManager.fileExists(atPath: (path.path))) {
                
                do {
                    let operations: [NYPLCirculationAnalyticsOperation] = NSKeyedUnarchiver.unarchiveObject(withFile: (path.path)) as! [NYPLCirculationAnalyticsOperation]
                    NYPLCirculationAnalytics.analyticsQueue.addOperations(operations, waitUntilFinished: true)
                    //we have sucessfully read the file back in, remove it
                    try! fileManager.removeItem(at: path)
                    
                }
                
            }
            
        }
        
        NYPLCirculationAnalytics.analyticsQueue.isSuspended = !NYPLCirculationAnalytics.isReachable
        Log.debug(#file,"App moved to foreground!")
    }
    
    class func postEvent(_ event: String, withBook book: NYPLBook) -> Void {
        self.postEvent(event, withBook: book)
    }
    
    //private varient for tracking retries
    fileprivate class func postEvent(_ event: String, retryCount: Int, withBook book: NYPLBook) -> Void {
        let analyticsOperation = NYPLCirculationAnalyticsOperation(event: event, book: book)
        
        analyticsOperation.completionBlock = {
            
            //added max retry count just in case the failure was not do to loss of internet, possible mailformation
            //of the url or server side issues
            if(!analyticsOperation.success && !reachability.isReachable && analyticsOperation.retryCount < maxRetryCount) {
                //we need to add this operation back into the queue, internet was lost while in progress
                //if order is importent, we need to remove all queued operations, then re-add starting with this one
                self.postEvent(analyticsOperation.event, retryCount: analyticsOperation.retryCount+1, withBook: analyticsOperation.book)
            } else {
                Log.error(#file, "Error posting event, retry count exceeds maximum or error occured on server side")
            }
            
        }
        
        analyticsQueue.addOperation(analyticsOperation)
    }
    
    // Server currently not validating authentication in header, but including
    // with call in case that changes in the future
    fileprivate class var headers:[String:String] {
        let authenticationString = "\(NYPLAccount.shared().barcode):\(NYPLAccount.shared().pin)"
        let authenticationData = authenticationString.data(using: String.Encoding.ascii)
        let authenticationValue = "Basic \(authenticationData?.base64EncodedString(options: NSData.Base64EncodingOptions.lineLength64Characters)))"
        
        let headers = [
            "Authorization": "\(authenticationValue)"
        ]
        
        return headers
    }
    
}

final class NYPLCirculationAnalyticsOperation: Operation, NSCoding {
    
    let book: NYPLBook
    let event: String
    fileprivate(set) var success: Bool = true
    fileprivate(set) var statusCode: Int = 0
    fileprivate(set) var retryCount: Int
    
    init(event: String, book: NYPLBook) {
        self.book = book
        self.event = event
        self.retryCount = 0
        super.init()
    }
    
    init(event: String, book: NYPLBook, retryCount: Int) {
        self.book = book
        self.event = event
        self.retryCount = retryCount
        super.init()
    }
    
    convenience init?(coder aDecoder: NSCoder) {
        
        guard let book = aDecoder.decodeObject(forKey: "book") as? NYPLBook,
            let event = aDecoder.decodeObject(forKey: "event") as? String
            else { return nil }
        
        self.init(
            event: event,
            book: book
        )
        
    }
    
    func encode(with aCoder: NSCoder) {
        
        aCoder.encode(self.event, forKey: "event")
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
        
        let requestURL = self.book.analyticsURL.appendingPathComponent(self.event)
        
        Alamofire.request(requestURL, method: .get, parameters: ["":""], encoding: URLEncoding.default, headers: NYPLCirculationAnalytics.headers).responseJSON { (response:DataResponse<Any>) in
            
            self.statusCode = (response.response?.statusCode)!
            
            switch(response.result) {
            case .success(_):
                if (response.response?.statusCode != 200) {
                    self.success = false
                } else {
                    self.success = true
                }
                break
                
            case .failure(_):
                self.success = false
                break
                
            }
            
            //default completion block is called on finish
            if !self.isCancelled {
                self.finish()
            }
            
        }
        
    }
    
    func finish() {
        // Notify the completion of async task and hence the completion of the operation
        _executing = false
        _finished = true
    }
    
}
