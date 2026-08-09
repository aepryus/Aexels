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
#define PC_NGRID 4096

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
    for (int i=0;i<universe->nodeCount;i++) {
        if (universe->nodes[i]->cdf) free(universe->nodes[i]->cdf);
        free(universe->nodes[i]);
    }
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
    node->pos0 = node->pos;
    node->v.x = 0;
    node->v.y = 0;
    node->cdf = 0;
    node->a = a;
    node->mode.x = 1;
    node->mode.y = 0;
    node->emitting = emitting;
    node->answering = answering;
    node->emitted = 0;
    node->captures = 0;
    node->plusCaptures = 0;
    node->minusCaptures = 0;
    node->pongArrivals = 0;

    universe->nodeCount++;
    if (universe->nodeCount > universe->nodeCapacity) {
        universe->nodeCapacity *= 2;
        universe->nodes = (PCNode**)realloc(universe->nodes, sizeof(PCNode*)*universe->nodeCapacity);
    }
    universe->nodes[universe->nodeCount-1] = node;
    return node;
}

void PCNodeSetMode(PCNode* node, double mx, double my) {
    double len = sqrt(mx*mx + my*my);
    if (len < 1e-12) return;
    node->mode.x = mx/len;
    node->mode.y = my/len;
}

// Set a node's velocity (lengths per tic) and build its engineered-
// emission inverse-CDF table.  This 2D lab uses the 2D-CORRECT form of
// Rule 3: rho(theta) = sqrt(1-b^2) rho0 / (1 - b cos theta), theta from
// the velocity direction, b = |v|/c.  Rule 3's job is two theorems —
// total emission beta-independent, and the fore/aft capture geometry
// exactly cancelled — and the power of kappa that does it is D-1: two
// in the papers' 3D, ONE here.  Verified in Sims/Bridge/
// bridge2d_check.py: the 3D form in 2D leaves capture asymmetric by
// (1+b)/(1-b) (3.992 measured at b=0.6); the 2D form restores equal
// bidirectional capture (1.007) with a beta-independent total (the
// integral is exactly 2*pi*rho0).  Constant velocities mean the table
// is built once, here.
void PCUniverseSetNodeVelocity(PCUniverse* universe, PCNode* node, double vx, double vy) {
    node->v.x = vx;
    node->v.y = vy;
    double beta = sqrt(vx*vx + vy*vy) / universe->c;
    if (node->cdf) { free(node->cdf); node->cdf = 0; }
    if (beta < 1e-9) return;
    node->cdf = (double*)malloc(sizeof(double)*(PC_NGRID+1));
    double dq = 2.0*M_PI/PC_NGRID;
    double pref = sqrt(1.0 - beta*beta);
    node->cdf[0] = 0;
    for (int g=0;g<PC_NGRID;g++) {
        double q = (g + 0.5)*dq;
        double k = 1.0 - beta*cos(q);
        node->cdf[g+1] = node->cdf[g] + pref/k*dq;
    }
    double total = node->cdf[PC_NGRID];
    for (int g=0;g<=PC_NGRID;g++) node->cdf[g] /= total;
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
        universe->nodes[i]->pos = universe->nodes[i]->pos0;
        universe->nodes[i]->emitted = 0;
        universe->nodes[i]->captures = 0;
        universe->nodes[i]->plusCaptures = 0;
        universe->nodes[i]->minusCaptures = 0;
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

// First entry of a moving point into a moving circle, parameterized by
// TIME fraction of the tic.  relP = point − circle center at tau=0;
// relV = point velocity − circle velocity (lengths per tic).  Returns
// tau in [0, tmax] or -1.  A start already inside returns -1: capture
// is an entry event, so there is no tunneling and no re-capture.
static double PCMovingEntry(CV2 relP, CV2 relV, double r, double tmax) {
    double c0 = relP.x*relP.x + relP.y*relP.y - r*r;
    if (c0 <= 0) return -1;
    double b = relP.x*relV.x + relP.y*relV.y;
    if (b >= 0) return -1;
    double A = relV.x*relV.x + relV.y*relV.y;
    if (A < 1e-18) return -1;
    double disc = b*b - A*c0;
    if (disc < 0) return -1;
    double tau = (-b - sqrt(disc)) / A;
    return (tau <= tmax) ? tau : -1;
}

static int PCUniverseOutside(PCUniverse* universe, CV2 pos, CV2 mid) {
    return pos.x < mid.x - universe->width/2  - PC_CULL_MARGIN
        || pos.x > mid.x + universe->width/2  + PC_CULL_MARGIN
        || pos.y < mid.y - universe->height/2 - PC_CULL_MARGIN
        || pos.y > mid.y + universe->height/2 + PC_CULL_MARGIN;
}

// A capture: absorb the ping, classify it against the node's mode axis
// (the stake-setter — Demo 1), and, if the capturing node answers,
// launch one pong from the capture point.  The pong is the SitD rule
// as stated: the ping's reversed translation mirrored over the ping's
// cupola axis — Euclid's bisector theorem guarantees it intercepts the
// (moving) source.  It finishes the tic itself (`remaining`, a TIME
// fraction) so event times stay continuous, and carries its capture's
// classification as its channel.  `center` is the capturing node's
// position at the capture instant.
static void PCUniverseCapture(PCUniverse* universe, PCNode* node, PCPing* ping, CV2 point, CV2 center, double remaining) {
    node->captures++;
    ping->recycle = 1;

    // n-hat . m-hat: outward normal at the capture point against the
    // mode axis.  A distant isotropic emitter is a uniform-impact-
    // parameter beam, so the split converges to (1 +/- cos chi)/2 with
    // chi the angle between m-hat and the incoming beam direction.
    double nx = (point.x - center.x) / node->a;
    double ny = (point.y - center.y) / node->a;
    unsigned char channel = (nx*node->mode.x + ny*node->mode.y) > 0;
    if (channel) node->plusCaptures++;
    else         node->minusCaptures++;

    if (!node->answering) return;

    PCNode* source = ping->source;

    // pong = ping translation mirrored over the cupola axis:
    // v_pong = v_ping − 2 (v_ping . C-hat) C-hat  (speed preserved: c).
    double c2 = ping->cupola.x*ping->cupola.x + ping->cupola.y*ping->cupola.y;
    if (c2 < 1e-18) return;
    double scale = 2.0 * (ping->dir.x*ping->cupola.x + ping->dir.y*ping->cupola.y) / c2;
    double px = ping->dir.x - scale * ping->cupola.x;
    double py = ping->dir.y - scale * ping->cupola.y;
    double plen = sqrt(px*px + py*py);
    if (plen < 1e-12) return;

    PCPong* pong = PCUniverseAddPong(universe);
    pong->pos = point;
    pong->dir.x = px/plen;
    pong->dir.y = py/plen;
    pong->target = source;
    pong->channel = channel;
    pong->recycle = 0;

    if (remaining > 0) {
        // Source's position at the capture instant: it has advanced
        // (1 − remaining) of this tic from its tic-start position.
        double adv = 1.0 - remaining;
        CV2 srcAt = { source->pos.x + source->v.x*adv, source->pos.y + source->v.y*adv };
        CV2 relP = { pong->pos.x - srcAt.x, pong->pos.y - srcAt.y };
        CV2 relV = { pong->dir.x*universe->c - source->v.x, pong->dir.y*universe->c - source->v.y };
        double tau = PCMovingEntry(relP, relV, source->a, remaining);
        if (tau >= 0) {
            source->pongArrivals++;
            pong->recycle = 1;
        } else {
            pong->pos.x += pong->dir.x * universe->c * remaining;
            pong->pos.y += pong->dir.y * universe->c * remaining;
        }
    }
}

void PCUniverseTic(PCUniverse* universe) {
    double c = universe->c;

    // The cull box follows the pair.
    CV2 mid = {0, 0};
    for (int n=0;n<universe->nodeCount;n++) {
        mid.x += universe->nodes[n]->pos.x;
        mid.y += universe->nodes[n]->pos.y;
    }
    if (universe->nodeCount) { mid.x /= universe->nodeCount; mid.y /= universe->nodeCount; }

    // 1. Emission at the tic boundary: Rule-3 angular density about the
    //    velocity direction, stratified with golden-ratio offset per
    //    tic per node — deterministic, no RNG.  Each ping carries its
    //    cupola C = n-hat − beta at emission.
    for (int n=0;n<universe->nodeCount;n++) {
        PCNode* node = universe->nodes[n];
        if (!node->emitting) continue;
        double u = fmod(PC_PHI * (double)universe->tic + 0.37 * n, 1.0);
        double speed = sqrt(node->v.x*node->v.x + node->v.y*node->v.y);
        double vDirX = 1.0, vDirY = 0.0;
        if (speed > 1e-12) { vDirX = node->v.x/speed; vDirY = node->v.y/speed; }
        for (int j=0;j<universe->rho0;j++) {
            double frac = ((double)j + u)/(double)universe->rho0;
            double theta;
            if (node->cdf) {
                int lo = 0, hi = PC_NGRID;
                while (hi - lo > 1) {
                    int m = (lo + hi)/2;
                    if (node->cdf[m] < frac) lo = m; else hi = m;
                }
                double den = node->cdf[hi] - node->cdf[lo];
                if (den < 1e-15) den = 1e-15;
                theta = ((double)lo + (frac - node->cdf[lo])/den) * (2.0*M_PI/PC_NGRID);
            } else {
                theta = 2.0*M_PI*frac;
            }
            double ct = cos(theta), st = sin(theta);
            PCPing* ping = PCUniverseAddPing(universe);
            ping->pos = node->pos;
            ping->dir.x = ct*vDirX - st*vDirY;
            ping->dir.y = ct*vDirY + st*vDirX;
            ping->cupola.x = ping->dir.x - node->v.x/c;
            ping->cupola.y = ping->dir.y - node->v.y/c;
            ping->source = node;
            ping->recycle = 0;
            node->emitted++;
        }
    }

    // 2. Fly the pings; captures spawn pongs, which finish the tic
    //    inside PCUniverseCapture.  Targets move within the tic, so
    //    entry is solved in the relative frame, in time fraction tau.
    int pongPre = universe->pongCount;
    for (int i=0;i<universe->pingCount;i++) {
        PCPing* ping = universe->pings[i];
        if (ping->recycle) continue;
        PCNode* hitNode = 0;
        double hitTau = 1e300;
        for (int n=0;n<universe->nodeCount;n++) {
            PCNode* node = universe->nodes[n];
            if (node == ping->source) continue;
            CV2 relP = { ping->pos.x - node->pos.x, ping->pos.y - node->pos.y };
            CV2 relV = { ping->dir.x*c - node->v.x, ping->dir.y*c - node->v.y };
            double tau = PCMovingEntry(relP, relV, node->a, 1.0);
            if (tau >= 0 && tau < hitTau) { hitTau = tau; hitNode = node; }
        }
        if (hitNode) {
            CV2 point  = { ping->pos.x + ping->dir.x*c*hitTau, ping->pos.y + ping->dir.y*c*hitTau };
            CV2 center = { hitNode->pos.x + hitNode->v.x*hitTau, hitNode->pos.y + hitNode->v.y*hitTau };
            PCUniverseCapture(universe, hitNode, ping, point, center, 1.0 - hitTau);
        } else {
            ping->pos.x += ping->dir.x * c;
            ping->pos.y += ping->dir.y * c;
            if (PCUniverseOutside(universe, ping->pos, mid)) ping->recycle = 1;
        }
    }

    // 3. Fly the pre-existing pongs; they die entering their (moving)
    //    target.
    for (int i=0;i<pongPre;i++) {
        PCPong* pong = universe->pongs[i];
        if (pong->recycle) continue;
        PCNode* target = pong->target;
        CV2 relP = { pong->pos.x - target->pos.x, pong->pos.y - target->pos.y };
        CV2 relV = { pong->dir.x*c - target->v.x, pong->dir.y*c - target->v.y };
        double tau = PCMovingEntry(relP, relV, target->a, 1.0);
        if (tau >= 0) {
            target->pongArrivals++;
            pong->recycle = 1;
        } else {
            pong->pos.x += pong->dir.x * c;
            pong->pos.y += pong->dir.y * c;
        }
    }

    // 3b. Translate the nodes.
    for (int n=0;n<universe->nodeCount;n++) {
        universe->nodes[n]->pos.x += universe->nodes[n]->v.x;
        universe->nodes[n]->pos.y += universe->nodes[n]->v.y;
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
