import Foundation
import Alamofire
import ReachabilitySwift


//TODO: final task is to handle app backgrounding, that could lead to app termination.  If the application does not have internet access in this scenerio, the pending, queued event would be lost if terminated.  Note, event will only be lost if the applciation is terminated, backgrounding in and of itself will not cause event to be lost

// This class encapsulates analytic events sent to the server.
final class NYPLCirculationAnalytics : NSObject {
    static let maxRetryCount: Int = 3
    static var reachability: Reachability!
    static var isReachable: Bool {return reachability.isReachable()}
    private static var analyticsQueue:NSOperationQueue = {
        var queue = NSOperationQueue()
        queue.name = "AnalyticsQueue"
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
        analyticsQueue.suspended = !reachability.isReachable()
    }
    
    func applicationDidEnterBackground() {
        Log.debug(#file,"App moved to background!")
        Log.debug(#file,"Suspending analyticsQueue")
        var fileWriteSuccess: Bool = false
        
        //suspend current operations while we attempt to write the contents to file
        NYPLCirculationAnalytics.analyticsQueue.suspended = true
        
        //write operations to file if there are any still queued
        if(NYPLCirculationAnalytics.analyticsQueue.operations.count == 0) {
            return;
        }
        
        do {
            let data = try! NSJSONSerialization.dataWithJSONObject(NYPLCirculationAnalytics.analyticsQueue.operations, options: [])
            
            if(data.length == 0) {
                return
            }
            
            let file = NYPLCirculationAnalytics.analyticsQueue.name! + ".plist" //this is the file. we will write to and read from it
            
            if let dir = NSSearchPathForDirectoriesInDomains(NSSearchPathDirectory.DocumentDirectory, NSSearchPathDomainMask.AllDomainsMask, true).first {
                let path = NSURL(fileURLWithPath: dir).URLByAppendingPathComponent(file)
                
                if(!data.writeToFile(path!.absoluteString!, atomically: true)) {
                    Log.error(#file,"Unable to write NYPLCirculationAnalytics.analyticsQueue data to file")
                } else {
                    fileWriteSuccess = true
                }
            }
        }
        
        if(fileWriteSuccess) {
            NYPLCirculationAnalytics.analyticsQueue.cancelAllOperations()
        }
        
    }
    
    func applicationDidEnterForeground() {
        
        //read file into queue if it exists, then enable queues if needed
        
        let file = NYPLCirculationAnalytics.analyticsQueue.name! + ".plist" //this is the file we will read from
        let fileManager = NSFileManager.defaultManager()
        
        if let dir = NSSearchPathForDirectoriesInDomains(NSSearchPathDirectory.DocumentDirectory, NSSearchPathDomainMask.AllDomainsMask, true).first {
            let path = NSURL(fileURLWithPath: dir).URLByAppendingPathComponent(file)
            let data: NSData? = NSData(contentsOfFile: (path?.absoluteString)!)
            do {
                if let jsonObject: NSDictionary = try! NSJSONSerialization.JSONObjectWithData(data!, options: NSJSONReadingOptions.MutableContainers) as? NSDictionary
                {
                    try! fileManager.removeItemAtURL(path!)
                    Log.debug(#file,jsonObject.description)
                } else {
                    Log.error(#file,"Unable to read NYPLCirculationAnalytics.analyticsQueue data from file")
                }
            }
            
        }
        
        NYPLCirculationAnalytics.analyticsQueue.suspended = !NYPLCirculationAnalytics.isReachable
        Log.debug(#file,"App moved to foreground!")
    }
    
    class func postEvent(event: String, withBook book: NYPLBook) -> Void {
        self.postEvent(event, withBook: book)
    }
    
    //private varient for tracking retries
    private class func postEvent(event: String, retryCount: Int, withBook book: NYPLBook) -> Void {
        let analyticsOperation = NYPLCirculationAnalyticsOperation(event: event, book: book)
        
        analyticsOperation.completionBlock = {
            
            //added max retry count just in case the failure was not do to loss of internet, possible mailformation
            //of the url or server side issues
            if(!analyticsOperation.success && !reachability.isReachable() && analyticsOperation.retryCount < maxRetryCount) {
                //we need to add this operation back into the queue, internet was lost while in progress
                //if order is importent, we need to remove all queued operations, then re-add starting with this one
                self.postEvent(analyticsOperation.event, retryCount: analyticsOperation.retryCount+1, withBook: analyticsOperation.book)
            } else {
                Log.error(#file, "Error posting event, retry count exceeds maximum or error occured on server side")
            }
            
        }
        
        analyticsQueue.addOperation(analyticsOperation)
    }
    
}

class NYPLCirculationAnalyticsOperation: NSOperation {
    
    let book: NYPLBook
    let event: String
    private(set) var success: Bool = true
    private(set) var statusCode: Int = 0
    private(set) var retryCount: Int
    
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
        
        let requestURL = self.book.analyticsURL.URLByAppendingPathComponent(self.event)
        
        Alamofire.request(.GET, requestURL!, headers: NYPLCirculationAnalyticsOperation.headers).response {
            (request, response, data, error)  in
            
            self.statusCode = response!.statusCode
            
            if (error != nil) || (response?.statusCode != 200) {
                self.success = false
            }
            
            //default completion block is called on finish
            if !self.cancelled {
                self.finish()
            }
            
        }
        
    }
    
    func finish() {
        // Notify the completion of async task and hence the completion of the operation
        _executing = false
        _finished = true
    }
    
    // Server currently not validating authentication in header, but including
    // with call in case that changes in the future
    private class var headers:[String:String] {
        let authenticationString = "\(NYPLAccount.sharedAccount().barcode):\(NYPLAccount.sharedAccount().PIN)"
        let authenticationData = authenticationString.dataUsingEncoding(NSASCIIStringEncoding)
        let authenticationValue = "Basic \(authenticationData?.base64EncodedStringWithOptions(NSDataBase64EncodingOptions.Encoding64CharacterLineLength)))"
        
        let headers = [
            "Authorization": "\(authenticationValue)"
        ]
        
        return headers
    }
    
}
