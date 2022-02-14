Shader "Custom/(NoCastingShadow)URPTestToonShader"
{
    Properties
    {
        [Header(Switch)]
        [ToggleOff]_EnableOutline ("Enable Outline", int) = 1
        [ToggleOff]_EnableDiffuse ("Enable Diffuse", int) = 1
        [ToggleOff]_EnableSpecular ("Enable Specular", int) = 1
        [ToggleOff]_EnableSubSurfaceScattering ("Enable Sub Surface Scattering", int) = 1
        [ToggleOff]_EnableRimLight ("Enable Rim Light", int) = 1

        [Header(Common Settings)]
        _FaceFix ("Face Fix", Range(0.0, 1.0)) = 0.0
        [Enum(OFF,0,ON,1)]_NormalReverse ("Normal Reverse", int) = 0
        [Enum(OFF,0,ON,1)]_ReceiveShadow ("Receive Shadow", int) = 1
        _HeadCenter ("Head Center", Vector) = (0, 0.5, 0, 1)
        [Enum(OFF,0,FRONT,1,BACK,2)]_CullMode ("Cull Mode", int) = 0

        [Header(Outline Settings)]
        _OutlineColor ("Outline Color", Color) = (0, 0, 0, 1)
        _Outline ("Outline", Range(0.0, 0.02)) = 0.002

        [Header(Texture Settings)]
        _BaseTexture ("Base Texture", 2D) = "white"{}
        _BaseColorStrength ("Base Color Strength", Range(0.0, 1.0)) = 1.0
        _AlphaClip ("Alpha Clip", Range(0.0, 1.0)) = 0.1

        [Header(Lighting Settings)]
        _DiffuseColor ("Diffuse Color", Color) = (1, 1, 1, 1)
        _ShadowColor ("Shadow Color", Color) = (0, 0, 0, 1)
        _DiffuseStrength ("Main Lighting Strength", Range(0.0, 1.0)) = 0.5
        _DiffuseBias ("Diffuse Shadow Bias", Range(-1.0, 1.0)) = 0.0
        _DiffuseSmoothstep ("Diffuse Shadow Smoothstep", Range(0.0, 1.0)) = 0.0
        _AdditionalLightStrength ("Additional Light Strength", Range(0.0, 10.0)) = 1.5
        _AdditionalLightBias ("Additional Light Bias", Range(-1.0, 1.0)) = 1.0
        _AdditionalLightSmoothstep ("Additional Light Smoothstep", Range(0.0, 1.0)) = 1.0

        [Header(Specular Settings)]
        _SpecularColor ("Specular Color", Color) = (1, 1, 1, 1)
        _SpecularStrength ("Specular Strength", Range(0.0, 10.0)) = 0.0
        _SpecularGloss ("Specular Range", Range(0.0, 1.0)) = 0.1
        [Enum(OFF,0,ON,1)]_Anisotropic ("Anisotropic", int) = 0

        [Header(Fast Approximate Sub Surface Scattering Settings)]
        _SubSurfaceScatteringColor ("Sub Surface Scattering Color", Color) = (1, 1, 1, 1)
        _SubSurfaceScatteringStrength ("Sub Surface Scattering Strength", Range(0.0, 1.0)) = 0
        _SubSurfaceScatteringBias ("Sub Surface Scattering Bias", Range(-1.0, 1.0)) = 0.0
        _SubSurfaceScatteringSmoothstep ("Sub Surface Scattering Smoothstep", Range(0.0, 1.0)) = 1.0

        [Header(Rim Light Settings)]
        _RimLightColor ("Rim Light Color", Color) = (1, 1, 1, 1)
        _RimLightStrength ("Rim Light Strength", Range(0.0, 100.0)) = 0.5
        _RimLightBias ("Rim Light Bias", Range(-1.0, 1.0)) = 0.0
        _RimLightSmoothstep ("Rim Light Smoothstep", Range(0.0, 1.0)) = 0.0

        [Header(Others)]
        _Wet ("Wet", Range(0.0, 1.0)) = 0.0
    }
    SubShader
    {
        Tags
        {
            "RenderPipeline"="UniversalPipeline"
            "RenderType" = "TransparentCutout"
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
            
            Cull [_CullMode]
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
            int _EnableDiffuse;
            int _EnableSpecular;
            int _EnableSubSurfaceScattering;
            int _EnableRimLight;

            float _FaceFix;
            int _NormalReverse;
            int _ReceiveShadow;
            float4 _HeadCenter;

            float _BaseColorStrength;
            float _AlphaClip;
            float4 _DiffuseColor;
            float4 _ShadowColor;
            float _DiffuseStrength;
            float _DiffuseBias;
            float _DiffuseSmoothstep;
            float _AdditionalLightStrength;
            float _AdditionalLightBias;
            float _AdditionalLightSmoothstep;
            float4 _SpecularColor;
            float _SpecularStrength;
            float _SpecularGloss;
            int _Anisotropic;
            float4 _SubSurfaceScatteringColor;
            float _SubSurfaceScatteringStrength;
            float _SubSurfaceScatteringBias;
            float _SubSurfaceScatteringSmoothstep;
            float4 _RimLightColor;
            float _RimLightStrength;
            float _RimLightBias;
            float _RimLightSmoothstep;

            float _Wet;
            CBUFFER_END

            TEXTURE2D(_BaseTexture);
            float4 _BaseTexture_ST;

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
                float3 normalWS : TEXCOORD1;
                float3 tangentWS : TEXCOORD2;
                float2 uv : TEXCOORD3;
                float4 shadowCoord : TEXCOORD4;
            };
            
            Varyings vert(Attributes v)
            {
                Varyings o;
                ZERO_INITIALIZE(Varyings, o);
                o.positionCS = TransformObjectToHClip(v.positionOS.xyz);
                o.positionWS = TransformObjectToWorld(v.positionOS.xyz);
                o.normalWS = TransformObjectToWorldNormal(v.normalOS);
                o.tangentWS = TransformObjectToWorldDir(v.tangentOS.xyz);
                o.uv = TRANSFORM_TEX(v.uv, _BaseTexture);
                o.shadowCoord = TransformWorldToShadowCoord(o.positionWS);
                return o;
            }            

            half4 frag(Varyings i): SV_Target
            {
                Light light = GetMainLight();

                float3 lightDirection = normalize(light.direction);
                float3 originalNormal = normalize(i.normalWS);
                float3 normal = normalize(i.normalWS) * (1 - _FaceFix) + normalize(i.positionWS - _HeadCenter.xyz) * _FaceFix;
                normal = normal * (1 - _NormalReverse) - normal *_NormalReverse;
                float3 tangent = normalize(i.tangentWS);
                float3 binormal = normalize(cross(tangent, normal));
                float3 viewDirection = normalize(_WorldSpaceCameraPos.xyz - i.positionWS);
                float3 halfDirection = normalize(lightDirection + viewDirection);

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

                half4 BaseTexture = SAMPLE_TEXTURE2D(_BaseTexture, textureSampler1, i.uv);
                clip(BaseTexture.a - _AlphaClip);

                _DiffuseStrength += (1 - _DiffuseStrength) * 0.5 * _Wet;
                _DiffuseColor *= (1 - 0.6 * _Wet);
                _ShadowColor *= (1 - 0.8 * _Wet);
                _DiffuseSmoothstep *= (1 + _Wet);
                _AdditionalLightStrength *= (1 + 0.5 * _Wet);
                _SpecularStrength += _Wet * 0.015;
                _SpecularStrength *= (1 - _Anisotropic) * (1 + 0.8 * _Wet) + _Anisotropic * (1 - 0.8 * _Wet);
                _SpecularGloss *= 1 - 0.7 * _Wet;
                _SubSurfaceScatteringStrength *= (1 - 0.5 * _Wet);

                half shadow = MainLightRealtimeShadow(i.shadowCoord);
                
                half3 diffuse = _EnableDiffuse * light.color.rgb * _DiffuseColor.rgb * smoothstep(0.5 - _DiffuseSmoothstep * 0.5, 0.5 + _DiffuseSmoothstep * 0.5, max(NdotL + _DiffuseBias * 0.5, 0));
                diffuse += _EnableDiffuse * light.color.rgb * _ShadowColor.rgb * (1 - smoothstep(0.5 - _DiffuseSmoothstep * 0.5, 0.5 + _DiffuseSmoothstep * 0.5, max(NdotL + _DiffuseBias * 0.5, 0)));
                half3 diffuseWithShadow = diffuse * shadow * _ReceiveShadow + light.color.rgb * _ShadowColor.rgb * (1 - shadow) * _ReceiveShadow + diffuse * (1 - _ReceiveShadow);
                half3 specular = _EnableSpecular * light.color.rgb * _SpecularColor.rgb * _SpecularStrength * ((1 - _Anisotropic) * pow(_SpecularGloss, 2) / pow((pow(ONdotH, 2) * (pow(_SpecularGloss, 2) - 1) + 1), 2) * (pow(LdotH, 2) * (_SpecularGloss + 0.5) * 4.0) + _Anisotropic * 10 * pow(max(0, sqrt(1 - (LdotB * LdotB)) * sqrt(1 - (VdotB * VdotB)) - LdotB * VdotB), _SpecularGloss * 100));
                int pixelLightCount = GetAdditionalLightsCount();
                for (int lightIndex = 0; lightIndex < pixelLightCount; lightIndex ++)
                {
                    Light additionalLight = GetAdditionalLight(lightIndex, i.positionWS);
                    float NdotAL = dot(normal, normalize(additionalLight.direction));
                    float ONdotAL = dot(originalNormal, normalize(additionalLight.direction));
                    float VdotAL = dot(viewDirection, normalize(additionalLight.direction));
                    float ALdotH = dot(normalize(additionalLight.direction), halfDirection);
                    diffuseWithShadow += additionalLight.color.rgb * additionalLight.distanceAttenuation * _AdditionalLightStrength * smoothstep(0.5 - _AdditionalLightSmoothstep * 0.5, 0.5 + _AdditionalLightSmoothstep * 0.5, max(dot(normal, normalize(additionalLight.direction)) + _AdditionalLightBias * 0.5, 0));
                    specular += _EnableSpecular * additionalLight.color.rgb * additionalLight.distanceAttenuation * _AdditionalLightStrength * _SpecularColor.rgb * _SpecularStrength * ((1 - _Anisotropic) * pow(_SpecularGloss, 2) / pow((pow(ONdotH, 2) * (pow(_SpecularGloss, 2) - 1) + 1), 2) * (pow(LdotH, 2) * (_SpecularGloss + 0.5) * 4.0) + _Anisotropic * 10 * pow(max(0, sqrt(1 - (LdotB * LdotB)) * sqrt(1 - (VdotB * VdotB)) - LdotB * VdotB), _SpecularGloss * 100));
                }
                specular *= _Anisotropic * smoothstep(0.5 - _DiffuseSmoothstep * 0.5, 0.5 + _DiffuseSmoothstep * 0.5, max(NdotL + _DiffuseBias * 0.5, 0)) + (1 - _Anisotropic);
                half3 subSurfaceScattering = _EnableSubSurfaceScattering * light.color.rgb * _SubSurfaceScatteringColor.rgb * _SubSurfaceScatteringStrength * ((1 - _FaceFix) * max(NdotL, 0) + _FaceFix * max(ONdotL, 0)) * smoothstep(0.5 - _SubSurfaceScatteringSmoothstep * 0.5, 0.5 + _SubSurfaceScatteringSmoothstep * 0.5, (1 - _FaceFix) * (1 - max(NdotV + _SubSurfaceScatteringBias * 0.5, 0)) + _FaceFix * (1 - max(ONdotV + _SubSurfaceScatteringBias * 0.5, 0)));
                half3 reversedSubSurfaceScatteringColor = half3(1, 1, 1) - _SubSurfaceScatteringColor.rgb;
                subSurfaceScattering = subSurfaceScattering + _EnableSubSurfaceScattering * light.color.rgb * reversedSubSurfaceScatteringColor * _SubSurfaceScatteringStrength * ((1 - _FaceFix) * min(NdotL, 0) + _FaceFix * min(ONdotL, 0)) * smoothstep(0.5 - _SubSurfaceScatteringSmoothstep * 0.5, 0.5 + _SubSurfaceScatteringSmoothstep * 0.5, (1 - _FaceFix) * (1 - max(NdotV + _SubSurfaceScatteringBias * 0.5, 0)) + _FaceFix * (1 - max(ONdotV + _SubSurfaceScatteringBias * 0.5, 0)));
                half4 color = half4((BaseTexture.rgb * _BaseColorStrength + light.color.rgb * (1 - _BaseColorStrength)) * ((1 - _DiffuseStrength) + _DiffuseStrength * diffuseWithShadow + specular + subSurfaceScattering), 1.0);

                half3 rimLight = _EnableRimLight * light.color.rgb * _RimLightColor.rgb * smoothstep(0.5 - _DiffuseSmoothstep * 0.5, 0.5 + _DiffuseSmoothstep * 0.5, max(NdotL + _DiffuseBias * 0.5, 0)) * shadow * smoothstep(0.5 - _RimLightSmoothstep * 0.5, 0.5 + _RimLightSmoothstep * 0.5, 1 - max(NdotV + _RimLightBias * 0.5, 0));
                color = (color + half4(_RimLightStrength * rimLight, 0.0));
                return color;
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
            int _EnableOutline;

            float4 _OutlineColor;
            float _Outline;
            float _AlphaClip;
            CBUFFER_END

            TEXTURE2D(_BaseTexture);
            float4 _BaseTexture_ST;

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
                float4 positionCS = mul(UNITY_MATRIX_MV, v.positionOS);
                float3 normalOS = mul((float3x3)UNITY_MATRIX_IT_MV, v.normalOS);
                normalOS.z = -0.5;
                positionCS = positionCS + float4(normalize(normalOS), 0) * _Outline * _EnableOutline;
                o.positionCS = mul(UNITY_MATRIX_P, positionCS);
                o.uv = TRANSFORM_TEX(v.uv, _BaseTexture);

                return o;
            }

            half4 frag(Varyings i) : SV_TARGET 
            {
                half4 BaseTexture = SAMPLE_TEXTURE2D(_BaseTexture, textureSampler1, i.uv);
                clip(BaseTexture.a - _AlphaClip);

                clip(_Outline - (1 - _EnableOutline));
                return float4(_OutlineColor.rgb, 1);
            }
            
            ENDHLSL
        }
    }
    FallBack "Packages/com.unity.render-pipelines.universal/FallbackError"
}

