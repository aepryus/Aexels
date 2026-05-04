//
//  IntoTheLightShaders.metal
//  Aexels
//
//  Liénard–Wiechert velocity-field (LW-E) potential map.  Renders the
//  analytic LW E-field magnitude of a single source teslon as a 50%
//  alpha overlay.  At β = 0 the field is spherically symmetric (1/r²);
//  for β > 0 the κ³ factor produces the characteristic forward
//  compression and backward stretch.
//

#include <metal_math>
#include <metal_stdlib>
using namespace metal;

struct ItLLWEContext {
    float2 cameraPos;
    float2 cameraBounds;
    float2 beta;
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

    // Same screen→world convention as the loop shader:
    //   normalizedPosition = (worldPosition − camera.position) / (bounds * 0.5)
    //   normalizedPosition.y *= -1
    float2 worldOffset = positions[vertexID] * ctx.cameraBounds * 0.5;
    worldOffset.y *= -1.0;
    out.worldPos = ctx.cameraPos + worldOffset;
    return out;
}

// Spectral palette — band 6 is the innermost (red) colour, also painted into
// the singular core so the centre is solid red, never black.
constant float3 ITL_PALETTE[7] = {
    float3(0.10, 0.05, 0.45),  // 0 deep indigo
    float3(0.10, 0.30, 0.80),  // 1 royal blue
    float3(0.10, 0.65, 0.75),  // 2 teal
    float3(0.20, 0.80, 0.30),  // 3 green
    float3(0.95, 0.85, 0.10),  // 4 yellow
    float3(1.00, 0.55, 0.05),  // 5 orange
    float3(0.95, 0.20, 0.10)   // 6 red (innermost — fills the core)
};

constant float ITL_CUTOFF_LOG = 0.42;
constant float ITL_TOP_LOG = 4.5;
constant float ITL_LEVELS = 7.0;
constant float ITL_R_OUTER = 440.0;

// Map logE to a normalized 0..1 band coordinate using equivalent-radius
// (r at β=0 that would produce this |E|) rather than logE directly.  This
// gives bands of equal width in r-space (so the ring widths look even)
// while preserving the LW asymmetry through logE itself.
static float itlScaledFromLogE(float logE) {
    float invE = exp(logE) - 1.0;
    float rEquiv = sqrt(100000.0 / max(invE, 1e-6));
    return clamp(1.0 - rEquiv / ITL_R_OUTER, 0.0, 1.0);
}

// Returns log( 1 + |E|·1e5 ) at the field point r relative to a source moving
// at β.  Returns a saturating value for r → 0 to avoid the singularity.
static float itlLogE(float2 r, float2 beta, float oneMinusBeta2) {
    float r2 = dot(r, r);
    if (r2 < 1.0) return ITL_TOP_LOG * 2.0;
    float rDotBeta = dot(r, beta);
    float disc = rDotBeta * rDotBeta + oneMinusBeta2 * r2;
    float tau = (rDotBeta + sqrt(disc)) / oneMinusBeta2;
    float2 nHat = (r + beta * tau) / tau;
    float kappa = 1.0 - dot(nHat, beta);
    float2 nMinusBeta = nHat - beta;
    float eMag = oneMinusBeta2 * length(nMinusBeta) / (kappa * kappa * kappa * tau * tau);
    return log(1.0 + eMag * 100000.0);
}

fragment float4 itlLWEFragmentShader(ItLLWEPacket in [[stage_in]],
                                     constant ItLLWEContext &ctx [[buffer(0)]]) {
    float2 r = in.worldPos - ctx.cameraPos;

    float2 beta = ctx.beta;
    float beta2 = dot(beta, beta);
    float oneMinusBeta2 = 1.0 - beta2;
    if (oneMinusBeta2 < 1e-4) return float4(0.0);

    float logE = itlLogE(r, beta, oneMinusBeta2);
    bool inDisc = logE >= ITL_CUTOFF_LOG;

    // Outside the disc — paint an offset drop shadow.  Computed as the disc
    // shape sampled at (r − shadowOffset).  Soft blurred edge via a screen-
    // pixel-wide smoothstep on logE_s near the cutoff, plus the same band-
    // boundary lines as the disc itself so the shadow shows the contour
    // structure too.
    if (!inDisc) {
        const float2 shadowOffset = float2(-50.0, 30.0);  // down-left in world (Y points down)
        float logE_s = itlLogE(r - shadowOffset, beta, oneMinusBeta2);

        const float blurPixels = 28.0;
        float gradLogE = max(fwidth(logE_s), 1e-4);
        float blurWidth = blurPixels * gradLogE;
        float shadowFade = smoothstep(ITL_CUTOFF_LOG - blurWidth,
                                      ITL_CUTOFF_LOG + 0.5 * blurWidth,
                                      logE_s);
        if (shadowFade <= 0.001) return float4(0.0);

        // Sample the disc's bands/lines at the shadow position and just
        // darken them — the shadow is the disc's own colours seen through
        // less light, like the red shadow under a red translucent sheet.
        float scaled_s = itlScaledFromLogE(logE_s);
        float scaledByLevels_s = clamp(scaled_s * ITL_LEVELS, 0.0, ITL_LEVELS - 0.001);
        float bandIdx_s = floor(scaledByLevels_s);
        float bandFrac_s = scaledByLevels_s - bandIdx_s;
        float screenStep_s = fwidth(scaledByLevels_s);
        float lineMix_s = smoothstep(0.0, 1.5 * screenStep_s, bandFrac_s);

        int idx_s = clamp(int(bandIdx_s), 0, 6);
        float3 bandCol_s = ITL_PALETTE[idx_s];
        bandCol_s *= 0.85 + 0.15 * bandFrac_s;
        float3 lineCol_s = bandCol_s * 0.15;

        // Darken for shadow.  Band stays visibly tinted; line goes near-black.
        const float shadowMultiplier = 0.45;
        float3 shadowCol = mix(lineCol_s, bandCol_s, lineMix_s) * shadowMultiplier;
        return float4(shadowCol, 0.35 * shadowFade);
    }

    // Inside the disc — paint the band colour.  Equal-width bands in r.
    float scaled = itlScaledFromLogE(logE);
    // Clamp just below ITL_LEVELS so the saturation core never lands on a
    // band boundary (otherwise the core paints as a "line", reading as black).
    float scaledByLevels = clamp(scaled * ITL_LEVELS, 0.0, ITL_LEVELS - 0.001);
    float bandIdx = floor(scaledByLevels);
    float bandFrac = scaledByLevels - bandIdx;

    int idx = clamp(int(bandIdx), 0, 6);
    float3 col = ITL_PALETTE[idx];

    // Plastic shading inside each band.
    col *= 0.85 + 0.15 * bandFrac;

    // Dividing line at the OUTER edge of each band only (bandFrac near 0).
    // No line at the inner edge ⇒ saturation core fills the inner band cleanly.
    float screenStep = fwidth(scaledByLevels);
    float lineMix = smoothstep(0.0, 1.5 * screenStep, bandFrac);

    float3 lineColor = col * 0.15;
    float bandAlpha = 0.55;
    float lineAlpha = 0.95;

    float3 finalCol = mix(lineColor, col, lineMix);
    float finalAlpha = mix(lineAlpha, bandAlpha, lineMix);
    return float4(finalCol, finalAlpha);
}
