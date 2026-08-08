//
//  Philippine.c
//  Aexels
//
//  Created by Joe Charlier on 8/8/26.
//  Copyright © 2026 Aepryus Software. All rights reserved.
//

#import <math.h>
#import <stdlib.h>
#import "Philippine.h"

#define PC_PHI 0.6180339887498949
#define PC_CULL_MARGIN 60.0

// Universe ========================================================================================
PCUniverse* PCUniverseCreate(double width, double height) {
    PCUniverse* universe = (PCUniverse*)malloc(sizeof(PCUniverse));
    universe->width = width;
    universe->height = height;
    universe->c = 2;
    universe->rho0 = 36;
    universe->tic = 0;

    universe->nodeCount = 0;
    universe->nodeCapacity = 2;
    universe->nodes = (PCNode**)malloc(sizeof(PCNode*)*universe->nodeCapacity);

    universe->pingCount = 0;
    universe->pingCapacity = 512;
    universe->pings = (PCPing**)malloc(sizeof(PCPing*)*universe->pingCapacity);

    universe->pongCount = 0;
    universe->pongCapacity = 512;
    universe->pongs = (PCPong**)malloc(sizeof(PCPong*)*universe->pongCapacity);

    return universe;
}
void PCUniverseRelease(PCUniverse* universe) {
    for (int i=0;i<universe->nodeCount;i++) free(universe->nodes[i]);
    free(universe->nodes);
    for (int i=0;i<universe->pingCount;i++) free(universe->pings[i]);
    free(universe->pings);
    for (int i=0;i<universe->pongCount;i++) free(universe->pongs[i]);
    free(universe->pongs);
    free(universe);
}

PCNode* PCUniverseCreateNode(PCUniverse* universe, double x, double y, double a, unsigned char emitting, unsigned char answering) {
    PCNode* node = (PCNode*)malloc(sizeof(PCNode));
    node->pos.x = x;
    node->pos.y = y;
    node->a = a;
    node->emitting = emitting;
    node->answering = answering;
    node->emitted = 0;
    node->captures = 0;
    node->pongArrivals = 0;

    universe->nodeCount++;
    if (universe->nodeCount > universe->nodeCapacity) {
        universe->nodeCapacity *= 2;
        universe->nodes = (PCNode**)realloc(universe->nodes, sizeof(PCNode*)*universe->nodeCapacity);
    }
    universe->nodes[universe->nodeCount-1] = node;
    return node;
}

void PCUniverseSetC(PCUniverse* universe, double c) {
    universe->c = c;
}
void PCUniverseSetRho0(PCUniverse* universe, int rho0) {
    universe->rho0 = rho0;
}
void PCUniverseSetSize(PCUniverse* universe, double width, double height) {
    universe->width = width;
    universe->height = height;
}
void PCUniverseReset(PCUniverse* universe) {
    for (int i=0;i<universe->pingCount;i++) free(universe->pings[i]);
    universe->pingCount = 0;
    for (int i=0;i<universe->pongCount;i++) free(universe->pongs[i]);
    universe->pongCount = 0;
    for (int i=0;i<universe->nodeCount;i++) {
        universe->nodes[i]->emitted = 0;
        universe->nodes[i]->captures = 0;
        universe->nodes[i]->pongArrivals = 0;
    }
    universe->tic = 0;
}

static PCPing* PCUniverseAddPing(PCUniverse* universe) {
    universe->pingCount++;
    if (universe->pingCount > universe->pingCapacity) {
        universe->pingCapacity *= 2;
        universe->pings = (PCPing**)realloc(universe->pings, sizeof(PCPing*)*universe->pingCapacity);
    }
    PCPing* ping = (PCPing*)malloc(sizeof(PCPing));
    universe->pings[universe->pingCount-1] = ping;
    return ping;
}
static PCPong* PCUniverseAddPong(PCUniverse* universe) {
    universe->pongCount++;
    if (universe->pongCount > universe->pongCapacity) {
        universe->pongCapacity *= 2;
        universe->pongs = (PCPong**)realloc(universe->pongs, sizeof(PCPong*)*universe->pongCapacity);
    }
    PCPong* pong = (PCPong*)malloc(sizeof(PCPong));
    universe->pongs[universe->pongCount-1] = pong;
    return pong;
}

// First entry of the segment p -> p + dir*s0 (dir unit) into the circle
// (C, r); returns the entry distance in [0, s0] or -1 for no entry.  A
// start already inside returns -1: capture is an entry event, so there
// is no tunneling at any speed and no re-capture from inside.
static double PCSegCircleEntry(CV2 p, CV2 dir, double s0, CV2 C, double r) {
    double qx = p.x - C.x, qy = p.y - C.y;
    double c0 = qx*qx + qy*qy - r*r;
    if (c0 <= 0) return -1;
    double b = qx*dir.x + qy*dir.y;
    if (b >= 0) return -1;
    double disc = b*b - c0;
    if (disc < 0) return -1;
    double sEnter = -b - sqrt(disc);
    return (sEnter <= s0) ? sEnter : -1;
}

