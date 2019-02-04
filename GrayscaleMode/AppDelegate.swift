//
//  AppDelegate.swift
//  GrayscaleMode
//
//  Created by Rajendra Bhochalya on 03/02/19.
//  Copyright © 2019 Rajendra Bhochalya. All rights reserved.
//

import Cocoa

@NSApplicationMain
class AppDelegate: NSObject, NSApplicationDelegate {

    @IBOutlet weak var statusMenu: NSMenu!
    let statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)

    func applicationDidFinishLaunching(_ aNotification: Notification) {
        self.statusItem.menu = statusMenu
        DispatchQueue.main.async {
            self.statusItem.button?.image = #imageLiteral(resourceName: "statusBarIcon")
        }
    }

    func applicationWillTerminate(_ aNotification: Notification) {
        // Insert code here to tear down your application
    }
    
    @IBAction func toggleGrayscaleMode(_ sender: NSMenuItem) {
        toggleGrayscale();
    }

}

