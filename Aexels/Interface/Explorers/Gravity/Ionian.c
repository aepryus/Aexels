//
//  Ionian.c
//  Aexels
//
//  Created by Joe Charlier on 5/12/19.
//  Copyright © 2019 Aepryus Software. All rights reserved.
//

#import <math.h>
#import <stdlib.h>
#import "Ionian.h"

#import "stdio.h"
#import <time.h>

// Cellular Automata ===============================================================================
Automata* AXAutomataCreate(Recipe* recipe, Memory* memory, int w, mnimi sI, mnimi aI, mnimi bI, mnimi cI, mnimi dI, mnimi eI, mnimi fI, mnimi gI, mnimi hI, mnimi rI) {
	Automata* automata = (Automata*)malloc(sizeof(Automata));
	automata->recipe = AERecipeCreateClone(recipe);
	automata->memory = AEMemoryCreateClone(memory);
	automata->w = w;
	automata->sI = sI;
	automata->aI = aI;
	automata->bI = bI;
	automata->cI = cI;
	automata->dI = dI;
	automata->eI = eI;
	automata->fI = fI;
	automata->gI = gI;
	automata->hI = hI;
	automata->rI = rI;
	return automata;
}
Automata* AXAutomataCreateClone(Automata* automata) {
	Automata* clone = (Automata*)malloc(sizeof(Automata));
	clone->recipe = AERecipeCreateClone(automata->recipe);
	clone->memory = AEMemoryCreateClone(automata->memory);
	clone->w = automata->w;
	clone->sI = automata->sI;
	clone->aI = automata->aI;
	clone->bI = automata->bI;
	clone->cI = automata->cI;
	clone->dI = automata->dI;
	clone->eI = automata->eI;
	clone->fI = automata->fI;
	clone->gI = automata->gI;
	clone->hI = automata->hI;
	clone->rI = automata->rI;
	return clone;
}
void AXAutomataRelease(Automata* automata) {
	if (automata == 0) return;
	AERecipeRelease(automata->recipe);
	AEMemoryRelease(automata->memory);
	free(automata);
}

void AXAutomataStep(Automata* a, double* cells, double* next, int from, int to) {
	for (int j = from; j < to; j++) {
		for (int i = 0; i < a->w; i++) {
			
			AEMemoryClear(a->memory);
			
			AEMemorySetValue(a->memory, a->sI, 								cells[i   + (j  )*a->w]);
			AEMemorySetValue(a->memory, a->aI, i != 0 && j != 0 ? 			cells[i-1 + (j-1)*a->w] : 0);
			AEMemorySetValue(a->memory, a->bI, j != 0 ? 					cells[i   + (j-1)*a->w] : 0);
			AEMemorySetValue(a->memory, a->cI, i != a->w-1 && j != 0 ? 		cells[i+1 + (j-1)*a->w] : 0);
			AEMemorySetValue(a->memory, a->dI, i != a->w-1 ? 				cells[i+1 + (j  )*a->w] : 0);
			AEMemorySetValue(a->memory, a->eI, i != a->w-1 && j != a->w-1 ?	cells[i+1 + (j+1)*a->w] : 0);
			AEMemorySetValue(a->memory, a->fI, j != a->w-1 ?				cells[i   + (j+1)*a->w] : 0);
			AEMemorySetValue(a->memory, a->gI, i != 0 && j != a->w-1 ? 		cells[i-1 + (j+1)*a->w] : 0);
			AEMemorySetValue(a->memory, a->hI, i != 0 ? 					cells[i-1 + (j  )*a->w] : 0);
			
			AERecipeExecute(a->recipe, a->memory);
			
			next[i + j*a->w] = a->memory->slots[a->rI].obj.a.x;
		}
	}
}

void AXDataLoad(uint8_t* data, double* cells, long sX, long eX, long dnX, long sY, long eY, long dnY, long zoom, double states, uint8_t* r, uint8_t* g, uint8_t* b, uint8_t* a, long cw, long dw) {
	long n = 0;
	for (long j=sY;j<eY;j++) {
		for (long i=sX;i<eX;i++) {
			for (long q=0;q<zoom;q++) {
				for (long p=0;p<zoom;p++) {
					double value = cells[i+j*cw];
					char state = value >= 0 && value <= states ? (char)value : (char)states;
					data[n+4*p+dw*q+0] = r[state];
					data[n+4*p+dw*q+1] = g[state];
					data[n+4*p+dw*q+2] = b[state];
					data[n+4*p+dw*q+3] = a[state];
				}
			}
			n += dnX;
		}
		n += dnY;
	}
}

