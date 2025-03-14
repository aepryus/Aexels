//
//  Baltic.h
//  Aexels
//
//  Created by Joe Charlier on 3/4/25.
//  Copyright © 2025 Aepryus Software. All rights reserved.
//

// BC = Baltic Sea : Bobbing Cylinders

// Cylinder =========
typedef struct BCCylinder {
    double iR;
    double oR;
    double height;
    double volume;
} BCCylinder;

BCCylinder* BCCylinderCreate(double oR, double iR, double height);
void BCCylinderRelease(BCCylinder* cylinder);
double BCCylinderLiquidHeight(BCCylinder* cylinder);
void BCCylinderSetLiquidHeight(BCCylinder* cylinder, double height);
void BCCylinderDrain(BCCylinder* cylinder, double volume);
