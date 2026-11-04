-- Ashen Trail - Custom Horde Forever leveling guide for RestedXP
-- Drop this folder into Interface/AddOns alongside RXPGuides.
-- Original custom route for World of Warcraft: Forever (Horde).

local faction = UnitFactionGroup("player")
if faction == "Alliance" then return end

RXPGuides.RegisterGuide([[
#forever
<< Horde
#name 1-6 Durotar (Ashen)
#version 1
#group Ashen Trail Forever (H)
#subgroup Ashen Trail 1-30
#defaultfor Orc/Troll
#next 6-12 Durotar (Ashen)

step << !Orc !Troll
    #sticky
    #completewith next
    >>This chapter is for Orcs and Trolls. Pick the starter that matches your race.
step
    .goto Durotar,43.3,68.5
    >>Talk to Kaltunk
    .accept 4641 >>Accept Your Place In The World
    .target Kaltunk
step
    .goto Durotar,42.1,68.3
    >>Talk to Gornek inside the Den
    .turnin 4641 >>Turn in Your Place In The World
    .accept 788 >>Accept Cutting Teeth
    .target Gornek
step << Warlock
    .goto Durotar,42.6,69
    >>Talk to Ruzan for the early Warlock chain
    .accept 1485 >>Accept Vile Familiars
    .target Ruzan
step
    .goto Durotar,43.8,67,40
    >>Kill Mottled Boars around the Valley for Cutting Teeth
    .complete 788 >>Mottled Boar slain
    .mob Mottled Boar
step
    .goto Durotar,42.1,68.3
    .turnin 788 >>Turn in Cutting Teeth
    .accept 789 >>Accept Sting of the Scorpid
    .accept 4402 >>Accept Galgar's Cactus Apple Surprise
    .target Gornek
step
    .goto Durotar,40.6,62.6
    >>Kill Scorpid Workers and loot Cactus Apples while moving north-west
    .complete 789 >>Scorpid Worker Tail
    .complete 4402 >>Cactus Apple
    .mob Scorpid Worker
step
    .goto Durotar,40.6,62.6
    .accept 790 >>Accept Sarkoth
    >>Talk to Hana'zua on the ridge
    .target Hana'zua
step
    .goto Durotar,40.6,67.1
    >>Kill Sarkoth on the hillside
    .complete 790 >>Sarkoth's Mangled Claw
    .unitscan Sarkoth
step
    .goto Durotar,40.6,62.6
    .turnin 790 >>Turn in Sarkoth
    .accept 804 >>Accept Sarkoth
    .target Hana'zua
step
    .goto Durotar,42.1,68.3
    .turnin 789 >>Turn in Sting of the Scorpid
    .turnin 804 >>Turn in Sarkoth
    .turnin 4402 >>Turn in Galgar's Cactus Apple Surprise
    .trainer >>Train level 4-6 skills before leaving
    .xp 6
]])

RXPGuides.RegisterGuide([[
#forever
<< Horde
#name 6-12 Durotar (Ashen)
#version 1
#group Ashen Trail Forever (H)
#subgroup Ashen Trail 1-30
#defaultfor Orc/Troll
#next 10-13 Tirisfal Detour (Ashen)

step
    .goto Durotar,52,68.3
    >>Travel to Sen'jin Village
    .accept 786 >>Accept Thwarting Kolkar Aggression
    .accept 784 >>Accept Vanquish the Betrayers
    .accept 791 >>Accept Carry Your Weight
    .fp >>Get the Sen'jin Village Flight Path
step
    .goto Durotar,58,56,50
    >>Clear Kul Tiras on the islands / coast for Vanquish and Canvas Scraps
    .complete 784 >>Kul Tiras Sailor / Marine
    .complete 791 >>Canvas Scraps
    .mob Kul Tiras Sailor
step
    .goto Durotar,54.5,75
    >>Burn the three Kolkar attack plans on the ridges south of Sen'jin
    .complete 786 >>Attack Plan: Valley of Trials / Sen'jin / Orgrimmar
step
    .goto Durotar,52,68.3
    .turnin 786 >>Turn in Thwarting Kolkar Aggression
    .turnin 784 >>Turn in Vanquish the Betrayers
    .turnin 791 >>Turn in Carry Your Weight
step
    .goto Durotar,51.9,43.5
    >>Arrive Razor Hill
    .home >>Set your Hearthstone to Razor Hill
    .fp >>Get the Razor Hill Flight Path
    .accept 807 >>Accept From The Wreckage....
    .accept 806 >>Accept Dark Storms
    .accept 837 >>Accept Encroachment
step
    .goto Durotar,44,39,45
    >>Kill Razormane for Encroachment west of Razor Hill
    .complete 837 >>Razormane Quilboar
    .mob Razormane Quilboar
step
    .goto Durotar,52,17
    >>Kill Fizzle Darkstorm near Thunder Ridge for Dark Storms
    .complete 806 >>Fizzle's Claw
    .unitscan Fizzle Darkstorm
step
    .goto Orgrimmar,45.1,63.9
    >>Enter Orgrimmar - get the Flight Path
    .fp >>Get the Orgrimmar Flight Path
    .trainer >>Train, bank, craft campfire buffs if offered
    *Optional: Ragefire Chasm once with all dungeon quests.
step
    .goto Durotar,51.9,43.5
    .hs >>Hearth to Razor Hill
    .turnin 806 >>Turn in Dark Storms
    .turnin 837 >>Turn in Encroachment
    .xp 12
    >>Take the zeppelin tower east of Orgrimmar toward Tirisfal Glades
]])

