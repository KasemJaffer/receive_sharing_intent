//
//  ActionViewController.swift
//  ActionExtension
//
//  Created by Kasem Mohamed on 2024-02-05.
//  Copyright © 2024 The Chromium Authors. All rights reserved.
//

import receive_sharing_intent

class ActionViewController: RSIShareViewController {
    // Use this method to return false if you don't want to redirect to host app automatically.
    // Default is true
    override func shouldAutoRedirect() -> Bool {
        return true
    }
}
