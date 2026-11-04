-- Ashen Trail fallback pack for RestedXP.
-- Saved copy of the Horde Forever route. The standalone AshenTrail addon does not load this file.
-- Install this folder next to RXPGuides only if you want that fallback.

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
    .accept 4641 >>Accept: Your Place In The World
    .target Kaltunk
step
    .goto Durotar,42.1,68.3
    >>Talk to Gornek inside the Den
    .turnin 4641 >>Turn in: Your Place In The World
    .accept 788 >>Accept: Cutting Teeth
    .target Gornek
step << Warlock
    .goto Durotar,42.6,69
    >>Talk to Ruzan for the early Warlock chain
    .accept 1485 >>Accept: Vile Familiars
    .target Ruzan
step << Warlock
    >>Kill Vile Familiars in the cave north of the Den.
    .complete 1485,1 >>Vile Familiar
    .goto Durotar,42.6,69
    .turnin 1485 >>Talk to Ruzan. Turn in: Vile Familiars
step
    .goto Durotar,43.8,67,40
    >>Kill Mottled Boars around the Valley for Cutting Teeth
    .complete 788,1 >>Mottled Boar slain
    .mob Mottled Boar
step
    .goto Durotar,42.1,68.3
    .turnin 788 >>Turn in: Cutting Teeth
    .accept 789 >>Accept: Sting of the Scorpid
    .accept 4402 >>Accept: Galgar's Cactus Apple Surprise
    .target Gornek
step
    .goto Durotar,40.6,62.6
    >>Kill Scorpid Workers and loot Cactus Apples while moving north-west
    .complete 789,1 >>Scorpid Worker Tail
    .complete 4402,1 >>Cactus Apple
    .mob Scorpid Worker
step
    .goto Durotar,40.6,62.6
    .accept 790 >>Accept: Sarkoth
    >>Talk to Hana'zua on the ridge
    .target Hana'zua
step
    .goto Durotar,40.6,67.1
    >>Kill Sarkoth on the hillside
    .complete 790,1 >>Sarkoth's Mangled Claw
    .unitscan Sarkoth
step
    .goto Durotar,40.6,62.6
    .turnin 790 >>Turn in: Sarkoth
    .accept 804 >>Accept: Sarkoth
    .target Hana'zua
step
    .goto Durotar,42.1,68.3
    .turnin 789 >>Turn in: Sting of the Scorpid
    .turnin 804 >>Turn in: Sarkoth
    .goto Durotar,42.73,67.23
    .turnin 4402 >>Talk to Galgar. Turn in: Galgar's Cactus Apple Surprise
    .trainer >>Train level 4–6 skills before leaving
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
    .goto Durotar,54.2,73.2
    .accept 786 >>Talk to Lar Prowltusk. Accept: Thwarting Kolkar Aggression
step
    .goto Durotar,49.8,81.3
    >>Burn the three Kolkar attack plans on the ridges south of Sen'jin
    .complete 786,1 >>Attack Plan: Valley of Trials / Sen'jin / Orgrimmar
step
    .goto Durotar,54.2,73.2
    .turnin 786 >>Talk to Lar Prowltusk. Turn in: Thwarting Kolkar Aggression
step
    .goto Durotar,51.9,43.5
    >>Go to Razor Hill.
    .home >>Set Hearth to Razor Hill
    .fp >>Get the Razor Hill flight path
step
    .goto Durotar,52,43.4
    .accept 784 >>Talk to Gar'Thok. Accept: Vanquish the Betrayers
    .goto Durotar,52,43.4
    .accept 837 >>Talk to Gar'Thok. Accept: Encroachment
step
    .goto Durotar,49.9,40.4
    .accept 791 >>Talk to Furl Scornbrow. Accept: Carry Your Weight
step
    .goto Durotar,52.2,43.1
    .accept 806 >>Talk to Orgnil Soulscar. Accept: Dark Storms
step
    .goto Durotar,58,56,50
    >>Clear Kul Tiras on the islands and coast for Vanquish the Betrayers and Canvas Scraps.
    .complete 784,1 >>Kul Tiras Sailor / Marine
    .complete 791,1 >>Canvas Scraps
    .mob Kul Tiras Sailor
