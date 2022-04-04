Shader "Unlit/OnScreenDetection"
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

			void main(){
				gl_Position = gl_ModelViewProjectionMatrix * gl_Vertex;
			}
			
			#endif

			#ifdef FRAGMENT
			
			void main(){
				vec4 onScreenCoordinate = vec4(
					gl_FragCoord.x / _ScreenParams.x,
					gl_FragCoord.y / _ScreenParams.y,
					gl_FragCoord.z / _ScreenParams.z,
					1);

				gl_FragColor = vec4(1.0, 1.0, 1.0, 1.0) * onScreenCoordinate;
			}

			#endif
            
            ENDGLSL 
        }
    }
}
