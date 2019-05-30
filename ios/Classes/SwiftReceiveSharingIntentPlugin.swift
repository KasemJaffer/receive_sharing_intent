import Flutter
import UIKit

public class SwiftReceiveSharingIntentPlugin: NSObject, FlutterPlugin, FlutterStreamHandler {

    static let kMessagesChannel = "receive_sharing_intent/messages";
    static let kEventsChannel = "receive_sharing_intent/events";

    private var initialIntentData: [String]? = nil
    private var latestIntentData: [String]? = nil

    private var _eventSink: FlutterEventSink? = nil;


    public static func register(with registrar: FlutterPluginRegistrar) {
        let instance = SwiftReceiveSharingIntentPlugin()

        let channel = FlutterMethodChannel(name: kMessagesChannel, binaryMessenger: registrar.messenger())
        registrar.addMethodCallDelegate(instance, channel: channel)

        let chargingChannel = FlutterEventChannel(name: kEventsChannel, binaryMessenger: registrar.messenger())
        chargingChannel.setStreamHandler(instance)
        registrar.addApplicationDelegate(instance)
    }

    public func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {

        if(call.method == "getInitialIntentData") {
            result(self.initialIntentData);
        } else {
            result(FlutterMethodNotImplemented);
        }
    }

    public func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [AnyHashable : Any] = [:]) -> Bool {
        let url = launchOptions[UIApplicationLaunchOptionsKey.url] as? URL
        return handleUrl(url: url, setInitialData: true)
    }


    public func application(_ application: UIApplication, open url: URL, options: [UIApplicationOpenURLOptionsKey : Any] = [:]) -> Bool {
        return handleUrl(url: url, setInitialData: false)
    }

    public func application(_ application: UIApplication, continue userActivity: NSUserActivity, restorationHandler: @escaping ([Any]) -> Void) -> Bool {
        return handleUrl(url: userActivity.webpageURL, setInitialData: _eventSink==nil)
    }

    private func handleUrl(url: URL?, setInitialData: Bool) -> Bool {
        if let url = url {
            let appDomain = Bundle.main.bundleIdentifier!
            let userDefaults = UserDefaults(suiteName: "group.\(appDomain)")
            if let key = url.absoluteString.components(separatedBy: "dataUrl=").last,
                let sharedArray = userDefaults?.object(forKey: key) as? [String] {
                latestIntentData = sharedArray
                if(setInitialData) {
                    initialIntentData = sharedArray
                }
                _eventSink?(latestIntentData)
                return true
            }
        }

        latestIntentData = nil
        return false
    }


    public func onListen(withArguments arguments: Any?, eventSink events: @escaping FlutterEventSink) -> FlutterError? {
        _eventSink = events;
        return nil;
    }

    public func onCancel(withArguments arguments: Any?) -> FlutterError? {
        _eventSink = nil;
        return nil;
    }
}