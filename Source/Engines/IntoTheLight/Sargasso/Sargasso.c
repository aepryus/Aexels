//
//  Sargasso.c
//  Aexels
//
//  Created by Joe Charlier on 12/12/24.
//  Copyright © 2024 Aepryus Software. All rights reserved.
//

#import <math.h>
#import <stdlib.h>
#import "Sargasso.h"

//#import <stdio.h>

// Teslon ==========================================================================================
SCTeslon* SCTeslonCreate(void) {
    SCTeslon* teslon = (SCTeslon*)malloc(sizeof(SCTeslon));
    return teslon;
}
void SCTeslonRelease(SCTeslon* teslon) {
    free(teslon);
}
double SCTeslonHyle(SCTeslon* teslon) {
    return teslon->hyle * CV2Gamma(teslon->v);
}
CV2 SCTeslonMomentum(SCTeslon* teslon) {
    double hyle = SCTeslonHyle(teslon);
    CV2 momentum = {hyle * teslon->v.x, hyle * teslon->v.y};
    return momentum;
}
//static double HyleOrientX(double hyle, double orient) {
//    return hyle * cos(orient);
//}
//static double HyleOrientY(double hyle, double orient) {
//    return hyle * sin(orient);
//}

void SCTeslonAddMomentum(SCTeslon* teslon, CV2 momentum, unsigned char bounded) {
    double iHyle = teslon->hyle;
    
    double g0 = CV2Gamma(teslon->v);

    CV2 v0 = {teslon->v.x, teslon->v.y};
    CV2 p0 = {teslon->v.x * g0, teslon->v.y * g0};
    
//    CV2 nC;
//    double lC = sqrt(cupola.x*cupola.x + cupola.y*cupola.y);
//    nC.x = cupola.x / lC;
//    nC.y = cupola.y / lC;
    
    CV2 p1 = {p0.x + momentum.x,  p0.y + momentum.y};
    
    double l2p1 = p1.x*p1.x + p1.y*p1.y;
    double den = sqrt(iHyle*iHyle + l2p1);
    CV2 v1 = {p1.x/den, p1.y/den};
    CV2 dv = {v1.x - v0.x, v1.y - v0.y};
    
    double t = 1;
    if (bounded) {
        if (CV2Dot(CV2Neg(v0), dv) <= 0) { return; }
        
        double l2v0 = v0.x*v0.x + v0.y*v0.y;
        double l2v1 = v1.x*v1.x + v1.y*v1.y;

        if (l2v0 < 0.0000001 || l2v1 < 0.0000001) {
            teslon->v.x = 0;
            teslon->v.y = 0;
            return;
        }
        
        if (l2v1 > l2v0) t = 2*(teslon->v.x * v1.x + teslon->v.y*v1.y) / l2v1;
    }
        
    teslon->v.x = v0.x + dv.x * t;
    teslon->v.y = v0.y + dv.y * t;
}

// Ping ============================================================================================
SCPing* SCPingCreate(void) {
    SCPing* ping = (SCPing*)malloc(sizeof(SCPing));
    return ping;
}
void SCPingRelease(SCPing* ping) {
    free(ping);
}

// Pong ============================================================================================
SCPong* SCPongCreate(void) {
    SCPong* pong = (SCPong*)malloc(sizeof(SCPong));
    return pong;
}
void SCPongRelease(SCPong* pong) {
    free(pong);
}

// Photon ==========================================================================================
SCPhoton* SCPhotonCreate(void) {
    SCPhoton* photon = (SCPhoton*)malloc(sizeof(SCPhoton));
    return photon;
}
void SCPhotonRelease(SCPhoton* photon) {
    free(photon);
}

// Camera ==========================================================================================
SCCamera* SCCameraCreate(void) {
    SCCamera* camera = (SCCamera*)malloc(sizeof(SCCamera));
    camera->v.x = 0;
    camera->v.y = 0;
    return camera;
}
void SCCameraRelease(SCCamera* camera) {
    free(camera);
}
void SCCameraSetWalls(SCCamera* camera, unsigned char walls) {
    camera->walls = walls;
}

