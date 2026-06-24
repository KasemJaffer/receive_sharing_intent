//
//  RSIShareViewController.swift
//  receive_sharing_intent
//
//  Created by Kasem Mohamed on 2024-01-25.
//

import UIKit
import MobileCoreServices
import Photos

// NOTE: This controller used to subclass `SLComposeServiceViewController` from
// the (now deprecated) Social framework. Apple's modern Share Extension is just
// a plain `UIViewController`. To keep the same features that the old compose
// sheet offered, this class hosts a `RSIComposeView` (Cancel / Send buttons, an
// editable message field with placeholder, and a
// media preview). The UI is only shown when `shouldAutoRedirect()` returns
// `false`; otherwise the shared content is processed and we redirect straight
// into the host app with no UI at all.
@available(swift, introduced: 5.0)
open class RSIShareViewController: UIViewController, RSIComposeViewDelegate {
    var hostAppBundleIdentifier = ""
    var appGroupId = ""
    var sharedMedia: [SharedMediaFile] = []

    // MARK: - Public, overridable compose UI API

    /// Override this method to return false if you don't want to redirect to host app automatically
    /// Default is true
    open func shouldAutoRedirect() -> Bool {
        return true
    }

    /// Placeholder shown in the message field while it is empty.
    open var placeholder: String { return "Add a message…" }

    /// Title of the confirm button (top right).
    open var sendButtonTitle: String { return "Send" }

    /// Height of the compact bottom sheet (iOS 16+). Lower values bring the sheet
    /// closer to the bottom of the screen. Override to customise.
    open var preferredSheetHeight: CGFloat { return 200 }

    /// The text the user typed in the message field.
    open var contentText: String { return composeView?.text ?? "" }

    /// Override to enable/disable the Send button based on your own validation.
    /// Default is always valid.
    open func isContentValid() -> Bool { return true }

    /// Called when the user taps Send. Default saves the message and redirects.
    open func didSelectPost() {
        saveAndRedirect(message: contentText)
    }

    /// Called when the user taps Cancel. Default cancels the extension request.
    open func didSelectCancel() {
        cancel()
    }

    // MARK: - Built-in compose UI

    /// The built-in compose UI, present only when `shouldAutoRedirect()` is false.
    private var composeView: RSIComposeView?

    /// Preview to display in the compose UI (first media item), applied on the
    /// main thread once loading finishes.
    private var pendingPreviewImage: UIImage?

    // MARK: - Lifecycle

    open override func viewDidLoad() {
        super.viewDidLoad()

        // load group and app id from build info
        loadIds()

        if !shouldAutoRedirect() {
            setupComposeUI()
        }
    }

