//
//  RSIComposeView.swift
//  receive_sharing_intent
//
//  Built-in compose UI used by `RSIShareViewController` when the extension is
//  configured to show UI (i.e. `shouldAutoRedirect()` returns false). It
//  replicates the features of the deprecated `SLComposeServiceViewController`
//  compose sheet: Cancel / Send buttons, an editable message field with a
//  placeholder, and a media preview.
//

import UIKit

/// Callbacks from the built-in compose UI back to the share view controller.
@available(swift, introduced: 5.0)
public protocol RSIComposeViewDelegate: AnyObject {
    /// The user tapped the Send button.
    func composeViewDidSelectPost(_ composeView: RSIComposeView)
    /// The user tapped the Cancel button.
    func composeViewDidSelectCancel(_ composeView: RSIComposeView)
    /// The message text changed.
    func composeViewDidChangeText(_ composeView: RSIComposeView)
}

/// A self-contained compose content view. Pin it to its host's edges; it lays
/// out the Cancel / Send buttons, the message field, the media preview.
/// It does NOT draw its own backdrop or rounded card that chrome is provided by the system sheet that presents the
/// extension (see `RSIShareViewController`'s sheet configuration).
@available(swift, introduced: 5.0)
open class RSIComposeView: UIView, UITextViewDelegate {

    /// Visual/behavioural configuration for the compose UI.
    public struct Configuration {
        public var placeholder: String
        public var sendButtonTitle: String

        public init(placeholder: String,
                    sendButtonTitle: String) {
            self.placeholder = placeholder
            self.sendButtonTitle = sendButtonTitle
        }
    }

    public weak var delegate: RSIComposeViewDelegate?

    private let configuration: Configuration

    private let grabberView = UIView()
    private let closeButton = UIButton(type: .system)
    private let sendButton = UIButton(type: .system)
    private let textView = UITextView()
    private let placeholderLabel = UILabel()
    private let previewImageView = UIImageView()

    /// The text currently entered in the message field.
    public var text: String { return textView.text ?? "" }

    public init(configuration: Configuration) {
        self.configuration = configuration
        super.init(frame: .zero)
        setupViews()
    }

    @available(*, unavailable)
    public required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - Public API

    /// Shows the given preview thumbnail, or hides the preview when nil.
    public func setPreviewImage(_ image: UIImage?) {
        previewImageView.image = image
        previewImageView.isHidden = (image == nil)
    }

    /// Enables/disables the Send button.
    public func setSendEnabled(_ enabled: Bool) {
        sendButton.isEnabled = enabled
        sendButton.backgroundColor = enabled ? .systemBlue : .systemGray3
    }

    /// Makes the message field the first responder (brings up the keyboard).
    @discardableResult
    public func focusTextView() -> Bool {
        return textView.becomeFirstResponder()
    }

    // MARK: - Layout

