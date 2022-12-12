//
//  Thracian.c
//  Aexels
//
//  Created by Joe Charlier on 12/3/22.
//  Copyright © 2022 Aepryus Software. All rights reserved.
//

#import <math.h>
#import <stdio.h>
#import <stdlib.h>
#include "Thracian.h"

double TCLambda(double v) { return 1/sqrt(1 - v*v); }

// V2 ==============================================================================================
TCV2 TCV2Add(TCV2 a, TCV2 b) {
    TCV2 result;
    result.x = a.x + b.x;
    result.y = a.y + b.y;
    return result;
}
TCV2 TCV2Sub(TCV2 a, TCV2 b) {
    TCV2 result;
    result.x = a.x - b.x;
    result.y = a.y - b.y;
    return result;
}
TCV2 TCV2Mul(TCV2 a, double b) {
    TCV2 result;
    result.x = a.x*b;
    result.y = a.y*b;
    return result;
}
double TCV2LengthSquared(TCV2 a) {
    return a.x*a.x + a.y*a.y;
}
double TCV2Length(TCV2 a) {
    return sqrt(a.x*a.x + a.y*a.y);
}
double TCV2Dot(TCV2 a,TCV2 b) {
    return a.x*b.x + a.y*b.y;
}
double TCV2Angle(TCV2 a,TCV2 b) {
    return acos(TCV2Dot(a, b)/TCV2Length(a)/TCV2Length(b));
}


// Maxton ==========================================================================================
TCMaxton* TCMaxtonCreate(void) {
    TCMaxton* maxton = (TCMaxton*)malloc(sizeof(TCMaxton));
    maxton->recycle = 0;
    return maxton;
}
void TCMaxtonRelease(TCMaxton* maxton) {
    free(maxton);
}

// Photon ==========================================================================================
TCPhoton* TCPhotonCreate(void) {
    TCPhoton* photon = (TCPhoton*)malloc(sizeof(TCPhoton));
    photon->recycle = 0;
    return photon;
}
void TCPhotonRelease(TCPhoton* photon) {
    free(photon);
}

// Teslon ==========================================================================================
TCTeslon* TCTeslonCreate() {
    TCTeslon* teslon = (TCTeslon*)malloc(sizeof(TCTeslon));
    teslon->v.s = 0;
    return teslon;
}
void TCTeslonRelease(TCTeslon* teslon) {
    free(teslon);
}

// Camera ==========================================================================================
TCCamera* TCCameraCreate() {
    TCCamera* camera = (TCCamera*)malloc(sizeof(TCCamera));
    camera->v.s = 0;
    return camera;
}
void TCCameraRelease(TCCamera* camera) {
    free(camera);
}

// Universe ========================================================================================
TCUniverse* TCUniverseCreate(double width, double height, double c) {
    TCUniverse* universe = (TCUniverse*)malloc(sizeof(TCUniverse));
    
    universe->center.x = width/2;
    universe->center.y = height/2;
    universe->width = width;
    universe->height = height;
    universe->c = c;
    
    double a = (width > height ? width : height)/2*1.5;
    universe->boundrySquared = a*a;
    
    universe->maxtonCount = 0;
    universe->maxtons = (TCMaxton**)malloc(sizeof(TCMaxton*)*0);
    universe->photonCount = 0;
    universe->photons = (TCPhoton**)malloc(sizeof(TCPhoton*)*0);
    universe->teslonCount = 0;
    universe->teslons = (TCTeslon**)malloc(sizeof(TCTeslon*)*0);
    universe->cameraCount = 0;
    universe->cameras = (TCCamera**)malloc(sizeof(TCCamera*)*0);

    return universe;
}
void TCUniverseRelease(TCUniverse* universe) {
    if (universe == 0) return;
    free(universe->maxtons);
    free(universe->photons);
    free(universe->teslons);
    free(universe);
}

