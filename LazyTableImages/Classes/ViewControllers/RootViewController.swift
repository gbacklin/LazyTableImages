/*
 Copyright (C) 2017 Apple Inc. All Rights Reserved.
 See LICENSE.txt for this sample’s licensing information
 
 Abstract:
 Controller for the main table view of the LazyTable sample.
 This table view controller works off the AppDelege's data model.
 produce a three-stage lazy load:
 1. No data (i.e. an empty table)
 2. Text-only data from the model's RSS feed
 3. Images loaded over the network asynchronously
 
 This process allows for asynchronous loading of the table to keep the UI responsive.
 Stage 3 is managed by the AppRecord corresponding to each row/cell.
 
 Images are scaled to the desired height.
 If rapid scrolling is in progress, downloads do not begin until scrolling has ended.
 */

import UIKit

let kCustomRowCount = 7

// MARK: -

class RootViewController: UITableViewController {

    var imageDownloadsInProgress: [NSIndexPath : IconDownloader]?
    var entries: [AppRecord]?
    
    // MARK: - View Lifecycle
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        imageDownloadsInProgress = [NSIndexPath : IconDownloader]()
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // terminate all pending download connections
        terminateAllDownloads()
    }
    
    deinit {
        // terminate all pending download connections
       terminateAllDownloads()
    }
    
    // MARK: -
    
    func terminateAllDownloads() {
        // terminate all pending download connections
        let allDownloads = imageDownloadsInProgress!.values
        allDownloads.forEach { (iconDownloader) in
            iconDownloader.cancelDownload()
        }
        imageDownloadsInProgress!.removeAll()
    }
    
    // MARK: - Table cell image support
    // -------------------------------------------------------------------------------
    //    startIconDownload:forIndexPath:
    // -------------------------------------------------------------------------------
    func startIconDownload(appRecord: AppRecord, indexPath: NSIndexPath) {
        weak var weakSelf = self
        var iconDownloader: IconDownloader? = imageDownloadsInProgress![indexPath]
        if iconDownloader == nil {
            iconDownloader = IconDownloader()
            iconDownloader?.appRecord = appRecord
            iconDownloader?.completionHandler = {
                let cell: UITableViewCell = weakSelf!.tableView.cellForRow(at: indexPath as IndexPath)!
                
                // Display the newly loaded image
                cell.imageView?.image = appRecord.appIcon
                
                // Remove the IconDownloader from the in progress list.
                // This will result in it being deallocated.
                weakSelf!.imageDownloadsInProgress?.removeValue(forKey: indexPath)
            }
            imageDownloadsInProgress![indexPath] = iconDownloader
            iconDownloader?.startDownload()
        }
    }
    
    // -------------------------------------------------------------------------------
    //    loadImagesForOnscreenRows
    //  This method is used in case the user scrolled into a set of cells that don't
    //  have their app icons yet.
    // -------------------------------------------------------------------------------
    func loadImagesForOnscreenRows() {
        if Int(entries!.count) > 0 {
            let visiblePaths: [IndexPath] = tableView.indexPathsForVisibleRows!
            for indexPath in visiblePaths {
                let appRecord: AppRecord = entries![indexPath.row]
                
                // Avoid the app icon download if the app already has an icon
               if appRecord.appIcon == nil {
                    startIconDownload(appRecord: appRecord, indexPath: indexPath as NSIndexPath)
                }
            }
        }
    }
}

// MARK: - UITableViewDataSource

extension RootViewController {
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        var count = 0
        
        // if there's no data yet, return enough rows to fill the screen
        if entries != nil {
            count = entries!.count
        } else {
            count = kCustomRowCount
        }

        return count;
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        var cell: UITableViewCell!
        var nodeCount = 0
        
        if entries != nil {
            nodeCount = entries!.count
        }
        
        // Configure the cell...

        if nodeCount == 0 && indexPath.row == 0 {
            // add a placeholder cell while waiting on table data
            cell = tableView.dequeueReusableCell(withIdentifier: PlaceholderCellIdentifier, for: indexPath)
        } else {
            cell = tableView.dequeueReusableCell(withIdentifier: CellIdentifier, for: indexPath)
            // Leave cells empty if there's no data yet
            if nodeCount > 0 {
                // Set up the cell representing the app
                let appRecord: AppRecord = entries![indexPath.row]
                
                cell.textLabel?.text = appRecord.appName
                cell.detailTextLabel?.text = appRecord.artist
                
                // Only load cached images; defer new downloads until scrolling ends
                if appRecord.appIcon == nil {
                    if tableView.isDragging == false && tableView.isDecelerating == false {
                        startIconDownload(appRecord: appRecord, indexPath: indexPath as NSIndexPath)
                    }
                    // if a download is deferred or in progress, return a placeholder image
                    cell.imageView?.image = UIImage(named: "Placeholder.png")
                } else {
                    cell.imageView?.image = appRecord.appIcon
                }
            }
        }
        
        return cell
    }
}

// MARK: - UIScrollViewDelegate

extension RootViewController {
    
    override func scrollViewDidEndDragging(_ scrollView: UIScrollView, willDecelerate decelerate: Bool) {
        if decelerate == false {
            loadImagesForOnscreenRows()
        }
    }
    
    override func scrollViewDidEndDecelerating(_ scrollView: UIScrollView) {
        loadImagesForOnscreenRows()
    }
}
