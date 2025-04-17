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
    aexel->moons = 0;
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

// Moon ============================================================================================
CCMoon* CCMoonCreate(void) {
    CCMoon* moon = (CCMoon*)malloc(sizeof(CCMoon));
    return moon;
}
void CCMoonRelease(CCMoon* moon) {
    free(moon);
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
CCUniverse* CCUniverseCreate(double width, double height, double darkEnergyBoost) {
    CCUniverse* universe = (CCUniverse*)malloc(sizeof(CCUniverse));
    universe->width = width;
    universe->height = height;
    
    universe->squishOn = true;
    universe->recycleOn = true;
    
    universe->p = 0;
    
    universe->radiusBond = 32;
    universe->radiusAexel = 10;
    universe->radiusSquish = 5;
    
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
    
    universe->moonCount = 0;
    universe->moonCapacity = 2;
    universe->moons = (CCMoon**)malloc(sizeof(CCMoon*)*universe->moonCapacity);
    
    universe->darkEnergyBoost = darkEnergyBoost;
    
    return universe;
}
void CCUniverseRelease(CCUniverse* universe) {
    for (int i=0;i<universe->sectorCount;i++) CCSectorRelease(universe->sectors[i]);
    free(universe->sectors);
    for (int i=0;i<universe->aexelCount;i++) CCAexelRelease(universe->aexels[i]);
    free(universe->aexels);
    for (int i=0;i<universe->moonCount;i++) CCMoonRelease(universe->moons[i]);
    free(universe->moons);
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
CCAexel* CCUniverseCreateAexelAt(CCUniverse* universe, double x, double y, double vx, double vy) {
    CCAexel* aexel = CCAexelCreate((CV2){x,y});
    aexel->velocity.x = vx;
    aexel->velocity.y = vy;
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
    
    // Recycle =====================================================================================
    if (universe->recycleOn) {
        double maxR2 = 0;
        for (int i=0;i<universe->aexelCount;i++) {
            CCAexel* aexel = universe->aexels[i];
            double length2 = CV2LengthSquared(aexel->position);
            if (length2 > maxR2) maxR2 = length2;
        }
        double border = universe->width / 2 * sqrt(2) - universe->radiusSquish;
        double border2 = border * border;
        if (maxR2 < border2) {
            double dx = 30 * 0.65;
            double dr = dx * sqrt(3)/2;
            double maxR = universe->width * sqrt(2) / 2;
            double r = floor(maxR / dr) * dr;
            double dQ = 2 * M_PI / round(r * 2 * M_PI / dx);
            CCUniverseDarkEnergy(universe, r, dQ*2, universe->p);
//            CCUniverseDarkEnergy(universe, 692.3873103256594, 0.02817571886627617*2, universe->p);

            universe->p = !universe->p;
        }
    }
    
    // Calculate Changes, but Don't Execute ========================================================
    for (int i=0;i<universe->aexelCount;i++) {
        CCAexel* aexel = universe->aexels[i];
        
        double length2 = CV2LengthSquared(aexel->position);
        if (universe->planet) {
            if (length2 > universe->planet->radius * universe->planet->radius) {
                aexel->acceleration = CV2ofLength(CV2Neg(aexel->position), 300/length2);
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
    }
    
    // Crystal Jump ================================================================================
    for (int i=0;i<universe->aexelCount;i++) {
        CCAexel* aexel = universe->aexels[i];
        aexel->jump = (CV2){0,0};

        for (int j=0;j<aexel->bondCount;j++) {
            CCBond* bond = &aexel->bonds[j];
            CCAexel* other = CCBondOther(bond, aexel);
            
            double length2 = CV2LengthSquared(CV2Sub(other->position, aexel->position));
            
            double pushRadius = (universe->radiusBond-universe->radiusAexel) * 0.5;
            double pushRadius2 = 4 * pushRadius * pushRadius;
            
            double dL2 = pushRadius2 - length2;
            if (dL2 > 0) {
                aexel->jump = CV2Add(aexel->jump, CV2ofLength(CV2Sub(aexel->position, other->position), dL2 * 0.001));
            }
        }
    }
    for (int i=0;i<universe->aexelCount;i++) {
        CCAexel* aexel = universe->aexels[i];
        aexel->position = CV2Add(aexel->position, aexel->jump);
    }
    
    // Squish ======================================================================================
    if (universe->squishOn) {
        for (int i=0;i<universe->aexelCount;i++) {
            CCAexel* aexel = universe->aexels[i];
            if (CV2Dot(aexel->position, aexel->velocity) > 0) { // Make sure the aexel doesn't pass through the planet
                aexel->recycle = true;
            } else {
                for (int j=0;j<aexel->bondCount;j++) {
                    CCBond* bond = &aexel->bonds[j];
                    if (bond->a != aexel) continue;
                    if (bond->length2 < 4*universe->radiusSquish*universe->radiusSquish) {
                        bond->b->recycle = true;
                    }
                }
            }
        }
    }
    
    // Remove Recycled Aexels ======================================================================
    int k = 0;
    int aC = universe->aexelCount;
    for (int i=0; i<aC; i++) {
        CCAexel* aexel = universe->aexels[i];
        if (aexel->recycle && aexel->moons == 0) {
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
        
    // Moons =======================================================================================
    for (int i=0;i<universe->moonCount;i++) {
        CCMoon* moon = universe->moons[i];

        CCAexel* oldAexel = moon->aexel;
        CV2 acceleration = CV2ofLength(CV2Neg(moon->position), 900/CV2LengthSquared(moon->position));
        
        moon->velocity = CV2Add(moon->velocity, acceleration);
        moon->position = CV2Add(moon->position, moon->velocity);
        
        CCAexel* newAexel = CCUniverseClosestAexelToMoon(universe, moon);
        
        if (newAexel == 0) continue;
        
        if (oldAexel != newAexel) {
            oldAexel->moons--;
            newAexel->moons++;
            moon->aexel = newAexel;


            // Calculate velocity magnitudes
//            double oldSpeed = CV2Length(oldAexel->velocity);
//            double newSpeed = CV2Length(newAexel->velocity);

            // Create a vector pointing from slow to fast aexel
//            CV2 velocityAdjustment;
//            if (newSpeed > oldSpeed) {
//                // New aexel is faster, keep current calculation
//                velocityAdjustment = CV2Sub(newAexel->velocity, oldAexel->velocity);
//            } else {
//                // Old aexel is faster, reverse the calculation
//                velocityAdjustment = CV2Sub(oldAexel->velocity, newAexel->velocity);
//            }

            // Apply the velocity adjustment
//            moon->velocity = CV2Add(moon->velocity, CV2ofLength(CV2Neg(moon->position), 300/CV2LengthSquared(moon->position)));
//            moon->velocity = CV2Add(moon->velocity, CV2ofLength(CV2Neg(moon->position), fabs(newSpeed-oldSpeed)));

        }
        
    }
    
    // Remove Recycled Moons =======================================================================
    k = 0;
    int mC = universe->moonCount;
    for (int i=0; i<mC; i++) {
        CCMoon* moon = universe->moons[i];
        if (moon->aexel == 0) {
            CCMoonRelease(moon);
            universe->moonCount--;
        } else {
            if (k != i) {
                universe->moons[k] = universe->moons[i];
            }
            k++;
        }
    }

}

void CCUniverseDarkEnergy(CCUniverse* universe, double r, double dQ, bool p) {
    double maxQ = 2 * M_PI;
    double Q = !p ? 0 : dQ/2;

    while (Q < maxQ) {
        double x = r * cos(Q);
        double y = r * sin(Q);
        double q = universe->darkEnergyBoost;
        CCUniverseCreateAexelAt(universe, x, y, -x*q, -y*q);
        Q += dQ;
    }
}
void CCUniverseSetSquishOn(CCUniverse* universe, bool squishOn) {
    universe->squishOn = squishOn;
}
void CCUniverseSetRecycleOn(CCUniverse* universe, bool recycleOn) {
    universe->recycleOn = recycleOn;
}
void CCUniverseAddMoon(CCUniverse* universe, CCMoon* moon) {
    universe->moonCount++;
    if (universe->moonCount > universe->moonCapacity) {
        universe->moonCapacity *= 2;
        universe->moons = (CCMoon**)realloc(universe->moons, sizeof(CCMoon*)*universe->moonCapacity);
    }
    universe->moons[universe->moonCount-1] = moon;
}
CCMoon* CCUniverseAddMoonAt(CCUniverse* universe, double x, double y, double vx, double vy, double radius) {
    CCMoon* moon = CCMoonCreate();
    moon->position.x = x;
    moon->position.y = y;
    moon->velocity.x = vx;
    moon->velocity.y = vy;
    moon->radius = radius;

    moon->aexel = CCUniverseClosestAexelToMoon(universe, moon);
    moon->aexel->moons++;
    
    CCUniverseAddMoon(universe, moon);
    return moon;
}
CCAexel* CCUniverseClosestAexelToMoon(CCUniverse* universe, CCMoon* moon) {
    CCAexel* closest = 0;
    double minLength2 = 100000;
    for (int i=0;i<universe->aexelCount;i++) {
        CCAexel* aexel = universe->aexels[i];
        double dx = aexel->position.x - moon->position.x;
        double dy = aexel->position.y - moon->position.y;
        double length2 = dx*dx + dy*dy;
        if (length2 < minLength2) {
            minLength2 = length2;
            closest = aexel;
        }
    }
    return closest;
}