    open override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)

        if shouldAutoRedirect() {
            view.backgroundColor = .clear
            // The share extension is presented inside a system sheet container whose
            // background is opaque. Clear the ancestor backgrounds so only our own
            // dim layer + bottom card are visible (and the host shows through).
            var ancestor = view.superview
            while let current = ancestor {
                current.backgroundColor = .clear
                current.isOpaque = false
                ancestor = current.superview
            }
        }
    }

    open override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)

        // Focus the message field so the keyboard comes up as the sheet opens.
        if !shouldAutoRedirect() {
            composeView?.focusTextView()
        }

        // Process the shared content from the NSExtensionContext attachments.
        if let content = extensionContext!.inputItems[0] as? NSExtensionItem {
            if let contents = content.attachments {
                for (index, attachment) in (contents).enumerated() {
                    for type in SharedMediaType.allCases {
                        if attachment.hasItemConformingToTypeIdentifier(type.toUTTypeIdentifier) {
                            attachment.loadItem(forTypeIdentifier: type.toUTTypeIdentifier) { [weak self] data, error in
                                guard let this = self, error == nil else {
                                    self?.dismissWithError()
                                    return
                                }
                                switch type {
                                case .text:
                                    if let text = data as? String {
                                        this.handleMedia(forLiteral: text,
                                                         type: type,
                                                         index: index,
                                                         content: content)
                                    }
                                case .url:
                                    if let url = data as? URL {
                                        this.handleMedia(forLiteral: url.absoluteString,
                                                         type: type,
                                                         index: index,
                                                         content: content)
                                    }
                                default:
                                    if let url = data as? URL {
                                        this.handleMedia(forFile: url,
                                                         type: type,
                                                         index: index,
                                                         content: content)
                                    }
                                    else if let image = data as? UIImage {
                                        this.handleMedia(forUIImage: image,
                                                         type: type,
                                                         index: index,
                                                         content: content)
                                    }
                                }
                            }
                            break
                        }
                    }
                }
            }
        }
    }
    
    private func loadIds() {
        // loading Share extension App Id
        let shareExtensionAppBundleIdentifier = Bundle.main.bundleIdentifier!
        
        
        // extract host app bundle id from ShareExtension id
        // by default it's <hostAppBundleIdentifier>.<ShareExtension>
        // for example: "com.kasem.sharing.Share-Extension" -> com.kasem.sharing
        let lastIndexOfPoint = shareExtensionAppBundleIdentifier.lastIndex(of: ".")
        hostAppBundleIdentifier = String(shareExtensionAppBundleIdentifier[..<lastIndexOfPoint!])
        let defaultAppGroupId = "group.\(hostAppBundleIdentifier)"
        
        
        // loading custom AppGroupId from Build Settings or use group.<hostAppBundleIdentifier>
        let customAppGroupId = Bundle.main.object(forInfoDictionaryKey: kAppGroupIdKey) as? String
        
        appGroupId = customAppGroupId ?? defaultAppGroupId
    }
    
    
    private func handleMedia(forLiteral item: String, type: SharedMediaType, index: Int, content: NSExtensionItem) {
        sharedMedia.append(SharedMediaFile(
            path: item,
            mimeType: type == .text ? "text/plain": nil,
            type: type
        ))
        completeAttachment(index: index, content: content)
    }

    private func handleMedia(forUIImage image: UIImage, type: SharedMediaType, index: Int, content: NSExtensionItem){
        let tempPath = FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: appGroupId)!.appendingPathComponent("TempImage.png")
        if self.writeTempFile(image, to: tempPath) {
            let newPathDecoded = tempPath.absoluteString.removingPercentEncoding!
            sharedMedia.append(SharedMediaFile(
                path: newPathDecoded,
                mimeType: type == .image ? "image/png": nil,
                type: type
            ))
        }
        if pendingPreviewImage == nil { pendingPreviewImage = image }
        completeAttachment(index: index, content: content)
    }
    
    private func handleMedia(forFile url: URL, type: SharedMediaType, index: Int, content: NSExtensionItem) {
        let fileName = getFileName(from: url, type: type)
        let newPath = FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: appGroupId)!.appendingPathComponent(fileName)
        
        if copyFile(at: url, to: newPath) {
            // The path should be decoded because Flutter is not expecting url encoded file names
            let newPathDecoded = newPath.absoluteString.removingPercentEncoding!;
            if type == .video {
                // Get video thumbnail and duration
                if let videoInfo = getVideoInfo(from: url) {
                    let thumbnailPathDecoded = videoInfo.thumbnail?.removingPercentEncoding;
                    sharedMedia.append(SharedMediaFile(
                        path: newPathDecoded,
                        mimeType: url.mimeType(),
                        thumbnail: thumbnailPathDecoded,
                        duration: videoInfo.duration,
                        type: type
                    ))
                    if pendingPreviewImage == nil, let thumb = videoInfo.thumbnail,
                       let thumbURL = URL(string: thumb) {
                        pendingPreviewImage = UIImage(contentsOfFile: thumbURL.path)
                    }
                }
            } else {
                sharedMedia.append(SharedMediaFile(
                    path: newPathDecoded,
                    mimeType: url.mimeType(),
                    type: type
                ))
                if type == .image, pendingPreviewImage == nil {
                    pendingPreviewImage = UIImage(contentsOfFile: newPath.path)
                }
            }
        }
        
        completeAttachment(index: index, content: content)
    }

    /// Called after each attachment finishes loading. When the last attachment is
    /// done we either redirect automatically or hand control to the compose UI.
    private func completeAttachment(index: Int, content: NSExtensionItem) {
        guard index == (content.attachments?.count ?? 0) - 1 else { return }
        if shouldAutoRedirect() {
            saveAndRedirect()
        } else {
            DispatchQueue.main.async { [weak self] in
                self?.didFinishLoadingContent()
            }
        }
    }
    
    
    // MARK: - Built-in compose UI

    private func setupComposeUI() {
        let configuration = RSIComposeView.Configuration(
            placeholder: placeholder,
            sendButtonTitle: sendButtonTitle,
        )
        let composeView = RSIComposeView(configuration: configuration)
        composeView.delegate = self
        composeView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(composeView)
        NSLayoutConstraint.activate([
            composeView.topAnchor.constraint(equalTo: view.topAnchor),
            composeView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            composeView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            composeView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
        ])
        self.composeView = composeView
        updateSendEnabled()
    }

    /// Called on the main thread once all shared content finished loading.
    private func didFinishLoadingContent() {
        guard !shouldAutoRedirect() else { return }
        composeView?.setPreviewImage(pendingPreviewImage)
        updateSendEnabled()
    }

    private func updateSendEnabled() {
        guard let composeView = composeView else { return }
        composeView.setSendEnabled(isContentValid())
    }

    /// Cancels the share extension request.
    open func cancel() {
        extensionContext?.cancelRequest(withError: NSError(domain: "RSIShareViewController", code: 0, userInfo: [NSLocalizedDescriptionKey: "User cancelled"]))
    }

    // MARK: - RSIComposeViewDelegate

    open func composeViewDidSelectPost(_ composeView: RSIComposeView) {
        didSelectPost()
    }

    open func composeViewDidSelectCancel(_ composeView: RSIComposeView) {
        didSelectCancel()
    }

    open func composeViewDidChangeText(_ composeView: RSIComposeView) {
        updateSendEnabled()
    }

    // Save shared media and redirect to host app
    open func saveAndRedirect(message: String? = nil) {
        let userDefaults = UserDefaults(suiteName: appGroupId)
        userDefaults?.set(toData(data: sharedMedia), forKey: kUserDefaultsKey)
        userDefaults?.set(message, forKey: kUserDefaultsMessageKey)
        userDefaults?.synchronize()
        redirectToHostApp()
    }
    
    private func redirectToHostApp() {
        // ids may not loaded yet so we need loadIds here too
        loadIds()
        let url = URL(string: "\(kSchemePrefix)-\(hostAppBundleIdentifier):share")
        var responder = self as UIResponder?
        
        if #available(iOS 18.0, *) {
            while responder != nil {
                if let application = responder as? UIApplication {
                    application.open(url!, options: [:], completionHandler: nil)
                }
                responder = responder?.next
            }
        } else {
            let selectorOpenURL = sel_registerName("openURL:")
            
            while (responder != nil) {
                if (responder?.responds(to: selectorOpenURL))! {
                    _ = responder?.perform(selectorOpenURL, with: url)
                }
                responder = responder!.next
            }
        }

        extensionContext!.completeRequest(returningItems: [], completionHandler: nil)
    }
    
    private func dismissWithError() {
        print("[ERROR] Error loading data!")
        let alert = UIAlertController(title: "Error", message: "Error loading data", preferredStyle: .alert)
        
        let action = UIAlertAction(title: "Error", style: .cancel) { _ in
            self.dismiss(animated: true, completion: nil)
        }
        
        alert.addAction(action)
        present(alert, animated: true, completion: nil)
        extensionContext!.completeRequest(returningItems: [], completionHandler: nil)
    }
    
    private func getFileName(from url: URL, type: SharedMediaType) -> String {
        var name = url.lastPathComponent
        if name.isEmpty {
            switch type {
            case .image:
                name = UUID().uuidString + ".png"
            case .video:
                name = UUID().uuidString + ".mp4"
            case .text:
                name = UUID().uuidString + ".txt"
            default:
                name = UUID().uuidString
            }
        }
        return name
    }

    private func writeTempFile(_ image: UIImage, to dstURL: URL) -> Bool {
        do {
            if FileManager.default.fileExists(atPath: dstURL.path) {
                try FileManager.default.removeItem(at: dstURL)
            }
            let pngData = image.pngData();
            try pngData?.write(to: dstURL);
            return true;
        } catch (let error){
            print("Cannot write to temp file: \(error)");
            return false;
        }
    }
    
    private func copyFile(at srcURL: URL, to dstURL: URL) -> Bool {
        do {
            if FileManager.default.fileExists(atPath: dstURL.path) {
                try FileManager.default.removeItem(at: dstURL)
            }
            try FileManager.default.copyItem(at: srcURL, to: dstURL)
        } catch (let error) {
            print("Cannot copy item at \(srcURL) to \(dstURL): \(error)")
            return false
        }
        return true
    }
    
    private func getVideoInfo(from url: URL) -> (thumbnail: String?, duration: Double)? {
        let asset = AVAsset(url: url)
        let duration = (CMTimeGetSeconds(asset.duration) * 1000).rounded()
        let thumbnailPath = getThumbnailPath(for: url)
        
        if FileManager.default.fileExists(atPath: thumbnailPath.path) {
            return (thumbnail: thumbnailPath.absoluteString, duration: duration)
        }
        
        var saved = false
        let assetImgGenerate = AVAssetImageGenerator(asset: asset)
        assetImgGenerate.appliesPreferredTrackTransform = true
        //        let scale = UIScreen.main.scale
        assetImgGenerate.maximumSize =  CGSize(width: 360, height: 360)
        do {
            let img = try assetImgGenerate.copyCGImage(at: CMTimeMakeWithSeconds(600, preferredTimescale: 1), actualTime: nil)
            try UIImage(cgImage: img).pngData()?.write(to: thumbnailPath)
            saved = true
        } catch {
            saved = false
        }
        
        return saved ? (thumbnail: thumbnailPath.absoluteString, duration: duration): nil
    }
    
    private func getThumbnailPath(for url: URL) -> URL {
        let fileName = Data(url.lastPathComponent.utf8).base64EncodedString().replacingOccurrences(of: "==", with: "")
        let path = FileManager.default
            .containerURL(forSecurityApplicationGroupIdentifier: appGroupId)!
            .appendingPathComponent("\(fileName).jpg")
        return path
    }
    
    private func toData(data: [SharedMediaFile]) -> Data {
        let encodedData = try? JSONEncoder().encode(data)
        return encodedData!
    }
}

extension URL {
    public func mimeType() -> String {
        if #available(iOS 14.0, *) {
            if let mimeType = UTType(filenameExtension: self.pathExtension)?.preferredMIMEType {
                return mimeType
            }
        } else {
            if let uti = UTTypeCreatePreferredIdentifierForTag(kUTTagClassFilenameExtension, self.pathExtension as NSString, nil)?.takeRetainedValue() {
                if let mimetype = UTTypeCopyPreferredTagWithClass(uti, kUTTagClassMIMEType)?.takeRetainedValue() {
                    return mimetype as String
                }
            }
        }
        
        return "application/octet-stream"
    }
}
