//
//  Philippine.h
//  Aexels
//
//  Created by Joe Charlier on 8/8/26.
//  Copyright © 2026 Aepryus Software. All rights reserved.
//

// PC = Philippine Sea : Hyle / Quantum — the deepest sea for the deepest layer.
//
// The bridge, with the rules as stated.  Nodes translate at constant
// velocity.  Emission follows ItL Rule 3 ((1-b^2)rho0/(1-b cos theta)^2
// around the velocity direction); every ping carries its cupola
// C = n-hat − beta (SitD, dimensionless convention); a ping entering
// the other node's (moving) radius is captured and answered with one
// pong = the ping's reversed translation mirrored over the cupola axis
// — Euclid's bisector theorem guarantees it intercepts the moving
// source (verified at ~1e-16 in the headless twin, Sims/Bridge).  The
// standing carrier population between the pair IS the bridge — two
// circuits, one per source, the frozen-snapshot object of the bridge
// model.  Static nodes recover Demo 0 exactly (C = n-hat; the mirror
// rule degenerates to fly-straight-back).
//
// Verified headless: Sims/PongBridge (static geometry: capture rate,
// census, drain, stake-setter splits) and Sims/Bridge (moving pairs:
// equal bidirectional capture, 2*gamma^2*L / 2*gamma*L round trips,
// (1+b)/(1-b) two-lane corridor).

#import "Sea.h"

typedef struct PCNode {
    CV2 pos;
    CV2 pos0;                    // placement at reset
    CV2 v;                       // velocity, lengths per tic (constant)
    double* cdf;                 // Rule-3 inverse-CDF table (NULL when static)
    double a;                    // radius
    CV2 mode;                    // m-hat: the axis of the node's internal 2-D
                                 // oscillation mode — a POSITED organ, new in
                                 // BJFE (the de Broglie clock is "a genuine
                                 // postulate of this paper"); nodes do NOT
                                 // have cupolas — cupolas belong to pings
                                 // (C = c-vec minus v_source).  The mode's
                                 // FOOTPRINT is what the earlier papers carry:
                                 // an oscillating source's velocity prints
                                 // onto its emitted cupolas (ItL S5.4), so
                                 // the per-ping cupola SAMPLES the mode.  How
                                 // the phase rides the ping is BJFE's open
                                 // fork (S8 item c): phase stamp vs
                                 // reconstruction from the cupola.
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
    CV2 dir;                     // unit flight direction n-hat; speed is universe->c
    CV2 cupola;                  // C = n-hat − beta at emission (dimensionless)
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
    int pingsPerVolley;          // spatial density — as in SitD
    int ticsPerVolley;           // temporal density — as in SitD
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
void PCUniverseSetNodeVelocity(PCUniverse* universe, PCNode* node, double vx, double vy);
void PCUniverseSetC(PCUniverse* universe, double c);
void PCUniverseSetVolley(PCUniverse* universe, int pingsPerVolley, int ticsPerVolley);
void PCUniverseSetSize(PCUniverse* universe, double width, double height);
void PCUniverseReset(PCUniverse* universe);
void PCUniverseTic(PCUniverse* universe);
long PCUniverseCensus(PCUniverse* universe, PCNode* target);
