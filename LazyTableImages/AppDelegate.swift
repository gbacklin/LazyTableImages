/*
 Copyright (C) 2017 Apple Inc. All Rights Reserved.
 See LICENSE.txt for this sample’s licensing information
 
 Abstract:
 Application delegate for the LazyTableImages sample.
 It also downloads in the background the "Top Paid iPhone Apps" RSS feed using NSURLSession/NSURLSessionDataTask.
 */

import UIKit

let TopPaidAppsFeed = "http://phobos.apple.com/WebObjects/MZStoreServices.woa/ws/RSS/toppaidapplications/limit=75/xml"

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {
    
    var window: UIWindow?
    
    // the queue to run our "ParseOperation"
    var queue: OperationQueue?
    
    // the Operation driving the parsing of the RSS feed
    var parser: ParseOperation?
    
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplicationLaunchOptionsKey: Any]?) -> Bool {
        // Override point for customization after application launch.
        
        fetchRSSFeed(urlString: TopPaidAppsFeed)
        
        return true
    }
    
    func applicationWillResignActive(_ application: UIApplication) {
        // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
        // Use this method to pause ongoing tasks, disable timers, and invalidate graphics rendering callbacks. Games should use this method to pause the game.
    }
    
    func applicationDidEnterBackground(_ application: UIApplication) {
        // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later.
        // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
    }
    
    func applicationWillEnterForeground(_ application: UIApplication) {
        // Called as part of the transition from the background to the active state; here you can undo many of the changes made on entering the background.
    }
    
    func applicationDidBecomeActive(_ application: UIApplication) {
        // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
    }
    
    func applicationWillTerminate(_ application: UIApplication) {
        // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
    }
    
    func fetchRSSFeed(urlString: String) {
        weak var weakSelf = self
        
        let request: URLRequest = URLRequest(url: URL(string: urlString)!)
        let sessionTask: URLSessionDataTask = URLSession.shared.dataTask(with: request) { (data, response, error) in
            // in case we want to know the response status code
            // let HTTPStatusCode = (response as! HTTPURLResponse).statusCode
            
            if error != nil {
                OperationQueue.main.addOperation({
                    UIApplication.shared.isNetworkActivityIndicatorVisible = false
                    
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
                        UIApplication.shared.isNetworkActivityIndicatorVisible = false
                        weakSelf!.handleError(error: parseError!)
                    }
                }
                
                weakSelf!.parser?.completionBlock = {
                    // The completion block may execute on any thread.  Because operations
                    // involving the UI are about to be performed, make sure they execute on the main thread.
                    //
                    DispatchQueue.main.async {
                        UIApplication.shared.isNetworkActivityIndicatorVisible = false
                        if weakSelf!.parser?.appRecordList != nil {
                            let rootViewController: RootViewController = (weakSelf!.window?.rootViewController as! UINavigationController).topViewController as! RootViewController
                            rootViewController.entries = weakSelf!.parser?.appRecordList
                            // tell our table view to reload its data, now that parsing has completed
                            rootViewController.tableView.reloadData()
                        }
                    }
                    
                    // we are finished with the queue and our ParseOperation
                    weakSelf!.queue = nil
                }
                weakSelf!.queue?.addOperation(weakSelf!.parser!) // this will start the "ParseOperation"
            }
        }
        sessionTask.resume()
        
        // show in the status bar that network activity is starting
        UIApplication.shared.isNetworkActivityIndicatorVisible = true
    }
    
    func handleError(error: Error) {
        let errorMessage = error.localizedDescription
        
        // alert user that our current record was deleted, and then we leave this view controller
        //
        let alert: UIAlertController = UIAlertController(title: NSLocalizedString("Cannot Show Top Paid Apps", comment: ""), message: errorMessage, preferredStyle: .actionSheet)
        let OKAction: UIAlertAction = UIAlertAction(title: NSLocalizedString("OK", comment: ""), style: .default) { (action) in
            // dissmissal of alert completed
        }
        alert.addAction(OKAction)
        window?.rootViewController?.present(alert, animated: true, completion: nil)
        
    }
}

