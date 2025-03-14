//
//  Sea.h
//  Aexels
//
//  Created by Joe Charlier on 3/14/25.
//  Copyright © 2025 Aepryus Software. All rights reserved.
//

typedef struct CV2 {
    double x;
    double y;
} CV2;

CV2 CV2Add(CV2 a, CV2 b);
CV2 CV2Neg(CV2 a);
double CV2LengthSquared(CV2 a);
double CV2Length(CV2 a);
double CV2Orient(CV2 a);
double CV2Gamma(CV2 a);
double CV2Dot(CV2 a, CV2 b);
CV2 CV2ofLength(CV2 a, double b);
