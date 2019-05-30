# receive_sharing_intent_example


## Android

android/app/src/main/manifest.xml
```xml
<manifest xmlns:android="http://schemas.android.com/apk/res/android"
.....
 <uses-permission android:name="android.permission.READ_EXTERNAL_STORAGE"/>

  <application
        android:name="io.flutter.app.FlutterApplication"
        ...
        >

    <activity
            android:name=".MainActivity"
            android:launchMode="singleTop"
            android:theme="@style/LaunchTheme"
            android:configChanges="orientation|keyboardHidden|keyboard|screenSize|locale|layoutDirection|fontScale|screenLayout|density|uiMode"
            android:hardwareAccelerated="true"
            android:windowSoftInputMode="adjustResize">

            <intent-filter>
                <action android:name="android.intent.action.SEND" />
                <category android:name="android.intent.category.DEFAULT" />
                <data android:mimeType="image/*" />
            </intent-filter>

            <intent-filter>
                <action android:name="android.intent.action.SEND_MULTIPLE" />
                <category android:name="android.intent.category.DEFAULT" />
                <data android:mimeType="image/*" />
            </intent-filter>
      </activity>
      
  </application>
</manifest>
....
```

### iOS

#### 1. Add the following
ios/Runner/info.plist
```xml
...
<key>CFBundleURLTypes</key>
	<array>
		<dict>
			<key>CFBundleTypeRole</key>
			<string>Editor</string>
			<key>CFBundleURLSchemes</key>
			<array>
				<string>SharePhotos</string>
			</array>
		</dict>
		<dict/>
	</array>

  <key>NSPhotoLibraryUsageDescription</key>
	<string>To upload photos, please allow permission to access your photo library.</string>
...
```

#### 2. Create Share Extension

- Using xcode, go to File/New/Target and Choose "Share Extension"
- Give it a name i.e. "Share Extension"


##### Add the following code:
ios/Share Extension/info.plist
```xml
....
	<string>$(FLUTTER_BUILD_NAME)</string>
	<key>CFBundleVersion</key>
	<string>$(FLUTTER_BUILD_NUMBER)</string>
	<key>NSExtension</key>
	<dict>
		<key>NSExtensionAttributes</key>
        <dict>
            <key>NSExtensionActivationRule</key>
            <dict>
                <key>NSExtensionActivationSupportsImageWithMaxCount</key>
                <integer>100</integer>
            </dict>
        </dict>
		<key>NSExtensionMainStoryboard</key>
		<string>MainInterface</string>
		<key>NSExtensionPointIdentifier</key>
		<string>com.apple.share-services</string>
	</dict>
....
```

ios/Share Extension/ShareViewContriller.swift
```swift

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
```

#### 3. Add Runner and Share Extension in the same group

* Go to the Capabilities tab and switch on the App Groups switch for both targets. Add a new group and name it `group.YOUR_HOST_APP_BUNDLE_IDENTIFIER` in my case `group.com.kasem.sharing`


#### 4. Compiling issues and their fixes

* Error: App does not build after adding Share Extension?
* Fix: Check Build Settings of your share extension and remove everything that tries to import Cocoapods from your main project. i.e. under `Linking/Other Linker Flags` 

* You might need to disable bitcode for the extension target

* Error: Invalid Bundle. The bundle at 'Runner.app/Plugins/Sharing Extension.appex' contains disallowed file 'Frameworks'
* Fix: https://stackoverflow.com/a/25789145/2061365



## Full Example

```dart

import 'package:flutter/material.dart';
import 'dart:async';

import 'package:receive_sharing_intent/receive_sharing_intent.dart';

void main() => runApp(MyApp());

class MyApp extends StatefulWidget {
  @override
  _MyAppState createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  StreamSubscription _intentDataStreamSubscription;
  List<Uri> _sharedFiles;

  @override
  void initState() {
    super.initState();

    // For sharing images coming from outside the app while the app is in the memory
    _intentDataStreamSubscription =
        ReceiveSharingIntent.getIntentDataStreamAsUri().listen(
            (List<Uri> uris) {
      _sharedFiles = uris;
    }, onError: (err) {
      print("Latest Intent Data error: $err");
    });

    // For sharing images coming from outside the app while the app is closed
    ReceiveSharingIntent.getInitialIntentDataAsUri().then((List<Uri> uris) {
      _sharedFiles = uris;
    });
  }

  @override
  void dispose() {
    _intentDataStreamSubscription.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(
          title: const Text('Plugin example app'),
        ),
        body: Center(
          child: Text('Number of shared files: ${_sharedFiles?.length ?? 0}'),
        ),
      ),
    );
  }
}
```

