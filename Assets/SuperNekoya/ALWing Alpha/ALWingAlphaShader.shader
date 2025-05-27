/*
	This software is licensed under MIT License.
	License text:

	Copyright 2023 Catherine

	Permission is hereby granted, free of charge, to any person obtaining a copy of this software 
	and associated documentation files (the "Software"), to deal in the Software without restriction, 
	including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense,
	and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, 
	subject to the following conditions:

	The above copyright notice and this permission notice shall be included in all copies or substantial 
	portions of the Software.

	THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT 
	LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. 
	IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, 
	WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE 
	SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.

	This software is based on FuwaParticle. (https://github.com/phi16/VRC_storage#fuwaparticle)
	License text:

	特に確認なども要らないので勝手に使っていただいて結構です
	利用は自己責任でお願いします
	諸々の著作権などは放棄しているので好きにいじってください
	意見などは Twitter にお願いします

	This software includes Udon AudioLink. (https://github.com/llealloo/vrc-udon-audio-link)
	License text:

	Copyright 2021 llealloo, cnlohr, lox9973, pema99, float3

	Permission is hereby granted, free of charge, to any person obtaining a copy of this software 
	and associated documentation files (the "Software"), to deal in the Software without restriction, 
	including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense,
	and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, 
	subject to the following conditions:

	The above copyright notice and this permission notice shall be included in all copies or substantial 
	portions of the Software.

	THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT 
	LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. 
	IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, 
	WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE 
	SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
*/

