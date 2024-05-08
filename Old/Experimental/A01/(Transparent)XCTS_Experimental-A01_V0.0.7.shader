Shader "XCTS_Experimental-A01/Transparent_V0.0.7"
{
    Properties
    {
        [Header(Base Color)]
        [Enum(OFF, 0, FRONT, 1, BACK, 2)] _Cull ("Cull Mode", int) = 0
        [MainTexture] _BaseMap ("Albedo", 2D) = "white" {}
        [MainColor] _BaseColor ("Base Color", Color) = (1, 1, 1)
        _Cutoff ("Alpha Cutoff", Range(0, 1)) = 0.5
        [Normal] _BumpMap ("Normal Map", 2D) = "bump" {}
        _BumpScale ("Normal Map Scale", float) = 1
        [ToggleOff] _NormalReverse ("Normal Reverse", int) = 0
        [ToggleOff] _SolidTransparency ("Solid Transparency", int) = 0

        [Header(Lighting And Shading)]
        [Enum(Solid Color, 0, Environment, 1)] _LightingMode ("Lighting Mode", int) = 0
        [Enum(Always On, 0, From Lighting Mode, 1)] _EnvironmentReflection ("Environment Reflection", int) = 0
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
        [ToggleOff] _IgnoreNormalMapRimLight ("Ignore Normal Map", int) = 0
        [HDR] _RimLightColor ("Color", Color) = (1, 1, 1)
        _RimLightIntensity ("Intensity", Range(0, 1)) = 0
        _DecreaseShadingRimLight ("Decrease Shading RimLight", Range(0, 1)) = 0
        _RimLightAlbedoMix ("Albedo Mix (Multiply)", Range(0, 1)) = 0.75
        _RimLightBias ("Bias", Range(-1, 1)) = 0
        _RimLightSmoothstep ("Smoothstep", Range(0, 1)) = 0

        [Header(Emission)]
        [HDR] _EmissionColor ("Color", Color) = (0, 0, 0)
        _EmissionMap ("Emission", 2D) = "white" {}

        [Header(Shade Enhancement 3.0)]
        _ShadeEnhancementColor ("Shade Enhancement Color", Color) = (0.5, 0.5, 0.5)
        _ShadeEnhancementIntensity ("Intensity", Range(0, 1)) = 0

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
            float _BumpScale;
            int _NormalReverse;
            int _SolidTransparency;

            int _LightingMode;
            int _EnvironmentReflection;
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

            int _IgnoreNormalMapRimLight;
            float3 _RimLightColor;
            float _RimLightIntensity;
            float _DecreaseShadingRimLight;
            float _RimLightAlbedoMix;
            float _RimLightBias;
            float _RimLightSmoothstep;

            float3 _EmissionColor;

            float3 _ShadeEnhancementColor;
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

            TEXTURE2D(_CameraDepthTexture);
            float2 _CameraDepthTexture_TexelSize;
            SAMPLER(sampler_CameraDepthTexture);

            //SAMPLER(sampler_unity_SpecCube0);

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
                float mainLightShadowStrength = _MainLightShadowParams.x;
                float3 ambientColor = float3(unity_SHAr.w, unity_SHAg.w, unity_SHAb.w) * _LightingMode;

                float3 lightDirection = normalize(mainLight.direction);//以相机方向为光照方向
                float3 normal = normalize(i.normalWS);
                float3 tangent = normalize(i.tangentWS);
                float3 binormal = normalize(i.binormalWS);

                float3x3 TBNmatrix = {tangent, binormal, normal};
                float3 originalNormal = normal;
                normal = mul(unpackedNormalMap, TBNmatrix);

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
                float linear01ShadowFactor = floatLerp(1, 1 - (1 - MainLightRealtimeShadow(i.shadowCoord)) / max(mainLightShadowStrength, 0.001), _ReceiveShadow);
                float linear01LightingFactor = (linear01DiffuseFactor * linear01ShadowFactor) * occlusion;
                linear01LightingFactor = floatLerp(1, linear01LightingFactor, mainLightShadowStrength);
                float linear01ShadingFactor = 1 - linear01LightingFactor;
                float3 solidMainLightingColor = _LightingColor * linear01LightingFactor + _ShadingColor * linear01ShadingFactor;
                float3 environmentMainLightingColor = mainLightColor * linear01LightingFactor;
                float3 finalMainLightingColor = float3Lerp(solidMainLightingColor, environmentMainLightingColor, _LightingMode);
                //-------结束主光源光照计算-------

                //-------次级光源光照计算-------
                float3 finalAdditionalLightingColor = float3(0, 0, 0);
                if (_EnableAdditionalLight == 1)
                {
                    int pixelLightCount = GetAdditionalLightsCount();
                    for (int lightIndex = 0; lightIndex < pixelLightCount; lightIndex ++)
                    {
                        Light additionalLight = GetAdditionalLight(lightIndex, i.positionWS);
                        float NdotAL = dot(normal, normalize(additionalLight.direction));
                        float linear01AdditionalLightingFactor = smoothstep(0.5 - _DiffuseShadowSmoothstep * 0.5, 0.5 + _DiffuseShadowSmoothstep * 0.5, NdotAL - _DiffuseShadowBias) * additionalLight.distanceAttenuation * occlusion;
                        finalAdditionalLightingColor += additionalLight.color.rgb * linear01AdditionalLightingFactor;
                    }
                }
                //-------结束次级光源光照计算-------

                //-------高光计算-------
                float4 specularMap = SAMPLE_TEXTURE2D(_SpecularMap, sampler_SpecularMap, (i.uv + _SpecularMap_ST.zw) * _SpecularMap_ST.xy);
                float roughness = (specularMap.a * _Roughness) * 0.95 + 0.05;
                float finalNDF = saturate(ceil(_Anisotropic)) * Distribution_GGX_Anisotropic(roughness, _Anisotropic, NdotH, halfDirection, tangent, binormal) + saturate(ceil(-_Anisotropic)) * Distribution_GGX_Anisotropic(roughness, -_Anisotropic, NdotH, halfDirection, binormal, tangent) + saturate(floor(1 - abs(_Anisotropic))) * Distribution_GGX(roughness, NdotH);
                float finalGAF = Vis_Schlick(roughness, NdotV, NdotL);
                float3 linear01SpecularFactor = smoothstep(0.5 - _SpecularSmoothstep * 0.5, 0.5 + _SpecularSmoothstep * 0.5, finalNDF * finalGAF * saturate(0.25 / NdotV / NdotL)) * _SpecularIntensity * linear01LightingFactor;
                //float3 environmentCube = SAMPLE_TEXTURECUBE(unity_SpecCube0, sampler_unity_SpecCube0, reflectionDirection).rgb;
                float3 environmentCube = GlossyEnvironmentReflection(reflectionDirection, roughness, occlusion);
                float3 finalEnvironmentReflectionColor = floatLerp(1, _LightingMode, _EnvironmentReflection) * float3Lerp(environmentCube, float3(0, 0, 0), roughness) * pow(saturate(1 - NdotV), roughness);
                float3 finalSpecularColor = (specularMap.rgb + finalEnvironmentReflectionColor) * linear01SpecularFactor / roughness;
                //-------结束高光计算-------

                //-------暗部增强计算-------
                float3 shadeEnhancementColor = _ShadeEnhancementColor.rgb * albedo.rgb;
                float linear01ShadeEnhancementFactor = pow(1 - saturate(NdotV), 2 * roughness) * _ShadeEnhancementIntensity;
                diffuse = float3Lerp(diffuse, shadeEnhancementColor, linear01ShadeEnhancementFactor);
                //-------结束暗部增强计算-------

                //-------边缘光计算-------
                float linear01RimLightFactor = smoothstep(0.5 - _RimLightSmoothstep * 0.5, 0.5 + _RimLightSmoothstep * 0.5, (1 - saturate(floatLerp(NdotV, ONdotV, _IgnoreNormalMapRimLight) - _RimLightBias * 0.5))) * _RimLightIntensity;
                linear01RimLightFactor *= floatLerp(1, 1 - _DecreaseShadingRimLight, linear01ShadingFactor);
                float3 finalRimLightColor = float3Lerp(_RimLightColor, _RimLightColor * albedo, _RimLightAlbedoMix);
                diffuse = float3Lerp(diffuse, diffuse + finalRimLightColor, linear01RimLightFactor);
                //-------结束边缘光计算-------

                //-------自发光计算-------
                float3 emissionMap = SAMPLE_TEXTURE2D(_EmissionMap, sampler_EmissionMap, (i.uv + _EmissionMap_ST.zw) * _EmissionMap_ST.xy).rgb;
                float3 finalEmissionColor = _EmissionColor.rgb * emissionMap;
                //-------结束自发光计算-------

                float3 finalEnvironmentColor = diffuse * (2 - roughness) * (ambientColor + finalEnvironmentReflectionColor);
                float3 finalColor = (diffuse + finalSpecularColor) * (finalMainLightingColor + finalAdditionalLightingColor) + finalEnvironmentColor + finalEmissionColor;
                float finalTransparency = floatLerp(floatLerp(1, baseMap.a, _SolidTransparency), baseMap.a, pow(saturate(NdotV), 0.1));
                return float4(finalColor, finalTransparency);
            }

            ENDHLSL
            
        }
    }
    FallBack "Packages/com.unity.render-pipelines.universal/FallbackError"
}