// Gravity =========================================================================================
// Vector ===
byte AXVectorEqual(Vector a, Vector b) {
	return a.x == b.x && a.y == b.y;
}
Vector AXVectorSub(Vector a, Vector b) {
	Vector result;
	result.x = a.x - b.x;
	result.y = a.y - b.y;
	return result;
}
Vector AXVectorMul(Vector a, double b) {
	Vector result;
	result.x = a.x*b;
	result.y = a.y*b;
	return result;
}
double AXVectorLength(Vector a) {
	return sqrt(a.x*a.x + a.y*a.y);
}
double AXVectorDot(Vector a,Vector b) {
	return a.x*b.x + a.y*b.y;
}
double AXVectorAngle(Vector a,Vector b) {
	return acos(AXVectorDot(a, b)/AXVectorLength(a)/AXVectorLength(b));
}
Vector AXVectorUnit(Vector a) {
	double l = sqrt(a.x*a.x + a.y*a.y);
	Vector result = {.x = a.x/l, .y = a.y/l};
	return result;
}
byte AXVectorWithin(Vector a, Vector b, double d) {
	double dx = fabs(a.x - b.x);
	double dy = fabs(a.y - b.y);
	return dx*dx+dy*dy <= d;
}
byte AXVectorIncludes(Vector a1, Vector a2, Vector v) {
	double top=0, bottom=0, left=0, right=0;
	if (a1.x < a2.x) {
		left = a1.x;
		right = a2.x;
	} else {
		left = a2.x;
		right = a1.x;
	}
	if (a1.y < a2.y) {
		top = a1.y;
		bottom = a2.y;
	} else {
		top = a2.y;
		bottom = a1.y;
	}
	return left <= v.x && right >= v.x && top <= v.y && bottom >= v.y;
}
//byte AXVectorCrossesNew(Vector a1, Vector a2, Vector b1, Vector b2) {
//	Vector a = {.x = a2.x-a1.x, .y = a2.y-a1.y};
//	Vector b = {.x = b2.x-b1.x, .y = b2.y-b1.y};
//	double thetaA = atan2(a.y, a.x);
//	double thetaB = atan2(b.y, b.x);
//	return 0;
//}
byte AXVectorCrosses(Vector a1, Vector a2,Vector b1, Vector b2) {
	Vector A = AXVectorSub(a2, a1);
	Vector B = AXVectorSub(b2, b1);

	if (A.x == 0 && B.x == 0) {
		if (a1.x != b1.x) return 0;
		return (a1.y < b1.y && b1.y < a2.y) || (a1.y < b2.y && b2.y < a2.y) || (b1.y < a1.y && a1.y < b2.y) || (b1.y < a2.y && a2.y < b2.y);
	}
	
	double aM = A.y/A.x;
	double bM = B.y/B.x;
	if (aM == bM) {
		double aB = a1.y - a1.x * aM;
		double bB = b1.y - b1.x * bM;
		if (aB != bB) return 0;
		return AXVectorIncludes(a1, a2, b1) || AXVectorIncludes(a1, a2, b2) || AXVectorIncludes(b1 ,b2, a1) || AXVectorIncludes(b1, b2, a2);
	}
	
	double r,p,q;
	
	if (fabs(A.y) > 1E-12) {
		r = A.x/A.y;
		q = (a1.x-a1.y*r-b1.x+b1.y*r) / (B.x-B.y*r);
		p = (b1.y+q*B.y-a1.y)/A.y;
	} else {
		r = A.y/A.x;
		q = (a1.y-a1.x*r-b1.y+b1.x*r) / (B.y-B.x*r);
		p = (b1.x+q*B.x-a1.x)/A.x;
	}

	return p > 0 && p < 1 && q > 0 && q < 1;
}

byte AXVectorCrosses2(Vector a1, Vector a2, Vector b1, Vector b2) {
	double adX = a2.x - a1.x;
	double bdX = b2.x - b1.x;
	
	if (adX == 0 && bdX == 0) {
		if (a1.x != b1.x) return 0;
		return AXVectorIncludes(a1, a2, b1) || AXVectorIncludes(a1, a2, b2) || AXVectorIncludes(b1, b2, a1) || AXVectorIncludes(b1, b2, a2);
	}
	
	Vector v;
	if (adX == 0 || bdX == 0) {
		Vector v1,v2,o1,o2;
		if (adX == 0) {
			v1 = a1;v2 = a2;
			o1 = b1;o2 = b2;
		} else {
			v1 = b1;v2 = b2;
			o1 = a1;o2 = a2;
		}
		double mO = (o2.y - o1.y)/(o2.x - o1.x);
		v.x = v1.x;
		v.y = o1.y + (v1.x - o1.x) * mO;
		return AXVectorIncludes(v1, v2, v) && AXVectorIncludes(o1, o2, v);
	}
	
	double adY = a2.y - a1.y;
	double bdY = b2.y - b1.y;
	
	double aM = adY/adX;
	double aB = a1.y - a1.x * aM;
	double bM = bdY/bdX;
	double bB = b1.y - b1.x * bM;
	
	if (aM == bM) {
		if (aB != bB) return 0;
		return AXVectorIncludes(a1, a2, b1) || AXVectorIncludes(a1, a2, b2) || AXVectorIncludes(b1 ,b2, a1) || AXVectorIncludes(b1, b2, a2);
	}
	
	v.x = (bB - aB)/(aM - bM);
	v.y = aM*v.x + aB;
	
	return AXVectorIncludes(a1, a2, v) && AXVectorIncludes(b1, b2, v);
}

