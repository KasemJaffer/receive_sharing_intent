
//
//  ShareViewController.swift
//  Sharing Extension
//
//  Created by Kasem Mohamed on 2019-05-30.
//  Copyright © 2019 The Chromium Authors. All rights reserved.
//
import receive_sharing_intent

class ShareViewController: RSIShareViewController {

    // Return false to show the built-in compose UI (Cancel / Send buttons,
    // an editable message field and a media preview) instead of redirecting
    // automatically. Return true to skip the UI and jump straight to the app.
    override func shouldAutoRedirect() -> Bool {
        return false
    }

    // Optionally customise the built-in compose UI:
    override var placeholder: String { "Add a caption…" }
    override var sendButtonTitle: String { "Send to Example" }
}
