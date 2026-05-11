//
//  IntoTheLightShaders.metal
//  Aexels
//
//  Liénard–Wiechert disc — the analytic truth the cupola algorithm is
//  meant to converge on.  Disc bands come from the closed-form LW field
//  evaluated per pixel; pings are coloured by the band at their centre,
//  so a ping distribution that aggregates correctly fills each colour
//  band with the right relative density.  Toggles do not change the
//  disc — they change the simulation, and the difference is what the
//  lab is meant to show.
//

#include <metal_math>
#include <metal_stdlib>
using namespace metal;

struct ItLLWEContext {
    float2 cameraPos;
    float2 cameraBounds;
    float2 beta;
    uint fieldMode;             // 0 = electric (rainbow), 1 = magnetic (red/blue diverging)
    uint _pad;
};

struct ItLLWEPacket {
    float4 position [[position]];
    float2 worldPos;
};

vertex ItLLWEPacket itlLWEVertexShader(uint vertexID [[vertex_id]],
                                       constant ItLLWEContext &ctx [[buffer(0)]]) {
    const float2 positions[4] = { float2(-1, -1), float2(1, -1), float2(-1, 1), float2(1, 1) };

    ItLLWEPacket out;
    out.position = float4(positions[vertexID], 0.0, 1.0);

    float2 worldOffset = positions[vertexID] * ctx.cameraBounds * 0.5;
    worldOffset.y *= -1.0;
    out.worldPos = ctx.cameraPos + worldOffset;
    return out;
}

constant float3 ITL_PALETTE[7] = {
    float3(0.10, 0.05, 0.45),  // 0 deep indigo
    float3(0.10, 0.30, 0.80),  // 1 royal blue
    float3(0.10, 0.65, 0.75),  // 2 teal
    float3(0.20, 0.80, 0.30),  // 3 green
    float3(0.95, 0.85, 0.10),  // 4 yellow
    float3(1.00, 0.55, 0.05),  // 5 orange
    float3(0.95, 0.20, 0.10)   // 6 red
};

// Magnetic mode: diverging palette, signed.  Positive B_z (out of page)
// runs warm, negative B_z (into page) runs cool — magnitude grows from
// dark/dim → saturated by band index, so equal-|B| contours read.
constant float3 ITL_B_POS_PALETTE[7] = {
    float3(0.10, 0.05, 0.05),  // 0 nearly black
    float3(0.30, 0.10, 0.10),  // 1 dim red
    float3(0.55, 0.15, 0.10),  // 2 deep red
    float3(0.80, 0.25, 0.15),  // 3 red
    float3(1.00, 0.45, 0.20),  // 4 orange-red
    float3(1.00, 0.70, 0.30),  // 5 orange
    float3(1.00, 0.90, 0.50)   // 6 light orange
};
constant float3 ITL_B_NEG_PALETTE[7] = {
    float3(0.05, 0.05, 0.10),  // 0 nearly black
    float3(0.10, 0.10, 0.35),  // 1 dim blue
    float3(0.10, 0.20, 0.55),  // 2 deep blue
    float3(0.15, 0.35, 0.80),  // 3 royal blue
    float3(0.30, 0.60, 0.95),  // 4 light blue
    float3(0.55, 0.80, 0.95),  // 5 sky blue
    float3(0.80, 0.92, 1.00)   // 6 pale cyan
};

constant float ITL_R_OUTER = 440.0;
constant float ITL_R_CAL = ITL_R_OUTER / 7.0;

// Closed-form Liénard–Wiechert E-field magnitude at field point r relative
// to a source moving with β.  This is the analytic truth — toggle-
// independent.  Saturates inside the singular core so the band lookup
// snaps to red.
static float itlEMag(float2 r, float2 beta, float oneMinusBeta2) {
    float r2 = dot(r, r);
    if (r2 < 1.0) return 1e30;
    float rDotBeta = dot(r, beta);
    float disc = rDotBeta * rDotBeta + oneMinusBeta2 * r2;
    float tau = (rDotBeta + sqrt(disc)) / oneMinusBeta2;
    float2 nHat = (r + beta * tau) / tau;
    float kappa = max(1.0 - dot(nHat, beta), 1e-4);
    float nMinusBetaMag = length(nHat - beta);
    return oneMinusBeta2 * nMinusBetaMag / (kappa * kappa * kappa * tau * tau);
}

