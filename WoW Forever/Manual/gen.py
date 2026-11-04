# Builds Schizzle's WoW Forever launch manual by Jon Shaw (Schizzle). MIT with attribution.
# Run from this folder:
#   python3 gen.py
#   google-chrome --headless=new --no-pdf-header-footer --print-to-pdf=Schizzles-WoW-Forever-Launch-Manual.pdf manual.html
import html, os, sys, urllib.parse
OUT = sys.argv[1] if len(sys.argv) > 1 else "."
FONT = urllib.parse.quote("../Schizzle's Warrior/AddOns/SchizzlesWarriorSetup/SchizzlesWarriorSetup/Media/FiraSansCondensed-Medium.ttf")
E = html.escape
def table(head, rows):
    h = "".join(f"<th>{c}</th>" for c in head)
    b = "".join("<tr>" + "".join(f"<td>{c}</td>" for c in r) + "</tr>" for r in rows)
    return f"<table><tr>{h}</tr>{b}</table>"
def checks(items): return "<ul class='cb'>" + "".join(f"<li>{i}</li>" for i in items) + "</ul>"
def code(s): return f"<pre>{E(s)}</pre>"
css = """
@font-face{font-family:Fira;src:url(""" + FONT + """)}
@page{size:Letter;margin:0}
*{-webkit-print-color-adjust:exact;print-color-adjust:exact}
html{background:#111}
body{background:#111;color:#e8e2da;font:13.5px/1.45 'Segoe UI',Arial,sans-serif;margin:0;padding:0 0.5in}
table.page{width:100%;border:0;margin:0}table.page>thead>tr>td,table.page>tfoot>tr>td{height:0.45in;border:0;padding:0}table.page>tbody>tr>td{border:0;padding:0}
h1,h2,h3{font-family:Fira,'Segoe UI',Arial;font-weight:normal}
h1{color:#FF7800;font-size:34px;margin:0 0 4px}
h2{color:#FF7800;font-size:21px;margin:22px 0 6px;border-bottom:2px solid #B87333;padding-bottom:3px;break-after:avoid}
h3{color:#FFD100;font-size:16px;margin:14px 0 4px;break-after:avoid}
table{border-collapse:collapse;width:100%;margin:6px 0 14px;break-inside:avoid}
th,td{border:1px solid #333;padding:5px 8px;vertical-align:top;text-align:left}
th{background:#2a1500;color:#FFD100;font-family:Fira,'Segoe UI';font-weight:normal}
code,pre{color:#ffb36b;font-family:Consolas,monospace}
pre{background:#1a1a1a;border:1px solid #333;padding:6px 10px;margin:4px 0 10px;white-space:pre-wrap;break-inside:avoid}
.note{background:#2a1500;border-left:4px solid #FF7800;padding:8px 12px;margin:10px 0;break-inside:avoid}
.sub{color:#c7b299}
.cb{list-style:none;padding-left:4px}.cb li{margin:3px 0}.cb li:before{content:'\\2610';color:#FF7800;font-size:16px;margin-right:8px}
.cover{border:2px solid #B87333;padding:26px 28px;margin-bottom:18px;background:linear-gradient(135deg,#1c120a,#111 60%)}
.tag{display:inline-block;background:#2a1500;border:1px solid #B87333;color:#FFD100;padding:2px 10px;margin:4px 6px 0 0;font-family:Fira}
.pb{break-before:page}
.screen{position:relative;width:100%;height:330px;background:#0b0b0b;border:2px solid #B87333;margin:8px 0 14px;font-family:Fira;font-size:12px}
.box{position:absolute;border:1px dashed #B87333;color:#e8e2da;display:flex;align-items:center;justify-content:center;text-align:center;background:rgba(184,115,51,.12)}
.foot{color:#888;font-size:11.5px;margin-top:18px}
"""
# screen sketch: 1920x1080 scaled to the box via percentages
def box(x, y, w, h, label, style=""):
    return f"<div class='box' style='left:{x}%;top:{y}%;width:{w}%;height:{h}%;{style}'>{label}</div>"
