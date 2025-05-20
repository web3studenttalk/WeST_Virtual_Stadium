// 2024/02/15 BeamLightShader V024

Shader "Noriben/noribenBeamLight"
{
	Properties
	{
		[Header(Texture)]
		_NoiseTex ("NoiseTex", 2D) = "white" {}

		[Header(Color)]
		_Color ("Color" , Color) = (1.0, 1.0, 1.0, 1.0)
		_Intensity ("Light Intensity", Range(0, 10)) = 1 

		[Space]
		[Header(Size)]
		_ConeWidth ("Width", Range(-0.07, 0.5)) = 1
		_ConeLength ("Length", Range(0.01, 3)) = 1

		[Space]
		[Header(Noise)]
		_TexPower ("Noise power", Range(0, 1)) = 1
		_NoieMoveSpeed ("Noise move speed", Range(0, 4)) = 1
		_LightIndex ("Noise seed", float) = 0
		[Toggle] _WorldPosNoiseRandom ("WorldPosition Noise Random", float) = 0

		[Space]
		[Header(Soft)]
		_RimPower ("Edge soft", Range(0.01, 10.0)) = 3

		[Space]
		[Header(Sampling Texture Color)]
		[Toggle(SampleTexToggle)] _SampleTexOn ("Sampling Texure On", float) = 0
		_SampleTex ("SamplingTex Color", 2D) = "black" {}
		_SamplePosX ("SamplingTex UV Position X", float) = .5
		_SamplePosY ("SamplingTex UV Position Y", float) = .5
		_SampleScrollSpeed ("SamplingTex Scroll Speed", float) = 0.1
		_MultiSampling ("Texture MultiSampling(5Pos Average)", Range(0, 1)) = 0

		[Space]
		[Header(Gradation Height)]
		[Toggle] _GradOn ("Gradation Height ON", float) = 0
		_GradHeight ("Gradation Height", float) = 1
		_GradPower ("Gradation Power", Range(0, 5)) = 0.3

		[Header(DepthFade and FakeLight (Need RealTime DirectionalLight with Shadows))]
		[Toggle(DepthFadeToggle)] _DepthFadeOn ("Depth Fade and Fake Light On", Float) = 0
		_FakeLightBrightness ("Fake Light Brightness", Range(0, 2)) = 1
		_DepthFade("Depth Fade Power", float) = 1.0

		[Space]
		[Header(Divide)]
		_Divide ("Divide", Range(0, 30)) = 0
		_DivideScroll("Divide Scroll", Range(-10, 10)) = 0
		_DividePower ("Divide Power", Range(0, 1)) = 0

		[Space(40)]
		[Header(AudioLink for VRChat)]
		[Toggle(AudioLinkOn)] _AudioLinkOn ("AudioLink On", Float) = 0
		
		_AudioLinkIntensity ("AudioLink Intensity", Range(0,1)) = 1
		[Enum(Bass,0,Low mid,1,High mid,2,Treble,3)]
		_AudioLinkType ("AudioLink BandType", int) = 0
		_AudioLinkFiltering ("AudioLink Smooth Filtering", Range(0, 1)) = 0


	}

	SubShader
	{
		Tags { "RenderType"="Transparent" "Queue" = "Transparent" "DisableBatching" = "True"}
		Cull Off
		Blend One One
		Zwrite Off
		LOD 100

		Pass
		{
			CGPROGRAM
			#pragma vertex vert
			#pragma fragment frag
			
			#pragma multi_compile_fog
			#pragma multi_compile_instancing

			#pragma shader_feature_local AudioLinkOn
			#pragma shader_feature_local SampleTexToggle
			#pragma shader_feature_local DepthFadeToggle
			
			#include "UnityCG.cginc"
			#include "UnityInstancing.cginc"


			// AudioLink
			#ifdef AudioLinkOn
			#define ALPASS_AUDIOLINK uint2(0,0)
            #define ALPASS_FILTEREDAUDIOLINK uint2(0,28)
			float4 _AudioTexture_TexelSize;
            Texture2D<float4> _AudioTexture;
            #define AudioLinkData(xycoord) _AudioTexture[uint2(xycoord)]
			#endif

			struct appdata
			{
				float4 vertex : POSITION;
				float2 uv : TEXCOORD0;
				float2 uv2 : TEXCOORD3;
				float3 normal : NORMAL;

				UNITY_VERTEX_INPUT_INSTANCE_ID
			};

			struct v2f
			{
				float2 uv : TEXCOORD0;
				UNITY_FOG_COORDS(1) // 内部でTEXCOORD1を使っている
				float4 vertex : SV_POSITION;
				float3 normal : TEXCOORD2;
				float3 worldPos : TEXCOORD3;
				float2 uv2 : TEXCOORD4; // ノイズテクスチャ用
				float3 objPos: TEXCOORD5;
				float4 screenPos: TEXCOORD6;

				UNITY_VERTEX_INPUT_INSTANCE_ID
				UNITY_VERTEX_OUTPUT_STEREO
			};

			sampler2D _NoiseTex;
			float4 _NoiseTex_ST;
			sampler2D _SampleTex;
			UNITY_DECLARE_DEPTH_TEXTURE(_CameraDepthTexture);


			// GPU instancing parameters
			UNITY_INSTANCING_BUFFER_START(Props)
            	UNITY_DEFINE_INSTANCED_PROP(float4, _Color)
				UNITY_DEFINE_INSTANCED_PROP(float, _Intensity)
				UNITY_DEFINE_INSTANCED_PROP(float, _RimPower)
				UNITY_DEFINE_INSTANCED_PROP(float, _TexPower)
				UNITY_DEFINE_INSTANCED_PROP(float, _GradHeight)
				UNITY_DEFINE_INSTANCED_PROP(float, _GradPower)
				UNITY_DEFINE_INSTANCED_PROP(float, _ConeWidth)
				UNITY_DEFINE_INSTANCED_PROP(float, _ConeLength)
				UNITY_DEFINE_INSTANCED_PROP(float, _Divide)
				UNITY_DEFINE_INSTANCED_PROP(float, _DivideScroll)
				UNITY_DEFINE_INSTANCED_PROP(float, _DividePower)
				UNITY_DEFINE_INSTANCED_PROP(float, _LightIndex)
				UNITY_DEFINE_INSTANCED_PROP(float, _GradOn)
				UNITY_DEFINE_INSTANCED_PROP(float, _WorldPosNoiseRandom)
				UNITY_DEFINE_INSTANCED_PROP(float, _NoieMoveSpeed)
				UNITY_DEFINE_INSTANCED_PROP(float, _AudioLinkIntensity)
				UNITY_DEFINE_INSTANCED_PROP(int, _AudioLinkType)
				UNITY_DEFINE_INSTANCED_PROP(float, _AudioLinkFiltering)
				UNITY_DEFINE_INSTANCED_PROP(float, _SampleTexOn)
				UNITY_DEFINE_INSTANCED_PROP(float, _SamplePosX)
				UNITY_DEFINE_INSTANCED_PROP(float, _SamplePosY)
				UNITY_DEFINE_INSTANCED_PROP(float, _SampleScrollSpeed)
				UNITY_DEFINE_INSTANCED_PROP(float, _MultiSampling)
				UNITY_DEFINE_INSTANCED_PROP(float, _DepthFade)
				UNITY_DEFINE_INSTANCED_PROP(float, _FakeLightBrightness)
        	UNITY_INSTANCING_BUFFER_END(Props)
			

			// リマップ
			// InMinMax.xからInMinMax.yの範囲で入力された値Inが、OutMinMax.xからOutMinMax.yのスケールにリマップして出力される
			float remap(float In, float2 InMinMax, float2 OutMinMax)
			{
				return OutMinMax.x + (In - InMinMax.x) * (OutMinMax.y - OutMinMax.x) / (InMinMax.y - InMinMax.x);
			}

			// ランダム関数
			float random1D (float p)
			{ 
            return frac(sin(p) * 10000);
        	}

			float random2D (float2 p)
			{ 
            return frac(sin(dot(p, fixed2(12.9898,78.233))) * 43758.5453);
        	}

			// HSV変換
            float3 hsv2rgb(float3 c)
            {
                float4 K = float4(1.0, 2.0 / 3.0, 1.0 / 3.0, 3.0);
                float3 p = abs(frac(c.xxx + K.xyz) * 6.0 - K.www);
                return c.z * lerp(K.xxx, clamp(p - K.xxx, 0.0, 1.0), c.y);
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


			v2f vert (appdata v)
			{

				v2f o;

				UNITY_SETUP_INSTANCE_ID(v);
				UNITY_INITIALIZE_VERTEX_OUTPUT_STEREO(o);
				UNITY_TRANSFER_INSTANCE_ID(v, o);

				// GPU instansing parameter
				float ConeWidth = UNITY_ACCESS_INSTANCED_PROP(Props, _ConeWidth);
				float ConeLength = UNITY_ACCESS_INSTANCED_PROP(Props, _ConeLength);


				o.objPos = mul(unity_ObjectToWorld, float4(0,0,0,1)).xyz;

				// コーンの直径を大きくする
				// 0から1にグラデーション状に大きくする
				float vertexHeight = (1 - v.uv.y) * ConeWidth * 100; 
				// normal方向に拡大
				v.vertex.xz = v.vertex.xz + v.normal.xz * 1 * vertexHeight;
				v.vertex.y *= ConeLength;

				o.vertex = UnityObjectToClipPos(v.vertex);
				o.normal = v.normal;//UnityObjectToWorldNormal(v.normal);
				
				o.uv = v.uv;
				o.uv2 = TRANSFORM_TEX(v.uv2, _NoiseTex);
				o.worldPos = mul(unity_ObjectToWorld, v.vertex).xyz;

				o.screenPos = ComputeScreenPos(o.vertex);
				
				float3 fresnelviewDir = normalize(ObjSpaceViewDir(v.vertex));
				UNITY_TRANSFER_FOG(o,o.vertex);
				
				return o;
			}

			
			fixed4 frag (v2f i, fixed facing:VFACE) : SV_Target
			{
				UNITY_SETUP_INSTANCE_ID(i);
                UNITY_SETUP_STEREO_EYE_INDEX_POST_VERTEX(i);

				// GPU instansing parameter
				float4 Color = UNITY_ACCESS_INSTANCED_PROP(Props, _Color);
				float Intensity = UNITY_ACCESS_INSTANCED_PROP(Props, _Intensity);
				float RimPower = UNITY_ACCESS_INSTANCED_PROP(Props, _RimPower);
				float TexPower = UNITY_ACCESS_INSTANCED_PROP(Props, _TexPower);
				float GradHeight = UNITY_ACCESS_INSTANCED_PROP(Props, _GradHeight);
				float GradPower = UNITY_ACCESS_INSTANCED_PROP(Props, _GradPower);
				float ConeWidth = UNITY_ACCESS_INSTANCED_PROP(Props, _ConeWidth);
				float Divide = UNITY_ACCESS_INSTANCED_PROP(Props, _Divide);
				float DivideScroll = UNITY_ACCESS_INSTANCED_PROP(Props, _DivideScroll);
				float DividePower = UNITY_ACCESS_INSTANCED_PROP(Props, _DividePower);
				float LightIndex = UNITY_ACCESS_INSTANCED_PROP(Props, _LightIndex);
				float GradOn = UNITY_ACCESS_INSTANCED_PROP(Props, _GradOn);
				float WorldPosNoiseRandom = UNITY_ACCESS_INSTANCED_PROP(Props, _WorldPosNoiseRandom);
				float NoieMoveSpeed = UNITY_ACCESS_INSTANCED_PROP(Props, _NoieMoveSpeed);
				float AudioLinkIntensity = UNITY_ACCESS_INSTANCED_PROP(Props, _AudioLinkIntensity);
				int AudioLinkType = UNITY_ACCESS_INSTANCED_PROP(Props, _AudioLinkType);
				float AudioLinkFiltering = UNITY_ACCESS_INSTANCED_PROP(Props, _AudioLinkFiltering);
				float SampleTexOn = UNITY_ACCESS_INSTANCED_PROP(Props, _SampleTexOn);
				float SamplePosX = UNITY_ACCESS_INSTANCED_PROP(Props, _SamplePosX);
				float SamplePosY = UNITY_ACCESS_INSTANCED_PROP(Props, _SamplePosY);
				float SampleScrollSpeed = UNITY_ACCESS_INSTANCED_PROP(Props, _SampleScrollSpeed);
				float MultiSampling = UNITY_ACCESS_INSTANCED_PROP(Props, _MultiSampling);
				float DepthFade = UNITY_ACCESS_INSTANCED_PROP(Props, _DepthFade);
				float FakeLightBrightness = UNITY_ACCESS_INSTANCED_PROP(Props, _FakeLightBrightness);
				



				i.normal = normalize(i.normal);
				float3 viewDir = normalize(_WorldSpaceCameraPos - i.worldPos);
				viewDir = normalize(mul(unity_WorldToObject,float4(viewDir,0.0)));

				// AudioLink
				float AudioLink = 1;
				#ifdef AudioLinkOn
					AudioLink = AudioLinkData(ALPASS_AUDIOLINK + int2(0, AudioLinkType));
					float AudioLinkLowFiltered = AudioLinkData(ALPASS_FILTEREDAUDIOLINK + int2(0, AudioLinkType));

					AudioLink = lerp(AudioLink, AudioLinkLowFiltered, AudioLinkFiltering);
					AudioLink = lerp(1, AudioLink, AudioLinkIntensity);
				#endif

				
				// 光のグラデーション
				float grad = 0.1 / distance(i.uv.y, float2(1.0, 1.0));
				// マイナス値をなくす
				grad = clamp(grad, 0, 100000);

				// 端のだんだん消えていく感じのマスク
				float mask = smoothstep(0.1, 1.0, distance(i.uv.y, 0.0));
				// リムライト的処理エッジをやわらかく消す
				float rim = (pow(max(0, dot(i.normal, -viewDir)), RimPower));

				// ビームの分割
				float pi = 3.14159265;
				float divide = sin(i.uv.x * pi * floor(Divide) * 2 + (_Time.w * DivideScroll)) + 1.0;
				divide = lerp(1.0, divide, DividePower);
				// 合成と明るさ調整・ビームが太くなるほど暗くする
				float baseCol = grad * 20 * Intensity  * mask * rim * divide * pow(1.5, - ConeWidth * 20);

				// テクスチャからの色反映
				float4 sampledColor = float4(1,1,1,1);
				#ifdef SampleTexToggle
					float sampleScrollSpeed = SampleScrollSpeed * _Time.x;
					sampledColor = tex2D(_SampleTex, float2(SamplePosX + sampleScrollSpeed, SamplePosY));
					// 3つのUVポジションからサンプルし平均を取る
					float4 sampledColor1 = tex2D(_SampleTex, float2(SamplePosX - .01 + sampleScrollSpeed, SamplePosY - .04));
					float4 sampledColor2 = tex2D(_SampleTex, float2(SamplePosX + .02 + sampleScrollSpeed, SamplePosY - .02));
					float4 sampledColor3 = tex2D(_SampleTex, float2(SamplePosX - .03 + sampleScrollSpeed, SamplePosY + .03));
					float4 sampledColor4 = tex2D(_SampleTex, float2(SamplePosX + .04 + sampleScrollSpeed, SamplePosY + .01));
					float4 multiSampledColor = (sampledColor + sampledColor1 + sampledColor2 + sampledColor3 + sampledColor4) / 5;
					sampledColor = lerp(sampledColor, multiSampledColor, MultiSampling);
				#endif


				// 空気中のもやもや用ノイズテクスチャ
				float2 texUV = i.uv2;
				texUV.x = texUV.x + _Time * .5 * NoieMoveSpeed;
				texUV.y = texUV.y + _Time * .1 * NoieMoveSpeed;
				// ノイズテクスチャを位置によって適当にずらす（ほんとに適当）
				float randVal = random1D(LightIndex + 1); // 適当なランダム値				
				float2 worldPosRandom = float2(frac(i.objPos.x + i.objPos.y + i.objPos.z + randVal), frac(i.objPos.x + i.objPos.y + i.objPos.z + randVal));
				texUV += lerp(float2(0, 0), worldPosRandom, WorldPosNoiseRandom);

				// 2つ目の逆回転のノイズ
				float2 texUV2 = i.uv2;
				texUV2.x = texUV2.x - _Time * .7 * NoieMoveSpeed;
				texUV2.y = texUV2.y - _Time * .2 * NoieMoveSpeed;
				// ノイズテクスチャを位置によって適当にずらす（ほんとに適当）			
				texUV2 += lerp(float2(0, 0), worldPosRandom, WorldPosNoiseRandom);
				
				// noise multiply
				float4 noiseTex = tex2D(_NoiseTex, texUV);
				float4 noiseTex2 = tex2D(_NoiseTex, texUV2);
				noiseTex *= noiseTex2;
				noiseTex = lerp(fixed4(1, 1, 1, 1), noiseTex, TexPower);

				// Main Color Mix
				// Colorの彩度がMaxだとレンズ部分の色が黒くなってしまうので少し彩度を下げる
				float3 desaturatedColor = rgb2hsv(Color);
				desaturatedColor.y *= 0.96;
				desaturatedColor = hsv2rgb(desaturatedColor);
				float4 col = float4(baseCol, baseCol, baseCol, 1) * float4(desaturatedColor.xyz, 1) * noiseTex * sampledColor * AudioLink;

				// レンズ部分の色
				float baselensColor = grad * Intensity * pow(1.5, - ConeWidth * 20);
				float3 lensColor = float3(baselensColor, baselensColor, baselensColor) * desaturatedColor.xyz * sampledColor * AudioLink;

				// 高さが0になるにつれてグラデーションで消す処理
				float worldHeight = saturate(i.worldPos.y * GradPower - GradHeight) ;
				worldHeight = lerp(1, worldHeight, GradOn); //トグル
				col *= float4(worldHeight, worldHeight, worldHeight, 1);

				// いい感じの減衰
				float lm = length(_WorldSpaceCameraPos - i.worldPos);
				lm = clamp(lm * 0.3, 0.0, 1.0) - 0.0;
				col *= float4(lm, lm, lm, 1.0);
				
				// 正面向いたときだけフラッシュ
				float xzlen = length(mul(unity_WorldToObject,float4(_WorldSpaceCameraPos,1.0)).xz);
				col *= clamp(0.6/xzlen,1.0,3.0)  - 0.0; //-0.0が明るさ調整
				
				// レンズ部分の色
				float lgrad= smoothstep(0.9999,.99999, i.uv.y);
				lensColor *= float3(lgrad,lgrad,lgrad);
				lensColor *= .0003;
				col += float4(float3(lensColor),1);

				// カメラ距離フェード
				float cameraDistanceFade = length(_WorldSpaceCameraPos - i.worldPos);
				cameraDistanceFade = saturate(smoothstep(0,.5, cameraDistanceFade));
				col *= float4(cameraDistanceFade,cameraDistanceFade,cameraDistanceFade,1);

				// bloom爆発対策、これが最終基本カラー
				col = clamp(col,0,3);

				// 通常時は背面だけ描画する
				col = facing > 0 ? 0 : col;


				// DepthFadeOnのときの処理
				#ifdef DepthFadeToggle
					// _CameraDepthTextureが存在するかどうかフラグ変数
					float exsistCameraDepthTex = 0;

					float4 depthSample = SAMPLE_DEPTH_TEXTURE_PROJ(_CameraDepthTexture, UNITY_PROJ_COORD(i.screenPos));
					half depth = LinearEyeDepth(depthSample);
					half screenDepth = depth - i.screenPos.w;
					screenDepth = saturate(screenDepth);

					// _CameraDepthTextureが存在しない環境でscreenDepthが真っ黒になるのを防ぐ処理
					// 0.00001以下の部分が1になってしまうのでDepthFadeOn時エッジの部分がわずかに白くなるが問題ない程度
					if(screenDepth < 0.00001)
					{
						exsistCameraDepthTex = 1;
						// screenDepthを白にする
						screenDepth = 0;
					}
					// depthのソフト具合
					screenDepth = pow(screenDepth, DepthFade);


					// 床面を照らすフロントメッシュ用のフレネル減衰
					float rimFront = (pow(max(0, dot(i.normal, viewDir)), RimPower));

					// 機械オブジェクトに近いレンズ部分はDepthの影響を受けないようにする
					float lensIgnoreDepth = saturate(smoothstep(0, .07, 1.-i.uv.y) - .001);
					lensIgnoreDepth = pow(lensIgnoreDepth, .1);
					lensIgnoreDepth = 1.- lensIgnoreDepth;
					screenDepth = saturate(screenDepth + lensIgnoreDepth);

					// 床面を照らす用カラー（フロントメッシュ）
					float4 frontCol = float4(screenDepth.xxx, 1) * float4(desaturatedColor.xyz, 1) * sampledColor * AudioLink * rimFront * Intensity * grad * mask;
					frontCol *= float4(worldHeight, worldHeight, worldHeight, 1) * FakeLightBrightness * 1; // FakeLigthが暗いので20倍
					frontCol *= float4(cameraDistanceFade, cameraDistanceFade, cameraDistanceFade,1);
					frontCol = clamp(frontCol,0,3);

					// ビームライト本体のカラー（背面メッシュ）
					float4 backCol = col * float4(screenDepth.xxx, 1);

					// 表面と裏面の処理の切り替え
					float4 depthFadeOnCol = facing > 0 ? frontCol : backCol;

					// DepthFadeOnのときの最終描画
					if(exsistCameraDepthTex > 0.99)
					{
						// _CameraDepthTextureが無いときは背面だけ描画
						col = facing > 0 ? 0 : col;
					}
					else
					{
						// _CameraDepthTextureが有るときは両面を描画
						col = depthFadeOnCol;
					}
				#endif

	

				// UNITY_APPLY_FOG(i.fogCoord, col);
				return col;
			}
			ENDCG
		}
	}
}