static int PCUniverseOutside(PCUniverse* universe, CV2 pos) {
    return pos.x < -PC_CULL_MARGIN || pos.x > universe->width + PC_CULL_MARGIN
        || pos.y < -PC_CULL_MARGIN || pos.y > universe->height + PC_CULL_MARGIN;
}

// A capture: absorb the ping and, if the capturing node answers, launch
// one pong from the capture point toward the ping's source.  The pong
// finishes the tic itself (`remaining`) so event times stay continuous.
// This function is the extension point: Demo 1's mode axis and
// hemisphere classification hang off this event with nothing rebuilt.
static void PCUniverseCapture(PCUniverse* universe, PCNode* node, PCPing* ping, CV2 point, double remaining) {
    node->captures++;
    ping->recycle = 1;

    if (!node->answering) return;

    PCNode* source = ping->source;
    double dx = source->pos.x - point.x, dy = source->pos.y - point.y;
    double len = sqrt(dx*dx + dy*dy);
    if (len < 1e-12) return;

    PCPong* pong = PCUniverseAddPong(universe);
    pong->pos = point;
    pong->dir.x = dx/len;
    pong->dir.y = dy/len;
    pong->target = source;
    pong->recycle = 0;

    if (remaining > 0) {
        double sEnter = PCSegCircleEntry(pong->pos, pong->dir, remaining, source->pos, source->a);
        if (sEnter >= 0) {
            source->pongArrivals++;
            pong->recycle = 1;
        } else {
            pong->pos.x += pong->dir.x * remaining;
            pong->pos.y += pong->dir.y * remaining;
        }
    }
}

void PCUniverseTic(PCUniverse* universe) {
    double step = universe->c;

    // 1. Emission at the tic boundary: stratified isotropic volley,
    //    golden-ratio offset per tic per node — deterministic, no RNG.
    for (int n=0;n<universe->nodeCount;n++) {
        PCNode* node = universe->nodes[n];
        if (!node->emitting) continue;
        double u = fmod(PC_PHI * (double)universe->tic + 0.37 * n, 1.0);
        for (int j=0;j<universe->rho0;j++) {
            double theta = 2.0*M_PI*((double)j + u)/(double)universe->rho0;
            PCPing* ping = PCUniverseAddPing(universe);
            ping->pos = node->pos;
            ping->dir.x = cos(theta);
            ping->dir.y = sin(theta);
            ping->source = node;
            ping->recycle = 0;
            node->emitted++;
        }
    }

    // 2. Fly the pings; captures spawn pongs, which finish the tic
    //    inside PCUniverseCapture.
    int pongPre = universe->pongCount;
    for (int i=0;i<universe->pingCount;i++) {
        PCPing* ping = universe->pings[i];
        if (ping->recycle) continue;
        PCNode* hitNode = 0;
        double hitS = 1e300;
        for (int n=0;n<universe->nodeCount;n++) {
            PCNode* node = universe->nodes[n];
            if (node == ping->source) continue;
            double sEnter = PCSegCircleEntry(ping->pos, ping->dir, step, node->pos, node->a);
            if (sEnter >= 0 && sEnter < hitS) { hitS = sEnter; hitNode = node; }
        }
        if (hitNode) {
            CV2 point = { ping->pos.x + ping->dir.x*hitS, ping->pos.y + ping->dir.y*hitS };
            PCUniverseCapture(universe, hitNode, ping, point, step - hitS);
        } else {
            ping->pos.x += ping->dir.x * step;
            ping->pos.y += ping->dir.y * step;
            if (PCUniverseOutside(universe, ping->pos)) ping->recycle = 1;
        }
    }

    // 3. Fly the pre-existing pongs; they die entering their target.
    for (int i=0;i<pongPre;i++) {
        PCPong* pong = universe->pongs[i];
        if (pong->recycle) continue;
        double sEnter = PCSegCircleEntry(pong->pos, pong->dir, step, pong->target->pos, pong->target->a);
        if (sEnter >= 0) {
            pong->target->pongArrivals++;
            pong->recycle = 1;
        } else {
            pong->pos.x += pong->dir.x * step;
            pong->pos.y += pong->dir.y * step;
        }
    }

    // 4. Compact.
    int k = 0;
    for (int i=0;i<universe->pingCount;i++) {
        PCPing* ping = universe->pings[i];
        if (ping->recycle) { free(ping); } else { universe->pings[k++] = ping; }
    }
    universe->pingCount = k;
    k = 0;
    for (int i=0;i<universe->pongCount;i++) {
        PCPong* pong = universe->pongs[i];
        if (pong->recycle) { free(pong); } else { universe->pongs[k++] = pong; }
    }
    universe->pongCount = k;

    universe->tic++;
}

long PCUniverseCensus(PCUniverse* universe, PCNode* target) {
    long census = 0;
    for (int i=0;i<universe->pongCount;i++)
        if (universe->pongs[i]->target == target && !universe->pongs[i]->recycle) census++;
    return census;
}