RXPGuides.RegisterGuide([[
#forever
<< Horde
#name 10-13 Tirisfal Detour (Ashen)
#version 1
#group Ashen Trail Forever (H)
#subgroup Ashen Trail 1-30
#defaultfor Orc/Troll
#next 12-16 Silverpine (Ashen)

step
    .goto Tirisfal Glades,60.7,58.8
    >>Arrive Brill via zeppelin from Orgrimmar
    .fp >>Get the Undercity Flight Path
    .home >>Set your Hearthstone to Brill / Undercity as preferred
step
    >>Clear available Brill / Agamand Mills yellows until ~12-13. Do not overstay - Silverpine and Barrens are denser XP.
    .xp 12.5
step
    .goto Undercity,63,48
    >>Pick up Ruins of Lordaeron dungeon quests from Undercity / Ruins NPCs while you are here
    *Run Ruins of Lordaeron once between 15-18 when a group forms.
step
    .goto Silverpine Forest,45.6,42.6
    >>Run south into Silverpine Forest toward The Sepulcher
]])

RXPGuides.RegisterGuide([[
#forever
<< Horde
#name 1-6 Mulgore (Ashen)
#version 1
#group Ashen Trail Forever (H)
#subgroup Ashen Trail 1-30
#defaultfor Tauren
#next 6-12 Mulgore (Ashen)

step << !Tauren
    #sticky
    #completewith next
    >>This chapter is for Tauren. Choose Mulgore only if you started in Camp Narache.
step
    .goto Mulgore,44.9,77.1
    .accept 747 >>Accept The Hunt Begins
    .target Grull Hawkwind
step
    .goto Mulgore,45,80,35
    >>Kill Plainstriders and loot their feathers / meat
    .complete 747 >>Plainstrider Meat / Feather
    .mob Plainstrider
step
    .goto Mulgore,44.9,77.1
    .turnin 747 >>Turn in The Hunt Begins
    .accept 750 >>Accept The Hunt Continues
    .accept 752 >>Accept A Humble Task
step
    .goto Mulgore,50,81.1
    .turnin 752 >>Turn in A Humble Task
    .accept 753 >>Accept A Humble Task
    .target Greatmother Hawkwind
step
    .goto Mulgore,44.9,77.1
    .turnin 753 >>Turn in A Humble Task
    .accept 755 >>Accept Rites of the Earthmother
    .xp 6
]])

RXPGuides.RegisterGuide([[
#forever
<< Horde
#name 6-12 Mulgore (Ashen)
#version 1
#group Ashen Trail Forever (H)
#subgroup Ashen Trail 1-30
#defaultfor Tauren
#next 12-16 Silverpine (Ashen)

step
    .goto Mulgore,47.5,60.2
    >>Arrive Bloodhoof Village
    .home >>Set your Hearthstone to Bloodhoof Village
    .fp >>Get the Bloodhoof Village Flight Path
    .accept 748 >>Accept Poison Water
    .accept 761 >>Accept Swoop Hunting
step
    .goto Mulgore,42,47,50
    >>Farm wolves, plainstriders, and swoops north/west of Bloodhoof
    .complete 748 >>Prairie Wolf Paw / Plainstrider Scale
    .complete 761 >>Trophy Swoop Quill
step
    .goto Mulgore,47.5,60.2
    .turnin 748 >>Turn in Poison Water
    .turnin 761 >>Turn in Swoop Hunting
    .accept 754 >>Accept Winterhoof Cleansing
step
    .goto Thunder Bluff,47,50
    >>Visit Thunder Bluff - get Flight Path and train
    .fp >>Get the Thunder Bluff Flight Path
    .trainer >>Train spells / weapons
step
    >>Finish remaining Bloodhoof quests to ~12, then take the zeppelin from Thunder Bluff toward Orgrimmar / Undercity connection and head to Silverpine.
    .xp 12
]])

