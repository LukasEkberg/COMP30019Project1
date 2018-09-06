﻿// Upgrade NOTE: replaced 'mul(UNITY_MATRIX_MVP,*)' with 'UnityObjectToClipPos(*)'

// Clearly the vast majority of this Shader comes from tutorial 5.

Shader "Unlit/PhongShader"
{
    Properties
    {
        _PointLightColor("Point Light Color", Color) = (0, 0, 0)
        _PointLightPosition("Point Light Position", Vector) = (0.0, 0.0, 0.0)
    }
    SubShader
    {
        Pass
        {
            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag

            #include "UnityCG.cginc"

            uniform float3 _PointLightColor;
            uniform float3 _PointLightPosition;
            
            // Define a struct for the vertex that will be passed into the
            // vertex shader
            struct vertIn
            {
                float4 vertex : POSITION;
                float4 normal : NORMAL;
                float4 color : COLOR;
            };
            
            // Similarly, define a struct for the vertices that will be returned
            // from the vertex shader
            struct vertOut
            {
                float4 vertex : SV_POSITION;
                float4 color : COLOR;
                float4 worldVertex : TEXCOORD0;
                float3 worldNormal : TEXCOORD1;
            };

            // Implementation of the vertex shader
            vertOut vert(vertIn v)
            {   
                vertOut o;

                // Convert Vertex position and corresponding normal into world
                // coords. Note that we have to multiply the normal by the
                // transposed inverse of the world transformation matrix (for
                // cases where we have non-uniform scaling; we also don't care
                // about the "fourth" dimension, because translations don't
                // affect the normal) 
                float4 worldVertex = mul(unity_ObjectToWorld, v.vertex);
                float3 worldNormal = normalize(mul(transpose((float3x3)unity_WorldToObject), v.normal.xyz));

                // Transform vertex in world coordinates to camera coordinates,
                // and pass colour
                o.vertex = UnityObjectToClipPos(v.vertex);
                o.color = v.color;

                // Pass out the world vertex position and world normal to be
                // interpolated in the fragment shader (and utilised)
                o.worldVertex = worldVertex;
                o.worldNormal = worldNormal;

                return o;
            }

            // Implementation of the fragment shader
            fixed4 frag(vertOut v) : SV_Target
            {
                // Our interpolated normal might not be of length 1
                float3 interpNormal = normalize(v.worldNormal);

                // Calculate ambient RGB intensities
                float Ka = 1;
                float3 amb = v.color.rgb * UNITY_LIGHTMODEL_AMBIENT.rgb * Ka;

                // Calculate diffuse RBG reflections, we save the results of L.N because we will use it again
                // (when calculating the reflected ray in our specular component)
                float fAtt = 1;
                float Kd = 1;
                float3 L = normalize(_PointLightPosition - v.worldVertex.xyz);
                float LdotN = dot(L, interpNormal);
                float3 dif = fAtt * _PointLightColor.rgb * Kd * v.color.rgb * saturate(LdotN);

                // Calculate specular reflections, but reduce Ks, since terrain
                // shouldn't be shiny.
                float Ks = .05;
                float specN = 5; // Values>>1 give tighter highlights
                float3 V = normalize(_WorldSpaceCameraPos - v.worldVertex.xyz);
                // Using Blinn-Phong approximation:
                // We usually need a higher specular power when using
                // Blinn-Phong
                specN = 25;
                float3 H = normalize(V + L);
                float3 spe = fAtt * _PointLightColor.rgb * Ks * pow(saturate(dot(interpNormal, H)), specN);

                // Combine Phong illumination model components
                float4 returnColor = float4(0.0f, 0.0f, 0.0f, 0.0f);
                returnColor.rgb = amb.rgb + dif.rgb + spe.rgb;
                returnColor.a = v.color.a;

                return returnColor;
            }
            ENDCG
        }
    }
}
