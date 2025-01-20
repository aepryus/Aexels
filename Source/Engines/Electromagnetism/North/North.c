//
//  North.c
//  Aexels
//
//  Created by Joe Charlier on 12/12/24.
//  Copyright © 2024 Aepryus Software. All rights reserved.
//

#import <math.h>
#import <stdlib.h>
#import "North.h"

#import <stdio.h>

// CV2 =============================================================================================
double CV2Orient(CV2 a) {
    return atan2(a.y, a.x);
}
double CV2Gamma(CV2 a) {
    return 1/sqrt(1 - (a.x*a.x+a.y*a.y));
}

// Momentum ========================================================================================
double MomentumX(Momentum* momentum) {
    return momentum->hyle * momentum->speed * cos(momentum->orient);
}
double MomentumY(Momentum* momentum) {
    return momentum->hyle * momentum->speed * -sin(momentum->orient);
}

// Teslon ==========================================================================================
NCTeslon* NCTeslonCreate(void) {
    NCTeslon* teslon = (NCTeslon*)malloc(sizeof(NCTeslon));
    return teslon;
}
void NCTeslonRelease(NCTeslon* teslon) {
    free(teslon);
}
double NCTeslonHyle(NCTeslon* teslon) {
    return teslon->iHyle * CV2Gamma(teslon->v);
}
double HyleOrientX(double hyle, double orient) {
    return hyle * cos(orient);
}
double HyleOrientY(double hyle, double orient) {
    return hyle * sin(orient);
}
void NCTeslonAddMomentum(NCTeslon* teslon, double hyle, double x, double y) {
//    double iHyle = teslon->iHyle;
//    double tHyle = iHyle * CV2Gamma(teslon->v);
//    double pX = tHyle*teslon->v.x + hyle*x;
//    double pY = tHyle*teslon->v.y + hyle*y;
//    double mag = sqrt(x*x+y*y);
//    teslon->v.speed = mag/sqrt(iHyle*iHyle+mag*mag);
//    teslon->v.orient = atan2(y, x);
}

// Ping ============================================================================================
NCPing* NCPingCreate(void) {
    NCPing* ping = (NCPing*)malloc(sizeof(NCPing));
    return ping;
}
void NCPingRelease(NCPing* ping) {
    free(ping);
}

// Pong ============================================================================================
NCPong* NCPongCreate(void) {
    NCPong* pong = (NCPong*)malloc(sizeof(NCPong));
    return pong;
}
void NCPongRelease(NCPong* pong) {
    free(pong);
}

// Photon ==========================================================================================
NCPhoton* NCPhotonCreate(void) {
    NCPhoton* photon = (NCPhoton*)malloc(sizeof(NCPhoton));
    return photon;
}
void NCPhotonRelease(NCPhoton* photon) {
    free(photon);
}

// Camera ==========================================================================================
NCCamera* NCCameraCreate(void) {
    NCCamera* camera = (NCCamera*)malloc(sizeof(NCCamera));
    camera->v.x = 0;
    camera->v.y = 0;
    return camera;
}
void NCCameraRelease(NCCamera* camera) {
    free(camera);
}

// Universe ========================================================================================
NCUniverse* NCUniverseCreate(double width, double height) {
    NCUniverse* universe = (NCUniverse*)malloc(sizeof(NCUniverse));
    universe->width = width;
    universe->height = height;
    universe->c = 1;
    universe->speed = 0;
    
    universe->teslonCount = 0;
    universe->teslonCapacity = 2;
    universe->teslons = (NCTeslon**)malloc(sizeof(NCTeslon*)*universe->teslonCapacity);
    
    universe->pingCount = 0;
    universe->pingCapacity = 2;
    universe->pings = (NCPing**)malloc(sizeof(NCPing*)*universe->pingCapacity);
    
    universe->pongCount = 0;
    universe->pongCapacity = 2;
    universe->pongs = (NCPong**)malloc(sizeof(NCPong*)*universe->pongCapacity);
    
    universe->photonCount = 0;
    universe->photonCapacity = 2;
    universe->photons = (NCPhoton**)malloc(sizeof(NCPhoton*)*universe->photonCapacity);
    
    universe->cameraCount = 0;
    universe->cameraCapacity = 2;
    universe->cameras = (NCCamera**)malloc(sizeof(NCCamera*)*universe->cameraCapacity);

    return universe;
}
void NCUniverseRelease(NCUniverse* universe) {
    for (int i=0;i<universe->teslonCount;i++) NCTeslonRelease(universe->teslons[i]);
    free(universe->teslons);
    for (int i=0;i<universe->pingCount;i++) NCPingRelease(universe->pings[i]);
    free(universe->pings);
    for (int i=0;i<universe->pongCount;i++) NCPongRelease(universe->pongs[i]);
    free(universe->pongs);
    for (int i=0;i<universe->photonCount;i++) NCPhotonRelease(universe->photons[i]);
    free(universe->photons);
    for (int i=0;i<universe->cameraCount;i++) NCCameraRelease(universe->cameras[i]);
    free(universe->cameras);
    free(universe);
}