void TCUniverseTic(TCUniverse* universe) {
    for (int i=0;i<universe->teslonCount;i++) {
        universe->teslons[i]->p.x += universe->c*universe->teslons[i]->v.s*sin(universe->teslons[i]->v.q);
        universe->teslons[i]->p.y += universe->c*universe->teslons[i]->v.s*(-cos(universe->teslons[i]->v.q));
    }

    for (int i=0;i<universe->maxtonCount;i++) {
        universe->maxtons[i]->p.x += universe->c*sin(universe->maxtons[i]->v.q);
        universe->maxtons[i]->p.y += universe->c*(-cos(universe->maxtons[i]->v.q));
        
        TCTeslon* center = universe->teslons[0];
        if (TCV2LengthSquared(TCV2Sub(center->p, universe->maxtons[i]->p)) > universe->boundrySquared) {
            universe->maxtons[i]->recycle = 1;
        }
        
        if (
            TCV2LengthSquared(TCV2Sub(universe->teslons[1]->p, universe->maxtons[i]->p)) < 49 &&
            TCV2LengthSquared(TCV2Sub(universe->teslons[0]->p, universe->maxtons[i]->p)) > TCV2LengthSquared(TCV2Sub(universe->teslons[0]->p, universe->teslons[1]->p))
        ) {
            universe->maxtons[i]->recycle = 1;
            
            TCTeslon* teslon = universe->teslons[1];
            TCMaxton* maxton = universe->maxtons[i];
            
            TCV2 p;
            p.x = 2*teslon->p.x - maxton->p.x;
            p.y = maxton->p.y;
            TCVelocity v;
            v.s = maxton->v.s;
            v.q = 2*teslon->v.q - maxton->v.q;
            TCUniverseCreatePhoton(universe, p, v, v.q, 0);
        }
        
        if (universe->teslonCount == 3) {
            if (
                TCV2LengthSquared(TCV2Sub(universe->teslons[2]->p, universe->maxtons[i]->p)) < 100 &&
                TCV2LengthSquared(TCV2Sub(universe->teslons[0]->p, universe->maxtons[i]->p)) > TCV2LengthSquared(TCV2Sub(universe->teslons[0]->p, universe->teslons[2]->p))
            ) {
                universe->maxtons[i]->recycle = 1;
                
                TCTeslon* teslon = universe->teslons[2];
                TCMaxton* maxton = universe->maxtons[i];
                
                TCV2 position;
                position.x = maxton->p.x;
                position.y = 2*teslon->p.y - maxton->p.y;
                TCVelocity velocity;
                velocity.s = maxton->v.s;
                
                double c = universe->c;
                double v = universe->teslons[2]->v.s*(universe->teslons[2]->v.q == M_PI/2 ? 1 : -1);
                double x = maxton->p.y - universe->teslons[2]->p.y;
                if (x == 0) {
                    velocity.q = M_PI+maxton->v.q;
                } else {
                    double theta = M_PI/2 - fabs(M_PI/2 - maxton->v.q);
                    double z = x / cos(theta);
                    double t1 = z / c;
                    double y = x * tan(theta);
                    double p = v * t1;
                    double r = y - p;
                    double s = fabs(x)/x;
                    double phi = atan2(
                        (-v*x + c*c*r*r*v*x/(c*c*r*r+c*c*x*x) + c*r*sqrt(-c*c*x*x*(-c*c*r*r-c*c*x*x+v*v*x*x))/(c*c*r*r+c*c*x*x))/(c*x),
                        s*(c*r*v*x + sqrt(c*c*c*c*r*r*x*x+c*c*c*c*x*x*x*x-c*c*v*v*x*x*x*x))/(c*c*r*r+c*c*x*x)
                    );
                    velocity.q = M_PI+phi;
                }
                
                TCUniverseCreatePhoton(universe, position, velocity, velocity.q, 1);
            }
        }
    }
    
    for (int i=0;i<universe->photonCount;i++) {
        universe->photons[i]->p.x += universe->c*sin(universe->photons[i]->v.q);
        universe->photons[i]->p.y += universe->c*(-cos(universe->photons[i]->v.q));
        
        TCTeslon* center = universe->teslons[0];
        if (TCV2LengthSquared(TCV2Sub(center->p, universe->photons[i]->p)) > universe->boundrySquared) {
            universe->photons[i]->recycle = 1;
        }
        
        if (
            TCV2LengthSquared(TCV2Sub(universe->teslons[0]->p, universe->photons[i]->p)) < 100 &&
            (
                (universe->photons[i]->vOrh == 0 && TCV2LengthSquared(TCV2Sub(universe->teslons[1]->p, universe->photons[i]->p)) > TCV2LengthSquared(TCV2Sub(universe->teslons[0]->p, universe->teslons[1]->p))) ||
                (universe->photons[i]->vOrh == 1 && TCV2LengthSquared(TCV2Sub(universe->teslons[2]->p, universe->photons[i]->p)) > TCV2LengthSquared(TCV2Sub(universe->teslons[0]->p, universe->teslons[2]->p)))
            )
        ) {
            universe->photons[i]->recycle = 1;
        }
    }
    
    for (int i=0;i<universe->cameraCount;i++) {
        universe->cameras[i]->p.x += universe->c*universe->cameras[i]->v.s*sin(universe->cameras[i]->v.q);
        universe->cameras[i]->p.y += universe->c*universe->cameras[i]->v.s*(-cos(universe->cameras[i]->v.q));
    }
    
    int k = 0;
    int mC = universe->maxtonCount;
    for (int i=0; i<mC; i++) {
        if (universe->maxtons[i]->recycle) {
            TCMaxtonRelease(universe->maxtons[i]);
            universe->maxtonCount--;
            continue;
        }
        if (k != i) universe->maxtons[k] = universe->maxtons[i];
        k++;
    }
    
    k = 0;
    int pC = universe->photonCount;
    for (int i=0; i<pC; i++) {
        if (universe->photons[i]->recycle) {
            TCPhotonRelease(universe->photons[i]);
            universe->photonCount--;
            continue;
        }
        if (k != i) universe->photons[k] = universe->photons[i];
        k++;
    }

//    printf("maxtons [%d]\tphotons [%d]\n", universe->maxtonCount, universe->photonCount);
}

