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
CCAexel* CCAexelCreate(CV2 position) {
    CCAexel* aexel = (CCAexel*)malloc(sizeof(CCAexel));
    aexel->position = position;
    aexel->velocity = (CV2){0,0};
    aexel->accelerant = 100;
    aexel->delta = 0;
    aexel->recycle = false;
    aexel->searchSectorIndex = 0;
    aexel->bondCount = 0;
    aexel->bondCapacity = 6;
    aexel->bonds = (CCBond*)malloc(sizeof(CCBond)*6);
    aexel->index = 0;
    return aexel;
}
void CCAexelRelease(CCAexel* aexel) {
    free(aexel->bonds);
    free(aexel);
}
void CCAexelAddBond(CCAexel* aexel, CCBond bond) {
    aexel->bondCount++;
    if (aexel->bondCount > aexel->bondCapacity) {
        aexel->bondCapacity *= 2;
        aexel->bonds = (CCBond*)realloc(aexel->bonds, sizeof(CCBond)*aexel->bondCapacity);
    }
    aexel->bonds[aexel->bondCount-1] = bond;
}
bool CCAexelBondsBondsCross(CCAexel* aexel, CCBond* bond) {
    CCAexel* anchor = CCBondOther(bond, aexel);
    for (int i=0;i<aexel->bondCount;i++) {
        CCBond* aexelBond = &aexel->bonds[i];
        CCAexel* other = CCBondOther(aexelBond, aexel);
        if (other == anchor) continue;
        for (int j=0;j<other->bondCount;j++) {
            CCBond* otherBond = &other->bonds[j];
            CCAexel* otherOther = CCBondOther(otherBond, other);
            if (otherOther == aexel || otherOther == anchor) continue;
            if (bond->length2 < otherBond->length2) continue;
            if (CV2LinesCross(bond->a->position, bond->b->position, otherBond->a->position, otherBond->b->position)) return true;
        }
    }
    return false;
}
void CCAexelRemoveBondTo(CCAexel* aexel, CCAexel* other) {
    int k = 0;
    int bC = aexel->bondCount;
    for (int i=0; i<bC; i++) {
        CCBond* bond = &aexel->bonds[i];
        CCAexel* test = CCBondOther(bond, aexel);
        if (test == other) {
            aexel->bondCount--;
        } else {
            if (k != i) aexel->bonds[k] = aexel->bonds[i];
            k++;
        }
    }
}

// Bond ============================================================================================
CCBond* CCBondCreate(void) {
    CCBond* bond = (CCBond*)malloc(sizeof(CCBond));
    return bond;
}
void CCBondRelease(CCBond* bond) {
    free(bond);
}
CCAexel* CCBondOther(CCBond* bond, CCAexel* aexel) {
    return bond->a == aexel ? bond->b : bond->a;
}
void CCBondRemoveBond(CCBond* bond) {
    CCAexelRemoveBondTo(bond->a, bond->b);
    CCAexelRemoveBondTo(bond->b, bond->a);
}

// Sector ==========================================================================================
CCSector* CCSectorCreate(int index) {
    CCSector* sector = (CCSector*)malloc(sizeof(CCSector));
    sector->aexelCount = 0;
    sector->aexelCapacity = 9;
    sector->aexels = (CCAexel**)malloc(sizeof(CCAexel*) * sector->aexelCapacity);
    sector->index = index;
    return sector;
}
void CCSectorRelease(CCSector* sector) {
    free(sector->aexels);
    free(sector);
}
void CCSectorAddAexel(CCSector* sector, CCAexel* aexel) {
    sector->aexelCount++;
    if (sector->aexelCount > sector->aexelCapacity) {
        sector->aexelCapacity *= 2;
        sector->aexels = (CCAexel**)realloc(sector->aexels, sizeof(CCAexel*)*sector->aexelCapacity);
    }
    sector->aexels[sector->aexelCount-1] = aexel;
}

// Planet ==========================================================================================
CCPlanet* CCPlanetCreate(double radius) {
    CCPlanet* planet = (CCPlanet*)malloc(sizeof(CCPlanet));
    planet->radius = radius;
    return planet;
}
void CCPlanetRelease(CCPlanet* planet) {
    free(planet);
}
bool CCPlanetContainsAexel(CCPlanet* planet, CCAexel* aexel) {
    if (aexel->position.x < -planet->radius ||
        aexel->position.x > planet->radius ||
        aexel->position.y < -planet->radius ||
        aexel->position.y > planet->radius) return false;
    
    double length2 = aexel->position.x * aexel->position.x + aexel->position.y * aexel->position.y;
    return length2 < planet->radius * planet->radius;
}

