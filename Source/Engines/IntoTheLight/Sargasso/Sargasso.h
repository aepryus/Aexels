//
//  Sargasso.h
//  Aexels
//
//  Created by Joe Charlier on 12/12/24.
//  Copyright © 2024 Aepryus Software. All rights reserved.
//

// SC = Sargasso Sea : Into the Light

#import "Sea.h"

typedef struct SCTeslon {
    CV2 pos;
    CV2 v;
    double hyle;                  // innate hyle
    unsigned char pings;
    unsigned char contracts;
} SCTeslon;

SCTeslon* SCTeslonCreate(void);
void SCTeslonRelease(SCTeslon* teslon);
double SCTeslonHyle(SCTeslon* teslon);
CV2 SCTeslonMomentum(SCTeslon* teslon);
void SCTeslonAddMomentum(SCTeslon* teslon, CV2 momentum, unsigned char bounded);

typedef struct SCPing {
    CV2 pos;
    CV2 v;
    CV2 cupola;
    unsigned char recycle;
    SCTeslon* source;
//    CV2 origin;
} SCPing;

SCPing* SCPingCreate(void);
void SCPingRelease(SCPing* ping);

typedef struct SCPong {
    CV2 pos;
    CV2 v;
    CV2 cupola;
    unsigned char recycle;
    SCTeslon* source;
} SCPong;

SCPong* SCPongCreate(void);
void SCPongRelease(SCPong* pong);

typedef struct SCPhoton {
    CV2 pos;
    CV2 v;
    CV2 cupola;
    CV2 momentum;
    double hyle;
    unsigned char recycle;
    SCTeslon* source;
} SCPhoton;

SCPhoton* SCPhotonCreate(void);
void SCPhotonRelease(SCPhoton* photon);

typedef struct SCCamera {
    CV2 pos;
    CV2 v;
    double width;
    double height;
    unsigned char walls;
} SCCamera;

SCCamera* SCCameraCreate(void);
void SCCameraRelease(SCCamera* camera);
void SCCameraSetWalls(SCCamera* camera, unsigned char walls);

typedef struct SCUniverse {
    double width;
    double height;
    double speed;
    double c;
    double boundrySquared;
    unsigned char hyleExchange;
    unsigned char aberration;
    int teslonCount;
    int teslonCapacity;
    SCTeslon** teslons;
    int pingCount;
    int pingCapacity;
    SCPing** pings;
    int pongCount;
    int pongCapacity;
    SCPong** pongs;
    int photonCount;
    int photonCapacity;
    SCPhoton** photons;
    int cameraCount;
    int cameraCapacity;
    SCCamera** cameras;
    SCCamera* camera;
} SCUniverse;

SCUniverse* SCUniverseCreate(double width, double height);
void SCUniverseRelease(SCUniverse* universe);
void SCUniverseAddTeslon(SCUniverse* universe, SCTeslon* teslon);
void SCUniverseAddPing(SCUniverse* universe, SCPing* ping);
void SCUniverseAddPong(SCUniverse* universe, SCPong* pong);
void SCUniverseAddPhoton(SCUniverse* universe, SCPhoton* photon);
SCTeslon* SCUniverseCreateTeslon(SCUniverse* universe, double x, double y, double speed, double orient, double hyle, unsigned char pings, unsigned char contracts);
SCPing* SCUniverseCreatePing(SCUniverse* universe, SCTeslon* teslon);
SCPong* SCUniverseCreatePong(SCUniverse* universe, SCTeslon* teslon);
SCPhoton* SCUniverseCreatePhoton(SCUniverse* universe, SCTeslon* teslon);
SCCamera* SCUniverseCreateCamera(SCUniverse* universe, double x, double y, double speed, double orient);
int SCUniverseOutsideOf(SCUniverse* universe, CV2 pos);
int SCTeslonInsideOf(SCTeslon* teslon, CV2 pos, double radius);
void SCUniverseSetC(SCUniverse* universe, double c);
void SCUniverseSetSpeed(SCUniverse* universe, double speed);
void SCUniverseSetSize(SCUniverse* universe, double width, double height);
void SCUniverseSetHyleExchange(SCUniverse* universe, unsigned char hyleExchange);
void SCUniverseSetAberration(SCUniverse* universe, unsigned char aberration);
void SCUniversePing(SCUniverse* universe, int n);
void SCUniversePingUniform(SCUniverse* universe, int n);
void SCUniversePong(SCUniverse* universe);
void SCUniverseTic(SCUniverse* universe);
void SCUniverseCameraChasing(SCUniverse* universe, SCCamera* camera, SCCamera* chasing);

//void SCTest(void);