RXPGuides.RegisterGuide([[
#forever
<< Horde
#name 1-6 Tirisfal (Ashen)
#version 1
#group Ashen Trail Forever (H)
#subgroup Ashen Trail 1-30
#defaultfor Undead
#next 6-12 Tirisfal (Ashen)

step << !Undead
    #sticky
    #completewith next
    >>This chapter is for Undead starting in Deathknell.
step
    .goto Tirisfal Glades,30.2,71.6
    .accept 363 >>Accept Rude Awakening
    .target Undertaker Mordo
step
    .goto Tirisfal Glades,30.8,66.2
    .turnin 363 >>Turn in Rude Awakening
    .accept 364 >>Accept The Mindless Ones
    .target Shadow Priest Sarvis
step
    .goto Tirisfal Glades,32,63,30
    >>Kill Mindless Zombies and Wretched Zombies outside the chapel
    .complete 364 >>Mindless / Wretched Zombie
    .mob Mindless Zombie
step
    .goto Tirisfal Glades,30.8,66.2
    .turnin 364 >>Turn in The Mindless Ones
    .accept 376 >>Accept The Damned
    .accept 380 >>Accept Night Web's Hollow
    .xp 6
]])

RXPGuides.RegisterGuide([[
#forever
<< Horde
#name 6-12 Tirisfal (Ashen)
#version 1
#group Ashen Trail Forever (H)
#subgroup Ashen Trail 1-30
#defaultfor Undead
#next 12-16 Silverpine (Ashen)

step
    .goto Tirisfal Glades,60.7,51.9
    >>Arrive Brill
    .home >>Set your Hearthstone to Brill
    .fp >>Get the Undercity Flight Path
    .accept 367 >>Accept A New Plague
    .accept 370 >>Accept At War With The Scarlet Crusade
step
    .goto Tirisfal Glades,32,48,40
    >>Work Scarlet and plague dog quests west of Brill
    .complete 367 >>Darkhound Blood
    .complete 370 >>Scarlet
step
    .goto Undercity,63,48
    >>Train in Undercity and collect Ruins of Lordaeron dungeon quests
    .trainer >>Train class skills
    .xp 12
step
    .goto Silverpine Forest,45.6,42.6
    >>Continue south into Silverpine Forest
]])

RXPGuides.RegisterGuide([[
#forever
<< Horde
#name 1-9 Zephras Isle (Ashen)
#version 1
#group Ashen Trail Forever (H)
#subgroup Ashen Trail 1-30
#defaultfor Skyborne
#next 9-14 Zephras Isle (Ashen)

step << !Skyborne
    #sticky
    #completewith next
    >>This chapter is for Windshaper Skyborne on Zephras Isle.
step
    .goto Zephras Isle,42.8,23.4
    >>Talk to Ailee Farheart and begin Coming of Age / Harmony in Balance
    +Accept every starter yellow in Thendal Grove before leaving the ridge
step
    .goto Zephras Isle,45,27,40
    >>Clear Juvenile Vuldren / infestation objectives around the grove
    .xp 5
step
    .goto Zephras Isle,50,40
    >>Move into Shen'dar and Falaath Village hubs - turn in, train, and take the next chapter leads
    .trainer >>Train as skills unlock
    .xp 9
]])

RXPGuides.RegisterGuide([[
#forever
<< Horde
#name 9-14 Zephras Isle (Ashen)
#version 1
#group Ashen Trail Forever (H)
#subgroup Ashen Trail 1-30
#defaultfor Skyborne
#next 12-16 Silverpine (Ashen)

step
    .goto Zephras Isle,55,55
    >>Complete Valanaar chapter quests until the skycutter becomes available
    .xp 13
step
    >>Take the skycutter to Skywatcher Plateau in Mulgore
    .goto Mulgore,36,30
    .fp >>Get the Thunder Bluff (run / fly once unlocked) Flight Path
step << Hunter
    >>Hunters: after Mulgore arrival, you may skip Silverpine and go Crossroads - Barrens chapter next.
step << !Hunter
    >>Travel to Orgrimmar -> zeppelin to Tirisfal -> Silverpine Sepulcher
    .goto Silverpine Forest,45.6,42.6
]])