// Universe ========================================================================================
SCUniverse* SCUniverseCreate(double width, double height) {
    SCUniverse* universe = (SCUniverse*)malloc(sizeof(SCUniverse));
    universe->width = width;
    universe->height = height;
    universe->c = 1;
    universe->speed = 0;
    universe->hyleExchange = 0;
    universe->aberration = 1;
    
    universe->teslonCount = 0;
    universe->teslonCapacity = 2;
    universe->teslons = (SCTeslon**)malloc(sizeof(SCTeslon*)*universe->teslonCapacity);
    
    universe->pingCount = 0;
    universe->pingCapacity = 2;
    universe->pings = (SCPing**)malloc(sizeof(SCPing*)*universe->pingCapacity);
    
    universe->pongCount = 0;
    universe->pongCapacity = 2;
    universe->pongs = (SCPong**)malloc(sizeof(SCPong*)*universe->pongCapacity);
    
    universe->photonCount = 0;
    universe->photonCapacity = 2;
    universe->photons = (SCPhoton**)malloc(sizeof(SCPhoton*)*universe->photonCapacity);
    
    universe->cameraCount = 0;
    universe->cameraCapacity = 2;
    universe->cameras = (SCCamera**)malloc(sizeof(SCCamera*)*universe->cameraCapacity);

    return universe;
}
void SCUniverseRelease(SCUniverse* universe) {
    for (int i=0;i<universe->teslonCount;i++) SCTeslonRelease(universe->teslons[i]);
    free(universe->teslons);
    for (int i=0;i<universe->pingCount;i++) SCPingRelease(universe->pings[i]);
    free(universe->pings);
    for (int i=0;i<universe->pongCount;i++) SCPongRelease(universe->pongs[i]);
    free(universe->pongs);
    for (int i=0;i<universe->photonCount;i++) SCPhotonRelease(universe->photons[i]);
    free(universe->photons);
    for (int i=0;i<universe->cameraCount;i++) SCCameraRelease(universe->cameras[i]);
    free(universe->cameras);
    free(universe);
}

void SCUniverseAddTeslon(SCUniverse* universe, SCTeslon* teslon) {
    universe->teslonCount++;
    if (universe->teslonCount > universe->teslonCapacity) {
        universe->teslonCapacity *= 2;
        universe->teslons = (SCTeslon**)realloc(universe->teslons, sizeof(SCTeslon*)*universe->teslonCapacity);
    }
    universe->teslons[universe->teslonCount-1] = teslon;
}
void SCUniverseAddPing(SCUniverse* universe, SCPing* ping) {
    universe->pingCount++;
    if (universe->pingCount > universe->pingCapacity) {
        universe->pingCapacity *= 2;
        universe->pings = (SCPing**)realloc(universe->pings, sizeof(SCPing*)*universe->pingCapacity);
    }
    universe->pings[universe->pingCount-1] = ping;
}
void SCUniverseAddPong(SCUniverse* universe, SCPong* pong) {
    universe->pongCount++;
    if (universe->pongCount > universe->pongCapacity) {
        universe->pongCapacity *= 2;
        universe->pongs = (SCPong**)realloc(universe->pongs, sizeof(SCPong*)*universe->pongCapacity);
    }
    universe->pongs[universe->pongCount-1] = pong;
}
void SCUniverseAddPhoton(SCUniverse* universe, SCPhoton* photon) {
    universe->photonCount++;
    if (universe->photonCount > universe->photonCapacity) {
        universe->photonCapacity *= 2;
        universe->photons = (SCPhoton**)realloc(universe->photons, sizeof(SCPhoton*)*universe->photonCapacity);
    }
    universe->photons[universe->photonCount-1] = photon;
}
void SCUniverseSetCamera(SCUniverse* universe, int i) {
    universe->camera = universe->cameras[i];
}
void SCUniverseAddCamera(SCUniverse* universe, SCCamera* camera) {
    universe->cameraCount++;
    if (universe->cameraCount > universe->cameraCapacity) {
        universe->cameraCapacity *= 2;
        universe->cameras = (SCCamera**)realloc(universe->cameras, sizeof(SCCamera*)*universe->cameraCapacity);
    }
    universe->cameras[universe->cameraCount-1] = camera;
    if (universe->cameraCount == 1) SCUniverseSetCamera(universe, 0);
}

