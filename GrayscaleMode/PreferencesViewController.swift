//
//  PreferencesViewController.swift
//  GrayscaleMode
//
//  Created by Rajendra Bhochalya on 07/04/19.
//  Copyright © 2019 Rajendra Bhochalya. All rights reserved.
//

import Cocoa
import Defaults
import LaunchAtLogin
import MASShortcut

class PreferencesViewController: NSViewController {

    @IBOutlet weak var launchAtLoginCheckbox: NSButtonCell!
    @IBOutlet weak var enableOnLeftClickCheckbox: NSButtonCell!
    @IBOutlet weak var enableHotKeyCheckbox: NSButtonCell!
    @IBOutlet weak var toggleShortcutView: MASShortcutView!

    let appDelegate = NSApplication.shared.delegate as! AppDelegate
    var shouldEnableOnLeftClickObserver: DefaultsObservation!
    var isHotKeyEnabledObserver: DefaultsObservation!

    override func viewDidLoad() {
        super.viewDidLoad()

        appDelegate.prefViewController = self
        toggleShortcutView.associatedUserDefaultsKey = appDelegate.toggleShortcutUserDefaultsKey

        shouldEnableOnLeftClickObserver = defaults.observe(.shouldEnableOnLeftClick, options: [.initial, .old, .new]) { change in
            self.enableOnLeftClickCheckbox.state = change.newValue.toNSControlState()
        }

        isHotKeyEnabledObserver = defaults.observe(.isHotKeyEnabled, options: [.initial, .old, .new]) { change in
          self.enableHotKeyCheckbox.state = change.newValue.toNSControlState()
          self.toggleShortcutView.isEnabled = change.newValue
        }

        syncLaunchAtLoginCheckboxState()
    }

    override func viewDidAppear() {
        super.viewDidAppear()
        view.window?.level = .floating
    }

    func syncLaunchAtLoginCheckboxState() {
        launchAtLoginCheckbox.state = LaunchAtLogin.isEnabled.toNSControlState()
    }

    @IBAction func launchAtLoginDidChange(_ sender: NSButton) {
        LaunchAtLogin.isEnabled.toggle()
        appDelegate.syncLaunchAtLoginMenuItemState()
    }

    @IBAction func enableOnLeftClickDidChange(_ sender: NSButton) {
        defaults[.shouldEnableOnLeftClick].toggle()
    }

    @IBAction func enableHotKeyDidChange(_ sender: NSButton) {
        defaults[.isHotKeyEnabled].toggle()
    }

}