#define MAXNEIGHBOR 6
// Aexel ====
Aexel* AXAexelCreate(double x, double y) {
	Aexel* aexel = (Aexel*)malloc(sizeof(Aexel));
	
	aexel->s.x = x;
	aexel->s.y = y;
	
	aexel->sectorIndex = -1;
	aexel->oldIndex = -1;

	aexel->bondCount = 0;
	aexel->bonds = (Bond*)malloc(sizeof(Bond)*100);
	
	aexel->stateA = arc4random() % 2;
	aexel->stateB = 0;
	
	return aexel;
}
void AXAexelRelease(Aexel* aexel) {
	free(aexel->bonds);
	free(aexel);
}
byte AXAexelWithin(Aexel* a, Aexel* b, int within) {
	if (a == 0 || b == 0) return 0;
	if (a == b) return 1;
	if (within == 0) return 0;
	for (int i=0;i<a->bondCount;i++) {
		if (AXAexelWithin(AXBondOtherAexel(a->bonds[i], a), b, within-1)) return 1;
	}
	return 0;
}
int AXAexelJumps(Aexel* a, Aexel* b) {
	for (int i=0;i<8;i++) {
		if (AXAexelWithin(a, b, i)) return i;
	}
	return -1;
}
//byte AXAexelNeighborCount(Aexel* aexel) {
//	int count = 0;
//	for (int i=0;i<MAXNEIGHBOR;i++) {
//		if (aexel->neighbors[i] != 0) count++;
//	}
//	return count;
//}
//byte AXAexelIsNeighbor(Aexel* aexel, Aexel* other) {
//	for (int i=0;i<MAXNEIGHBOR;i++) {
//		if (aexel->neighbors[i] == other) return 1;
//	}
//	return 0;
//}
//void AXAexelDetach(Aexel* aexel, Aexel* from) {
//	for (int i=0;i<MAXNEIGHBOR;i++) {
//		if (aexel->neighbors[i] == 0) continue;
//		if (aexel->neighbors[i] == from) aexel->neighbors[i] = 0;
//	}
//}
//void AXAexelUnbind(Aexel* aexel) {
//	for (int i=0;i<MAXNEIGHBOR;i++) {
//		if (aexel->neighbors[i] == 0) continue;
//		AXAexelDetach(aexel->neighbors[i], aexel);
//		aexel->neighbors[i] = 0;
//	}
//}
//int AXAexelClearFurthestNeighbor(Aexel* aexel) {
//	int farIndex = -1;
//	double furthestSquared = 0;
//	for (int i=0;i<MAXNEIGHBOR;i++) {
//		Aexel* neighbor = aexel->neighbors[i];
//		if (!neighbor) return i;
//		double dx = neighbor->s.x - aexel->s.x;
//		double dy = neighbor->s.y - aexel->s.y;
//		double lengthSquared = dx*dx + dy*dy;
//		if (farIndex == -1 || lengthSquared > furthestSquared) {
//			farIndex = i;
//			furthestSquared = lengthSquared;
//		}
//	}
//	aexel->neighbors[farIndex] = 0;
//	return farIndex;
//}
//void AXAexelForceBind(Aexel* aexel, Aexel* other) {
//	int a = AXAexelClearFurthestNeighbor(aexel);
//	int b = AXAexelClearFurthestNeighbor(other);
//	aexel->neighbors[a] = other;
//	other->neighbors[b] = aexel;
//}

// Bond =====
Bond* AXBondCreate(Aexel* a, Aexel* b) {
	Bond* bond = (Bond*)malloc(sizeof(Bond));
	bond->a = a;
	bond->b = b;
	double dx = bond->b->s.x - bond->a->s.x;
	double dy = bond->b->s.y - bond->a->s.y;
	bond->lengthSquared = dx*dx + dy*dy;
	return bond;
}
Bond* AXBondCreateClone(Bond* bond) {
	Bond* clone = (Bond*)malloc(sizeof(Bond));
	clone->a = bond->a;
	clone->b = bond->b;
	clone->lengthSquared = bond->lengthSquared;
	return clone;
}
void AXBondRelease(Bond* bond) {
	free(bond);
}
Aexel* AXBondOtherAexel(Bond bond, Aexel* aexel) {
	return bond.a == aexel ? bond.b : bond.a;
}
byte AXBondCrosses(Bond a, Bond b) {
	if (a.a != b.a && a.a != b.b && a.b != b.a && a.b != b.b)
		return AXVectorCrosses(a.a->s, a.b->s, b.a->s, b.b->s);

	double thetaA = atan2(a.b->s.y-a.a->s.y, a.b->s.x-a.a->s.x);
	double thetaB = atan2(b.b->s.y-b.a->s.y, b.b->s.x-b.a->s.x);
	
	if (fabs(thetaA-thetaB) > 0.0001) return 0;
	
	if ((a.a == b.a && a.b == b.b) || (a.a == b.b && a.b == b.a)) return 1;
	
	Vector p = (a.a == b.a || a.a == b.b) ? a.a->s : a.b->s;
	Vector q = (a.a == b.a || a.a == b.b) ? a.b->s : a.a->s;
	Vector r = (b.a == a.a || b.a == a.b) ? b.b->s : b.a->s;
	
	return AXVectorDot(AXVectorSub(p, r), AXVectorSub(p, q)) > 0;
}