SCTeslon* SCUniverseCreateTeslon(SCUniverse* universe, double x, double y, double speed, double orient, double hyle, unsigned char pings, unsigned char contracts) {
    SCTeslon* teslon = SCTeslonCreate();
    teslon->pos.x = x;
    teslon->pos.y = y;
    teslon->v.x = speed * cos(orient);
    teslon->v.y = speed * sin(orient);
    teslon->hyle = hyle;
    teslon->pings = pings;
    teslon->contracts = contracts;
    SCUniverseAddTeslon(universe, teslon);
    return teslon;
}
SCPing* SCUniverseCreatePing(SCUniverse* universe, SCTeslon* teslon) {
    SCPing* ping = SCPingCreate();
    ping->source = teslon;
    ping->pos = teslon->pos;
    ping->v.x = 0;
    ping->v.y = 0;
    ping->recycle = 0;
    SCUniverseAddPing(universe, ping);
    return ping;
}
SCPong* SCUniverseCreatePong(SCUniverse* universe, SCTeslon* teslon) {
    SCPong* pong = SCPongCreate();
    pong->source = teslon;
    pong->pos = teslon->pos;
    pong->v.x = 0;
    pong->v.y = 0;
    pong->recycle = 0;
    SCUniverseAddPong(universe, pong);
    return pong;
}
SCPong* SCUniverseCreatePongWithPos(SCUniverse* universe, CV2 pos) {
    SCPong* pong = SCPongCreate();
    pong->source = 0;
    pong->pos = pos;
    pong->v.x = 0;
    pong->v.y = 0;
    pong->recycle = 0;
    SCUniverseAddPong(universe, pong);
    return pong;
}
SCPhoton* SCUniverseCreatePhoton(SCUniverse* universe, SCTeslon* teslon) {
    SCPhoton* photon = SCPhotonCreate();
    photon->source = teslon;
    photon->pos = teslon->pos;
    photon->v.x = 0;
    photon->v.y = 0;
    photon->hyle = 1;
    photon->recycle = 0;
    SCUniverseAddPhoton(universe, photon);
    return photon;
}
SCCamera* SCUniverseCreateCamera(SCUniverse* universe, double x, double y, double speed, double orient) {
    SCCamera* camera = SCCameraCreate();
    camera->pos.x = x;
    camera->pos.y = y;
    camera->v.x = speed * cos(orient);
    camera->v.y = speed * sin(orient);
    camera->walls = 0;
    SCUniverseAddCamera(universe, camera);
    return camera;
}

int SCUniverseOutsideOf(SCUniverse* universe, CV2 pos) {
    SCCamera* camera = universe->cameras[0];
    double dx = fabs(pos.x - camera->pos.x);
    double dy = fabs(pos.y - camera->pos.y);
    return dx > universe->width + 100 || dy > universe->height + 100;
}
int SCTeslonInsideOf(SCTeslon* teslon, CV2 pos, double radius) {
    if (pos.x < teslon->pos.x - radius) return 0;
    if (pos.x > teslon->pos.x + radius) return 0;
    if (pos.y < teslon->pos.y - radius) return 0;
    if (pos.y > teslon->pos.y + radius) return 0;
    double dx = teslon->pos.x-pos.x;
    double dy = teslon->pos.y-pos.y;
    return dx*dx+dy*dy < radius*radius;
}

