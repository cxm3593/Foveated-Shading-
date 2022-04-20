// Upgrade NOTE: replaced 'mul(UNITY_MATRIX_MVP,*)' with 'UnityObjectToClipPos(*)'

Shader "Unlit/HLSL_DoubleBRDF"
{
    Properties
    {
        _MainTex ("Texture", 2D) = "white" {}
        Fov_size ("Foveated Region size", Range(0, 1)) = 0.1
    }
    SubShader
    {
        Tags { "RenderType"="Opaque" }
        LOD 100

        Pass
        {
            CGPROGRAM

            #pragma vertex vert
            #pragma fragment frag
            // make fog work
            #pragma multi_compile_fog

            

            #include "UnityCG.cginc"
            #include "UnityLightingCommon.cginc"

            struct appdata
            {
                float4 vertex : POSITION;
                float3 normal : NORMAL;
                float2 uv : TEXCOORD0;

                UNITY_VERTEX_INPUT_INSTANCE_ID
            };

            struct v2f
            {
                UNITY_FOG_COORDS(1)
                //float4 vertex : SV_POSITION;
                float4 vPos : POSITION;
                float3 normal : NORMAL;
                float4 onScreenPos: TEXCOORD1;
                float2 uv : TEXCOORD0;

                UNITY_VERTEX_OUTPUT_STEREO
            };

            sampler2D _MainTex;
            float4 _MainTex_ST;

            uniform float Fov_size;
            uniform float2 target_region = {0.5, 0.5};

            v2f vert (appdata v)
            {
                v2f o;

                UNITY_SETUP_INSTANCE_ID(v); //Insert
                UNITY_INITIALIZE_OUTPUT(v2f, o); //Insert
                UNITY_INITIALIZE_VERTEX_OUTPUT_STEREO(o); //Insert

                o.uv = TRANSFORM_TEX(v.uv, _MainTex);
                //o.vertex = UnityObjectToClipPos(v.vertex);
                o.vPos = UnityObjectToClipPos(v.vertex.xyz);
                o.normal = normalize(mul(float4(v.normal, 0.0), unity_WorldToObject).xyz);
                o.onScreenPos = ComputeScreenPos(o.vPos);
                return o;
            }

            float getDistance(float2 a, float2 b){
                return sqrt(pow(a.x - b.x, 2) + pow(a.y - b.y, 2));
            }

            float4 Phong(float4 col, float3 N, float3 V, float3 L, float3 R, v2f i){

                float4 ambient = UNITY_LIGHTMODEL_AMBIENT * col; //Ambient component
                float4 diffuse = _LightColor0 * col * max(0.0, dot(N, L)); //Diffuse component
                float specExp = 8;
                float4 specularColor = float4(1, 1, 1, 1);
                float specDot = pow( max(dot(R,V),0.0), specExp );
                float4 specular = _LightColor0 * specularColor * specDot;
                if (dot(i.normal, L) < 0.0) specular = float4(0, 0, 0, 1);

                float4 col_phong = (0.1 * ambient) + (0.5 * diffuse) + (0.4 * specular) ;
                return col_phong;
            }

            float F(float x){
                float kf = 1.12;
                float numerator = (1 / pow((x - kf), 2) ) - ( 1 / pow(kf, 2));
                float denominator = (1 / pow((1 - kf), 2) ) - ( 1 / pow(kf, 2));
                float result = numerator / denominator;
                return result;
            }

            float G(float x){
                float kg = 1.01;
                float numerator = (1 / pow( (1-kg), 2)) - ( 1 / pow( (x-kg), 2 ) );
                float denominator = (1 / pow( (1-kg), 2)) - (1 / pow(kg, 2));
                float result = numerator / denominator;
                return result;
            }

            float4 Strauss(float4 col, float3 N, float3 V, float3 L, float3 R, v2f i){
                L = -L;
                R = normalize( -reflect(L, N) );
                float3 H = R;



                float4 C = col;
                float s = 0.7;
                float m = 0.5;
                float t = 0;

                // calculate components
                //// Component Qd:
                float d = (1 - m*s);
                float rd = (1 - pow(s, 3)) * (1 - t);
                float4 Qd = dot(N, -L) * d * rd * C;
                Qd = max(Qd, float4(0.0, 0.0, 0.0, 0.0));

                //// Component Qs:
                // Qs = rs * Cs
                // rs:
                float4 Qs = float4(0, 0, 0, 1);
                if (dot(i.normal, L) < 0.0){
                    float4 Qs = float4(0, 0, 0, 1);
                }
                else{
                    float alpha = dot(N, L);
                    float gamma = dot(N, V);
                    float h = 3 / (1 - s);
                    float rn = (1 - t) - rd;
                    float kj = 0.1;
                    float j = F(alpha) * G(alpha) * G(gamma);
                    float rj = min(1, rn + (rn + kj) * j); // kj = 0.1
                    float rs = pow(-dot(R, V), h) * rj; // H = R

                    // Cs
                    float4 C1 = _LightColor0;
                    float4 Cs = C1 + m * (1 - F(alpha)) * (C - C1);

                    // Qs
                    float4 Qs = rs * Cs;
                    Qs = max(Qs, float4(0.0, 0.0, 0.0, 0.0));
                }
                

                // Ir = I (Qd + Qs)
                //vec4 Ir = (Qd + Qs);
                float4 Ir = Qd + Qs;

                // ambient
                float index = 0;
                // while (index < 1){
                //     if (index >= 0){
                //         index += _delay;
                //     }
                // }

                return Ir ;
            }

            fixed4 frag (v2f i) : SV_Target
            {
                // sample the texture
                fixed4 col = tex2D(_MainTex, i.uv);
                

                float3 N = normalize(i.normal);
                float3 V = normalize(-_WorldSpaceCameraPos);
                //float3 L = normalize(_WorldSpaceLightPos0.xyz - i.vPos.xyz);
                float3 L = normalize((_WorldSpaceLightPos0).xyz);
                float3 R = normalize(-reflect(-L, N));

                

                col = Phong(col, N, V, L, R, i) ;

                float2 onScreenCoordinate = {i.onScreenPos.x / i.onScreenPos.w, i.onScreenPos.y / i.onScreenPos.w};
                

                float target_distance = getDistance(target_region, onScreenCoordinate);
                if (target_distance > Fov_size){
                    float4 signal_color = {1, 0, 0, 1};
                    col = Phong(col, N, V, L, R, i) ;
                }
                else{
                    col = Strauss(col, N, V, L, R, i);
                }
                return col;
            }
            ENDCG
        }
    }
}
