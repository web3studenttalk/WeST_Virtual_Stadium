Shader "Custom/ClusterAudioReactiveShader"
{
    Properties
    {
        _MainTex ("Main Texture", 2D) = "white" {}
        _Color ("Base Color", Color) = (1,1,1,1)
        
        // Audio Reactive Colors
        _LowFreqColor ("Low Frequency Color", Color) = (1,0,0,1)
        _MidFreqColor ("Mid Frequency Color", Color) = (0,1,0,1)
        _HighFreqColor ("High Frequency Color", Color) = (0,0,1,1)
        
        // Audio Simulation (for testing without audio input)
        _AudioSimulation ("Audio Simulation", Range(0, 1)) = 0
        _SimulationSpeed ("Simulation Speed", Range(0, 10)) = 2
        
        // Wave Effects
        _WaveSpeed ("Wave Speed", Range(0, 10)) = 2
        _WaveAmplitude ("Wave Amplitude", Range(0, 1)) = 0.1
        _WaveFrequency ("Wave Frequency", Range(0, 20)) = 5
        
        // Pulse Effects
        _PulseSpeed ("Pulse Speed", Range(0, 10)) = 3
        _PulseIntensity ("Pulse Intensity", Range(0, 2)) = 0.5
        
        // Distortion
        _DistortionStrength ("Distortion Strength", Range(0, 1)) = 0.2
        
        // Emission
        _EmissionStrength ("Emission Strength", Range(0, 10)) = 2
        
        // Noise
        _NoiseScale ("Noise Scale", Range(0.1, 10)) = 1
        _NoiseSpeed ("Noise Speed", Range(0, 5)) = 1
        
        // Reactivity Controls
        _ReactivityScale ("Reactivity Scale", Range(0, 5)) = 1
        _TimeScale ("Time Scale", Range(0, 5)) = 1
        
        // Pattern Controls
        _PatternScale ("Pattern Scale", Range(0.1, 5)) = 1
        _PatternSpeed ("Pattern Speed", Range(0, 5)) = 1
        
        // Color Mixing
        _ColorMixIntensity ("Color Mix Intensity", Range(0, 2)) = 1
        
        // Transparency
        _AlphaMultiplier ("Alpha Multiplier", Range(0, 2)) = 1
    }
    
    SubShader
    {
        Tags { "RenderType"="Transparent" "Queue"="Transparent" }
        LOD 200
        
        Blend SrcAlpha OneMinusSrcAlpha
        ZWrite Off
        Cull Off
        
        Pass
        {
            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag
            #pragma multi_compile_fog
            #pragma target 3.0
            
            #include "UnityCG.cginc"
            
            struct appdata
            {
                float4 vertex : POSITION;
                float2 uv : TEXCOORD0;
                float3 normal : NORMAL;
                float4 tangent : TANGENT;
            };
            
            struct v2f
            {
                float2 uv : TEXCOORD0;
                float4 vertex : SV_POSITION;
                float3 worldPos : TEXCOORD1;
                float3 worldNormal : TEXCOORD2;
                float4 screenPos : TEXCOORD3;
                UNITY_FOG_COORDS(4)
            };
            
            sampler2D _MainTex;
            float4 _MainTex_ST;
            float4 _Color;
            
            // Audio Colors
            float4 _LowFreqColor;
            float4 _MidFreqColor;
            float4 _HighFreqColor;
            
            // Audio Simulation
            float _AudioSimulation;
            float _SimulationSpeed;
            
            // Effects
            float _WaveSpeed;
            float _WaveAmplitude;
            float _WaveFrequency;
            float _PulseSpeed;
            float _PulseIntensity;
            float _DistortionStrength;
            float _EmissionStrength;
            float _NoiseScale;
            float _NoiseSpeed;
            float _ReactivityScale;
            float _TimeScale;
            float _PatternScale;
            float _PatternSpeed;
            float _ColorMixIntensity;
            float _AlphaMultiplier;
            
            // Enhanced noise function
            float hash(float2 p)
            {
                float3 p3 = frac(float3(p.xyx) * 0.1031);
                p3 += dot(p3, p3.yzx + 33.33);
                return frac((p3.x + p3.y) * p3.z);
            }
            
            float noise(float2 p)
            {
                float2 i = floor(p);
                float2 f = frac(p);
                
                float a = hash(i);
                float b = hash(i + float2(1.0, 0.0));
                float c = hash(i + float2(0.0, 1.0));
                float d = hash(i + float2(1.0, 1.0));
                
                float2 u = f * f * (3.0 - 2.0 * f);
                
                return lerp(a, b, u.x) + (c - a) * u.y * (1.0 - u.x) + (d - b) * u.x * u.y;
            }
            
            // Fractal Brownian Motion
            float fbm(float2 p)
            {
                float value = 0.0;
                float amplitude = 0.5;
                float frequency = 0.0;
                
                for (int i = 0; i < 5; i++)
                {
                    value += amplitude * noise(p);
                    p *= 2.0;
                    amplitude *= 0.5;
                }
                return value;
            }
            
            // Simulate audio frequencies using mathematical functions
            float3 simulateAudioFrequencies(float time)
            {
                float low = (sin(time * 2.3) + sin(time * 1.7) + sin(time * 0.9)) * 0.33 + 0.5;
                float mid = (sin(time * 4.1) + sin(time * 3.2) + sin(time * 2.8)) * 0.33 + 0.5;
                float high = (sin(time * 8.7) + sin(time * 12.3) + sin(time * 15.1)) * 0.33 + 0.5;
                
                // Add some randomness
                low += fbm(float2(time * 0.5, 0)) * 0.3;
                mid += fbm(float2(time * 0.7, 10)) * 0.3;
                high += fbm(float2(time * 1.2, 20)) * 0.3;
                
                return saturate(float3(low, mid, high));
            }
            
            v2f vert (appdata v)
            {
                v2f o;
                
                float time = _Time.y * _TimeScale;
                float3 worldPos = mul(unity_ObjectToWorld, v.vertex).xyz;
                
                // Simulate audio data
                float3 audioFreqs = simulateAudioFrequencies(time * _SimulationSpeed);
                
                // Calculate audio-reactive displacement
                float wave1 = sin(worldPos.x * _WaveFrequency + time * _WaveSpeed) * 
                             cos(worldPos.z * _WaveFrequency * 0.7 + time * _WaveSpeed * 1.3);
                
                float wave2 = sin(worldPos.y * _WaveFrequency * 1.3 + time * _WaveSpeed * 0.8) *
                             cos(worldPos.x * _WaveFrequency * 0.9 + time * _WaveSpeed * 1.1);
                
                // Audio-reactive displacement
                float audioDisplacement = (audioFreqs.x + audioFreqs.y + audioFreqs.z) * _ReactivityScale;
                
                // Apply displacement
                float totalDisplacement = (wave1 + wave2) * _WaveAmplitude + audioDisplacement * 0.05;
                v.vertex.xyz += v.normal * totalDisplacement;
                
                o.vertex = UnityObjectToClipPos(v.vertex);
                o.uv = TRANSFORM_TEX(v.uv, _MainTex);
                o.worldPos = mul(unity_ObjectToWorld, v.vertex).xyz;
                o.worldNormal = UnityObjectToWorldNormal(v.normal);
                o.screenPos = ComputeScreenPos(o.vertex);
                
                UNITY_TRANSFER_FOG(o, o.vertex);
                return o;
            }
            
            fixed4 frag (v2f i) : SV_Target
            {
                float time = _Time.y * _TimeScale;
                float2 screenUV = i.screenPos.xy / i.screenPos.w;
                
                // Simulate audio frequencies
                float3 audioFreqs = simulateAudioFrequencies(time * _SimulationSpeed);
                
                // Sample main texture with distortion
                float2 distortedUV = i.uv;
                float noiseValue = fbm(i.worldPos.xz * _NoiseScale + time * _NoiseSpeed);
                distortedUV += noiseValue * _DistortionStrength * (audioFreqs.x + audioFreqs.z);
                
                fixed4 texColor = tex2D(_MainTex, distortedUV);
                
                // Create various patterns
                float2 center = float2(0.5, 0.5);
                float dist = distance(i.uv, center);
                
                // Pulse effect
                float pulse = sin(dist * 15.0 * _PatternScale - time * _PulseSpeed) * 0.5 + 0.5;
                pulse *= audioFreqs.x * _PulseIntensity;
                
                // Radial waves
                float radialWave = sin(dist * 25.0 * _PatternScale - time * _PatternSpeed * 3.0) * 0.5 + 0.5;
                radialWave *= (audioFreqs.x + audioFreqs.z) * 0.6;
                
                // Circular patterns
                float angle = atan2(i.uv.y - 0.5, i.uv.x - 0.5);
                float circularPattern = sin(angle * 6.0 + time * _PatternSpeed * 2.0 + dist * 20.0 * _PatternScale) * 0.5 + 0.5;
                circularPattern *= audioFreqs.y * 0.8;
                
                // Frequency-based stripe patterns
                float stripes = sin(i.uv.y * 30.0 * _PatternScale + time * _PatternSpeed * 5.0) * 0.5 + 0.5;
                stripes *= audioFreqs.x * 0.7;
                
                // Grid pattern
                float2 grid = abs(frac(i.uv * 10.0 * _PatternScale) - 0.5);
                float gridPattern = smoothstep(0.0, 0.1, min(grid.x, grid.y));
                gridPattern *= audioFreqs.z * 0.5;
                
                // Voronoi-like pattern
                float2 voronoiUV = i.uv * 5.0 * _PatternScale + time * _PatternSpeed * 0.5;
                float voronoi = fbm(voronoiUV) * fbm(voronoiUV + 5.0);
                voronoi *= audioFreqs.y * 0.6;
                
                // Color mixing based on simulated audio frequencies
                float4 audioColor = _LowFreqColor * audioFreqs.x +
                                   _MidFreqColor * audioFreqs.y +
                                   _HighFreqColor * audioFreqs.z;
                
                // Combine base color with texture
                float4 finalColor = texColor * _Color;
                
                // Apply audio-reactive coloring
                finalColor = lerp(finalColor, audioColor * _ColorMixIntensity, 0.7);
                
                // Add all patterns
                finalColor.rgb += pulse * audioColor.rgb * 0.8;
                finalColor.rgb += radialWave * float3(1, 1, 1) * 0.6;
                finalColor.rgb += circularPattern * audioColor.rgb * 0.5;
                finalColor.rgb += stripes * _LowFreqColor.rgb * 0.4;
                finalColor.rgb += gridPattern * _HighFreqColor.rgb * 0.3;
                finalColor.rgb += voronoi * _MidFreqColor.rgb * 0.4;
                
                // Add noise-based texture variation
                finalColor.rgb += noiseValue * 0.15 * (audioFreqs.x + audioFreqs.z);
                
                // Emission boost
                float audioIntensity = (audioFreqs.x + audioFreqs.y + audioFreqs.z) * 0.33;
                finalColor.rgb *= _EmissionStrength * (1.0 + audioIntensity * 0.8);
                
                // Dynamic transparency
                finalColor.a *= _AlphaMultiplier * (0.6 + audioIntensity * 0.4);
                
                // Screen-space effects
                float2 screenDistortion = (screenUV - 0.5) * 2.0;
                float screenEffect = 1.0 - length(screenDistortion) * 0.3;
                finalColor.rgb *= screenEffect;
                
                // Chromatic aberration effect
                float chromatic = audioFreqs.z * 0.01;
                finalColor.r += chromatic;
                finalColor.b -= chromatic;
                
                // Saturation boost based on audio
                float3 gray = dot(finalColor.rgb, float3(0.299, 0.587, 0.114));
                finalColor.rgb = lerp(gray, finalColor.rgb, 1.0 + audioIntensity * 0.5);
                
                UNITY_APPLY_FOG(i.fogCoord, finalColor);
                
                return finalColor;
            }
            ENDCG
        }
    }
    
    // Simplified fallback
    SubShader
    {
        Tags { "RenderType"="Opaque" }
        LOD 100
        
        Pass
        {
            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag
            
            #include "UnityCG.cginc"
            
            struct appdata
            {
                float4 vertex : POSITION;
                float2 uv : TEXCOORD0;
            };
            
            struct v2f
            {
                float2 uv : TEXCOORD0;
                float4 vertex : SV_POSITION;
            };
            
            sampler2D _MainTex;
            float4 _MainTex_ST;
            float4 _Color;
            
            v2f vert (appdata v)
            {
                v2f o;
                o.vertex = UnityObjectToClipPos(v.vertex);
                o.uv = TRANSFORM_TEX(v.uv, _MainTex);
                return o;
            }
            
            fixed4 frag (v2f i) : SV_Target
            {
                fixed4 col = tex2D(_MainTex, i.uv) * _Color;
                return col;
            }
            ENDCG
        }
    }
    
    FallBack "Diffuse"
}