// bandCoord = 7 − √(calFlux/eMag).  Integer values are band boundaries:
// bandCoord = 6 is the orange/red edge (eMag = calFlux), bandCoord = 0 is
// the disc's outer edge (eMag = calFlux/49), bandCoord < 0 is outside.
static float itlBandCoord(float eMag, float calFlux) {
    return 7.0 - sqrt(calFlux / max(eMag, 1e-30));
}

// Closed-form Liénard–Wiechert magnetic z-component (signed) at field
// point r relative to a source moving with β.  In 2D, B = (n̂ × E)/c,
// and B_z reduces to (1−β²) (n̂×β)_z / (κ³ R²) up to sign — purely
// transverse, vanishing along the motion axis.  Sign is flipped from
// the bare math so that screen-up (where the disc shader's
// worldOffset.y flip puts world Y < cameraY) reads warm/positive,
// matching the right-hand-rule intuition for β along +x.  Returns 0
// inside the singular core to avoid runaway.
static float itlBz(float2 r, float2 beta, float oneMinusBeta2) {
    float r2 = dot(r, r);
    if (r2 < 1.0) return 0.0;
    float rDotBeta = dot(r, beta);
    float disc = rDotBeta * rDotBeta + oneMinusBeta2 * r2;
    float tau = (rDotBeta + sqrt(disc)) / oneMinusBeta2;
    float2 nHat = (r + beta * tau) / tau;
    float kappa = max(1.0 - dot(nHat, beta), 1e-4);
    float crossZ = nHat.x * beta.y - nHat.y * beta.x;
    return oneMinusBeta2 * crossZ / (kappa * kappa * kappa * tau * tau);
}

struct ItLPingCamera {
    float2 position;
    float2 bounds;
    float2 hexBounds;
    float2 velocity;
    float hexWidth;
    bool pingVectorsOn;
    bool pongVectorsOn;
    bool photonVectorsOn;
    char padding[1];
};

struct ItLPingDraw {
    float2 position;
    float2 cupola;
    float2 velocity;
};

struct ItLPingFragCtx {
    float2 cameraPos;
    float colormapExtent;
    float beta;
    uint fullPingsOn;          // 1 = render body + cupola vector + head
    uint magnitudeOn;          // 1 = arm length scales with |cupola|; 0 = unit
    uint fieldMode;            // 0 = electric (rainbow), 1 = magnetic (signed diverging)
    uint _pad;
};

struct ItLAccumCtx {
    float2 sourcePos;
    float2 aetherTranslation; // per-tick lab displacement from the aether
    float colormapExtent;
    float c;                  // ping speed; SCPing.v is unit-direction
    uint pingCount;
    uint magnitudeOn;         // 1 = weight by cupola·n̂_face, 0 = 1 (electric only)
    uint fieldMode;           // 0 = electric (cupola·n̂), 1 = magnetic (n̂×cupola)_z
    uint _pad;
};

constant int ITL_CM_M_R = 128;
constant int ITL_CM_M_THETA = 240;
constant float ITL_SENSOR_SCALE = 1.0e6;

