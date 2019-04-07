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
    static let isEnableAtLaunchOn = Defaults.Key<Bool>("isEnableAtLaunchOn", default: false)
    static let isEnableOnLeftKeyOn = Defaults.Key<Bool>("isEnableOnLeftKeyOn", default: false)
}

@NSApplicationMain
class AppDelegate: NSObject, NSApplicationDelegate {

    @IBOutlet weak var statusMenu: NSMenu!
    @IBOutlet weak var menuItemEnableGrayscaleMode: NSMenuItem!
    @IBOutlet weak var menuItemLaunchAtStartup: NSMenuItem!
    @IBOutlet weak var menuItemEnableAtLaunch: NSMenuItem!
    @IBOutlet weak var menuItemEnableOnLeftClick: NSMenuItem!

    let statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
    
    let hotKey = HotKey(key: .g, modifiers: [.control])

    func applicationDidFinishLaunching(_ aNotification: Notification) {
        DispatchQueue.main.async {
            self.statusItem.button?.image = #imageLiteral(resourceName: "statusBarIcon")
        }
        
        if let button = statusItem.button {
            button.action = #selector(self.handleMenuIconClick(sender:))
            button.sendAction(on: [.leftMouseUp, .rightMouseUp])
        }
        
        if defaults[.isEnableAtLaunchOn] {
            enableGrayscale()
        }
        
        checkEnableGrayscaleModeState()
        checkLaunchAtStartupState()
        checkEnableAtLaunchState()
        checkEnableOnLeftClickState()
        
        hotKey.keyDownHandler = {
            toggleGrayscale()
        }
    }

    func applicationWillTerminate(_ aNotification: Notification) {
        // Insert code here to tear down your application
    }
    
    @IBAction func toggleGrayscaleMode(_ sender: NSMenuItem) {
        toggleGrayscale();
        checkEnableGrayscaleModeState()
    }

    @IBAction func toggleLaunchAtStartup(_ sender: NSMenuItem) {
        LaunchAtLogin.isEnabled = !LaunchAtLogin.isEnabled
        checkLaunchAtStartupState()
    }
    
    @IBAction func toggleEnableAtLaunch(_ sender: NSMenuItem) {
        defaults[.isEnableAtLaunchOn] = !defaults[.isEnableAtLaunchOn]
        checkEnableAtLaunchState()
    }
    
    @IBAction func toggleEnableOnLeftClick(_ sender: NSMenuItem) {
        defaults[.isEnableOnLeftKeyOn] = !defaults[.isEnableOnLeftKeyOn]
        checkEnableOnLeftClickState()
    }
    
    func checkEnableGrayscaleModeState() {
        let state = checkIfGrayscaleOn() ? 1 : 0
        menuItemEnableGrayscaleMode.state = NSControl.StateValue(rawValue: state)
    }
    
    func checkLaunchAtStartupState() {
        let state = LaunchAtLogin.isEnabled ? 1 : 0
        menuItemLaunchAtStartup.state = NSControl.StateValue(rawValue: state)
    }

    func checkEnableAtLaunchState() {
        let state = defaults[.isEnableAtLaunchOn] ? 1 : 0
        menuItemEnableAtLaunch.state = NSControl.StateValue(rawValue: state)
    }
    
    func checkEnableOnLeftClickState() {
        let state = defaults[.isEnableOnLeftKeyOn] ? 1 : 0
        menuItemEnableOnLeftClick.state = NSControl.StateValue(rawValue: state)
    }
    
    @objc func handleMenuIconClick(sender: NSStatusItem) {
        
        let event = NSApp.currentEvent!
        
        if !defaults[.isEnableOnLeftKeyOn] {
            statusItem.popUpMenu(statusMenu)
            return
        }
        
        if event.type == NSEvent.EventType.leftMouseUp {
            statusItem.popUpMenu(statusMenu)
        } else {
            toggleGrayscale();
            checkEnableGrayscaleModeState()
        }
        
    }
}

