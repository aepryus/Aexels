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

// V2 ==============================================================================================
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
TCUniverse* TCUniverseCreate(double width, double height, double c, double v) {
    TCUniverse* universe = (TCUniverse*)malloc(sizeof(TCUniverse));
    
    universe->center.x = width/2;
    universe->center.y = height/2;
    universe->width = width;
    universe->height = height;
    universe->v = v;
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
        
        if (TCV2LengthSquared(TCV2Sub(universe->teslons[1]->p, universe->maxtons[i]->p)) < 100) {
            universe->maxtons[i]->recycle = 1;
            
            TCTeslon* teslon = universe->teslons[1];
            TCMaxton* maxton = universe->maxtons[i];
            
            TCV2 p;
            p.x = 2*teslon->p.x - maxton->p.x;
            p.y = maxton->p.y;
            TCVelocity v;
            v.s = maxton->v.s;
            v.q = 2*teslon->v.q - maxton->v.q;
            TCUniverseCreatePhoton(universe, p, v, v.q);
        }
    }
    
    for (int i=0;i<universe->photonCount;i++) {
        universe->photons[i]->p.x += universe->c*sin(universe->photons[i]->v.q);
        universe->photons[i]->p.y += universe->c*(-cos(universe->photons[i]->v.q));
        
        TCTeslon* center = universe->teslons[0];
        if (TCV2LengthSquared(TCV2Sub(center->p, universe->photons[i]->p)) > universe->boundrySquared) {
            universe->photons[i]->recycle = 1;
        }
        
        if (TCV2LengthSquared(TCV2Sub(universe->teslons[0]->p, universe->photons[i]->p)) < 100) {
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
TCPhoton* TCUniverseCreatePhoton(TCUniverse* universe, TCV2 p, TCVelocity v, double q) {
    TCPhoton* photon = TCPhotonCreate();
    photon->p = p;
    photon->v = v;
    photon->q = q;
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
    double dq = 2*M_PI/(double)n;
    double q = 0;
    for (int i=0;i<n;i++) {
        int j = universe->maxtonCount-n+i;
        TCMaxton* maxton = TCMaxtonCreate();
        maxton->p.x = teslon->p.x;
        maxton->p.y = teslon->p.y;
        maxton->v.s = universe->c;
        maxton->v.q = q;
        maxton->q = q;
        universe->maxtons[j] = maxton;
        q += dq;
    }
}
