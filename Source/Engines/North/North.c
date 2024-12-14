//
//  North.c
//  Aexels
//
//  Created by Joe Charlier on 12/12/24.
//  Copyright © 2024 Aepryus Software. All rights reserved.
//

#import <stdlib.h>
#import "North.h"

// Teslon ==========================================================================================
NCTeslon* NCTeslonCreate(void) {
    NCTeslon* teslon = (NCTeslon*)malloc(sizeof(NCTeslon));
    return teslon;
}
void NCTeslonRelease(NCTeslon* teslon) {
    free(teslon);
}

// Ping ============================================================================================
NCPing* NCPingCreate(void) {
    NCPing* teslon = (NCPing*)malloc(sizeof(NCPing));
    return teslon;
}
void NCPingRelease(NCPing* teslon) {
    free(teslon);
}

// Pong ============================================================================================
NCPong* NCPongCreate(void) {
    NCPong* teslon = (NCPong*)malloc(sizeof(NCPong));
    return teslon;
}
void NCPongRelease(NCPong* teslon) {
    free(teslon);
}

// Photon ==========================================================================================
NCPhoton* NCPhotonCreate(void) {
    NCPhoton* teslon = (NCPhoton*)malloc(sizeof(NCPhoton));
    return teslon;
}
void NCPhotonRelease(NCPhoton* teslon) {
    free(teslon);
}

// Universe ========================================================================================
NCUniverse* NCUniverseCreate(void) {
    NCUniverse* teslon = (NCUniverse*)malloc(sizeof(NCUniverse));
    return teslon;
}
void NCUniverseRelease(NCUniverse* teslon) {
    free(teslon);
}

void NCUniverseAddTeslon(NCUniverse* universe, NCTeslon* teslon) {
    universe->teslonCount++;
    universe->teslons = (NCTeslon**)realloc(universe->teslons, sizeof(NCTeslon*)*universe->teslonCount);
    universe->teslons[universe->teslonCount-1] = teslon;
}
void NCUniverseAddPing(NCUniverse* universe, NCPing* ping) {
    universe->pingCount++;
    universe->pings = (NCPing**)realloc(universe->pings, sizeof(NCPing*)*universe->pingCount);
    universe->pings[universe->pingCount-1] = ping;
}
void NCUniverseAddPong(NCUniverse* universe, NCPong* pong) {
    universe->pongCount++;
    universe->pongs = (NCPong**)realloc(universe->pongs, sizeof(NCPong*)*universe->pongCount);
    universe->pongs[universe->pongCount-1] = pong;
}
void NCUniverseAddPhoton(NCUniverse* universe, NCPhoton* photon) {
    universe->photonCount++;
    universe->photons = (NCPhoton**)realloc(universe->photons, sizeof(NCPhoton*)*universe->photonCount);
    universe->photons[universe->photonCount-1] = photon;
}

NCTeslon* NCUniverseCreateTeslon(NCUniverse* universe, double x, double y, double s, double q) {
    NCTeslon* teslon = NCTeslonCreate();
    teslon->pos.x = x;
    teslon->pos.y = y;
    NCUniverseAddTeslon(universe, teslon);
    return teslon;
}
NCPing* NCUniverseCreatePing(NCUniverse* universe, double x, double y, double s, double q) {
    NCPing* ping = NCPingCreate();
    ping->pos.x = x;
    ping->pos.y = y;
    NCUniverseAddPing(universe, ping);
    return ping;
}
NCPong* NCUniverseCreatePong(NCUniverse* universe, double x, double y, double s, double q) {
    NCPong* pong = NCPongCreate();
    pong->pos.x = x;
    pong->pos.y = y;
    NCUniverseAddPong(universe, pong);
    return pong;
}
NCPhoton* NCUniverseCreatePhoton(NCUniverse* universe, double x, double y, double s, double q) {
    NCPhoton* photon = NCPhotonCreate();
    photon->pos.x = x;
    photon->pos.y = y;
    NCUniverseAddPhoton(universe, photon);
    return photon;
}

void NCUniverseTic(NCUniverse* universe) {
}

void NCUniversePulse(NCUniverse* universe, int n) {
}
