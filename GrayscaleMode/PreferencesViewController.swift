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
    @IBOutlet weak var enableAtLaunchCheckbox: NSButtonCell!
    @IBOutlet weak var enableOnLeftClickCheckbox: NSButtonCell!
    @IBOutlet weak var enableHotKeyCheckbox: NSButtonCell!
    @IBOutlet weak var toggleShortcutView: MASShortcutView!

    let appDelegate = NSApplication.shared.delegate as! AppDelegate

    override func viewDidLoad() {
        super.viewDidLoad()

        appDelegate.prefViewController = self

        NotificationCenter.default.addObserver(self,
                                               selector: #selector(self.defaultsChanged),
                                               name: UserDefaults.didChangeNotification,
                                               object: nil)

        toggleShortcutView.associatedUserDefaultsKey = appDelegate.toggleShortcutUserDefaultsKey

        syncLaunchAtLoginCheckboxState()
        updateCheckboxesStateFromDefaults();
    }

    override func viewDidAppear() {
        super.viewDidAppear()
        view.window?.level = .floating
    }

    @objc func defaultsChanged() {
        updateCheckboxesStateFromDefaults()
    }

    func updateCheckboxesStateFromDefaults() {
        let isEnabledAtLaunch = UserDefaults.standard.bool(forKey: "isEnabledAtLaunch")
        let isEnabledOnLeftClick = UserDefaults.standard.bool(forKey: "isEnabledOnLeftClick")
        let isHotKeyEnabled = UserDefaults.standard.bool(forKey: "isHotKeyEnabled")
        enableAtLaunchCheckbox.state = isEnabledAtLaunch.toNSControlState()
        enableOnLeftClickCheckbox.state = isEnabledOnLeftClick.toNSControlState()
        enableHotKeyCheckbox.state = isHotKeyEnabled.toNSControlState()
        toggleShortcutView.isEnabled = isHotKeyEnabled
    }

    func syncLaunchAtLoginCheckboxState() {
        launchAtLoginCheckbox.state = LaunchAtLogin.isEnabled.toNSControlState()
    }

    @IBAction func launchAtLoginDidChange(_ sender: NSButton) {
        LaunchAtLogin.isEnabled.toggle()
        appDelegate.syncLaunchAtLoginMenuItemState()
    }

    @IBAction func enableAtLaunchDidChange(_ sender: NSButton) {
        defaults[.isEnabledAtLaunch].toggle()
    }

    @IBAction func enableOnLeftClickDidChange(_ sender: NSButton) {
        defaults[.isEnabledOnLeftClick].toggle()
    }

    @IBAction func enableHotKeyDidChange(_ sender: NSButton) {
        defaults[.isHotKeyEnabled].toggle()
    }

}
