//
//  Caribbean.c
//  Aexels
//
//  Created by Joe Charlier on 3/14/25.
//  Copyright © 2025 Aepryus Software. All rights reserved.
//

#include <math.h>
#include <stdlib.h>
#include "Caribbean.h"

#include <stdio.h>

// Aexel ===========================================================================================
CCAexel* CCAexelCreate(void) {
    CCAexel* aexel = (CCAexel*)malloc(sizeof(CCAexel));
    aexel->bonds = (CCBond*)malloc(sizeof(CCBond)*6);
    aexel->admin = (CCBond**)malloc(sizeof(CCBond*)*6);
    aexel->adminCount = 0;
    return aexel;
}
void CCAexelRelease(CCAexel* aexel) {
    free(aexel->bonds);
    free(aexel->admin);
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
    sector->aexels = (CCAexel**)malloc(sizeof(CCAexel*)*10);
    return sector;
}
void CCSectorRelease(CCSector* sector) {
    free(sector->aexels);
    free(sector);
}

// Universe ========================================================================================
CCUniverse* CCUniverseCreate(double width, double height) {
    CCUniverse* universe = (CCUniverse*)malloc(sizeof(CCUniverse));
    universe->width = width;
    universe->height = height;
    
    universe->radiusBond = 24;
    universe->radiusAexel = 10;
    universe->radiusSquish = 9;
    
    universe->aexelCount = 0;
    universe->aexelCapacity = 2;
    universe->aexels = (CCAexel**)malloc(sizeof(CCAexel*)*universe->aexelCapacity);
    
    universe->ds = universe->radiusBond*2;
    universe->sectorCountX = 2*(int)ceil(universe->width/2/universe->ds);
    universe->sectorCountY = 2*(int)ceil(universe->height/2/universe->ds);
    universe->sectorCount = universe->sectorCountX * universe->sectorCountY;
    universe->sectors = (CCSector**)malloc(sizeof(CCSector*)*universe->sectorCount);
    for (int i=0;i<universe->sectorCount;i++)
        universe->sectors[i] = CCSectorCreate();
    
    return universe;
}
void CCUniverseRelease(CCUniverse* universe) {
    for (int i=0;i<universe->aexelCount;i++) CCAexelRelease(universe->aexels[i]);
    free(universe->aexels);
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
    aexel->index = universe->aexelCount-1;
    universe->aexels[aexel->index] = aexel;
}
CCAexel* CCUniverseCreateAexelAt(CCUniverse* universe, double x, double y) {
    CCAexel* aexel = CCAexelCreate();
    aexel->pos.x = x;
    aexel->pos.y = y;
    CCUniverseAddAexel(universe, aexel);
    return aexel;
}
void CCUniverseDemarcate(CCUniverse* universe) {
    for (int i=0;i<universe->sectorCount;i++) { universe->sectors[i]->aexelCount = 0; }
    
    double ds = universe->ds;
    
    universe->originX = -ds * universe->sectorCountX/2;
    universe->originY = -ds * universe->sectorCountY/2;
    
    for (int i=0;i<universe->aexelCount;i++) {
        CCAexel* aexel = universe->aexels[i];
        int x = (int)((aexel->pos.x - universe->originX)/ds);
        int y = (int)((aexel->pos.y - universe->originY)/ds);
        CCSector* sector = universe->sectors[y*universe->sectorCountX+x];
        sector->aexels[sector->aexelCount++] = aexel;
        
        int qx = (int)((aexel->pos.x - ds/2 - universe->originX)/ds);
        int qy = (int)((aexel->pos.y - ds/2 - universe->originY)/ds);
        
        int maxX = universe->sectorCountX - 2;
        int maxY = universe->sectorCountY - 2;
        qx = qx < 0 ? 0 : (qx > maxX ? maxX : qx );
        qy = qy < 0 ? 0 : (qy > maxY ? maxY : qy );
        aexel->searchSectorIndex = qy*universe->sectorCountX+qx;
    }
}
void CCUniverseBuildBondsFor(CCUniverse* universe, CCAexel* aexel) {
    int sectorIndexes[] = {
        aexel->searchSectorIndex,
        aexel->searchSectorIndex+1,
        aexel->searchSectorIndex+universe->sectorCountX,
        aexel->searchSectorIndex+universe->sectorCountX+1
    };
    for (int i=0;i<4;i++) {
        int sectorIndex = sectorIndexes[i];
        if (sectorIndex < 0 || sectorIndex >= universe->sectorCount) continue;
        CCSector* sector = universe->sectors[sectorIndex];
        for (int j=0;j<sector->aexelCount;j++) {
            CCAexel* other = sector->aexels[j];
            if (aexel->index >= other->index) continue;
            
            double dx = aexel->pos.x - other->pos.x;
            double dy = aexel->pos.y - other->pos.y;
            double length2 = dx*dx+dy*dy;
            
            if (length2 > universe->radiusBond*universe->radiusBond) continue;

            CCBond bond = (CCBond){aexel, other, length2};
            aexel->bonds[aexel->bondCount++] = bond;
            other->bonds[other->bondCount++] = bond;
            aexel->admin[aexel->adminCount++] = &aexel->bonds[aexel->bondCount-1];
        }
    }
}

void CCUniverseBind(CCUniverse* universe) {
    CCUniverseDemarcate(universe);
    
    for (int i=0;i<universe->aexelCount;i++) {
        CCAexel* aexel = universe->aexels[i];
        aexel->bondCount = 0;
        aexel->adminCount = 0;
    }
    for (int i=0;i<universe->aexelCount;i++) {
        CCAexel* aexel = universe->aexels[i];
        CCUniverseBuildBondsFor(universe, aexel);
    }
}
