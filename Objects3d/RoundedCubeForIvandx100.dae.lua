model = {
	--radius = 25.0,
	--height = 40,
	--tex1 = "Jeffy_Diffuse+TeamColor.dds",
	tex1 = "bricks2.png",
	--tex2 = "armtech_tex2.dds",
	--tex2 = "armtech_tex2.dds",
	midpos = {0, 0, 0},
	--rotAxisSigns = {-1, -1, -1}
	pbr = {
		flipUV = false, --flip second component of UV map. False is for DDS, True is for everything else. For now keep everything either in DDS or in PNG/TGA
		fastGamma = true, --default is false i.e. more precise method
		tbnReortho = true, -- Re-orthogonalize TBN matrix using Gram-Schmidt process. Might behave differently depending on "hasTangents". Default is true.
		pbrWorkflow = "metallic", -- either "metallic" or "specular". "specular" is not yet implemented
		-- PBR shader will sample a certain number of supplied textures.
		-- provide a recipe to map samples to PBR inputs
		baseColorMap = {
			scale = {1.0, 1.0, 1.0, 0.0}, -- acts as a color if tex unit is unused or as a multiplier if tex unit is present. Defaults to vec4(1.0).
			get = "[0].rgba", -- take sample from first texture unit in array.
			gammaCorrection = true, -- do sRGB to RGB in-shader translation. Defaults to true.
		},
		normalMap = {
			hasTangents = true, --you somehow must know if the import of the model puts tangents and bitangents to gl_MultiTexCoord[5,6]
			scale = {1.0, 1.0, 1.0}, -- scale for Red/X/tangent and Green/Y/bitangent parts of normal sampled from normalMapTex. Defaults to 1.0
			get = "[1].rgb", --If you use DDS and see some weird moar/acne like artifacts, use uncompressed DDS instead.
			gammaCorrection = false, -- do sRGB to RGB in-shader translation. Defaults to false, because normals are stored linearly.
		},
		parallaxMap = { -- parallax occlusion mapping. Will be ignored if normalMap.hasTangents == false
			invert = true, -- invert height value, i.e. height = (1.0 - height). Algorithm expects depth map: 0.0 to be baseline, and 1.0 to be deep (not high!!!). Default is false.
			fast = false, --always test if fast is good enough and only switch to "precise" if quality is bad. fast=true is simple parallax, fast=false is parallax occlusion mapping
			perspective = true, --whether to divide tangentViewDir.xy by tangentViewDir.z or not. A matter of personal preference. Check both.
			limits = true, -- Can be boolean or vec2() table. This limits how large texture coordinates offsets parallax mapping can do. Offsets bigget than limits will be clamped.
			scale = 0.1, --if you set this up and your model texturing (and everything else) looks off, try to divide scale by 10 and then find out the best value iteratively
			get = "[1].a", -- expects linear bump map as input
			--get = nil,
			gammaCorrection = false, -- don't do. A is always linear
		},
		emissiveMap = {
			--scale = {1.0, 1.0, 1.0}, -- acts as a color if tex unit is unused or as a multiplier if tex unit is present. Can be a single channel, in that case it acts as a multipier to baseColor Defaults to vec3(1.0).
			scale = 1.0,
			--get = "[2].rgb", --get can be RGB
			--get = "[3].a", --or get can be single channel. I
			--gammaCorrection = true, -- do sRGB to RGB in-shader translation. Defaults to true.
			gammaCorrection = false,-- don't do. A is always linear
		},
		occlusionMap = {
			strength = 1.0, --multiplier in case occlusionMap is present. Does NOT act as a texture stand-in
			--get = "[3].r",
			gammaCorrection = false, -- do sRGB to RGB in-shader translation. Defaults to false, as ao should be saved in linear RGB.
		},
		roughnessMap = {
			scale = 1.0, --acts as a multiplier or a base value (if get is nil)
			--get = "[3].g",
			gammaCorrection = false, -- do sRGB to RGB in-shader translation. Defaults to false, as roughness should be saved in linear RGB.
		},
		metallicMap = {
			scale = 0.0, --acts as a multiplier or a base value (if get is nil)
			--get = "[3].b",
			gammaCorrection = false, -- do sRGB to RGB in-shader translation. Defaults to false, as roughness should be saved in linear RGB.
		},
		iblMap = {
			scale = {0.7, 0.7}, --{diffuse, specular} IBL scale. Acts as a multiplier or a base value (if get is nil)
			--get = true, -- to generate GET_IBLMAP definition
			lod = true, -- can be nil, a number, or true for auto
			gammaCorrection = true, -- do sRGB to RGB in-shader translation. Defaults to false, as roughness should be saved in linear RGB.
		},
		exposure = 1.0,
		--toneMapping = "aces", --valid values are "aces", "uncharted2", "filmic".
		gammaCorrection = true, -- do gamma correction (RGB-->sRGB) on the final color.
		texUnits = { -- substitute values
			--["TEX0"] = "bricks2.png",
			["TEX0"] = "rocks_color_bc3_unorm.dds",
			["TEX1"] = "rocks_normal_height_rgba.dds",
			--["TEX1"] = "bricks2_normal_bump.png",
			--["TEX2"] = "Jeffy_Emissive512x512.dds",
			--["TEX3"] = "Jeffy_ORM_EMGS_1k.dds",
		}
	},
}
return model