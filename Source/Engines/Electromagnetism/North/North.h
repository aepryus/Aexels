//
//  North.h
//  Aexels
//
//  Created by Joe Charlier on 12/12/24.
//  Copyright © 2024 Aepryus Software. All rights reserved.
//

// NC = North Sea : Electricity and Magnetism

typedef struct CV2 {
    double x;
    double y;
} CV2;

CV2 CV2Neg(CV2 a);
double CV2Length(CV2 a);
double CV2Orient(CV2 a);
double CV2Gamma(CV2 a);
double CV2Dot(CV2 a, CV2 b);

typedef struct NCTeslon {
    CV2 pos;
    CV2 v;
    double hyle;                  // innate hyle
    unsigned char pings;
    unsigned char contracts;
} NCTeslon;

NCTeslon* NCTeslonCreate(void);
void NCTeslonRelease(NCTeslon* teslon);
double NCTeslonHyle(NCTeslon* teslon);
CV2 NCTeslonMomentum(NCTeslon* teslon);
void NCTeslonAddMomentum(NCTeslon* teslon, CV2 momentum, unsigned char bounded);

typedef struct NCPing {
    CV2 pos;
    CV2 v;
    CV2 cupola;
    unsigned char recycle;
    NCTeslon* source;
} NCPing;

NCPing* NCPingCreate(void);
void NCPingRelease(NCPing* ping);

typedef struct NCPong {
    CV2 pos;
    CV2 v;
    CV2 cupola;
    unsigned char recycle;
    NCTeslon* source;
} NCPong;

NCPong* NCPongCreate(void);
void NCPongRelease(NCPong* pong);

typedef struct NCPhoton {
    CV2 pos;
    CV2 v;
    CV2 cupola;
    CV2 momentum;
    double hyle;
    unsigned char recycle;
    NCTeslon* source;
} NCPhoton;

NCPhoton* NCPhotonCreate(void);
void NCPhotonRelease(NCPhoton* photon);

typedef struct NCCamera {
    CV2 pos;
    CV2 v;
    double width;
    double height;
    unsigned char walls;
} NCCamera;

NCCamera* NCCameraCreate(void);
void NCCameraRelease(NCCamera* camera);
void NCCameraSetWalls(NCCamera* camera, unsigned char walls);

typedef struct NCUniverse {
    double width;
    double height;
    double speed;
    double c;
    double boundrySquared;
    unsigned char hyleExchange;
    int teslonCount;
    int teslonCapacity;
    NCTeslon** teslons;
    int pingCount;
    int pingCapacity;
    NCPing** pings;
    int pongCount;
    int pongCapacity;
    NCPong** pongs;
    int photonCount;
    int photonCapacity;
    NCPhoton** photons;
    int cameraCount;
    int cameraCapacity;
    NCCamera** cameras;
    NCCamera* camera;
} NCUniverse;

NCUniverse* NCUniverseCreate(double width, double height);
void NCUniverseRelease(NCUniverse* universe);
void NCUniverseAddTeslon(NCUniverse* universe, NCTeslon* teslon);
void NCUniverseAddPing(NCUniverse* universe, NCPing* ping);
void NCUniverseAddPong(NCUniverse* universe, NCPong* pong);
void NCUniverseAddPhoton(NCUniverse* universe, NCPhoton* photon);
NCTeslon* NCUniverseCreateTeslon(NCUniverse* universe, double x, double y, double speed, double orient, double hyle, unsigned char pings, unsigned char contracts);
NCPing* NCUniverseCreatePing(NCUniverse* universe, NCTeslon* teslon);
NCPong* NCUniverseCreatePong(NCUniverse* universe, NCTeslon* teslon);
NCPhoton* NCUniverseCreatePhoton(NCUniverse* universe, NCTeslon* teslon);
NCCamera* NCUniverseCreateCamera(NCUniverse* universe, double x, double y, double speed, double orient);
int NCUniverseOutsideOf(NCUniverse* universe, CV2 pos);
int NCTeslonInsideOf(NCTeslon* teslon, CV2 pos, double radius);
void NCUniverseSetC(NCUniverse* universe, double c);
void NCUniverseSetSpeed(NCUniverse* universe, double speed);
void NCUniverseSetSize(NCUniverse* universe, double width, double height);
void NCUniverseSetHyleExchange(NCUniverse* universe, unsigned char hyleExchange);
void NCUniversePing(NCUniverse* universe, int n);
void NCUniversePong(NCUniverse* universe);
void NCUniverseTic(NCUniverse* universe);
void NCUniverseCameraChasing(NCUniverse* universe, NCCamera* camera, NCCamera* chasing);

//void NCTest(void);
