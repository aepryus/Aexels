//
//  Baltic.c
//  Aexels
//
//  Created by Joe Charlier on 3/4/25.
//  Copyright © 2025 Aepryus Software. All rights reserved.
//

#import <math.h>
#import <stdlib.h>
#include "Baltic.h"

BCCylinder* BCCylinderCreate(double oR, double iR, double height) {
    BCCylinder* cylinder = (BCCylinder*)malloc(sizeof(BCCylinder));
    cylinder->iR = iR;
    cylinder->oR = oR;
    cylinder->height = height;
    cylinder->volume = M_PI * (cylinder->oR * cylinder->oR - cylinder->iR * cylinder->iR) * height;
    return cylinder;
}
void BCCylinderRelease(BCCylinder* cylinder) {
    free(cylinder);
}
double BCCylinderLiquidHeight(BCCylinder* cylinder) {
    double area = M_PI * (cylinder->oR * cylinder->oR - cylinder->iR * cylinder->iR);
    return cylinder->volume / area;
}
void BCCylinderSetLiquidHeight(BCCylinder* cylinder, double height) {
    cylinder->height = height;
    cylinder->volume = M_PI * (cylinder->oR * cylinder->oR - cylinder->iR * cylinder->iR) * height;
}
void BCCylinderDrain(BCCylinder* cylinder, double volume) {
    cylinder->volume -= fmin(volume, cylinder->volume);
}
