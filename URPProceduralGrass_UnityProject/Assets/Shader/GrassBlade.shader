Shader "URP Procedural Grass/GrassBlade"
{
    Properties
    {
        [Header(Shape)]
        _Height("Height", Float) = 1 // 草叶高度
        _Tilt("Tilt", Range(0, 1)) = 1 // 草尖到地面的高度/草长，其实控制的是草尖到底部的倾斜程度，如图 Tilt 所示
        _BladeWidth("Blade Width", Float) = 0.1 // 草叶的底部宽度
        _TaperAmount("Taper Amount", Range(0, 1)) = 0 // 随着高度升高，宽度值的衰减
        _P1Offset("P1 Offset", Float) = 0
        _P2Offset("P2 Offset", Float) = 0
    }
    SubShader
    {
        Tags { "RenderType" = "Opaque" "RenderPipeline" = "UniversalPipeline"}
        
        Cull Off
        
        Pass
        {
            Name "Simple Grass Blade"
            Tags {"LightMode" = "UniversalForward"}
            
            HLSLPROGRAM
            #pragma prefer_hlslcc gles
            #pragma exclude_renderers d3d11_9x
            #pragma vertex vert
            #pragma fragment frag

            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"

            #include "CubicBezier.hlsl"
            
            float _Height;
            float _Tilt;
            float _BladeWidth;
            float _TaperAmount;
            float _P1Offset;
            float _P2Offset;
            
            struct Attributes
            {
                float4 positionOS : POSITION;
                float2 color : COLOR;
                float2 texcoord : TEXCOORD0;
            };

            struct Varyings
            {
                float4 positionCS : SV_POSITION;
            };

            // 如图 Tilt 所示
            float3 GetP0()
            {
                return float3(0, 0, 0);
            }
            
            // 如图 Tilt 所示
            float3 GetP3(float height, float tilt)
            {
                float p3y = tilt * height;
                float p3x = sqrt(height * height - p3y * p3y);
                return float3(-p3x, p3y, 0); // xz平面
            }
            
            // 如图 Tilt 所示
            void GetP1P2(float3 p0, float3 p3, out float3 p1, out float3 p2)
            {
                p1 = lerp(p0, p3, 0.33);
                p2 = lerp(p1, p3, 0.66);
                float3 bladeDir = normalize(p3 - p0);
            
                float3 bezierCtrolOffsetDir = normalize(cross(bladeDir, float3(0, 0, 1)));
                p1 += bezierCtrolOffsetDir * _P1Offset;
                p2 += bezierCtrolOffsetDir * _P2Offset;
            }

            Varyings vert(Attributes input)
            {
                Varyings output;

                float3 p0 = GetP0();
                float3 p3 = GetP3(_Height, _Tilt);
                float3 p1 = float3(0, 0, 0);
                float3 p2 = float3(0, 0, 0);
                GetP1P2(p0, p3, p1, p2);

                // 如图 VertexColor 所示
                float t = input.color.r;
                float3 centerPos = CubicBezier(p0, p1, p2, p3, t);
                float width = _BladeWidth * (1 - _TaperAmount * t);
                float side = input.color.g * 2 - 1;
                float3 vertexPos = centerPos + float3(0, 0, side * width);

                output.positionCS = TransformObjectToHClip(vertexPos);
                
                return output;
            }
            
            half4 frag(Varyings input) : SV_Target
            {
                return half4(0.0, 1.0, 0.0, 1.0);
            }
            ENDHLSL
        }
    }
}