//
//  Thracian.h
//  Aexels
//
//  Created by Joe Charlier on 12/3/22.
//  Copyright © 2022 Aepryus Software. All rights reserved.
//

// TC = Thracian Sea

double TCGamma(double v);

typedef struct TCV2 {
    double x;
    double y;
} TCV2;

TCV2 TCV2Add(TCV2 a, TCV2 b);
TCV2 TCV2Sub(TCV2 a, TCV2 b);
TCV2 TCV2Mul(TCV2 a, double b);
double TCV2LengthSquared(TCV2 a);
double TCV2Length(TCV2 a);
double TCV2Dot(TCV2 a, TCV2 b);
double TCV2Angle(TCV2 a, TCV2 b);

typedef struct TCVelocity {
    double s;               // speed
    double q;               // theta
} TCVelocity;

typedef struct TCMaxton {
    TCV2 o;                 // old - last position
    TCV2 e;                 // end - of tail (fixed length not just old position)
    TCV2 p;                 // position
    TCVelocity v;           // velocity
    double q;               // theta?
    unsigned char recycle;
} TCMaxton;

TCMaxton* TCMaxtonCreate(void);
void TCMaxtonRelease(TCMaxton* maxton);

typedef struct TCPhoton {
    TCV2 o;
    TCV2 p;
    TCVelocity v;
    double q;
    double e;
    char vOrh;
    unsigned char recycle;
} TCPhoton;

TCPhoton* TCPhotonCreate(void);
void TCPhotonRelease(TCPhoton* photon);

typedef struct TCTeslon {
    TCV2 o;
    TCV2 p;
    TCVelocity v;
} TCTeslon;

TCTeslon* TCTeslonCreate(void);
void TCTeslonRelease(TCTeslon* teslon);

typedef struct TCCamera {
    TCV2 p;
    TCVelocity v;
} TCCamera;

TCCamera* TCCameraCreate(void);
void TCCameraRelease(TCCamera* camera);

typedef struct TCUniverse {
    TCV2 center;
    double width;
    double height;
//    double v;
    double c;
    double boundrySquared;
    int maxtonCount;
    TCMaxton** maxtons;
    int photonCount;
    TCPhoton** photons;
    int teslonCount;
    TCTeslon** teslons;
    int cameraCount;
    TCCamera** cameras;
} TCUniverse;

TCUniverse* TCUniverseCreate(double width, double height, double c);
void TCUniverseRelease(TCUniverse* universe);
void TCUniverseTic(TCUniverse* universe);
TCPhoton* TCUniverseCreatePhoton(TCUniverse* universe, TCV2 p, TCVelocity v, double q, char vOrH);
TCTeslon* TCUniverseCreateTeslon(TCUniverse* universe, double x, double y, double s, double q);
TCCamera* TCUniverseCreateCamera(TCUniverse* universe, double x, double y, double s, double q);
void TCUniversePulse(TCUniverse* universe, TCTeslon* teslon, int n);