void NCUniverseAddTeslon(NCUniverse* universe, NCTeslon* teslon) {
    universe->teslonCount++;
    if (universe->teslonCount > universe->teslonCapacity) {
        universe->teslonCapacity *= 2;
        universe->teslons = (NCTeslon**)realloc(universe->teslons, sizeof(NCTeslon*)*universe->teslonCapacity);
    }
    universe->teslons[universe->teslonCount-1] = teslon;
}
void NCUniverseAddPing(NCUniverse* universe, NCPing* ping) {
    universe->pingCount++;
    if (universe->pingCount > universe->pingCapacity) {
        universe->pingCapacity *= 2;
        universe->pings = (NCPing**)realloc(universe->pings, sizeof(NCPing*)*universe->pingCapacity);
    }
    universe->pings[universe->pingCount-1] = ping;
}
void NCUniverseAddPong(NCUniverse* universe, NCPong* pong) {
    universe->pongCount++;
    if (universe->pongCount > universe->pongCapacity) {
        universe->pongCapacity *= 2;
        universe->pongs = (NCPong**)realloc(universe->pongs, sizeof(NCPong*)*universe->pongCapacity);
    }
    universe->pongs[universe->pongCount-1] = pong;
}
void NCUniverseAddPhoton(NCUniverse* universe, NCPhoton* photon) {
    universe->photonCount++;
    if (universe->photonCount > universe->photonCapacity) {
        universe->photonCapacity *= 2;
        universe->photons = (NCPhoton**)realloc(universe->photons, sizeof(NCPhoton*)*universe->photonCapacity);
    }
    universe->photons[universe->photonCount-1] = photon;
}
void NCUniverseAddCamera(NCUniverse* universe, NCCamera* camera) {
    universe->cameraCount++;
    if (universe->cameraCount > universe->cameraCapacity) {
        universe->cameraCapacity *= 2;
        universe->cameras = (NCCamera**)realloc(universe->cameras, sizeof(NCCamera*)*universe->cameraCapacity);
    }
    universe->cameras[universe->cameraCount-1] = camera;
}

NCTeslon* NCUniverseCreateTeslon(NCUniverse* universe, double x, double y, double speed, double orient, unsigned char fixed) {
    NCTeslon* teslon = NCTeslonCreate();
    teslon->pos.x = x;
    teslon->pos.y = y;
    teslon->v.x = speed * cos(orient);
    teslon->v.y = speed * sin(orient);
    teslon->fixed = fixed;
    teslon->iHyle = 1;
    NCUniverseAddTeslon(universe, teslon);
    return teslon;
}
NCPing* NCUniverseCreatePing(NCUniverse* universe, NCTeslon* teslon) {
    NCPing* ping = NCPingCreate();
    ping->source = teslon;
    ping->pos = teslon->pos;
    ping->v.x = 0;
    ping->v.y = 0;
    ping->recycle = 0;
    NCUniverseAddPing(universe, ping);
    return ping;
}
NCPong* NCUniverseCreatePong(NCUniverse* universe, NCTeslon* teslon) {
    NCPong* pong = NCPongCreate();
    pong->source = teslon;
    pong->pos = teslon->pos;
    pong->v.x = 0;
    pong->v.y = 0;
    pong->recycle = 0;
    NCUniverseAddPong(universe, pong);
    return pong;
}
NCPong* NCUniverseCreatePongWithPos(NCUniverse* universe, CV2 pos) {
    NCPong* pong = NCPongCreate();
    pong->source = 0;
    pong->pos = pos;
    pong->v.x = 0;
    pong->v.y = 0;
    pong->recycle = 0;
    NCUniverseAddPong(universe, pong);
    return pong;
}
NCPhoton* NCUniverseCreatePhoton(NCUniverse* universe, NCTeslon* teslon) {
    NCPhoton* photon = NCPhotonCreate();
    photon->source = teslon;
    photon->pos = teslon->pos;
    photon->v.x = 0;
    photon->v.y = 0;
    photon->hyle = 1;
    photon->recycle = 0;
    NCUniverseAddPhoton(universe, photon);
    return photon;
}
NCCamera* NCUniverseCreateCamera(NCUniverse* universe, double x, double y, double speed, double orient) {
    NCCamera* camera = NCCameraCreate();
    camera->pos.x = x;
    camera->pos.y = y;
    camera->v.x = speed * cos(orient);
    camera->v.y = orient * sin(orient);
    NCUniverseAddCamera(universe, camera);
    return camera;
}