// Photon ===
Photon* AXPhotonCreate(Aexel* aexel) {
	Photon* photon = (Photon*)malloc(sizeof(Photon));
	photon->aexel = aexel;
	double theta = ((double)(arc4random() % 10000))/10000*2*M_PI;
	photon->v.x = cos(theta);
	photon->v.y = sin(theta);
	return photon;
}
void AXPhotonRelease(Photon* photon) {
	free(photon);
}
byte AXPhotonAttempt(Photon* photon) {
	double minAngle = M_PI;
	Aexel* aexel = photon->aexel;
	Aexel* next = 0;
	for (int i=0;i<aexel->bondCount;i++) {
		Aexel* neighbor = AXBondOtherAexel(aexel->bonds[i], aexel);
		Vector nV = AXVectorSub(neighbor->s, aexel->s);
		double angle = fabs(AXVectorAngle(photon->v, nV));
		if (angle < minAngle) {
			minAngle = angle;
			next = neighbor;
		}
	}
	if (minAngle >= M_PI_2) return 0;
	photon->aexel = next;
	return 1;
}
void AXPhotonStep(Photon* photon) {
	if (!photon->aexel->bondCount) return;
	if (AXPhotonAttempt(photon)) return;
	photon->v.x = -photon->v.x;
	photon->v.y = -photon->v.y;
	AXPhotonAttempt(photon);
}
byte AXPhotonUsing(Photon* photon, Aexel* aexel) {
	return photon->aexel == aexel;
}

// Quark ====
Quark* AXQuarkCreate(Hadron* hadron, Aexel* aexel) {
	Quark* quark = (Quark*)malloc(sizeof(Quark));
	quark->hadron = hadron;
	quark->aexel = aexel;
	quark->pressure.x = 0;
	quark->pressure.y = 0;
	return quark;
}
void AXQuarkRelease(Quark* quark) {
	free(quark);
}
double AXQuarkPressure(Quark* quark, Aexel* aexel) {
	Vector pressure = {.x = quark->pressure.x + quark->hadron->v.x, .y = quark->pressure.y + quark->hadron->v.y};
	if (quark->aexel != aexel) {
		Vector t = AXVectorUnit(AXVectorSub(aexel->s, quark->aexel->s));
		pressure.x -= t.x;
		pressure.y -= t.y;
	}
	return AXVectorLength(pressure);
}
void AXQuarkMoveTo(Quark* quark, Aexel* aexel) {
	quark->pressure.x += quark->hadron->v.x;
	quark->pressure.y += quark->hadron->v.y;
	if (quark->aexel != aexel) {
		Vector t = AXVectorUnit(AXVectorSub(aexel->s, quark->aexel->s));
		quark->pressure.x -= t.x;
		quark->pressure.y -= t.y;
		quark->aexel = aexel;
	}
}

// Hadron ===
Hadron* AXHadronCreate(Aexel* aexel, byte anti) {
	Hadron* hadron = (Hadron*)malloc(sizeof(Hadron));
	
	hadron->anti = anti;
	hadron->center = 0;

	double theta = ((double)(arc4random() % 10000))/10000*2*M_PI;
	hadron->v.x = cos(theta)*0.0;
	hadron->v.y = sin(theta)*0.0;

	hadron->quarks[0].hadron = hadron;
	hadron->quarks[0].aexel = aexel;
	hadron->quarks[0].pressure.x = 0;
	hadron->quarks[0].pressure.y = 0;

	hadron->quarks[1].hadron = hadron;
	hadron->quarks[1].aexel = aexel;
	hadron->quarks[1].pressure.x = 0;
	hadron->quarks[1].pressure.y = 0;

	hadron->quarks[2].hadron = hadron;
	hadron->quarks[2].aexel = aexel;
	hadron->quarks[2].pressure.x = 0;
	hadron->quarks[2].pressure.y = 0;

	return hadron;
}
void AXHadronRelease(Hadron* hadron) {
	free(hadron);
}
double AXHadronPressure(Hadron* hadron, Aexel* a, Aexel* b, Aexel* c) {
	return	AXQuarkPressure(&hadron->quarks[0], a) +
			AXQuarkPressure(&hadron->quarks[1], b) +
			AXQuarkPressure(&hadron->quarks[2], c);
}
void AXHadronStep(Universe* universe, Hadron* hadron) {
	int min = -1;
	double pressure = 0;
	Aexel* mA = 0;
	Aexel* mB = 0;
	Aexel* mC = 0;

	for (int i=0;i<hadron->quarks[0].aexel->bondCount+1;i++) {
		Aexel* a = i<hadron->quarks[0].aexel->bondCount ? AXBondOtherAexel(hadron->quarks[0].aexel->bonds[i], hadron->quarks[0].aexel) : hadron->quarks[0].aexel;
//		if (AXUniverseUsing(universe, a) && !AXHadronUsing(hadron, a)) continue;
		
		for (int j=0;j<hadron->quarks[1].aexel->bondCount+1;j++) {
			Aexel* b = j<hadron->quarks[1].aexel->bondCount ? AXBondOtherAexel(hadron->quarks[1].aexel->bonds[j], hadron->quarks[1].aexel) : hadron->quarks[1].aexel;
//			if (AXUniverseUsing(universe, b) && !AXHadronUsing(hadron, b)) continue;

			for (int k=0;k<hadron->quarks[2].aexel->bondCount+1;k++) {
				Aexel* c = k<hadron->quarks[2].aexel->bondCount ? AXBondOtherAexel(hadron->quarks[2].aexel->bonds[k], hadron->quarks[2].aexel) : hadron->quarks[2].aexel;
//				if (AXUniverseUsing(universe, c) && !AXHadronUsing(hadron, c)) continue;

				int ab = AXAexelJumps(a, b);
				int bc = AXAexelJumps(b, c);
				int ca = AXAexelJumps(c, a);

				if (ab != -1 && bc != -1 && ca != -1) {
					int score = abs(ab-2)+abs(bc-2)+abs(ca-2);
					if (min == -1 || score < min) {
						min = score;
						pressure = AXHadronPressure(hadron, a, b, c);
						mA = a;mB = b;mC = c;
					} else if (score == min) {
						double test = AXHadronPressure(hadron, a, b, c);
						if (test < pressure) {
							pressure = test;
							mA = a;mB = b;mC = c;
						}
					}
				}
			}
		}
	}
	if (mA) {
		AXQuarkMoveTo(&hadron->quarks[0], mA);
		AXQuarkMoveTo(&hadron->quarks[1], mB);
		AXQuarkMoveTo(&hadron->quarks[2], mC);
	}
//	if (pressure > 11) {
//		hadron->v.x = -hadron->v.x;
//		hadron->v.y = -hadron->v.y;
//		hadron->quarks[0].pressure.x = 0;
//		hadron->quarks[0].pressure.y = 0;
//		hadron->quarks[1].pressure.x = 0;
//		hadron->quarks[1].pressure.y = 0;
//		hadron->quarks[2].pressure.x = 0;
//		hadron->quarks[2].pressure.y = 0;
//	}
}
byte AXHadronUsing(Hadron* hadron, Aexel* aexel) {
	return hadron->quarks[0].aexel == aexel || hadron->quarks[1].aexel == aexel || hadron->quarks[2].aexel == aexel || hadron->center == aexel;
}
// Sector ===
Sector* AXSectorCreate(void) {
	Sector* sector = (Sector*)malloc(sizeof(Sector));
	
	sector->aexelCount = 0;
	sector->aexels = (Aexel**)malloc(sizeof(Aexel*)*400);
	
	return sector;
}
void AXSectorRelease(Sector* sector) {
	free(sector->aexels);
	free(sector);
}

