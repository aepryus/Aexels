//
//  Sea.h
//  Aexels
//
//  Created by Joe Charlier on 3/14/25.
//  Copyright © 2025 Aepryus Software. All rights reserved.
//

// C = Sea : Shared

typedef unsigned char bool;
#define true 1
#define false 0

typedef struct CV2 {
    double x;
    double y;
} CV2;

CV2 CV2Add(CV2 a, CV2 b);
CV2 CV2Sub(CV2 a, CV2 b);
CV2 CV2Neg(CV2 a);
CV2 CV2Mul(CV2 a, double b);
CV2 CV2Div(CV2 a, double b);
double CV2LengthSquared(CV2 a);
double CV2Length(CV2 a);
double CV2Orient(CV2 a);
double CV2Gamma(CV2 a);
double CV2Dot(CV2 a, CV2 b);
CV2 CV2ofLength(CV2 a, double b);
bool CV2LinesCross(CV2 a1, CV2 a2, CV2 b1, CV2 b2);
