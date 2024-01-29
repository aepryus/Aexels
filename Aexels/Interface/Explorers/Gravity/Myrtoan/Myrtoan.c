//
//  Myrtoan.c
//  Aexels
//
//  Created by Joe Charlier on 8/16/23.
//  Copyright © 2023 Aepryus Software. All rights reserved.
//

//#import <math.h>
#import <stdio.h>
#import <stdlib.h>
#include "Myrtoan.h"

// Slice ===========================================================================================
MYSlice* MYSliceCreate(void) {
    MYSlice* slice = (MYSlice*)malloc(sizeof(MYSlice));
    return slice;
}
void MYSliceRelease(MYSlice* slice) {
    free(slice);
}

// Universe ========================================================================================
MYUniverse* MYUniverseCreate(double width, double height, double dx, double g) {
    MYUniverse* universe = (MYUniverse*)malloc(sizeof(MYUniverse));
    
    universe->width = width;
    universe->height = height;
    universe->dx = dx;
    universe->g = g;
    universe->destroyed = -1;
    
    universe->sliceCount = 0;
    universe->slices = (MYSlice**)malloc(sizeof(MYSlice*)*0);
    
    return universe;
}
void MYUniverseRelease(MYUniverse* universe) {
    if (universe == 0) return;
    free(universe->slices);
    free(universe);
}
void MYUniverseTic(MYUniverse* universe) {
    for (int i=0;i<universe->sliceCount;i++) {
        MYSlice* slice = universe->slices[i];
        slice->y += slice->vy/60;
        slice->vy *= 0.9985;
//        slice->vy += universe->g/60;
    }
    for (int i=0;i<universe->sliceCount;i++) {
        MYSlice* slice = universe->slices[i];
        if (!slice->replicated && slice->y > universe->dx) {
            slice->replicated = 1;
            if (universe->destroyed == -1) {
                MYUniverseCreateSlice(universe, 0, 100, !slice->evenOdd);
            } else {
                MYSlice* newSlice = universe->slices[universe->destroyed];
                universe->destroyed = -1;
                newSlice->destroyed = 0;
                newSlice->y = 0;
                newSlice->vy = 100;
                newSlice->replicated = 0;
                newSlice->evenOdd = !slice->evenOdd;
            }
        }
        if (slice->y > universe->height) {
            slice->destroyed = 1;
            universe->destroyed = i;
        }
    }
}

void MYUniverseAddSlice(MYUniverse* universe, MYSlice* slice) {
    universe->sliceCount++;
    universe->slices = (MYSlice**)realloc(universe->slices, sizeof(MYSlice*)*universe->sliceCount);
    universe->slices[universe->sliceCount-1] = slice;
}
MYSlice* MYUniverseCreateSlice(MYUniverse* universe, double y, double vy, byte evenOdd) {
    MYSlice* slice = MYSliceCreate();
    slice->y = y;
    slice->vy = vy;
    slice->evenOdd = evenOdd;
    slice->replicated = 0;
    slice->destroyed = 0;
    MYUniverseAddSlice(universe, slice);
    return slice;
}