RXPGuides.RegisterGuide([[
#forever
<< Horde
#name 12-16 Silverpine (Ashen)
#version 1
#group Ashen Trail Forever (H)
#subgroup Ashen Trail 1-30
#next 16-24 The Barrens (Ashen)

step
    .goto Silverpine Forest,43.4,40.9
    >>Talk to High Executor Hadrec at The Sepulcher
    .home >>Set your Hearthstone to The Sepulcher
    .fp >>Get the The Sepulcher Flight Path
    .accept 429 >>Accept Wild Hearts
    .accept 445 >>Accept Delivery to Silverpine Forest
    .accept 447 >>Accept A Recipe For Death
step
    .goto Silverpine Forest,56,34,45
    >>Farm Worgens / bears / spiders east of The Sepulcher for early Silverpine quests
    .complete 429 >>Discolored Worg Hearts
    .mob Worgen
step
    .goto Silverpine Forest,44.2,39.8
    .turnin 429 >>Turn in Wild Hearts
    >>Continue Sepulcher quests (Border Patrols, Ivar's Farm, Beren's Peril) until 15-16
    .xp 15.5
step
    *Optional: Shadowfang Keep around 22+ with Hillsbrad - skip for now unless a full group is ready.
    >>Take the zeppelin from Tirisfal to Orgrimmar, then run / fly to The Crossroads
    .goto The Barrens,51.5,30.2
]])

RXPGuides.RegisterGuide([[
#forever
<< Horde
#name 16-24 The Barrens (Ashen)
#version 1
#group Ashen Trail Forever (H)
#subgroup Ashen Trail 1-30
#next 24-26 Hillsbrad (Ashen)

step
    .goto The Barrens,51.5,30.2
    >>Arrive The Crossroads
    .home >>Set your Hearthstone to The Crossroads
    .fp >>Get the The Crossroads Flight Path
    .accept 871 >>Accept Disrupt the Attacks
    .accept 872 >>Accept The Disruption Ends
    .accept 844 >>Accept Plainstrider Menace
    .accept 869 >>Accept Raptor Thieves
step
    .goto The Barrens,54,25,50
    >>Clear Razormane camps north-east of Crossroads
    .complete 871 >>Razormane
    .complete 872 >>Kreenig Snarlsnout
    .unitscan Kreenig Snarlsnout
step
    .goto The Barrens,52,30,60
    >>Kill Plainstriders and Raptors on the circuits around Crossroads
    .complete 844 >>Plainstrider Beak
    .complete 869 >>Raptor Head
step
    .goto The Barrens,51.5,30.2
    .turnin 871 >>Turn in Disrupt the Attacks
    .turnin 872 >>Turn in The Disruption Ends
    .turnin 844 >>Turn in Plainstrider Menace
    .turnin 869 >>Turn in Raptor Thieves
step
    .goto The Barrens,62.7,36.2
    >>Travel to Ratchet
    .fp >>Get the Ratchet Flight Path
    .accept 887 >>Accept Southsea Freebooters
    .accept 894 >>Accept Samophlange
    *Ratchet boat still connects to Booty Bay later for STV.
step
    .goto The Barrens,46,36
    >>Collect every Wailing Caverns quest (Crossroads / Ratchet / WC mouth), then run WC once
    +Do not farm WC - one clear with quests, then return outdoors
step
    .goto The Barrens,44.9,59.1
    >>Push south to Camp Taurajo around 18-20
    .fp >>Get the Camp Taurajo Flight Path
    .home >>Set your Hearthstone to Camp Taurajo (optional swap)
    .accept 878 >>Accept Tribes at War
    .xp 22
step
    >>Finish southern Barrens quilboar / harpy quests to 23-24, hearth, then zeppelin toward Hillsbrad (Tirisfal -> south)
    .xp 24
]])

