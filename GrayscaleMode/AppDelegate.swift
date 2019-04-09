//
//  AppDelegate.swift
//  GrayscaleMode
//
//  Created by Rajendra Bhochalya on 03/02/19.
//  Copyright © 2019 Rajendra Bhochalya. All rights reserved.
//

import Cocoa
import LaunchAtLogin
import Defaults
import HotKey

extension Defaults.Keys {
    static let isEnabledAtLaunch = Defaults.Key<Bool>("isEnabledAtLaunch", default: false)
    static let isEnabledOnLeftClick = Defaults.Key<Bool>("isEnabledOnLeftClick", default: false)
    static let isHotKeyEnabled = Defaults.Key<Bool>("isHotKeyEnabled", default: true)
}

@NSApplicationMain
class AppDelegate: NSObject, NSApplicationDelegate {

    @IBOutlet weak var statusMenu: NSMenu!
    @IBOutlet weak var enableGrayscaleModeMenuItem: NSMenuItem!
    @IBOutlet weak var launchAtLoginMenuItem: NSMenuItem!
    @IBOutlet weak var enableAtLaunchMenuItem: NSMenuItem!
    @IBOutlet weak var enableOnLeftClickMenuItem: NSMenuItem!

    let statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)

    let hotKey = HotKey(key: .g, modifiers: [.command, .option])

    var prefViewController: PreferencesViewController!

    func applicationDidFinishLaunching(_ aNotification: Notification) {
        DispatchQueue.main.async {
            self.statusItem.button?.image = #imageLiteral(resourceName: "statusBarIcon")
        }

        if let button = statusItem.button {
            button.action = #selector(self.handleMenuIconClick(sender:))
            button.sendAction(on: [.leftMouseUp, .rightMouseUp])
        }

        if defaults[.isEnabledAtLaunch] {
            enableGrayscale()
        }

        hotKey.keyDownHandler = {
            toggleGrayscale()
        }

        NotificationCenter.default.addObserver(self,
                                               selector: #selector(self.defaultsChanged),
                                               name: UserDefaults.didChangeNotification,
                                               object: nil)

        syncEnableGrayscaleModeMenuItemState()
        syncLaunchAtLoginMenuItemState()
        updateMenuItemsStateFromDefaults()
    }

    func applicationWillTerminate(_ aNotification: Notification) {
        // Insert code here to tear down your application
    }

    @objc func defaultsChanged() {
        updateMenuItemsStateFromDefaults()
        // Note: for some reason getting/setting defaults using defaults object
        // (eg. defaults[.isHotKeyEnabled]) returns runtime error: EXC_BAD_INSTRUCTION
        hotKey.isPaused = !UserDefaults.standard.bool(forKey: "isHotKeyEnabled")
    }

    func updateMenuItemsStateFromDefaults() {
        let isEnabledAtLaunch = UserDefaults.standard.bool(forKey: "isEnabledAtLaunch")
        let isEnabledOnLeftClick = UserDefaults.standard.bool(forKey: "isEnabledOnLeftClick")
        enableAtLaunchMenuItem.state = isEnabledAtLaunch.toNSControlState()
        enableOnLeftClickMenuItem.state = isEnabledOnLeftClick.toNSControlState()
    }

    func syncLaunchAtLoginMenuItemState() {
        launchAtLoginMenuItem.state = LaunchAtLogin.isEnabled.toNSControlState()
    }

    func syncEnableGrayscaleModeMenuItemState() {
        enableGrayscaleModeMenuItem.state = checkIfGrayscaleOn().toNSControlState()
    }

    @objc func handleMenuIconClick(sender: NSStatusItem) {
        let event = NSApp.currentEvent!

        if !defaults[.isEnabledOnLeftClick] {
            statusItem.popUpMenu(statusMenu)
            return
        }

        if event.type == NSEvent.EventType.leftMouseUp {
            statusItem.popUpMenu(statusMenu)
        } else {
            toggleGrayscale()
            syncEnableGrayscaleModeMenuItemState()
        }
    }

    @IBAction func toggleGrayscaleMode(_ sender: NSMenuItem) {
        toggleGrayscale()
        syncEnableGrayscaleModeMenuItemState()
    }

    @IBAction func toggleLaunchAtLogin(_ sender: NSMenuItem) {
        LaunchAtLogin.isEnabled.toggle()
        syncLaunchAtLoginMenuItemState()
        if let prefViewController = prefViewController {
            prefViewController.syncLaunchAtLoginCheckboxState()
        }
    }

    @IBAction func toggleEnableAtLaunch(_ sender: NSMenuItem) {
        defaults[.isEnabledAtLaunch].toggle()
    }

    @IBAction func toggleEnableOnLeftClick(_ sender: NSMenuItem) {
        defaults[.isEnabledOnLeftClick].toggle()
    }
}