// Atomic-accum kernel.  One thread per live ping.  Deposits the
// ping's weight ONCE per cell-crossing event: when the ping has
// entered a new R-cell this tick (iR1 > iR0).  This makes each ping
// contribute exactly once to each cell its trajectory passes through,
// so after one full volley sweep the bandcoord ratio between cells is
// final — subsequent volleys just add scaled copies.  Per-cell weight
// = |𝐂|/R, the toggle-aware cupola magnitude times the 1/R geometric
// factor that turns 2D ping density into 1/R² flux.  Aberration is
// baked into the C engine's emission distribution.  Bilinear in θ so
// the discrete emission spokes don't leave gaps between cells.
kernel void itlAccumulateKernel(constant ItLAccumCtx &ctx [[buffer(0)]],
                                constant ItLPingDraw *pings [[buffer(1)]],
                                device atomic_int *sensor [[buffer(2)]],
                                uint pid [[thread_position_in_grid]]) {
    if (pid >= ctx.pingCount) return;
    float2 r1 = pings[pid].position - ctx.sourcePos;
    float R1 = length(r1);
    if (R1 < 1.0 || R1 > ctx.colormapExtent) return;

    // Per-tick lab motion = c·n̂_em + aether translation.  SCPing.v is
    // unit n̂_em (engine scales by c at tic-time), so multiply by c
    // here.  Subtract both to recover r0 — works at any β.
    float2 r0 = r1 - ctx.c * pings[pid].velocity - ctx.aetherTranslation;
    float R0 = length(r0);

    float dR = ctx.colormapExtent / float(ITL_CM_M_R);
    int iR1 = int(R1 / dR);
    int iR0 = R0 < 0.0 ? -1 : int(R0 / dR);
    if (iR1 <= iR0) return;                 // not a new outward crossing
    if (iR1 >= ITL_CM_M_R) return;

    float theta = atan2(r1.y, r1.x);
    if (theta < 0) theta += 2.0 * 3.14159265358979;
    float dT = 2.0 * 3.14159265358979 / float(ITL_CM_M_THETA);

    // Bilinear-θ deposit: split weight across the two θ-cells the
    // ping straddles, so emission spokes don't leave empty cells
    // between them.
    float jf = theta / dT - 0.5;
    int j0_raw = int(floor(jf));
    float jt = jf - floor(jf);
    int j0 = ((j0_raw % ITL_CM_M_THETA) + ITL_CM_M_THETA) % ITL_CM_M_THETA;
    int j1 = (j0 + 1) % ITL_CM_M_THETA;

    // Electric mode: deposit cupola·n̂_face (radial component of cupola)
    //   — reproduces |E|_LW.
    // Magnetic mode: deposit (β × cupola)_z, signed.  In this lab the
    //   source is at rest and the aether drifts, which makes cupola
    //   parallel to n̂_face by construction — so the natural choice
    //   (n̂×cupola)_z would vanish.  Cross with β instead: it picks up
    //   the transverse-to-motion component the same way the LW formula
    //   does (B_z ∝ -(n̂×β)_z = (β×n̂)_z), and since cupola ∥ n̂_face
    //   the dipole pattern matches.  Sign flipped so screen-up (world
    //   Y < cameraY due to the disc's worldOffset.y flip) reads warm.
    //   Sensor is atomic_int so the sign is preserved cell-by-cell.
    // Rule 3 (aberrated emission distribution) is baked into the C
    // engine's emission, so the kernel does NOT re-weight by ρ here.
    float2 nFace = r1 / R1;
    float w;
    if (ctx.fieldMode == 1u) {
        // β = -aetherTranslation/c (aether drifts opposite to source motion).
        float2 betaV = -ctx.aetherTranslation / ctx.c;
        float crossZ = betaV.y * pings[pid].cupola.x - betaV.x * pings[pid].cupola.y;
        if (ctx.magnitudeOn != 0u) {
            w = crossZ;
        } else {
            // Sign only: drop the sin(angle) magnitude so each cell
            // gets a hard ±1.  Lobes go solid-edged instead of band-
            // graded, directly showing what the cupola magnitude
            // contributes to B.
            w = crossZ > 0.0 ? 1.0 : (crossZ < 0.0 ? -1.0 : 0.0);
        }
    } else if (ctx.magnitudeOn != 0u) {
        w = pings[pid].cupola.x * nFace.x + pings[pid].cupola.y * nFace.y;
    } else {
        w = 1.0;
    }
    int w0 = int(w * (1.0 - jt) * ITL_SENSOR_SCALE);
    int w1 = int(w * jt * ITL_SENSOR_SCALE);

    int row = iR1 * ITL_CM_M_THETA;
    atomic_fetch_add_explicit(&sensor[row + j0], w0, memory_order_relaxed);
    atomic_fetch_add_explicit(&sensor[row + j1], w1, memory_order_relaxed);
}

