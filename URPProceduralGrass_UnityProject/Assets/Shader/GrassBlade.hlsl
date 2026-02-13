// #ifndef GRASS_BLADE_INCLUDED
// #define GRASS_BLADE_INCLUDED
//
// #include "CubicBezier.hlsl"
//
// // 如图 Tilt 所示
// float3 GetP0()
// {
//     return float3(0, 0, 0);
// }
//
// // 如图 Tilt 所示
// float3 GetP3(float height, float tilt)
// {
//     float p3y = tilt * height;
//     float p3x = sqrt(height * height - p3y * p3y);
//     return float3(-p3x, p3y, 0); // xz平面
// }
//
// // 如图 Tilt 所示
// float3 GetP1P2(float3 p0, float3 p3, float p1Offset, float p2Offset, out float3 p1, out float3 p2)
// {
//     p1 = lerp(p0, p3, 0.33);
//     p2 = lerp(p1, p3, 0.66);
//     float3 bladeDir = normalize(p3 - p0);
//
//     float3 bezierCtrolOffsetDir = normalize(cross(bladeDir, float3(0, 0, 1)));
//     p1 += bezierCtrolOffsetDir * p1Offset;
//     p2 += bezierCtrolOffsetDir * p2Offset;
// }
//
// #endif