step
    .goto Durotar,52,43.4
    .turnin 784 >>Talk to Gar'Thok. Turn in: Vanquish the Betrayers
step
    .goto Durotar,52,43.4
    .accept 825 >>Talk to Gar'Thok. Accept: From The Wreckage....
step
    .goto Durotar,61,52
    >>Swim the wrecks off Scuttle Coast and collect Gnomish Tools.
    .complete 825,1 >>Gnomish Tools
step
    .goto Durotar,52,43.4
    .turnin 825 >>Talk to Gar'Thok. Turn in: From The Wreckage....
step
    .goto Durotar,49.9,40.4
    .turnin 791 >>Talk to Furl Scornbrow. Turn in: Carry Your Weight
step
    .goto Durotar,44,39,45
    >>Kill Razormane for Encroachment west of Razor Hill
    .complete 837,1 >>Razormane Quilboar
    .mob Razormane Quilboar
step
    .goto Durotar,52,17
    >>Kill Fizzle Darkstorm near Thunder Ridge for Dark Storms
    .complete 806,1 >>Fizzle's Claw
    .unitscan Fizzle Darkstorm
step
    .goto Orgrimmar,45.1,63.9
    >>Enter Orgrimmar and get the flight path.
    .fp >>Get the Orgrimmar flight path
    .trainer >>Train your class skills, visit the bank, and cook a campfire buff if one is offered.
step
    .goto Orgrimmar,49.5,50.6
    >>Talk to Neeru Fireblade. Accept: Slaying the Beast.
step
    .goto Orgrimmar,31.7,37.8
    >>Talk to Thrall. Accept: Hidden Enemies.
step
    .goto Thunder Bluff,70.1,29.5
    >>Talk to Rahauro. Accept: Testing an Enemy's Strength.
step
    .goto Undercity,56.2,92.2
    >>Talk to Varimathras. Accept: The Power to Destroy....
step
    >>Inside Ragefire Chasm. Talk to Maur Grimtotem. Accept: Searching for the Lost Satchel.
step
    >>No published Horde quest giver for Hall of Thanes. Nothing to mark.
step
    .goto Durotar,51.9,43.5
    .hs >>Use your Hearthstone to return to Razor Hill
    .goto Durotar,52.2,43.1
    .turnin 806 >>Talk to Orgnil Soulscar. Turn in: Dark Storms
    .goto Durotar,52,43.4
    .turnin 837 >>Talk to Gar'Thok. Turn in: Encroachment
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
    >>Get off the zeppelin at Brill.
    >>Set Hearth to Brill. Bind in Undercity instead if you would rather hearth there.
    .home >>Set Hearth to Brill
step
    .goto Undercity,63,48
    >>Get the Undercity flight path inside the city.
    .fp >>Get the Undercity flight path
step
    .goto Tirisfal Glades,61.8,52.4
    >>Clear available Brill and Agamand Mills yellows until about 12. Do not overstay. Silverpine and the Barrens are denser XP.
    .xp 12.5
step
    >>Pick up the Ruins of Lordaeron quests from the givers below.
step
    .goto Tirisfal Glades,65.2,60.2
    >>Talk to Deathguard Kristof. Accept: The Wrath of Rath'mael.
step
    .goto Silverpine Forest,44.6,42.8
    >>Talk to Tabitha Heartweaver. Accept: A Frightened Request.
step
    .goto Undercity,57.8,89.8
    >>Talk to Morbin Lightbane. Accept: Light's Justice.
step
    .goto Undercity,47,72.6
    >>Talk to Theodore Griffs. Accept: The New Plague.
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
    .accept 747 >>Accept: The Hunt Begins
    .target Grull Hawkwind
step
    .goto Mulgore,45,80,35
    >>Kill Plainstriders and loot their feathers / meat
    .complete 747,1 >>Plainstrider Meat / Feather
    .mob Plainstrider
step
    .goto Mulgore,44.9,77.1
    .turnin 747 >>Turn in: The Hunt Begins
    .accept 750 >>Accept: The Hunt Continues
    .accept 752 >>Accept: A Humble Task
step
    .goto Mulgore,50,81.1
    .turnin 752 >>Turn in: A Humble Task
    .accept 753 >>Accept: A Humble Task
    .target Greatmother Hawkwind
