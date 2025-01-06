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

CV2 CV2Add(CV2 a, CV2 b);
CV2 CV2Sub(CV2 a, CV2 b);
CV2 CV2Mul(CV2 a, double b);
double CV2LengthSquared(CV2 a);
double CV2Length(CV2 a);
double CV2Dot(CV2 a, CV2 b);
double CV2Angle(CV2 a, CV2 b);

typedef struct Velocity {
    double speed;
    double orient;
} Velocity;

Velocity VelocityAdd(Velocity a, Velocity b);
double VelocityX(Velocity v);
double VelocityY(Velocity v);
double VelocityGamma(Velocity v);

typedef struct Momentum {
    double hyle;
    double speed;
    double orient;
} Momentum;

double MomentumX(Momentum* momentum);
double MomentumY(Momentum* momentum);

typedef struct NCTeslon {
    CV2 pos;
    Velocity v;
    double iHyle;                  // innate hyle
    unsigned char fixed;
} NCTeslon;

NCTeslon* NCTeslonCreate(void);
void NCTeslonRelease(NCTeslon* teslon);
double NCTeslonHyle(NCTeslon* teslon);
void NCTeslonAddMomentum(NCTeslon* teslon, double hyle, double orient);

typedef struct NCPing {
    CV2 pos;
    Velocity v;
    double cupola;
    unsigned char recycle;
    NCTeslon* source;
} NCPing;

NCPing* NCPingCreate(void);
void NCPingRelease(NCPing* ping);

typedef struct NCPong {
    CV2 pos;
    Velocity v;
    double cupola;
    unsigned char recycle;
    NCTeslon* source;
} NCPong;

NCPong* NCPongCreate(void);
void NCPongRelease(NCPong* pong);

typedef struct NCPhoton {
    CV2 pos;
    Velocity v;
    double cupola;
    double hyle;
    unsigned char recycle;
    NCTeslon* source;
} NCPhoton;

NCPhoton* NCPhotonCreate(void);
void NCPhotonRelease(NCPhoton* photon);

typedef struct NCCamera {
    CV2 pos;
    Velocity v;
    double width;
    double height;
} NCCamera;

NCCamera* NCCameraCreate(void);
void NCCameraRelease(NCCamera* camera);

typedef struct NCUniverse {
    double width;
    double height;
    double speed;
    double c;
    double boundrySquared;
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
} NCUniverse;

NCUniverse* NCUniverseCreate(double width, double height);
void NCUniverseRelease(NCUniverse* universe);
void NCUniverseAddTeslon(NCUniverse* universe, NCTeslon* teslon);
void NCUniverseAddPing(NCUniverse* universe, NCPing* ping);
void NCUniverseAddPong(NCUniverse* universe, NCPong* pong);
void NCUniverseAddPhoton(NCUniverse* universe, NCPhoton* photon);
NCTeslon* NCUniverseCreateTeslon(NCUniverse* universe, double x, double y, double speed, double orient, unsigned char fixed);
NCPing* NCUniverseCreatePing(NCUniverse* universe, NCTeslon* teslon, double orient);
NCPong* NCUniverseCreatePong(NCUniverse* universe, NCTeslon* teslon, double orient);
NCPhoton* NCUniverseCreatePhoton(NCUniverse* universe, NCTeslon* teslon);
NCCamera* NCUniverseCreateCamera(NCUniverse* universe, double x, double y, double speed, double orient);
int NCUniverseOutsideOf(NCUniverse* universe, CV2 pos);
int NCTeslonInsideOf(NCTeslon* teslon, CV2 pos, double radius);
void NCUniverseSetSpeed(NCUniverse* universe, double speed);
void NCUniversePing(NCUniverse* universe, int n);
void NCUniversePong(NCUniverse* universe);
void NCUniverseTic(NCUniverse* universe);
