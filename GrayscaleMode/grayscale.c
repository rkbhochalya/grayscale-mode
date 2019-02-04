//
//  grayscale.c
//  GrayscaleMode
//
//  Created by Rajendra Bhochalya on 04/02/19.
//  Copyright © 2019 Rajendra Bhochalya. All rights reserved.
//

#include "grayscale.h"

bool checkIfGrayscaleOn(void) {
    bool isGrayscale = CGDisplayUsesForceToGray();
    return isGrayscale;
}

void enableGrayscale(void) {
    CGDisplayForceToGray(true);
}

void disableGrayscale(void) {
    CGDisplayForceToGray(false);
}

void toggleGrayscale(void) {
    bool isGrayscale = CGDisplayUsesForceToGray();
    CGDisplayForceToGray(!isGrayscale);
}
