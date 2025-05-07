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
typedef struct AXAutomata {
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
} AXAutomata;

AXAutomata* AXAutomataCreate(Recipe* recipe, Memory* memory, int w, mnimi sI, mnimi aI, mnimi bI, mnimi cI, mnimi dI, mnimi eI, mnimi fI, mnimi gI, mnimi hI, mnimi rI);
AXAutomata* AXAutomataCreateClone(AXAutomata* automata);
void AXAutomataRelease(AXAutomata* automata);
void AXAutomataStep(AXAutomata* automata, double* cells, double* next, int from, int to);
void AXDataLoad(byte* data, double* cells, long sX, long eX, long dnX, long sY, long eY, long dnY, long zoom, double states, byte* r, byte* g, byte* b, byte* a, long cw, long dw);
