Shader "XCTS_Experimental-A01/Opaque_V0.0.3"
{
    Properties
    {
        [Header(Base Color)]
        _CameraFarClip ("Camera Far Clip (affect rim light in depth mode)", float) = 15
        [Enum(OFF, 0, FRONT, 1, BACK, 2)] _Cull ("Cull Mode", int) = 0
        [MainTexture] _BaseMap ("Albedo", 2D) = "white" {}
        [MainColor] _BaseColor ("Base Color", Color) = (1, 1, 1)
        _Cutoff ("Alpha Cutoff", Range(0, 1)) = 0.5
        [Normal] _BumpMap ("Normal Map", 2D) = "bump" {}
        _BumpScale ("Normal Map Scale", float) = 1
        [ToggleOff] _NormalReverse ("Normal Reverse", int) = 0

        [Header(Lighting And Shading)]
        [Enum(Solid Color, 0, Environment, 1)] _LightingMode ("Lighting Mode", int) = 0
        [ToggleOff] _ReceiveShadow ("Receive Shadow", int) = 0
        [ToggleOff] _EnableAdditionalLight ("Enable Additional Light", int) = 1
        _LightingDirectionFix ("Lighting Direction Fix", Range(0, 1)) = 0
        _LightingColor ("Lighting Color (is enabled in solid color lighting)", Color) = (1, 1, 1)
        _ShadingColor ("Shading Color (is enabled in solid color lighting)", Color) = (0.5, 0.5, 0.5)
        _OcclusionMap ("Occlusion Map", 2D) = "white" {}
        _DiffuseShadowBias ("Bias", Range(-1, 1)) = 0
        _DiffuseShadowSmoothstep ("Smoothstep", Range(0, 1)) = 0.05

        [Header(Specular)]
        _SpecularMap ("Specular Map (Alpha Channel For Roughness)", 2D) = "white" {}
        _SpecularIntensity ("Specular Intensity", Range(0, 10)) = 0
        _Roughness ("Roughness", Range(0, 1)) = 1
        _Anisotropic ("Anisotropic", Range(-1, 1)) = 0
        _SpecularSmoothstep ("Smoothstep", Range(0, 1)) = 1

        [Header(Rim Light)]
        [Enum(Fresnel,0,Depth,1)] _RimLightMode ("Mode", int) = 0
        [ToggleOff] _IgnoreNormalMapRimLight ("Ignore Normal Map", int) = 0
        [HDR] _RimLightColor ("Color", Color) = (1, 1, 1)
        _RimLightIntensity ("Intensity", Range(0, 1)) = 0
        _RimLightAlbedoMix ("Albedo Mix (Multiply)", Range(0, 1)) = 0.75
        _RimLightBias ("Bias", Range(-1, 1)) = 0
        _RimLightSmoothstep ("Smoothstep", Range(0, 1)) = 0

        [Header(Emission)]
        [HDR] _EmissionColor ("Color", Color) = (0, 0, 0)
        _EmissionMap ("Emission", 2D) = "white" {}

        [Header(Outline)]
        _OutlineScale ("Scale", Range(0, 1)) = 0.5
        [HDR] _OutlineColor ("Color", Color) = (0, 0, 0)

        [Header(Shade Enhancement 3.0)]
        _ShadeEnhancementMap ("Shade Enhancement Map (is similar with darker albedo)", 2D) = "black"{}
        _ShadeEnhancementIntensity ("Intensity", Range(0, 1)) = 0

    }
    SubShader
    {
        Tags
        {
            "RenderPipeline" = "UniversalPipeline"
            "RenderType" = "Opaque"
            "Queue" = "AlphaTest"
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

            float _CameraFarClip;
            float3 _BaseColor;
            float _Cutoff;
            float _BumpScale;
            int _NormalReverse;

            int _LightingMode;
            int _ReceiveShadow;
            int _EnableAdditionalLight;
            float _LightingDirectionFix;
            float3 _LightingColor;
            float3 _ShadingColor;
            float _DiffuseShadowBias;
            float _DiffuseShadowSmoothstep;

            float _SpecularIntensity;
            float _Roughness;
            float _Anisotropic;
            float _SpecularSmoothstep;

            int _RimLightMode;
            int _IgnoreNormalMapRimLight;
            float3 _RimLightColor;
            float _RimLightIntensity;
            float _RimLightAlbedoMix;
            float _RimLightBias;
            float _RimLightSmoothstep;

            float3 _EmissionColor;

            float _ShadeEnhancementIntensity;

            CBUFFER_END

            TEXTURE2D(_BaseMap);
            float4 _BaseMap_ST;
            SAMPLER(sampler_BaseMap);

            TEXTURE2D(_BumpMap);
            float4 _BumpMap_ST;
            SAMPLER(sampler_BumpMap);

            TEXTURE2D(_OcclusionMap);
            float4 _OcclusionMap_ST;
            SAMPLER(sampler_OcclusionMap);

            TEXTURE2D(_SpecularMap);
            float4 _SpecularMap_ST;
            SAMPLER(sampler_SpecularMap);

            TEXTURE2D(_EmissionMap);
            float4 _EmissionMap_ST;
            SAMPLER(sampler_EmissionMap);

            TEXTURE2D(_ShadeEnhancementMap);
            float4 _ShadeEnhancementMap_ST;
            SAMPLER(sampler_ShadeEnhancementMap);

            TEXTURE2D(_CameraDepthTexture);
            float2 _CameraDepthTexture_TexelSize;
            SAMPLER(sampler_CameraDepthTexture);

            SAMPLER(sampler_unity_SpecCube0);

            struct Attributes
            {
                float4 positionOS : POSITION;
                float3 normalOS : NORMAL;
                float4 tangentOS : TANGENT;
                float2 uv : TEXCOORD0;
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
            
            float3 float3Lerp(float3 a, float3 b, float c)//用于0-1插值两种颜色的函数
            {
                return a * (1 - c) + b * c;
            }

            float floatLerp(float a, float b, float c)//用于0-1插值两个数的函数
            {
                return a * (1 - c) + b * c;
            }

            Varyings vert(Attributes v)
            {
                Varyings o;
                ZERO_INITIALIZE(Varyings, o);
                o.positionWS = TransformObjectToWorld(v.positionOS.xyz);
                o.positionCS = TransformWorldToHClip(o.positionWS);
                o.positionSS = ComputeScreenPos(o.positionCS);
                o.normalWS = TransformObjectToWorldNormal(v.normalOS);
                o.normalWS = float3Lerp(o.normalWS, -o.normalWS, _NormalReverse);
                o.tangentWS = TransformObjectToWorldDir(v.tangentOS.xyz);
                o.binormalWS = cross(normalize(o.normalWS), normalize(o.tangentWS)) * v.tangentOS.w * unity_WorldTransformParams.w;
                o.uv = v.uv;
                return o;
            }            

            //-------法线分布函数 (NDF) -------

            //GGX / Trowbridge-Reitz (UE4)
            float Distribution_GGX(float Roughness, float NoH)
            {
                float a = Roughness * Roughness;
                float a2 = a * a;
                return a2 / (3.14 * pow(pow(NoH, 2) * (a2 - 1) + 1, 2));
            }

            //Anisotropic GGX, Burley 2012, "Physically-Based Shading at Disney"
            float Distribution_GGX_Anisotropic(float Roughness, float Anisotropic, float NoH, float3 H, float3 X, float3 Y)
            {
                float RoughnessX = 0.99 * Roughness * (1.0 + Anisotropic * 0.5) + 0.01;
                float RoughnessY = 0.99 * Roughness * (1.0 - Anisotropic * 0.5) + 0.01;
                float ax = RoughnessX * RoughnessX;
                float ay = RoughnessY * RoughnessY;
                float XoH = dot(X, H);
                float YoH = dot(Y, H);
                float d = XoH * XoH / (ax * ax) + YoH * YoH / (ay * ay) + NoH * NoH;
                return 1 / (PI * ax * ay * d * d);
            }

            //-------法线分布函数 (NDF) -------

            //-------几何衰减因子 (Geometrical Attenuation Factor) -------

            //Schlick (UE4)
            float Vis_Schlick(float Roughness, float NoV, float NoL)
            {
                float k = pow(Roughness * 0.5 + 0.5, 2) * 0.5;
                float Vis_SchlickV = NoV / (NoV * (1 - k) + k);
                float Vis_SchlickL = NoL / (NoL * (1 - k) + k);
                return Vis_SchlickV * Vis_SchlickL;
            }

            //-------几何衰减因子 (Geometrical Attenuation Factor) -------

            float4 frag(Varyings i): SV_Target
            {
            
                //-------前期准备-------
                float4 baseMap = SAMPLE_TEXTURE2D(_BaseMap, sampler_BaseMap, (i.uv + _BaseMap_ST.zw) * _BaseMap_ST.xy);
                clip(baseMap.a - _Cutoff);
                float3 albedo = baseMap.rgb * _BaseColor;
                float3 diffuse = albedo;

                float4 normalMap = SAMPLE_TEXTURE2D(_BumpMap, sampler_BumpMap, (i.uv + _BumpMap_ST.zw) * _BumpMap_ST.xy);
                float3 unpackedNormalMap = UnpackNormalScale(normalMap, _BumpScale);
                unpackedNormalMap.z = pow((1 - pow(unpackedNormalMap.x, 2) - pow(unpackedNormalMap.y,2)), 0.5);

                Light mainLight = GetMainLight();
                float3 mainLightColor = mainLight.color.rgb;
                float3 ambientColor = float3(unity_SHAr.w, unity_SHAg.w, unity_SHAb.w) * _LightingMode;

                float3 lightDirection = normalize(mainLight.direction);//以相机方向为光照方向
                float3 normal = normalize(i.normalWS);
                float3 tangent = normalize(i.tangentWS);
                float3 binormal = normalize(i.binormalWS);

                float3x3 TBNmatrix = {tangent, binormal, normal};
                float3 originalNormal = normal;
                normal = mul(unpackedNormalMap, TBNmatrix);
                normal = normalize(normal);

                float3 viewDirection = normalize(_WorldSpaceCameraPos.xyz - i.positionWS);
                float3 halfDirection = normalize(lightDirection + viewDirection);
                float3 reflectionDirection = reflect(-viewDirection, normal);

                float NdotV = dot(normal, viewDirection);
                float NdotL = dot(normal, lightDirection);
                float NdotH = dot(normal, halfDirection);
                float ONdotV = dot(originalNormal, viewDirection);
                float ONdotL = dot(originalNormal, lightDirection);
                float ONdotH = dot(originalNormal, halfDirection);
                float VdotL = dot(viewDirection, lightDirection);
                float VdotH = dot(viewDirection, halfDirection);
                float LdotH = dot(lightDirection, halfDirection);
                float BdotH = dot(binormal, halfDirection);
                float LdotB = dot(lightDirection, binormal);
	            float VdotB = dot(viewDirection, binormal);
                //-------结束前期准备-------

                //-------主光源光照计算-------
                float occlusion = SAMPLE_TEXTURE2D(_OcclusionMap, sampler_OcclusionMap, (i.uv + _OcclusionMap_ST.zw) * _OcclusionMap_ST.xy).r;
                float3 fixedLightDirection = normalize(float3Lerp(lightDirection, float3(lightDirection.x, 0, lightDirection.z), _LightingDirectionFix));
                NdotL = dot(normal, fixedLightDirection);
                float linear01DiffuseFactor = smoothstep(0.5 - _DiffuseShadowSmoothstep * 0.5, 0.5 + _DiffuseShadowSmoothstep * 0.5, NdotL - _DiffuseShadowBias);
                i.shadowCoord = TransformWorldToShadowCoord(i.positionWS);
                float linear01ShadowFactor = floatLerp(1, MainLightRealtimeShadow(i.shadowCoord), _ReceiveShadow);
                float linear01LightingFactor = linear01DiffuseFactor * linear01ShadowFactor * occlusion;
                float linear01ShadingFactor = 1 - linear01LightingFactor;
                float3 solidMainLightingColor = _LightingColor * linear01LightingFactor + _ShadingColor * linear01ShadingFactor;
                float3 environmentMainLightingColor = mainLightColor * linear01LightingFactor;
                float3 finalMainLightingColor = float3Lerp(solidMainLightingColor, environmentMainLightingColor, _LightingMode);
                //-------结束主光源光照计算-------

                //-------次级光源光照计算-------
                int pixelLightCount = GetAdditionalLightsCount();
                float3 finalAdditionalLightingColor = float3(0, 0, 0);
                for (int lightIndex = 0; lightIndex < pixelLightCount; lightIndex ++)
                {
                    Light additionalLight = GetAdditionalLight(lightIndex, i.positionWS);
                    float NdotAL = dot(normal, normalize(additionalLight.direction));
                    float linear01AdditionalLightingFactor = smoothstep(0.5 - _DiffuseShadowSmoothstep * 0.5, 0.5 + _DiffuseShadowSmoothstep * 0.5, NdotAL - _DiffuseShadowBias) * additionalLight.distanceAttenuation * occlusion;
                    finalAdditionalLightingColor += additionalLight.color.rgb * linear01AdditionalLightingFactor;
                }
                //-------结束次级光源光照计算-------

                //-------高光计算-------
                float4 specularMap = SAMPLE_TEXTURE2D(_SpecularMap, sampler_SpecularMap, (i.uv + _SpecularMap_ST.zw) * _SpecularMap_ST.xy);
                float roughness = (specularMap.a * _Roughness) * 0.9 + 0.1;
                float finalNDF = saturate(ceil(_Anisotropic)) * Distribution_GGX_Anisotropic(roughness, _Anisotropic, NdotH, halfDirection, tangent, binormal) + saturate(ceil(-_Anisotropic)) * Distribution_GGX_Anisotropic(roughness, -_Anisotropic, NdotH, halfDirection, binormal, tangent) + saturate(floor(1 - abs(_Anisotropic))) * Distribution_GGX(roughness, NdotH);
                float finalGAF = Vis_Schlick(roughness, NdotV, NdotL);
                float3 linear01SpecularFactor = smoothstep(0.5 - _SpecularSmoothstep * 0.5, 0.5 + _SpecularSmoothstep * 0.5, finalNDF * finalGAF * saturate(0.25 / NdotV / NdotL)) * _SpecularIntensity * linear01LightingFactor;
                float3 finalSpecularColor = specularMap.rgb * linear01SpecularFactor;
                float3 environmentCube = SAMPLE_TEXTURECUBE(unity_SpecCube0, sampler_unity_SpecCube0, reflectionDirection).rgb;
                float3 finalEnvironmentReflectionColor = _LightingMode * float3Lerp(environmentCube, float3(0, 0, 0), roughness) * specularMap.rgb * _SpecularIntensity * pow(saturate(1 - NdotV), roughness);
                finalSpecularColor += finalEnvironmentReflectionColor;
                //-------结束高光计算-------

                //-------暗部增强计算-------
                float3 shadeEnhancementColor = SAMPLE_TEXTURE2D(_ShadeEnhancementMap, sampler_ShadeEnhancementMap, (i.uv + _ShadeEnhancementMap_ST.zw) * _ShadeEnhancementMap_ST.xy).rgb;
                float linear01ShadeEnhancementFactor = pow(1 - saturate(NdotV), 2 * roughness) * _ShadeEnhancementIntensity;
                diffuse = float3Lerp(diffuse, shadeEnhancementColor, linear01ShadeEnhancementFactor);
                //-------结束暗部增强计算-------

                //-------边缘光计算-------
                float linear01FresnelRimLightFactor = smoothstep(0.5 - _RimLightSmoothstep * 0.5, 0.5 + _RimLightSmoothstep * 0.5, (1 - saturate(floatLerp(NdotV, ONdotV, _IgnoreNormalMapRimLight) - _RimLightBias * 0.5)));
                float2 screenUV = ComputeScreenPos(TransformWorldToHClip(i.positionWS)).xy / i.positionSS.w;
                float2 screenUVTranslation = ComputeScreenPos(TransformWorldToHClip(i.positionWS + float3Lerp(normal, originalNormal, _IgnoreNormalMapRimLight) * (0.1 + _RimLightBias * 0.1))).xy / i.positionSS.w;
                screenUVTranslation = float2(min(saturate(screenUVTranslation.x), 1 - _CameraDepthTexture_TexelSize.x), min(saturate(screenUVTranslation.y), 1 - _CameraDepthTexture_TexelSize.y));
                float linear01Depth = Linear01Depth(SAMPLE_TEXTURE2D(_CameraDepthTexture, sampler_CameraDepthTexture, screenUV).r, _ZBufferParams);
                float linear01DepthTranslation = Linear01Depth(SAMPLE_TEXTURE2D(_CameraDepthTexture, sampler_CameraDepthTexture, screenUVTranslation).r, _ZBufferParams);
                float linear01DepthGap = saturate((linear01DepthTranslation - linear01Depth) * _CameraFarClip);
                float linear01DepthRimLightFactor = smoothstep(0.5 - _RimLightSmoothstep * 0.5, 0.5 + _RimLightSmoothstep * 0.5, linear01DepthGap);

                float linear01RimLightFactor = floatLerp(linear01FresnelRimLightFactor, linear01DepthRimLightFactor, _RimLightMode) * _RimLightIntensity;
                float3 finalRimLightColor = float3Lerp(_RimLightColor, (float3(1, 1, 1) + _RimLightColor) * albedo, _RimLightAlbedoMix);
                diffuse = float3Lerp(diffuse, finalRimLightColor, linear01RimLightFactor);
                //-------结束边缘光计算-------

                //-------自发光计算-------
                float3 emissionMap = SAMPLE_TEXTURE2D(_EmissionMap, sampler_EmissionMap, (i.uv + _EmissionMap_ST.zw) * _EmissionMap_ST.xy).rgb;
                float3 finalEmissionColor = _EmissionColor.rgb * emissionMap;
                //-------结束自发光计算-------

                float3 finalEnvironmentColor = diffuse * (2 - roughness) * (ambientColor + finalEnvironmentReflectionColor);
                float3 finalColor = (diffuse + finalSpecularColor) * (finalMainLightingColor + finalAdditionalLightingColor) + finalEnvironmentColor + finalEmissionColor;
                return float4(finalColor, 1);
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
                positionCS = positionCS + float4(normalize(normalOS), 0) * _OutlineScale * 0.05;
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
            Tags{"LightMode" = "ShadowCaster"}

            ZWrite On
            ZTest LEqual
            ColorMask 0
            Cull[_Cull]

            HLSLPROGRAM
            #pragma exclude_renderers gles gles3 glcore
            #pragma target 4.5

            // -------------------------------------
            // Material Keywords
            #pragma shader_feature_local_fragment _ALPHATEST_ON
            #pragma shader_feature_local_fragment _SMOOTHNESS_TEXTURE_ALBEDO_CHANNEL_A

            //--------------------------------------
            // GPU Instancing
            #pragma multi_compile_instancing
            #pragma multi_compile _ DOTS_INSTANCING_ON

            // -------------------------------------
            // Universal Pipeline keywords

            // This is used during shadow map generation to differentiate between directional and punctual light shadows, as they use different formulas to apply Normal Bias
            #pragma multi_compile_vertex _ _CASTING_PUNCTUAL_LIGHT_SHADOW

            #pragma vertex ShadowPassVertex
            #pragma fragment ShadowPassFragment

            #include "Packages/com.unity.render-pipelines.universal/Shaders/LitInput.hlsl"
            #include "Packages/com.unity.render-pipelines.universal/Shaders/ShadowCasterPass.hlsl"
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