    private func setupViews() {
        backgroundColor = .systemBackground
        layer.cornerRadius = 20
        layer.maskedCorners = [.layerMinXMinYCorner, .layerMaxXMinYCorner]
        layer.masksToBounds = true

        // Grabber
        grabberView.backgroundColor = .systemGray4
        grabberView.layer.cornerRadius = 2.5
        grabberView.translatesAutoresizingMaskIntoConstraints = false
        addSubview(grabberView)

        // Close button (Circular).
        let symbolConfig = UIImage.SymbolConfiguration(pointSize: 12, weight: .bold)
        closeButton.setImage(UIImage(systemName: "xmark", withConfiguration: symbolConfig), for: .normal)
        closeButton.tintColor = .secondaryLabel
        closeButton.backgroundColor = .secondarySystemFill
        closeButton.layer.cornerRadius = 15
        closeButton.addTarget(self, action: #selector(onCancelTapped), for: .touchUpInside)
        closeButton.translatesAutoresizingMaskIntoConstraints = false
        addSubview(closeButton)


        // Send button (filled, pill shaped).
        sendButton.setTitle(configuration.sendButtonTitle, for: .normal)
        sendButton.setTitleColor(.white, for: .normal)
        sendButton.setTitleColor(UIColor.white.withAlphaComponent(0.6), for: .disabled)
        sendButton.titleLabel?.font = .systemFont(ofSize: 16, weight: .bold)
        sendButton.backgroundColor = .systemBlue
        sendButton.layer.cornerRadius = 18
        sendButton.contentEdgeInsets = UIEdgeInsets(top: 8, left: 20, bottom: 8, right: 20)
        sendButton.addTarget(self, action: #selector(onSendTapped), for: .touchUpInside)
        sendButton.translatesAutoresizingMaskIntoConstraints = false
        addSubview(sendButton)

        // Message text view.
        textView.font = .systemFont(ofSize: 18)
        textView.backgroundColor = .clear
        textView.delegate = self
        textView.translatesAutoresizingMaskIntoConstraints = false
        addSubview(textView)

        // Placeholder for the text view.
        placeholderLabel.text = configuration.placeholder
        placeholderLabel.font = .systemFont(ofSize: 17)
        placeholderLabel.textColor = .placeholderText
        placeholderLabel.translatesAutoresizingMaskIntoConstraints = false
        addSubview(placeholderLabel)

        // Media preview.
        previewImageView.contentMode = .scaleAspectFill
        previewImageView.clipsToBounds = true
        previewImageView.layer.cornerRadius = 12
        previewImageView.layer.borderWidth = 1
        previewImageView.layer.borderColor = UIColor.systemGray6.cgColor
        previewImageView.isHidden = true
        previewImageView.translatesAutoresizingMaskIntoConstraints = false
        addSubview(previewImageView)

        let guide = safeAreaLayoutGuide
        NSLayoutConstraint.activate([
            grabberView.topAnchor.constraint(equalTo: topAnchor, constant: 8),
            grabberView.centerXAnchor.constraint(equalTo: centerXAnchor),
            grabberView.widthAnchor.constraint(equalToConstant: 36),
            grabberView.heightAnchor.constraint(equalToConstant: 5),

            closeButton.topAnchor.constraint(equalTo: grabberView.bottomAnchor, constant: 12),
            closeButton.leadingAnchor.constraint(equalTo: guide.leadingAnchor, constant: 20),
            closeButton.widthAnchor.constraint(equalToConstant: 30),
            closeButton.heightAnchor.constraint(equalToConstant: 30),

            sendButton.centerYAnchor.constraint(equalTo: closeButton.centerYAnchor),
            sendButton.trailingAnchor.constraint(equalTo: guide.trailingAnchor, constant: -20),
            sendButton.leadingAnchor.constraint(greaterThanOrEqualTo: closeButton.trailingAnchor, constant: 12),

            textView.topAnchor.constraint(equalTo: closeButton.bottomAnchor, constant: 16),
            textView.leadingAnchor.constraint(equalTo: guide.leadingAnchor, constant: 16),
            textView.heightAnchor.constraint(greaterThanOrEqualToConstant: 100),
            textView.bottomAnchor.constraint(equalTo: guide.bottomAnchor, constant: -20),

            placeholderLabel.topAnchor.constraint(equalTo: textView.topAnchor, constant: 8),
            placeholderLabel.leadingAnchor.constraint(equalTo: textView.leadingAnchor, constant: 5),

            previewImageView.topAnchor.constraint(equalTo: textView.topAnchor, constant: 4),
            previewImageView.trailingAnchor.constraint(equalTo: guide.trailingAnchor, constant: -20),
            previewImageView.leadingAnchor.constraint(equalTo: textView.trailingAnchor, constant: 12),
            previewImageView.widthAnchor.constraint(equalToConstant: 72),
            previewImageView.heightAnchor.constraint(equalToConstant: 72),
        ])
    }

    // MARK: - Actions

    @objc private func onSendTapped() {
        delegate?.composeViewDidSelectPost(self)
    }

    @objc private func onCancelTapped() {
        delegate?.composeViewDidSelectCancel(self)
    }

    // MARK: - UITextViewDelegate

    open func textViewDidChange(_ textView: UITextView) {
        placeholderLabel.isHidden = !textView.text.isEmpty
        delegate?.composeViewDidChangeText(self)
    }
}
