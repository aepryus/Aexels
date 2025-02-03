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
double CV2Length(CV2 a) {
    return sqrt(a.x*a.x+a.y*a.y);
}
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
    return teslon->hyle * CV2Gamma(teslon->v);
}
double HyleOrientX(double hyle, double orient) {
    return hyle * cos(orient);
}
double HyleOrientY(double hyle, double orient) {
    return hyle * sin(orient);
}
//void NCTeslonAddMomentum(NCTeslon* teslon, double hyle, CV2 cupola, unsigned char bounded) {
//    double iHyle = teslon->hyle;
//    double tHyle = iHyle * CV2Gamma(teslon->v);
//
//    CV2 v0;
//    
//    v0.x = teslon->v.x;
//    v0.y = teslon->v.y;
//    
//    CV2 nC;
//    double lC = sqrt(cupola.x*cupola.x + cupola.y*cupola.y);
//    nC.x = cupola.x / fabs(lC);
//    nC.y = cupola.y / fabs(lC);
//    
//    CV2 v1;
//    v1.x = v0.x + nC.x * hyle / tHyle;
//    v1.y = v0.y + nC.y * hyle / tHyle;
//    
//    double l2v0 = v0.x*v0.x + v0.y*v0.y;
//    double l2v1 = v1.x*v1.x + v1.y*v1.y;
//    
//    double t = 1;
//    if (bounded) {
//        if (l2v0 < 0.0000001 || l2v1 < 0.0000001) {
//            teslon->v.x = 0;
//            teslon->v.y = 0;
//            return;
//        }
//        if (l2v0 > l2v1) t = 2*(teslon->v.x * v1.x + teslon->v.y*v1.y) / l2v1;
//    }
//    
//    teslon->v.x = v1.x * t;
//    teslon->v.y = v1.y * t;
//}