// Bilinear sample of the signed sensor buffer at polar (R, θ), converted
// back to float by dividing out the fixed-point scale.  Returns positive
// values in electric mode, signed values in magnetic mode.
static float itlSensorSample(device const int *sensor,
                             float R, float theta, float colormapExtent) {
    float dR = colormapExtent / float(ITL_CM_M_R);
    float dT = 2.0 * 3.14159265358979 / float(ITL_CM_M_THETA);
    float jf = theta / dT - 0.5;
    float kf = R / dR - 0.5;
    int j0_raw = int(floor(jf));
    int k0 = clamp(int(floor(kf)), 0, ITL_CM_M_R - 2);
    float jt = jf - floor(jf);
    float kt = clamp(kf - float(k0), 0.0, 1.0);
    int j0 = ((j0_raw % ITL_CM_M_THETA) + ITL_CM_M_THETA) % ITL_CM_M_THETA;
    int j1 = (j0 + 1) % ITL_CM_M_THETA;
    int k1 = k0 + 1;
    float f00 = float(sensor[k0 * ITL_CM_M_THETA + j0]) / ITL_SENSOR_SCALE;
    float f10 = float(sensor[k0 * ITL_CM_M_THETA + j1]) / ITL_SENSOR_SCALE;
    float f01 = float(sensor[k1 * ITL_CM_M_THETA + j0]) / ITL_SENSOR_SCALE;
    float f11 = float(sensor[k1 * ITL_CM_M_THETA + j1]) / ITL_SENSOR_SCALE;
    float fBot = mix(f00, f10, jt);
    float fTop = mix(f01, f11, jt);
    return mix(fBot, fTop, kt);
}

struct ItLPingPacket {
    float4 position [[position]];
    float2 local;
    float2 cupola [[flat]];
    float2 centreLocal [[flat]];   // ping centre in teslon-local coords
};

vertex ItLPingPacket itlPingVertexShader(uint vertexID [[vertex_id]],
                                         uint instanceID [[instance_id]],
                                         constant ItLPingCamera &camera [[buffer(0)]],
                                         constant ItLPingDraw *pings [[buffer(1)]]) {
    ItLPingDraw ping = pings[instanceID];
    float size = 18;

    const float2 localOffsets[4] = {
        float2(-1.0, -1.0),
        float2(1.0, -1.0),
        float2(-1.0, 1.0),
        float2(1.0, 1.0)
    };

    float2 worldPosition = ping.position + localOffsets[vertexID] * size;
    float2 normalizedPosition = (worldPosition - camera.position) / (camera.bounds * 0.5);
    normalizedPosition.y *= -1.0;

    ItLPingPacket out;
    out.position = float4(normalizedPosition, 0.0, 1.0);
    out.local = localOffsets[vertexID];
    out.cupola = ping.cupola;
    out.centreLocal = ping.position - camera.position;
    return out;
}

