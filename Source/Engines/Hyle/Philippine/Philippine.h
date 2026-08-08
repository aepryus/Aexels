//
//  Philippine.h
//  Aexels
//
//  Created by Joe Charlier on 8/8/26.
//  Copyright © 2026 Aepryus Software. All rights reserved.
//

// PC = Philippine Sea : Hyle / Quantum — the deepest sea for the deepest layer.
//
// Demo 0: the static pong bridge, from nothing.  The only physics is
// emit, fly, capture, respond.  Nodes emit pings isotropically; a ping
// entering another node's radius is captured and answered with exactly
// one pong, launched from the capture point toward the emitting node's
// center, where it dies on arrival.  Pongs are never answered.  The
// standing in-flight pong population between two nodes IS the static
// pong bridge — two directed cones, emerging rather than drawn.
//
// Verified against exact geometry in the headless build
// (Sims/PongBridge): capture rate rho0*asin(a/L)/pi, census
// rho0*a/(pi*c) in the point-node limit, drain (2*sqrt(L^2-a^2)-a)/c.

#import "Sea.h"

typedef struct PCNode {
    CV2 pos;
    double a;                    // radius
    CV2 mode;                    // m-hat: the axis of the node's internal 2-D
                                 // oscillation mode — the ONE object of the
                                 // papers (BJFE abstract/S7): the per-ping
                                 // cupola is this mode's emission-by-emission
                                 // sampling (ItL S5.4: an oscillating source's
                                 // cupolas trace its axis at the observer),
                                 // and the SU(2) frame is its double cover.
                                 // Every capture classifies by
                                 // sign(n-hat . m-hat), n-hat the outward
                                 // normal at the capture point — BJFE's
                                 // bisector/Archimedes mechanism candidate for
                                 // the cross-section coupling: the split is
                                 // (1 + cos chi)/2 = cos^2(chi/2), the
                                 // electron-branch Born weight, chi the angle
                                 // between m-hat and the incoming beam.
                                 // Missing here, per the papers: the mode's
                                 // PHASE (BJFE S5's de Broglie clock,
                                 // omega0 = eta0 c^2 / hbar) — the stirrer of
                                 // the H-theorem and the beat behind the
                                 // parcel; Demo 2 runs on it.
    unsigned char emitting;      // streams pings when set
    unsigned char answering;     // answers captures with pongs when set
    long emitted;
    long captures;
    long plusCaptures;           // sign(n-hat . m-hat) > 0
    long minusCaptures;
    long pongArrivals;
} PCNode;

typedef struct PCPing {
    CV2 pos;
    CV2 dir;                     // unit; speed is universe->c
    PCNode* source;
    unsigned char recycle;
} PCPing;

typedef struct PCPong {
    CV2 pos;
    CV2 dir;                     // unit; aimed at target's center at birth
    PCNode* target;              // the node whose ping was captured
    unsigned char channel;       // its capture's classification: 1 = plus
    unsigned char recycle;
} PCPong;

typedef struct PCUniverse {
    double width;
    double height;
    double c;                    // lengths per tic
    int rho0;                    // pings per tic per emitting node
    long tic;
    int nodeCount;
    int nodeCapacity;
    PCNode** nodes;
    int pingCount;
    int pingCapacity;
    PCPing** pings;
    int pongCount;
    int pongCapacity;
    PCPong** pongs;
} PCUniverse;

PCUniverse* PCUniverseCreate(double width, double height);
void PCUniverseRelease(PCUniverse* universe);
PCNode* PCUniverseCreateNode(PCUniverse* universe, double x, double y, double a, unsigned char emitting, unsigned char answering);
void PCNodeSetMode(PCNode* node, double mx, double my);
void PCUniverseSetC(PCUniverse* universe, double c);
void PCUniverseSetRho0(PCUniverse* universe, int rho0);
void PCUniverseSetSize(PCUniverse* universe, double width, double height);
void PCUniverseReset(PCUniverse* universe);
void PCUniverseTic(PCUniverse* universe);
long PCUniverseCensus(PCUniverse* universe, PCNode* target);
