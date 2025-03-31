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

// Aexel ===============
typedef struct CCAexel {
    CV2 position;
    CV2 velocity;
    CV2 acceleration;
    double accelerant;
    double delta;
    CV2 jump;
    bool recycle;
    int searchSectorIndex;
    int bondCount;
    int bondCapacity;
    CCBond* bonds;
    int index;
} CCAexel;

CCAexel* CCAexelCreate(CV2 pos);
void CCAexelRelease(CCAexel* aexel);
void CCAexelAddBond(CCAexel* aexel, CCBond bond);

// Bond ================
typedef struct CCBond {
    CCAexel* a;
    CCAexel* b;
    double length2;
    int stress;
} CCBond;

CCBond* CCBondCreate(void);
void CCBondRelease(CCBond* bond);
CCAexel* CCBondOther(CCBond* bond, CCAexel* aexel);

// Sector ==============
typedef struct CCSector {
    int aexelCount;
    int aexelCapacity;
    CCAexel** aexels;
    int index;
} CCSector;

CCSector* CCSectorCreate(int index);
void CCSectorRelease(CCSector* sector);

// Packet ==============
typedef struct CCPacket {
    CCAexel* source;
} CCPacket;

// Planet ==============
typedef struct CCPlanet {
    CV2 position;
    double radius;
} CCPlanet;

CCPlanet* CCPlanetCreate(double radius);
void CCPlanetRelease(CCPlanet* planet);
bool CCPlanetContainsAexel(CCPlanet* planet, CCAexel* aexel);

// Universe ============
typedef struct CCUniverse {
    double width;
    double height;
    
    bool squishOn;
    bool recycleOn;
    
    bool p;
    
    double radiusBond;
    double radiusAexel;
    double radiusSquish;
    
    double ds;
    double originX;
    double originY;
    int sectorCountX;
    int sectorCountY;
    
    CCPlanet* planet;

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
CCAexel* CCUniverseCreateAexelAt(CCUniverse* universe, double x, double y, double vx, double vy);
void CCUniverseDemarcate(CCUniverse* universe);
void CCUniverseBind(CCUniverse* universe);
void CCUniverseTic(CCUniverse* universe);
void CCUniverseDarkEnergy(CCUniverse* universe, double r, double dQ, bool p);
void CCUniverseSetSquishOn(CCUniverse* universe, bool squishOn);
void CCUniverseSetRecycleOn(CCUniverse* universe, bool recycleOn);