step
    .goto Mulgore,44.9,77.1
    .turnin 753 >>Turn in: A Humble Task
    .accept 755 >>Accept: Rites of the Earthmother
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
    >>Go to Bloodhoof Village.
    .home >>Set Hearth to Bloodhoof Village
    .fp >>Get the Bloodhoof Village flight path
    .accept 748 >>Accept: Poison Water
step
    .goto Mulgore,47.67,62.68
    .accept 761 >>Talk to Harken Windtotem. Accept: Swoop Hunting
step
    .goto Mulgore,42,47,50
    >>Farm wolves, plainstriders, and swoops north/west of Bloodhoof
    .complete 748,1 >>Prairie Wolf Paw / Plainstrider Scale
    .complete 761,1 >>Trophy Swoop Quill
step
    .goto Mulgore,47.5,60.2
    .turnin 748 >>Turn in: Poison Water
    .goto Mulgore,47.67,62.68
    .turnin 761 >>Talk to Harken Windtotem. Turn in: Swoop Hunting
    .accept 754 >>Accept: Winterhoof Cleansing
step
    .goto Thunder Bluff,47,50
    >>Go to Thunder Bluff, get the flight path, and train your class skills.
    .fp >>Get the Thunder Bluff flight path
    .trainer >>Train spells / weapons
step
    .goto Orgrimmar,50.8,13.8
    >>Finish the remaining Bloodhoof quests, then go to the Orgrimmar zeppelin tower and ride to Tirisfal for Silverpine.
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
    .accept 363 >>Accept: Rude Awakening
    .target Undertaker Mordo
step
    .goto Tirisfal Glades,30.8,66.2
    .turnin 363 >>Turn in: Rude Awakening
    .accept 364 >>Accept: The Mindless Ones
    .target Shadow Priest Sarvis
step
    .goto Tirisfal Glades,32,63,30
    >>Kill Mindless Zombies and Wretched Zombies outside the chapel
    .complete 364,1 >>Mindless / Wretched Zombie
    .mob Mindless Zombie
step
    .goto Tirisfal Glades,30.8,66.2
    .turnin 364 >>Turn in: The Mindless Ones
    .accept 376 >>Accept: The Damned
    .goto Tirisfal Glades,32.15,66.01
    .accept 380 >>Talk to Executor Arren. Accept: Night Web's Hollow
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
    >>Go to Brill.
    .home >>Set Hearth to Brill
    .accept 367 >>Accept: A New Plague
    .accept 370 >>Accept: At War With The Scarlet Crusade
step
    .goto Undercity,63,48
    >>Get the Undercity flight path inside the city.
    .fp >>Get the Undercity flight path
step
    .goto Tirisfal Glades,32,48,40
    >>Work Scarlet and plague dog quests west of Brill
    .complete 367,1 >>Darkhound Blood
    .complete 370,1 >>Scarlet
step
    >>Train your class skills in Undercity.
    .trainer >>Train your class skills.
    .xp 12
step
    .goto Tirisfal Glades,65.2,60.2
    >>Talk to Deathguard Kristof. Accept: The Wrath of Rath'mael.
step
    .goto Silverpine Forest,44.6,42.8
    >>Talk to Tabitha Heartweaver. Accept: A Frightened Request.
step
    .goto Undercity,57.8,89.8
    >>Talk to Morbin Lightbane. Accept: Light's Justice.
step
    .goto Undercity,47,72.6
    >>Talk to Theodore Griffs. Accept: The New Plague.
step
    .goto Silverpine Forest,45.6,42.6
    >>Run south into Silverpine Forest.
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
    >>Move into Shen'dar and Falaath Village hubs — turn in, train, and take the next chapter leads
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
    .fp >>Get the Thunder Bluff (run / fly once unlocked) flight path
step << Hunter
    >>Hunters: after Mulgore arrival, you may skip Silverpine and go Crossroads — Barrens chapter next.
step << !Hunter
    >>Go to Orgrimmar, take the zeppelin to Tirisfal, then run to The Sepulcher in Silverpine Forest.
    .goto Silverpine Forest,45.6,42.6
step << !Hunter
    .goto Orgrimmar,49.5,50.6
    >>Talk to Neeru Fireblade. Accept: Slaying the Beast.
