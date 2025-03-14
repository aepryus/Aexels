//
//  Sea.c
//  Aexels
//
//  Created by Joe Charlier on 3/14/25.
//  Copyright © 2025 Aepryus Software. All rights reserved.
//

#import <math.h>
#include "Sea.h"

// CV2 =============================================================================================
CV2 CV2Add(CV2 a, CV2 b) {
    CV2 c = {a.x + b.x, a.y + b.y};
    return c;
}
CV2 CV2Neg(CV2 a) {
    CV2 b = {-a.x, -a.y};
    return b;
}
double CV2LengthSquared(CV2 a) {
    return a.x*a.x+a.y*a.y;
}
double CV2Length(CV2 a) {
    return sqrt(a.x*a.x+a.y*a.y);
}
double CV2Orient(CV2 a) {
    return atan2(a.y, a.x);
}
double CV2Gamma(CV2 a) {
    return 1/sqrt(1 - (a.x*a.x+a.y*a.y));
}
double CV2Dot(CV2 a, CV2 b) {
    return a.x*b.x+a.y*b.y;
}
CV2 CV2ofLength(CV2 a, double b) {
    double r = b/CV2Length(a);
    CV2 result = {a.x*r, a.y*r};
    return result;
}
