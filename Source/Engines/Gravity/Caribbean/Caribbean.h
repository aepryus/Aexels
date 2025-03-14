//
//  Caribbean.h
//  Aexels
//
//  Created by Joe Charlier on 3/14/25.
//  Copyright © 2025 Aepryus Software. All rights reserved.
//

// CC = Caribbean Sea : Gravity

#import "Sea.h"

typedef struct CCAexel {
    CV2 pos;
} CCAexel;

CCAexel* CCAexelCreate(void);
void CCAexelRelease(CCAexel* aexel);

typedef struct CCUniverse {
} CCUniverse;

CCUniverse* CCUniverseCreate(double width, double height);
void CCUniverseRelease(CCUniverse* universe);