void SCUniverseSetC(SCUniverse* universe, double c) {
    universe->c = c;
}
void SCUniverseSetSpeed(SCUniverse* universe, double speed) {
    double fromGamma = 1/sqrt(1 - universe->speed*universe->speed);
    double toGamma = 1/sqrt(1 - speed*speed);
    double cx = universe->cameras[0]->pos.x;
    
    for (int i=0;i<universe->teslonCount;i++) {
        SCTeslon* teslon = universe->teslons[i];
        teslon->pos.x = cx + (teslon->pos.x - cx) * fromGamma / toGamma;
        universe->teslons[i]->v.x = speed + (universe->teslons[i]->v.x - universe->speed) * (fromGamma*fromGamma)/(toGamma*toGamma);
        universe->teslons[i]->v.y = universe->teslons[i]->v.y * fromGamma/toGamma;
    }
    
    universe->speed = speed;
    universe->camera->v.x = speed;
}
void SCUniverseSetSize(SCUniverse* universe, double width, double height) {
    universe->width = width;
    universe->height = height;
    for (int i=0;i<universe->cameraCount;i++) {
        universe->cameras[i]->width = width;
        universe->cameras[i]->height = height;
    }
}
void SCUniverseSetHyleExchange(SCUniverse* universe, unsigned char hyleExchange) {
    universe->hyleExchange = hyleExchange;
}
void SCUniverseSetAberration(SCUniverse* universe, unsigned char aberration) {
    universe->aberration = aberration;
}

void SCUniversePing(SCUniverse* universe, int n) {
    int pingI = universe->pingCount;

    int pingingTeslons = 0;
    for (int i=0;i<universe->teslonCount;i++) {
        SCTeslon* teslon = universe->teslons[i];
        if (teslon->pings) pingingTeslons++;
    }

    universe->pingCount += n * pingingTeslons;
    if (universe->pingCount > universe->pingCapacity) {
        while (universe->pingCount > universe->pingCapacity) universe->pingCapacity *= 2;
        universe->pings = (SCPing**)realloc(universe->pings, sizeof(SCPing*)*universe->pingCapacity);
    }

    for (int i=0;i<universe->teslonCount;i++) {
        SCTeslon* teslon = universe->teslons[i];
        if (!teslon->pings) continue;

        double tVx = teslon->v.x;
        double tVy = teslon->v.y;
        double speed = sqrt(tVx*tVx + tVy*tVy);

        // Source-velocity unit vector (defaults to +x for a stationary teslon).
        double vDirX = 1.0;
        double vDirY = 0.0;
        double beta = 0.0;
        if (speed > 1e-8) {
            vDirX = tVx / speed;
            vDirY = tVy / speed;
            beta = speed;
        }

        // Rule 3 emission density in the medium frame:
        //
        //     ρ(θ,β) = (1−β²) / (1−β cos θ)²    per dθ
        //
        // This is the relativistic-Doppler (3D-style) angular density —
        // the analytical target the LW disc shader is plotted against,
        // and what the cupola algorithm must reproduce when aberration
        // is on.  We sample θ from this density via inverse CDF on a
        // numerical grid.  (Sampling uniform-θ' in the source rest frame
        // and applying the aberration map cosθ=(cosθ'+β)/(1+β cosθ')
        // produces a different density — √(1−β²)/(1−β cosθ) — which is
        // 2D-correct relativistic aberration but not Rule 3.)
        // Aberration off ⇒ uniform medium-frame angles (isotropic).
        #define nGrid 8192
        double cdf[nGrid + 1];
        int useRule3 = (universe->aberration && beta > 1e-8);
        if (useRule3) {
            double dq = 2*M_PI/nGrid;
            cdf[0] = 0;
            double omb2 = 1 - beta*beta;
            for (int g=0;g<nGrid;g++) {
                double q = (g + 0.5)*dq;
                double k = 1 - beta*cos(q);
                double rho = omb2 / (k*k);
                cdf[g+1] = cdf[g] + rho*dq;
            }
            double total = cdf[nGrid];
            for (int g=0;g<=nGrid;g++) cdf[g] /= total;
        }

        for (int j=0;j<n;j++) {
            double thetaLab;
            if (useRule3) {
                // Inverse-CDF sample: uniform u → θ such that the density
                // of θ over the n samples matches Rule 3.
                double u = (j + 0.5) / (double)n;
                int lo = 0, hi = nGrid;
                while (hi - lo > 1) {
                    int mid = (lo + hi) / 2;
                    if (cdf[mid] < u) lo = mid; else hi = mid;
                }
                double denom = cdf[hi] - cdf[lo];
                if (denom < 1e-12) denom = 1e-12;
                thetaLab = ((double)lo + (u - cdf[lo]) / denom) * (2*M_PI/nGrid);
            } else {
                thetaLab = j * (2*M_PI/n);
            }
            #undef nGrid
            double cosT = cos(thetaLab);
            double sinT = sin(thetaLab);

            // Rotate (cosT, sinT) into the medium frame, aligning the
            // sampled angle's "forward" with the source's velocity direction.
            double iQx = cosT * vDirX - sinT * vDirY;
            double iQy = cosT * vDirY + sinT * vDirX;

            SCPing* ping = SCPingCreate();
            ping->pos = teslon->pos;
            ping->v.x = iQx;
            ping->v.y = iQy;
            ping->cupola.x = iQx - tVx;
            ping->cupola.y = iQy - tVy;
            ping->source = teslon;

            universe->pings[pingI] = ping;
            pingI++;
        }
    }
}
// Uniform-θ_lab emission — same as SCUniversePing with aberration off,
// regardless of the universe's aberration toggle.  Used for the lab's
// visual auto-fire stream so the on-screen ping cloud stays roughly
// even-density at high β; the actual sensor population is done by a
// single Rule-3 pulse via SCUniversePing.  Pings still get the same
// cupola = ping.v − teslon.v so they sample the sensor correctly.
void SCUniversePingUniform(SCUniverse* universe, int n) {
    int pingI = universe->pingCount;

    int pingingTeslons = 0;
    for (int i=0;i<universe->teslonCount;i++) {
        SCTeslon* teslon = universe->teslons[i];
        if (teslon->pings) pingingTeslons++;
    }

    universe->pingCount += n * pingingTeslons;
    if (universe->pingCount > universe->pingCapacity) {
        while (universe->pingCount > universe->pingCapacity) universe->pingCapacity *= 2;
        universe->pings = (SCPing**)realloc(universe->pings, sizeof(SCPing*)*universe->pingCapacity);
    }

    for (int i=0;i<universe->teslonCount;i++) {
        SCTeslon* teslon = universe->teslons[i];
        if (!teslon->pings) continue;

        double tVx = teslon->v.x;
        double tVy = teslon->v.y;
        double speed = sqrt(tVx*tVx + tVy*tVy);

        double vDirX = 1.0;
        double vDirY = 0.0;
        if (speed > 1e-8) {
            vDirX = tVx / speed;
            vDirY = tVy / speed;
        }

        double dQ = 2*M_PI/n;
        for (int j=0;j<n;j++) {
            double thetaLab = j * dQ;
            double cosT = cos(thetaLab);
            double sinT = sin(thetaLab);

            double iQx = cosT * vDirX - sinT * vDirY;
            double iQy = cosT * vDirY + sinT * vDirX;

            SCPing* ping = SCPingCreate();
            ping->pos = teslon->pos;
            ping->v.x = iQx;
            ping->v.y = iQy;
            ping->cupola.x = iQx - tVx;
            ping->cupola.y = iQy - tVy;
            ping->source = teslon;

            universe->pings[pingI] = ping;
            pingI++;
        }
    }
}

