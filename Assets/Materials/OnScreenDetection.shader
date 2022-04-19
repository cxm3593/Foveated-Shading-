Shader "Unlit/OnScreenDetection"
{
    Properties
    {
        _MainTex ("Texture", 2D) = "white" {}
        _delay ("Delay", Float) = 0.000001
        
    }
    SubShader
    {
        Tags { "RenderType"="Opaque" }
        LOD 100

        Pass
        {
            GLSLPROGRAM 
            #pragma vertex vert
            #pragma fragment frag
            // make fog work
            #pragma multi_compile_fog

            #include "UnityCG.glslinc"

			#ifdef VERTEX

            //in vec3 vNormal;
            in vec4 vPosition;
            in vec3 vNormal;

            varying vec3 normal;
            varying vec3 vPos;

            

			void main(){
                normal = inverse( transpose( mat3(gl_ModelViewProjectionMatrix) ) ) * vNormal;
                vPos = (gl_ModelViewProjectionMatrix * vPosition).xyz;
				gl_Position = gl_ModelViewProjectionMatrix * vPosition;
                //gl_Position = gl_ModelViewProjectionMatrix * gl_Vertex ;

			}
			
			#endif

			#ifdef FRAGMENT

            varying vec3 normal;
            varying vec3 vPos;

            uniform float _delay;
            uniform vec4 foveated_position = vec4(0);

            vec3 L = (gl_ModelViewProjectionMatrix * _WorldSpaceLightPos0).xyz;
            vec3 N = normalize( normal );
            vec3 R = normalize( -reflect(L, N) );
            vec3 V = normalize( -vPos );
            vec3 P = normalize( vPos );
            vec3 H = R;

            vec4 lightColor = vec4(1, 1, 1, 1);

            vec4 Phong(){
                vec4 ambientColor = vec4(0.1, 0.1, 0.1, 1);
                vec4 ambientLight = vec4(1, 1, 1, 1);
                vec4 ambient = ambientColor * ambientLight;

                vec4 diffuseColor = vec4(1, 0, 0, 1);
                vec4 diffuse = lightColor * diffuseColor * max(dot(N,L),0.0);

                float specExp = 8;
                vec4 specularColor = vec4(1, 1, 1, 1);
                float specDot = pow( max(dot(R,V),0.0), specExp );
                vec4 specular = lightColor * specularColor * specDot;

                vec4 color = (0.1 * ambient) +
                 (0.5 * diffuse) + (0.4 * specular) ;

                return color;
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

            vec4 Strauss(){
                L = -L;
                R = normalize( -reflect(L, N) );
                H = R;



                vec4 C = vec4(1, 0, 0, 1);
                float s = 0.7;
                float m = 0.5;
                float t = 0;

                // calculate components
                //// Component Qd:
                float d = (1 - m*s);
                float rd = (1 - pow(s, 3)) * (1 - t);
                vec4 Qd = dot(N, -L) * d * rd * C;
                Qd = max(Qd, vec4(0.0, 0.0, 0.0, 0.0));

                //// Component Qs:
                // Qs = rs * Cs
                // rs:
                float alpha = dot(N, L);
                float gamma = dot(N, V);
                float h = 3 / (1 - s);
                float rn = (1 - t) - rd;
                float kj = 0.1;
                float j = F(alpha) * G(alpha) * G(gamma);
                float rj = min(1, rn + (rn + kj) * j); // kj = 0.1
                float rs = pow(-dot(R, V), h) * rj; // H = R

                // Cs
                vec4 C1 = lightColor;
                vec4 Cs = C1 + m * (1 - F(alpha)) * (C - C1);

                // Qs
                vec4 Qs = rs * Cs;
                Qs = max(Qs, vec4(0.0, 0.0, 0.0, 0.0));

                // Ir = I (Qd + Qs)
                //vec4 Ir = (Qd + Qs);
                vec4 Ir = Qd + Qs;

                // ambient
                float index = 0;
                    while (index < 1){
                        if (index >= 0){
                            index += _delay;
                        }
                    }

                return Ir * index;
            }
            
			
			void main(){
                

				vec4 onScreenCoordinate = vec4(
					gl_FragCoord.x / _ScreenParams.x, // 0.0 - 1.0
					gl_FragCoord.y / _ScreenParams.y,
					1,
					1);

                vec2 onScreenC_v2 = vec2(onScreenCoordinate.x, onScreenCoordinate.y);

                vec2 target = foveated_position.xy;
                float target_distance = length(target - onScreenCoordinate.xy);
                float switch_distance = 0.1;
                if (target_distance > switch_distance){
                    vec4 color = Phong();
                    gl_FragColor = color;
                    //gl_FragColor = Strauss();
                }
                else{
                    
                    gl_FragColor = Strauss()  ;
                }
				
			}

			#endif
            
            ENDGLSL 
        }
    }
}
