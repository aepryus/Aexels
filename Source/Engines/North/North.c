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

// Velocity ========================================================================================
Velocity VelocityAdd(Velocity a, Velocity b) {
    double rx = VelocityX(a) + VelocityX(b);
    double ry = VelocityY(a) + VelocityY(b);
    
    Velocity result;
    result.speed = sqrt(rx*rx + ry*ry);
    result.orient = atan2(ry, rx);
    return result;
}
double VelocityX(Velocity v) {
    return v.speed * cos(v.orient);
}
double VelocityY(Velocity v) {
    return v.speed * -sin(v.orient);
}

// Teslon ==========================================================================================
NCTeslon* NCTeslonCreate(void) {
    NCTeslon* teslon = (NCTeslon*)malloc(sizeof(NCTeslon));
    return teslon;
}
void NCTeslonRelease(NCTeslon* teslon) {
    free(teslon);
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
    camera->v.speed = 0;
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
    teslon->v.speed = speed;
    teslon->v.orient = orient;
    teslon->fixed = fixed;
    teslon->hyle = 1;
    NCUniverseAddTeslon(universe, teslon);
    return teslon;
}
NCPing* NCUniverseCreatePing(NCUniverse* universe, NCTeslon* teslon, double orient) {
    NCPing* ping = NCPingCreate();
    ping->source = teslon;
    ping->pos = teslon->pos;
    ping->v.speed = 1;
    ping->v.orient = orient;
    ping->recycle = 0;
    NCUniverseAddPing(universe, ping);
    return ping;
}
NCPong* NCUniverseCreatePong(NCUniverse* universe, NCTeslon* teslon, double orient) {
    NCPong* pong = NCPongCreate();
    pong->source = teslon;
    pong->pos = teslon->pos;
    pong->v.speed = 1;
    pong->v.orient = orient;
    pong->recycle = 0;
    NCUniverseAddPong(universe, pong);
    return pong;
}
NCPhoton* NCUniverseCreatePhoton(NCUniverse* universe, NCTeslon* teslon, double orient) {
    NCPhoton* photon = NCPhotonCreate();
    photon->source = teslon;
    photon->pos = teslon->pos;
    photon->v.speed = 1;
    photon->v.orient = orient;
    photon->hyle = 1;
    photon->recycle = 0;
    NCUniverseAddPhoton(universe, photon);
    return photon;
}
NCCamera* NCUniverseCreateCamera(NCUniverse* universe, double x, double y, double speed, double orient) {
    NCCamera* camera = NCCameraCreate();
    camera->pos.x = x;
    camera->pos.y = y;
    camera->v.speed = speed;
    camera->v.orient = orient;
    NCUniverseAddCamera(universe, camera);
    return camera;
}

int NCUniverseOutsideOf(NCUniverse* universe, CV2 pos) {
    NCCamera* camera = universe->cameras[0];
    double dx = fabs(pos.x - camera->pos.x);
    double dy = fabs(pos.y - camera->pos.y);
    return dx > universe->width + 100 || dy > universe->height + 100;
}
int NCTeslonInsideOf(NCTeslon* teslon, CV2 pos) {
    double radius = 20;
    if (pos.x < teslon->pos.x - radius) return 0;
    if (pos.x > teslon->pos.x + radius) return 0;
    if (pos.y < teslon->pos.y - radius) return 0;
    if (pos.y > teslon->pos.y + radius) return 0;
    double dx = teslon->pos.x-pos.x;
    double dy = teslon->pos.y-pos.y;
    return dx*dx+dy*dy < radius*radius;
}

void NCUniverseSetSpeed(NCUniverse* universe, double speed) {
    Velocity delta;
    delta.speed = speed - universe->speed;
    delta.orient = 0;
    universe->speed += delta.speed;
    for (int i=0;i<universe->teslonCount;i++) universe->teslons[i]->v = VelocityAdd(universe->teslons[i]->v, delta);
    for (int i=0;i<universe->cameraCount;i++) universe->cameras[i]->v = VelocityAdd(universe->cameras[i]->v, delta);
}