screen = "<div class='screen'>" + "".join([
    box(1, 2, 14, 12, "Player + target<br>(BetterBlizzFrames, Blizzard spots)"),
    box(84, 2, 15, 26, "SexyMap minimap<br>1.5x, square"),
    box(41, 4, 18, 6, "TomTom arrow"),
    box(41.1, 28, 17.7, 31, "HUD box<br>Cooldown Manager<br>x 0, y -40<br>(keep clear)", "border-color:#FF7800;color:#FFD100"),
    box(1, 62, 26, 26, "Prat chat"),
    box(31, 78, 38, 18, "Bartender4 bars 1-3<br>(bars 4-5 on mouseover)"),
    box(73.8, 78.4, 26, 13, "Details! x2<br>250 x 141 each"),
    box(73.8, 91.8, 26, 3.4, "XP / Rep / Guild tray", "border-color:#FF7800;font-size:10px"),
]) + "</div>"
parts = []
parts.append(f"""<div class='cover'><h1>Schizzle's Warrior &mdash; WoW Forever launch manual</h1>
<p class='sub'>By Jon Shaw (Schizzle) &middot; for WoW Forever 1.60.1 (build 70755, Interface 16001) &middot; written Nov 3 2026</p>
<p><b>WoW Forever opens Wednesday Nov 4 at 6 PM EST</b> (3 PM PST), after maintenance from about 1 PM EST. Raids (Barrow Deeps, Hyjal Summit, Onyxia's Lair) open Dec 9.</p>
<span class='tag'>Schizzle's Warrior Setup F1</span><span class='tag'>XP &amp; Rep Tray</span><span class='tag'>Cooldown Manager</span><span class='tag'>Auctionator list</span><span class='tag'>TSM plan</span>
<div class='note'><b>Why a manual and not one big import:</b> WeakAuras and TradeSkillMaster have no WoW Forever build yet, so the rotation aura and TSM imports can't be used on day one. The helper addon does everything that can be automated; this sheet covers the rest, in order.</div></div>""")
parts.append("<h2>1. Put the addons in the Forever folder</h2>")
parts.append("<ol><li>Close WoW and Battle.net.</li><li>Open <code>C:\\Program Files (x86)\\World of Warcraft\\_forever_\\Interface\\AddOns\\</code>. Copy it somewhere safe first.</li><li>Copy in the Forever-ready addons (table below) and the <code>SchizzlesWarriorSetup</code> folder from the repo's <b>WoW Forever</b> folder.</li><li>Leave <b>TradeSkillMaster</b>, <b>TSM AppHelper</b>, <b>WeakAuras</b> and <b>WagoAppCompanion</b> off on Forever.</li></ol>")
parts.append(table(["Job", "Forever-ready addons"], [
    ["Bars, frames, chat, map", "Bartender4 4.18.4 &middot; BetterBlizzFrames v2.2.0e &middot; Prat 3.9.115 &middot; SexyMap v12.1.4 &middot; MinimapButtonButton &middot; MoveAny (Forever)"],
    ["Questing", "Questie 12.5.0 &middot; RXPGuides v4.11.30 &middot; TomTom v4.4.0 &middot; GatherMate2 &middot; HandyNotes &middot; RareScanner (Forever)"],
    ["Combat", "Details! (Camelot) &middot; BigWigs v427.8 &middot; GTFO 6.12.2 &middot; BetterPersonalResourceDisplay &middot; BetterBlizzMarkers &middot; Platynator"],
    ["Bags, gold, alts", "Baganator 839 + Syndicator &middot; Auctionator 341 &middot; Altoholic + DataStore &middot; Pawn (Forever)"],
    ["Comfort", "Leatrix Plus (Forever) &middot; Speedy AutoLoot &middot; BetterFishing &middot; WowSimsExporter"],
    ["Error catching", "BugSack + !BugGrabber &middot; BugTabs"],
]))
parts.append("<h2>2. First login: one click</h2>")
parts.append("<ol><li>At the character list, click <b>AddOns</b>. Nothing you rely on should say <i>Out of date</i>.</li><li>Log in on the Warrior. Click <b>Yes</b> on <i>Set up Schizzle's Warrior on this character?</i></li><li>Read the chat lines (one per piece: <i>done</i> or <i>skipped</i>), then click <b>Reload</b>. If the button does nothing, type <code>/reload</code>.</li></ol>")
parts.append(table(["Piece", "What it sets", "Command"], [
    ["Console variables", "auto loot, cast on key down, max camera zoom, enemy nameplates, target of target, full tooltips, <b>Cooldown Manager on</b>", "<code>/schizzle cvars</code>"],
    ["Keybinds", "Bar 3 on Q E R F T G Y + mouse buttons; Shift versions on Bar 2; A/D strafe (account-wide)", "<code>/schizzle binds</code>"],
    ["Bartender4", "three centred bars, bars 4-5 on mouseover, Fira hotkeys", "<code>/schizzle bars</code>"],
    ["Prat 3.0", "Fira chat, short channel names, bronze timestamps", "<code>/schizzle chat</code>"],
    ["SexyMap", "square 1.5x minimap, top right, bronze border", "<code>/schizzle map</code>"],
    ["Questie / GatherMate2 / TomTom", "smaller icons, darker tracker, arrow at the top", "<code>/schizzle quests</code> &middot; <code>gather</code> &middot; <code>tomtom</code>"],
    ["Details!", "the Schizzle's Warrior meter profile, imported and switched to", "<code>/schizzle details</code>"],
    ["XP &amp; Rep Tray", "XP, watched rep and guild rep bars under the meters", "<code>/schizzle tray</code> (on/off)"],
]))
parts.append("<div class='note'>Every addon gets a new <b>Schizzle's Warrior</b> profile; old profiles are kept. Run any command again to put that addon back. In combat the helper waits.</div>")
parts.append("<h2>3. Where everything sits</h2>")
parts.append(screen)
parts.append("<p>The orange box in the middle is kept clear for cooldowns. Unit frames stay at Blizzard's spots. The tray is 500 x 34 px, 4 px from the right and bottom edges; the two Details! windows sit right on top of it.</p>")
parts.append("<h2>4. Cooldown Manager (instead of the rotation aura)</h2>")
parts.append("<ol><li><b>Options &gt; Gameplay &gt; Advanced Options</b> &gt; <b>Cooldown Manager</b>: check <i>Enable Cooldown Manager</i> is ticked.</li><li>Open its settings button. <b>Essential</b>: Overpower, Execute, Revenge, Mortal Strike / Bloodthirst / Shield Slam, Whirlwind, Victory Rush. <b>Utility</b>: Charge, Intercept, Pummel / Shield Bash, Bloodrage, Berserker Rage, Shield Wall, Retaliation, Recklessness.</li><li>Track <b>Rend</b>, <b>Battle Shout</b>, <b>Sunder Armor</b> and <b>Demoralizing Shout</b> on the buff/debuff bars.</li><li><b>Edit Mode</b>: drag Essential to the centre, slightly low (x 0, y -40); Utility just under it, buffs just above.</li></ol>")
parts.append("<div class='note'>It shows a spell once whatever its rank, and it doesn't pick the next spell for you. The priorities below do that job.</div>")
parts.append("<h2>5. Warrior quick reference</h2>")
parts.append(table(["Spec", "Priority"], [
    ["1-10", "Battle Shout &rarr; Charge &rarr; Rend &rarr; Heroic Strike with spare rage; Thunder Clap on 2+; Hamstring runners"],
    ["Arms (leveling pick)", "Rend &rarr; Overpower whenever lit (Bloodthrill lights it more often) &rarr; Mortal Strike &rarr; Slam (15 s cd) &rarr; Execute &lt;20% &rarr; Victory Rush after kills; Sweeping Strikes + Cleave on packs"],
    ["Fury", "Berserker Stance &rarr; Bloodthirst (needs Death Wish in the tree now) &rarr; Whirlwind &rarr; Execute &lt;20% &rarr; Heroic Strike/Cleave with spare rage; Death Wish, Recklessness, Reckless Swings for big pulls"],
    ["Protection", "Defensive Stance (+80% threat) &rarr; Shield Slam &rarr; Revenge &rarr; Sunder; Thunder Clap + Demo Shout on packs; Shield Block, Shield Wall, Last Stand when it hurts"],
]))
parts.append(table(["Level", "Don't miss"], [
    ["10", "Defensive Stance quest; Taunt, Sunder Armor, Bloodrage. Learn First Aid."],
    ["20", "Victory Rush (new), Cleave, Slam, Retaliation, Dual Wield"],
    ["25", "Legacy panel: take <b>Talented</b> first (talent points from level 5, every character)"],
    ["30", "<b>The Affray</b> (Klannoc Macleod, The Barrens, 10-min timer): Berserker Stance + Intercept; Berserker Rage"],
    ["36 / 38", "Whirlwind (Whirlwind Weapon chain: Bath'rah, Alterac) / Pummel"],
    ["40 / 50", "Plate, riding, dual spec, Mortal Strike / Recklessness"],
]))
parts.append("<h3>Macros (Esc &gt; Macros; names, so they always use your highest rank)</h3>")
parts.append(table(["Button", "Macro"], [
    ["Charge / Intercept", code("#showtooltip\n/cast [nocombat,nostance:1] Battle Stance; [nocombat] Charge; [nostance:3] Berserker Stance; Intercept")],
    ["Overpower", code("#showtooltip Overpower\n/cast [nostance:1] Battle Stance; Overpower")],
    ["Interrupt", code("#showtooltip\n/cast [stance:3] Pummel; [equipped:Shields] Shield Bash; Berserker Stance")],
    ["Fear break", code("#showtooltip Berserker Rage\n/cast [nostance:3] Berserker Stance; Berserker Rage")],
    ["Heroic Strike", code("#showtooltip Heroic Strike\n/startattack\n/cast Heroic Strike")],
]))
parts.append("<h2>6. Gold: a brand-new economy</h2>")
parts.append("<p>TSM has no Forever build and no Forever market data, so <b>Auctionator</b> runs the auction house for now. Import the <b>Schizzle's Warrior Leveling</b> shopping list (repo: WoW Forever &gt; Schizzle's Warrior &gt; AddOns &gt; Auctionator) in the <b>Shopping</b> tab &gt; <b>Import</b>, and scan once a day.</p>")
parts.append("<p>When TSM updates, make these custom sources (they never use DBMarket):</p>")
parts.append(table(["Source", "Formula"], [
    ["szfloor", "<code>max(VendorSell * 1.25, 1c)</code>"],
    ["szseen", "<code>first(AtrValue, DBMinBuyout, DBRegionMarketAvg)</code>"],
    ["szvalue", "<code>first(szseen, Crafting, VendorSell * 4)</code>"],
    ["szmat", "<code>first(AtrValue, DBMinBuyout, VendorBuy, VendorSell * 4)</code>"],
    ["szcraft / szmin", "<code>first(Crafting, szvalue)</code> / <code>max(szfloor, szcraft * 1.1)</code>"],
    ["szmax / szsnipe", "<code>max(szvalue * 2, szfloor * 3)</code> / <code>max(szvalue * 0.6, szfloor)</code>"],
]))
parts.append("<ul><li>First week: sell cloth, copper, herbs, light leather and bags while everyone levels.</li><li>Post 2 h or 8 h while prices move; rescan before posting.</li><li>Copper prices are allowed: undercut by 1c.</li><li>No Pet Cages on Forever: only companions that are still items can be sold.</li><li>The full group tree (all professions, dungeon BoEs by bracket, raid BoEs from Dec 9, companions) and operations are in the repo: WoW Forever &gt; Schizzle's TSM.</li></ul>")
parts.append("<h2>7. Not ready on day one</h2>")
parts.append(table(["Addon / app", "Status", "Do"], [
    ["TradeSkillMaster + AppHelper", "no 16001 build", "Use Auctionator; TSM plan is ready"],
    ["TSM Desktop App", "no Forever data", "Nothing yet"],
    ["WeakAuras", "no Forever build", "Cooldown Manager + the tray built into the helper"],
    ["Wago App / WagoAppCompanion", "no Forever support", "Leave off"],
    ["LittleWigs", "no Forever file", "BigWigs covers bosses"],
]))
parts.append("<h2>8. Troubleshooting</h2>")
parts.append(table(["Problem", "Fix"], [
    ["No setup prompt", "Type <code>/schizzle all</code>. With the private local file, only the named character is asked."],
    ["A piece says <i>skipped</i>", "That addon isn't installed or enabled. Install it, then run its command."],
    ["A console variable says skipped", "Forever doesn't have that setting; nothing to do."],
    ["Reload button does nothing", "Type <code>/reload</code>."],
    ["Keys don't work", "Esc &gt; Key Bindings: untick <i>Character Specific Keybindings</i>, then <code>/schizzle binds</code>."],
    ["Bar 1 empty after a stance swap", "Normal: drag abilities onto bar 1 once in each stance."],
    ["Tray missing", "<code>/schizzle tray</code>. The XP bar hides at 60; the rep bar needs <i>Show as Experience Bar</i>."],
    ["Red errors", "Click the BugSack minimap icon; note the first error and the addon named in it."],
    ["An addon \"Out of date\"", "Don't tick <i>Load out of date AddOns</i>; update it from its Forever file."],
]))
parts.append("<h2>9. In-game test list</h2>")
parts.append(checks([
    "<code>/schizzle</code> lists every command; nothing installed says <i>(not loaded)</i>",
    "<code>/schizzle cvars</code>: seven set, none skipped; abilities fire on key down",
    "<code>/schizzle details</code>: two meter windows side by side, bottom right",
    "Tray: XP bar with level and rested %, hover tooltip, green quest XP grows on a completed quest",
    "Tray: watched faction shows as the second bar; guild bar in a guild with guild rep",
    "<code>/schizzle tray</code> hides and shows it",
    "Fira Sans Condensed in the tray, Bartender4 hotkeys and chat",
    "Q E R F T G Y + mouse buttons fire Bar 3; Shift versions Bar 2; A/D strafe",
    "Bar 1 swaps with stances from level 10",
    "BugSack stays quiet through a fight, a quest turn-in and a level-up",
    "Cooldown Manager shows tracked spells in combat",
    "Auctionator list imports and searches",
]))
parts.append("<p class='foot'>Sources (Nov 3 2026): Blizzard news (launch Nov 4, raid overview), Blizzard forums Beta Development Notes updated Nov 2, wowforever.be Warrior leveling guide, foreverguide.app, endgametools.com talents and spellbook, patchmymain.com and 0hp.com Warrior changes, CurseForge file lists, Gethe/wow-ui-source <i>forever</i> branch. Repo: github.com/shawj317/Schizzles-World-of-Warcraft-Repo &middot; MIT with attribution &middot; Jon Shaw (Schizzle).</p>")
doc = f"<!doctype html><html><head><meta charset='utf-8'><title>Schizzle's Warrior - WoW Forever launch manual</title><style>{css}</style></head><body><table class='page'><thead><tr><td></td></tr></thead><tfoot><tr><td></td></tr></tfoot><tbody><tr><td>{''.join(parts)}</td></tr></tbody></table></body></html>"
open(os.path.join(OUT, "manual.html"), "w").write(doc)
