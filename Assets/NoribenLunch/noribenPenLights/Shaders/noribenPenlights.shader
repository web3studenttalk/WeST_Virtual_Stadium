// 2021/07/25 noribenPenLights V001

Shader "Noriben/noribenPenLights"
{
    Properties
    {
        [HideInInspector]_MainTex ("Texture", 2D) = "white" {}

        [HDR]_MainColor ("Main Color", Color) = (.8, .8, .8, 1)
        
        _RotateSpeed("Shake Speed", Range(0, 30)) = 1.0
        _RotateOffset("Shake Offset", float) = .4
        _RotateWidth("Shake Width", float) = .5
    }
    SubShader
    {
        Tags { "RenderType"="Opaque" "DisableBatching" = "True"}
        LOD 100

        Pass
        {
            CGPROGRAM

            #pragma vertex vert
            #pragma fragment frag
            // make fog work
            #pragma multi_compile_fog

            //GPU INstancing
            #pragma multi_compile_instancing
            #pragma instancing_options procedural:vertInstancingSetup


            #include "UnityCG.cginc"
            #include "UnityStandardParticleInstancing.cginc"

            struct appdata
            {
                float4 vertex : POSITION;
                float2 uv : TEXCOORD0;
                float4 color : COLOR;
                UNITY_VERTEX_INPUT_INSTANCE_ID
            };

            struct v2f
            {
                float2 uv : TEXCOORD0;
                UNITY_FOG_COORDS(1)
                float4 vertex : SV_POSITION;
                float4 color : COLOR;
                UNITY_VERTEX_INPUT_INSTANCE_ID
				UNITY_VERTEX_OUTPUT_STEREO
            };

            sampler2D _MainTex;
            float4 _MainTex_ST;
            float4 _MainColor;
            float _RotateSpeed;
            float _RotateOffset;
            float _RotateWidth;

            float3 vertexRotateX(float a, float3 vertex)
            {
                float y = vertex.y * cos(a) - vertex.z * sin(a);
                float z = vertex.z * cos(a) + vertex.y * sin(a);
                return float3(vertex.x, y, z);
            }

            float ease_out_sine(float x) {
                float t = x; float b = 0; float c = 1; float d = 1;
                return c * sin(t/d * (3.14159265359/2)) + b;
            }

            v2f vert (appdata v)
            {
                v2f o;
                UNITY_SETUP_INSTANCE_ID(v);
				UNITY_INITIALIZE_VERTEX_OUTPUT_STEREO(o);
				UNITY_TRANSFER_INSTANCE_ID(v, o);

                o.color = v.color;
                vertInstancingColor(o.color);
                o.color.rgb = min(1, o.color.rgb); //一部端末でエラー抑制

                float randCol = o.color.w;

                // o.color.wのparticle側の値が0.9～1.0くらいなので1～0の値に補正
                float randCol10x = (1 - o.color.w) * 10;
                randCol10x = saturate(randCol10x);

                //ペンライトの振り方をランダムに変える
                float angle1 = sin((_Time.y + randCol) * _RotateSpeed) + 1. * .5;
                float angle2 = ease_out_sine((sin((_Time.y + randCol) * _RotateSpeed) + 1.) *.5);
                float angleMix = lerp(angle1, angle2, randCol10x);
                angleMix = lerp(angle1, angleMix, .5); //振り方をangle1寄りにする
                angleMix = (angleMix - _RotateOffset) * _RotateWidth;
                o.vertex.xyz = vertexRotateX(angleMix, v.vertex);

                o.vertex = UnityObjectToClipPos(o.vertex);

                o.uv = TRANSFORM_TEX(v.uv, _MainTex);
                vertInstancingUVs(v.uv, o.uv);

                


                UNITY_TRANSFER_FOG(o,o.vertex);
                return o;
            }

            fixed4 frag (v2f i) : SV_Target
            {
                UNITY_SETUP_INSTANCE_ID(i);
                UNITY_SETUP_STEREO_EYE_INDEX_POST_VERTEX(i);

                
                float4 col = _MainColor * i.color;

                // apply fog
                UNITY_APPLY_FOG(i.fogCoord, col);
                return col;
            }
            ENDCG
        }
    }
}