// Universe ========================================================================================
CCUniverse* CCUniverseCreate(double width, double height) {
    CCUniverse* universe = (CCUniverse*)malloc(sizeof(CCUniverse));
    universe->width = width;
    universe->height = height;
    
    universe->radiusBond = 32;
    universe->radiusAexel = 10;
    universe->radiusSquish = 9;
    
    universe->planet = CCPlanetCreate(80);
//    universe->planet = 0;
    
    universe->aexelCount = 0;
    universe->aexelCapacity = 2;
    universe->aexels = (CCAexel**)malloc(sizeof(CCAexel*)*universe->aexelCapacity);
    
    universe->ds = universe->radiusBond*2;
    double radius = sqrt(universe->width * universe->width + universe->height * universe->height);
    universe->sectorCountX = 2*(int)ceil(radius/universe->ds);
    universe->sectorCountY = universe->sectorCountX;
    universe->sectorCount = universe->sectorCountX * universe->sectorCountY;
    universe->sectors = (CCSector**)malloc(sizeof(CCSector*)*universe->sectorCount);
    for (int i=0;i<universe->sectorCount;i++)
        universe->sectors[i] = CCSectorCreate(i);
    
    return universe;
}
void CCUniverseRelease(CCUniverse* universe) {
    for (int i=0;i<universe->sectorCount;i++) CCSectorRelease(universe->sectors[i]);
    free(universe->sectors);
    for (int i=0;i<universe->aexelCount;i++) CCAexelRelease(universe->aexels[i]);
    free(universe->aexels);
    free(universe->planet);
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
    CCAexel* aexel = CCAexelCreate((CV2){x,y});
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
        
        int x = (int)((aexel->position.x - universe->originX)/ds);
        int y = (int)((aexel->position.y - universe->originY)/ds);
        
        if (x < 0 || x >= universe->sectorCountX || y < 0 || y >= universe->sectorCountY) {
            aexel->searchSectorIndex = -1;
            continue;
        }
        
        CCSector* sector = universe->sectors[y*universe->sectorCountX+x];
        CCSectorAddAexel(sector, aexel);
        
        int qx = (int)((aexel->position.x - ds/2 - universe->originX)/ds);
        int qy = (int)((aexel->position.y - ds/2 - universe->originY)/ds);
        
        int maxX = universe->sectorCountX - 2;
        int maxY = universe->sectorCountY - 2;
        qx = qx < 0 ? 0 : (qx > maxX ? maxX : qx );
        qy = qy < 0 ? 0 : (qy > maxY ? maxY : qy );
        aexel->searchSectorIndex = qy*universe->sectorCountX+qx;
    }
}

void CCUniverseRemoveBondsFor(CCUniverse* universe, CCAexel* aexel) {
    for (int i=0;i<aexel->bondCount;i++) {
        CCBond* bond = &aexel->bonds[i];
        CCAexel* other = CCBondOther(bond, aexel);
        
        int k = 0;
        int bC = other->bondCount;
        for (int j=0; j<bC; j++) {
            CCBond* otherBond = &other->bonds[j];
            CCAexel* otherOther = CCBondOther(otherBond, other);
            if (otherOther == aexel) {
                other->bondCount--;
            } else {
                if (k != i) other->bonds[k] = other->bonds[j];
                k++;
            }
        }
    }
}
void CCUniverseBuildBondsFor(CCUniverse* universe, CCAexel* aexel) {
    if (aexel->searchSectorIndex == -1) return;
    int sectorIndexes[] = {
        aexel->searchSectorIndex,
        aexel->searchSectorIndex+1,
        aexel->searchSectorIndex+universe->sectorCountX,
        aexel->searchSectorIndex+universe->sectorCountX+1
    };
    for (int i=0;i<4;i++) {
        int sectorIndex = sectorIndexes[i];
        CCSector* sector = universe->sectors[sectorIndex];
        for (int j=0;j<sector->aexelCount;j++) {
            CCAexel* other = sector->aexels[j];
            if (aexel->index >= other->index) continue;
            
            double dx = aexel->position.x - other->position.x;
            double dy = aexel->position.y - other->position.y;
            double length2 = dx*dx+dy*dy;
            
            if (length2 > universe->radiusBond*universe->radiusBond) continue;
            
            int stress = 0;
            if (length2 < 4*universe->radiusSquish*universe->radiusSquish) stress = 2;
            else if (length2 < 4*universe->radiusAexel*universe->radiusAexel) stress = 1;
            
            CCBond bond = (CCBond){aexel, other, length2, stress};
            CCAexelAddBond(aexel, bond);
            CCAexelAddBond(other, bond);
        }
    }
}
void CCUniverseBind(CCUniverse* universe) {
    CCUniverseDemarcate(universe);
    
    for (int i=0;i<universe->aexelCount;i++) {
        CCAexel* aexel = universe->aexels[i];
        aexel->bondCount = 0;
    }
    for (int i=0;i<universe->aexelCount;i++) {
        CCAexel* aexel = universe->aexels[i];
        CCUniverseBuildBondsFor(universe, aexel);
    }
    
    for (int i=0;i<universe->aexelCount;i++) {
        CCAexel* aexel = universe->aexels[i];
        
        for (int j=aexel->bondCount-1;j>=0;j--) {
            CCBond* bond = &aexel->bonds[j];
            if (bond->a != aexel) continue;
            CCAexel* other = bond->b;
            
            if (CCAexelBondsBondsCross(aexel, bond) || CCAexelBondsBondsCross(other, bond)) {
                CCBondRemoveBond(bond);
            }
        }
    }
}

