/*
 Copyright (C) 2017 Apple Inc. All Rights Reserved.
 See LICENSE.txt for this sample’s licensing information
 
 Abstract:
 Object encapsulating information about an iOS app in the 'Top Paid Apps' RSS feed.
 Each one corresponds to a row in the app's table.
 */

import UIKit

class AppRecord: NSObject, Identifiable {
   var appName: String?
   var appIcon: UIImage?
   var artist: String?
   var imageURLString: String?
   var appURLString: String?
}

