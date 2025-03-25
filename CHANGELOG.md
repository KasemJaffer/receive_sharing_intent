## 1.8.1

* Fixed sharing not working on iOS 18

## 1.8.0

* Added support for cached images on iOS such as shared images from a Screenshot.

## 1.7.0

* Added `ReceiveSharingIntent.setMockValues` method to set mock values for testing purposes.
```dart
ReceiveSharingIntent.setMockValues(
      initialMedia: [],
      mediaStream: Stream.empty(),
    );
```
## Breaking change

* Use instance getter i.e. `ReceiveSharingIntent.instance.getInitialMedia()` instead of `ReceiveSharingIntent.getInitialMedia()`

## 1.6.8

* Fix sometimes file doesn't exist error on iOS

## 1.6.7

* Fix sharing url not working on iOS

## 1.6.6

* Fix compatibility issue with Android SDK <33

## 1.6.5

* Update deprecated API usage in Android

## 1.6.4

* Added a flag to disable the automatic closing of the share extension after sharing. 

```swift
class ShareViewController: RSIShareViewController {
    
    // Use this method to return false if you don't want to redirect to host app automatically.
    // Default is true
    override func shouldAutoRedirect() -> Bool {
        return false
    }
    
}
```
* Added new field `message` to the SharedMediaFile class.

## 1.6.3

* Updated readme iOS section, rearranged the steps to properly setup the plugin and added a new step #7

## 1.6.2

* Requires Swift 5.0
* Fix backward compatibility down to iOS 8.0
* Use UTType for iOS 14.0 and above

## 1.6.1

* Stop using UTType because it doesn't exist prior to iOS 14.0

## 1.6.0

### Breaking changes

* All files types now come through `getInitialMedia` and `getMediaStream`
* Your `ShareViewController` class should now inherit from `RSIShareViewController`. Eliminating the
  need to copy the whole class again. Please check the example project for more details.
* Removed `getInitialText`, `getInitialTextAsUri`, `getTextStream` and `getTextStreamAsUri` methods.
  Please use `getInitialMedia` and `getMediaStream` instead.

## 1.5.4

* Fix broken links in readme

## 1.5.3

* Update readme
* Code refactor, remove unnecessary semicolon and initialization of optional fields

## 1.5.2

* Fix wrong file path on iOS

## 1.5.1

* Update plugin's iOS build version

## 1.5.0

* Add support for custom group ID for iOS
* Update android gradle build tools to 7.3.1
* Replace deprecated jcenter with mavenCentral
* Update android to use compileSdkVersion 34

## 1.4.5

* Update android to use compileSdkVersion 30

## 1.4.4

* Enabled null safety
* Fix frozen app after sharing. Fix requires you to update your Sharing Extension Class (Check example project)
* Fix regression regarding link propagation

## 1.4.3

* Fix suppressed link propagation to other modules on iOS

## 1.4.2

* Migrate to flutter android embedding v2
* Fix crash while getting raw files path on Android

## 1.4.1

* Preserve original file name

Note. Updating your Sharing Extension Class is required (please check that in the example project)

## 1.4.0

* Added support for sharing any type of file

# Breaking changes

* In your project `ios/Runner/Info.plist` please change 'SharePhotos' to 'ShareMedia' as follows
```xml
    <key>CFBundleURLSchemes</key>
    <array>
    	<string>ShareMedia</string>
```

## 1.3.3

* Fixed the >= 4.2 Swift compiler parsing errors

## 1.3.2

* Fix Some photos and videos have wrong extension names
* Fix sharing dialog doesn't close properly

Note. Both fixes require you to update your Sharing Extension Class (please check that in the example project)

## 1.3.1+1

* Remove unnecessary code

## 1.3.1

* Fixed iOS 13 bugs

## 1.3.0

* Video support. 

# Breaking changes
### Updated
* `ShareViewController.swift` Please copy the whole class again as there are many code changes.
* `getInitialImage` changed to `getInitialMedia` for images and videos
* `getImageStream` changed to `getMediaStream` for images and videos
* both `getInitialMedia` and `getMediaStream` now return video duration and thumbnail along with the shared file path

### Removed
* `getInitialImageAsUri`
* `getImageStreamAsUri`

## 1.2.0+1

* New method added to reset the already consumed callbacks

## 1.1.5

* Example project updated. Check the method [handleImages] in example/Sharing Extension/ShareViewController.swift
* Fix some images are not successfully shared on iOS

## 1.1.4

* Add screen recorded demo

## 1.1.3

* Fix sharing image does not work sometimes on iOS and on Android when sharing from google photos (cloud)

## 1.1.2

* Return absolute path for images instead of a reference that can be used directly with File.dart
* Refactor code

## 1.0.1

* Bug fixes and updated api name

## 1.0.0

* Add support for urls

## 0.9.2

* Remove un-necessary jar libraries

## 0.9.1

* Fix issue where sharing in iOS simulator does not work
