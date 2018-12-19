model = {
	--radius = 25.0,
	--height = 40,
	--tex1 = "Jeffy_Diffuse+TeamColor.dds",
	tex1 = "for_texture_devil_dog_low_poly_1_default_B_1k.png",
	--tex2 = "armtech_tex2.dds",
	--tex2 = "armtech_tex2.dds",
	midpos = {0, 0, 0},
	--rotAxisSigns = {-1, -1, -1}
	pbr = {
		flipUV = true, --flip second component of UV map. False is for DDS, True is for everything else. For now keep everything either in DDS or in PNG/TGA
		fastGamma = true, --default is false i.e. more precise method
		fastDiffuse = true, --Lambert(true) or Burley(false)
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
			gammaCorrection = false, -- do sRGB to RGB in-shader translation. Defaults to true, because normals are stored just as a regular image. If you don't see right reflections, try to flip this value
		},
		parallaxMap = { -- parallax occlusion mapping. Will be ignored if normalMap.hasTangents == false
			fast = false, --always test if fast is good enough and only switch to "precise" if quality is bad. fast=true is simple parallax, fast=false is parallax occlusion mapping
			perspective = false, --whether to divide tangentViewDir.xy by tangentViewDir.z or not. A matter of personal preference. Check both.
			limits = true, -- Can be boolean or vec2() table. This limits how large texture coordinates offsets parallax mapping can do. Offsets bigget than limits will be clamped.
			scale = 0.02, --if you set this up and your model texturing (and everything else) looks off, try to divide scale by 10 and then find out the best value iteratively
			--get = "[1].a", -- expects linear bump map as input
			--get = nil,
			gammaCorrection = false, -- don't do. A is always linear
		},
		emissiveMap = {
			--scale = {1.0, 1.0, 1.0}, -- acts as a color if tex unit is unused or as a multiplier if tex unit is present. Can be a single channel, in that case it acts as a multipier to baseColor Defaults to vec3(1.0).
			--scale = 2.5,
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
			get = "[2].g",
			gammaCorrection = false, -- do sRGB to RGB in-shader translation. Defaults to false, as roughness should be saved in linear RGB.
		},
		metallicMap = {
			scale = 1.0, --acts as a multiplier or a base value (if get is nil)
			get = "[2].r",
			gammaCorrection = false, -- do sRGB to RGB in-shader translation. Defaults to false, as roughness should be saved in linear RGB.
		},
		iblMap = {
			scale = {1.0, 1.0}, --{diffuse, specular} IBL scale. Acts as a multiplier or a base value (if get is nil)
			get = true, -- to generate GET_IBLMAP definition
			lod = true, -- can be nil, a number, or true for auto
			invToneMapExp = 1.3,
			gammaCorrection = false, -- do sRGB to RGB in-shader translation. Defaults to false, as roughness should be saved in linear RGB.
		},
		exposure = 1.0,
		--toneMapping = "aces", --valid values are "aces", "uncharted2", "filmic".
		gammaCorrection = true, -- do gamma correction (RGB-->sRGB) on the final color.
		texUnits = { -- substitute values
			["TEX0"] = "for_texture_devil_dog_low_poly_1_default_B_1k.png",
			["TEX1"] = "for_texture_devil_dog_low_poly_1_default_N_1k.png",
			["TEX2"] = "for_texture_devil_dog_low_poly_1_default_MR_1k.png",
			--["TEX3"] = "for_texture_devil_dog_low_poly_1_default_R.png",
		}
	},
}
return model