// Mini-dot ping.  Body colour = the band that the running cupola
// simulation's accumulated sensor field puts the ping centre in.  The
// sensor buffer is filled by itlAccumulateKernel — every tick, every
// live ping atomic-adds its weight into the cell it currently sits
// in.  No phantom splat, no σ kernel, no curvature correction:
// crossings are exact, the buffer literally is the simulation's
// output.  Empty cells (the field hasn't reached this R yet) render
// dim grey; once enough pings have passed, ping bodies converge onto
// the disc band beneath them when toggles agree, and visibly diverge
// when they don't.
fragment float4 itlPingFragmentShader(ItLPingPacket in [[stage_in]],
                                      constant ItLPingFragCtx &ctx [[buffer(0)]],
                                      device const int *sensor [[buffer(1)]]) {
    float2 r = in.centreLocal;
    float R = length(r);

    float3 bodyCol;
    // Radiation mode: no analytic field disc yet, and sampling the
    // E-mode sensor would mis-colour the pings.  Use a neutral body
    // colour so the cupola arm + head read clean against the aether.
    if (ctx.fieldMode == 2u) {
        bodyCol = float3(0.85, 0.85, 0.85);
    } else if (R < 1.0) {
        bodyCol = ctx.fieldMode == 1u ? float3(0.30, 0.30, 0.30) : ITL_PALETTE[6];
    } else {
        float theta = atan2(r.y, r.x);
        if (theta < 0) theta += 2.0 * 3.14159265358979;

        // Sensor stores ping crossings × cupola-projection.  In E mode
        // the projection is cupola·n̂ (always positive once collected
        // statistically); in B mode it's (n̂×cupola)_z (signed, dipole).
        // Either way, dividing by R² yields the corresponding 2D flux.
        float cellValue = itlSensorSample(sensor, R, theta, ctx.colormapExtent);
        float flux = cellValue / (R * R);

        // Calibration at the perp cal point Y_cal(β), 3π/2 — anchors disc
        // and pings to the same R.  In B mode B_z peaks at this angle,
        // so |calFlux| stays well-conditioned the same way it does for E.
        float beta = ctx.beta;
        float oneMinusBeta2 = max(1.0 - beta * beta, 1e-4);
        float yCal = ITL_R_CAL / pow(oneMinusBeta2, 0.25);
        float calCellValue = itlSensorSample(sensor, yCal,
                                             1.5 * 3.14159265358979,
                                             ctx.colormapExtent);
        float calFlux = calCellValue / (yCal * yCal);

        if (ctx.fieldMode == 1u) {
            float absFlux = abs(flux);
            float absCal = abs(calFlux);
            if (absFlux <= 1e-12 || absCal <= 1e-12) {
                bodyCol = float3(0.30, 0.30, 0.30);
            } else {
                float bandCoord = 7.0 - sqrt(absCal / absFlux);
                if (bandCoord < 0.0) {
                    bodyCol = float3(0.55, 0.55, 0.55);
                } else {
                    float bcClamped = clamp(bandCoord, 0.0, 6.999);
                    float bandIdx = floor(bcClamped);
                    float bandFrac = bcClamped - bandIdx;
                    int band = clamp(int(bandIdx), 0, 6);
                    bodyCol = (flux > 0.0 ? ITL_B_POS_PALETTE[band] : ITL_B_NEG_PALETTE[band])
                              * (0.85 + 0.15 * bandFrac);
                }
            }
        } else {
            if (flux <= 1e-12 || calFlux <= 1e-12) {
                bodyCol = float3(0.30, 0.30, 0.30);  // sensor cell still empty
            } else {
                float bandCoord = 7.0 - sqrt(calFlux / flux);
                if (bandCoord < 0.0) {
                    bodyCol = float3(0.55, 0.55, 0.55);
                } else {
                    float bcClamped = clamp(bandCoord, 0.0, 6.999);
                    float bandIdx = floor(bcClamped);
                    float bandFrac = bcClamped - bandIdx;
                    int band = clamp(int(bandIdx), 0, 6);
                    bodyCol = ITL_PALETTE[band] * (0.85 + 0.15 * bandFrac);
                }
            }
        }
    }

    float2 local = in.local;
    if (ctx.fullPingsOn != 0u) {
        // Full ping: body dot + white cupola arm + small body-coloured head.
        float2 cupola = in.cupola;
        float cmag = length(cupola);
        if (cmag > 1e-6) {
            float2 cupolaDir = cupola / cmag;
            float2 perpDir = float2(-cupolaDir.y, cupolaDir.x);
            float along = dot(local, cupolaDir);
            float perp  = dot(local, perpDir);

            // Body: same dot as default.
            if (length(local) < 0.14) return float4(bodyCol, 1.0);

            // Arm length: scales with |cupola| only when magnitude is on;
            // otherwise fixed (treats cupola as a unit direction vector).
            float armLen = ctx.magnitudeOn != 0u
                ? clamp(cmag * 0.55, 0.20, 0.70)
                : 0.45;

            // Head: small body-coloured dot at the tip of the arm.
            float headRadius = 0.10;
            float2 headCentre = cupolaDir * armLen;
            float2 toHead = local - headCentre;
            if (dot(toHead, toHead) < headRadius * headRadius) {
                return float4(bodyCol, 1.0);
            }

            // Cupola arm between body and head, in the body colour.
            if (along > 0.14 && along < armLen && abs(perp) < 0.03) {
                return float4(bodyCol, 1.0);
            }
            return float4(0.0);
        }
    }

    // Default: just the body dot.
    if (length(local) < 0.14) return float4(bodyCol, 1.0);
    return float4(0.0);
}