RXPGuides.RegisterGuide([[
#forever
<< Horde
#name 24-26 Hillsbrad (Ashen)
#version 1
#group Ashen Trail Forever (H)
#subgroup Ashen Trail 1-30
#next 25-27 Stonetalon (Ashen)

step
    .goto Hillsbrad Foothills,62.3,20.8
    >>Arrive Tarren Mill
    .fp >>Get the Tarren Mill Flight Path
    .home >>Set your Hearthstone to Tarren Mill
    .accept 494 >>Accept Time To Strike
    .accept 498 >>Accept The Rescue
    .accept 549 >>Accept WANTED: Syndicate Personnel
step
    .goto Hillsbrad Foothills,62,20
    >>Talk to Magus Wordeen Voidglare for City of Dalaran attunement leads
    +Accept Key to the City and Prison Break-In - required before City of Dalaran (28-33)
step
    .goto Hillsbrad Foothills,58,28,40
    >>Clear Syndicate / yeti / Hillsbrad field quests around Tarren Mill
    .complete 549 >>Syndicate
    .xp 25.5
step
    *Optional Shadowfang Keep clear if your group is 22-26.
    >>Hearth / zeppelin back to Kalimdor for Stonetalon and southern Barrens leftovers
]])

RXPGuides.RegisterGuide([[
#forever
<< Horde
#name 25-27 Stonetalon (Ashen)
#version 1
#group Ashen Trail Forever (H)
#subgroup Ashen Trail 1-30
#next 27-28 Ashenvale (Ashen)

step
    .goto The Barrens,35.3,27.9
    >>Enter Stonetalon via the Barrens northwest pass
    .accept 1062 >>Accept Goblin Invaders
step
    .goto Stonetalon Mountains,47.2,61.1
    >>Reach Sun Rock Retreat
    .fp >>Get the Sun Rock Retreat Flight Path
    .home >>Set your Hearthstone to Sun Rock Retreat
step
    .goto Stonetalon Mountains,60,52,45
    >>Clear Windshear Crag goblins and deepmoss spiders for Sun Rock quests
    .complete 1062 >>Venture Co. Loggers
    .xp 26.5
step
    >>Turn in Stonetalon quests, then travel north toward Ashenvale / Zoram Strand for BFD
]])

RXPGuides.RegisterGuide([[
#forever
<< Horde
#name 27-28 Ashenvale (Ashen)
#version 1
#group Ashen Trail Forever (H)
#subgroup Ashen Trail 1-30
#next 28-30 Thousand Needles (Ashen)

step
    .goto Ashenvale,12.2,33.8
    >>Zoram'gar Outpost - get FP and Naga quests
    .fp >>Get the Zoram'gar Outpost Flight Path
step
    >>Collect Blackfathom Deeps quests and run the dungeon once
    +One BFD clear with quests - then resume outdoor Ashenvale XP
step
    .goto Ashenvale,73.2,61.6
    >>Splintertree Post hub
    .fp >>Get the Splintertree Post Flight Path
    .accept 6503 >>Accept Ashenvale Outrunners
    .xp 28
step
    >>Finish Splintertree outdoors, then hearth / fly toward Thousand Needles via Camp Taurajo
]])

RXPGuides.RegisterGuide([[
#forever
<< Horde
#name 28-30 Thousand Needles (Ashen)
#version 1
#group Ashen Trail Forever (H)
#subgroup Ashen Trail 1-30
#next 30-40 Desolace & STV (Ashen)

step
    .goto The Barrens,44.5,91
    >>Enter Thousand Needles from southern Barrens / Great Lift
step
    .goto Thousand Needles,45.1,49.1
    >>Freewind Post
    .fp >>Get the Freewind Post Flight Path
    .home >>Set your Hearthstone to Freewind Post
    .accept 1149 >>Accept Test of Faith
step
    >>Work Freewind / Whitereach quests to 30. Queue Razorfen Kraul with quests when 29+.
    .xp 30
step
    *Legacy Point checkpoint at 25 should already be done - next major systems hit at 40 (mount / dual spec).
    >>Continue to the 30-40 chapter: Desolace, Stranglethorn, Dustwallow, Arathi, Riverglades
]])

