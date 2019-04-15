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

    let toggleShortcutUserDefaultsKey = "toggleShortcutKey"

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

        NotificationCenter.default.addObserver(self,
                                               selector: #selector(self.defaultsChanged),
                                               name: UserDefaults.didChangeNotification,
                                               object: nil)

        setDefaultShortcutOnFirstLaunch()
        syncEnableGrayscaleModeMenuItemState()
        syncLaunchAtLoginMenuItemState()
        updateMenuItemsStateFromDefaults()
    }

    func applicationWillTerminate(_ aNotification: Notification) {
        disableGrayscale()
    }

    @objc func defaultsChanged() {
        updateMenuItemsStateFromDefaults()
        // Note: for some reason getting/setting defaults using defaults object
        // (eg. defaults[.isHotKeyEnabled]) returns runtime error: EXC_BAD_INSTRUCTION
        if UserDefaults.standard.bool(forKey: "isHotKeyEnabled") {
            // Bind shortcut to grayscale mode toggle action
            MASShortcutBinder.shared().bindShortcut(withDefaultsKey: toggleShortcutUserDefaultsKey, toAction: {
                toggleGrayscale()
                self.syncEnableGrayscaleModeMenuItemState()
            })
        } else {
            MASShortcutBinder.shared().breakBinding(withDefaultsKey: toggleShortcutUserDefaultsKey)
        }
    }

    func updateMenuItemsStateFromDefaults() {
        let isEnabledAtLaunch = UserDefaults.standard.bool(forKey: "isEnabledAtLaunch")
        let isEnabledOnLeftClick = UserDefaults.standard.bool(forKey: "isEnabledOnLeftClick")
        enableAtLaunchMenuItem.state = isEnabledAtLaunch.toNSControlState()
        enableOnLeftClickMenuItem.state = isEnabledOnLeftClick.toNSControlState()
    }

    func setDefaultShortcutOnFirstLaunch() {
        let modifierFlags = NSEvent.ModifierFlags.init(arrayLiteral: [.option, .command]).rawValue
        guard let defaultShortcut = MASShortcut(keyCode: UInt(kVK_ANSI_G),
                                                modifierFlags: modifierFlags) else { return }
        guard let defaultShortcutData = try? NSKeyedArchiver
            .archivedData(withRootObject: defaultShortcut, requiringSecureCoding: false) else {
                return
        }
        UserDefaults.standard.register(defaults: [toggleShortcutUserDefaultsKey: defaultShortcutData])
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
