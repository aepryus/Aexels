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
byte AXVectorCrosses_Claude(Vector a1, Vector a2, Vector b1, Vector b2) {
    // Fast bounding box rejection test
    double a_min_x = a1.x < a2.x ? a1.x : a2.x;
    double a_max_x = a1.x > a2.x ? a1.x : a2.x;
    double a_min_y = a1.y < a2.y ? a1.y : a2.y;
    double a_max_y = a1.y > a2.y ? a1.y : a2.y;
    
    double b_min_x = b1.x < b2.x ? b1.x : b2.x;
    double b_max_x = b1.x > b2.x ? b1.x : b2.x;
    double b_min_y = b1.y < b2.y ? b1.y : b2.y;
    double b_max_y = b1.y > b2.y ? b1.y : b2.y;
    
    // If bounding boxes don't overlap, segments can't intersect
    if (a_max_x < b_min_x || b_max_x < a_min_x ||
        a_max_y < b_min_y || b_max_y < a_min_y) {
        return 0;
    }
    
    // Compute vectors
    double v1x = a2.x - a1.x;
    double v1y = a2.y - a1.y;
    double v2x = b2.x - b1.x;
    double v2y = b2.y - b1.y;
    
    // Compute cross products
    double cross_v1_v2 = v1x * v2y - v1y * v2x;
    
    // If cross product is zero, segments are parallel
    if (fabs(cross_v1_v2) < 1e-10) {
        // Check if segments are collinear
        double cross_v1_diff = v1x * (b1.y - a1.y) - v1y * (b1.x - a1.x);
        if (fabs(cross_v1_diff) > 1e-10) {
            return 0;  // Parallel but not collinear
        }
        
        // Collinear case - check if segments overlap
        // Project onto x-axis if segment is more horizontal, y-axis if more vertical
        if (fabs(v1x) > fabs(v1y)) {
            // Project onto x-axis
            double t0 = (b1.x - a1.x) / v1x;
            double t1 = (b2.x - a1.x) / v1x;
            if (v1x < 0) { double tmp = t0; t0 = t1; t1 = tmp; }
            return (t0 <= 1.0 && t1 >= 0.0);
        } else {
            // Project onto y-axis
            double t0 = (b1.y - a1.y) / v1y;
            double t1 = (b2.y - a1.y) / v1y;
            if (v1y < 0) { double tmp = t0; t0 = t1; t1 = tmp; }
            return (t0 <= 1.0 && t1 >= 0.0);
        }
    }
    
    // Not parallel - compute parameters for both lines
    double vdx = a1.x - b1.x;
    double vdy = a1.y - b1.y;
    
    double t1 = (v2x * vdy - v2y * vdx) / cross_v1_v2;
    double t2 = (v1x * vdy - v1y * vdx) / cross_v1_v2;
    
    // Check if intersection point is within both segments
    return (t1 >= 0.0 && t1 <= 1.0 && t2 >= 0.0 && t2 <= 1.0);
}

#define MAXNEIGHBOR 6
// Aexel ====
ICAexel* ICAexelCreate(double x, double y) {
	ICAexel* aexel = (ICAexel*)malloc(sizeof(ICAexel));
	
	aexel->s.x = x;
	aexel->s.y = y;
	
	aexel->sectorIndex = -1;
	aexel->oldIndex = -1;

	aexel->bondCount = 0;
	aexel->bonds = (Bond*)malloc(sizeof(Bond)*100);
	
	aexel->stateA = arc4random() % 2;
	aexel->stateB = 0;
    aexel->stateC = 0;

	return aexel;
}
void ICAexelRelease(ICAexel* aexel) {
	free(aexel->bonds);
	free(aexel);
}
byte ICAexelWithin(ICAexel* a, ICAexel* b, int within) {
	if (a == 0 || b == 0) return 0;
	if (a == b) return 1;
	if (within == 0) return 0;
	for (int i=0;i<a->bondCount;i++) {
		if (ICAexelWithin(AXBondOtherAexel(a->bonds[i], a), b, within-1)) return 1;
	}
	return 0;
}
int ICAexelJumps(ICAexel* a, ICAexel* b) {
	for (int i=0;i<8;i++) {
		if (ICAexelWithin(a, b, i)) return i;
	}
	return -1;
}

