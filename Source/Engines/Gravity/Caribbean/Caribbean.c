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
//void CCAexelAddBond(CCAexel* aexel, CCBond* bond) {
//    aexel->bondCount++;
//    if (aexel->bondCount > aexel->bondCapacity) {
//        aexel->bondCapacity *= 2;
////        aexel->bonds = (CCBond**)realloc(aexel->bonds, sizeof(CCBond*)*aexel->bondCapacity);
//    }
////    aexel->bonds[aexel->bondCount-1] = bond;
//}

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
    
//    universe->bondCount = 0;
//    universe->bondCapacity = 2;
//    universe->bonds = (CCBond**)malloc(sizeof(CCBond*)*universe->bondCapacity);
    
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
//    for (int i=0;i<universe->bondCount;i++) CCBondRelease(universe->bonds[i]);
//    free(universe->bonds);
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
//void CCUniverseAddBond(CCUniverse* universe, CCBond* bond) {
//    universe->bondCount++;
//    if (universe->bondCount > universe->bondCapacity) {
//        universe->bondCapacity *= 2;
//        universe->bonds = (CCBond**)realloc(universe->bonds, sizeof(CCBond*)*universe->bondCapacity);
//    }
//    universe->bonds[universe->bondCount-1] = bond;
//}
//void CCUniverseCreateBondBetween(CCUniverse* universe, CCAexel* a, CCAexel* b) {
//    CCBond* bond = CCBondCreate();
//    bond->a = a;
//    bond->b = b;
//    double dx = a->pos.x - b->pos.x;
//    double dy = a->pos.y - b->pos.y;
//    bond->length2 = dx*dx + dy*dy;
//    CCAexelAddBond(bond->a, bond);
//    CCAexelAddBond(bond->b, bond);
//    CCUniverseAddBond(universe, bond);
//}
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
//        aexel->searchSectorIndex = y*universe->sectorCountX+x;
    }
}
//void CCUniverseWipeBondsFor(CCUniverse* universe, CCAexel* aexel) {
//    for (int i=0;i<universe->bondCount;i++) {
//        if (universe->bonds[i]->a == aexel || universe->bonds[i]->b == aexel) {
//            universe->bondCount--;
//            if (i != universe->bondCount) {
//                universe->bonds[i] = universe->bonds[universe->bondCount];
//                i--;
//            }
//        }
//    }
//}
void CCUniverseBuildBondsFor(CCUniverse* universe, CCAexel* aexel) {
    int sectorIndexes[] = {
        aexel->searchSectorIndex,
        aexel->searchSectorIndex+1,
        aexel->searchSectorIndex+universe->sectorCountX,
        aexel->searchSectorIndex+universe->sectorCountX+1
    };
//    int sectorIndexes[] = {
//        aexel->searchSectorIndex-universe->sectorCountX-1,
//        aexel->searchSectorIndex-universe->sectorCountX,
//        aexel->searchSectorIndex-universe->sectorCountX+1,
//        aexel->searchSectorIndex-1,
//        aexel->searchSectorIndex,
//        aexel->searchSectorIndex+1,
//        aexel->searchSectorIndex+universe->sectorCountX-1,
//        aexel->searchSectorIndex+universe->sectorCountX,
//        aexel->searchSectorIndex+universe->sectorCountX+1
//    };

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
    
//    if (aexel->bondCount < 6 && aexel->pos.x > -100 && aexel->pos.x < 100 && aexel->pos.y > -100 && aexel->pos.y < 100) {
//        
//        aexel->bondCount = 0;
//        aexel->adminCount = 0;
//        
//        for (int i=0;i<4;i++) {
//            int sectorIndex = sectorIndexes[i];
//            if (sectorIndex < 0 || sectorIndex >= universe->sectorCount) continue;
//            
//            double ds = universe->ds;
//            
//            int x = (int)((aexel->pos.x - universe->originX)/ds);
//            int y = (int)((aexel->pos.y - universe->originY)/ds);
//            
//            if (x == 0 || y == 0 || x == universe->sectorCountX-1) continue;
//            
//            int sectorIndex2 = y*universe->sectorCountX+x;
//            
////            printf("qq:%d, %d, %d\n", x, y, sectorIndex2);
//            
//            int qx = (int)((aexel->pos.x - ds/2 - universe->originX)/ds);
//            int qy = (int)((aexel->pos.y - ds/2 - universe->originY)/ds);
//            
//            double x1 = universe->originX + qx * universe->ds;
//            double y1 = universe->originY + qy * universe->ds;
//            double x2 = universe->originX + (qx+1) * universe->ds;
//            double y2 = universe->originY + (qy+1) * universe->ds;
//
//            printf("(%0.0lf, %0.0lf) - (%0.0lf, %0.0lf)\n", x1, y1, x2, y2);
//            printf("pos:(%0.0lf, %0.0lf)\n", aexel->pos.x, aexel->pos.y);
//                        
//            CCSector* sector = universe->sectors[sectorIndex];
//            for (int j=0;j<sector->aexelCount;j++) {
//                CCAexel* other = sector->aexels[j];
//                if (aexel->index >= other->index) continue;
//                
//                double dx = aexel->pos.x - other->pos.x;
//                double dy = aexel->pos.y - other->pos.y;
//                double length2 = dx*dx+dy*dy;
//                
//                if (length2 > 4*universe->radiusBond*universe->radiusBond) continue;
//
//                CCBond bond = (CCBond){aexel, other, length2};
//                aexel->bonds[aexel->bondCount++] = bond;
//                other->bonds[other->bondCount++] = bond;
//                aexel->admin[aexel->adminCount++] = &aexel->bonds[aexel->bondCount-1];
//            }
//        }
//    }
}
//CCBond* CCUniverseBondForIndex(CCUniverse* universe, int index) {
//    for (int i=0;i<universe->aexelCount;i++) {
//        CCAexel* aexel = universe->aexels[i];
//        if (index >= aexel->bondCount) { index -= aexel->bondCount; continue; }
//        return aexel->aBonds[index];
//    }
//    return 0;
//}

void CCUniverseBind(CCUniverse* universe) {
//    double snap = universe->radiusBond;
    
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
