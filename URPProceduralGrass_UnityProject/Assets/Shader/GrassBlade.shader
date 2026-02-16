Shader "URP Procedural Grass/GrassBlade"
{
    Properties
    {
        [Header(Shape)]
        _Height("Height", Float) = 1 // 草叶高度
        _Tilt("Tilt", Range(0, 1)) = 1 // 草尖到地面的高度/草长，其实控制的是草尖到底部的倾斜程度，如图 Tilt 所示
        _BladeWidth("Blade Width", Float) = 0.1 // 草叶的底部宽度
        _TaperAmount("Taper Amount", Range(0, 1)) = 0 // 随着高度升高，宽度值的衰减
        _CurvedNormalAmount("Curved Normal Amount", Range(0, 5)) = 1 // 两侧法线向外延申的程度
        _P1Offset("P1 Offset", Float) = 0
        _P2Offset("P2 Offset", Float) = 0
        
        [Header(Shading)]
        _TopColor("Top Color", Color) = (0.25, 0.5, 0.5, 1)
        _BottomColor("Top Color", Color) = (0.25, 0.5, 0.5, 1)
        _GrassAlbedo("Grass Albedo", 2D) = "white" {}
        _GrassGloss("Grass Gloss", 2D) = "white" {}
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

            #pragma multi_compile _ _MAIN_LIGHT_SHADOWS _MAIN_LIGHT_SHADOWS_CASCADE _MAIN_LIGHT_SHADOWS_SCREEN
            #pragma multi_compile _ _SHADOWS_SOFT
            
            #pragma vertex vert
            #pragma fragment frag

            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Lighting.hlsl"

            #include "CubicBezier.hlsl"

            struct GrassBlade
            {
                float3 position;
            };

            StructuredBuffer<GrassBlade> _GrassBlades;
            StructuredBuffer<int> _Triangles;
            StructuredBuffer<float4> _Colors;
            StructuredBuffer<float2> _Uvs;
            
            float _Height;
            float _Tilt;
            float _BladeWidth;
            float _TaperAmount;
            float _CurvedNormalAmount;
            float _P1Offset;
            float _P2Offset;

            float4 _TopColor;
            float4 _BottomColor;
            TEXTURE2D(_GrassAlbedo);
            SAMPLER(sampler_GrassAlbedo);
            TEXTURE2D(_GrassGloss);
            SAMPLER(sampler_GrassGloss);
            
            struct Attributes
            {
                uint VertexID : SV_VertexID;
                uint instanceID : SV_InstanceID;
            };

            struct Varyings
            {
                float4 positionCS : SV_POSITION;
                float3 positionWS : TEXCOORD0;
                float3 curvedNormalWS : TEXCOORD1;
                float3 originalNormalWS : TEXCOORD2;
                float2 uv : TEXCOORD03;
                float t : TEXCOORD4;
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

                int vertexIndex = _Triangles[input.VertexID];
                float4 vertexColor = _Colors[vertexIndex];
                float2 uv = _Uvs[vertexIndex];
                GrassBlade grassBlade = _GrassBlades[input.instanceID];

                // 如图 VertexColor 所示
                float t = vertexColor.r;
                float3 centerPos = CubicBezier(p0, p1, p2, p3, t);
                float width = _BladeWidth * (1 - _TaperAmount * t);
                float side = vertexColor.g * 2 - 1;
                float3 positionWS = grassBlade.position + centerPos + float3(0, 0, side * width);

                float3 tangent = CubicBezierTanget(p0, p1, p2, p3, t);
                float3 normal = normalize(cross(tangent, float3(0, 0, 1)));

                float3 curvedNormal = normal;
                curvedNormal.z += side * _CurvedNormalAmount;
                curvedNormal = normalize(curvedNormal);
                
                output.positionCS = TransformWorldToHClip(positionWS);
                output.curvedNormalWS = curvedNormal;
                output.originalNormalWS = normal;
                output.positionWS = positionWS;
                output.uv = uv;
                output.t = t;
                
                return output;
            }
            
            half4 frag(Varyings input, bool isFrontFace : SV_IsFrontFace) : SV_Target
            {
                // 草叶模型是单个面片，所以背面要镜像一下法线
                // 参考图 Mesh
                float3 n = isFrontFace ? normalize(input.curvedNormalWS) : -reflect(-normalize(input.curvedNormalWS), normalize(input.originalNormalWS));                

                Light mainLight = GetMainLight(TransformWorldToShadowCoord(input.positionWS));
                float3 viewDir = normalize(GetCameraPositionWS() - input.positionWS);

                float3 grasAlbedo = saturate(_GrassAlbedo.Sample(sampler_GrassAlbedo, input.uv));
                float4 grassColor = lerp(_BottomColor, _TopColor, input.t);
                float3 albedo = grassColor.rgb * grasAlbedo;
                float gloss = (1 - _GrassGloss.Sample(sampler_GrassGloss, input.uv).r) * 0.2;
                half3 gi = SampleSH(n);


                // 没有贴图
                float smoothness = 0.5;
                
                half nDotL = saturate(dot(n, mainLight.direction));
                BRDFData brdfData;
                half alpha = 1;
                InitializeBRDFData(albedo, 0, half3(1, 1, 1), smoothness, alpha, brdfData);
                float3 directBrdfColor = DirectBDRF(brdfData, n, mainLight.direction, viewDir, false) * mainLight.color * nDotL;
                float3 finalColor = gi * albedo + directBrdfColor * (mainLight.shadowAttenuation * mainLight.distanceAttenuation);

                float4 color = float4(finalColor, grassColor.a);
                return color;
            }
            ENDHLSL
        }
    }
}