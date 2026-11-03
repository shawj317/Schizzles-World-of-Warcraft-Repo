-- Builds the three Schizzle's Warrior Details! profiles (Arms, Fury, Protection).
-- Usage (from this folder):  lua build.lua      env: DETAILS_SRC, WA_TYPES (see common.lua), DETAILS_FONT, OUT_DIR
-- Two locked 250x153 Minimalistic windows side by side in the bottom-right corner, 4 px from the right edge
-- (window 2 in the corner, window 1 directly to its left), sitting right on top of the 500x22 WeakAuras
-- XP & Rep Tray (4 px up, so the windows' bottom edge is 26 px up). Fira Sans Condensed Medium, bar text 9, title 11, tooltip 11.
local HERE = (arg and arg[0] or ""):match("^(.*[/\\])") or "./"
dofile(HERE .. "common.lua")
local R = dofile(HERE .. "defaults.lua")
local OUT_DIR = os.getenv("OUT_DIR") or (HERE .. "../")

local FONT = os.getenv("DETAILS_FONT") or "Fira Sans Condensed Medium"
local BAR_SIZE, TITLE_SIZE, TOOLTIP_SIZE = 9, 11, 11
-- file path is only a cache seed; Details re-resolves the file from the LibSharedMedia name on every refresh
local KNOWN_FILES = {
  ["Fira Sans Condensed Medium"] = "Interface\\Addons\\WeakAuras\\Media\\Fonts\\FiraSansCondensed-Medium.ttf",
  ["Fira Sans Medium"] = "Interface\\Addons\\WeakAuras\\Media\\Fonts\\FiraSans-Medium.ttf",
  ["Friz Quadrata TT"] = "Fonts\\FRIZQT__.TTF",
}
local FONT_FILE = KNOWN_FILES[FONT] or "Fonts\\FRIZQT__.TTF"
local FLAT, FLAT_FILE = "Details Flat", "Interface\\AddOns\\Details\\images\\bar_background"
-- 153 = the old 175 minus the XP & Rep Tray's height (22), so the title bars still top out 199 px up
local W, H = 250, 153
local SPEC_ALPHA = "Interface\\AddOns\\Details\\images\\spec_icons_normal_alpha" -- the "Specialization Alpha" entry (functions/util.lua)
local TITLE_BAR = 20 -- Details' title bar sits above the bar area (class_instance_snap.lua TITLE_BAR_HEIGHT)

local function themedWindow()
  local w = deepcopy(R.instance)
  merge(w, R.skins.Minimalistic.instance_cprops)
  merge(w, {
    skin = "Minimalistic",
    color = {0.06, 0.06, 0.07, 0.95},
    -- v1.6: Designer > Window: Background Texture "Blizzard Out of Control" (a LibSharedMedia background name),
    -- Row Area Opacity 0.25 (bg_alpha)
    bg_r = 0.05, bg_g = 0.05, bg_b = 0.06, bg_alpha = 0.25,
    backdrop_texture = "Blizzard Out of Control",
    -- v1.6: Designer > Title Bar: Texture "Details! Slash" (statusbar name). The texture only draws while the custom
    -- title bar is on, so titlebar_shown is on too, at 20 px (the height of the existing title bar strip)
    titlebar_shown = true, titlebar_height = 20, titlebar_texture = "Details! Slash",
    -- v1.6: Designer > Title Bar: Auto Hide Buttons (Details only reads .left; .right is deprecated)
    auto_hide_menu = {left = true, right = false},
    show_statusbar = false, show_sidebars = false,
    desaturated_menu = true, menu_icons_alpha = 0.9, menu_icons_size = 0.82,
    attribute_text = {
      enabled = true, text_face = FONT, text_size = TITLE_SIZE, shadow = true,
      text_color = {0.92, 0.92, 0.92, 1}, side = 1,
      show_timer = true, show_timer_always = true, show_timer_bg = true,
    },
    rowareaborder_shown = true, rowareaborder_color = {0, 0, 0, 1}, rowareaborder_size = 1,
    fullborder_shown = false,
    row_info = {
      height = 18,
      font_face = FONT, font_face_file = FONT_FILE, font_size = BAR_SIZE,
      texture = FLAT, texture_file = FLAT_FILE,
      texture_class_colors = true, alpha = 1,
      texture_background = FLAT, texture_background_file = FLAT_FILE,
      texture_background_class_color = false,
      fixed_texture_background_color = {0.11, 0.11, 0.12, 0.55},
      fixed_text_color = {1, 1, 1},
      textL_outline = false, textR_outline = false,
      textL_outline_small = true, textR_outline_small = true,
      textL_show_number = true,
      textR_show_data = {true, true, true},      -- total, per second, percent
      textR_bracket = "NONE", textR_separator = "NONE",
      space = {left = 0, right = 0, between = 1},
      -- v1.6: Designer > Bars > Icons: Texture "Specialization Alpha" and Show Arena Role Icon
      use_spec_icons = true, spec_file = SPEC_ALPHA,
      show_arena_role_icon = true,
      -- v1.6: Bars: General > Fast Updates (row_info.fast_ps_update)
      fast_ps_update = true,
      backdrop = {enabled = false},
      start_after_icon = true,
      percent_type = 1,
      texts = {
        -- v1.6: Designer > Bars > Unit Name: Outline "Slug" (Details' outline value "SLUG", Libs/DF/fw.lua FontOutlineFlags)
        [1] = {font = {outline = "SLUG"}, shadow = {color = {0, 0, 0, 1}, offset = {1, -1}}},
        [2] = {font = {outline = ""}, shadow = {color = {0, 0, 0, 1}, offset = {1, -1}}},
        [3] = {font = {outline = ""}, shadow = {color = {0, 0, 0, 1}, offset = {1, -1}}},
        [4] = {font = {outline = ""}, shadow = {color = {0, 0, 0, 1}, offset = {1, -1}},
               color = {byClass = false, fixed = {0.75, 0.75, 0.75, 1}}},
      },
    },
    wallpaper = {enabled = false},
    use_multi_fontstrings = true, use_auto_align_multi_fontstrings = true,
    strata = "LOW", window_scale = 1,
  })
  return w
end

-- both windows on one row in the bottom-right corner: window 2 in the corner, window 1 touching its left edge.
-- The XP & Rep Tray (WeakAuras, 500x22) fills the 4..26 px strip under them, so they start on its top edge.
local TRAY_BOTTOM, TRAY_HEIGHT = 4, 22
local RIGHT_MARGIN, BOTTOM_MARGIN = -4, TRAY_BOTTOM + TRAY_HEIGHT
local function placeWindow(w, id, atributo, sub)
  local xRight = RIGHT_MARGIN - (id == 1 and W or 0)
  local yBottom = BOTTOM_MARGIN
  w.libwindow = {point = "BOTTOMRIGHT", x = xRight, y = yBottom, scale = 1}
  local uiW, uiH = 1365, 768 -- fallback CENTER offsets in case libwindow is ignored
  local cx, cy = uiW / 2 + xRight - W / 2, yBottom + H / 2 - uiH / 2
  local pos = {normal = {x = cx, y = cy, w = W, h = H}, solo = {x = cx, y = cy, w = W, h = H}}
  w.posicao, w.__pos = deepcopy(pos), deepcopy(pos)
  w.__was_opened = true
  w.__locked = true -- locked: no dragging, no resize grips (Details:LockInstance)
  w.__snapH, w.__snapV = true, false
  w.__snap = (id == 1) and {[3] = 2} or {[1] = 1} -- 3 = window to my right, 1 = window to my left
  w.atributo, w.sub_atributo = atributo, sub
  -- last sub-display remembered per attribute (damage, heal, energy, misc, custom)
  w.sub_atributo_last = {1, 1, 1, 1, 1}
  w.sub_atributo_last[atributo] = sub
  w.segmento, w.modo, w.mostrando = 0, 2, "normal"
  w.version = 3
  return w
end

local function buildProfile(spec)
  local profile = {}
  local tooltip = deepcopy(R.profile.tooltip)
  tooltip.fontface, tooltip.fontsize, tooltip.fontsize_title = FONT, TOOLTIP_SIZE, TOOLTIP_SIZE
  tooltip.background = {0.05, 0.05, 0.06, 0.92}
  tooltip.bar_color = {0.22, 0.22, 0.24, 0.85}
  tooltip.divisor_color = {1, 1, 1, 1}
  profile.tooltip = tooltip
  profile.font_faces = merge(deepcopy(R.profile.font_faces), {menus = FONT})
  profile.skin = "Minimalistic"
  profile.profile_save_pos = true
  profile.disable_window_groups = false
  profile.grouping_horizontal_gap = 0
  profile.ps_abbreviation = 3
  profile.total_abbreviation = 2
  profile.time_type = 2
  -- v1.6: Display > Update Interval 0.05 (the slider's minimum), Clear On Logoff, Combat Log > Advanced Damage Taken
  profile.update_speed = 0.05
  profile.overall_clear_logout = true
  profile.damage_taken_everything = true
  profile.use_row_animations = true
  profile.disable_stretch_from_toolbar = true -- a locked window doesn't stretch when its title bar is dragged
  profile.instances = {
    placeWindow(themedWindow(), 1, 1, 1),                 -- Damage Done
    placeWindow(themedWindow(), 2, spec.w2[1], spec.w2[2]),
  }
  -- account-wide (global) Details setting, carried in the export's globaData: Combat Log > Parser Options >
  -- Record Tank Avoidance. Since v1.6 all three profiles turn it on.
  local globaData = {}
  local parser = deepcopy(R.global.parser_options)
  parser.tank_avoidance = true
  globaData.parser_options = parser
  -- per-character Details setting, carried in the export's playerData: Combat Log > Auto Start Combatlog.
  -- ImportProfile copies it onto the character doing the import only.
  local playerData = {auto_combatlog = true}
  return {profile = profile, playerData = playerData, globaData = globaData, version = 1}
end

for _, spec in ipairs(SPECS) do
  local str = encode(buildProfile(spec))
  writefile(OUT_DIR .. spec.file, str .. "\n")
  print(string.format("%-24s %-32s %6d chars", spec.file, spec.name, #str))
end