int NCUniverseOutsideOf(NCUniverse* universe, CV2 pos) {
    NCCamera* camera = universe->cameras[0];
    double dx = fabs(pos.x - camera->pos.x);
    double dy = fabs(pos.y - camera->pos.y);
    return dx > universe->width + 100 || dy > universe->height + 100;
}
int NCTeslonInsideOf(NCTeslon* teslon, CV2 pos, double radius) {
    if (pos.x < teslon->pos.x - radius) return 0;
    if (pos.x > teslon->pos.x + radius) return 0;
    if (pos.y < teslon->pos.y - radius) return 0;
    if (pos.y > teslon->pos.y + radius) return 0;
    double dx = teslon->pos.x-pos.x;
    double dy = teslon->pos.y-pos.y;
    return dx*dx+dy*dy < radius*radius;
}

void NCUniverseSetSpeed(NCUniverse* universe, double speed) {
    double delta = speed - universe->speed;
    universe->speed += delta;
    for (int i=0;i<universe->teslonCount;i++) universe->teslons[i]->v.x += delta;
    for (int i=0;i<universe->cameraCount;i++) universe->cameras[i]->v.x += delta;
}

void NCUniversePing(NCUniverse* universe, int n) {
    int pingI = universe->pingCount;
    universe->pingCount += n * universe->teslonCount;
    if (universe->pingCount > universe->pingCapacity) {
        while (universe->pingCount > universe->pingCapacity) universe->pingCapacity *= 2;
        universe->pings = (NCPing**)realloc(universe->pings, sizeof(NCPing*)*universe->pingCapacity);
    }
    
    for (int i=0;i<universe->teslonCount;i++) {
        NCTeslon* teslon = universe->teslons[i];
        double iQ = CV2Orient(teslon->v);
        double dQ = 2*M_PI/n;
        
        for (int j=0;j<n;j++) {
            NCPing* ping = NCPingCreate();
            ping->pos = teslon->pos;
            
            double iQx = cos(iQ);
            double iQy = sin(iQ);
            
            ping->v.x = iQx;
            ping->v.y = iQy;

            
            double tVx = teslon->v.x;
            double tVy = teslon->v.y;
            
            ping->cupola.x = iQx - tVx;
            ping->cupola.y = iQy - tVy;
            
            ping->source = teslon;
            iQ += dQ;
            universe->pings[pingI] = ping;
            pingI++;
        }
    }
}
void NCUniversePong(NCUniverse* universe) {
    for (int j=0;j<universe->pingCount;j++) {
        NCPing* ping = universe->pings[j];
        NCPong* pong = NCUniverseCreatePongWithPos(universe, ping->pos);
        pong->pos = ping->pos;
        pong->v.x = -(2 * ping->cupola.x - ping->v.x);
        pong->v.y = -(2 * ping->cupola.y - ping->v.y);
        pong->cupola.x = -ping->cupola.x;
        pong->cupola.y = -ping->cupola.y;
        ping->recycle = 1;
    }
}

