-- Schizzle's Warrior Plater profiles: sparse overrides on top of Plater defaults.
-- Shared look for Arms, Fury and Protection; per-spec debuffs are picked from PER_SPEC below.
local spec = ...   -- "arms" | "fury" | "prot"
local FONT = "Fira Sans Condensed Medium"   -- registered by WeakAuras (LibSharedMedia)
local TEX  = "You Are Beautiful!"   -- Plater's flat white texture (images/regular_white)

local function textBlock(t)
  -- shared font/layout settings for hostile plates
  t.actorname_text_font = FONT
  t.actorname_text_size = 10
  t.actorname_text_outline = "OUTLINE"
  t.actorname_text_anchor = {side = 10, x = 3, y = 0}      -- inside left
  t.actorname_text_max_width = 86
  t.actorname_text_shadow_color = {0, 0, 0, 0}
  t.percent_text_enabled = true
  t.percent_text_ooc = true
  t.percent_show_percent = true
  t.percent_show_health = false
  t.percent_text_show_decimals = false
  t.percent_text_font = FONT
  t.percent_text_size = 10
  t.percent_text_outline = "OUTLINE"
  t.percent_text_color = {1, 1, 1, 1}
  t.percent_text_anchor = {side = 11, x = -3, y = 0}       -- inside right
  t.percent_text_shadow_color = {0, 0, 0, 0}
  t.spellname_text_font = FONT
  t.spellname_text_size = 10
  t.spellname_text_outline = "OUTLINE"
  t.spellname_text_anchor = {side = 10, x = 3, y = 0}
  t.spellname_text_max_width = 96
  t.spellname_text_shadow_color = {0, 0, 0, 0}
  t.spellpercent_text_font = FONT
  t.spellpercent_text_size = 10
  t.spellpercent_text_outline = "OUTLINE"
  t.spellpercent_text_anchor = {side = 11, x = -3, y = 0}
  t.level_text_enabled = false
  t.health = {120, 14}
  t.health_incombat = {136, 18}
  t.cast = {120, 12}
  t.cast_incombat = {136, 16}
  t.big_actorname_text_font = FONT
  t.big_actortitle_text_font = FONT
  return t
end

local enemynpc = textBlock({
  quest_enabled = true,
  quest_color_enabled = true,
  quest_color_enemy = {1, 0.45, 0.05, 1},
  quest_color_neutral = {1, 0.70, 0.15, 1},
})
local enemyplayer = textBlock({
  use_playerclass_color = true,
})
enemyplayer.cast_incombat = {136, 16}

-- Warrior debuffs to show on enemy plates (by spell ID; any source, so raid debuffs from
-- other classes count too). Rend is not listed: it was removed from Warriors in Mists.
local COMMON = {
  [115767] = false, -- Deep Wounds
  [113746] = false, -- Weakened Armor (Sunder Armor / Devastate)
  [115798] = false, -- Weakened Blows (Thunder Clap)
  [1715]   = false, -- Hamstring
  [12323]  = false, -- Piercing Howl
  [107566] = false, -- Staggering Shout (root)
  [132168] = false, -- Shockwave (stun)
  [132169] = false, -- Storm Bolt (stun)
  [7922]   = false, -- Charge Stun
  [5246]   = false, -- Intimidating Shout
  [676]    = false, -- Disarm
}
local PER_SPEC = {
  arms = {
    [86346]  = false, -- Colossus Smash
    [115804] = false, -- Mortal Wounds (Mortal Strike)
  },
  fury = {
    [86346]  = false, -- Colossus Smash
  },
  prot = {
    [1160]   = false, -- Demoralizing Shout
    [355]    = false, -- Taunt
  },
}
assert(PER_SPEC[spec], "unknown spec " .. tostring(spec))
local DEBUFFS = {}
for id, v in pairs(COMMON) do DEBUFFS[id] = v end
for id, v in pairs(PER_SPEC[spec]) do DEBUFFS[id] = v end