Shader "Unlit/ALWingAlpha"
{
	Properties
	{
		_Height ("Height", Float) = 0.05
		_Size ("Particle Size", Float) = 1.0
		_Fuwa ("Fuwa Rate", Range(0,1)) = 0.3
		_FuwaDuration ("Fuwa Duration", Float) = 1.0
		_FuwaTarget ("Fuwa Direction", Vector) = (0,1,0,0)
		_AudioLinkX ("AudioLink X", Float) = 1.0
		_AudioLinkY ("AudioLink Y", Float) = 0.0
		_AudioLinkChannel ("AudioLink Channels", Vector) = (1,0,0,0)
		_Speed ("Randomize Speed", Float) = 1.0
		_ScatterFactor ("Scatter Factor", Float) = 8
		_ScatterDistance ("Scatter Distance", Float) = 1
		_Color ("Color", Color) = (0.3,0.6,1.0,1.0)
	}
	SubShader
	{
		Tags { "RenderType"="Transparent" "Queue"="Transparent" }
		LOD 100
		Cull Off
		Blend SrcAlpha One
		ZWrite Off

		Pass
		{
			CGPROGRAM
			#pragma vertex vert
			#pragma geometry geom
			#pragma fragment frag
			
			#include "UnityCG.cginc"
			#include "Packages/com.llealloo.audiolink/Runtime/Shaders/AudioLink.cginc"

			struct appdata
			{
				float4 vertex : POSITION;
				float2 uv : TEXCOORD0;
			};

			struct v2g {
				float4 vertex : POSITION;
				float2 uv : TEXCOORD0;
			};

			struct g2f
			{
				float4 vertex : SV_POSITION;
				float2 uv : TEXCOORD0;
				float3 color : TEXCOORD1;
				float distance : TEXCOORD2;
				float time : TEXCOORD3;
			};

			sampler2D _MainTex;
			float4 _Color;
			float _Height;
			float _Fuwa;
			float _FuwaDuration;
			float4 _FuwaTarget;
			float _AudioLinkX;
			float _AudioLinkY;
			float4 _AudioLinkChannel;
			float _Size;
			float _Speed;
			float _ScatterFactor;
			float _ScatterDistance;

			float rand(float2 co){
				return frac(sin(dot(co.xy, float2(12.9898,78.233))) * 43758.5453);
			}

			v2g vert (appdata v)
			{
				v2g o;
				o.vertex = v.vertex;
				o.uv = v.uv.xy;
				return o;
			}
			float stepping(float t){
				if(t<0.)return -1.+pow(1.+t,2.);
				else return 1.-pow(1.-t,2.);
			}

			[maxvertexcount(4)]
			void geom (triangle v2g IN[3], inout TriangleStream<g2f> stream) {
				float2 avgUV = (IN[0].uv + IN[1].uv + IN[2].uv) / 3;
				avgUV.x = (floor(avgUV.x * 256) + 0.5) / 256.0;
				avgUV.y = (floor(avgUV.y * 128) + 0.5) / 128.0;
				g2f output;
				output.color = float3(1,1,1);
				float particleSize = 1.0;

				float3 avgVert = (IN[0].vertex + IN[1].vertex + IN[2].vertex) / 3;

				float r0 = rand(avgUV+0), r1 = rand(avgUV+1), r2 = rand(avgUV+2), r3 = rand(avgUV+3), r4 = rand(avgUV+4);
				float3 position = 0, velocity = 0;

				float time = _Time.y * _Speed;
				float firstAngle = r0 * 3.1415926535 * 2;
				float firstU = r1 * 2 - 1;
				float3 firstPos = float3(sqrt(1 - firstU * firstU) * float2(cos(firstAngle), sin(firstAngle)), 0).xzy + float3(0, firstU, 0);
				float3 finalPos = firstPos;
				float secondRotation = time / 3.0 + r1 * 500;

				float theta = r0 * 3.1415926535 * 2.0 + r2;
				position = avgVert;
				position += finalPos * _Height;
				position.y += _Height;
				output.color = _Color;
				if (r3 < _Fuwa) {
					float motion = (exp(-r4 * 10) + 1.0) * 3.0;
					float heightVariation = fmod((100 + _Time.y) * (r3 * 1.0 + 1.0) * 0.5 / _FuwaDuration, motion);
					position += heightVariation * 0.1 * _FuwaTarget.xyz;
					output.color *= pow(sin(heightVariation / motion * 3.1415926535), 0.5);
				}
				//float colorTheta = r3 * 3.1415926535 * 2.0;
				output.color *= 0.5;
				output.color *= max(0, min(1, 1 + r3));
				particleSize = 2.0 + sin(r2 * 3.1415926535 * 2.0 + _Time.y * 0.3 * (1 + r2));
				particleSize *= _Size;

				float4 clipPos1 = UnityObjectToClipPos(float4(position, 1));
				float4 clipPos2 = UnityObjectToClipPos(float4(position + velocity, 1));
				float2 screenDiff = clipPos1.xy / clipPos1.w - clipPos2.xy / clipPos2.w;
				float aspectRatio = -UNITY_MATRIX_P[0][0] / UNITY_MATRIX_P[1][1];
				screenDiff.x /= aspectRatio;
				output.distance = length(screenDiff);
				if (length(screenDiff) < 0.0001) screenDiff = float2(1, 0);
				else screenDiff = normalize(screenDiff);
				float2 normal = screenDiff.yx * float2(-1, 1);
				particleSize *= 2;
				if (abs(UNITY_MATRIX_P[0][2]) < 0.01) particleSize *= 2;
				float particleScale = 0.002 * particleSize;
				screenDiff *= particleScale, normal *= particleScale;
				screenDiff.x *= aspectRatio, normal.x *= aspectRatio;

				float alTime = AudioLinkIsAvailable() ? fmod(_AudioLinkX * avgUV.x + _AudioLinkY * avgUV.y, 1) : 0;

				output.uv = float2(-1, -1);
				output.vertex = clipPos1 + float4(screenDiff + normal, 0, 0);
				output.time = alTime;
				stream.Append(output);
				output.uv = float2(-1, 1);
				output.vertex = clipPos1 + float4(screenDiff - normal, 0, 0);
				output.time = alTime;
				stream.Append(output);
				output.uv = float2(1, -1);
				output.vertex = clipPos2 + float4(-screenDiff + normal, 0, 0);
				output.time = alTime;
				stream.Append(output);
				output.uv = float2(1, 1);
				output.vertex = clipPos2 + float4(-screenDiff - normal, 0, 0);
				output.time = alTime;
				stream.Append(output);
				stream.RestartStrip();
			}

			float3 rgb2hsv(float3 c)
			{
				float4 K = float4(0.0, -1.0 / 3.0, 2.0 / 3.0, -1.0);
				float4 p = lerp(float4(c.bg, K.wz), float4(c.gb, K.xy), step(c.b, c.g));
				float4 q = lerp(float4(p.xyw, c.r), float4(c.r, p.yzx), step(p.x, c.r));

				float d = q.x - min(q.w, q.y);
				float e = 1.0e-10;
				return float3(abs(q.z + (q.w - q.y) / (6.0 * d + e)), d / (q.x + e), q.x);
			}

			float3 hsv2rgb(float3 c)
			{
				float4 K = float4(1.0, 2.0 / 3.0, 1.0 / 3.0, 3.0);
				float3 p = abs(frac(c.xxx + K.xyz) * 6.0 - K.www);
				return c.z * lerp(K.xxx, clamp(p - K.xxx, 0.0, 1.0), c.y);
			}
			
			fixed4 frag (g2f i) : SV_Target
			{
				float l = length(i.uv);
				clip(1-l);
				float3 color = i.color;
				float time = i.time * 128;

				color *= pow(max(0, 0.5 - i.distance) + 1 - l, 0.5) * 2;
				color *= pow(1 - distance(i.uv, float2(0, 0)), 5);

				color *= AudioLinkData( ALPASS_AUDIOLINK + uint2( time, 0 ) ).r * _AudioLinkChannel.r +
				AudioLinkData( ALPASS_AUDIOLINK + uint2( time, 1 ) ).r  * _AudioLinkChannel.g +
				AudioLinkData( ALPASS_AUDIOLINK + uint2( time, 2 ) ).r * _AudioLinkChannel.b +
				AudioLinkData( ALPASS_AUDIOLINK + uint2( time, 3 ) ).r * _AudioLinkChannel.a;

				color = min(1, color);

				return float4(color,smoothstep(1,0.8,l)*_Color.a);
			}
			ENDCG
		}
	}
}

