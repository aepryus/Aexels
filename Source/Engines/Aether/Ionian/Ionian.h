//
//  Ionian.h
//  Aexels
//
//  Created by Joe Charlier on 5/12/19.
//  Copyright © 2019 Aepryus Software. All rights reserved.
//

// IC = Ionian Sea : Cellular Automata and Aether

#import "Aegean.h"

// Aether ==========================================================================================
typedef struct ICAexel ICAexel;
typedef struct Bond Bond;
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
typedef struct ICAexel {
	Vector s;
	Vector ds;
	int sectorIndex;
	int oldIndex;
	int bondCount;
	Bond* bonds;
	byte stateA;
	byte stateB;
    byte stateC;
} ICAexel;

ICAexel* ICAexelCreate(double x, double y);
void ICAexelRelease(ICAexel* aexel);

// Bond =====
typedef struct Bond {
	ICAexel* a;
	ICAexel* b;
	double lengthSquared;
	byte hot;
} Bond;

Bond* AXBondCreate(ICAexel* a, ICAexel* b);
Bond* AXBondCreateClone(Bond* bond);
void AXBondRelease(Bond* bond);
ICAexel* AXBondOtherAexel(Bond bond, ICAexel* aexel);
byte AXBondCrosses(Bond a, Bond b);

// Sector ===
typedef struct Sector {
	int aexelCount;
	ICAexel** aexels;
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
	ICAexel** aexels;
	int bondCount;
	Bond* bonds;
	byte gol;
} Universe;

Universe* AXUniverseCreate(double width, double height, double relaxed, double snapped, double jump, int aexelCount, int photonCount, int hadronCount);
Universe* AXUniverseCreateE(double width, double height, double relaxed);
Universe* AXUniverseCreateF(double width, double height, double relaxed);
Universe* AXUniverseCreateG(double width, double height, double relaxed);
Universe* AXUniverseCreateH(double width, double height, double relaxed);
Universe* AXUniverseCreateI(double width, double height, double relaxed);
Universe* AXUniverseCreateJ(double width, double height, double relaxed);
void AXUniverseRelease(Universe* universe);
void AXUniverseDemarcate(Universe* universe);
void AXUniverseReset(Universe* universe);
byte AXUniverseUsing(Universe* universe, ICAexel* aexel);
ICAexel* AXUniverseAexelNear(Universe* universe, Vector v);
void AXUniverseBind(Universe* universe);
void AXUniverseTic(Universe* universe);
void AXUniverseAddAexel(Universe* universe, double x, double y);
void AXUniverseRemoveAexel(Universe* universe, ICAexel* aexel);

void test(void);