return {
  plate_config = {
    enemynpc = enemynpc,
    enemyplayer = enemyplayer,
    friendlyplayer = {
      actorname_text_font = FONT,
      percent_text_font = FONT,
      spellname_text_font = FONT,
      spellpercent_text_font = FONT,
      level_text_font = FONT,
    },
    friendlynpc = {
      actorname_text_font = FONT,
      percent_text_font = FONT,
      spellname_text_font = FONT,
      spellpercent_text_font = FONT,
      level_text_font = FONT,
      big_actorname_text_font = FONT,
      big_actortitle_text_font = FONT,
    },
  },

  -- bars: flat, dark background, crisp black border
  health_statusbar_texture = TEX,
  health_statusbar_bgtexture = TEX,
  health_statusbar_bgcolor = {0.05, 0.05, 0.06, 0.92},
  health_selection_overlay = TEX,
  health_selection_overlay_alpha = 0.12,
  border_color = {0, 0, 0, 1},
  border_thickness = 1,

  -- reaction colours (out of combat / not threat-coloured)
  color_override = true,
  color_override_colors = {
    [3] = {0.78, 0.16, 0.13, 1},   -- hostile
    [4] = {0.93, 0.76, 0.25, 1},   -- neutral
    [5] = {0.22, 0.75, 0.32, 1},   -- friendly
  },
  use_playerclass_color = true,

  -- cast bars: big, flat, gold = kickable, steel grey + shield = not kickable
  cast_statusbar_texture = TEX,
  cast_statusbar_bgtexture = TEX,
  cast_statusbar_bgcolor = {0.04, 0.04, 0.05, 0.92},
  cast_statusbar_color = {1, 0.76, 0.10, 1},
  cast_statusbar_color_channeling = {0.20, 0.80, 1, 1},
  cast_statusbar_color_nointerrupt = {0.46, 0.48, 0.54, 1},
  cast_statusbar_color_important = {1, 0.32, 0.08, 1},
  cast_statusbar_color_interrupted = {0.95, 0.15, 0.55, 1},
  cast_statusbar_color_finished = {0.30, 0.90, 0.40, 1},
  cast_statusbar_spark_color = {1, 1, 1, 1},
  cast_statusbar_spark_alpha = 0.9,
  cast_statusbar_interrupt_anim = true,
  castbar_icon_show = true,
  castbar_icon_showshield = true,
  castbar_target_show = true,
  castbar_target_font = FONT,
  castbar_target_text_size = 9,

  -- target / focus / hover
  target_highlight = true,
  target_highlight_alpha = 0.55,
  target_highlight_color = {1, 1, 1, 1},
  target_indicator = "Arrow Thin",
  target_shady_enabled = true,
  target_shady_alpha = 0.65,
  target_shady_combat_only = true,
  focus_indicator_enabled = true,
  focus_color = {0.60, 0.25, 1, 0.35},
  hover_highlight = true,
  hover_highlight_alpha = 0.25,

  -- threat: both colour sets ship in every profile; the Threat Mode mod picks tank or DPS.
  -- tank: green = you hold it, red = lost, orange = losing it, yellow = being pulled off another tank,
  --       blue = another tank has it (off-tank). DPS: red = it's on you, orange = about to pull, purple = mob on a non-tank
  tank = {
    colors = {
      aggro = {0.16, 0.74, 0.36, 1},
      noaggro = {0.95, 0.16, 0.16, 1},
      pulling = {1, 0.58, 0.05, 1},
      nocombat = {0.42, 0.10, 0.10, 1},
      anothertank = {0.30, 0.55, 1, 1},
      pulling_from_tank = {1, 0.85, 0.10, 1},
    },
  },
  dps = {
    colors = {
      aggro = {0.95, 0.16, 0.16, 1},
      noaggro = {0.18, 0.60, 0.32, 1},
      pulling = {1, 0.58, 0.05, 1},
      notontank = {0.66, 0.30, 0.95, 1},
      solo = {0.78, 0.16, 0.13, 1},
    },
    use_aggro_solo = true,
  },
  aggro_can_check_notank = true,
  aggro_modifies = {health_bar_color = true, border_color = false, actor_name_color = false},
  show_aggro_glow = true,
  show_aggro_flash = true,
  not_affecting_combat_enabled = true,
  not_affecting_combat_alpha = 0.6,
  range_check_alpha = 0.55,

  -- markers
  indicator_elite = true,
  indicator_rare = true,
  indicator_quest = true,
  indicator_worldboss = true,
  indicator_extra_raidmark = true,

  -- auras: your debuffs + CC, enemy buffs, enrage as a big icon on the right
  aura_enabled = true,
  aura_width = 24, aura_height = 18,
  aura_width2 = 24, aura_height2 = 18,
  aura_frame1_anchor = {side = 8, x = 0, y = 11},
  aura_frame2_anchor = {side = 8, x = 0, y = 11},
  aura_timer = true,
  aura_timer_text_font = FONT,
  aura_timer_text_size = 11,
  aura_stack_font = FONT,
  aura_stack_size = 10,
  aura_border_colors_by_type = true,
  aura_show_aura_by_the_player = true,
  aura_show_debuff_by_the_player = true,
  aura_show_buff_by_the_unit = true,
  aura_show_dispellable = true,
  aura_show_crowdcontrol = true,
  aura_show_enrage = false,
  debuff_show_cc = true,
  aura_tracker = {
    debuff_tracked = DEBUFFS,
  },
  extra_icon_show_enrage = true,
  extra_icon_timer_font = FONT,
  extra_icon_stack_font = FONT,
  extra_icon_caster_font = FONT,
}
