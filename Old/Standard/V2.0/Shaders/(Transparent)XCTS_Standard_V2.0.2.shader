Shader "XCTS_Standard/Transparent_V2.0.2"
{
    Properties
    {
        [Header(Base Settings)]
        [MainMapture] _BaseMap ("Albedo", 2D) = "white" {}
        _BaseColor ("Base Color", Color) = (1, 1, 1, 1)
        _Cutoff ("Alpha Cutoff", Range(0, 1)) = 0.5
        [Enum(OFF,0,FRONT,1,BACK,2)] _Cull ("Cull Mode", int) = 0
        [ToggleOff] _NormalReverse ("Normal Reverse", int) = 0

        [Header(Main Lighting Settings)]
        [ToggleOff] _ReceiveShadow ("Receive Shadow", int) = 1
        _LightingDirectionFix ("Lighting Direction Fix", Range(0, 1)) = 0
        _LightingColor ("Lighting Color", Color) = (1, 1, 1)
        _ShadingColor ("Shading Color", Color) = (0.5, 0.5, 0.5)
        _DiffuseShadowBias ("Bias", Range(-1, 1)) = 0
        _DiffuseShadowSmoothstep ("Smoothstep", Range(0, 1)) = 0

        [Header(Specular Settings)]
        [Enum(Common,0,Anisotropic,1)] _SpecularMode ("Specular Mode", int) = 0
        [HDR] _SpecularColor ("Specular Color", Color) = (1, 1, 1)
        _SpecularGlossness ("Specular Glossness", Range(1, 256)) = 50
        _SpecularSmoothstep ("Specular Smoothstep", Range(0, 1)) = 1

        [Header(Rim Light Settings)]
        [ToggleOff] _ShadingSideRimLight ("Shading Side Enable", int) = 1
        [HDR] _RimLightColor ("Color", Color) = (1, 1, 1)
        _RimLightAlbedoMix ("Albedo Mix (Multiply)", Range(0, 1)) = 0.5
        _RimLightBias ("Bias", Range(-1, 1)) = 0
        _RimLightSmoothstep ("Smoothstep", Range(0, 1)) = 0

        [Header(Emission Settings)]
        [HDR] _EmissionColor ("Color", Color) = (0, 0, 0)

        [Header(Outline Settings)]
        _OutlineScale ("Scale", Range(0, 1)) = 0.5
        [HDR] _OutlineColor ("Color", Color) = (0, 0, 0)

        [Header(Shade Enhancement Settings)]
        _ShadeEnhancementIntensity ("Intensity", Range(0, 1)) = 0
        _ShadeEnhancementColor ("Color", Color) = (1, 1, 1)
        _ShadeEnhancementBias ("Bias", Range(-1, 1)) = 0
        _ShadeEnhancementSmoothstep ("Smoothstep", Range(0, 1)) = 1
    }
    SubShader
    {
        Tags
        {
            "RenderPipeline" = "UniversalPipeline"
            "RenderType" = "Transparent"
            "Queue" = "Transparent"
            "IgnoreProjector" = "True"
        }
        Pass
        {
            Name "Main"
            Tags
            {
                "LightMode" = "UniversalForward"
            }
            
            Cull [_Cull]
            Blend SrcAlpha OneMinusSrcAlpha
            ZWrite On


            HLSLPROGRAM
            
            #pragma vertex vert
            #pragma fragment frag
            #pragma multi_compile _ _MAIN_LIGHT_SHADOWS
            #pragma multi_compile _ _MAIN_LIGHT_SHADOWS_CASCADE
            #pragma multi_compile _ _SHADOWS_SOFT
            #pragma multi_compile _ _ADDITIONAL_LIGHTS_VERTEX _ADDITIONAL_LIGHTS
            
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Lighting.hlsl"
            #include "Packages/com.unity.render-pipelines.core/ShaderLibrary/SpaceTransforms.hlsl"
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Shadows.hlsl"
            
            CBUFFER_START(UnityPerMaterial)
            float3 _BaseColor;
            float _Cutoff;
            int _NormalReverse;

            int _ReceiveShadow;
            float _LightingDirectionFix;
            float3 _LightingColor;
            float3 _ShadingColor;
            float _DiffuseShadowSmoothstep;
            float _DiffuseShadowBias;

            int _SpecularMode;
            float3 _SpecularColor;
            float _SpecularGlossness;
            float _SpecularSmoothstep;

            int _ShadingSideRimLight;
            float3 _RimLightColor;
            float _RimLightAlbedoMix;
            float _RimLightBias;
            float _RimLightSmoothstep;

            float3 _EmissionColor;

            float _ShadeEnhancementIntensity;
            float3 _ShadeEnhancementColor;
            float _ShadeEnhancementBias;
            float _ShadeEnhancementSmoothstep;

            CBUFFER_END

            TEXTURE2D(_BaseMap);
            float4 _BaseMap_ST;

            #define textureSampler1 SamplerState_Point_Repeat
            SAMPLER(textureSampler1);

            struct Attributes
            {
                float4 positionOS : POSITION;
                float3 normalOS : NORMAL;
                float4 tangentOS : TANGENT;
                float2 uv :TEXCOORD0;
            };
            
            struct Varyings
            {
                float4 positionCS : SV_POSITION;
                float3 positionWS : TEXCOORD0;
                float4 positionSS : TEXCOORD1;
                float3 normalWS : TEXCOORD2;
                float3 tangentWS : TEXCOORD3;
                float3 binormalWS : TEXCOORD4;
                float2 uv : TEXCOORD5;
                float4 shadowCoord : TEXCOORD6;
            };
            
            Varyings vert(Attributes v)
            {
                Varyings o;
                ZERO_INITIALIZE(Varyings, o);
                o.positionWS = TransformObjectToWorld(v.positionOS.xyz);
                o.positionCS = TransformWorldToHClip(o.positionWS);
                o.positionSS = ComputeScreenPos(o.positionCS);
                o.normalWS = TransformObjectToWorldNormal(v.normalOS);
                o.normalWS = o.normalWS * (1 - _NormalReverse) - o.normalWS *_NormalReverse;
                o.tangentWS = TransformObjectToWorldDir(v.tangentOS.xyz);
                o.binormalWS = cross(normalize(o.tangentWS), normalize(o.normalWS)) * v.tangentOS.w * unity_WorldTransformParams.w;
                o.uv = v.uv;
                return o;
            }            

            float3 float3Lerp(float3 a, float3 b, float c)//用于0-1插值两种颜色的函数
            {
                return a * (1 - c) + b * c;
            }

            float floatLerp(float a, float b, float c)//用于0-1插值两个数的函数
            {
                return a * (1 - c) + b * c;
            }

            float4 frag(Varyings i): SV_Target
            {
                //-------前期准备-------
                float4 baseMap = SAMPLE_TEXTURE2D(_BaseMap, textureSampler1, i.uv);
                clip(baseMap.a - _Cutoff);
                float3 albedo = baseMap.rgb * _BaseColor;

                Light mainLight = GetMainLight();

                float3 lightDirection = normalize(mainLight.direction);//以相机方向为光照方向
                float3 normal = normalize(i.normalWS);
                float3 tangent = normalize(i.tangentWS);
                float3 binormal = normalize(i.binormalWS);

                float3 viewDirection = normalize(_WorldSpaceCameraPos.xyz - i.positionWS);
                float3 halfDirection = normalize(lightDirection + viewDirection);

                float NdotV = dot(normal, viewDirection);
                float NdotL = dot(normal, lightDirection);
                float NdotH = dot(normal, halfDirection);
                float VdotL = dot(viewDirection, lightDirection);
                float VdotH = dot(viewDirection, halfDirection);
                float LdotH = dot(lightDirection, halfDirection);
                float BdotH = dot(binormal, halfDirection);
                float LdotB = dot(lightDirection, binormal);
	            float VdotB = dot(viewDirection, binormal);

                //-------结束前期准备-------

                //-------主光源光照计算-------
                float3 fixedLightDirection = normalize(float3Lerp(lightDirection, float3(lightDirection.x, 0, lightDirection.z), _LightingDirectionFix));
                float NdotFL = dot(normal, fixedLightDirection);
                float linear01DiffuseFactor = smoothstep(0.5 - _DiffuseShadowSmoothstep * 0.5, 0.5 + _DiffuseShadowSmoothstep * 0.5, NdotFL - _DiffuseShadowBias);
                i.shadowCoord = TransformWorldToShadowCoord(i.positionWS);
                float linear01ShadowFactor = floatLerp(1, MainLightRealtimeShadow(i.shadowCoord), _ReceiveShadow);
                float linear01LightingFactor = linear01DiffuseFactor * linear01ShadowFactor;
                float linear01ShadingFactor = 1 - linear01LightingFactor;
                float3 finalDiffuseColor = _LightingColor * linear01LightingFactor + _ShadingColor * linear01ShadingFactor;
                //-------结束主光源光照计算-------
                
                //-------次级光源光照计算-------
                int pixelLightCount = GetAdditionalLightsCount();
                float3 finalAdditionalLightingColor = float3(0, 0, 0);
                for (int lightIndex = 0; lightIndex < pixelLightCount; lightIndex ++)
                {
                    Light additionalLight = GetAdditionalLight(lightIndex, i.positionWS);
                    float NdotAL = dot(normal, normalize(additionalLight.direction));
                    float linear01AdditionalLightingFactor = smoothstep(0.5 - _DiffuseShadowSmoothstep * 0.5, 0.5 + _DiffuseShadowSmoothstep * 0.5, NdotAL - _DiffuseShadowBias) * additionalLight.distanceAttenuation;
                    finalAdditionalLightingColor += additionalLight.color.rgb * linear01AdditionalLightingFactor;
                }
                //-------结束次级光源光照计算-------

                //-------高光计算-------
                float linear01SpecularFactorCommon = pow(saturate(NdotH), _SpecularGlossness);
                float linear01SpecularFactorAnisotropic = pow(saturate(sqrt(1 - BdotH * BdotH)), _SpecularGlossness);
                float linear01SpecularFactor = smoothstep(0.5 - _SpecularSmoothstep * 0.5, 0.5 + _SpecularSmoothstep * 0.5, floatLerp(linear01SpecularFactorCommon, linear01SpecularFactorAnisotropic, _SpecularMode));
                float3 finalSpecularColor = _SpecularColor.rgb * linear01SpecularFactor * finalDiffuseColor;
                //-------结束高光计算-------

                //-------边缘光计算-------
                float linear01RimLightFactor = smoothstep(0.5 - _RimLightSmoothstep * 0.5, 0.5 + _RimLightSmoothstep * 0.5, (1 - saturate(NdotV - _RimLightBias * 0.5)));
                linear01RimLightFactor *= floatLerp(linear01DiffuseFactor, 1, _ShadingSideRimLight);
                float3 finalRimLightColor = _RimLightColor.rgb * linear01RimLightFactor * float3Lerp(float3(1, 1, 1), albedo, _RimLightAlbedoMix) * finalDiffuseColor * (float3(1, 1, 1) + finalAdditionalLightingColor);
                //-------结束边缘光计算-------

                //-------自发光计算-------
                float3 finalEmissionColor = _EmissionColor.rgb;
                //-------结束自发光计算-------

                //-------暗部增强计算-------
                float linear01ShadeEnhancementFactor = smoothstep(0.5 - _ShadeEnhancementSmoothstep * 0.5, 0.5 + _ShadeEnhancementSmoothstep * 0.5, (1 - saturate(NdotV - _ShadeEnhancementBias * 0.5)) * (1 - saturate(NdotV)));
                float3 finalShadeEnhancementColor = (_ShadeEnhancementColor.rgb - float3(1, 1, 1)) * _ShadeEnhancementIntensity * linear01ShadeEnhancementFactor;
                //-------结束暗部增强计算-------

                float3 finalColor = albedo * (finalDiffuseColor + finalAdditionalLightingColor + finalSpecularColor + finalEmissionColor + finalShadeEnhancementColor) + finalRimLightColor;
                return float4(finalColor, baseMap.a);
            }

            ENDHLSL
            
        }

        Pass
        {
            Name "Outline"
            Tags 
            { 
                
            }
            
            Cull Front
            ZWrite On

            HLSLPROGRAM
            #pragma vertex vert
            #pragma fragment frag
            #pragma prefer_hlslcc gles
            #pragma exclude_renderers d3d11_9x
            #pragma target 2.0
            #pragma multi_compile_instancing
            
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Lighting.hlsl"
            #include "Packages/com.unity.render-pipelines.core/ShaderLibrary/SpaceTransforms.hlsl"

            CBUFFER_START(UnityPerMaterial)
            float _OutlineScale;
            float4 _OutlineColor;
            float _Cutoff;
            CBUFFER_END

            TEXTURE2D(_BaseMap);
            float4 _BaseMap_ST;

            #define textureSampler1 SamplerState_Point_Repeat
            SAMPLER(textureSampler1);

            struct Attributes
            {
                float4 positionOS : POSITION;
                float3 normalOS : NORMAL;
                float2 uv :TEXCOORD0;
            };
            
            struct Varyings
            {
                float4 positionCS : SV_POSITION;
                float2 uv : TEXCOORD2;

            };
            
            Varyings vert(Attributes v)
            {
                Varyings o = (Varyings)0;
                float4 originalPositionCS = TransformObjectToHClip(v.positionOS.xyz);
                float4 positionCS = mul(UNITY_MATRIX_MV, v.positionOS);
                float3 normalOS = mul((float3x3)UNITY_MATRIX_IT_MV, v.normalOS);
                normalOS.z = -0.5;
                positionCS = positionCS + float4(normalize(normalOS), 0) * _OutlineScale * 0.002;
                o.positionCS = mul(UNITY_MATRIX_P, positionCS);
                o.uv = TRANSFORM_TEX(v.uv, _BaseMap);

                return o;
            }

            float4 frag(Varyings i) : SV_TARGET 
            {
                float4 baseMap = SAMPLE_TEXTURE2D(_BaseMap, textureSampler1, i.uv);
                clip(baseMap.a - _Cutoff);

                return float4(_OutlineColor.rgb, 1);
            }
            
            ENDHLSL
        }

        Pass
        {
            Name "ShadowCaster"

            Cull [_CullMode]

            Tags 
            { 
                "LightMode" = "ShadowCaster"
            }

            HLSLPROGRAM
            #pragma vertex vert
            #pragma fragment frag
            
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"

            CBUFFER_START(UnityPerMaterial)
            float _Cutoff;
            CBUFFER_END

            TEXTURE2D(_BaseMap);
            float4 _BaseMap_ST;

            #define textureSampler1 SamplerState_Point_Repeat
            SAMPLER(textureSampler1);

            struct Attributes
            {
                float4 positionOS : POSITION;
                float3 normalOS : NORMAL;
                float2 uv : TEXCOORD0;
            };
            
            struct Varyings
            {
                float4 positionCS : SV_POSITION;
                float2 uv : TEXCOORD0;

            };
            
            float3 _LightDirection;
            float4 _ShadowBias;
            half4 _MainLightShadowParams;

            float3 ApplyShadowBias(float3 positionWS, float3 normalWS, float3 lightDirection)
            {
                float invNdotL = 1.0 - saturate(dot(lightDirection, normalWS));
                float scale = invNdotL * _ShadowBias.y;
                positionWS = lightDirection * _ShadowBias.xxx + positionWS;
                positionWS = normalWS * scale.xxx + positionWS;
                return positionWS;
            }

            Varyings vert(Attributes v)
            {
                Varyings o = (Varyings)0;
                float3 positionWS = TransformObjectToWorld(v.positionOS.xyz);
                half3 normalWS = TransformObjectToWorldNormal(v.normalOS);
                positionWS = ApplyShadowBias(positionWS, normalWS, _LightDirection);
                o.positionCS = TransformWorldToHClip(positionWS);
                #if UNITY_REVERSED_Z
    	            o.positionCS.z = min(o.positionCS.z, o.positionCS.w * UNITY_NEAR_CLIP_VALUE);
                #else
    	            o.positionCS.z = max(o.positionCS.z, o.positionCS.w * UNITY_NEAR_CLIP_VALUE);
                #endif
                o.uv = v.uv;
                return o;
            }

            half4 frag(Varyings i) : SV_TARGET 
            {    
                float4 baseMap = SAMPLE_TEXTURE2D(_BaseMap, textureSampler1, i.uv);
                clip(baseMap.a - _Cutoff);
                return float4(0, 0, 0, 1);
            }

            ENDHLSL
        }

        Pass
        {
            Name "DepthOnly"
            Tags{"LightMode" = "DepthOnly"}

            ZWrite On
            ColorMask 0
            Cull[_Cull]

            HLSLPROGRAM
            #pragma exclude_renderers gles gles3 glcore
            #pragma target 4.5

            #pragma vertex DepthOnlyVertex
            #pragma fragment DepthOnlyFragment

            // -------------------------------------
            // Material Keywords
            #pragma shader_feature_local_fragment _ALPHATEST_ON
            #pragma shader_feature_local_fragment _SMOOTHNESS_TEXTURE_ALBEDO_CHANNEL_A

            //--------------------------------------
            // GPU Instancing
            #pragma multi_compile_instancing
            #pragma multi_compile _ DOTS_INSTANCING_ON

            #include "Packages/com.unity.render-pipelines.universal/Shaders/LitInput.hlsl"
            #include "Packages/com.unity.render-pipelines.universal/Shaders/DepthOnlyPass.hlsl"
            ENDHLSL
        }

        Pass
        {
            Name "DepthNormals"
            Tags{"LightMode" = "DepthNormals"}

            ZWrite On
            Cull[_Cull]

            HLSLPROGRAM
            #pragma only_renderers gles gles3 glcore d3d11
            #pragma target 2.0

            #pragma vertex DepthNormalsVertex
            #pragma fragment DepthNormalsFragment

            // -------------------------------------
            // Material Keywords
            #pragma shader_feature_local _NORMALMAP
            #pragma shader_feature_local_fragment _ALPHATEST_ON
            #pragma shader_feature_local_fragment _GlossnessINESS_FROM_BASE_ALPHA

            //--------------------------------------
            // GPU Instancing
            #pragma multi_compile_instancing

            #include "Packages/com.unity.render-pipelines.universal/Shaders/SimpleLitInput.hlsl"
            #include "Packages/com.unity.render-pipelines.universal/Shaders/DepthNormalsPass.hlsl"
            ENDHLSL
        }
    }
    FallBack "Packages/com.unity.render-pipelines.universal/FallbackError"
}

