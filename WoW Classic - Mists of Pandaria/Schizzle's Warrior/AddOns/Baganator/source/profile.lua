-- Schizzle's Warrior Baganator profile (Jon Shaw / Schizzle), MIT with attribution.
-- Plain Lua table; build.lua turns it into Baganator's JSON profile import.
-- Only settings that differ from Baganator's defaults are listed; Baganator
-- fills in every other setting with its default when the profile loads.
return {
  -- Baganator's profile import header (CustomiseDialog/Main.lua import button)
  addon = "Baganator",
  version = 3,
  kind = "profile",

  -- Look: the Dark skin, nearly solid, square icons (reload needed for those)
  current_skin = "dark",
  skins = {
    dark = {
      view_transparency = 0.15,
      no_frame_borders = false,
      empty_slot_background = false,
      square_icons = true,
    },
  },

  -- One bag, compact: 10 columns of 32 px icons with tight spacing
  bag_view_type = "single",
  bank_view_type = "single",
  seen_welcome = 1,
  bag_view_width = 10,
  bank_view_width = 16,
  bag_icon_size = 32,
  reduce_spacing = true,
  icon_text_font_size = 12,

  -- Icons: item levels in quality colours, junk greyed, unusable gear marked red
  icon_text_quality_colors = true,
  icon_grey_junk = true,
  icon_mark_unusable = true,

  -- Where: bags open over the Details! corner (24 px from the right, 190 px up,
  -- clear of the action bars); the bank opens bottom left at the same height.
  bag_view_position = {"BOTTOMRIGHT", -24, 190},
  bank_view_position = {"BOTTOMLEFT", 30, 190},
}
