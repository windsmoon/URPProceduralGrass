#ifndef CUBIC_BEZIER_INCLUDED
#define CUBIC_BEZIER_INCLUDED

float3 CubicBezier(float3 p0, float3 p1, float3 p2, float3 p3, float t)
{
    float omt = 1 - t;
    float omt2 = omt * omt;
    float t2 = t * t;
    return p0 * (omt * omt2) +
           p1 * (3 * omt2 * t) +
           p2 * (3 * omt * t2) +
           p3 * (t * t2);
}


// 插值版本
float3 CubicBezier2(float3 p0, float3 p1, float3 p2, float3 p3, float t)
{
    float3 a = lerp(p0, p1, t);
    float3 b = lerp(p2, p3, t);
    float3 c = lerp(p1, p2, t);
    float3 d = lerp(a, c, t);
    float3 e = lerp(c, b, t);
    return lerp(d, e, t);
}

#endif