fragment float4 itlLWEFragmentShader(ItLLWEPacket in [[stage_in]],
                                     constant ItLLWEContext &ctx [[buffer(0)]]) {
    float2 r = in.worldPos - ctx.cameraPos;
    float beta2 = dot(ctx.beta, ctx.beta);
    float oneMinusBeta2 = max(1.0 - beta2, 1e-4);

    // Cal point at perp Y_cal(β) = R_cal/(1−β²)^¼ — same definition the
    // colormap uses, so disc and colormap anchor to the same R.  LW gives
    // 1/R_cal² at this point regardless of β, so calFlux is β-invariant.
    float yCal = ITL_R_CAL / pow(oneMinusBeta2, 0.25);

    // Magnetic mode: signed B_z, diverging palette.  calRef is the
    // perpendicular-axis B_z magnitude (peaks here, vanishes along the
    // motion axis), so the band scheme stays β-invariant the same way
    // calFlux is for E.
    if (ctx.fieldMode == 1u) {
        float calRef = abs(itlBz(float2(0.0, -yCal), ctx.beta, oneMinusBeta2));
        if (calRef <= 1e-30) return float4(0.0);
        float bz = itlBz(r, ctx.beta, oneMinusBeta2);
        float absBz = abs(bz);
        float bandCoord = absBz <= 1e-30 ? -1e30 : 7.0 - sqrt(calRef / absBz);

        if (bandCoord < 0.0) {
            // Drop shadow — sample at offset and project the dipole's
            // silhouette behind the lobes.  Sign at the offset point
            // selects warm/cool palette so the shadow keeps the
            // dipole's polarity.
            const float2 shadowOffset = float2(-50.0, 30.0);
            float bz_s = itlBz(r - shadowOffset, ctx.beta, oneMinusBeta2);
            float absBz_s = abs(bz_s);
            if (absBz_s <= 1e-30) return float4(0.0);
            float bandCoord_s = 7.0 - sqrt(calRef / absBz_s);

            const float blurPixels = 28.0;
            float gradBC = max(fwidth(bandCoord_s), 1e-4);
            float blurWidth = blurPixels * gradBC;
            float shadowFade = smoothstep(-blurWidth, 0.5 * blurWidth, bandCoord_s);
            if (shadowFade <= 0.001) return float4(0.0);

            // Suppress the spurious shadow line along the motion axis
            // — B_z passes through zero there, so the dipole has no
            // silhouette at θ = 0/π.  The shadow at this pixel is the
            // silhouette of the OFFSET point, so fade based on that
            // point's perpendicular component relative to β, not the
            // current pixel's.  The smoothstep thresholds set how
            // wide the dead-zone wedge along the axis is.
            float bMag = max(sqrt(beta2), 1e-6);
            float2 betaHat = beta2 > 1e-12 ? ctx.beta / bMag : float2(1.0, 0.0);
            float2 rOff = r - shadowOffset;
            float perpOff = abs(rOff.x * (-betaHat.y) + rOff.y * betaHat.x);
            float perpRatioOff = perpOff / max(length(rOff), 1.0);
            float axisFade = smoothstep(0.03, 0.09, perpRatioOff);
            if (axisFade <= 0.001) return float4(0.0);
            shadowFade *= axisFade;

            float bcClamped_s = clamp(bandCoord_s, 0.0, 6.999);
            float bandIdx_s = floor(bcClamped_s);
            float bandFrac_s = bcClamped_s - bandIdx_s;
            float screenStep_s = fwidth(bcClamped_s);
            float lineMix_s = smoothstep(0.0, 1.5 * screenStep_s, bandFrac_s);

            int idx_s = clamp(int(bandIdx_s), 0, 6);
            float3 bandCol_s = bz_s > 0.0 ? ITL_B_POS_PALETTE[idx_s] : ITL_B_NEG_PALETTE[idx_s];
            bandCol_s *= 0.85 + 0.15 * bandFrac_s;
            float3 lineCol_s = bandCol_s * 0.15;

            const float shadowMultiplier = 0.45;
            float3 shadowCol = mix(lineCol_s, bandCol_s, lineMix_s) * shadowMultiplier;
            return float4(shadowCol, 0.35 * shadowFade);
        }

        float bcClamped = clamp(bandCoord, 0.0, 6.999);
        float bandIdx = floor(bcClamped);
        float bandFrac = bcClamped - bandIdx;
        int idx = clamp(int(bandIdx), 0, 6);
        float3 col = bz > 0.0 ? ITL_B_POS_PALETTE[idx] : ITL_B_NEG_PALETTE[idx];
        col *= 0.85 + 0.15 * bandFrac;
        float screenStep = fwidth(bcClamped);
        float lineMix = smoothstep(0.0, 1.5 * screenStep, bandFrac);
        float3 lineColor = col * 0.15;
        float3 finalCol = mix(lineColor, col, lineMix);
        float finalAlpha = mix(0.95, 0.55, lineMix);
        return float4(finalCol, finalAlpha);
    }

    float calFlux = itlEMag(float2(0.0, -yCal), ctx.beta, oneMinusBeta2);
    float eMag = itlEMag(r, ctx.beta, oneMinusBeta2);
    float bandCoord = itlBandCoord(eMag, calFlux);

    if (bandCoord < 0.0) {
        // Drop shadow — same band scheme, sampled at offset.
        const float2 shadowOffset = float2(-50.0, 30.0);
        float eMag_s = itlEMag(r - shadowOffset, ctx.beta, oneMinusBeta2);
        float bandCoord_s = itlBandCoord(eMag_s, calFlux);

        const float blurPixels = 28.0;
        float gradBC = max(fwidth(bandCoord_s), 1e-4);
        float blurWidth = blurPixels * gradBC;
        float shadowFade = smoothstep(-blurWidth, 0.5 * blurWidth, bandCoord_s);
        if (shadowFade <= 0.001) return float4(0.0);

        float bcClamped_s = clamp(bandCoord_s, 0.0, 6.999);
        float bandIdx_s = floor(bcClamped_s);
        float bandFrac_s = bcClamped_s - bandIdx_s;
        float screenStep_s = fwidth(bcClamped_s);
        float lineMix_s = smoothstep(0.0, 1.5 * screenStep_s, bandFrac_s);

        int idx_s = clamp(int(bandIdx_s), 0, 6);
        float3 bandCol_s = ITL_PALETTE[idx_s];
        bandCol_s *= 0.85 + 0.15 * bandFrac_s;
        float3 lineCol_s = bandCol_s * 0.15;

        const float shadowMultiplier = 0.45;
        float3 shadowCol = mix(lineCol_s, bandCol_s, lineMix_s) * shadowMultiplier;
        return float4(shadowCol, 0.35 * shadowFade);
    }

    float bcClamped = clamp(bandCoord, 0.0, 6.999);
    float bandIdx = floor(bcClamped);
    float bandFrac = bcClamped - bandIdx;

    int idx = clamp(int(bandIdx), 0, 6);
    float3 col = ITL_PALETTE[idx];
    col *= 0.85 + 0.15 * bandFrac;

    float screenStep = fwidth(bcClamped);
    float lineMix = smoothstep(0.0, 1.5 * screenStep, bandFrac);

    float3 lineColor = col * 0.15;
    float bandAlpha = 0.55;
    float lineAlpha = 0.95;

    float3 finalCol = mix(lineColor, col, lineMix);
    float finalAlpha = mix(lineAlpha, bandAlpha, lineMix);
    return float4(finalCol, finalAlpha);
}
