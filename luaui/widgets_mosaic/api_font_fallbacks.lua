function widget:GetInfo()
	return {
		name      = "Font Fallbacks",
		desc      = "Adds bundled symbol fonts to Recoil's font fallback chain",
		author    = "PicassoCT",
		date      = "September 2026",
		license   = "GNU GPL, v2 or later",
		layer     = -math.huge,
		enabled   = true,
	}
end

local fallbackFonts = {
	"fonts/NotoSansSymbols2-Regular.ttf",
	"fonts/NotoSansMath-Regular.ttf",
}

function widget:Initialize()
	-- Spring 105 has no explicit fallback API and retains its old system-font
	-- substitution. Recoil exposes this function so games can ship a stable,
	-- platform-independent fallback chain.
	if not gl.AddFallbackFont then
		return
	end

	for i = 1, #fallbackFonts do
		local fontFile = fallbackFonts[i]
		if not gl.AddFallbackFont(fontFile) then
			Spring.Echo("[Font Fallbacks] Failed to register " .. fontFile)
		end
	end
end