step << !Hunter
    .goto Orgrimmar,31.7,37.8
    >>Talk to Thrall. Accept: Hidden Enemies.
step << !Hunter
    .goto Thunder Bluff,70.1,29.5
    >>Talk to Rahauro. Accept: Testing an Enemy's Strength.
step << !Hunter
    .goto Undercity,56.2,92.2
    >>Talk to Varimathras. Accept: The Power to Destroy....
step << !Hunter
    >>Inside Ragefire Chasm. Talk to Maur Grimtotem. Accept: Searching for the Lost Satchel.
step << !Hunter
    .goto Tirisfal Glades,65.2,60.2
    >>Talk to Deathguard Kristof. Accept: The Wrath of Rath'mael.
step << !Hunter
    .goto Silverpine Forest,44.6,42.8
    >>Talk to Tabitha Heartweaver. Accept: A Frightened Request.
step << !Hunter
    .goto Undercity,57.8,89.8
    >>Talk to Morbin Lightbane. Accept: Light's Justice.
step << !Hunter
    .goto Undercity,47,72.6
    >>Talk to Theodore Griffs. Accept: The New Plague.
step << !Hunter
    .goto Silverpine Forest,45.6,42.6
    >>Go to The Sepulcher.
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
    .home >>Set Hearth to The Sepulcher
    .fp >>Get the The Sepulcher flight path
    .accept 445 >>Accept: Delivery to Silverpine Forest
    .accept 447 >>Accept: A Recipe For Death
step
    .goto Silverpine Forest,53.46,13.43
    .accept 429 >>Talk to Rane Yorick. Accept: Wild Hearts
step
    .goto Silverpine Forest,56,34,45
    >>Farm Worgens / bears / spiders east of The Sepulcher for early Silverpine quests
    .complete 429,1 >>Discolored Worg Hearts
    .mob Worgen
step
    .goto Silverpine Forest,44.2,39.8
    .turnin 429 >>Turn in: Wild Hearts
    >>Continue Sepulcher quests (Border Patrols, Ivar's Farm, Beren's Peril) until 15–16
    .xp 15.5
step
    >>Shadowfang Keep waits until the Hillsbrad chapter, around level 22, unless a full group is ready now. Its quests are at The Sepulcher.
    >>Take the zeppelin from Tirisfal to Orgrimmar, then run or fly to the Crossroads.
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
    >>Go to the Crossroads.
    .home >>Set Hearth to The Crossroads
    .fp >>Get the The Crossroads flight path
    .goto The Barrens,51.5,30.2
    .accept 871 >>Talk to Thork. Accept: Disrupt the Attacks
    .accept 844 >>Accept: Plainstrider Menace
    .accept 869 >>Accept: Raptor Thieves
step
    .goto The Barrens,54,25,50
    >>Clear Razormane camps north-east of Crossroads
    .complete 871,1 >>Razormane
step
    .goto The Barrens,51.5,30.2
    .goto The Barrens,51.5,30.2
    .turnin 871 >>Talk to Thork. Turn in: Disrupt the Attacks
    .goto The Barrens,51.5,30.2
    .accept 872 >>Talk to Thork. Accept: The Disruption Ends
step
    .goto The Barrens,54,25,50
    >>Kill Kreenig Snarlsnout in the Razormane camps.
    .complete 872,1 >>Kreenig Snarlsnout
    .unitscan Kreenig Snarlsnout
step
    .goto The Barrens,51.5,30.2
    .goto The Barrens,51.5,30.2
    .turnin 872 >>Talk to Thork. Turn in: The Disruption Ends
step
    .goto The Barrens,52,30,60
    >>Kill Plainstriders and Raptors on the circuits around Crossroads
    .complete 844,1 >>Plainstrider Beak
    .complete 869,1 >>Raptor Head
step
    .goto The Barrens,51.5,30.2
    .turnin 844 >>Turn in: Plainstrider Menace
    .turnin 869 >>Turn in: Raptor Thieves
step
    .goto The Barrens,62.7,36.2
    >>Go to Ratchet.
    .fp >>Get the Ratchet flight path
    .accept 887 >>Accept: Southsea Freebooters
    .accept 894 >>Accept: Samophlange
    *Ratchet boat still connects to Booty Bay later for STV.