// Universe =
Universe* AXUniverseCreateAll(double width, double height, double relaxed, double snapped, double jump, int aexelCount, int photonCount, int hadronCount) {
	Universe* universe = (Universe*)malloc(sizeof(Universe));
	
	universe->width = width;
	universe->height = height;
	universe->relaxed = relaxed;
	universe->snapped = snapped;
	universe->jump = jump;
	universe->aexelCount = aexelCount;
	universe->aexels = (Aexel**)malloc(sizeof(Aexel*)*aexelCount);
	universe->photonCount = photonCount;
	universe->photons = (Photon**)malloc(sizeof(Photon*)*photonCount);
	universe->hadronCount = hadronCount;
	universe->hadrons = (Hadron**)malloc(sizeof(Hadron*)*hadronCount);
	
	universe->sectorWidth = 2+(int)ceil(universe->width/(universe->snapped*2));
	universe->sectorCount = universe->sectorWidth*(2+(int)ceil(universe->height/(universe->snapped*2)));
	universe->sectors = (Sector**)malloc(sizeof(Sector*)*universe->sectorCount);
	for (int i=0;i<universe->sectorCount;i++)
		universe->sectors[i] = AXSectorCreate();
	
	universe->bondCount = 0;
	universe->bonds = (Bond*)malloc(sizeof(Bond)*aexelCount*aexelCount);
	
	universe->gol = 0;
	
	return universe;
}
Universe* AXUniverseCreate(double width, double height, double relaxed, double snapped, double jump, int aexelCount, int photonCount, int hadronCount) {
	Universe* universe = AXUniverseCreateAll(width, height, relaxed, snapped, jump, aexelCount, photonCount, hadronCount);
	
	double aexelsLeft = aexelCount;
	double spacesLeft = width*height;
	double resolution = 1000000;
	int i = 0;
	for (int p=0;p<width;p++) {
		for (int q=0;q<height;q++) {
			double chance = (int)aexelsLeft/spacesLeft*resolution;
			double roll = arc4random() % (int)resolution;
			if (roll < chance) {
				universe->aexels[i++] = AXAexelCreate(p, q);
				aexelsLeft--;
			}
			spacesLeft--;
		}
	}
	
	AXUniverseBind(universe);
	
	for (int j=0;j<universe->photonCount;j++)
		universe->photons[j] = AXPhotonCreate(universe->aexels[arc4random() % universe->aexelCount]);
	
	for (int j=0;j<hadronCount;j++)
		universe->hadrons[j] = AXHadronCreate(universe->aexels[arc4random() % universe->aexelCount], j%2 == 0);
	
//	double r = 50;
//	Vector center = {.x = width/2, .y = width/2};
//	Vector a = {.x = width/2+r*cos(2*M_PI*1/6), .y = width/2+r*sin(2*M_PI*1/6)};
//	Vector b = {.x = width/2+r*cos(2*M_PI*2/6), .y = width/2+r*sin(2*M_PI*2/6)};
//	Vector c = {.x = width/2+r*cos(2*M_PI*3/6), .y = width/2+r*sin(2*M_PI*3/6)};
//	Vector d = {.x = width/2+r*cos(2*M_PI*4/6), .y = width/2+r*sin(2*M_PI*4/6)};
//	Vector e = {.x = width/2+r*cos(2*M_PI*5/6), .y = width/2+r*sin(2*M_PI*5/6)};
//	Vector f = {.x = width/2+r*cos(2*M_PI*6/6), .y = width/2+r*sin(2*M_PI*6/6)};
//	r = 300;
//	Vector u = {.x = width/2+r*cos(2*M_PI*1/6), .y = width/2+r*sin(2*M_PI*1/6)};
//	Vector v = {.x = width/2+r*cos(2*M_PI*2/6), .y = width/2+r*sin(2*M_PI*2/6)};
//	Vector w = {.x = width/2+r*cos(2*M_PI*3/6), .y = width/2+r*sin(2*M_PI*3/6)};
//	Vector x = {.x = width/2+r*cos(2*M_PI*4/6), .y = width/2+r*sin(2*M_PI*4/6)};
//	Vector y = {.x = width/2+r*cos(2*M_PI*5/6), .y = width/2+r*sin(2*M_PI*5/6)};
//	Vector z = {.x = width/2+r*cos(2*M_PI*6/6), .y = width/2+r*sin(2*M_PI*6/6)};
//
//	double o = 0.03;
	
//	universe->hadrons[0] = AXHadronCreate(AXUniverseAexelNear(universe, a), 0);
//	universe->hadrons[1] = AXHadronCreate(AXUniverseAexelNear(universe, b), 0);
//	universe->hadrons[2] = AXHadronCreate(AXUniverseAexelNear(universe, c), 0);
//	universe->hadrons[3] = AXHadronCreate(AXUniverseAexelNear(universe, d), 0);
//	universe->hadrons[4] = AXHadronCreate(AXUniverseAexelNear(universe, e), 0);
//	universe->hadrons[5] = AXHadronCreate(AXUniverseAexelNear(universe, f), 0);
//	universe->hadrons[6] = AXHadronCreate(AXUniverseAexelNear(universe, u), 1);
//	universe->hadrons[7] = AXHadronCreate(AXUniverseAexelNear(universe, v), 1);
//	universe->hadrons[8] = AXHadronCreate(AXUniverseAexelNear(universe, w), 1);
//	universe->hadrons[9] = AXHadronCreate(AXUniverseAexelNear(universe, x), 1);
//	universe->hadrons[10] = AXHadronCreate(AXUniverseAexelNear(universe, y), 1);
//	universe->hadrons[11] = AXHadronCreate(AXUniverseAexelNear(universe, z), 1);
//
//	universe->hadrons[6]->v = AXVectorMul(AXVectorUnit(AXVectorSub(a, center)), o);
//	universe->hadrons[7]->v = AXVectorMul(AXVectorUnit(AXVectorSub(b, center)), o);
//	universe->hadrons[8]->v = AXVectorMul(AXVectorUnit(AXVectorSub(c, center)), o);
//	universe->hadrons[9]->v = AXVectorMul(AXVectorUnit(AXVectorSub(d, center)), o);
//	universe->hadrons[10]->v = AXVectorMul(AXVectorUnit(AXVectorSub(e, center)), o);
//	universe->hadrons[11]->v = AXVectorMul(AXVectorUnit(AXVectorSub(f, center)), o);
	
	return universe;
}
void AXUniverseRelease(Universe* universe) {
	for (int i=0;i<universe->sectorCount;i++) {AXSectorRelease(universe->sectors[i]);}
	free(universe->sectors);
	
	for (int i=0;i<universe->aexelCount;i++) {AXAexelRelease(universe->aexels[i]);}
	free(universe->aexels);
	
	for (int i=0;i<universe->photonCount;i++) {AXPhotonRelease(universe->photons[i]);}
	free(universe->photons);
	
	for (int i=0;i<universe->hadronCount;i++) {AXHadronRelease(universe->hadrons[i]);}
	free(universe->hadrons);
	
	free(universe->bonds);
	free(universe);
}
byte AXUniverseUsing(Universe* universe, Aexel* aexel) {
	for (int i=0;i<universe->photonCount;i++) {
		if (AXPhotonUsing(universe->photons[i], aexel)) return 1;
	}
	for (int i=0;i<universe->hadronCount;i++) {
		if (AXHadronUsing(universe->hadrons[i], aexel)) return 1;
	}
	return 0;
}
void AXUniverseHadronFindCenter(Universe* universe, Hadron* hadron) {
	Vector center = {
		.x = (hadron->quarks[0].aexel->s.x+hadron->quarks[1].aexel->s.x+hadron->quarks[2].aexel->s.x)/3,
		.y = (hadron->quarks[0].aexel->s.y+hadron->quarks[1].aexel->s.y+hadron->quarks[2].aexel->s.y)/3
	};
	double min = -1;
	Aexel* aexel = 0;
	hadron->center = 0;
	for (int j=0;j<3;j++) {
		Aexel* quarkAexel = hadron->quarks[j].aexel;
		for (int k=0;k<quarkAexel->bondCount;k++) {
			Aexel* maybe = AXBondOtherAexel(quarkAexel->bonds[k], quarkAexel);
			if (maybe == 0 || AXUniverseUsing(universe, maybe)) continue;
			Vector delta = AXVectorSub(center, maybe->s);
			double lengthSquared = delta.x*delta.x + delta.y*delta.y;
			if (min == -1 || lengthSquared < min) {
				min = lengthSquared;
				aexel = maybe;
			}
		}
	}
	hadron->center = aexel;
}
//clock_t yo (clock_t n) {
//	if (n == 0) return 0;
//	return (int)(1.0/((double)n/(double)CLOCKS_PER_SEC));
//}

