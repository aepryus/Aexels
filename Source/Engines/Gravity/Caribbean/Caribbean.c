//
//  Caribbean.c
//  Aexels
//
//  Created by Joe Charlier on 3/14/25.
//  Copyright © 2025 Aepryus Software. All rights reserved.
//

#include <stdlib.h>
#include "Caribbean.h"

// Aexel ===========================================================================================
CCAexel* CCAexelCreate(void) {
    CCAexel* aexel = (CCAexel*)malloc(sizeof(CCAexel));
    return aexel;
}
void CCAexelRelease(CCAexel* aexel) {
    free(aexel);
}

// Bond ============================================================================================
CCBond* CCBondCreate(void) {
    CCBond* bond = (CCBond*)malloc(sizeof(CCBond));
    return bond;
}
void CCBondRelease(CCBond* bond) {
    free(bond);
}

// Sector ==========================================================================================
CCSector* CCSectorCreate(void) {
    CCSector* sector = (CCSector*)malloc(sizeof(CCSector));
    return sector;
}
void CCSectorRelease(CCSector* sector) {
    free(sector);
}

// Universe ========================================================================================
CCUniverse* CCUniverseCreate(double width, double height) {
    CCUniverse* universe = (CCUniverse*)malloc(sizeof(CCUniverse));
    universe->width = width;
    universe->height = height;
    
    universe->aexelCount = 0;
    universe->aexelCapacity = 2;
    universe->aexels = (CCAexel**)malloc(sizeof(CCAexel*)*universe->aexelCapacity);
    
    universe->bondCount = 0;
    universe->bondCapacity = 2;
    universe->bonds = (CCBond**)malloc(sizeof(CCBond*)*universe->bondCapacity);
    
    universe->sectorCount = 0;
    universe->sectorCapacity = 2;
    universe->sectors = (CCSector**)malloc(sizeof(CCSector*)*universe->sectorCapacity);
    
    return universe;
}
void CCUniverseRelease(CCUniverse* universe) {
    for (int i=0;i<universe->aexelCount;i++) CCAexelRelease(universe->aexels[i]);
    free(universe->aexels);
    for (int i=0;i<universe->bondCount;i++) CCBondRelease(universe->bonds[i]);
    free(universe->bonds);
    for (int i=0;i<universe->sectorCount;i++) CCSectorRelease(universe->sectors[i]);
    free(universe->sectors);
    free(universe);
}
void CCUniverseAddAexel(CCUniverse* universe, CCAexel* aexel) {
    universe->aexelCount++;
    if (universe->aexelCount > universe->aexelCapacity) {
        universe->aexelCapacity *= 2;
        universe->aexels = (CCAexel**)realloc(universe->aexels, sizeof(CCAexel*)*universe->aexelCapacity);
    }
    universe->aexels[universe->aexelCount-1] = aexel;
}
void CCUniverseCreateAexelAt(CCUniverse* universe, double x, double y) {
    CCAexel* aexel = CCAexelCreate();
    aexel->pos.x = x;
    aexel->pos.y = y;
    CCUniverseAddAexel(universe, aexel);
}
