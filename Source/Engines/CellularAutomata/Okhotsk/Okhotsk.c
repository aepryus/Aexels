//
//  Okhotsk.c
//  Aexels
//
//  Created by Joe Charlier on 3/16/25.
//  Copyright © 2025 Aepryus Software. All rights reserved.
//

#import <stdlib.h>
#include "Okhotsk.h"

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
            
            AEMemorySetValue(a->memory, a->sI,                                 cells[i   + (j  )*a->w]);
            AEMemorySetValue(a->memory, a->aI, i != 0 && j != 0 ?             cells[i-1 + (j-1)*a->w] : 0);
            AEMemorySetValue(a->memory, a->bI, j != 0 ?                     cells[i   + (j-1)*a->w] : 0);
            AEMemorySetValue(a->memory, a->cI, i != a->w-1 && j != 0 ?         cells[i+1 + (j-1)*a->w] : 0);
            AEMemorySetValue(a->memory, a->dI, i != a->w-1 ?                 cells[i+1 + (j  )*a->w] : 0);
            AEMemorySetValue(a->memory, a->eI, i != a->w-1 && j != a->w-1 ?    cells[i+1 + (j+1)*a->w] : 0);
            AEMemorySetValue(a->memory, a->fI, j != a->w-1 ?                cells[i   + (j+1)*a->w] : 0);
            AEMemorySetValue(a->memory, a->gI, i != 0 && j != a->w-1 ?         cells[i-1 + (j+1)*a->w] : 0);
            AEMemorySetValue(a->memory, a->hI, i != 0 ?                     cells[i-1 + (j  )*a->w] : 0);
            
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