void AXUniverseDemarcate(Universe* universe) {
	for (int i=0;i<universe->sectorCount;i++) {
		Sector* sector = universe->sectors[i];
		sector->aexelCount = 0;
	}
	double sectionLength = universe->snapped*2;
	for (int i=0;i<universe->aexelCount;i++) {
		Aexel* aexel = universe->aexels[i];
		int x = (int)((aexel->s.x + sectionLength)/sectionLength);
		int y = (int)((aexel->s.y + sectionLength)/sectionLength);
		Sector* sector = universe->sectors[y*universe->sectorWidth+x];
		sector->aexels[sector->aexelCount++] = aexel;
		int qx = (int)((aexel->s.x + sectionLength/2)/sectionLength);
		int qy = (int)((aexel->s.y + sectionLength/2)/sectionLength);
		aexel->oldIndex = aexel->sectorIndex;
		aexel->sectorIndex = qy*universe->sectorWidth+qx;
	}
}
void AXUniverseWipeBondsFor(Universe* universe, Aexel* aexel) {
	for (int i=0;i<universe->bondCount;i++) {
		if (universe->bonds[i].a == aexel || universe->bonds[i].b == aexel) {
			universe->bondCount--;
			if (i != universe->bondCount) {
				universe->bonds[i] = universe->bonds[universe->bondCount];
				i--;
			}
		}
	}
}
void AXUniverseBuildBondsFor(Universe* universe, Aexel* aexel) {
	int sectorIndexes[] = {
		aexel->sectorIndex,
		aexel->sectorIndex+1,
		aexel->sectorIndex+universe->sectorWidth,
		aexel->sectorIndex+universe->sectorWidth+1
	};
	
	for (int i=0;i<4;i++) {
		Sector* sector = universe->sectors[sectorIndexes[i]];
		for (int j=0;j<sector->aexelCount;j++) {
			Aexel* other = sector->aexels[j];
			if (aexel == other) continue;
			
//			int exists = 0;
//
//			for (int k=0;k<aexel->bondCount;k++) {
//				if (AXBondOtherAexel(aexel->bonds[k], aexel) == other)
//					exists = 1;
//			}
//			if (exists) continue;
//
//			for (int k=0;k<other->bondCount;k++) {
//				if (AXBondOtherAexel(other->bonds[k], other) == aexel)
//					exists = 1;
//			}
//			if (exists) continue;
			
//			double dx = aexel->s.x - other->s.x;
//			double dy = aexel->s.y - other->s.y;
//			double lengthSquared = dx*dx + dy*dy;
			
//			if (lengthSquared > snappedSquared) continue;
			
			int k = universe->bondCount++;
			universe->bonds[k] = (Bond){aexel, other, 0.0, 0};
						
//			aexel->bonds[aexel->bondCount++] = universe->bonds[k];
//			other->bonds[other->bondCount++] = universe->bonds[k];
		}
	}
//	printf("###] %d\n", universe->bondCount);
}
Aexel* AXUniverseAexelNear(Universe* universe, Vector v) {
	double min = -1;
	Aexel* aexel = 0;
	for (int i=0;i<universe->aexelCount;i++) {
		Vector delta = AXVectorSub(v, universe->aexels[i]->s);
		double lengthSquared = delta.x*delta.x + delta.y*delta.y;
		if (min == -1 || lengthSquared < min) {
			min = lengthSquared;
			aexel = universe->aexels[i];
		}
	}
	return aexel;
}

