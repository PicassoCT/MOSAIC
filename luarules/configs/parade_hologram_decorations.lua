-- Small, code-authored pixel ornaments; '.' is transparent.
-- Frames are written top-to-bottom and rendered from a bottom-center anchor.
-- At the sizes below, a motif is 2.6--5.5 world units tall, compared with the
-- floats' 40--52 unit heights and 17.6 x 45.6 unit mounting skids.
--
-- Anchors sit outside each float's measured X bounds, including the Moonwhale's
-- fins and Night Post's wings, with at least 0.8 units beyond half the sprite
-- width in side views. Screen-facing sprites can overlap the silhouette at
-- oblique angles; the renderer depth-tests that natural occlusion.
-- Positions are relative to the payload's moved center piece: do not apply
-- carrierOffsets again. See tools/truck_parade_payloads/manifest.json.
return {
    glyphs = {
        candle = {
            frameSeconds = 0.18,
            palette = {
                F = {1.00, 0.44, 0.08, 0.96},
                H = {1.00, 0.91, 0.43, 1.00},
                W = {0.72, 0.94, 1.00, 0.83},
                S = {0.24, 0.61, 0.80, 0.62},
                B = {0.25, 0.78, 0.92, 0.68},
            },
            frames = {
                {"...F...", "..FHF..", "..FHF..", "...H...", "..WWW..",
                 "..WWS..", "..WWS..", "..WWS..", "..WWS..", "..WWW..", ".BBBBB."},
                {"....F..", "...HF..", "..FHF..", "...H...", "..WWW..",
                 "..WWS..", "..WWS..", "..WWS..", "..WWS..", "..WWW..", ".BBBBB."},
                {"..F....", "..FH...", "..FHF..", "...H...", "..WWW..",
                 "..WWS..", "..WWS..", "..WWS..", "..WWS..", "..WWW..", ".BBBBB."},
            },
        },
        leaf = {
            frameSeconds = 0.65,
            palette = {
                L = {0.44, 1.00, 0.50, 0.86},
                V = {0.84, 1.00, 0.57, 0.96},
                S = {0.14, 0.64, 0.52, 0.65},
            },
            frames = {
                {"......LL", "....LLLL", "...LLVLS", "..LLVLS.",
                 ".LLVLS..", ".LVLS...", "..VS....", ".V......"},
                {".....LL.", "...LLLLL", "..LLVLLS", ".LLVLLS.",
                 ".LVLLS..", "..VLS...", "..VS....", ".V......"},
            },
        },
        star = {
            frameSeconds = 0.48,
            palette = {
                S = {0.43, 0.79, 1.00, 0.76},
                H = {0.86, 0.97, 1.00, 0.98},
            },
            frames = {
                {"...S...", "...H...", "..SHS..", "SHHHHHS",
                 "..SHS..", "...H...", "...S..."},
                {".......", "...S...", "...H...", ".SHHHS.",
                 "...H...", "...S...", "......."},
            },
        },
        lantern = {
            frameSeconds = 0.42,
            palette = {
                R = {1.00, 0.27, 0.17, 0.80},
                G = {1.00, 0.73, 0.27, 0.94},
                H = {1.00, 0.95, 0.66, 0.98},
                T = {0.26, 0.83, 0.86, 0.73},
            },
            frames = {
                {"...T...", "..TTT..", ".RGGGR.", "RGGHGGR", "RGGHGGR",
                 "RGGHGGR", ".RGGGR.", "..TTT..", "...G...", "..G.G.."},
                {"...T...", "..TTT..", ".RGGGR.", "RGGGGGR", "RGGHGGR",
                 "RGGGGGR", ".RGGGR.", "..TTT..", "...G...", "...G.G."},
            },
        },
        crescent = {
            frameSeconds = 1.0,
            palette = {
                M = {0.30, 0.67, 1.00, 0.79},
                H = {0.72, 0.94, 1.00, 0.97},
            },
            frames = {
                {"...MMM...", "..MHH....", ".MHH.....", "MHH......", "MHH......",
                 "MHH......", ".MHH.....", "..MHH..M.", "...MMMM.."},
            },
        },
        koi = {
            frameSeconds = 0.30,
            palette = {
                W = {0.88, 0.97, 1.00, 0.92},
                R = {1.00, 0.36, 0.16, 0.94},
                F = {1.00, 0.72, 0.34, 0.80},
                E = {0.20, 0.66, 0.83, 0.83},
            },
            frames = {
                {"....F......", "..WWRWF..F.", ".WWRRWW.FF.", "WWERWWWWFFF",
                 ".WWRRWW.FF.", "..WWRWF..F.", "....F......"},
                {".....F.....", "..WWRWF....", ".WWRRWW..FF", "WWERWWWWFFF",
                 ".WWRRWW..FF", "..WWRWF....", ".....F....."},
            },
        },
        lotus = {
            frameSeconds = 0.72,
            palette = {
                P = {1.00, 0.43, 0.76, 0.84},
                H = {1.00, 0.84, 0.94, 0.98},
                L = {0.21, 0.93, 0.69, 0.77},
                W = {0.26, 0.70, 1.00, 0.57},
            },
            frames = {
                {".....H.....", "..P.PHP.P..", "..PPPHPPP..", ".PPPPHPPPP.",
                 "..PPHHHPP..", "...LLLLL...", ".WWWWWWWWW.", "...WWWWW..."},
                {".....P.....", "..P.PHP.P..", "..PPPHPPP..", ".PPPPHPPPP.",
                 "..PPHHHPP..", "...LLLLL...", "...WWWWW...", ".WWWWWWWWW."},
            },
        },
        cloud = {
            frameSeconds = 0.90,
            palette = {
                W = {0.65, 0.88, 1.00, 0.82},
                H = {0.91, 0.98, 1.00, 0.94},
                S = {0.32, 0.58, 0.90, 0.60},
            },
            frames = {
                {"....WWW....", "...WHHHW...", ".WWWHHHWWW.", "WHHHHHHHHHW",
                 "WHHHHHHHHHW", ".SSSSSSSSS."},
                {"....WWW....", "...WHHHW...", ".WWWHHHWWW.", "WHHHHHHHHHW",
                 "WHHHHHHHHHW", ".WSSSSSSSW."},
            },
        },
        pinwheel = {
            frameSeconds = 0.24,
            palette = {
                A = {0.31, 0.86, 1.00, 0.91},
                B = {1.00, 0.61, 0.86, 0.91},
                H = {1.00, 0.96, 0.64, 1.00},
                S = {0.44, 0.72, 0.92, 0.70},
            },
            frames = {
                {"..AA.....", "..AAA..B.", "...AA.BB.", ".B..ABBB.", "BBB.H.AAA",
                 ".BBBAA...", ".BB.AA...", ".B..AAA..", "....S...."},
                {"....A....", "...AAA...", "...AA....", ".BBBB.AA.", "BBBBHAAAA",
                 ".BB.BBBB.", "....BB...", "...BBB...", "....S...."},
            },
        },
        envelope = {
            frameSeconds = 0.60,
            palette = {
                E = {0.31, 0.84, 1.00, 0.83},
                P = {0.79, 0.96, 1.00, 0.91},
                H = {1.00, 0.74, 0.91, 0.98},
            },
            frames = {
                {".........", ".EEEEEEE.", "EEPPPPPEE", "EPEPPPEPE", "EPPEHEPPE",
                 "EPPPEPPPE", ".EEEEEEE."},
                {"....H....", "...EPE...", "..EPPPE..", ".EEEEEEE.", "EEPPPPPEE",
                 "EPPPHPPPE", ".EEEEEEE."},
            },
        },
        moth = {
            frameSeconds = 0.28,
            palette = {
                W = {0.72, 0.67, 1.00, 0.83},
                E = {1.00, 0.69, 0.91, 0.90},
                H = {1.00, 0.95, 0.64, 0.98},
            },
            frames = {
                {"..H...H..", "...H.H...", "WW..H..WW", "WEW.H.WEW", "WWEWHWEWW",
                 ".WWWHWWW.", "..WEHEW..", "...WHW...", "....H...."},
                {"..H...H..", "...H.H...", "..W.H.W..", ".WEWHWEW.", "..WEHEW..",
                 "..WWHWW..", "...WHW...", "....H....", "....H...."},
            },
        },
    },
    themes = {
        forest_dreamer = {
            {glyph = "candle", x = -13.0, y = 6.2, z = 14.0, pixelSize = 0.50, phase = 0.00},
            {glyph = "candle", x =  13.0, y = 6.2, z = 14.0, pixelSize = 0.50, phase = 0.27},
            {glyph = "leaf",   x = -13.0, y = 8.6, z = -13.0, pixelSize = 0.50, phase = 0.63},
            {glyph = "leaf",   x =  13.0, y = 8.6, z = -13.0, pixelSize = 0.50, phase = 0.98},
            {glyph = "star",   x = -13.0, y = 12.6, z = 0.0, pixelSize = 0.48, phase = 0.41},
            {glyph = "star",   x =  13.0, y = 12.6, z = 0.0, pixelSize = 0.48, phase = 1.19},
        },
        wandering_bathhouse = {
            {glyph = "candle",  x = -12.5, y = 6.0, z = -14.0, pixelSize = 0.50, phase = 0.13},
            {glyph = "candle",  x =  12.5, y = 6.0, z = -14.0, pixelSize = 0.50, phase = 0.54},
            {glyph = "lantern", x = -12.5, y = 7.0, z = 12.0, pixelSize = 0.50, phase = 0.20},
            {glyph = "lantern", x =  12.5, y = 7.0, z = 12.0, pixelSize = 0.50, phase = 0.71},
            {glyph = "lantern", x = -12.5, y = 10.5, z = 0.0, pixelSize = 0.46, phase = 1.10},
            {glyph = "lantern", x =  12.5, y = 10.5, z = 0.0, pixelSize = 0.46, phase = 1.46},
        },
        moonwhale = {
            {glyph = "crescent", x = -20.0, y = 9.5, z = 11.0, pixelSize = 0.55, phase = 0.00},
            {glyph = "crescent", x =  20.0, y = 9.5, z = 11.0, pixelSize = 0.55, phase = 0.84},
            {glyph = "star",     x = -20.0, y = 8.0, z = -13.0, pixelSize = 0.55, phase = 0.26},
            {glyph = "star",     x =  20.0, y = 8.0, z = -13.0, pixelSize = 0.55, phase = 0.78},
            {glyph = "star",     x = -20.0, y = 6.0, z = 0.0, pixelSize = 0.45, phase = 1.12},
            {glyph = "star",     x =  20.0, y = 6.0, z = 0.0, pixelSize = 0.45, phase = 1.63},
        },
        lantern_koi = {
            {glyph = "koi",     x = -18.5, y = 8.5, z = 12.0, pixelSize = 0.45, phase = 0.12},
            {glyph = "koi",     x =  18.5, y = 8.5, z = 12.0, pixelSize = 0.45, phase = 0.61},
            {glyph = "lotus",   x = -18.5, y = 6.0, z = -12.0, pixelSize = 0.45, phase = 0.39},
            {glyph = "lotus",   x =  18.5, y = 6.0, z = -12.0, pixelSize = 0.45, phase = 1.11},
            {glyph = "lantern", x = -18.5, y = 11.0, z = 0.0, pixelSize = 0.46, phase = 0.82},
            {glyph = "lantern", x =  18.5, y = 11.0, z = 0.0, pixelSize = 0.46, phase = 1.43},
        },
        cloud_mill = {
            {glyph = "cloud",    x = -14.5, y = 7.5, z = -12.0, pixelSize = 0.50, phase = 0.11},
            {glyph = "cloud",    x =  14.5, y = 7.5, z = -12.0, pixelSize = 0.50, phase = 0.67},
            {glyph = "pinwheel", x = -14.5, y = 8.4, z = 12.0, pixelSize = 0.50, phase = 0.35},
            {glyph = "pinwheel", x =  14.5, y = 8.4, z = 12.0, pixelSize = 0.50, phase = 0.94},
            {glyph = "cloud",    x = -14.5, y = 12.2, z = 0.0, pixelSize = 0.44, phase = 1.20},
            {glyph = "cloud",    x =  14.5, y = 12.2, z = 0.0, pixelSize = 0.44, phase = 1.66},
        },
        night_post = {
            {glyph = "candle",   x = -23.0, y = 6.0, z = -14.0, pixelSize = 0.50, phase = 0.09},
            {glyph = "candle",   x =  23.0, y = 6.0, z = -14.0, pixelSize = 0.50, phase = 0.37},
            {glyph = "envelope", x = -23.0, y = 8.8, z = 13.0, pixelSize = 0.55, phase = 0.54},
            {glyph = "envelope", x =  23.0, y = 8.8, z = 13.0, pixelSize = 0.55, phase = 1.13},
            {glyph = "moth",     x = -23.0, y = 12.5, z = 0.0, pixelSize = 0.50, phase = 0.83},
            {glyph = "moth",     x =  23.0, y = 12.5, z = 0.0, pixelSize = 0.50, phase = 1.54},
        },
    },
}
