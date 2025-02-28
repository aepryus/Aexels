//
//  Myrtoan.c
//  Aexels
//
//  Created by Joe Charlier on 8/16/23.
//  Copyright © 2023 Aepryus Software. All rights reserved.
//

#import <math.h>
#import <stdio.h>
#import <stdlib.h>
#include "Myrtoan.h"

// Planet ==========================================================================================
MCPlanet* MCPlanetCreate(double radius) {
    MCPlanet* planet = (MCPlanet*)malloc(sizeof(MCPlanet));
    planet->radius = radius;
    return planet;
}
void MCPlanetRelease(MCPlanet* planet) {
    free(planet);
}

// Ring ============================================================================================
MCRing* MCRingCreate(void) {
    MCRing* ring = (MCRing*)malloc(sizeof(MCRing));
    return ring;
}
void MCRingRelease(MCRing* ring) {
    free(ring);
}

// Moon ============================================================================================
MCMoon* MCMoonCreate(void) {
    MCMoon* moon = (MCMoon*)malloc(sizeof(MCMoon));
    return moon;
}
void MCMoonRelease(MCMoon* moon) {
    free(moon);
}

// Universe ========================================================================================
MCUniverse* MCUniverseCreate(double width, double height) {
    MCUniverse* universe = (MCUniverse*)malloc(sizeof(MCUniverse));
    
    universe->width = width;
    universe->height = height;
    
    universe->planet = MCPlanetCreate(80);
    
    universe->ringCount = 0;
    universe->ringCapacity = 1;
    universe->rings = (MCRing**)malloc(sizeof(MCRing*)*universe->ringCapacity);
    
    universe->moonCount = 0;
    universe->moonCapacity = 1;
    universe->moons = (MCMoon**)malloc(sizeof(MCMoon*)*universe->moonCapacity);
    
    return universe;
}
void MCUniverseRelease(MCUniverse* universe) {
    if (universe == 0) return;
    for (int i=0;i<universe->moonCount;i++) MCMoonRelease(universe->moons[i]);
    free(universe->moons);
    for (int i=0;i<universe->ringCount;i++) MCRingRelease(universe->rings[i]);
    free(universe->rings);
    MCPlanetRelease(universe->planet);
    free(universe);
}
void MCUniverseTic(MCUniverse* universe) {
}
void MCUniverseAddRing(MCUniverse* universe, MCRing* ring) {
    universe->ringCount++;
    if (universe->ringCount > universe->ringCapacity) {
        universe->ringCapacity *= 2;
        universe->rings = (MCRing**)realloc(universe->rings, sizeof(MCRing*)*universe->ringCapacity);
    }
    universe->rings[universe->ringCount-1] = ring;
}
MCRing* MCUniverseCreateRing(MCUniverse* universe, double oR, double iR, int n) {
    double nQ = n*3;
    MCRing* ring = MCRingCreate();
    ring->oR = oR;
    ring->iR = iR;
    ring->dQ = 2*M_PI/nQ;
    ring->dR = ring->dQ * (iR+oR)/2 * sqrt(3)/2;
    MCUniverseAddRing(universe, ring);
    return ring;
}
void MCUniverseAddMoon(MCUniverse* universe, MCMoon* moon) {
    universe->moonCount++;
    if (universe->moonCount > universe->moonCapacity) {
        universe->moonCapacity *= 2;
        universe->moons = (MCMoon**)realloc(universe->moons, sizeof(MCMoon*)*universe->moonCapacity);
    }
    universe->moons[universe->moonCount-1] = moon;
}
MCMoon* MCUniverseCreateMoon(MCUniverse* universe, double x, double y, double radius) {
    MCMoon* moon = MCMoonCreate();
    moon->pos.x = x;
    moon->pos.y = y;
    moon->radius = radius;
    MCUniverseAddMoon(universe, moon);
    return moon;
}