void SCUniversePong(SCUniverse* universe) {
    for (int j=0;j<universe->pingCount;j++) {
        SCPing* ping = universe->pings[j];
        SCPong* pong = SCUniverseCreatePongWithPos(universe, ping->pos);
        pong->pos = ping->pos;
        double dot = ping->v.x * ping->cupola.x + ping->v.y * ping->cupola.y;  // A·B
        double dot2 = ping->cupola.x * ping->cupola.x + ping->cupola.y * ping->cupola.y;  // B·B
        double scale = 2.0f * dot / dot2;
        pong->v.x = ping->v.x - scale * ping->cupola.x;
        pong->v.y = ping->v.y - scale * ping->cupola.y;
        
        pong->cupola.x = 0;
        pong->cupola.y = 0;
        ping->recycle = 1;
    }
}

void SCUniverseTic(SCUniverse* universe) {
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
        SCTeslon* teslon = universe->teslons[i];

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
            SCPing* ping = universe->pings[j];
            if (ping->source != teslon && !ping->recycle && SCTeslonInsideOf(teslon, ping->pos, collisionRadius)) {
                SCPong* pong = SCUniverseCreatePong(universe, teslon);
                pong->pos = ping->pos;

                double dot = ping->v.x * ping->cupola.x + ping->v.y * ping->cupola.y;  // A·B
                double dot2 = ping->cupola.x * ping->cupola.x + ping->cupola.y * ping->cupola.y;  // B·B
                double scale = 2.0f * dot / dot2;
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
            SCPong* pong = universe->pongs[j];
            if (pong->source != teslon && !pong->recycle && SCTeslonInsideOf(teslon, pong->pos, collisionRadius)) {
                
                double h0 = SCTeslonHyle(teslon);
                CV2 p0 = SCTeslonMomentum(teslon);
                
                double lc = CV2Length(pong->cupola);
                CV2 momentum = {pong->cupola.x/lc*0.0005 , pong->cupola.y/lc*0.0005};
                
                if (universe->hyleExchange) { SCTeslonAddMomentum(teslon, momentum, 1); }
                double h1 = SCTeslonHyle(teslon);
                CV2 p1 = SCTeslonMomentum(teslon);
                double dh = h0 - h1;
                CV2 dp = {p0.x-p1.x, p0.y-p1.y};
                
                if (h1 < h0) {
                    SCPhoton* photon = SCUniverseCreatePhoton(universe, teslon);
                    photon->pos = pong->pos;
                    
                    double dot = pong->v.x * pong->cupola.x + pong->v.y * pong->cupola.y;  // A·B
                    double dot2 = pong->cupola.x * pong->cupola.x + pong->cupola.y * pong->cupola.y;  // B·B
                    double scale = 2.0f * dot / dot2;
                    photon->v.x = pong->v.x - scale * pong->cupola.x;
                    photon->v.y = pong->v.y - scale * pong->cupola.y;
                    
                    double iQx = photon->v.x;
                    double iQy = photon->v.y;

                    double tVx = teslon->v.x;
                    double tVy = teslon->v.y;

                    photon->cupola.x = iQx - tVx;
                    photon->cupola.y = iQy - tVy;
                    
                    photon->momentum.x = dp.x;
                    photon->momentum.y = dp.y;
                    
                    photon->hyle = dh;

                }
                pong->recycle = 1;
            }
        }
        
        // Photon Collision; Photon Absorption
        for (int j=0;j<universe->photonCount;j++) {
            SCPhoton* photon = universe->photons[j];
            if (photon->source != teslon && !photon->recycle && SCTeslonInsideOf(teslon, photon->pos, collisionRadius)) {
                
                double h0 = SCTeslonHyle(teslon);
                CV2 p0 = SCTeslonMomentum(teslon);
                
                double lc = CV2Length(photon->cupola);
                CV2 momentum = {photon->cupola.x/lc*0.0005 , photon->cupola.y/lc*0.0005};
                
                if (universe->hyleExchange) { SCTeslonAddMomentum(teslon, momentum, 1); }
                double h1 = SCTeslonHyle(teslon);
                CV2 p1 = SCTeslonMomentum(teslon);
                double dh = h0 - h1;
                CV2 dp = {p0.x-p1.x, p0.y-p1.y};

                
//                double beforeHyle = SCTeslonHyle(teslon) + photon->hyle;
//                if (universe->hyleExchange) { SCTeslonAddMomentum(teslon, photon->hyle, photon->momentum, 0); }
//                double afterHyle = SCTeslonHyle(teslon);

                if (h1 < h0) {
                    SCPhoton* bounce = SCUniverseCreatePhoton(universe, teslon);
                    bounce->pos = photon->pos;
                    
                    double dot = photon->v.x * photon->cupola.x + photon->v.y * photon->cupola.y;  // A·B
                    double dot2 = photon->cupola.x * photon->cupola.x + photon->cupola.y * photon->cupola.y;  // B·B
                    double scale = 2.0f * dot / dot2;
                    bounce->v.x = photon->v.x - scale * photon->cupola.x;
                    bounce->v.y = photon->v.y - scale * photon->cupola.y;
                    
                    double iQx = bounce->v.x;
                    double iQy = bounce->v.y;

                    double tVx = teslon->v.x;
                    double tVy = teslon->v.y;

                    bounce->cupola.x = iQx - tVx;
                    bounce->cupola.y = iQy - tVy;
                    
                    photon->momentum.x = dp.x;
                    photon->momentum.y = dp.y;

                    bounce->hyle = dh;
                }

                photon->recycle = 1;
            }
        }
    }
    
    // Clear Recycled Edisons
    int k = 0;
    int pC = universe->pingCount;
    for (int i=0; i<pC; i++) {
        SCPing* ping = universe->pings[i];
        if (ping->recycle || SCUniverseOutsideOf(universe, ping->pos)) {
            SCPingRelease(ping);
            universe->pingCount--;
        } else {
            if (k != i) universe->pings[k] = universe->pings[i];
            k++;
        }
    }
    k = 0;
    pC = universe->pongCount;
    for (int i=0; i<pC; i++) {
        SCPong* pong = universe->pongs[i];
        if (pong->recycle || SCUniverseOutsideOf(universe, pong->pos)) {
            SCPongRelease(pong);
            universe->pongCount--;
        } else {
            if (k != i) universe->pongs[k] = universe->pongs[i];
            k++;
        }
    }
    k = 0;
    pC = universe->photonCount;
    for (int i=0; i<pC; i++) {
        SCPhoton* photon = universe->photons[i];
        if (photon->recycle || SCUniverseOutsideOf(universe, photon->pos)) {
            SCPhotonRelease(photon);
            universe->photonCount--;
        } else {
            if (k != i) universe->photons[k] = universe->photons[i];
            k++;
        }
    }
}
void SCUniverseCameraChasing(SCUniverse* universe, SCCamera* camera, SCCamera* chasing) {
    if (chasing->pos.x - camera->pos.x > universe->width/2) {
        camera->pos.x += universe->width;
    } else if (camera->pos.x - chasing->pos.x > universe->width/2) {
        camera->pos.x -= universe->width;
    }
}

