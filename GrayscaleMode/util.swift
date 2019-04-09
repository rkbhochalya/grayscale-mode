//
//  util.swift
//  GrayscaleMode
//
//  Created by Rajendra Bhochalya on 08/04/19.
//  Copyright © 2019 Rajendra Bhochalya. All rights reserved.
//

import Cocoa

extension Bool {
    func toNSControlState() -> NSControl.StateValue {
        return self ? NSControl.StateValue.on : NSControl.StateValue.off
    }
}
