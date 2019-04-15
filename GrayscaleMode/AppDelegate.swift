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
    static let whitelistedApps = Defaults.Key<[String]>("whitelistedApps", default: [])
}

@NSApplicationMain
class AppDelegate: NSObject, NSApplicationDelegate {

    @IBOutlet weak var statusMenu: NSMenu!
    @IBOutlet weak var enableGrayscaleModeMenuItem: NSMenuItem!
    @IBOutlet weak var launchAtLoginMenuItem: NSMenuItem!
    @IBOutlet weak var enableAtLaunchMenuItem: NSMenuItem!
    @IBOutlet weak var enableOnLeftClickMenuItem: NSMenuItem!
    @IBOutlet weak var disableForCurrentAppMenuItem: NSMenuItem!

    let statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
    let toggleShortcutUserDefaultsKey = "toggleShortcutKey"
    var prefViewController: PreferencesViewController!
    var wasGrayscaleModeOn = false

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

        NSWorkspace.shared.notificationCenter.addObserver(self,
                                               selector: #selector(self.frontmostAppChanged),
                                               name: NSWorkspace.didActivateApplicationNotification,
                                               object: nil)

        setDefaultShortcutOnFirstLaunch()
        syncEnableGrayscaleModeMenuItemState()
        syncLaunchAtLoginMenuItemState()
        updateMenuItemsStateFromDefaults()
        updateDisableForCurrentAppMenuItemTitleAndState()
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
                self.wasGrayscaleModeOn = false
                self.syncEnableGrayscaleModeMenuItemState()
            })
        } else {
            MASShortcutBinder.shared().breakBinding(withDefaultsKey: toggleShortcutUserDefaultsKey)
        }
    }

    @objc func frontmostAppChanged() {
        updateDisableForCurrentAppMenuItemTitleAndState()
        toggleGrayscaleModeBasedOnFrontmostApp()
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

    func updateDisableForCurrentAppMenuItemTitleAndState() {
        guard let currentAppName = NSWorkspace.shared.frontmostApplication?.localizedName else {
            return
        }
        guard let currentAppId = NSWorkspace.shared.frontmostApplication?.bundleIdentifier else {
            return
        }
        guard let menuItem = disableForCurrentAppMenuItem else {
            return
        }
        menuItem.title = "Disable for \(currentAppName)"
        menuItem.state = defaults[.whitelistedApps].contains(currentAppId).toNSControlState()
    }

    func toggleGrayscaleModeBasedOnFrontmostApp() {
        guard let currentAppId = NSWorkspace.shared.frontmostApplication?.bundleIdentifier else {
            return
        }
        if defaults[.whitelistedApps].contains(currentAppId) {
            if checkIfGrayscaleOn() {
                wasGrayscaleModeOn = true
                disableGrayscale()
                syncEnableGrayscaleModeMenuItemState()
            }
        } else if wasGrayscaleModeOn {
            enableGrayscale()
            syncEnableGrayscaleModeMenuItemState()
            wasGrayscaleModeOn = false
        }
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
            wasGrayscaleModeOn = false
            syncEnableGrayscaleModeMenuItemState()
        }
    }

    @IBAction func toggleGrayscaleMode(_ sender: NSMenuItem) {
        toggleGrayscale()
        wasGrayscaleModeOn = false
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

    @IBAction func toggleDisableForCurrentApp(_ sender: NSMenuItem) {
        guard let currentAppId = NSWorkspace.shared.frontmostApplication?.bundleIdentifier else {
            return
        }
        if defaults[.whitelistedApps].contains(currentAppId) {
            defaults[.whitelistedApps] = defaults[.whitelistedApps].filter {$0 != currentAppId}
        } else {
            defaults[.whitelistedApps].append(currentAppId)
        }
        updateDisableForCurrentAppMenuItemTitleAndState()
        toggleGrayscaleModeBasedOnFrontmostApp()
    }
}
