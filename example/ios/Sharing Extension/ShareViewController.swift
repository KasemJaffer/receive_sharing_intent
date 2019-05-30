//
//  ShareViewController.swift
//  Sharing Extension
//
//  Created by Kasem Mohamed on 2019-05-30.
//  Copyright © 2019 The Chromium Authors. All rights reserved.
//

import UIKit
import Social
import MobileCoreServices
import Photos

class ShareViewController: SLComposeServiceViewController {

    let sharedKey = "ImageSharePhotoKey"
    var imagesData: [String] = []
    
    override func isContentValid() -> Bool {
        return true
    }
    
    override func viewDidLoad() {
        // This is called after the user selects Post. Do the upload of contentText and/or NSExtensionContext attachments.
        
        if let content = extensionContext!.inputItems[0] as? NSExtensionItem {
            let contentType = kUTTypeImage as String
            
            if let contents = content.attachments {
                for (index, attachment) in (contents as! [NSItemProvider]).enumerated() {
                    if attachment.hasItemConformingToTypeIdentifier(contentType) {
                        attachment.loadItem(forTypeIdentifier: contentType, options: nil) { [weak self] data, error in
                            
                            if error == nil, let url = data as? URL, let this = self {
                                
                                // Prefix check: image is shared from Photos app
                                if url.path.hasPrefix("/var/mobile/Media/") {
                                    for component in url.path.components(separatedBy: "/") where component.contains("IMG_") {
                                        
                                        // photo: /var/mobile/Media/DCIM/101APPLE/IMG_1320.PNG
                                        // edited photo: /var/mobile/Media/PhotoData/Mutations/DCIM/101APPLE/IMG_1309/Adjustments/FullSizeRender.jpg
                                        
                                        // cut file's suffix if have, get file name like IMG_1309.
                                        let fileName = component.components(separatedBy: ".").first!
                                        if let asset = this.imageAssetDictionary[fileName] {
                                            this.imagesData.append( asset.localIdentifier)
                                        }
                                        break
                                    }
                                }
                                
                                // If this is the last item, save imagesData in userDefaults and redirect to host app
                                if index == (content.attachments?.count)! - 1 {
                                    // TODO: IMPROTANT: This should be your host app bundle identiefier
                                    let hostAppBundleIdentiefier = "com.kasem.sharing"
                                    let userDefaults = UserDefaults(suiteName: "group.\(hostAppBundleIdentiefier)")
                                    userDefaults?.set(this.imagesData, forKey: this.sharedKey)
                                    userDefaults?.synchronize()
                                    this.redirectToHostApp()
                                    this.extensionContext!.completeRequest(returningItems: [], completionHandler: nil)
                                }
                                
                            } else {
                                print("GETTING ERROR")
                                let alert = UIAlertController(title: "Error", message: "Error loading image", preferredStyle: .alert)
                                
                                let action = UIAlertAction(title: "Error", style: .cancel) { _ in
                                    self?.dismiss(animated: true, completion: nil)
                                }
                                
                                alert.addAction(action)
                                self?.present(alert, animated: true, completion: nil)
                                self?.extensionContext!.completeRequest(returningItems: [], completionHandler: nil)
                            }
                        }
                    }
                }
            }
        }
    }
    
    override func configurationItems() -> [Any]! {
        // To add configuration options via table cells at the bottom of the sheet, return an array of SLComposeSheetConfigurationItem here.
        return []
    }
    
    private func redirectToHostApp() {
        let url = URL(string: "SharePhotos://dataUrl=\(sharedKey)")
        var responder = self as UIResponder?
        let selectorOpenURL = sel_registerName("openURL:")
        
        while (responder != nil) {
            if (responder?.responds(to: selectorOpenURL))! {
                let _ = responder?.perform(selectorOpenURL, with: url)
            }
            responder = responder!.next
        }
    }
    
    /// Key is the matched asset's original file name without suffix. E.g. IMG_193
    private lazy var imageAssetDictionary: [String : PHAsset] = {
        
        let options = PHFetchOptions()
        options.includeHiddenAssets = true
        
        let fetchResult = PHAsset.fetchAssets(with: options)
        
        var assetDictionary = [String : PHAsset]()
        
        for i in 0 ..< fetchResult.count {
            let asset = fetchResult[i]
            let fileName = asset.value(forKey: "filename") as! String
            let fileNameWithoutSuffix = fileName.components(separatedBy: ".").first!
            assetDictionary[fileNameWithoutSuffix] = asset
        }
        
        return assetDictionary
    }()
}