step
    .goto The Barrens,62,37
    >>Talk to Mebok Mizzyrix. Accept: Smart Drinks.
step
    .goto The Barrens,63,37
    >>Talk to Crane Operator Bigglefuzz. Accept: Trouble at the Docks.
step
    .goto The Barrens,46,35
    >>Talk to Nalpak. Accept: Deviate Hides.
step
    .goto The Barrens,46,35
    >>Talk to Ebru. Accept: Deviate Eradication.
step
    .goto Thunder Bluff,34,21
    >>Talk to Apothecary Zamah. Accept: Serpentbloom.
step
    .goto Thunder Bluff,45,23
    >>Talk to Nara Wildmane. Accept: Leaders of the Fang.
step
    >>Clear Wailing Caverns once with those quests, then go back to outdoor quests. Do not farm the instance.
step
    .goto The Barrens,44.9,59.1
    >>Go south to Camp Taurajo around level 18 to 20.
    >>Set Hearth to Camp Taurajo if you want this inn instead of the Crossroads.
    .fp >>Get the Camp Taurajo flight path
    .home >>Set Hearth to Camp Taurajo
    .accept 878 >>Accept: Tribes at War
    .xp 22
step
    .goto The Barrens,44.9,59.1
    >>Finish the southern Barrens quilboar and harpy quests around Camp Taurajo.
    .xp 23
step
    .goto Hillsbrad Foothills,62.3,20.8
    >>Hearth or take the zeppelin to Tirisfal, then run south to Tarren Mill.
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
    >>Go to Tarren Mill.
    .fp >>Get the Tarren Mill flight path
    .home >>Set Hearth to Tarren Mill
    .accept 494 >>Accept: Time To Strike
    .accept 498 >>Accept: The Rescue
    .accept 549 >>Accept: WANTED: Syndicate Personnel
step
    .goto Hillsbrad Foothills,62.6,20.6
    >>Talk to Melisara. Accept: The Grave Knight.
step
    .goto Undercity,46.6,73.7
    >>Talk to Doctor Martin Felben. Accept: Source of Power.
step
    .goto Hillsbrad Foothills,58,28,40
    >>Clear Syndicate / yeti / Hillsbrad field quests around Tarren Mill
    .complete 549,1 >>Syndicate
    .xp 25.5
step
    .goto Silverpine Forest,43,41
    >>Talk to High Executor Hadrec. Accept: Deathstalkers in Shadowfang.
step
    .goto Silverpine Forest,44,39
    >>Talk to Dalar Dawnweaver. Accept: Arugal Must Die.
step
    .goto Undercity,53,54
    >>Talk to Keeper Bel'dugur. Accept: The Book of Ur.
step << Warlock
    .goto The Barrens,49,57
    >>Talk to Doan Karhan. Accept: The Orb of Soran'ruk.
step
    >>Hearth, or take the zeppelin, back to Kalimdor. The Stonetalon road leaves the Barrens at the northwest pass.
    .goto The Barrens,35.3,27.9
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
    .accept 1062 >>Accept: Goblin Invaders
step
    .goto Stonetalon Mountains,47.2,61.1
    >>Go to Sun Rock Retreat.
    .fp >>Get the Sun Rock Retreat flight path
    .home >>Set Hearth to Sun Rock Retreat
step
    .goto Stonetalon Mountains,60,52,45
    >>Clear Windshear Crag goblins and deepmoss spiders for Sun Rock quests
    .complete 1062,1 >>Venture Co. Loggers
    .xp 26.5
step
    >>Turn in the Stonetalon quests at Sun Rock Retreat.
    .goto Stonetalon Mountains,47.2,61.1
step
    .goto Ashenvale,12.2,33.8
    >>Travel north to Zoram'gar Outpost for Blackfathom Deeps.
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
    >>Go to Zoram'gar Outpost, get the flight path, and pick up the naga quests.
    .fp >>Get the Zoram'gar Outpost flight path
step
    .goto Ashenvale,11.6,34.3
    >>Talk to Je'neu Sancrea. Accept: The Essence of Aku'Mai. Accept: Amongst the Ruins.
step
    .goto Stonetalon Mountains,47.4,64.2
    >>Talk to Tsunaman. Accept: Trouble in the Deeps.