//void SCTest(void) {
//    SCTeslon* teslon = SCTeslonCreate();
//    
//    teslon->v.x = -0.02;
//    teslon->v.y = 0;
//    teslon->hyle = 1;
//    
//    double hyle = 0.0005;
//
//    CV2 cupola;
//    cupola.x = 1;
//    cupola.y = 0;
//        
//    double h0 = SCTeslonHyle(teslon);
//    double g0 = CV2Gamma(teslon->v);
//    CV2 p0 = SCTeslonMomentum(teslon);
//    CV2 v0 = teslon->v;
//    double ke0 = 1.0/2*h0*CV2Dot(v0, v0);
//    SCTeslonAddMomentum(teslon, hyle, cupola, 1);
//    double h1 = SCTeslonHyle(teslon);
//    double g1 = CV2Gamma(teslon->v);
//    CV2 p1 = SCTeslonMomentum(teslon);
//    CV2 v1 = teslon->v;
//    double ke1 = 1.0/2*h1*CV2Dot(v1, v1);
//
//    printf("=================================\n");
//    printf("hyle: %lf\n", hyle);
//    printf("h0: %lf\n", h0);
//    printf("h1: %lf\n", h1);
//    printf("dh: %lf\n", h1-h0);
//    printf("--------------------\n");
//    printf("g0: %lf\n", g0);
//    printf("g1: %lf\n", g1);
//    printf("dg: %lf\n", g1-g0);
//    printf("--------------------\n");
//    printf("ke0: %lf\n", ke0);
//    printf("ke1: %lf\n", ke1);
//    printf("dke: %lf\n", ke1-ke0);
//    printf("--------------------\n");
//    printf("p0: (%lf, %lf)\n", p0.x, p0.y);
//    printf("p1: (%lf, %lf)\n", p1.x, p1.y);
//    printf("dp: (%lf, %lf)\n", p1.x-p0.x, p1.y-p0.y);
//    printf("--------------------\n");
//    printf("v0: (%lf, %lf)\n", v0.x, v0.y);
//    printf("v1: (%lf, %lf)\n", v1.x, v1.y);
//    printf("dv: (%lf, %lf)\n", v1.x-v0.x, v1.y-v0.y);
//
//    SCTeslonRelease(teslon);
//}
