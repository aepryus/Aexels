//
//  Ionian.h
//  Aexels
//
//  Created by Joe Charlier on 5/12/19.
//  Copyright © 2019 Aepryus Software. All rights reserved.
//

#import "Aegean.h"

// Cellular Automata ===============================================================================
typedef struct Automata {
	Recipe* recipe;
	Memory* memory;
	int w;
	mnimi sI;
	mnimi aI;
	mnimi bI;
	mnimi cI;
	mnimi dI;
	mnimi eI;
	mnimi fI;
	mnimi gI;
	mnimi hI;
	mnimi rI;
} Automata;

Automata* AXAutomataCreate(Recipe* recipe, Memory* memory, int w, mnimi sI, mnimi aI, mnimi bI, mnimi cI, mnimi dI, mnimi eI, mnimi fI, mnimi gI, mnimi hI, mnimi rI);
Automata* AXAutomataCreateClone(Automata* automata);
void AXAutomataRelease(Automata* automata);
void AXAutomataStep(Automata* automata, double* cells, double* next, int from, int to);
void AXDataLoad(byte* data, double* cells, long sX, long eX, long dnX, long sY, long eY, long dnY, long zoom, double states, byte* r, byte* g, byte* b, byte* a, long cw, long dw);

// Gravity =========================================================================================
typedef struct Aexel Aexel;
typedef struct Bond Bond;
typedef struct Photon Photon;
typedef struct Quark Quark;
typedef struct Hadron Hadron;
typedef struct Sector Sector;
typedef struct Universe Universe;

// Vector ===
typedef struct Vector {
	double x;
	double y;
} Vector;

Vector AXVectorSub(Vector a, Vector b);
Vector AXVectorMul(Vector a, double b);
double AXVectorLength(Vector a);
double AXVectorDot(Vector a, Vector b);
double AXVectorAngle(Vector a, Vector b);
byte AXVectorCrosses(Vector a1, Vector a2, Vector b1, Vector b2);

// Aexel ====
typedef struct Aexel {
	Vector s;
	Vector ds;
	int sectorIndex;
	int oldIndex;
	int bondCount;
	Bond* bonds;
	byte stateA;
	byte stateB;
} Aexel;

Aexel* AXAexelCreate(double x, double y);
void AXAexelRelease(Aexel* aexel);

// Bond =====
typedef struct Bond {
	Aexel* a;
	Aexel* b;
	double lengthSquared;
	byte hot;
} Bond;

Bond* AXBondCreate(Aexel* a, Aexel* b);
Bond* AXBondCreateClone(Bond* bond);
void AXBondRelease(Bond* bond);
Aexel* AXBondOtherAexel(Bond bond, Aexel* aexel);
byte AXBondCrosses(Bond a, Bond b);

// Photon ===
typedef struct Photon {
	Aexel* aexel;
	Vector v;
} Photon;

Photon* AXPhotonCreate(Aexel* aexel);
void AXPhotonRelease(Photon* photon);
void AXPhotonStep(Photon* photon);

// Quark ====
typedef struct Quark {
	Aexel* aexel;
	Hadron* hadron;
	Vector pressure;
} Quark;

Quark* AXQuarkCreate(Hadron* hadron, Aexel* aexel);
void AXQuarkRelease(Quark* quark);
void AXQuarkStep(Quark* quark);

// Hadron ===
typedef struct Hadron {
	byte anti;
	Quark quarks[3];
	Vector v;
	Aexel* center;
} Hadron;

Hadron* AXHadronCreate(Aexel* aexel, byte anti);
void AXHadronRelease(Hadron* hadron);
byte AXHadronUsing(Hadron* hadron, Aexel* aexel);
void AXHadronStep(Universe* universe, Hadron* hadron);

// Sector ===
typedef struct Sector {
	int aexelCount;
	Aexel** aexels;
} Sector;

Sector* AXSectorCreate(void);
void AXSectorRelease(Sector* sector);

// Universe =
typedef struct Universe {
	double width;
	double height;
	double relaxed;
	double snapped;
	double jump;
	int sectorWidth;
	int sectorCount;
	Sector** sectors;
	int aexelCount;
	Aexel** aexels;
	int bondCount;
	Bond* bonds;
	int photonCount;
	Photon** photons;
	int hadronCount;
	Hadron** hadrons;
	byte gol;
} Universe;

Universe* AXUniverseCreate(double width, double height, double relaxed, double snapped, double jump, int aexelCount, int photonCount, int hadronCount);
void AXUniverseRelease(Universe* universe);
void AXUniverseDemarcate(Universe* universe);
void AXUniverseHadronFindCenter(Universe* universe, Hadron* hadron);
byte AXUniverseUsing(Universe* universe, Aexel* aexel);
Aexel* AXUniverseAexelNear(Universe* universe, Vector v);
void AXUniverseBind(Universe* universe);
void AXUniverseTic(Universe* universe);

void test(void);