// Bond =====
Bond* AXBondCreate(ICAexel* a, ICAexel* b) {
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
ICAexel* AXBondOtherAexel(Bond bond, ICAexel* aexel) {
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

// Sector ===
Sector* AXSectorCreate(void) {
	Sector* sector = (Sector*)malloc(sizeof(Sector));
	
	sector->aexelCount = 0;
	sector->aexels = (ICAexel**)malloc(sizeof(ICAexel*)*400);
	
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
	universe->aexels = (ICAexel**)malloc(sizeof(ICAexel*)*aexelCount);
	
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
				universe->aexels[i++] = ICAexelCreate(p, q);
				aexelsLeft--;
			}
			spacesLeft--;
		}
	}
	
	AXUniverseBind(universe);
	
	return universe;
}
Universe* AXUniverseCreateE(double width, double height, double relaxed) {
    Universe* universe = AXUniverseCreateAll(width, height, relaxed, relaxed*2, 0.1, 9, 0, 0);
    
    double dx = 0;
    for (int i=0;i<9;i++) {
        universe->aexels[i] = ICAexelCreate(width/2, height*0.25+dx);
        dx += height*0.5 / 8.0;
    }

    AXUniverseBind(universe);
    
    return universe;
}
Universe* AXUniverseCreateF(double width, double height, double relaxed) {
    int n = 4;
    int m = 5;
    
    Universe* universe = AXUniverseCreateAll(width, height, relaxed, relaxed*2, 0.1, n*m-((n-2)*(m-2)), 0, 0);
    
    double x0 = width * 0.25;
    double dx = width * 0.5 / ((double)n - 1);
    double x = x0;
    
    double y0 = height * 0.2;
    double dy = height * 0.6 / ((double)m - 1);
    double y = y0;
    
    int k=0;
    
    x = x0;
    for (int i=0; i<n; i++) {
        universe->aexels[k] = ICAexelCreate(x, y);
        x += dx;
        k++;
    }
    
    for (int j=1; j<m-1; j++) {
        y += dy;
        universe->aexels[k] = ICAexelCreate(x0, y);
        k++;
        universe->aexels[k] = ICAexelCreate(x0+((double)n-1)*dx, y);
        k++;
    }
    
    x = x0;
    y += dy;
    for (int i=0; i<n; i++) {
        universe->aexels[k] = ICAexelCreate(x, y);
        x += dx;
        k++;
    }

    AXUniverseBind(universe);
    
    return universe;
}
Universe* AXUniverseCreateG(double width, double height, double relaxed) {
    int n = 4;
    int m = 5;

    Universe* universe = AXUniverseCreateAll(width, height, relaxed, relaxed*2, 0.1, n*m, 0, 0);
    
    double x0 = width * 0.25;
    double dx = width * 0.5 / ((double)n - 1);
    double x = x0;
    
    double y0 = height * 0.2;
    double dy = height * 0.6 / ((double)m - 1);
    double y = y0;
    
    for (int j=0; j<m; j++) {
        for (int i=0; i<n; i++) {
            universe->aexels[j*n+i] = ICAexelCreate(x, y);
            x += dx;
        }
        x = x0;
        y += dy;
    }

    AXUniverseBind(universe);
    
    return universe;
}
Universe* AXUniverseCreateH(double width, double height, double relaxed) {
    int n = 20;

    Universe* universe = AXUniverseCreateAll(width, height, relaxed, relaxed*2, 0.1, n, 0, 0);
    
    double r = width * 0.3;
    double dq = 2*M_PI/((double)n-1);
    double q = 0;
    
    for (int i=0;i<n;i++) {
        double x = width/2 + r*sin(q);
        double y = height/2 + r*cos(q);
        universe->aexels[i] = ICAexelCreate(x, y);
        q += dq;
    }

    AXUniverseBind(universe);
    
    return universe;
}
Universe* AXUniverseCreateI(double width, double height, double relaxed) {
    int n = 16;
    int m = 5;

    Universe* universe = AXUniverseCreateAll(width, height, relaxed, relaxed*2, 0.1, n*m, 0, 0);
    
    double r0 = width * 0.5;
    double dr = -r0/((double)m-0);
    double r = r0;
    
    double q0 = 0;
    double dq = 2*M_PI/((double)n-1);
    double q = 0;
    
    for (int j=0;j<m;j++) {
        for (int i=0;i<n;i++) {
            double x = width/2 + r*sin(q);
            double y = height/2 + r*cos(q);
            universe->aexels[j*n+i] = ICAexelCreate(x, y);
            q += dq;
        }
        q = q0;
        r += dr;
    }

    AXUniverseBind(universe);
    
    return universe;
}
Universe* AXUniverseCreateJ(double width, double height, double relaxed) {
    return AXUniverseCreateAll(width, height, relaxed, relaxed*2, 0.1, 0, 0, 0);
}
void AXUniverseRelease(Universe* universe) {
	for (int i=0;i<universe->sectorCount;i++) {AXSectorRelease(universe->sectors[i]);}
	free(universe->sectors);
	
	for (int i=0;i<universe->aexelCount;i++) {ICAexelRelease(universe->aexels[i]);}
	free(universe->aexels);
	
	free(universe->bonds);
	free(universe);
}

