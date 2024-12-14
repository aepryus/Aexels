//
//  North.h
//  Aexels
//
//  Created by Joe Charlier on 12/12/24.
//  Copyright © 2024 Aepryus Software. All rights reserved.
//

// NC = North Sea

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

typedef struct NCTeslon {
    CV2 pos;
    Velocity v;
} NCTeslon;

NCTeslon* NCTeslonCreate(void);
void NCTeslonRelease(NCTeslon* teslon);

typedef struct NCPing {
    CV2 pos;
    Velocity v;
    double emOrient;
} NCPing;

NCPing* NCPingCreate(void);
void NCPingRelease(NCPing* ping);

typedef struct NCPong {
    CV2 pos;
    Velocity v;
    double emOrient;
} NCPong;

NCPong* NCPongCreate(void);
void NCPongRelease(NCPong* pong);

typedef struct NCPhoton {
    CV2 pos;
    Velocity v;
    double emOrient;
} NCPhoton;

NCPhoton* NCPhotonCreate(void);
void NCPhotonRelease(NCPhoton* photon);

typedef struct NCUniverse {
    double width;
    double height;
    double boundrySquared;
    int teslonCount;
    NCTeslon** teslons;
    int pingCount;
    NCPing** pings;
    int pongCount;
    NCPong** pongs;
    int photonCount;
    NCPhoton** photons;
} NCUniverse;

NCUniverse* NCUniverseCreate(void);
void NCUniverseRelease(NCUniverse* universe);
void NCUniverseAddTeslon(NCUniverse* universe, NCTeslon* teslon);
void NCUniverseAddPing(NCUniverse* universe, NCPing* ping);
void NCUniverseAddPong(NCUniverse* universe, NCPong* pong);
void NCUniverseAddPhoton(NCUniverse* universe, NCPhoton* photon);
NCTeslon* NCUniverseCreateTeslon(NCUniverse* universe, double x, double y, double s, double q);
NCPing* NCUniverseCreatePing(NCUniverse* universe, double x, double y, double s, double q);
NCPong* NCUniverseCreatePong(NCUniverse* universe, double x, double y, double s, double q);
NCPhoton* NCUniverseCreatePhoton(NCUniverse* universe, double x, double y, double s, double q);
void NCUniverseTic(NCUniverse* universe);
void NCUniversePulse(NCUniverse* universe, int n);
