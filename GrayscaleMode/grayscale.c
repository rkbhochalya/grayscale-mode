//
//  grayscale.c
//  GrayscaleMode
//
//  Created by Rajendra Bhochalya on 04/02/19.
//  Copyright © 2019 Rajendra Bhochalya. All rights reserved.
//

#include "grayscale.h"

bool isGrayscaleModeEnabled(void) {
    bool isEnabled = CGDisplayUsesForceToGray();
    return isEnabled;
}

void enableGrayscaleMode(void) {
    CGDisplayForceToGray(true);
}

void disableGrayscaleMode(void) {
    CGDisplayForceToGray(false);
}

void toggleGrayscaleMode(void) {
    bool isEnabled = CGDisplayUsesForceToGray();
    CGDisplayForceToGray(!isEnabled);
}
