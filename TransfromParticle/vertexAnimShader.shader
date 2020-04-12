Shader "Unlit/vertexAnimShader"
{
    Properties
    {
        _MainTex ("Texture", 2D) = "white" {}
        _MainTex2("Texture2", 2D) = "white" {}
        _posMax("Position Max", Float) = 1.0
        _posMin("Position Min", Float) = 1.0
        _numOfFrames("Number Of Frames", int) = 240
        _speed("Speed", Float) = 0.33
        _packNorm ("Pack Normal", Float) = 1.0
        _doubleTex ("Double Texture (Higher Precision)", Float) = 0.0
        _padPowTwo ("Power of 2", Float) = 0.0
        _textureSizeX ("Active Pixels X", Int) = 128
        _textureSizeY ("Active Pixels Y", Int) = 128
        _paddedSizeX ("Padded Size X", Int) = 128
        _paddedSizeY ("Padded Size Y", Int) = 128
        sampler_posTex("Position Map (RGB)", 2D) = "white" {}
        _DebugTime("Debug Time", Range(0, 10)) = 0
    }
    SubShader
    {
        Tags { "RenderType"="Opaque" }
        LOD 100

        Pass
        {
            Cull off
            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag
            // make fog work
            #pragma multi_compile_fog

            #include "UnityCG.cginc"

            struct appdata
            {
                float4 vertex : POSITION;
                float3 normalOS      : NORMAL;
                float4 tangentOS     : TANGENT;
                float4 texcoord      : TEXCOORD0;
                float4 texcoord1     : TEXCOORD1;
                float4 texcoord2     : TEXCOORD2;
            };

            struct v2f
            {
                float4 uv : TEXCOORD0;
                float3 color : TEXCOORD1;
                float4 vertex : SV_POSITION;
            };

            sampler2D _MainTex;
            sampler2D _MainTex2;
            float4 _MainTex_ST;

            float _posMax;
            float _posMin;
            int _numOfFrames;
            float _speed;
            int _packNorm;
            int _doubleTex;
            int _padPowTwo;
            float _textureSizeX;
            float _textureSizeY;
            float _paddedSizeX;
            float _paddedSizeY;
            float _DebugTime;

            //TEXTURE2D(_posTex);
            sampler2D sampler_posTex;

            v2f vert (appdata v)
            {
                v2f o;


                float4 uv2 = v.texcoord2;


                //calculate uv coordinates
                float FPS = 24.0;
                // float FPS_div_Frames = FPS / _numOfFrames;
                //Use the line below if you want to use time to animate the object
                // float timeInFrames = frac(FPS_div_Frames * _speed * _Time.y);
                
                //float timeInFrames = frac(_speed * _Time.y);
                float timeInFrames = frac(_speed * _DebugTime * 0.0989);
                //The line below is particle age to drive the animation. Comment it out if you want to use time above.
                // timeInFrames = uv.z;
                
                timeInFrames = ceil(timeInFrames * _numOfFrames);
                timeInFrames /= _numOfFrames;
                
                float x_ratio = _textureSizeX/_paddedSizeX;
                float y_ratio = _textureSizeY/_paddedSizeY;
                float uv2y = 0;
                float uv2x = 0;
                if (_padPowTwo) {
                    uv2x = uv2.x * x_ratio;
                    uv2y = (1 - (timeInFrames * y_ratio)) + (1 - ((1 - uv2.y) * y_ratio));
                }
                else {
                    uv2y = (1 - timeInFrames) + uv2.y;
                    uv2x = uv2.x;
                }
                
                //get position, normal and colour from textures
                float4 texturePos = tex2Dlod(sampler_posTex,  float4(uv2x, uv2y, 0, 0));

                                //expand normalised position texture values to world space
                float expand = _posMax - _posMin;
                texturePos.xyz *= expand;
                texturePos.xyz += _posMin;
                // texturePos.x *= -1;  //flipped to account for right-handedness of unity
                float3 vertexPos = v.vertex.xyz + texturePos.xyz * 100;  //swizzle y and z because textures are exported with z-up


                o.vertex = UnityObjectToClipPos(float4(vertexPos, 1));
                o.uv.xy = TRANSFORM_TEX(v.texcoord, _MainTex);
                o.uv.zw = TRANSFORM_TEX(v.texcoord1, _MainTex);

                o.color = texturePos.xyz;
                return o;
            }

            fixed4 frag (v2f i) : SV_Target
            {
                // sample the texture
                fixed4 col = tex2D(_MainTex, i.uv.xy);
                fixed4 col2 = tex2D(_MainTex2, i.uv.zw);

                float l = clamp(_DebugTime * 0.0989, 0, 1);

                fixed4 c = lerp(col, col2, l);

            //col.xyz = i.color;
                // apply fog
                UNITY_APPLY_FOG(i.fogCoord, col);
                return c;
            }
            ENDCG
        }
    }
}
