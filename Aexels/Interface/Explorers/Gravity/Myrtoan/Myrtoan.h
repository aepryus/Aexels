//
//  Myrtoan.h
//  Aexels
//
//  Created by Joe Charlier on 8/16/23.
//  Copyright © 2023 Aepryus Software. All rights reserved.
//

// MY = Myrtoan Sea

#import "Ionian.h"

// Slice ========
typedef struct MYSlice {
    double y;
    double vy;
    byte evenOdd;
    byte replicated;
    byte destroyed;
} MYSlice;

// Quark ========
typedef struct MYQuark {
    MYSlice* slice;
    int x;
} MYQuark;

// Universe =====
typedef struct MYUniverse {
    double width;
    double height;
    double g;
    double dx;
    int sliceCount;
    MYSlice** slices;
    int destroyed;
} MYUniverse;

MYUniverse* MYUniverseCreate(double width, double height, double dx, double g);
void MYUniverseRelease(MYUniverse* universe);
void MYUniverseTic(MYUniverse* universe);
MYSlice* MYUniverseCreateSlice(MYUniverse* universe, double y, double vy, byte evenOdd);