void NCTeslonAddMomentum(NCTeslon* teslon, double hyle, CV2 cupola, unsigned char bounded) {
    double iHyle = teslon->hyle;
    double tHyle = iHyle * CV2Gamma(teslon->v);

    CV2 v0;
    
    v0.x = teslon->v.x;
    v0.y = teslon->v.y;
    
    CV2 nC;
    double lC = sqrt(cupola.x*cupola.x + cupola.y*cupola.y);
    nC.x = cupola.x / fabs(lC);
    nC.y = cupola.y / fabs(lC);
    
    CV2 v1;
    v1.x = v0.x + nC.x * hyle / tHyle;
    v1.y = v0.y + nC.y * hyle / tHyle;
    
    CV2 dv;
    dv.x = v1.x - v0.x;
    dv.y = v1.y - v0.y;
    
    double l2v0 = v0.x*v0.x + v0.y*v0.y;
    double l2v1 = v1.x*v1.x + v1.y*v1.y;
    
    double t = 1;
    if (bounded) {
        if (l2v0 < 0.0000001 || l2v1 < 0.0000001) {
            teslon->v.x = 0;
            teslon->v.y = 0;
            return;
        }
        
        if (l2v1 > l2v0) t = 2*(teslon->v.x * v1.x + teslon->v.y*v1.y) / l2v1;
    }
    
    
    double oldSpeed = CV2Length(teslon->v);
    teslon->v.x = v0.x + dv.x * t;
    teslon->v.y = v0.y + dv.y * t;
    double newSpeed = CV2Length(teslon->v);
    
    if (fabs(oldSpeed - newSpeed) > 0.1) {
        printf("wtf\n");
    }
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
void NCCameraSetWalls(NCCamera* camera, unsigned char walls) {
    camera->walls = walls;
}

// Universe ========================================================================================
NCUniverse* NCUniverseCreate(double width, double height) {
    NCUniverse* universe = (NCUniverse*)malloc(sizeof(NCUniverse));
    universe->width = width;
    universe->height = height;
    universe->c = 1;
    universe->speed = 0;
    universe->hyleExchange = 0;
    
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
void NCUniverseSetCamera(NCUniverse* universe, int i) {
    universe->camera = universe->cameras[i];
}
void NCUniverseAddCamera(NCUniverse* universe, NCCamera* camera) {
    universe->cameraCount++;
    if (universe->cameraCount > universe->cameraCapacity) {
        universe->cameraCapacity *= 2;
        universe->cameras = (NCCamera**)realloc(universe->cameras, sizeof(NCCamera*)*universe->cameraCapacity);
    }
    universe->cameras[universe->cameraCount-1] = camera;
    if (universe->cameraCount == 1) NCUniverseSetCamera(universe, 0);
}

NCTeslon* NCUniverseCreateTeslon(NCUniverse* universe, double x, double y, double speed, double orient, double hyle, unsigned char pings, unsigned char contracts) {
    NCTeslon* teslon = NCTeslonCreate();
    teslon->pos.x = x;
    teslon->pos.y = y;
    teslon->v.x = speed * cos(orient);
    teslon->v.y = speed * sin(orient);
    teslon->hyle = hyle;
    teslon->pings = pings;
    teslon->contracts = contracts;
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
    camera->v.y = speed * sin(orient);
    camera->walls = 0;
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

void NCUniverseSetC(NCUniverse* universe, double c) {
    universe->c = c;
}
void NCUniverseSetSpeed(NCUniverse* universe, double speed) {
    double fromGamma = 1/sqrt(1 - universe->speed*universe->speed);
    double toGamma = 1/sqrt(1 - speed*speed);
    double cx = universe->cameras[0]->pos.x;
    
    for (int i=0;i<universe->teslonCount;i++) {
        NCTeslon* teslon = universe->teslons[i];
        teslon->pos.x = cx + (teslon->pos.x - cx) * fromGamma / toGamma;
        universe->teslons[i]->v.x = speed + (universe->teslons[i]->v.x - universe->speed) * (fromGamma*fromGamma)/(toGamma*toGamma);
        universe->teslons[i]->v.y = universe->teslons[i]->v.y * fromGamma/toGamma;
    }
    
    universe->speed = speed;
    universe->camera->v.x = speed;
}
void NCUniverseSetSize(NCUniverse* universe, double width, double height) {
    universe->width = width;
    universe->height = height;
    for (int i=0;i<universe->cameraCount;i++) {
        universe->cameras[i]->width = width;
        universe->cameras[i]->height = height;
    }
}
void NCUniverseSetHyleExchange(NCUniverse* universe, unsigned char hyleExchange) {
    universe->hyleExchange = hyleExchange;
}

void NCUniversePing(NCUniverse* universe, int n) {
    int pingI = universe->pingCount;
    
    int pingingTeslons = 0;
    for (int i=0;i<universe->teslonCount;i++) {
        NCTeslon* teslon = universe->teslons[i];
        if (teslon->pings) pingingTeslons++;
    }
    
    universe->pingCount += n * pingingTeslons;
    if (universe->pingCount > universe->pingCapacity) {
        while (universe->pingCount > universe->pingCapacity) universe->pingCapacity *= 2;
        universe->pings = (NCPing**)realloc(universe->pings, sizeof(NCPing*)*universe->pingCapacity);
    }
    
    for (int i=0;i<universe->teslonCount;i++) {
        NCTeslon* teslon = universe->teslons[i];
        if (!teslon->pings) continue;
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
        float dot = ping->v.x * ping->cupola.x + ping->v.y * ping->cupola.y;  // A·B
        float dot2 = ping->cupola.x * ping->cupola.x + ping->cupola.y * ping->cupola.y;  // B·B
        float scale = 2.0f * dot / dot2;
        pong->v.x = ping->v.x - scale * ping->cupola.x;
        pong->v.y = ping->v.y - scale * ping->cupola.y;
        
        pong->cupola.x = 0;
        pong->cupola.y = 0;
        ping->recycle = 1;
    }
}

void NCUniverseTic(NCUniverse* universe) {
    // Basic Translation
    for (int i=0;i<universe->cameraCount;i++) {
        universe->cameras[i]->pos.x += universe->cameras[i]->v.x * universe->c;
        universe->cameras[i]->pos.y += universe->cameras[i]->v.y * universe->c;
    }
    for (int i=0;i<universe->teslonCount;i++) {
        universe->teslons[i]->pos.x += universe->teslons[i]->v.x * universe->c;
        universe->teslons[i]->pos.y += universe->teslons[i]->v.y * universe->c;
    }
    for (int i=0;i<universe->pingCount;i++) {
        universe->pings[i]->pos.x += universe->pings[i]->v.x * universe->c;
        universe->pings[i]->pos.y += universe->pings[i]->v.y * universe->c;
    }
    for (int i=0;i<universe->pongCount;i++) {
        universe->pongs[i]->pos.x += universe->pongs[i]->v.x * universe->c;
        universe->pongs[i]->pos.y += universe->pongs[i]->v.y * universe->c;
    }
    for (int i=0;i<universe->photonCount;i++) {
        universe->photons[i]->pos.x += universe->photons[i]->v.x * universe->c;
        universe->photons[i]->pos.y += universe->photons[i]->v.y * universe->c;
    }
    
    for (int i=0;i<universe->teslonCount;i++) {
        NCTeslon* teslon = universe->teslons[i];

        // Teslon Bounce
        if (universe->camera->walls) {
            if (teslon->pos.x < universe->camera->pos.x - universe->width/2 || teslon->pos.x > universe->camera->pos.x + universe->width/2) {
                teslon->v.x = 2*universe->camera->v.x - teslon->v.x;
            }
            if (teslon->pos.y < universe->camera->pos.y - universe->height/2 || teslon->pos.y > universe->camera->pos.y + universe->height/2) {
                teslon->v.y = 2*universe->camera->v.y - teslon->v.y;
            }
        }
        
        double collisionRadius = 20;
        
        // Ping Collision; Pong Reflection
        for (int j = 0; j < universe->pingCount; j++) {
            NCPing* ping = universe->pings[j];
            if (ping->source != teslon && !ping->recycle && NCTeslonInsideOf(teslon, ping->pos, collisionRadius)) {
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
            if (pong->source != teslon && !pong->recycle && NCTeslonInsideOf(teslon, pong->pos, collisionRadius)) {

                double beforeHyle = NCTeslonHyle(teslon);
                if (universe->hyleExchange) { NCTeslonAddMomentum(teslon, 0.0005, pong->cupola, 1); }
                double afterHyle = NCTeslonHyle(teslon);
                
                if (afterHyle < beforeHyle) {
                    NCPhoton* photon = NCUniverseCreatePhoton(universe, teslon);
                    photon->pos = pong->pos;
                    
                    float dot = pong->v.x * pong->cupola.x + pong->v.y * pong->cupola.y;  // A·B
                    float dot2 = pong->cupola.x * pong->cupola.x + pong->cupola.y * pong->cupola.y;  // B·B
                    float scale = 2.0f * dot / dot2;
                    photon->v.x = pong->v.x - scale * pong->cupola.x;
                    photon->v.y = pong->v.y - scale * pong->cupola.y;
                    
                    photon->cupola.x = -pong->cupola.x;
                    photon->cupola.y = -pong->cupola.y;
                    
                    photon->hyle = beforeHyle - afterHyle;
                    
                    pong->recycle = 1;
                }
            }
        }
        
        // Photon Collision; Photon Absorption
        for (int j=0;j<universe->photonCount;j++) {
            NCPhoton* photon = universe->photons[j];
            if (photon->source != teslon && !photon->recycle && NCTeslonInsideOf(teslon, photon->pos, collisionRadius)) {

                double beforeHyle = NCTeslonHyle(teslon) + photon->hyle;
                if (universe->hyleExchange) { NCTeslonAddMomentum(teslon, photon->hyle, photon->cupola, 0); }
                double afterHyle = NCTeslonHyle(teslon);
                
                if (afterHyle > beforeHyle + photon->hyle) {
                    printf("wtf\n");
                }
                
                if (afterHyle < beforeHyle) {
                    NCPhoton* bounce = NCUniverseCreatePhoton(universe, teslon);
                    bounce->pos = photon->pos;
                    
                    float dot = photon->v.x * photon->cupola.x + photon->v.y * photon->cupola.y;  // A·B
                    float dot2 = photon->cupola.x * photon->cupola.x + photon->cupola.y * photon->cupola.y;  // B·B
                    float scale = 2.0f * dot / dot2;
                    bounce->v.x = photon->v.x - scale * photon->cupola.x;
                    bounce->v.y = photon->v.y - scale * photon->cupola.y;
                    
                    bounce->cupola.x = -photon->cupola.x;
                    bounce->cupola.y = -photon->cupola.y;
                    
                    bounce->hyle = beforeHyle - afterHyle;
                    
                    photon->recycle = 1;
                }

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
void NCUniverseCameraChasing(NCUniverse* universe, NCCamera* camera, NCCamera* chasing) {
    if (chasing->pos.x - camera->pos.x > universe->width/2) {
        camera->pos.x += universe->width;
    } else if (camera->pos.x - chasing->pos.x > universe->width/2) {
        camera->pos.x -= universe->width;
    }
}