void AXUniverseGOLStep(Universe* universe);

void AXUniverseStep(Universe* universe) {
	for (int i=0;i<universe->photonCount;i++) {
		AXPhotonStep(universe->photons[i]);
	}
	for (int i=0;i<universe->hadronCount;i++) {
		AXHadronStep(universe, universe->hadrons[i]);
		if (!universe->hadrons[i]->anti)
			AXUniverseHadronFindCenter(universe, universe->hadrons[i]);
	}
}

void AXUniverseJump(Universe* universe) {
	for (int i=0;i<universe->aexelCount;i++) {
		Aexel* aexel = universe->aexels[i];
		double nx = 0;
		double ny = 0;
		for (int j=0;j<aexel->bondCount;j++) {
			double dx = AXBondOtherAexel(aexel->bonds[j], aexel)->s.x - aexel->s.x;
			double dy = AXBondOtherAexel(aexel->bonds[j], aexel)->s.y - aexel->s.y;
			double length = sqrt(dx*dx+dy*dy);
			double stretch = universe->relaxed - length;
//			if (stretch < 0) stretch /= 20;
//			else stretch *= 1;
			nx += -dx/length*stretch;
			ny += -dy/length*stretch;
		}
		aexel->ds.x = nx*universe->jump;
		aexel->ds.y = ny*universe->jump;
	}
	for (int i=0;i<universe->aexelCount;i++) {
		universe->aexels[i]->s.x += universe->aexels[i]->ds.x;
		universe->aexels[i]->s.y += universe->aexels[i]->ds.y;
	}
}

