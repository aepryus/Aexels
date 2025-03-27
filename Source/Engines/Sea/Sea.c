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
CV2 CV2Sub(CV2 a, CV2 b) {
    CV2 c = {a.x - b.x, a.y - b.y};
    return c;
}
CV2 CV2Neg(CV2 a) {
    CV2 b = {-a.x, -a.y};
    return b;
}
CV2 CV2Mul(CV2 a, double b) {
    CV2 c = {a.x*b, a.y*b};
    return c;
}
CV2 CV2Div(CV2 a, double b) {
    CV2 c = {a.x/b, a.y/b};
    return c;
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

bool CV2Includes(CV2 a1, CV2 a2, CV2 v) {
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
bool CV2LinesCross(CV2 a1, CV2 a2, CV2 b1, CV2 b2) {
    CV2 A = CV2Sub(a2, a1);
    CV2 B = CV2Sub(b2, b1);
    
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
        return CV2Includes(a1, a2, b1) || CV2Includes(a1, a2, b2) || CV2Includes(b1 ,b2, a1) || CV2Includes(b1, b2, a2);
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