step
    >>Inside Blackfathom Deeps. Talk to Argent Guard Thaelrid. Accept: Blackfathom Villainy.
step
    .goto Ashenvale,35,48.6
    >>Talk to Llana. Accept: Lost in the Thicket Things.
step
    >>Clear Blackfathom Deeps once with those quests, then go back to outdoor Ashenvale quests.
step
    .goto Ashenvale,73.2,61.6
    >>Go to Splintertree Post and pick up the quests there.
    .fp >>Get the Splintertree Post flight path
    .xp 28
step
    .goto Ashenvale,71.11,68.12
    .accept 6503 >>Talk to Kuray'bin. Accept: Ashenvale Outrunners
step
    >>Hearth or fly to Camp Taurajo, then take the Great Lift into Thousand Needles.
    .goto The Barrens,44.5,91
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
    >>Go to Freewind Post.
    .fp >>Get the Freewind Post flight path
    .home >>Set Hearth to Freewind Post
step
    .goto Thousand Needles,53.95,41.49
    .accept 1149 >>Talk to Dorn Plainstalker. Accept: Test of Faith
step
    .goto Thousand Needles,45.1,49.1
    >>Work the Freewind Post and Whitereach quests until level 30.
    .xp 30
step
    .goto Thunder Bluff,37,29
    >>Talk to Auld Stonespire. Accept: A Vengeful Fate.
step
    .goto Undercity,48,69
    >>Talk to Master Apothecary Faranell. Accept: Going, Going, Guano!.
step
    .goto The Barrens,62,37
    >>Talk to Mebok Mizzyrix. Accept: Blueleaf Tubers.
step
    *Legacy Point checkpoint at 25 should already be done — next major systems hit at 40 (mount / dual spec).
    >>Continue to the 30–40 chapter: Desolace, Stranglethorn, Dustwallow, Arathi, Riverglades
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
    >>Go to Ghost Walker Post and pick up the Desolace centaur and satyr quests.
    .fp >>Get the Shadowprey Village flight path
    .xp 33
step
    .goto Undercity,56.2,92.2
    >>Talk to Varimathras. Accept: Into The Scarlet Monastery.
step
    .goto Undercity,48,69
    >>Talk to Master Apothecary Faranell. Accept: Hearts of Zeal.
step << !Undead
    .goto Thunder Bluff,36,26
    >>Talk to Sage Truthseeker. Accept: Compendium of the Fallen.
step
    .goto Undercity,57,65
    >>Talk to Parqual Fintallas. Accept: Test of Lore.
step
    .goto Undercity,74,33
    >>Talk to Andrew Brownell. Accept: Bring the End.
step
    .goto The Barrens,49,95
    >>Talk to Myriam Moonsinger. Accept: A Host of Evil.
step
    .goto Stranglethorn Vale,32.5,29.4
    >>Go to Grom'gol Base Camp and pick up the Stranglethorn page, raptor, and tiger quests.
    >>Set Hearth to Grom'gol Base Camp, or to Booty Bay if you are questing on the coast.
    .fp >>Get the Grom'gol Base Camp flight path
    .home >>Set Hearth to Grom'gol Base Camp
step
    .goto Mulgore,32.5,20.7
    >>Talk to Mazu'kon. Accept: Ancient Gurubashi Idol.
step
    >>Go to Rog'mar in Riverglades and quest there until about level 42. Clear the hub boards and finish the Brotherhood and ogre storylines.
    .goto Riverglades,59.6,45.1
    .fp >>Get the Rog'mar flight path
    .xp 38
step
    >>No published Horde quest giver for Krol'dok Stronghold. Nothing to mark.
step
    .goto Dustwallow Marsh,35.2,30.7
    >>Go to Brackenwall Village for Dustwallow quests between Stranglethorn and Riverglades.
    .fp >>Get the Brackenwall Village flight path
step
    .goto Arathi Highlands,73.1,32.8
    >>Go to Hammerfall and work the Arathi quests when Kalimdor slows down.
    .fp >>Get the Hammerfall flight path
    .xp 40
step << Orc
    .goto Orgrimmar,69,13
    .trainer >>Talk to Kildar. Learn Wolf Riding.
step << Troll
    .goto Durotar,55.3,75.5
    .trainer >>Talk to Xar'Ti. Learn Raptor Riding.