void AXUniverseWarp(Universe* universe) {
	static int n = -1;
	static Aexel** recycle = 0;
	
	if (n == -1) {
		n = universe->hadronCount/2;
		recycle = (Aexel**)malloc(sizeof(Aexel*)*n);
	} else if (n < universe->hadronCount/2) {
		n = universe->hadronCount/2;
		recycle = (Aexel**)realloc(recycle, sizeof(Aexel*)*n);
	}
	
	int s = 0;
	for (int i=0;i<universe->hadronCount;i++) {
		Hadron* hadron = universe->hadrons[i];
		if (hadron->anti) continue;
		if (hadron->center) {
			recycle[s++] = hadron->center;
			hadron->center = 0;
		}
	}
	for (int i=0;i<universe->hadronCount;i++) {
		Hadron* hadron = universe->hadrons[i];
		if (!hadron->anti) continue;
		Vector center = {
			.x = (hadron->quarks[0].aexel->s.x + hadron->quarks[1].aexel->s.x + hadron->quarks[2].aexel->s.x)/3,
			.y = (hadron->quarks[0].aexel->s.y + hadron->quarks[1].aexel->s.y + hadron->quarks[2].aexel->s.y)/3
		};

		if (s > 0) {
			Aexel* aexel = recycle[--s];
			aexel->s = center;
		}
	}
}

void AXUniverseBind(Universe* universe) {
	double snapped = universe->snapped;
	double snappedSquared = snapped*snapped;
	
	AXUniverseDemarcate(universe);
	
	for (int i=0;i<universe->aexelCount;i++) {
		Aexel* aexel = universe->aexels[i];
		if (aexel->sectorIndex == aexel->oldIndex) continue;
		AXUniverseWipeBondsFor(universe, aexel);
		AXUniverseBuildBondsFor(universe, aexel);
	}
	
	for (int i=0;i<universe->bondCount;i++) {
		double dx = universe->bonds[i].a->s.x - universe->bonds[i].b->s.x;
		double dy = universe->bonds[i].a->s.y - universe->bonds[i].b->s.y;
		
		universe->bonds[i].lengthSquared = dx*dx + dy*dy;
		universe->bonds[i].hot = universe->bonds[i].lengthSquared <= snappedSquared;
	}

	for (int i=0;i<universe->aexelCount;i++)
		universe->aexels[i]->bondCount = 0;
	for (int i=0;i<universe->bondCount;i++) {
		if (!universe->bonds[i].hot) continue;
		universe->bonds[i].a->bonds[universe->bonds[i].a->bondCount++] = universe->bonds[i];
		universe->bonds[i].b->bonds[universe->bonds[i].b->bondCount++] = universe->bonds[i];
	}

	for (int i=0;i<universe->bondCount;i++) {
		
		if (!universe->bonds[i].hot) continue;
		
		Bond bond = universe->bonds[i];
		
//		printf("(%lf, %lf)-(%lf, %lf)\n", bond.a->s.x, bond.a->s.y, bond.b->s.x, bond.b->s.y);
		
		Aexel* aexel = bond.a;
		
		for (int j=0;j<aexel->bondCount;j++) {
			Aexel* other = AXBondOtherAexel(aexel->bonds[j], aexel);
			if (other == bond.b) continue;
			for (int k=0;k<other->bondCount;k++) {
				Bond test = other->bonds[k];
//				if (!test.hot) continue;
				if (test.lengthSquared > bond.lengthSquared) continue;
				if (AXBondCrosses(bond, test)) {
					universe->bonds[i].hot = 0;
					goto BLOCKED;
				}
			}
		}
		
		aexel = bond.b;
		
		for (int j=0;j<aexel->bondCount;j++) {
			Aexel* other = AXBondOtherAexel(aexel->bonds[j], aexel);
			if (other == bond.a) continue;
			for (int k=0;k<other->bondCount;k++) {
				Bond test = other->bonds[k];
//				if (!test.hot) continue;
				if (test.lengthSquared > bond.lengthSquared) continue;
				if (AXBondCrosses(bond, test)) {
					universe->bonds[i].hot = 0;
					goto BLOCKED;
				}
			}
		}
		
		BLOCKED:
		aexel = 0;
	}
	
	for (int i=0;i<universe->aexelCount;i++)
		universe->aexels[i]->bondCount = 0;
	for (int i=0;i<universe->bondCount;i++) {
		if (!universe->bonds[i].hot) continue;
		universe->bonds[i].a->bonds[universe->bonds[i].a->bondCount++] = universe->bonds[i];
		universe->bonds[i].b->bonds[universe->bonds[i].b->bondCount++] = universe->bonds[i];
	}
}

int tic = 1;

void AXUniverseGOLStep(Universe* universe) {
	for (int i=0;i<universe->aexelCount;i++)
		universe->aexels[i]->stateB = universe->aexels[i]->stateA;
	for (int i=0;i<universe->aexelCount;i++) {
		Aexel* aexel = universe->aexels[i];
		int sum = 0;
		for (int j=0;j<aexel->bondCount;j++)
			sum += AXBondOtherAexel(aexel->bonds[j], aexel)->stateB;
		aexel->stateA = ((aexel->stateB && sum == 2) || sum == 3) ? 1 : 0;
	}
}

void AXUniverseTic(Universe* universe) {
//	if (tic % 7 == 0)
//		AXUniverseStep(universe);
	AXUniverseJump(universe);
//	if (tic % 10 == 0)
//		AXUniverseWarp(universe);
	AXUniverseBind(universe);
	if (tic % 17 == 0)
		AXUniverseGOLStep(universe);
	tic++;
}

void test() {
	int sortedList[] = {3,4,5};
	int element = 5;
	int index = 0;
	while (sortedList[index] != element && 3 > ++index);
	int answer = index < 3 ? index : -1;
	printf("@@@ answer [%d]\n", answer);
}