//
//  Caspian.c
//  Aexels
//
//  Created by Joe Charlier with Grok on 2/19/25.
//  Copyright © 2025 Aepryus Software. All rights reserved.
//

#include <math.h>
#include <stdlib.h>
#include "Caspian.h"

// CSTeslon ========================================================================================
CSTeslon* CSTeslonCreate(void) {
    CSTeslon* teslon = (CSTeslon*)malloc(sizeof(CSTeslon));
    teslon->pos = (CV2){0, 0};
    teslon->v = (CV2){0, 0};
    teslon->hyle = 0;
    return teslon;
}
void CSTeslonRelease(CSTeslon* teslon) {
    free(teslon);
}

// CSCamera ========================================================================================
CSCamera* CSCameraCreate(void) {
    CSCamera* camera = (CSCamera*)malloc(sizeof(CSCamera));
    camera->pos = (CV2){0, 0};
    camera->v = (CV2){0, 0};
    camera->width = 0;
    camera->height = 0;
    return camera;
}
void CSCameraRelease(CSCamera* camera) {
    free(camera);
}

// CSUniverse ======================================================================================
CSUniverse* CSUniverseCreate(double width, double height) {
    CSUniverse* universe = (CSUniverse*)malloc(sizeof(CSUniverse));
    universe->width = width;
    universe->height = height;
    universe->c = 1.0;  // 1 aexel/tic (adjustable)
    universe->G = 6.6743e-11;  // aexels³/hyle/tic² (scale later)

    universe->teslonCount = 0;
    universe->teslonCapacity = 2;
    universe->teslons = (CSTeslon**)malloc(sizeof(CSTeslon*) * universe->teslonCapacity);

    universe->cameraCount = 0;
    universe->cameraCapacity = 2;
    universe->cameras = (CSCamera**)malloc(sizeof(CSCamera*) * universe->cameraCapacity);

    return universe;
}

void CSUniverseRelease(CSUniverse* universe) {
    for (int i = 0; i < universe->teslonCount; i++) CSTeslonRelease(universe->teslons[i]);
    free(universe->teslons);
    for (int i = 0; i < universe->cameraCount; i++) CSCameraRelease(universe->cameras[i]);
    free(universe->cameras);
    free(universe);
}

void CSUniverseAddTeslon(CSUniverse* universe, CSTeslon* teslon) {
    universe->teslonCount++;
    if (universe->teslonCount > universe->teslonCapacity) {
        universe->teslonCapacity *= 2;
        universe->teslons = (CSTeslon**)realloc(universe->teslons, sizeof(CSTeslon*) * universe->teslonCapacity);
    }
    universe->teslons[universe->teslonCount - 1] = teslon;
}

CSTeslon* CSUniverseCreateTeslon(CSUniverse* universe, double x, double y, double hyle) {
    CSTeslon* teslon = CSTeslonCreate();
    teslon->pos.x = x;
    teslon->pos.y = y;
    teslon->hyle = hyle;
    CSUniverseAddTeslon(universe, teslon);
    return teslon;
}

CSCamera* CSUniverseCreateCamera(CSUniverse* universe, double x, double y) {
    CSCamera* camera = CSCameraCreate();
    camera->pos.x = x;
    camera->pos.y = y;
    camera->width = universe->width;
    camera->height = universe->height;
    universe->cameraCount++;
    if (universe->cameraCount > universe->cameraCapacity) {
        universe->cameraCapacity *= 2;
        universe->cameras = (CSCamera**)realloc(universe->cameras, sizeof(CSCamera*) * universe->cameraCapacity);
    }
    universe->cameras[universe->cameraCount - 1] = camera;
    if (universe->cameraCount == 1) universe->camera = camera;
    return camera;
}

void CSUniverseTic(CSUniverse* universe) {
    // Calculate center of mass (hyle-weighted)
    double total_hyle = 0;
    CV2 center = {0, 0};
    for (int i = 0; i < universe->teslonCount; i++) {
        CSTeslon* teslon = universe->teslons[i];
        total_hyle += teslon->hyle;
        center.x += teslon->pos.x * teslon->hyle;
        center.y += teslon->pos.y * teslon->hyle;
    }
    center.x /= total_hyle;
    center.y /= total_hyle;

    // Apply gravity flow
    for (int i = 0; i < universe->teslonCount; i++) {
        CSTeslon* teslon = universe->teslons[i];
        CV2 dr = {teslon->pos.x - center.x, teslon->pos.y - center.y};
        double r = CV2Length(dr);
        if (r < 1e-6) continue;  // Avoid singularity
        double v_a = sqrt(2 * universe->G * total_hyle / r);  // Flow speed
        CV2 flow = {-v_a * dr.x / r, -v_a * dr.y / r};  // Radial inward
        teslon->v = CV2Add(teslon->v, flow);  // Update velocity
        teslon->pos.x += teslon->v.x * universe->c;
        teslon->pos.y += teslon->v.y * universe->c;
    }
}
