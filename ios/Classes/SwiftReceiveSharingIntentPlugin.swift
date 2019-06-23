import Flutter
import UIKit

public class SwiftReceiveSharingIntentPlugin: NSObject, FlutterPlugin, FlutterStreamHandler {

    static let kMessagesChannel = "receive_sharing_intent/messages";
    static let kEventsChannelImage = "receive_sharing_intent/events-image";
    static let kEventsChannelLink = "receive_sharing_intent/events-text";

    private var initialIntentData: [String]? = nil
    private var latestIntentData: [String]? = nil
    
    private var initialLink: String? = nil
    private var latestLink: String? = nil

    private var eventSinkImage: FlutterEventSink? = nil;
    private var eventSinkText: FlutterEventSink? = nil;


    public static func register(with registrar: FlutterPluginRegistrar) {
        let instance = SwiftReceiveSharingIntentPlugin()

        let channel = FlutterMethodChannel(name: kMessagesChannel, binaryMessenger: registrar.messenger())
        registrar.addMethodCallDelegate(instance, channel: channel)

        let chargingChannelImage = FlutterEventChannel(name: kEventsChannelImage, binaryMessenger: registrar.messenger())
        chargingChannelImage.setStreamHandler(instance)
        
        let chargingChannelLink = FlutterEventChannel(name: kEventsChannelLink, binaryMessenger: registrar.messenger())
        chargingChannelLink.setStreamHandler(instance)
        
        registrar.addApplicationDelegate(instance)
    }

    public func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {

        if(call.method == "getInitialIntentData") {
            result(self.initialIntentData);
        } else if(call.method == "getInitialText") {
            result(self.initialLink);
        } else {
            result(FlutterMethodNotImplemented);
        }
    }

    public func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [AnyHashable : Any] = [:]) -> Bool {
        if let url = launchOptions[UIApplicationLaunchOptionsKey.url] as? URL {
            return handleUrl(url: url, setInitialData: true)
        } else if let activityDictionary = launchOptions[UIApplicationLaunchOptionsKey.userActivityDictionary] as? [AnyHashable: Any] { //Universal link
            for key in activityDictionary.keys {
                if let userActivity = activityDictionary[key] as? NSUserActivity {
                    if let url = userActivity.webpageURL {
                        return handleUrl(url: url, setInitialData: true)
                    }
                }
            }
        }
        return false
    }

    public func application(_ application: UIApplication, open url: URL, options: [UIApplicationOpenURLOptionsKey : Any] = [:]) -> Bool {
        return handleUrl(url: url, setInitialData: false)
    }

    public func application(_ application: UIApplication, continue userActivity: NSUserActivity, restorationHandler: @escaping ([Any]) -> Void) -> Bool {
        return handleUrl(url: userActivity.webpageURL, setInitialData: true)
    }

    private func handleUrl(url: URL?, setInitialData: Bool) -> Bool {
        if let url = url {
            let appDomain = Bundle.main.bundleIdentifier!
            let userDefaults = UserDefaults(suiteName: "group.\(appDomain)")
            if url.fragment == "image" {
                if let key = url.host?.components(separatedBy: "=").last,
                    let sharedArray = userDefaults?.object(forKey: key) as? [String] {
                    latestIntentData = sharedArray
                    if(setInitialData) {
                        initialIntentData = latestIntentData
                    }
                    eventSinkImage?(latestIntentData)
                }
            } else if url.fragment == "text" {
                if let key = url.host?.components(separatedBy: "=").last,
                    let sharedArray = userDefaults?.object(forKey: key) as? [String] {
                    latestLink =  sharedArray.joined(separator: ",")
                    if(setInitialData) {
                        initialLink = latestLink
                    }
                    eventSinkText?(latestLink)
                }
            } else {
                latestLink = url.absoluteString
                if(setInitialData) {
                    initialLink = latestLink
                }
                eventSinkText?(latestLink)
            }
            return true
        }

        latestIntentData = nil
        latestLink = nil
        return false
    }


    public func onListen(withArguments arguments: Any?, eventSink events: @escaping FlutterEventSink) -> FlutterError? {
        if (arguments as! String? == "image") {
            eventSinkImage = events;
        } else if (arguments as! String? == "text") {
            eventSinkText = events;
        } else {
            return FlutterError.init(code: "NO_SUCH_ARGUMENT", message: "No such argument\(String(describing: arguments))", details: nil);
        }
        return nil;
    }

    public func onCancel(withArguments arguments: Any?) -> FlutterError? {
        if (arguments as! String? == "image") {
            eventSinkImage = nil;
        } else if (arguments as! String? == "text") {
            eventSinkText = nil;
        } else {
            return FlutterError.init(code: "NO_SUCH_ARGUMENT", message: "No such argument as \(String(describing: arguments))", details: nil);
        }
        return nil;
    }
}
