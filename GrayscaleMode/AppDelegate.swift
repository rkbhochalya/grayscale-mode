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
    static let isEnabled = Defaults.Key<Bool>("isEnabled", default: false)
    static let shouldEnableOnRightClick = Defaults.Key<Bool>("shouldEnableOnRightClick", default: false)
    static let isHotKeyEnabled = Defaults.Key<Bool>("isHotKeyEnabled", default: true)
    static let whitelistedApps = Defaults.Key<[String]>("whitelistedApps", default: [])
}

@NSApplicationMain
class AppDelegate: NSObject, NSApplicationDelegate {

    @IBOutlet weak var statusMenu: NSMenu!
    @IBOutlet weak var enableGrayscaleModeMenuItem: NSMenuItem!
    @IBOutlet weak var launchAtLoginMenuItem: NSMenuItem!
    @IBOutlet weak var enableOnRightClickMenuItem: NSMenuItem!
    @IBOutlet weak var disableForCurrentAppMenuItem: NSMenuItem!

    let statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
    let toggleShortcutUserDefaultsKey = "toggleShortcutKey"
    var prefViewController: PreferencesViewController!
    var isEnabledObserver: DefaultsObservation!
    var shouldEnableOnRightClickObserver: DefaultsObservation!
    var isHotKeyEnabledObserver: DefaultsObservation!

    func applicationDidFinishLaunching(_ aNotification: Notification) {
        DispatchQueue.main.async {
            self.statusItem.button?.image = #imageLiteral(resourceName: "statusBarIcon")
        }

        if let button = statusItem.button {
            button.action = #selector(self.handleMenuIconClick(sender:))
            button.sendAction(on: [.leftMouseUp, .rightMouseUp])
        }

        isEnabledObserver = Defaults.observe(.isEnabled, options: [.initial, .old, .new]) { change in
            if change.newValue {
                self.maybeEnableGrayscaleMode()
            } else {
                disableGrayscaleMode()
            }
            self.enableGrayscaleModeMenuItem.state = change.newValue.toNSControlState()
        }

        shouldEnableOnRightClickObserver = Defaults.observe(.shouldEnableOnRightClick, options: [.initial, .old, .new]) { change in
            self.enableOnRightClickMenuItem.state = change.newValue.toNSControlState()
        }

        isHotKeyEnabledObserver = Defaults.observe(.isHotKeyEnabled, options: [.initial, .old, .new]) { change in
            if change.newValue {
                // Bind shortcut to grayscale mode toggle action
                MASShortcutBinder.shared().bindShortcut(withDefaultsKey: self.toggleShortcutUserDefaultsKey, toAction: {
                    Defaults[.isEnabled].toggle()
                })
            } else {
                // Remove shortcut callback binding
                MASShortcutBinder.shared().breakBinding(withDefaultsKey: self.toggleShortcutUserDefaultsKey)
            }
        }

        NSWorkspace.shared.notificationCenter.addObserver(self,
                                               selector: #selector(self.frontmostAppChanged),
                                               name: NSWorkspace.didActivateApplicationNotification,
                                               object: nil)

        setDefaultShortcutOnFirstLaunch()
        syncLaunchAtLoginMenuItemState()
        updateDisableForCurrentAppMenuItemTitleAndState()
    }

    func applicationWillTerminate(_ aNotification: Notification) {
        disableGrayscaleMode()
    }

    @objc func frontmostAppChanged() {
        updateDisableForCurrentAppMenuItemTitleAndState()
        toggleGrayscaleModeBasedOnFrontmostApp()
    }

    // Enable grayscale mode only if frontmost app is not whitelisted
    func maybeEnableGrayscaleMode() {
        guard let currentAppId = NSWorkspace.shared.frontmostApplication?.bundleIdentifier else {
            return
        }
        if Defaults[.whitelistedApps].contains(currentAppId) {
            return
        }
        enableGrayscaleMode()
    }

    func setDefaultShortcutOnFirstLaunch() {
        let modifierFlags = NSEvent.ModifierFlags.init(arrayLiteral: [.option, .command])
        guard let defaultShortcut = MASShortcut(keyCode: kVK_ANSI_G,
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
        menuItem.title = "Disable when \(currentAppName) is active"
        menuItem.state = Defaults[.whitelistedApps].contains(currentAppId).toNSControlState()
    }

    func toggleGrayscaleModeBasedOnFrontmostApp() {
        guard let currentAppId = NSWorkspace.shared.frontmostApplication?.bundleIdentifier else {
            return
        }
        if Defaults[.whitelistedApps].contains(currentAppId) {
            if isGrayscaleModeEnabled() {
                disableGrayscaleMode()
            }
        } else if Defaults[.isEnabled] && !isGrayscaleModeEnabled() {
            enableGrayscaleMode()
        }
    }

    @objc func handleMenuIconClick(sender: NSStatusItem) {
        let event = NSApp.currentEvent!

        if !Defaults[.shouldEnableOnRightClick] {
            statusItem.popUpMenu(statusMenu)
            return
        }

        if event.type == NSEvent.EventType.leftMouseUp {
            statusItem.popUpMenu(statusMenu)
        } else {
            Defaults[.isEnabled].toggle()
        }
    }

    @IBAction func toggleGrayscaleModeAction(_ sender: NSMenuItem) {
        Defaults[.isEnabled].toggle()
    }

    @IBAction func toggleLaunchAtLogin(_ sender: NSMenuItem) {
        LaunchAtLogin.isEnabled.toggle()
        syncLaunchAtLoginMenuItemState()
        if let prefViewController = prefViewController {
            prefViewController.syncLaunchAtLoginCheckboxState()
        }
    }

    @IBAction func toggleEnableOnRightClick(_ sender: NSMenuItem) {
        Defaults[.shouldEnableOnRightClick].toggle()
    }

    @IBAction func toggleDisableForCurrentApp(_ sender: NSMenuItem) {
        guard let currentAppId = NSWorkspace.shared.frontmostApplication?.bundleIdentifier else {
            return
        }
        if Defaults[.whitelistedApps].contains(currentAppId) {
            Defaults[.whitelistedApps] = Defaults[.whitelistedApps].filter {$0 != currentAppId}
        } else {
            Defaults[.whitelistedApps].append(currentAppId)
        }
        updateDisableForCurrentAppMenuItemTitleAndState()
        toggleGrayscaleModeBasedOnFrontmostApp()
    }
}