void AXUniverseDemarcate(Universe* universe) {
	for (int i=0;i<universe->sectorCount;i++) {
		Sector* sector = universe->sectors[i];
		sector->aexelCount = 0;
	}
	double sectionLength = universe->snapped*2;
	for (int i=0;i<universe->aexelCount;i++) {
		ICAexel* aexel = universe->aexels[i];
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
void AXUniverseWipeBondsFor(Universe* universe, ICAexel* aexel) {
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
void AXUniverseBuildBondsFor(Universe* universe, ICAexel* aexel) {
	int sectorIndexes[] = {
		aexel->sectorIndex,
		aexel->sectorIndex+1,
		aexel->sectorIndex+universe->sectorWidth,
		aexel->sectorIndex+universe->sectorWidth+1
	};
	
	for (int i=0;i<4;i++) {
		Sector* sector = universe->sectors[sectorIndexes[i]];
		for (int j=0;j<sector->aexelCount;j++) {
			ICAexel* other = sector->aexels[j];
			if (aexel == other) continue;
			
			int k = universe->bondCount++;
			universe->bonds[k] = (Bond){aexel, other, 0.0, 0};
		}
	}
}
ICAexel* AXUniverseAexelNear(Universe* universe, Vector v) {
	double min = -1;
	ICAexel* aexel = 0;
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

void AXUniverseJump(Universe* universe) {
	for (int i=0;i<universe->aexelCount;i++) {
		ICAexel* aexel = universe->aexels[i];
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
        if (universe->aexels[i]->stateC == 1) continue;
		universe->aexels[i]->s.x += universe->aexels[i]->ds.x;
		universe->aexels[i]->s.y += universe->aexels[i]->ds.y;
	}
}

void AXUniverseBind(Universe* universe) {
	double snapped = universe->snapped;
	double snappedSquared = snapped*snapped;
	
	AXUniverseDemarcate(universe);
	
	for (int i=0;i<universe->aexelCount;i++) {
		ICAexel* aexel = universe->aexels[i];
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
		
		ICAexel* aexel = bond.a;
		
		for (int j=0;j<aexel->bondCount;j++) {
			ICAexel* other = AXBondOtherAexel(aexel->bonds[j], aexel);
			if (other == bond.b) continue;
			for (int k=0;k<other->bondCount;k++) {
				Bond test = other->bonds[k];
				if (test.lengthSquared > bond.lengthSquared) continue;
				if (AXBondCrosses(bond, test)) {
					universe->bonds[i].hot = 0;
					goto BLOCKED;
				}
			}
		}
		
		aexel = bond.b;
		
		for (int j=0;j<aexel->bondCount;j++) {
			ICAexel* other = AXBondOtherAexel(aexel->bonds[j], aexel);
			if (other == bond.a) continue;
			for (int k=0;k<other->bondCount;k++) {
				Bond test = other->bonds[k];
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
		ICAexel* aexel = universe->aexels[i];
		int sum = 0;
		for (int j=0;j<aexel->bondCount;j++)
			sum += AXBondOtherAexel(aexel->bonds[j], aexel)->stateB;
		aexel->stateA = ((aexel->stateB && sum == 2) || sum == 3) ? 1 : 0;
	}
}

void AXUniverseTic(Universe* universe) {
	AXUniverseJump(universe);
	AXUniverseBind(universe);
	if (tic % 17 == 0)
		AXUniverseGOLStep(universe);
	tic++;
}

void AXUniverseAddAexel(Universe* universe, double x, double y) {
    universe->aexelCount++;
    universe->aexels = (ICAexel**)realloc(universe->aexels, sizeof(ICAexel*)*universe->aexelCount);
    universe->bonds = (Bond*)realloc(universe->bonds, sizeof(Bond)*universe->aexelCount*universe->aexelCount);
    universe->aexels[universe->aexelCount-1] = ICAexelCreate(x, y);
}

void AXUniverseRemoveAexel(Universe* universe, ICAexel* aexel) {
    int i = 0;
    while (i < universe->aexelCount) {
        if (universe->aexels[i] == aexel) break;
        i++;
    }
    AXUniverseWipeBondsFor(universe, universe->aexels[i]);
    while (i+1 < universe->aexelCount) {
        universe->aexels[i] = universe->aexels[i+1];
        i++;
    }
    universe->aexelCount--;
    universe->aexels = (ICAexel**)realloc(universe->aexels, sizeof(ICAexel*)*universe->aexelCount);
    universe->bonds = (Bond*)realloc(universe->bonds, sizeof(Bond)*universe->aexelCount*universe->aexelCount);
}