void CCUniverseTic(CCUniverse* universe) {
    // Calculate Changes, but Don't Execute ========================================================
    for (int i=0;i<universe->aexelCount;i++) {
        CCAexel* aexel = universe->aexels[i];
        
//        double n = 1;
//        double accelerant = aexel->accelerant;
//        for (int j=0;j<aexel->bondCount;j++) {
//            CCAexel* other = CCBondOther(&aexel->bonds[j], aexel);
//            if (other->accelerant < aexel->accelerant) {
//                n++;
//                accelerant += other->accelerant;
//            }
//        }
//        double average = accelerant / n;
//        aexel->delta += average - aexel->accelerant;
//        for (int j=0;j<aexel->bondCount;j++) {
//            CCAexel* other = CCBondOther(&aexel->bonds[j], aexel);
//            if (other->accelerant < aexel->accelerant) {
//                double delta = average - other->accelerant;
//                other->delta += delta;
////                CV2 dV = CV2ofLength(CV2Sub(other->position, aexel->position), delta*0.0001);
//                double length2 = CV2LengthSquared(aexel->position);
//                if (length2 > universe->planet->radius * universe->planet->radius) {
//                    CV2 dV = CV2ofLength(CV2Neg(aexel->position), 1/length2);
//                    aexel->velocity = CV2Add(aexel->velocity, dV);
//                } else if (CV2LengthSquared(aexel->velocity) > 0) {
//                    aexel->recycle = true;
//                }
//            }
//        }
        
        double length2 = CV2LengthSquared(aexel->position);
        if (universe->planet) {
            if (length2 > universe->planet->radius * universe->planet->radius) {
                // Gravity
                aexel->acceleration = CV2ofLength(CV2Neg(aexel->position), 100/length2);
            } else if (CV2LengthSquared(aexel->velocity) > 0) {
                aexel->recycle = true;
            }
        }
        
    }

    // Execute Changes - Position, Velocity and Accelerant =========================================
    for (int i=0;i<universe->aexelCount;i++) {
        CCAexel* aexel = universe->aexels[i];
        aexel->position = CV2Add(aexel->position, aexel->velocity);
        aexel->velocity = CV2Add(aexel->velocity, aexel->acceleration);
        aexel->acceleration = (CV2){0,0};
        aexel->accelerant += aexel->delta;
        aexel->delta = 0;
//        if (CCPlanetContainsAexel(universe->planet, aexel)) { aexel->accelerant -= 1; }
    }
    
    // Crystal Jump ================================================================================
    for (int i=0;i<universe->aexelCount;i++) {
        CCAexel* aexel = universe->aexels[i];
        aexel->jump = (CV2){0,0};

        for (int j=0;j<aexel->bondCount;j++) {
            CCBond* bond = &aexel->bonds[j];
            CCAexel* other = CCBondOther(bond, aexel);
            
            double length2 = CV2LengthSquared(CV2Sub(other->position, aexel->position));
            
            double dL2 = 4*universe->radiusAexel*universe->radiusAexel - length2;
            if (dL2 > 0) {
                aexel->jump = CV2Add(aexel->jump, CV2ofLength(CV2Sub(aexel->position, other->position), dL2 * 0.007));
            }
        }
    }
    for (int i=0;i<universe->aexelCount;i++) {
        CCAexel* aexel = universe->aexels[i];
        aexel->position = CV2Add(aexel->position, aexel->jump);
    }
    
    // Remove Recycled Aexels ======================================================================
    int k = 0;
    int aC = universe->aexelCount;
    for (int i=0; i<aC; i++) {
        CCAexel* aexel = universe->aexels[i];
        if (aexel->recycle) {
            CCUniverseRemoveBondsFor(universe, aexel);
            CCAexelRelease(aexel);
            universe->aexelCount--;
        } else {
            if (k != i) {
                universe->aexels[k] = universe->aexels[i];
                universe->aexels[k]->index = k;
            }
            k++;
        }
    }
    
    // Bind ========================================================================================
    CCUniverseBind(universe);
}
