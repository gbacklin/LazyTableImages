//
//  RSSReader.swift
//  LazyTableImages LazyTableImages.xcodeproj LazyTableImagesTests LazyTableImages
//
//  Created by Gene Backlin on 6/21/21.
//

import Foundation

let TopPaidAppsFeed = "https://rss.itunes.apple.com/api/v1/us/ios-apps/top-paid/all/50/explicit.atom"

public class RSSReader: ObservableObject {
    @Published var entries: [AppRecord]?

    // the queue to run our "ParseOperation"
    var queue: OperationQueue?
    
    // the Operation driving the parsing of the RSS feed
    var parser: ParseOperation?

    init(){
        fetchRSSFeed(urlString: TopPaidAppsFeed)
    }
    
    func load() async {
        debugPrint("Loading...")
        fetchRSSFeed(urlString: TopPaidAppsFeed)
    }
    
    func reload() {
        debugPrint("reloading...")
        fetchRSSFeed(urlString: TopPaidAppsFeed)
    }
    
    func fetchRSSFeed(urlString: String) {
        weak var weakSelf = self
        
        let request: URLRequest = URLRequest(url: URL(string: urlString)!)
        let sessionTask: URLSessionDataTask = URLSession.shared.dataTask(with: request) { (data, response, error) in
            // in case we want to know the response status code
            // let HTTPStatusCode = (response as! HTTPURLResponse).statusCode
            
            if error != nil {
                OperationQueue.main.addOperation({
                    if (error! as NSError).code == NSURLErrorAppTransportSecurityRequiresSecureConnection {
                        // if you get error NSURLErrorAppTransportSecurityRequiresSecureConnection (-1022),
                        // then your Info.plist has not been properly configured to match the target server.
                        //
                        abort();
                    } else {
                        weakSelf!.handleError(error: error!)
                    }
                })
            } else {
                // create the queue to run our ParseOperation
                weakSelf!.queue = OperationQueue()
                
                // create an ParseOperation (NSOperation subclass) to parse the RSS feed data so that the UI is not blocked
                weakSelf!.parser = ParseOperation(data: data!)
                weakSelf!.parser?.errorHandler = {
                    parseError in
                    DispatchQueue.main.async {
                        weakSelf!.handleError(error: parseError!)
                    }
                }
                
                weakSelf!.parser?.completionBlock = {
                    // The completion block may execute on any thread.  Because operations
                    // involving the UI are about to be performed, make sure they execute on the main thread.
                    //
                    DispatchQueue.main.async {
                        if weakSelf!.parser?.appRecordList != nil {
                            weakSelf!.entries = weakSelf!.parser?.appRecordList
                        }
                    }
                    // we are finished with the queue and our ParseOperation
                    weakSelf!.queue = nil
                }
                weakSelf!.queue?.addOperation(weakSelf!.parser!) // this will start the "ParseOperation"
            }
        }
        sessionTask.resume()
    }
    
    func handleError(error: Error) {
        debugPrint(error)
    }
}
