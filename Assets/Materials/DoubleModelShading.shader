Shader "Unlit/DoubleModelShading"
{
    Properties
    {
        _MainTex ("Texture", 2D) = "white" {}
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

            in vec4 vPosition;
            in vec3 vNormal;

			void main(){
				gl_Position = gl_ModelViewProjectionMatrix * gl_Vertex;
			}
			
			#endif

			#ifdef FRAGMENT
			
			void main(){
				vec4 onScreenCoordinate = vec4(
					gl_FragCoord.x / _ScreenParams.x, // 0.0 - 1.0
					gl_FragCoord.y / _ScreenParams.y,
					1,
					1);

                vec2 onScreenC_v2 = vec2(onScreenCoordinate.x, onScreenCoordinate.y);
                if (onScreenCoordinate.x < 0.4){
                    //gl_FragColor = vec4(1.0, 1.0, 1.0, 1.0) * onScreenCoordinate;
                    gl_FragColor = vec4(1.0, 1.0, 1.0, 1.0) * _WorldSpaceLightPos0;
                }
                else{
                    gl_FragColor = vec4(1.0, 1.0, 1.0, 1.0) ;
                }
				//gl_FragColor = vec4(1.0, 1.0, 1.0, 1.0) * onScreenCoordinate;
			}

			#endif
            
            ENDGLSL 
        }
    }
}