void NCUniversePulse(NCUniverse* universe, int n) {
    int pingI = universe->pingCount;
    universe->pingCount += n * universe->teslonCount;
    if (universe->pingCount > universe->pingCapacity) {
        while (universe->pingCount > universe->pingCapacity) universe->pingCapacity *= 2;
        universe->pings = (NCPing**)realloc(universe->pings, sizeof(NCPing*)*universe->pingCapacity);
    }
    
    for (int i=0;i<universe->teslonCount;i++) {
        NCTeslon* teslon = universe->teslons[i];
        double iQ = teslon->v.orient;
        double dQ = 2*M_PI/n;
        
        for (int j=0;j<n;j++) {
            NCPing* ping = NCPingCreate();
            ping->pos = teslon->pos;
            ping->v.speed = 1;
            ping->v.orient = iQ;
            ping->emOrient = atan2(universe->c*sin(iQ), universe->c*cos(iQ) - teslon->v.speed);
            ping->source = teslon;
            iQ += dQ;
            universe->pings[pingI] = ping;
            pingI++;
        }
    }
}

void NCUniverseTic(NCUniverse* universe) {
    // Basic Translation
    for (int i=0;i<universe->teslonCount;i++) {
        universe->teslons[i]->pos.x += universe->c * VelocityX(universe->teslons[i]->v);
        universe->teslons[i]->pos.y += universe->c * VelocityY(universe->teslons[i]->v);
    }
    for (int i=0;i<universe->pingCount;i++) {
        universe->pings[i]->pos.x += universe->c * VelocityX(universe->pings[i]->v);
        universe->pings[i]->pos.y += universe->c * VelocityY(universe->pings[i]->v);
    }
    for (int i=0;i<universe->pongCount;i++) {
        universe->pongs[i]->pos.x += universe->c * VelocityX(universe->pongs[i]->v);
        universe->pongs[i]->pos.y += universe->c * VelocityY(universe->pongs[i]->v);
    }
    for (int i=0;i<universe->photonCount;i++) {
        universe->photons[i]->pos.x += universe->c * VelocityX(universe->photons[i]->v);
        universe->photons[i]->pos.y += universe->c * VelocityY(universe->photons[i]->v);
    }
    for (int i=0;i<universe->cameraCount;i++) {
        universe->cameras[i]->pos.x += universe->c * VelocityX(universe->cameras[i]->v);
        universe->cameras[i]->pos.y += universe->c * VelocityY(universe->cameras[i]->v);
    }

    for (int i=0;i<universe->teslonCount;i++) {
        NCTeslon* teslon = universe->teslons[i];

        // Teslon Bounce
        if (teslon->pos.x < 0 || teslon->pos.x > universe->width) {
            double orient = teslon->v.orient;
            teslon->v.orient = -orient;
        }
        if (teslon->pos.y < 0 || teslon->pos.y > universe->height) {
            double orient = teslon->v.orient;
            teslon->v.orient = M_PI-orient;
        }
        
        // Ping Collision; Pong Reflection
        for (int j=0;j<universe->pingCount;j++) {
            NCPing* ping = universe->pings[j];
            if (ping->source != teslon && NCTeslonInsideOf(teslon, ping->pos)) {
                NCPong* pong = NCUniverseCreatePong(universe, teslon, 0);
                pong->pos = ping->pos;
                pong->v.orient = M_PI + ping->emOrient + (ping->emOrient - ping->v.orient);
                pong->emOrient = M_PI + ping->emOrient;
                ping->recycle = 1;
            }
        }

        // Pong Collision; Photon Reflection
        for (int j=0;j<universe->pongCount;j++) {
            NCPong* pong = universe->pongs[j];
            if (pong->source != teslon && NCTeslonInsideOf(teslon, pong->pos)) {
                NCPhoton* photon = NCUniverseCreatePhoton(universe, teslon, 0);
                photon->pos = pong->pos;
                photon->v.orient = M_PI + pong->emOrient + (pong->emOrient - pong->v.orient);
                photon->emOrient = M_PI + pong->emOrient;
                pong->recycle = 1;
            }
        }
        
        // Photon Collision; Photon Absorption
        for (int j=0;j<universe->photonCount;j++) {
            NCPhoton* photon = universe->photons[j];
            if (photon->source != teslon && NCTeslonInsideOf(teslon, photon->pos)) {
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
