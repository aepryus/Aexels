//
//  Okhotsk.h
//  Aexels
//
//  Created by Joe Charlier on 3/16/25.
//  Copyright © 2025 Aepryus Software. All rights reserved.
//

// OC = Okhotsk Sea : Cellular Automata

#import "Aegean.h"

// Cellular Automata ===============================================================================
typedef struct Automata {
    Recipe* recipe;
    Memory* memory;
    int w;
    mnimi sI;
    mnimi aI;
    mnimi bI;
    mnimi cI;
    mnimi dI;
    mnimi eI;
    mnimi fI;
    mnimi gI;
    mnimi hI;
    mnimi rI;
} Automata;

Automata* AXAutomataCreate(Recipe* recipe, Memory* memory, int w, mnimi sI, mnimi aI, mnimi bI, mnimi cI, mnimi dI, mnimi eI, mnimi fI, mnimi gI, mnimi hI, mnimi rI);
Automata* AXAutomataCreateClone(Automata* automata);
void AXAutomataRelease(Automata* automata);
void AXAutomataStep(Automata* automata, double* cells, double* next, int from, int to);
void AXDataLoad(byte* data, double* cells, long sX, long eX, long dnX, long sY, long eY, long dnY, long zoom, double states, byte* r, byte* g, byte* b, byte* a, long cw, long dw);
