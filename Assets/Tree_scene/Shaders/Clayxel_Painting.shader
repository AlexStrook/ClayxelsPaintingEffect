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
		#define ASE_TEXTURE_PARAMS(textureName) textureName

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
		uniform sampler2D _nm;
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


		inline float3 TriplanarSamplingSNF( sampler2D topTexMap, float3 worldPos, float3 worldNormal, float falloff, float2 tiling, float3 normalScale, float3 index )
		{
			float3 projNormal = ( pow( abs( worldNormal ), falloff ) );
			projNormal /= ( projNormal.x + projNormal.y + projNormal.z ) + 0.00001;
			float3 nsign = sign( worldNormal );
			half4 xNorm; half4 yNorm; half4 zNorm;
			xNorm = ( tex2D( ASE_TEXTURE_PARAMS( topTexMap ), tiling * worldPos.zy * float2( nsign.x, 1.0 ) ) );
			yNorm = ( tex2D( ASE_TEXTURE_PARAMS( topTexMap ), tiling * worldPos.xz * float2( nsign.y, 1.0 ) ) );
			zNorm = ( tex2D( ASE_TEXTURE_PARAMS( topTexMap ), tiling * worldPos.xy * float2( -nsign.z, 1.0 ) ) );
			xNorm.xyz = half3( UnpackScaleNormal( xNorm, normalScale.y ).xy * float2( nsign.x, 1.0 ) + worldNormal.zy, worldNormal.x ).zyx;
			yNorm.xyz = half3( UnpackScaleNormal( yNorm, normalScale.x ).xy * float2( nsign.y, 1.0 ) + worldNormal.xz, worldNormal.y ).xzy;
			zNorm.xyz = half3( UnpackScaleNormal( zNorm, normalScale.y ).xy * float2( -nsign.z, 1.0 ) + worldNormal.xy, worldNormal.z ).xyz;
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
			float3 triplanar138 = TriplanarSamplingSNF( _nm, ase_worldPos, ase_worldNormal, 1.0, ( half2( 1,1 ) * ( _NormalTile * (0.85 + (Noise145 - 0.0) * (2.0 - 0.85) / (1.0 - 0.0)) ) ), _NormalScale, 0 );
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
			half dotResult4_g13 = dot( pointCenter126.xy , half2( 12.9898,78.233 ) );
			half lerpResult10_g13 = lerp( -1.0 , 1.0 , frac( ( sin( dotResult4_g13 ) * 43758.55 ) ));
			half dotResult4_g14 = dot( pointCenter126.xy , half2( 12.9898,78.233 ) );
			half lerpResult10_g14 = lerp( -2.0 , 2.0 , frac( ( sin( dotResult4_g14 ) * 43758.55 ) ));
			half2 appendResult125 = (half2(sign( lerpResult10_g13 ) , sign( lerpResult10_g14 )));
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
			half temp_output_4_0_g15 = 2.0;
			half temp_output_5_0_g15 = 2.0;
			half2 appendResult7_g15 = (half2(temp_output_4_0_g15 , temp_output_5_0_g15));
			float totalFrames39_g15 = ( temp_output_4_0_g15 * temp_output_5_0_g15 );
			half2 appendResult8_g15 = (half2(totalFrames39_g15 , temp_output_5_0_g15));
			half mulTime3_g15 = _Time.y * Noise145;
			half clampResult42_g15 = clamp( round( (0.0 + (simplePerlin2D132 - 0.0) * (5.0 - 0.0) / (1.0 - 0.0)) ) , 0.0001 , ( totalFrames39_g15 - 1.0 ) );
			half temp_output_35_0_g15 = frac( ( ( mulTime3_g15 + clampResult42_g15 ) / totalFrames39_g15 ) );
			half2 appendResult29_g15 = (half2(temp_output_35_0_g15 , ( 1.0 - temp_output_35_0_g15 )));
			half2 temp_output_15_0_g15 = ( ( rotator29 / appendResult7_g15 ) + ( floor( ( appendResult8_g15 * appendResult29_g15 ) ) / appendResult7_g15 ) );
			half4 tex2DNode11 = tex2D( _MainTex1, ( appendResult125 * temp_output_15_0_g15 ) );
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
Version=17900
526;696;984;680;729.8444;-387.5766;1.811039;True;False
Node;AmplifyShaderEditor.VertexIdVariableNode;35;-3507.834,-60.2031;Inherit;False;0;1;INT;0
Node;AmplifyShaderEditor.CustomExpressionNode;34;-3330.485,-75.92169;Inherit;False;clayxelGetPointCloud(vertexId, gridPoint, pointColor, pointCenter, pointNormal)@;7;True;5;False;vertexId;INT;0;In;;Inherit;False;True;pointCenter;FLOAT3;0,0,0;Out;;Inherit;False;True;pointNormal;FLOAT3;0,0,0;Out;;Inherit;False;True;pointColor;FLOAT3;0,0,0;Out;;Inherit;False;True;gridPoint;FLOAT3;0,0,0;Out;;Inherit;False;clayxelGetPointCloud;False;False;0;6;0;FLOAT;0;False;1;INT;0;False;2;FLOAT3;0,0,0;False;3;FLOAT3;0,0,0;False;4;FLOAT3;0,0,0;False;5;FLOAT3;0,0,0;False;5;FLOAT;0;FLOAT3;3;FLOAT3;4;FLOAT3;5;FLOAT3;6
Node;AmplifyShaderEditor.CrossProductOpNode;90;-3032.324,-53.94052;Inherit;False;2;0;FLOAT3;0,0,0;False;1;FLOAT3;0,0,0;False;1;FLOAT3;0
Node;AmplifyShaderEditor.BreakToComponentsNode;70;-2843.37,-3.682618;Inherit;False;FLOAT3;1;0;FLOAT3;0,0,0;False;16;FLOAT;0;FLOAT;1;FLOAT;2;FLOAT;3;FLOAT;4;FLOAT;5;FLOAT;6;FLOAT;7;FLOAT;8;FLOAT;9;FLOAT;10;FLOAT;11;FLOAT;12;FLOAT;13;FLOAT;14;FLOAT;15
Node;AmplifyShaderEditor.VertexIdVariableNode;108;-2651.279,809.1593;Inherit;False;0;1;INT;0
Node;AmplifyShaderEditor.RangedFloatNode;134;-2431.193,981.6943;Inherit;False;Constant;_randomScale;randomScale;9;0;Create;True;0;0;False;0;1000;1000;0;0;0;1;FLOAT;0
Node;AmplifyShaderEditor.CustomExpressionNode;109;-2467.114,789.2009;Inherit;False;clayxelGetPointCloud(vertexId, gridPoint, pointColor, pointCenter, pointNormal)@;7;True;5;False;vertexId;INT;0;In;;Inherit;False;True;pointCenter;FLOAT3;0,0,0;Out;;Inherit;False;True;pointNormal;FLOAT3;0,0,0;Out;;Inherit;False;True;pointColor;FLOAT3;0,0,0;Out;;Inherit;False;True;gridPoint;FLOAT3;0,0,0;Out;;Inherit;False;clayxelGetPointCloud;False;False;0;6;0;FLOAT;0;False;1;INT;0;False;2;FLOAT3;0,0,0;False;3;FLOAT3;0,0,0;False;4;FLOAT3;0,0,0;False;5;FLOAT3;0,0,0;False;5;FLOAT;0;FLOAT3;3;FLOAT3;4;FLOAT3;5;FLOAT3;6
Node;AmplifyShaderEditor.VertexIdVariableNode;127;-1888.813,-200.9516;Inherit;False;0;1;INT;0
Node;AmplifyShaderEditor.DynamicAppendNode;69;-2518.745,-1.778038;Inherit;False;FLOAT2;4;0;FLOAT;0;False;1;FLOAT;0;False;2;FLOAT;0;False;3;FLOAT;0;False;1;FLOAT2;0
Node;AmplifyShaderEditor.CustomExpressionNode;126;-1682.647,-230.9099;Inherit;False;clayxelGetPointCloud(vertexId, gridPoint, pointColor, pointCenter, pointNormal)@;7;True;5;False;vertexId;INT;0;In;;Inherit;False;True;pointCenter;FLOAT3;0,0,0;Out;;Inherit;False;True;pointNormal;FLOAT3;0,0,0;Out;;Inherit;False;True;pointColor;FLOAT3;0,0,0;Out;;Inherit;False;True;gridPoint;FLOAT3;0,0,0;Out;;Inherit;False;clayxelGetPointCloud;False;False;0;6;0;FLOAT;0;False;1;INT;0;False;2;FLOAT3;0,0,0;False;3;FLOAT3;0,0,0;False;4;FLOAT3;0,0,0;False;5;FLOAT3;0,0,0;False;5;FLOAT;0;FLOAT3;3;FLOAT3;4;FLOAT3;5;FLOAT3;6
Node;AmplifyShaderEditor.FunctionNode;31;-2410.272,224.0759;Inherit;False;Random Range;-1;;3;7b754edb8aebbfb4a9ace907af661cfc;0;3;1;FLOAT2;0,0;False;2;FLOAT;0;False;3;FLOAT;1000;False;1;FLOAT;0
Node;AmplifyShaderEditor.RangedFloatNode;50;-2554.587,353.352;Inherit;False;Property;_randomize;randomize;8;0;Create;True;0;0;False;0;0;1;0;1;0;1;FLOAT;0
Node;AmplifyShaderEditor.NoiseGeneratorNode;132;-2198.181,868.3156;Inherit;False;Simplex2D;True;False;2;0;FLOAT2;0,0;False;1;FLOAT;1;False;1;FLOAT;0
Node;AmplifyShaderEditor.RangedFloatNode;167;-1885.829,-1862.117;Inherit;False;Property;_HueRange;HueRange;13;0;Create;True;0;0;False;0;0;0.237;0;1;0;1;FLOAT;0
Node;AmplifyShaderEditor.RangedFloatNode;166;-1875.529,-1774.116;Inherit;False;Property;_Hue;Hue;12;0;Create;True;0;0;False;0;0;0.047;0;1;0;1;FLOAT;0
Node;AmplifyShaderEditor.TextureCoordinatesNode;94;-969.3891,215.718;Inherit;False;0;-1;2;3;2;SAMPLER2D;;False;0;FLOAT2;1,1;False;1;FLOAT2;0,0;False;5;FLOAT2;0;FLOAT;1;FLOAT;2;FLOAT;3;FLOAT;4
Node;AmplifyShaderEditor.TFHCRemapNode;133;-1773.11,816.4754;Inherit;False;5;0;FLOAT;0;False;1;FLOAT;0;False;2;FLOAT;1;False;3;FLOAT;0;False;4;FLOAT;5;False;1;FLOAT;0
Node;AmplifyShaderEditor.SimpleMultiplyOpNode;49;-2209.593,257.6046;Inherit;False;2;2;0;FLOAT;0;False;1;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.RegisterLocalVarNode;145;-2009.754,1014.312;Inherit;False;Noise;-1;True;1;0;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.TexCoordVertexDataNode;4;-2272.302,91.96666;Inherit;False;0;2;0;5;FLOAT2;0;FLOAT;1;FLOAT;2;FLOAT;3;FLOAT;4
Node;AmplifyShaderEditor.FunctionNode;123;-1384.732,-144.7935;Inherit;False;Random Range;-1;;14;7b754edb8aebbfb4a9ace907af661cfc;0;3;1;FLOAT2;0,0;False;2;FLOAT;-2;False;3;FLOAT;2;False;1;FLOAT;0
Node;AmplifyShaderEditor.FunctionNode;121;-1397.732,-269.7935;Inherit;False;Random Range;-1;;13;7b754edb8aebbfb4a9ace907af661cfc;0;3;1;FLOAT2;0,0;False;2;FLOAT;-1;False;3;FLOAT;1;False;1;FLOAT;0
Node;AmplifyShaderEditor.RoundOpNode;102;-1589.331,808.5957;Inherit;False;1;0;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.SimpleAddOpNode;168;-1484.329,-1777.117;Inherit;False;2;2;0;FLOAT;0;False;1;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.SimpleSubtractOpNode;169;-1474.496,-1921.432;Inherit;False;2;0;FLOAT;0;False;1;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.SignOpNode;124;-1182.731,-150.7935;Inherit;False;1;0;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.TFHCRemapNode;95;-750.9565,184.1505;Inherit;False;5;0;FLOAT2;0,0;False;1;FLOAT2;0,0;False;2;FLOAT2;1,1;False;3;FLOAT2;-1,-1;False;4;FLOAT2;1,1;False;1;FLOAT2;0
Node;AmplifyShaderEditor.GetLocalVarNode;205;-1724.789,98.67396;Inherit;False;145;Noise;1;0;OBJECT;;False;1;FLOAT;0
Node;AmplifyShaderEditor.RotatorNode;29;-2021.313,196.2094;Inherit;False;3;0;FLOAT2;0,0;False;1;FLOAT2;0.5,0.5;False;2;FLOAT;1;False;1;FLOAT2;0
Node;AmplifyShaderEditor.SignOpNode;122;-1182.731,-269.7935;Inherit;False;1;0;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.FunctionNode;100;-1449.597,230.6535;Inherit;False;Flipbook;-1;;15;53c2488c220f6564ca6c90721ee16673;2,71,0,68,0;9;73;FLOAT;1;False;51;SAMPLER2D;0.0;False;13;FLOAT2;0,0;False;4;FLOAT;2;False;5;FLOAT;2;False;24;FLOAT;0;False;2;FLOAT;0;False;55;FLOAT;0;False;70;FLOAT;0;False;5;COLOR;53;FLOAT2;0;FLOAT;47;FLOAT;48;FLOAT;62
Node;AmplifyShaderEditor.DynamicAppendNode;125;-1058.255,-216.9524;Inherit;False;FLOAT2;4;0;FLOAT;0;False;1;FLOAT;0;False;2;FLOAT;0;False;3;FLOAT;0;False;1;FLOAT2;0
Node;AmplifyShaderEditor.SaturateNode;171;-1273.396,-1744.032;Inherit;False;1;0;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.LengthOpNode;96;-548.9565,190.1505;Inherit;False;1;0;FLOAT2;0,0;False;1;FLOAT;0
Node;AmplifyShaderEditor.RangedFloatNode;118;-747.4055,391.2916;Inherit;False;Property;_CircleMask;CircleMask;9;0;Create;True;0;0;False;0;0;0.486;0;1;0;1;FLOAT;0
Node;AmplifyShaderEditor.GetLocalVarNode;150;-1997.718,-1021.776;Inherit;False;145;Noise;1;0;OBJECT;;False;1;FLOAT;0
Node;AmplifyShaderEditor.Vector3Node;189;-820.3605,853.2983;Inherit;False;Property;_FresnelBSP;FresnelBSP;16;0;Create;True;0;0;False;0;0,1,1;0,0.5,1;0;4;FLOAT3;0;FLOAT;1;FLOAT;2;FLOAT;3
Node;AmplifyShaderEditor.GetLocalVarNode;163;-1617.859,-2010.561;Inherit;False;145;Noise;1;0;OBJECT;;False;1;FLOAT;0
Node;AmplifyShaderEditor.SaturateNode;170;-1312.896,-1860.432;Inherit;False;1;0;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.GetLocalVarNode;175;-1082.645,-1422.407;Inherit;False;145;Noise;1;0;OBJECT;;False;1;FLOAT;0
Node;AmplifyShaderEditor.ColorNode;190;-811.3605,639.2983;Inherit;False;Property;_Fresnel;Fresnel;17;0;Create;True;0;0;False;0;0,0,0,0;0.0233624,0.1981131,0.04497746,0;True;0;5;COLOR;0;FLOAT;1;FLOAT;2;FLOAT;3;FLOAT;4
Node;AmplifyShaderEditor.TFHCRemapNode;165;-1073.99,-2056.859;Inherit;False;5;0;FLOAT;0;False;1;FLOAT;0;False;2;FLOAT;1;False;3;FLOAT;0.5;False;4;FLOAT;0.5;False;1;FLOAT;0
Node;AmplifyShaderEditor.FresnelNode;188;-643.8641,818.3457;Inherit;False;Standard;WorldNormal;ViewDir;True;True;5;0;FLOAT3;0,0,1;False;4;FLOAT3;0,0,0;False;1;FLOAT;0;False;2;FLOAT;1;False;3;FLOAT;5;False;1;FLOAT;0
Node;AmplifyShaderEditor.SimpleSubtractOpNode;120;-426.4055,287.2916;Inherit;False;2;0;FLOAT;0;False;1;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.RangedFloatNode;173;-1100.829,-1504.466;Inherit;False;Property;_HueIntensity;Hue Intensity;14;0;Create;True;0;0;False;0;0;0.199;0;1;0;1;FLOAT;0
Node;AmplifyShaderEditor.TFHCRemapNode;151;-1810.719,-1039.776;Inherit;False;5;0;FLOAT;0;False;1;FLOAT;0;False;2;FLOAT;1;False;3;FLOAT;0.85;False;4;FLOAT;2;False;1;FLOAT;0
Node;AmplifyShaderEditor.TexturePropertyNode;3;-940.87,-324.7855;Inherit;True;Property;_MainTex1;Texture;6;1;[NoScaleOffset];Create;False;0;0;False;0;1aa3096b1b9d9204eaa6c75a4275adb1;05b9f4f9595505d458066c275ae00596;False;white;Auto;Texture2D;-1;0;1;SAMPLER2D;0
Node;AmplifyShaderEditor.SimpleMultiplyOpNode;128;-930.4115,24.04059;Inherit;False;2;2;0;FLOAT2;0,0;False;1;FLOAT2;0,0;False;1;FLOAT2;0
Node;AmplifyShaderEditor.TFHCRemapNode;176;-910.6457,-1413.407;Inherit;False;5;0;FLOAT;0;False;1;FLOAT;0;False;2;FLOAT;1;False;3;FLOAT;0.85;False;4;FLOAT;1;False;1;FLOAT;0
Node;AmplifyShaderEditor.RangedFloatNode;140;-1803.177,-1119.576;Inherit;False;Property;_NormalTile;NormalTile;10;0;Create;True;0;0;False;0;0;-0.04;0;0;0;1;FLOAT;0
Node;AmplifyShaderEditor.HSVToRGBNode;162;-926.7859,-1939.155;Inherit;False;3;0;FLOAT;1;False;1;FLOAT;1;False;2;FLOAT;1;False;4;FLOAT3;0;FLOAT;1;FLOAT;2;FLOAT;3
Node;AmplifyShaderEditor.SamplerNode;11;-662.6234,-143.3718;Inherit;True;Property;_TextureSample0;Texture Sample 0;6;0;Create;True;0;0;False;0;-1;None;None;True;0;False;white;Auto;False;Object;-1;Auto;Texture2D;6;0;SAMPLER2D;;False;1;FLOAT2;0,0;False;2;FLOAT;0;False;3;FLOAT2;0,0;False;4;FLOAT2;0,0;False;5;FLOAT;1;False;5;COLOR;0;FLOAT;1;FLOAT;2;FLOAT;3;FLOAT;4
Node;AmplifyShaderEditor.SimpleMultiplyOpNode;174;-714.6456,-1420.407;Inherit;False;2;2;0;FLOAT;0;False;1;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.SimpleMultiplyOpNode;191;-424.3605,647.2983;Inherit;False;2;2;0;COLOR;0,0,0,0;False;1;FLOAT;0;False;1;COLOR;0
Node;AmplifyShaderEditor.RangedFloatNode;1;-733.4143,1373.595;Inherit;False;Property;_NormalOrient;NormalOrient;4;0;Create;True;0;0;False;0;0;0.584;0;1;0;1;FLOAT;0
Node;AmplifyShaderEditor.SimpleMultiplyOpNode;149;-1631.626,-1085.651;Inherit;False;2;2;0;FLOAT;0;False;1;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.TextureCoordinatesNode;185;-780.2157,-1206.688;Inherit;False;0;-1;2;3;2;SAMPLER2D;;False;0;FLOAT2;1,1;False;1;FLOAT2;0,0;False;5;FLOAT2;0;FLOAT;1;FLOAT;2;FLOAT;3;FLOAT;4
Node;AmplifyShaderEditor.ColorNode;193;-323.6244,787.0574;Inherit;False;Property;_Color0;Color 0;18;0;Create;True;0;0;False;0;0,0,0,0;0.03292986,0.1855648,0.1886791,0;True;0;5;COLOR;0;FLOAT;1;FLOAT;2;FLOAT;3;FLOAT;4
Node;AmplifyShaderEditor.Vector2Node;143;-1809.178,-1268.576;Inherit;False;Constant;_Vector0;Vector 0;10;0;Create;True;0;0;False;0;1,1;0,0;0;3;FLOAT2;0;FLOAT;1;FLOAT;2
Node;AmplifyShaderEditor.OneMinusNode;98;-289.9565,216.1505;Inherit;False;1;0;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.VertexColorNode;6;-929.8511,-1719.011;Inherit;False;0;5;COLOR;0;FLOAT;1;FLOAT;2;FLOAT;3;FLOAT;4
Node;AmplifyShaderEditor.LerpOp;172;-391.445,-1660.644;Inherit;False;3;0;COLOR;0,0,0,0;False;1;COLOR;0,0,0,0;False;2;FLOAT;0;False;1;COLOR;0
Node;AmplifyShaderEditor.VertexIdVariableNode;5;-418.0722,1081.559;Inherit;False;0;1;INT;0
Node;AmplifyShaderEditor.RangedFloatNode;2;-547.08,1210.297;Inherit;False;Property;_ClayxelSize;ClayxelSize;3;0;Create;True;0;0;False;0;1;2;0.1;2;0;1;FLOAT;0
Node;AmplifyShaderEditor.SimpleAddOpNode;192;-122.6244,667.0574;Inherit;False;2;2;0;COLOR;0,0,0,0;False;1;COLOR;0,0,0,0;False;1;COLOR;0
Node;AmplifyShaderEditor.OneMinusNode;103;-144.2603,101.7176;Inherit;False;1;0;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.SimpleMultiplyOpNode;93;-434.4473,1360.751;Inherit;False;2;2;0;FLOAT;0;False;1;FLOAT;0.45;False;1;FLOAT;0
Node;AmplifyShaderEditor.SamplerNode;184;-463.0111,-1230.754;Inherit;True;Property;_Diff;Diff;15;0;Create;True;0;0;False;0;-1;None;b82ed60a5ac4a9b478324bb06f9bf242;True;0;False;white;Auto;False;Object;-1;Auto;Texture2D;6;0;SAMPLER2D;;False;1;FLOAT2;0,0;False;2;FLOAT;0;False;3;FLOAT2;0,0;False;4;FLOAT2;0,0;False;5;FLOAT;1;False;5;COLOR;0;FLOAT;1;FLOAT;2;FLOAT;3;FLOAT;4
Node;AmplifyShaderEditor.SimpleMultiplyOpNode;142;-1476.177,-1142.576;Inherit;False;2;2;0;FLOAT2;0,0;False;1;FLOAT;0;False;1;FLOAT2;0
Node;AmplifyShaderEditor.SaturateNode;97;-136.1102,234.7834;Inherit;True;1;0;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.RangedFloatNode;144;-1826.077,-833.9649;Inherit;False;Property;_NormalScale;NormalScale;11;0;Create;True;0;0;False;0;0;0.1;0;0;0;1;FLOAT;0
Node;AmplifyShaderEditor.RangedFloatNode;8;524.1329,350.419;Inherit;False;Property;_Smoothness1;Smoothness;5;0;Create;False;0;0;True;0;0.5;0.518;0;1;0;1;FLOAT;0
Node;AmplifyShaderEditor.GetLocalVarNode;156;-0.2710571,66.22983;Inherit;False;-1;;1;0;OBJECT;;False;1;FLOAT;0
Node;AmplifyShaderEditor.TriplanarNode;138;-1354.758,-1014.039;Inherit;True;Spherical;World;True;nm;_nm;bump;0;None;Mid Texture 0;_MidTexture0;white;-1;None;Bot Texture 0;_BotTexture0;white;-1;None;NM;False;10;0;SAMPLER2D;;False;5;FLOAT;1;False;1;SAMPLER2D;;False;6;FLOAT;0;False;2;SAMPLER2D;;False;7;FLOAT;0;False;9;FLOAT3;0,0,0;False;8;FLOAT;1;False;3;FLOAT2;1,1;False;4;FLOAT;1;False;5;FLOAT3;0;FLOAT;1;FLOAT;2;FLOAT;3;FLOAT;4
Node;AmplifyShaderEditor.SimpleMultiplyOpNode;186;-115.6866,-1254.131;Inherit;False;2;2;0;COLOR;0,0,0,0;False;1;COLOR;0,0,0,0;False;1;COLOR;0
Node;AmplifyShaderEditor.SaturateNode;194;12.37561,633.0574;Inherit;False;1;0;COLOR;0,0,0,0;False;1;COLOR;0
Node;AmplifyShaderEditor.ColorNode;12;950.3491,-83.52566;Inherit;False;Property;_Emission;Emission;7;1;[HDR];Create;True;0;0;False;0;0,0,0,0;0,0,0,0;True;0;5;COLOR;0;FLOAT;1;FLOAT;2;FLOAT;3;FLOAT;4
Node;AmplifyShaderEditor.SimpleMultiplyOpNode;104;28.25319,149.7286;Inherit;False;2;2;0;FLOAT;0;False;1;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.CustomExpressionNode;7;-192.7874,1062.946;Inherit;False;$clayxelVertFoliage(vertexId , clayxelSize, normalOrient, v.texcoord, v.color.xyz, vertexPosition, vertexNormal)@ $v.vertex.w = 1.0@ // fix shadows in builtin renderer$$v.tangent = float4(normalize(cross(UNITY_MATRIX_V._m20_m21_m22, vertexNormal)),0.5)@$;7;True;5;False;vertexId;INT;0;In;;Inherit;False;False;vertexPosition;FLOAT3;0,0,0;Out;;Inherit;False;False;vertexNormal;FLOAT3;0,0,0;Out;;Inherit;False;False;clayxelSize;FLOAT;0;In;;Inherit;False;False;normalOrient;FLOAT;0;In;;Inherit;False;clayxelComputeVertex;False;False;0;6;0;FLOAT;0;False;1;INT;0;False;2;FLOAT3;0,0,0;False;3;FLOAT3;0,0,0;False;4;FLOAT;0;False;5;FLOAT;0;False;3;FLOAT;0;FLOAT3;3;FLOAT3;4
Node;AmplifyShaderEditor.RegisterLocalVarNode;159;-339.3006,-125.17;Inherit;False;tex;-1;True;1;0;COLOR;0,0,0,0;False;1;COLOR;0
Node;AmplifyShaderEditor.RangedFloatNode;10;529.0828,280.0701;Inherit;False;Property;_Metallic;Metallic;2;0;Create;True;0;0;True;0;0.5;0.692;0;1;0;1;FLOAT;0
Node;AmplifyShaderEditor.StandardSurfaceOutputNode;77;228.7608,249.3745;Half;False;True;-1;2;ASEMaterialInspector;0;0;Standard;Clayxel_Painting;False;False;False;False;False;False;False;True;False;False;False;False;False;False;False;False;False;False;False;False;False;Back;0;False;-1;0;False;-1;False;0;False;-1;0;False;-1;False;4;Custom;0.5;True;True;0;True;Opaque;;AlphaTest;All;14;all;True;True;True;True;0;False;-1;False;0;False;-1;255;False;-1;255;False;-1;0;False;-1;0;False;-1;0;False;-1;0;False;-1;0;False;-1;0;False;-1;0;False;-1;0;False;-1;False;2;15;10;25;False;0.5;True;0;5;False;-1;10;False;-1;0;5;False;-1;10;False;-1;0;False;-1;0;False;-1;0;False;5.8;0,0,0,0;VertexScale;True;False;Cylindrical;False;Relative;0;;1;-1;-1;-1;0;True;0;0;False;-1;-1;0;False;-1;1;Include;Assets/Clayxels/Resources/clayxelSRPUtils.cginc;False;;Custom;0;0;False;0.1;False;-1;0;False;9;16;0;FLOAT3;0,0,0;False;1;FLOAT3;0,0,0;False;2;FLOAT3;0,0,0;False;3;FLOAT;0;False;4;FLOAT;0;False;5;FLOAT;0;False;6;FLOAT3;0,0,0;False;7;FLOAT3;0,0,0;False;8;FLOAT;0;False;9;FLOAT;0;False;10;FLOAT;0;False;13;FLOAT3;0,0,0;False;11;FLOAT3;0,0,0;False;12;FLOAT3;0,0,0;False;14;FLOAT4;0,0,0,0;False;15;FLOAT3;0,0,0;False;0
WireConnection;34;1;35;0
WireConnection;90;0;34;3
WireConnection;90;1;34;4
WireConnection;70;0;90;0
WireConnection;109;1;108;0
WireConnection;69;0;70;0
WireConnection;69;1;70;1
WireConnection;126;1;127;0
WireConnection;31;1;69;0
WireConnection;132;0;109;3
WireConnection;132;1;134;0
WireConnection;133;0;132;0
WireConnection;49;0;31;0
WireConnection;49;1;50;0
WireConnection;145;0;132;0
WireConnection;123;1;126;3
WireConnection;121;1;126;3
WireConnection;102;0;133;0
WireConnection;168;0;166;0
WireConnection;168;1;167;0
WireConnection;169;0;166;0
WireConnection;169;1;167;0
WireConnection;124;0;123;0
WireConnection;95;0;94;0
WireConnection;29;0;4;0
WireConnection;29;2;49;0
WireConnection;122;0;121;0
WireConnection;100;73;205;0
WireConnection;100;13;29;0
WireConnection;100;24;102;0
WireConnection;125;0;122;0
WireConnection;125;1;124;0
WireConnection;171;0;168;0
WireConnection;96;0;95;0
WireConnection;170;0;169;0
WireConnection;165;0;163;0
WireConnection;165;3;170;0
WireConnection;165;4;171;0
WireConnection;188;1;189;1
WireConnection;188;2;189;2
WireConnection;188;3;189;3
WireConnection;120;0;96;0
WireConnection;120;1;118;0
WireConnection;151;0;150;0
WireConnection;128;0;125;0
WireConnection;128;1;100;0
WireConnection;176;0;175;0
WireConnection;162;0;165;0
WireConnection;11;0;3;0
WireConnection;11;1;128;0
WireConnection;174;0;173;0
WireConnection;174;1;176;0
WireConnection;191;0;190;0
WireConnection;191;1;188;0
WireConnection;149;0;140;0
WireConnection;149;1;151;0
WireConnection;98;0;120;0
WireConnection;172;0;6;0
WireConnection;172;1;162;0
WireConnection;172;2;174;0
WireConnection;192;0;191;0
WireConnection;192;1;193;0
WireConnection;103;0;11;1
WireConnection;93;0;1;0
WireConnection;184;1;185;0
WireConnection;142;0;143;0
WireConnection;142;1;149;0
WireConnection;97;0;98;0
WireConnection;138;8;144;0
WireConnection;138;3;142;0
WireConnection;186;0;172;0
WireConnection;186;1;184;0
WireConnection;194;0;192;0
WireConnection;104;0;103;0
WireConnection;104;1;97;0
WireConnection;7;1;5;0
WireConnection;7;4;2;0
WireConnection;7;5;93;0
WireConnection;159;0;11;0
WireConnection;77;0;186;0
WireConnection;77;1;138;0
WireConnection;77;2;194;0
WireConnection;77;3;10;0
WireConnection;77;4;8;0
WireConnection;77;10;104;0
WireConnection;77;11;7;3
WireConnection;77;12;7;4
ASEEND*/
//CHKSM=39DE328321713F7BF2CC4D109BDDB9C298873B81