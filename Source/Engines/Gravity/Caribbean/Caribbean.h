//
//  Caribbean.h
//  Aexels
//
//  Created by Joe Charlier on 3/14/25.
//  Copyright © 2025 Aepryus Software. All rights reserved.
//

// CC = Caribbean Sea : Gravity

#import "Sea.h"

typedef struct CCBond CCBond;

typedef struct CCAexel {
    CV2 pos;
    int bondCount;
    CCBond* bonds;
    int adminCount;
    CCBond** admin;
    int searchSectorIndex;
    int index;
} CCAexel;

CCAexel* CCAexelCreate(void);
void CCAexelRelease(CCAexel* aexel);

typedef struct CCBond {
    CCAexel* a;
    CCAexel* b;
    double length2;
} CCBond;

CCBond* CCBondCreate(void);
void CCBondRelease(CCBond* bond);

typedef struct CCSector {
    int aexelCount;
    int aexelCapacity;
    CCAexel** aexels;
    int index;
} CCSector;

CCSector* CCSectorCreate(void);
void CCSectorRelease(CCSector* sector);

typedef struct CCPacket {
    CCAexel* source;
} CCPacket;

typedef struct CCUniverse {
    double width;
    double height;
    
    double radiusBond;
    double radiusAexel;
    double radiusSquish;
    
    double ds;
    double originX;
    double originY;
    int sectorCountX;
    int sectorCountY;

    int aexelCount;
    int aexelCapacity;
    CCAexel** aexels;

    int sectorCount;
    int sectorCapacity;
    CCSector** sectors;
} CCUniverse;

CCUniverse* CCUniverseCreate(double width, double height);
void CCUniverseRelease(CCUniverse* universe);
void CCUniverseAddAexel(CCUniverse* universe, CCAexel* aexel);
CCAexel* CCUniverseCreateAexelAt(CCUniverse* universe, double x, double y);
void CCUniverseAddBond(CCUniverse* universe, CCBond* bond);
void CCUniverseDemarcate(CCUniverse* universe);
void CCUniverseBind(CCUniverse* universe);
