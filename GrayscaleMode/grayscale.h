//
//  grayscale.h
//  GrayscaleMode
//
//  Created by Rajendra Bhochalya on 04/02/19.
//  Copyright © 2019 Rajendra Bhochalya. All rights reserved.
//

#ifndef grayscale_h
#define grayscale_h

#include <stdio.h>
#include <ApplicationServices/ApplicationServices.h>

CG_EXTERN bool CGDisplayUsesForceToGray(void);
CG_EXTERN void CGDisplayForceToGray(bool forceToGray);

bool checkIfGrayscaleOn(void);
void enableGrayscale(void);
void disableGrayscale(void);
void toggleGrayscale(void);

#endif /* grayscale_h */