step << Tauren
    .goto Mulgore,47.6,58.5
    .trainer >>Talk to Kar Stormsinger. Learn Kodo Riding.
step << Undead
    .goto Tirisfal Glades,60,52
    .trainer >>Talk to Velma Warnam. Learn Undead Horsemanship.
step << Skyborne
    >>No published Skyborne riding trainer. Learn Apprentice Riding from the trainer for the mount your race can use.
step
    >>Unlock Dual Spec in a capital after you learn riding, then continue to Tanaris.
    *The boat from Steamwheedle Port to Riverglades shortens the mid-game trip.
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
    >>Go to Gadgetzan, set your Hearth there, and pick up the pirate and wastewander quests.
    .fp >>Get the Gadgetzan flight path
    .home >>Set Hearth to Gadgetzan
step
    .goto Tanaris,52,28
    >>Talk to Chief Engineer Bilgewhizzle. Accept: Divino-matic Rod.
step
    .goto Tanaris,51,26
    >>Talk to Tran'rek. Accept: Scarab Shells.
step
    .goto Tanaris,51,28
    >>Talk to Trenton Lighthammer. Accept: Troll Temper.
step
    .goto Tanaris,67,22
    >>Talk to Yeh'kinya. Accept: The Prophecy of Mosh'aru.
step
    .goto Dustwallow Marsh,46,57
    >>Talk to Tabetha. Accept: Tiara of the Deep.
step
    .goto Thousand Needles,78,77
    >>Talk to Wizzle Brassbolts. Accept: Gahz'rilla.
step
    .goto Durotar,56,74
    >>Talk to Master Gadrin. Accept: The Spider God.
step
    .goto Tanaris,52.5,27.9
    >>Keep working from Gadgetzan until level 45.
    .xp 45
step
    .goto Feralas,75.4,44.3
    >>Go to Camp Mojache and pick up the Feralas yeti, ruins, and sprite quests.
    .fp >>Get the Camp Mojache flight path
step
    .goto The Hinterlands,78.1,81.4
    >>Go to Revantusk Village and pick up the Hinterlands quests.
    .fp >>Get the Revantusk Village flight path
    .xp 48
step
    >>No published Horde quest giver for Alcaz Prison. Nothing to mark.
step
    >>Go to Marshal's Refuge in Un'Goro Crater and pick up the leads there.
    >>Loot Un'Goro power crystals now. Shaper's Terrace needs them later.
    .goto Un'Goro Crater,45.2,5.8
    .fp >>Get the Marshal's Refuge (neutral) flight path
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
    >>Go to Bloodvenom Post and pick up the Felwood quests.
    .fp >>Get the Bloodvenom Post flight path
    .xp 52
step
    .goto Winterspring,60.5,36.3
    >>Go to Everlook for Winterspring quests and Timbermaw reputation.
    .fp >>Get the Everlook flight path
step
    .goto Azshara,22,49.7
    >>Go to Valormok and pick up the Azshara quests.
    .fp >>Get the Valormok flight path
step
    >>No published Horde quest giver for Blackmaw Hold. Nothing to mark.
step
    .goto Western Plaguelands,39.5,69
    >>Go to the Bulwark and work Western Plaguelands toward Eastern Plaguelands.
step
    .goto Eastern Plaguelands,81.6,59.3
    >>Get the Light's Hope Chapel flight path.
    .fp >>Get the Light's Hope Chapel flight path
    .xp 56
step
    >>Fly from Everlook to Tainted Foothills and clear the Mount Hyjal hubs until level 58.
    .goto Mount Hyjal,55.1,82.5
    .fp >>Get the Tainted Foothills flight path
    *Hyjal quest IDs are launch-live; follow yellows and keep Ashen Trail notes updated as you map them.
    .xp 58
step
    >>No published Horde quest giver for Shaper's Terrace. Nothing to mark.
step
    .goto Silithus,50.8,34.6
    >>If Hyjal is crowded, quest in Silithus and finish any Plaguelands quests you still have until level 60.
    .fp >>Get the Cenarion Hold flight path
    .xp 60
    >>Ashen Trail is complete. Bank your heirlooms, lock Dual Spec for raids, and claim the Legacy Point.
]])
