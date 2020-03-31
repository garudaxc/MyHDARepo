Shader "Unlit/NewUnlitShader"
{
    Properties
    {
        _MainTex ("Texture", 2D) = "white" {}
        _AnimPos("Animation", Range(-5, 5)) = 0
        _NoiseScale("摆动幅度", Range(0, 5)) = 2
        _FadeStart("消散位置", Range(2, 5)) = 3
        _FadeDist("消散距离", Range(2, 10)) = 3
    }
    SubShader
    {
        Tags {"Queue" = "Transparent" "RenderType"="Transparent" }
        LOD 100

        Pass
        {
            Blend SrcAlpha OneMinusSrcAlpha

            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag
            // make fog work
            #pragma multi_compile_fog

            #include "UnityCG.cginc"



            float2 hash22(float2 p) {
                p = float2(dot(p,float2(127.1,311.7)),dot(p,float2(269.5,183.3)));
                return -1.0 + 2.0 * frac(sin(p) * 43758.5453123);
            }


            //perlin
            float perlin_noise(float2 p) {
                float2 pi = floor(p);
                float2 pf = p - pi;
                float2 w = pf * pf * (3.0 - 2.0 * pf);
                return lerp(lerp(dot(hash22(pi + float2(0.0, 0.0)), pf - float2(0.0, 0.0)),
                    dot(hash22(pi + float2(1.0, 0.0)), pf - float2(1.0, 0.0)), w.x),
                    lerp(dot(hash22(pi + float2(0.0, 1.0)), pf - float2(0.0, 1.0)),
                        dot(hash22(pi + float2(1.0, 1.0)), pf - float2(1.0, 1.0)), w.x), w.y);
            }
            


            struct appdata
            {
                float4 vertex : POSITION;
                float2 uv : TEXCOORD0;
                float4 uv1 : TEXCOORD1;
                float2 uv2 : TEXCOORD2;
                float2 uv3 : TEXCOORD3;
                float4 color : COLOR0;
                float3 normal : NORMAL;
                float4 tangent : TANGENT;
            };

            struct v2f
            {
                float2 uv : TEXCOORD0;
                float3 color : TEXCOORD1;
                float3 normal : TEXCOORD2;
                UNITY_FOG_COORDS(1)
                float4 vertex : SV_POSITION;
            };

            sampler2D _MainTex;
            float4 _MainTex_ST;

            float _AnimPos;
            float _NoiseScale;
            float _FadeStart;
            float _FadeDist;

            v2f vert (appdata v)
            {
                // 摆动频率
                float _NoiseTurb = 3;

                v2f o;

                float area = v.uv3.y;
                float pieceNoise = v.color.b;

                float grow = (_AnimPos + 5.0) / 5.0;

                float s = ((2 - grow * 2) - area) / pieceNoise;
                s = clamp(s, 0, 1);             

                float3 binormal = cross(v.normal, v.tangent.xyz) * v.tangent.w;
                binormal = normalize(binormal);                

                float n0 = perlin_noise(float2(frac(area * 100), s * _NoiseTurb));
                float n1 = perlin_noise(float2(frac(area * 133), s * _NoiseTurb));
                float3 turb0 = float3(n0, n1, (n0+n1) * 0.5) * _NoiseScale * (5 - area * 4.0) * 0.1;
                //
                // 注意houdini和unity的手向性相反
                float3 dir = v.normal * v.uv2.x + v.tangent.xyz * v.uv2.y - binormal * v.uv3.x;
                float dirLen = length(dir);

                float3 turb = turb0 * min(s * 2, 2 - s * 2) * dirLen;
                float3 pos = v.vertex.xyz + dir * s + turb;


                float _FallSpeed = 1.6f;
                float fallTime = clamp(_AnimPos - 0.5, 0, 5);

                float3 fallDir = UnityWorldToObjectDir(float3(0, -1, 0));
                float3 fall = fallDir * fallTime * pow(area, 0.4) * _FallSpeed;             

                // 羽毛头部旋转下落
                float3 drop = fallDir * dirLen * _FallSpeed * fallTime * pieceNoise;
                float3 realDrop = normalize(drop - dir) * dirLen + dir;
                pos += realDrop + fall;

                
                float fade = (-4 / _FadeDist) * (length(realDrop + fall) - _FadeStart);
                float alpha = clamp(fade, 0, 1);

                o.vertex = UnityObjectToClipPos(float4(pos, 1));

                o.normal = UnityObjectToWorldNormal(v.normal);
                o.uv = TRANSFORM_TEX(v.uv, _MainTex);
                o.color = alpha.rrrr;
                UNITY_TRANSFER_FOG(o,o.vertex);
                return o;
            }

            fixed4 frag (v2f i) : SV_Target
            {
                // sample the texture
                fixed4 col = tex2D(_MainTex, i.uv);
                col.xyz = col.rgb;

                float3 light = float3(1, 1, 1);
                light = normalize(light);
                float dnl = max(0.3, dot(light, i.normal));
                dnl = pow(dnl, 1.4);

                clip(col.a - 0.5);

                //col.rgb = i.color;
                col.rgb *= dnl;
                col.a = i.color.r;
                // apply fog
                UNITY_APPLY_FOG(i.fogCoord, col);
                return col;
            }
            ENDCG
        }
    }
}