void NCUniverseTic(NCUniverse* universe) {
    // Basic Translation
    for (int i=0;i<universe->teslonCount;i++) {
        universe->teslons[i]->pos.x += universe->teslons[i]->v.x;
        universe->teslons[i]->pos.y += universe->teslons[i]->v.y;
    }
    for (int i=0;i<universe->pingCount;i++) {
        universe->pings[i]->pos.x += universe->pings[i]->v.x;
        universe->pings[i]->pos.y += universe->pings[i]->v.y;
    }
    for (int i=0;i<universe->pongCount;i++) {
        universe->pongs[i]->pos.x += universe->pongs[i]->v.x;
        universe->pongs[i]->pos.y += universe->pongs[i]->v.y;
    }
    for (int i=0;i<universe->photonCount;i++) {
        universe->photons[i]->pos.x += universe->photons[i]->v.x;
        universe->photons[i]->pos.y += universe->photons[i]->v.y;
    }
    for (int i=0;i<universe->cameraCount;i++) {
        universe->cameras[i]->pos.x += universe->cameras[i]->v.x;
        universe->cameras[i]->pos.y += universe->cameras[i]->v.y;
    }

    for (int i=0;i<universe->teslonCount;i++) {
        NCTeslon* teslon = universe->teslons[i];

        // Teslon Bounce
        if (teslon->pos.x < 0 || teslon->pos.x > universe->width) {
            teslon->v.x = -teslon->v.x;
        }
        if (teslon->pos.y < 0 || teslon->pos.y > universe->height) {
            teslon->v.y = -teslon->v.y;
        }
        
        // Ping Collision; Pong Reflection
        for (int j = 0; j < universe->pingCount; j++) {
            NCPing* ping = universe->pings[j];
            if (ping->source != teslon && !ping->recycle && NCTeslonInsideOf(teslon, ping->pos, 20)) {
                NCPong* pong = NCUniverseCreatePong(universe, teslon);
                pong->pos = ping->pos;

                float dot = ping->v.x * ping->cupola.x + ping->v.y * ping->cupola.y;  // A·B
                float dot2 = ping->cupola.x * ping->cupola.x + ping->cupola.y * ping->cupola.y;  // B·B
                float scale = 2.0f * dot / dot2;
                pong->v.x = ping->v.x - scale * ping->cupola.x;
                pong->v.y = ping->v.y - scale * ping->cupola.y;
                
                double iQx = pong->v.x;
                double iQy = pong->v.y;

                double tVx = teslon->v.x;
                double tVy = teslon->v.y;

                pong->cupola.x = iQx - tVx;
                pong->cupola.y = iQy - tVy;

                ping->recycle = 1;
            }
        }

        // Pong Collision; Photon Reflection
        for (int j = 0; j < universe->pongCount; j++) {
            NCPong* pong = universe->pongs[j];
            if (pong->source != teslon && !pong->recycle && NCTeslonInsideOf(teslon, pong->pos, 20)) {

                double beforeHyle = NCTeslonHyle(teslon);
                // NCTeslonAddMomentum(teslon, 0.1, pong->cupola);
                double afterHyle = NCTeslonHyle(teslon);

                NCPhoton* photon = NCUniverseCreatePhoton(universe, teslon);
                photon->pos = pong->pos;

                float dot = pong->v.x * pong->cupola.x + pong->v.y * pong->cupola.y;  // A·B
                float dot2 = pong->cupola.x * pong->cupola.x + pong->cupola.y * pong->cupola.y;  // B·B
                float scale = 2.0f * dot / dot2;
                photon->v.x = pong->v.x - scale * pong->cupola.x;
                photon->v.y = pong->v.y - scale * pong->cupola.y;

                double iQx = photon->v.x;
                double iQy = photon->v.y;

                double tVx = teslon->v.x;
                double tVy = teslon->v.y;

                photon->cupola.x = iQx - tVx;
                photon->cupola.y = iQy - tVy;

                photon->hyle = beforeHyle - afterHyle;

                pong->recycle = 1;
            }
        }
        
        // Photon Collision; Photon Absorption
        for (int j=0;j<universe->photonCount;j++) {
            NCPhoton* photon = universe->photons[j];
            if (photon->source != teslon && !photon->recycle && NCTeslonInsideOf(teslon, photon->pos, 20)) {
                photon->recycle = 1;
            }
        }
    }
    
    // Clear Recycled Edisons
    int k = 0;
    int pC = universe->pingCount;
    for (int i=0; i<pC; i++) {
        NCPing* ping = universe->pings[i];
        if (ping->recycle || NCUniverseOutsideOf(universe, ping->pos)) {
            NCPingRelease(ping);
            universe->pingCount--;
        } else {
            if (k != i) universe->pings[k] = universe->pings[i];
            k++;
        }
    }
    k = 0;
    pC = universe->pongCount;
    for (int i=0; i<pC; i++) {
        NCPong* pong = universe->pongs[i];
        if (pong->recycle || NCUniverseOutsideOf(universe, pong->pos)) {
            NCPongRelease(pong);
            universe->pongCount--;
        } else {
            if (k != i) universe->pongs[k] = universe->pongs[i];
            k++;
        }
    }
    k = 0;
    pC = universe->photonCount;
    for (int i=0; i<pC; i++) {
        NCPhoton* photon = universe->photons[i];
        if (photon->recycle || NCUniverseOutsideOf(universe, photon->pos)) {
            NCPhotonRelease(photon);
            universe->photonCount--;
        } else {
            if (k != i) universe->photons[k] = universe->photons[i];
            k++;
        }
    }
}
