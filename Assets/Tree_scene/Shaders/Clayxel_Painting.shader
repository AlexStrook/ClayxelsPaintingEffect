// Made with Amplify Shader Editor
// Available at the Unity Asset Store - http://u3d.as/y3X 
Shader "Clayxel_Painting"
{
	Properties
	{
		_nm("nm", 2D) = "bump" {}
		_Cutoff( "Mask Clip Value", Float ) = 0.5
		_Metallic("Metallic", Range( 0 , 1)) = 0.5
		_ClayxelSize("ClayxelSize", Range( 0.1 , 2)) = 1
		_NormalOrient("NormalOrient", Range( 0 , 1)) = 0
		_Smoothness1("Smoothness", Range( 0 , 1)) = 0.5
		[NoScaleOffset]_MainTex1("Texture", 2D) = "white" {}
		_randomize("randomize", Range( 0 , 1)) = 0
		_CircleMask("CircleMask", Range( 0 , 1)) = 0
		_NormalTile("NormalTile", Float) = 0
		_NormalScale("NormalScale", Float) = 0
		_Hue("Hue", Range( 0 , 1)) = 0
		_HueRange("HueRange", Range( 0 , 1)) = 0
		_HueIntensity("Hue Intensity", Range( 0 , 1)) = 0
		_Diff("Diff", 2D) = "white" {}
		_FresnelBSP("FresnelBSP", Vector) = (0,1,1,0)
		_Fresnel("Fresnel", Color) = (0,0,0,0)
		_Color0("Color 0", Color) = (0,0,0,0)
		[HideInInspector] _texcoord( "", 2D ) = "white" {}
		[HideInInspector] __dirty( "", Int ) = 1
	}

	SubShader
	{
		Tags{ "RenderType" = "Opaque"  "Queue" = "AlphaTest+0" "IsEmissive" = "true"  }
		Cull Back
		AlphaToMask On
		CGINCLUDE
		#include "UnityShaderVariables.cginc"
		#include "UnityPBSLighting.cginc"
		#include "Lighting.cginc"
		#pragma target 3.0
		#include "Assets/Clayxels/Resources/clayxelSRPUtils.cginc"
		#ifdef UNITY_PASS_SHADOWCASTER
			#undef INTERNAL_DATA
			#undef WorldReflectionVector
			#undef WorldNormalVector
			#define INTERNAL_DATA half3 internalSurfaceTtoW0; half3 internalSurfaceTtoW1; half3 internalSurfaceTtoW2;
			#define WorldReflectionVector(data,normal) reflect (data.worldRefl, half3(dot(data.internalSurfaceTtoW0,normal), dot(data.internalSurfaceTtoW1,normal), dot(data.internalSurfaceTtoW2,normal)))
			#define WorldNormalVector(data,normal) half3(dot(data.internalSurfaceTtoW0,normal), dot(data.internalSurfaceTtoW1,normal), dot(data.internalSurfaceTtoW2,normal))
		#endif

		struct appdata_full_custom
		{
			float4 vertex : POSITION;
			float4 tangent : TANGENT;
			float3 normal : NORMAL;
			float4 texcoord : TEXCOORD0;
			float4 texcoord1 : TEXCOORD1;
			float4 texcoord2 : TEXCOORD2;
			float4 texcoord3 : TEXCOORD3;
			fixed4 color : COLOR;
			UNITY_VERTEX_INPUT_INSTANCE_ID
			uint ase_vertexId : SV_VertexID;
		};
		struct Input
		{
			float3 worldPos;
			half3 worldNormal;
			INTERNAL_DATA
			uint ase_vertexId;
			float4 vertexColor : COLOR;
			float2 uv_texcoord;
		};

		uniform half _ClayxelSize;
		uniform half _NormalOrient;
		sampler2D _nm;
		uniform half _NormalTile;
		uniform half _NormalScale;
		uniform half _Hue;
		uniform half _HueRange;
		uniform half _HueIntensity;
		uniform sampler2D _Diff;
		uniform half4 _Fresnel;
		uniform half3 _FresnelBSP;
		uniform half4 _Color0;
		uniform half _Metallic;
		uniform half _Smoothness1;
		uniform sampler2D _MainTex1;
		uniform half _randomize;
		uniform half _CircleMask;
		uniform float _Cutoff = 0.5;


		float3 mod2D289( float3 x ) { return x - floor( x * ( 1.0 / 289.0 ) ) * 289.0; }

		float2 mod2D289( float2 x ) { return x - floor( x * ( 1.0 / 289.0 ) ) * 289.0; }

		float3 permute( float3 x ) { return mod2D289( ( ( x * 34.0 ) + 1.0 ) * x ); }

		float snoise( float2 v )
		{
			const float4 C = float4( 0.211324865405187, 0.366025403784439, -0.577350269189626, 0.024390243902439 );
			float2 i = floor( v + dot( v, C.yy ) );
			float2 x0 = v - i + dot( i, C.xx );
			float2 i1;
			i1 = ( x0.x > x0.y ) ? float2( 1.0, 0.0 ) : float2( 0.0, 1.0 );
			float4 x12 = x0.xyxy + C.xxzz;
			x12.xy -= i1;
			i = mod2D289( i );
			float3 p = permute( permute( i.y + float3( 0.0, i1.y, 1.0 ) ) + i.x + float3( 0.0, i1.x, 1.0 ) );
			float3 m = max( 0.5 - float3( dot( x0, x0 ), dot( x12.xy, x12.xy ), dot( x12.zw, x12.zw ) ), 0.0 );
			m = m * m;
			m = m * m;
			float3 x = 2.0 * frac( p * C.www ) - 1.0;
			float3 h = abs( x ) - 0.5;
			float3 ox = floor( x + 0.5 );
			float3 a0 = x - ox;
			m *= 1.79284291400159 - 0.85373472095314 * ( a0 * a0 + h * h );
			float3 g;
			g.x = a0.x * x0.x + h.x * x0.y;
			g.yz = a0.yz * x12.xz + h.yz * x12.yw;
			return 130.0 * dot( m, g );
		}


		inline float3 TriplanarSampling138( sampler2D topTexMap, float3 worldPos, float3 worldNormal, float falloff, float2 tiling, float3 normalScale, float3 index )
		{
			float3 projNormal = ( pow( abs( worldNormal ), falloff ) );
			projNormal /= ( projNormal.x + projNormal.y + projNormal.z ) + 0.00001;
			float3 nsign = sign( worldNormal );
			half4 xNorm; half4 yNorm; half4 zNorm;
			xNorm = tex2D( topTexMap, tiling * worldPos.zy * float2(  nsign.x, 1.0 ) );
			yNorm = tex2D( topTexMap, tiling * worldPos.xz * float2(  nsign.y, 1.0 ) );
			zNorm = tex2D( topTexMap, tiling * worldPos.xy * float2( -nsign.z, 1.0 ) );
			xNorm.xyz  = half3( UnpackScaleNormal( xNorm, normalScale.y ).xy * float2(  nsign.x, 1.0 ) + worldNormal.zy, worldNormal.x ).zyx;
			yNorm.xyz  = half3( UnpackScaleNormal( yNorm, normalScale.x ).xy * float2(  nsign.y, 1.0 ) + worldNormal.xz, worldNormal.y ).xzy;
			zNorm.xyz  = half3( UnpackScaleNormal( zNorm, normalScale.y ).xy * float2( -nsign.z, 1.0 ) + worldNormal.xy, worldNormal.z ).xyz;
			return normalize( xNorm.xyz * projNormal.x + yNorm.xyz * projNormal.y + zNorm.xyz * projNormal.z );
		}


		half3 HSVToRGB( half3 c )
		{
			half4 K = half4( 1.0, 2.0 / 3.0, 1.0 / 3.0, 3.0 );
			half3 p = abs( frac( c.xxx + K.xyz ) * 6.0 - K.www );
			return c.z * lerp( K.xxx, saturate( p - K.xxx ), c.y );
		}


		void vertexDataFunc( inout appdata_full_custom v, out Input o )
		{
			UNITY_INITIALIZE_OUTPUT( Input, o );
			half localclayxelComputeVertex7 = ( 0.0 );
			int vertexId7 = v.ase_vertexId;
			half3 vertexPosition7 = float3( 0,0,0 );
			half3 vertexNormal7 = float3( 0,0,0 );
			half clayxelSize7 = _ClayxelSize;
			half normalOrient7 = ( _NormalOrient * 0.45 );
			clayxelVertFoliage(vertexId7 , clayxelSize7, normalOrient7, v.texcoord, v.color.xyz, vertexPosition7, vertexNormal7); 
			v.vertex.w = 1.0; // fix shadows in builtin renderer
			v.tangent = float4(normalize(cross(UNITY_MATRIX_V._m20_m21_m22, vertexNormal7)),0.5);
			v.vertex.xyz += vertexPosition7;
			v.vertex.w = 1;
			v.normal = vertexNormal7;
			o.ase_vertexId = v.ase_vertexId;
		}

		void surf( Input i , inout SurfaceOutputStandard o )
		{
			half localclayxelGetPointCloud109 = ( 0.0 );
			int vertexId109 = i.ase_vertexId;
			half3 pointCenter109 = float3( 0,0,0 );
			half3 pointNormal109 = float3( 0,0,0 );
			half3 pointColor109 = float3( 0,0,0 );
			half3 gridPoint109 = float3( 0,0,0 );
			clayxelGetPointCloud(vertexId109, gridPoint109, pointColor109, pointCenter109, pointNormal109);
			half simplePerlin2D132 = snoise( pointCenter109.xy*1000.0 );
			simplePerlin2D132 = simplePerlin2D132*0.5 + 0.5;
			half Noise145 = simplePerlin2D132;
			float3 ase_worldPos = i.worldPos;
			half3 ase_worldNormal = WorldNormalVector( i, half3( 0, 0, 1 ) );
			half3 ase_worldTangent = WorldNormalVector( i, half3( 1, 0, 0 ) );
			half3 ase_worldBitangent = WorldNormalVector( i, half3( 0, 1, 0 ) );
			half3x3 ase_worldToTangent = float3x3( ase_worldTangent, ase_worldBitangent, ase_worldNormal );
			float3 triplanar138 = TriplanarSampling138( _nm, ase_worldPos, ase_worldNormal, 1.0, ( half2( 1,1 ) * ( _NormalTile * (0.85 + (Noise145 - 0.0) * (2.0 - 0.85) / (1.0 - 0.0)) ) ), _NormalScale, 0 );
			float3 tanTriplanarNormal138 = mul( ase_worldToTangent, triplanar138 );
			o.Normal = tanTriplanarNormal138;
			half3 hsvTorgb162 = HSVToRGB( half3((saturate( ( _Hue - _HueRange ) ) + (Noise145 - 0.0) * (saturate( ( _Hue + _HueRange ) ) - saturate( ( _Hue - _HueRange ) )) / (1.0 - 0.0)),1.0,1.0) );
			half4 lerpResult172 = lerp( i.vertexColor , half4( hsvTorgb162 , 0.0 ) , ( _HueIntensity * (0.85 + (Noise145 - 0.0) * (1.0 - 0.85) / (1.0 - 0.0)) ));
			o.Albedo = ( lerpResult172 * tex2D( _Diff, i.uv_texcoord ) ).rgb;
			half3 ase_worldViewDir = normalize( UnityWorldSpaceViewDir( ase_worldPos ) );
			half3 ase_normWorldNormal = normalize( ase_worldNormal );
			half fresnelNdotV188 = dot( ase_normWorldNormal, ase_worldViewDir );
			half fresnelNode188 = ( _FresnelBSP.x + _FresnelBSP.y * pow( max( 1.0 - fresnelNdotV188 , 0.0001 ), _FresnelBSP.z ) );
			o.Emission = saturate( ( ( _Fresnel * fresnelNode188 ) + _Color0 ) ).rgb;
			o.Metallic = _Metallic;
			o.Smoothness = _Smoothness1;
			o.Alpha = 1;
			half localclayxelGetPointCloud126 = ( 0.0 );
			int vertexId126 = i.ase_vertexId;
			half3 pointCenter126 = float3( 0,0,0 );
			half3 pointNormal126 = float3( 0,0,0 );
			half3 pointColor126 = float3( 0,0,0 );
			half3 gridPoint126 = float3( 0,0,0 );
			clayxelGetPointCloud(vertexId126, gridPoint126, pointColor126, pointCenter126, pointNormal126);
			half dotResult4_g15 = dot( pointCenter126.xy , half2( 12.9898,78.233 ) );
			half lerpResult10_g15 = lerp( -1.0 , 1.0 , frac( ( sin( dotResult4_g15 ) * 43758.55 ) ));
			half dotResult4_g14 = dot( pointCenter126.xy , half2( 12.9898,78.233 ) );
			half lerpResult10_g14 = lerp( -2.0 , 2.0 , frac( ( sin( dotResult4_g14 ) * 43758.55 ) ));
			half2 appendResult125 = (half2(sign( lerpResult10_g15 ) , sign( lerpResult10_g14 )));
			half localclayxelGetPointCloud34 = ( 0.0 );
			int vertexId34 = i.ase_vertexId;
			half3 pointCenter34 = float3( 0,0,0 );
			half3 pointNormal34 = float3( 0,0,0 );
			half3 pointColor34 = float3( 0,0,0 );
			half3 gridPoint34 = float3( 0,0,0 );
			clayxelGetPointCloud(vertexId34, gridPoint34, pointColor34, pointCenter34, pointNormal34);
			half3 break70 = cross( pointCenter34 , pointNormal34 );
			half2 appendResult69 = (half2(break70.x , break70.y));
			half dotResult4_g3 = dot( appendResult69 , half2( 12.9898,78.233 ) );
			half lerpResult10_g3 = lerp( 0.0 , 1000.0 , frac( ( sin( dotResult4_g3 ) * 43758.55 ) ));
			float cos29 = cos( ( lerpResult10_g3 * _randomize ) );
			float sin29 = sin( ( lerpResult10_g3 * _randomize ) );
			half2 rotator29 = mul( i.uv_texcoord - float2( 0.5,0.5 ) , float2x2( cos29 , -sin29 , sin29 , cos29 )) + float2( 0.5,0.5 );
			half temp_output_4_0_g16 = 2.0;
			half temp_output_5_0_g16 = 2.0;
			half2 appendResult7_g16 = (half2(temp_output_4_0_g16 , temp_output_5_0_g16));
			float totalFrames39_g16 = ( temp_output_4_0_g16 * temp_output_5_0_g16 );
			half2 appendResult8_g16 = (half2(totalFrames39_g16 , temp_output_5_0_g16));
			half clampResult42_g16 = clamp( round( (0.0 + (simplePerlin2D132 - 0.0) * (5.0 - 0.0) / (1.0 - 0.0)) ) , 0.0001 , ( totalFrames39_g16 - 1.0 ) );
			half temp_output_35_0_g16 = frac( ( ( _Time.y + clampResult42_g16 ) / totalFrames39_g16 ) );
			half2 appendResult29_g16 = (half2(temp_output_35_0_g16 , ( 1.0 - temp_output_35_0_g16 )));
			half2 temp_output_15_0_g16 = ( ( rotator29 / appendResult7_g16 ) + ( floor( ( appendResult8_g16 * appendResult29_g16 ) ) / appendResult7_g16 ) );
			half4 tex2DNode11 = tex2D( _MainTex1, ( appendResult125 * temp_output_15_0_g16 ) );
			clip( ( ( 1.0 - tex2DNode11.r ) * saturate( ( 1.0 - ( length( (float2( -1,-1 ) + (i.uv_texcoord - float2( 0,0 )) * (float2( 1,1 ) - float2( -1,-1 )) / (float2( 1,1 ) - float2( 0,0 ))) ) - _CircleMask ) ) ) ) - _Cutoff );
		}

		ENDCG
		CGPROGRAM
		#pragma surface surf Standard keepalpha fullforwardshadows nodynlightmap vertex:vertexDataFunc 

		ENDCG
		Pass
		{
			Name "ShadowCaster"
			Tags{ "LightMode" = "ShadowCaster" }
			ZWrite On
			AlphaToMask Off
			CGPROGRAM
			#pragma vertex vert
			#pragma fragment frag
			#pragma target 3.0
			#pragma multi_compile_shadowcaster
			#pragma multi_compile UNITY_PASS_SHADOWCASTER
			#pragma skip_variants FOG_LINEAR FOG_EXP FOG_EXP2
			#include "HLSLSupport.cginc"
			#if ( SHADER_API_D3D11 || SHADER_API_GLCORE || SHADER_API_GLES || SHADER_API_GLES3 || SHADER_API_METAL || SHADER_API_VULKAN )
				#define CAN_SKIP_VPOS
			#endif
			#include "UnityCG.cginc"
			#include "Lighting.cginc"
			#include "UnityPBSLighting.cginc"
			struct v2f
			{
				V2F_SHADOW_CASTER;
				float3 customPack1 : TEXCOORD1;
				float4 tSpace0 : TEXCOORD2;
				float4 tSpace1 : TEXCOORD3;
				float4 tSpace2 : TEXCOORD4;
				half4 color : COLOR0;
				UNITY_VERTEX_INPUT_INSTANCE_ID
				UNITY_VERTEX_OUTPUT_STEREO
			};
			v2f vert( appdata_full_custom v )
			{
				v2f o;
				UNITY_SETUP_INSTANCE_ID( v );
				UNITY_INITIALIZE_OUTPUT( v2f, o );
				UNITY_INITIALIZE_VERTEX_OUTPUT_STEREO( o );
				UNITY_TRANSFER_INSTANCE_ID( v, o );
				Input customInputData;
				vertexDataFunc( v, customInputData );
				float3 worldPos = mul( unity_ObjectToWorld, v.vertex ).xyz;
				half3 worldNormal = UnityObjectToWorldNormal( v.normal );
				half3 worldTangent = UnityObjectToWorldDir( v.tangent.xyz );
				half tangentSign = v.tangent.w * unity_WorldTransformParams.w;
				half3 worldBinormal = cross( worldNormal, worldTangent ) * tangentSign;
				o.tSpace0 = float4( worldTangent.x, worldBinormal.x, worldNormal.x, worldPos.x );
				o.tSpace1 = float4( worldTangent.y, worldBinormal.y, worldNormal.y, worldPos.y );
				o.tSpace2 = float4( worldTangent.z, worldBinormal.z, worldNormal.z, worldPos.z );
				o.customPack1.x = customInputData.ase_vertexId;
				o.customPack1.yz = customInputData.uv_texcoord;
				o.customPack1.yz = v.texcoord;
				TRANSFER_SHADOW_CASTER_NORMALOFFSET( o )
				o.color = v.color;
				return o;
			}
			half4 frag( v2f IN
			#if !defined( CAN_SKIP_VPOS )
			, UNITY_VPOS_TYPE vpos : VPOS
			#endif
			) : SV_Target
			{
				UNITY_SETUP_INSTANCE_ID( IN );
				Input surfIN;
				UNITY_INITIALIZE_OUTPUT( Input, surfIN );
				surfIN.ase_vertexId = IN.customPack1.x;
				surfIN.uv_texcoord = IN.customPack1.yz;
				float3 worldPos = float3( IN.tSpace0.w, IN.tSpace1.w, IN.tSpace2.w );
				half3 worldViewDir = normalize( UnityWorldSpaceViewDir( worldPos ) );
				surfIN.worldPos = worldPos;
				surfIN.worldNormal = float3( IN.tSpace0.z, IN.tSpace1.z, IN.tSpace2.z );
				surfIN.internalSurfaceTtoW0 = IN.tSpace0.xyz;
				surfIN.internalSurfaceTtoW1 = IN.tSpace1.xyz;
				surfIN.internalSurfaceTtoW2 = IN.tSpace2.xyz;
				surfIN.vertexColor = IN.color;
				SurfaceOutputStandard o;
				UNITY_INITIALIZE_OUTPUT( SurfaceOutputStandard, o )
				surf( surfIN, o );
				#if defined( CAN_SKIP_VPOS )
				float2 vpos = IN.pos;
				#endif
				SHADOW_CASTER_FRAGMENT( IN )
			}
			ENDCG
		}
	}
	Fallback "Diffuse"
	CustomEditor "ASEMaterialInspector"
}
/*ASEBEGIN
Version=18500
0;0;1920;1009;6255.75;2931.939;4.796939;True;False
Node;AmplifyShaderEditor.VertexIdVariableNode;35;-4207.679,8.075003;Inherit;False;0;1;INT;0
Node;AmplifyShaderEditor.CustomExpressionNode;34;-4030.33,-7.643591;Inherit;False;clayxelGetPointCloud(vertexId, gridPoint, pointColor, pointCenter, pointNormal)@;7;True;5;False;vertexId;INT;0;In;;Inherit;False;True;pointCenter;FLOAT3;0,0,0;Out;;Inherit;False;True;pointNormal;FLOAT3;0,0,0;Out;;Inherit;False;True;pointColor;FLOAT3;0,0,0;Out;;Inherit;False;True;gridPoint;FLOAT3;0,0,0;Out;;Inherit;False;clayxelGetPointCloud;False;False;0;6;0;FLOAT;0;False;1;INT;0;False;2;FLOAT3;0,0,0;False;3;FLOAT3;0,0,0;False;4;FLOAT3;0,0,0;False;5;FLOAT3;0,0,0;False;5;FLOAT;0;FLOAT3;3;FLOAT3;4;FLOAT3;5;FLOAT3;6
Node;AmplifyShaderEditor.CommentaryNode;209;-3186.957,726.9569;Inherit;False;1001.186;386.0297;Noise used a bit everywhere, produce a undesirable pattern and need to be fixed;5;108;134;109;132;145;;1,1,1,1;0;0
Node;AmplifyShaderEditor.CrossProductOpNode;90;-3732.169,14.33758;Inherit;False;2;0;FLOAT3;0,0,0;False;1;FLOAT3;0,0,0;False;1;FLOAT3;0
Node;AmplifyShaderEditor.VertexIdVariableNode;108;-3136.957,796.9153;Inherit;False;0;1;INT;0
Node;AmplifyShaderEditor.CommentaryNode;210;-2280.067,-359.2415;Inherit;False;1033.558;331;i dont remember what this was for ;7;123;121;124;122;125;127;126;;1,1,1,1;0;0
Node;AmplifyShaderEditor.BreakToComponentsNode;70;-3525.215,-0.4045182;Inherit;False;FLOAT3;1;0;FLOAT3;0,0,0;False;16;FLOAT;0;FLOAT;1;FLOAT;2;FLOAT;3;FLOAT;4;FLOAT;5;FLOAT;6;FLOAT;7;FLOAT;8;FLOAT;9;FLOAT;10;FLOAT;11;FLOAT;12;FLOAT;13;FLOAT;14;FLOAT;15
Node;AmplifyShaderEditor.CustomExpressionNode;109;-2952.792,776.9569;Inherit;False;clayxelGetPointCloud(vertexId, gridPoint, pointColor, pointCenter, pointNormal)@;7;True;5;False;vertexId;INT;0;In;;Inherit;False;True;pointCenter;FLOAT3;0,0,0;Out;;Inherit;False;True;pointNormal;FLOAT3;0,0,0;Out;;Inherit;False;True;pointColor;FLOAT3;0,0,0;Out;;Inherit;False;True;gridPoint;FLOAT3;0,0,0;Out;;Inherit;False;clayxelGetPointCloud;False;False;0;6;0;FLOAT;0;False;1;INT;0;False;2;FLOAT3;0,0,0;False;3;FLOAT3;0,0,0;False;4;FLOAT3;0,0,0;False;5;FLOAT3;0,0,0;False;5;FLOAT;0;FLOAT3;3;FLOAT3;4;FLOAT3;5;FLOAT3;6
Node;AmplifyShaderEditor.VertexIdVariableNode;127;-2230.067,-249.3996;Inherit;False;0;1;INT;0
Node;AmplifyShaderEditor.CommentaryNode;206;-2958.622,33.7714;Inherit;False;796.2737;426.3854;Random Rotation;5;50;49;4;29;31;;1,1,1,1;0;0
Node;AmplifyShaderEditor.RangedFloatNode;134;-2916.871,969.4503;Inherit;False;Constant;_randomScale;randomScale;9;0;Create;True;0;0;False;0;False;1000;1000;0;0;0;1;FLOAT;0
Node;AmplifyShaderEditor.DynamicAppendNode;69;-3200.59,1.500063;Inherit;False;FLOAT2;4;0;FLOAT;0;False;1;FLOAT;0;False;2;FLOAT;0;False;3;FLOAT;0;False;1;FLOAT2;0
Node;AmplifyShaderEditor.NoiseGeneratorNode;132;-2683.859,856.0716;Inherit;False;Simplex2D;True;False;2;0;FLOAT2;0,0;False;1;FLOAT;1;False;1;FLOAT;0
Node;AmplifyShaderEditor.CustomExpressionNode;126;-2037.901,-270.3579;Inherit;False;clayxelGetPointCloud(vertexId, gridPoint, pointColor, pointCenter, pointNormal)@;7;True;5;False;vertexId;INT;0;In;;Inherit;False;True;pointCenter;FLOAT3;0,0,0;Out;;Inherit;False;True;pointNormal;FLOAT3;0,0,0;Out;;Inherit;False;True;pointColor;FLOAT3;0,0,0;Out;;Inherit;False;True;gridPoint;FLOAT3;0,0,0;Out;;Inherit;False;clayxelGetPointCloud;False;False;0;6;0;FLOAT;0;False;1;INT;0;False;2;FLOAT3;0,0,0;False;3;FLOAT3;0,0,0;False;4;FLOAT3;0,0,0;False;5;FLOAT3;0,0,0;False;5;FLOAT;0;FLOAT3;3;FLOAT3;4;FLOAT3;5;FLOAT3;6
Node;AmplifyShaderEditor.FunctionNode;31;-2767.307,203.8806;Inherit;False;Random Range;-1;;3;7b754edb8aebbfb4a9ace907af661cfc;0;3;1;FLOAT2;0,0;False;2;FLOAT;0;False;3;FLOAT;1000;False;1;FLOAT;0
Node;AmplifyShaderEditor.RangedFloatNode;50;-2908.622,345.1568;Inherit;False;Property;_randomize;randomize;7;0;Create;True;0;0;False;0;False;0;1;0;1;0;1;FLOAT;0
Node;AmplifyShaderEditor.CommentaryNode;214;-1329.233,557.2117;Inherit;False;1187.979;372.1411;fade the texture over the edge of triangles (not good : create a lot of overdraw);7;95;96;118;120;98;97;94;;1,1,1,1;0;0
Node;AmplifyShaderEditor.CommentaryNode;207;-2150.229,-2226.859;Inherit;False;1728.384;895.4523;Hue variation;15;165;173;176;174;172;175;167;166;168;169;163;170;171;162;6;;1,1,1,1;0;0
Node;AmplifyShaderEditor.FunctionNode;121;-1752.987,-309.2415;Inherit;False;Random Range;-1;;15;7b754edb8aebbfb4a9ace907af661cfc;0;3;1;FLOAT2;0,0;False;2;FLOAT;-1;False;3;FLOAT;1;False;1;FLOAT;0
Node;AmplifyShaderEditor.TFHCRemapNode;133;-2052.078,828.5821;Inherit;False;5;0;FLOAT;0;False;1;FLOAT;0;False;2;FLOAT;1;False;3;FLOAT;0;False;4;FLOAT;5;False;1;FLOAT;0
Node;AmplifyShaderEditor.FunctionNode;123;-1739.987,-184.2415;Inherit;False;Random Range;-1;;14;7b754edb8aebbfb4a9ace907af661cfc;0;3;1;FLOAT2;0,0;False;2;FLOAT;-2;False;3;FLOAT;2;False;1;FLOAT;0
Node;AmplifyShaderEditor.RangedFloatNode;166;-2089.929,-1893.116;Inherit;False;Property;_Hue;Hue;11;0;Create;True;0;0;False;0;False;0;0.047;0;1;0;1;FLOAT;0
Node;AmplifyShaderEditor.RangedFloatNode;167;-2100.229,-1981.117;Inherit;False;Property;_HueRange;HueRange;12;0;Create;True;0;0;False;0;False;0;0.237;0;1;0;1;FLOAT;0
Node;AmplifyShaderEditor.TextureCoordinatesNode;94;-1279.233,663.2794;Inherit;False;0;-1;2;3;2;SAMPLER2D;;False;0;FLOAT2;1,1;False;1;FLOAT2;0,0;False;5;FLOAT2;0;FLOAT;1;FLOAT;2;FLOAT;3;FLOAT;4
Node;AmplifyShaderEditor.TexCoordVertexDataNode;4;-2626.337,83.7714;Inherit;False;0;2;0;5;FLOAT2;0;FLOAT;1;FLOAT;2;FLOAT;3;FLOAT;4
Node;AmplifyShaderEditor.SimpleMultiplyOpNode;49;-2563.628,249.4094;Inherit;False;2;2;0;FLOAT;0;False;1;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.SignOpNode;122;-1537.986,-309.2415;Inherit;False;1;0;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.SignOpNode;124;-1537.986,-190.2415;Inherit;False;1;0;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.CommentaryNode;208;-2066.57,-1193.468;Inherit;False;1091.96;599.6112;world space normal;8;150;151;140;149;143;142;144;138;;1,1,1,1;0;0
Node;AmplifyShaderEditor.RotatorNode;29;-2375.348,188.0142;Inherit;False;3;0;FLOAT2;0,0;False;1;FLOAT2;0.5,0.5;False;2;FLOAT;1;False;1;FLOAT2;0
Node;AmplifyShaderEditor.SimpleAddOpNode;168;-1698.729,-1896.117;Inherit;False;2;2;0;FLOAT;0;False;1;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.SimpleSubtractOpNode;169;-1688.896,-2040.432;Inherit;False;2;0;FLOAT;0;False;1;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.RoundOpNode;102;-1853.32,815.3759;Inherit;False;1;0;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.RegisterLocalVarNode;145;-2428.771,997.9865;Inherit;False;Noise;-1;True;1;0;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.TFHCRemapNode;95;-954.1006,607.2117;Inherit;False;5;0;FLOAT2;0,0;False;1;FLOAT2;0,0;False;2;FLOAT2;1,1;False;3;FLOAT2;-1,-1;False;4;FLOAT2;1,1;False;1;FLOAT2;0
Node;AmplifyShaderEditor.CommentaryNode;213;-1489.319,1137.24;Inherit;False;1057.736;454.2409;rim lighting;7;189;190;188;191;193;192;194;;1,1,1,1;0;0
Node;AmplifyShaderEditor.CommentaryNode;211;-1613.106,183.4673;Inherit;False;353;252;Comment;1;100;;1,1,1,1;0;0
Node;AmplifyShaderEditor.DynamicAppendNode;125;-1413.51,-256.4004;Inherit;False;FLOAT2;4;0;FLOAT;0;False;1;FLOAT;0;False;2;FLOAT;0;False;3;FLOAT;0;False;1;FLOAT2;0
Node;AmplifyShaderEditor.LengthOpNode;96;-752.1006,613.2117;Inherit;False;1;0;FLOAT2;0,0;False;1;FLOAT;0
Node;AmplifyShaderEditor.RangedFloatNode;118;-950.5496,814.353;Inherit;False;Property;_CircleMask;CircleMask;8;0;Create;True;0;0;False;0;False;0;0.486;0;1;0;1;FLOAT;0
Node;AmplifyShaderEditor.FunctionNode;100;-1563.106,233.4673;Inherit;False;Flipbook;-1;;16;53c2488c220f6564ca6c90721ee16673;2,71,0,68,0;8;51;SAMPLER2D;0.0;False;13;FLOAT2;0,0;False;4;FLOAT;2;False;5;FLOAT;2;False;24;FLOAT;0;False;2;FLOAT;0;False;55;FLOAT;0;False;70;FLOAT;0;False;5;COLOR;53;FLOAT2;0;FLOAT;47;FLOAT;48;FLOAT;62
Node;AmplifyShaderEditor.SaturateNode;171;-1487.796,-1886.032;Inherit;False;1;0;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.Vector3Node;189;-1439.319,1407.48;Inherit;False;Property;_FresnelBSP;FresnelBSP;15;0;Create;True;0;0;False;0;False;0,1,1;0,0.5,1;0;4;FLOAT3;0;FLOAT;1;FLOAT;2;FLOAT;3
Node;AmplifyShaderEditor.GetLocalVarNode;175;-1315.045,-1529.407;Inherit;False;145;Noise;1;0;OBJECT;;False;1;FLOAT;0
Node;AmplifyShaderEditor.GetLocalVarNode;163;-1481.259,-2172.561;Inherit;False;145;Noise;1;0;OBJECT;;False;1;FLOAT;0
Node;AmplifyShaderEditor.GetLocalVarNode;150;-2016.57,-896.6679;Inherit;False;145;Noise;1;0;OBJECT;;False;1;FLOAT;0
Node;AmplifyShaderEditor.SaturateNode;170;-1527.296,-2051.432;Inherit;False;1;0;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.RangedFloatNode;173;-1315.229,-1624.466;Inherit;False;Property;_HueIntensity;Hue Intensity;13;0;Create;True;0;0;False;0;False;0;0.199;0;1;0;1;FLOAT;0
Node;AmplifyShaderEditor.TFHCRemapNode;176;-1125.046,-1533.407;Inherit;False;5;0;FLOAT;0;False;1;FLOAT;0;False;2;FLOAT;1;False;3;FLOAT;0.85;False;4;FLOAT;1;False;1;FLOAT;0
Node;AmplifyShaderEditor.CommentaryNode;212;-184.5348,1147.024;Inherit;False;927.6268;480.8049;default clayxels stuff;5;1;5;2;93;7;;1,1,1,1;0;0
Node;AmplifyShaderEditor.TFHCRemapNode;165;-1288.39,-2176.859;Inherit;False;5;0;FLOAT;0;False;1;FLOAT;0;False;2;FLOAT;1;False;3;FLOAT;0.5;False;4;FLOAT;0.5;False;1;FLOAT;0
Node;AmplifyShaderEditor.ColorNode;190;-1430.319,1193.48;Inherit;False;Property;_Fresnel;Fresnel;16;0;Create;True;0;0;False;0;False;0,0,0,0;0.0233624,0.1981131,0.04497746,0;True;0;5;COLOR;0;FLOAT;1;FLOAT;2;FLOAT;3;FLOAT;4
Node;AmplifyShaderEditor.TFHCRemapNode;151;-1829.571,-914.6679;Inherit;False;5;0;FLOAT;0;False;1;FLOAT;0;False;2;FLOAT;1;False;3;FLOAT;0.85;False;4;FLOAT;2;False;1;FLOAT;0
Node;AmplifyShaderEditor.RangedFloatNode;140;-1822.029,-994.468;Inherit;False;Property;_NormalTile;NormalTile;9;0;Create;True;0;0;False;0;False;0;-0.04;0;0;0;1;FLOAT;0
Node;AmplifyShaderEditor.SimpleSubtractOpNode;120;-629.5495,710.353;Inherit;False;2;0;FLOAT;0;False;1;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.FresnelNode;188;-1262.822,1372.528;Inherit;False;Standard;WorldNormal;ViewDir;True;True;5;0;FLOAT3;0,0,1;False;4;FLOAT3;0,0,0;False;1;FLOAT;0;False;2;FLOAT;1;False;3;FLOAT;5;False;1;FLOAT;0
Node;AmplifyShaderEditor.SimpleMultiplyOpNode;128;-933.0115,46.14059;Inherit;False;2;2;0;FLOAT2;0,0;False;1;FLOAT2;0,0;False;1;FLOAT2;0
Node;AmplifyShaderEditor.TexturePropertyNode;3;-940.87,-324.7855;Inherit;True;Property;_MainTex1;Texture;6;1;[NoScaleOffset];Create;False;0;0;False;0;False;1aa3096b1b9d9204eaa6c75a4275adb1;05b9f4f9595505d458066c275ae00596;False;white;Auto;Texture2D;-1;0;2;SAMPLER2D;0;SAMPLERSTATE;1
Node;AmplifyShaderEditor.SimpleMultiplyOpNode;191;-1043.319,1201.48;Inherit;False;2;2;0;COLOR;0,0,0,0;False;1;FLOAT;0;False;1;COLOR;0
Node;AmplifyShaderEditor.RangedFloatNode;1;-134.5348,1507.673;Inherit;False;Property;_NormalOrient;NormalOrient;4;0;Create;True;0;0;False;0;False;0;0.584;0;1;0;1;FLOAT;0
Node;AmplifyShaderEditor.ColorNode;193;-942.5823,1341.24;Inherit;False;Property;_Color0;Color 0;17;0;Create;True;0;0;False;0;False;0,0,0,0;0.03292986,0.1855648,0.1886791,0;True;0;5;COLOR;0;FLOAT;1;FLOAT;2;FLOAT;3;FLOAT;4
Node;AmplifyShaderEditor.SimpleMultiplyOpNode;174;-929.0457,-1540.407;Inherit;False;2;2;0;FLOAT;0;False;1;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.SamplerNode;11;-689.9233,10.0282;Inherit;True;Property;_TextureSample0;Texture Sample 0;6;0;Create;True;0;0;False;0;False;-1;None;None;True;0;False;white;Auto;False;Object;-1;Auto;Texture2D;8;0;SAMPLER2D;;False;1;FLOAT2;0,0;False;2;FLOAT;0;False;3;FLOAT2;0,0;False;4;FLOAT2;0,0;False;5;FLOAT;1;False;6;FLOAT;0;False;7;SAMPLERSTATE;;False;5;COLOR;0;FLOAT;1;FLOAT;2;FLOAT;3;FLOAT;4
Node;AmplifyShaderEditor.SimpleMultiplyOpNode;149;-1650.478,-960.5429;Inherit;False;2;2;0;FLOAT;0;False;1;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.HSVToRGBNode;162;-1065.786,-2141.055;Inherit;False;3;0;FLOAT;1;False;1;FLOAT;1;False;2;FLOAT;1;False;4;FLOAT3;0;FLOAT;1;FLOAT;2;FLOAT;3
Node;AmplifyShaderEditor.VertexColorNode;6;-1014.651,-1909.411;Inherit;False;0;5;COLOR;0;FLOAT;1;FLOAT;2;FLOAT;3;FLOAT;4
Node;AmplifyShaderEditor.OneMinusNode;98;-493.1004,639.2117;Inherit;False;1;0;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.TextureCoordinatesNode;185;-780.2157,-1206.688;Inherit;False;0;-1;2;3;2;SAMPLER2D;;False;0;FLOAT2;1,1;False;1;FLOAT2;0,0;False;5;FLOAT2;0;FLOAT;1;FLOAT;2;FLOAT;3;FLOAT;4
Node;AmplifyShaderEditor.Vector2Node;143;-1828.03,-1143.468;Inherit;False;Constant;_Vector0;Vector 0;10;0;Create;True;0;0;False;0;False;1,1;0,0;0;3;FLOAT2;0;FLOAT;1;FLOAT;2
Node;AmplifyShaderEditor.SaturateNode;97;-339.2541,657.8447;Inherit;True;1;0;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.SimpleAddOpNode;192;-741.5823,1221.24;Inherit;False;2;2;0;COLOR;0,0,0,0;False;1;COLOR;0,0,0,0;False;1;COLOR;0
Node;AmplifyShaderEditor.SimpleMultiplyOpNode;142;-1495.029,-1017.468;Inherit;False;2;2;0;FLOAT2;0,0;False;1;FLOAT;0;False;1;FLOAT2;0
Node;AmplifyShaderEditor.SimpleMultiplyOpNode;93;164.4321,1494.829;Inherit;False;2;2;0;FLOAT;0;False;1;FLOAT;0.45;False;1;FLOAT;0
Node;AmplifyShaderEditor.RangedFloatNode;2;51.79942,1344.375;Inherit;False;Property;_ClayxelSize;ClayxelSize;3;0;Create;True;0;0;False;0;False;1;2;0.1;2;0;1;FLOAT;0
Node;AmplifyShaderEditor.VertexIdVariableNode;5;180.8072,1215.637;Inherit;False;0;1;INT;0
Node;AmplifyShaderEditor.RangedFloatNode;144;-1844.929,-708.8568;Inherit;False;Property;_NormalScale;NormalScale;10;0;Create;True;0;0;False;0;False;0;0.1;0;0;0;1;FLOAT;0
Node;AmplifyShaderEditor.LerpOp;172;-605.845,-1780.644;Inherit;False;3;0;COLOR;0,0,0,0;False;1;COLOR;0,0,0,0;False;2;FLOAT;0;False;1;COLOR;0
Node;AmplifyShaderEditor.SamplerNode;184;-463.0111,-1230.754;Inherit;True;Property;_Diff;Diff;14;0;Create;True;0;0;False;0;False;-1;None;b82ed60a5ac4a9b478324bb06f9bf242;True;0;False;white;Auto;False;Object;-1;Auto;Texture2D;8;0;SAMPLER2D;;False;1;FLOAT2;0,0;False;2;FLOAT;0;False;3;FLOAT2;0,0;False;4;FLOAT2;0,0;False;5;FLOAT;1;False;6;FLOAT;0;False;7;SAMPLERSTATE;;False;5;COLOR;0;FLOAT;1;FLOAT;2;FLOAT;3;FLOAT;4
Node;AmplifyShaderEditor.OneMinusNode;103;-341.1928,30.71909;Inherit;False;1;0;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.SaturateNode;194;-606.5823,1187.24;Inherit;False;1;0;COLOR;0,0,0,0;False;1;COLOR;0
Node;AmplifyShaderEditor.RangedFloatNode;10;1028.609,221.0128;Inherit;False;Property;_Metallic;Metallic;2;0;Create;True;0;0;True;0;False;0.5;0.692;0;1;0;1;FLOAT;0
Node;AmplifyShaderEditor.RangedFloatNode;8;1023.66,291.3618;Inherit;False;Property;_Smoothness1;Smoothness;5;0;Create;False;0;0;True;0;False;0.5;0.518;0;1;0;1;FLOAT;0
Node;AmplifyShaderEditor.TriplanarNode;138;-1373.61,-888.9309;Inherit;True;Spherical;World;True;nm;_nm;bump;0;None;Mid Texture 0;_MidTexture0;white;-1;None;Bot Texture 0;_BotTexture0;white;-1;None;NM;Tangent;10;0;SAMPLER2D;;False;5;FLOAT;1;False;1;SAMPLER2D;;False;6;FLOAT;0;False;2;SAMPLER2D;;False;7;FLOAT;0;False;9;FLOAT3;0,0,0;False;8;FLOAT;1;False;3;FLOAT2;1,1;False;4;FLOAT;1;False;5;FLOAT3;0;FLOAT;1;FLOAT;2;FLOAT;3;FLOAT;4
Node;AmplifyShaderEditor.SimpleMultiplyOpNode;186;-115.6866,-1254.131;Inherit;False;2;2;0;COLOR;0,0,0,0;False;1;COLOR;0,0,0,0;False;1;COLOR;0
Node;AmplifyShaderEditor.SimpleMultiplyOpNode;104;-14.70372,347.3304;Inherit;False;2;2;0;FLOAT;0;False;1;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.RegisterLocalVarNode;159;-342.4285,-142.3733;Inherit;False;tex;-1;True;1;0;COLOR;0,0,0,0;False;1;COLOR;0
Node;AmplifyShaderEditor.CustomExpressionNode;7;406.092,1197.024;Inherit;False;$clayxelVertFoliage(vertexId , clayxelSize, normalOrient, v.texcoord, v.color.xyz, vertexPosition, vertexNormal)@ $v.vertex.w = 1.0@ // fix shadows in builtin renderer$$v.tangent = float4(normalize(cross(UNITY_MATRIX_V._m20_m21_m22, vertexNormal)),0.5)@$;7;True;5;False;vertexId;INT;0;In;;Inherit;False;False;vertexPosition;FLOAT3;0,0,0;Out;;Inherit;False;False;vertexNormal;FLOAT3;0,0,0;Out;;Inherit;False;False;clayxelSize;FLOAT;0;In;;Inherit;False;False;normalOrient;FLOAT;0;In;;Inherit;False;clayxelComputeVertex;False;False;0;6;0;FLOAT;0;False;1;INT;0;False;2;FLOAT3;0,0,0;False;3;FLOAT3;0,0,0;False;4;FLOAT;0;False;5;FLOAT;0;False;3;FLOAT;0;FLOAT3;3;FLOAT3;4
Node;AmplifyShaderEditor.StandardSurfaceOutputNode;77;728.2875,190.3171;Half;False;True;-1;2;ASEMaterialInspector;0;0;Standard;Clayxel_Painting;False;False;False;False;False;False;False;True;False;False;False;False;False;False;False;False;False;False;False;False;False;Back;0;False;-1;0;False;-1;False;0;False;-1;0;False;-1;False;4;Custom;0.5;True;True;0;True;Opaque;;AlphaTest;All;14;all;True;True;True;True;0;False;-1;False;0;False;-1;255;False;-1;255;False;-1;0;False;-1;0;False;-1;0;False;-1;0;False;-1;0;False;-1;0;False;-1;0;False;-1;0;False;-1;False;2;15;10;25;False;0.5;True;0;5;False;-1;10;False;-1;0;5;False;-1;10;False;-1;0;False;-1;0;False;-1;0;False;5.8;0,0,0,0;VertexScale;True;False;Cylindrical;False;Relative;0;;1;-1;-1;-1;0;True;0;0;False;-1;-1;0;False;-1;1;Include;Assets/Clayxels/Resources/clayxelSRPUtils.cginc;False;;Custom;0;0;False;0.1;False;-1;0;False;9;False;16;0;FLOAT3;0,0,0;False;1;FLOAT3;0,0,0;False;2;FLOAT3;0,0,0;False;3;FLOAT;0;False;4;FLOAT;0;False;5;FLOAT;0;False;6;FLOAT3;0,0,0;False;7;FLOAT3;0,0,0;False;8;FLOAT;0;False;9;FLOAT;0;False;10;FLOAT;0;False;13;FLOAT3;0,0,0;False;11;FLOAT3;0,0,0;False;12;FLOAT3;0,0,0;False;14;FLOAT4;0,0,0,0;False;15;FLOAT3;0,0,0;False;0
WireConnection;34;1;35;0
WireConnection;90;0;34;3
WireConnection;90;1;34;4
WireConnection;70;0;90;0
WireConnection;109;1;108;0
WireConnection;69;0;70;0
WireConnection;69;1;70;1
WireConnection;132;0;109;3
WireConnection;132;1;134;0
WireConnection;126;1;127;0
WireConnection;31;1;69;0
WireConnection;121;1;126;3
WireConnection;133;0;132;0
WireConnection;123;1;126;3
WireConnection;49;0;31;0
WireConnection;49;1;50;0
WireConnection;122;0;121;0
WireConnection;124;0;123;0
WireConnection;29;0;4;0
WireConnection;29;2;49;0
WireConnection;168;0;166;0
WireConnection;168;1;167;0
WireConnection;169;0;166;0
WireConnection;169;1;167;0
WireConnection;102;0;133;0
WireConnection;145;0;132;0
WireConnection;95;0;94;0
WireConnection;125;0;122;0
WireConnection;125;1;124;0
WireConnection;96;0;95;0
WireConnection;100;13;29;0
WireConnection;100;24;102;0
WireConnection;171;0;168;0
WireConnection;170;0;169;0
WireConnection;176;0;175;0
WireConnection;165;0;163;0
WireConnection;165;3;170;0
WireConnection;165;4;171;0
WireConnection;151;0;150;0
WireConnection;120;0;96;0
WireConnection;120;1;118;0
WireConnection;188;1;189;1
WireConnection;188;2;189;2
WireConnection;188;3;189;3
WireConnection;128;0;125;0
WireConnection;128;1;100;0
WireConnection;191;0;190;0
WireConnection;191;1;188;0
WireConnection;174;0;173;0
WireConnection;174;1;176;0
WireConnection;11;0;3;0
WireConnection;11;1;128;0
WireConnection;149;0;140;0
WireConnection;149;1;151;0
WireConnection;162;0;165;0
WireConnection;98;0;120;0
WireConnection;97;0;98;0
WireConnection;192;0;191;0
WireConnection;192;1;193;0
WireConnection;142;0;143;0
WireConnection;142;1;149;0
WireConnection;93;0;1;0
WireConnection;172;0;6;0
WireConnection;172;1;162;0
WireConnection;172;2;174;0
WireConnection;184;1;185;0
WireConnection;103;0;11;1
WireConnection;194;0;192;0
WireConnection;138;8;144;0
WireConnection;138;3;142;0
WireConnection;186;0;172;0
WireConnection;186;1;184;0
WireConnection;104;0;103;0
WireConnection;104;1;97;0
WireConnection;159;0;11;0
WireConnection;7;1;5;0
WireConnection;7;4;2;0
WireConnection;7;5;93;0
WireConnection;77;0;186;0
WireConnection;77;1;138;0
WireConnection;77;2;194;0
WireConnection;77;3;10;0
WireConnection;77;4;8;0
WireConnection;77;10;104;0
WireConnection;77;11;7;3
WireConnection;77;12;7;4
ASEEND*/
//CHKSM=E2BEAEA7CF1E53E522CDE9C9B12BB3FA531F4E56