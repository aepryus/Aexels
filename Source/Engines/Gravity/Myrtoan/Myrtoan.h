//
//  Myrtoan.h
//  Aexels
//
//  Created by Joe Charlier on 8/16/23.
//  Copyright © 2023 Aepryus Software. All rights reserved.
//

// MC = Myrtoan Sea : Gravity

#import "Aegean.h"
#import "North.h"

// Ring =========
typedef struct MCRing {
    double iR;
    double oR;
    double current;
    double dQ;
    double dR;
    double o;
    unsigned char focus;
} MCRing;

MCRing* MCRingCreate(void);
void MCRingRelease(MCRing* ring);

// Moon =========
typedef struct MCMoon {
    double radius;
    CV2 pos;
    CV2 v;
} MCMoon;

MCMoon* MCMoonCreate(void);
void MCMoonRelease(MCMoon* moon);

// Planet =======
typedef struct MCPlanet {
    double radius;
} MCPlanet;

MCPlanet* MCPlanetCreate(double radius);
void MCPlanetRelease(MCPlanet* ring);

// Universe =====
typedef struct MCUniverse {
    double width;
    double height;
    MCPlanet* planet;
    int ringCount;
    int ringCapacity;
    MCRing** rings;
    int moonCount;
    int moonCapacity;
    MCMoon** moons;
} MCUniverse;

MCUniverse* MCUniverseCreate(double width, double height);
void MCUniverseRelease(MCUniverse* universe);
void MCUniverseTic(MCUniverse* universe);
void MCUniverseAddRing(MCUniverse* universe, MCRing* ring);
MCRing* MCUniverseCreateRing(MCUniverse* universe, double oR, double iR, int n, double current);
void MCUniverseAddMoon(MCUniverse* universe, MCMoon* moon);
MCMoon* MCUniverseCreateMoon(MCUniverse* universe, double x, double y, double vx, double vy, double radius);
MCRing* MCUniverseRingAt(MCUniverse* universe, CV2 pos);
void MCUniverseSetFocusRing(MCUniverse* universe, MCRing* ring);