RXPGuides.RegisterGuide([[
#forever
<< Horde
#name 30-40 Desolace & STV (Ashen)
#version 1
#group Ashen Trail Forever (H)
#subgroup Ashen Trail 30-60
#next 40-50 Tanaris Loop (Ashen)

step
    .goto Desolace,55,55.8
    >>Ghost Walker Post - open Desolace centaur / satyr quests
    .fp >>Get the Shadowprey Village Flight Path
    .xp 33
step
    .goto Stranglethorn Vale,32.5,29.4
    >>Grom'gol Base Camp - STV pages, raptors, tigers
    .fp >>Get the Grom'gol Base Camp Flight Path
    .home >>Set your Hearthstone to Grom'gol or Booty Bay
    *While at Grom'gol, dive west for The Drowned City entrance around 35-38.
step
    >>Travel to Riverglades when you hit the mid-30s - treat it as your primary outdoor XP until ~42
    +Riverglades: clear hub boards, finish Brotherhood / ogre storylines, run Krol'dok Stronghold near 40
    .xp 38
step
    .goto Dustwallow Marsh,35.2,30.7
    >>Brackenwall Village - Dustwallow fillers between STV / Riverglades
    .fp >>Get the Brackenwall Village Flight Path
step
    .goto Arathi Highlands,73.1,32.8
    >>Hammerfall - Arathi circuit when Kalimdor slows
    .fp >>Get the Hammerfall Flight Path
    .xp 40
step
    >>At 40: train Apprentice Riding in Orgrimmar / Thunder Bluff / Undercity, unlock Dual Spec, then continue Tanaris
    *New boat: Steamwheedle Port (Tanaris) <-> Riverglades shortens mid-game travel.
]])

RXPGuides.RegisterGuide([[
#forever
<< Horde
#name 40-50 Tanaris Loop (Ashen)
#version 1
#group Ashen Trail Forever (H)
#subgroup Ashen Trail 30-60
#next 50-60 Plaguelands & Hyjal (Ashen)

step
    .goto Tanaris,52.5,27.9
    >>Gadgetzan - set hearth and vacuum pirate / wastewander quests
    .fp >>Get the Gadgetzan Flight Path
    .home >>Set your Hearthstone to Gadgetzan
step
    >>Run Zul'Farrak once with all Gadgetzan / ZF quests around 44-48
    .xp 45
step
    .goto Feralas,75.4,44.3
    >>Camp Mojache - Feralas yeti / ruins / sprite quests
    .fp >>Get the Camp Mojache Flight Path
step
    .goto The Hinterlands,78.1,81.4
    >>Revantusk Village - Hinterlands circuit
    .fp >>Get the Revantusk Village Flight Path
    .xp 48
step
    >>Return to Dustwallow for Alcaz Prison (48-53), then push Un'Goro and Felwood leads
    .goto Un'Goro Crater,45.2,5.8
    .fp >>Get the Marshal's Refuge (neutral) Flight Path
    *Loot Un'Goro power crystals now - required inside Shaper's Terrace later.
]])

RXPGuides.RegisterGuide([[
#forever
<< Horde
#name 50-60 Plaguelands & Hyjal (Ashen)
#version 1
#group Ashen Trail Forever (H)
#subgroup Ashen Trail 30-60

step
    .goto Felwood,34.8,52.8
    >>Bloodvenom Post / Felwood chain openers
    .fp >>Get the Bloodvenom Post Flight Path
    .xp 52
step
    .goto Winterspring,60.5,36.3
    >>Everlook - Winterspring fillers and Timbermaw reputation stops
    .fp >>Get the Everlook Flight Path
step
    .goto Azshara,22,49.7
    >>Valormok - Azshara quests + Blackmaw Hold around 55+
    .fp >>Get the Valormok Flight Path
    +Run Blackmaw Hold once with quests between 55-60
step
    .goto Western Plaguelands,39.5,69
    >>The Bulwark -> Western Plaguelands -> Eastern Plaguelands (Light's Hope)
    .fp >>Get the Light's Hope Chapel Flight Path
    .xp 56
step
    >>Enter Mount Hyjal for Forever's endgame leveling chapters - clear hubs until 58+
    *Hyjal quest IDs are launch-live; follow yellows and keep Ashen Trail notes updated as you map them.
    .xp 58
step
    .goto Un'Goro Crater,50,20
    >>Shaper's Terrace (northern Un'Goro) - bring power crystals to the consoles
    +Final dungeon spike: Shaper's Terrace 58-60 with crystals in bags
step
    .goto Silithus,50.8,34.6
    >>Optional Silithus / remaining Plaguelands until 60 if Hyjal is congested
    .fp >>Get the Cenarion Hold Flight Path
    .xp 60
    >>Congratulations - Ashen Trail complete. Bank heirlooms, lock Dual Spec for raids, claim Legacy Point.
]])
