//
//  Caspian.h
//  Aexels
//
//  Created by Joe Charlier with Grok on 2/19/25.
//  Copyright © 2025 Aepryus Software. All rights reserved.
//

// CS = Caspian Sea : Gravity Simulator

#ifndef Caspian_h
#define Caspian_h

#include "North.h"

typedef struct CSTeslon {
    CV2 pos;         // Position in aexels
    CV2 v;           // Velocity in aexels/tic
    double hyle;     // Mass-like quantity (proxy for kg)
} CSTeslon;

CSTeslon* CSTeslonCreate(void);
void CSTeslonRelease(CSTeslon* teslon);

typedef struct CSCamera {
    CV2 pos;
    CV2 v;
    double width;
    double height;
} CSCamera;

CSCamera* CSCameraCreate(void);
void CSCameraRelease(CSCamera* camera);

typedef struct CSUniverse {
    double width;         // Aexels
    double height;        // Aexels
    double c;             // Speed of light (aexels/tic)
    double G;             // Gravitational constant (aexels³/hyle/tic²)
    int teslonCount;
    int teslonCapacity;
    CSTeslon** teslons;
    int cameraCount;
    int cameraCapacity;
    CSCamera** cameras;
    CSCamera* camera;
} CSUniverse;

CSUniverse* CSUniverseCreate(double width, double height);
void CSUniverseRelease(CSUniverse* universe);
void CSUniverseAddTeslon(CSUniverse* universe, CSTeslon* teslon);
CSTeslon* CSUniverseCreateTeslon(CSUniverse* universe, double x, double y, double hyle);
CSCamera* CSUniverseCreateCamera(CSUniverse* universe, double x, double y);
void CSUniverseTic(CSUniverse* universe);

#endif /* Caspian_h */