void TCUniverseAddPhoton(TCUniverse* universe, TCPhoton* photon) {
    universe->photonCount++;
    universe->photons = (TCPhoton**)realloc(universe->photons, sizeof(TCPhoton*)*universe->photonCount);
    universe->photons[universe->photonCount-1] = photon;
}
TCPhoton* TCUniverseCreatePhoton(TCUniverse* universe, TCV2 p, TCVelocity v, double q, char vOrH) {
    TCPhoton* photon = TCPhotonCreate();
    photon->p = p;
    photon->o = p;
    photon->v = v;
    photon->q = q;
    photon->vOrh = vOrH;
    TCUniverseAddPhoton(universe, photon);
    return photon;
}

void TCUniverseAddTeslon(TCUniverse* universe, TCTeslon* teslon) {
    universe->teslonCount++;
    universe->teslons = (TCTeslon**)realloc(universe->teslons, sizeof(TCTeslon*)*universe->teslonCount);
    universe->teslons[universe->teslonCount-1] = teslon;
}
TCTeslon* TCUniverseCreateTeslon(TCUniverse* universe, double x, double y, double s, double q) {
    TCTeslon* teslon = TCTeslonCreate();
    teslon->p.x = x;
    teslon->p.y = y;
    teslon->o = teslon->p;
    teslon->v.s = s;
    teslon->v.q = q;
    TCUniverseAddTeslon(universe, teslon);
    return teslon;
}

void TCUniverseAddCamera(TCUniverse* universe, TCCamera* camera) {
    universe->cameraCount++;
    universe->cameras = (TCCamera**)realloc(universe->cameras, sizeof(TCCamera*)*universe->cameraCount);
    universe->cameras[universe->cameraCount-1] = camera;
}
TCCamera* TCUniverseCreateCamera(TCUniverse* universe, double x, double y, double s, double q) {
    TCCamera* camera = TCCameraCreate();
    camera->p.x = x;
    camera->p.y = y;
    camera->v.s = s;
    camera->v.q = q;
    TCUniverseAddCamera(universe, camera);
    return camera;
}


void TCUniversePulse(TCUniverse* universe, TCTeslon* teslon, int n) {
    universe->maxtonCount += n;
    universe->maxtons = (TCMaxton**)realloc(universe->maxtons, sizeof(TCMaxton*)*universe->maxtonCount);
    
    int i=0;
    int j = universe->maxtonCount-n+i;
    TCMaxton* maxton = TCMaxtonCreate();
    maxton->p.x = teslon->p.x;
    maxton->p.y = teslon->p.y;
    maxton->o = maxton->p;
    maxton->v.s = universe->c;
    maxton->v.q = M_PI/2;
    maxton->q = maxton->v.q;
    universe->maxtons[j] = maxton;
    i++;
    
    j = universe->maxtonCount-n+i;
    maxton = TCMaxtonCreate();
    maxton->p.x = teslon->p.x;
    maxton->p.y = teslon->p.y;
    maxton->o = maxton->p;
    maxton->v.s = universe->c;
    
    double d = TCV2Length(TCV2Sub(universe->teslons[0]->p, universe->teslons[1]->p));
    double v = universe->teslons[0]->v.s;
    double s = universe->teslons[0]->v.q < M_PI ? 1 : -1;
    double c = 1;
    double lambda = TCLambda(v);
    
    maxton->v.q = atan2(s*v*d/c*lambda, d);
    
    maxton->q = maxton->v.q;
    universe->maxtons[j] = maxton;
    i++;
    
    double iQ = maxton->q;
    double dQ = M_PI/2 - iQ;
    int nA = round(dQ/2/M_PI*(n-2));
    
    double dq = dQ/(double)(nA+1);
    double q = iQ+dq;
    for (;i<nA+2;i++) {
        int j = universe->maxtonCount-n+i;
        TCMaxton* maxton = TCMaxtonCreate();
        maxton->p.x = teslon->p.x;
        maxton->p.y = teslon->p.y;
        maxton->o = maxton->p;
        maxton->v.s = universe->c;
        maxton->v.q = q;
        maxton->q = q;
        universe->maxtons[j] = maxton;
        q += dq;
    }
    
    dq = (2*M_PI-dQ)/(double)((n-nA-2)+1);
    q = M_PI/2+dq;
    for (;i<n;i++) {
        int j = universe->maxtonCount-n+i;
        TCMaxton* maxton = TCMaxtonCreate();
        maxton->p.x = teslon->p.x;
        maxton->p.y = teslon->p.y;
        maxton->o = maxton->p;
        maxton->v.s = universe->c;
        maxton->v.q = q;
        maxton->q = q;
        universe->maxtons[j] = maxton;
        q += dq;
    }
}
