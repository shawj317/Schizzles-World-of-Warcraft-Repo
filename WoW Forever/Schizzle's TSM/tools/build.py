"""Schizzle's Forever TSM: build the Mining and Blacksmithing TSM 4 group imports.

Inputs: wago.tools db2 CSVs for WoW Forever (product wowf, build 1.60.1.70790) in db/,
and the TSM v4.15.2 source (for LibSerialize/LibDeflate). Output: out/*.txt, out/items.json.
"""
import sys, json, zlib
import os
HERE = os.path.dirname(os.path.abspath(__file__)); sys.path.insert(0, HERE)
from load import IS, IT, crafts, sod
import lupa.lua51 as LL
from luagen import lua

TSM = os.environ.get('TSM_SRC', '/workspace/tsm415/TradeSkillMaster').rstrip('/') + '/'
MODULES = ['Auctioning', 'Crafting', 'Shopping', 'Sniper', 'Warehousing']

# ---------- items (every ID checked against Forever's ItemSparse below) ----------
MINING = {
  'Ore': [2770, 2771, 2775, 2772, 2776, 3858, 7911, 10620, 11370, 18562, 248815, 249426],
  'Stone': [2835, 2836, 2838, 7912, 12365],
  'Gems`Low (Copper-Tin)': [774, 818, 1210, 1206, 1705],
  'Gems`Mid (Iron-Mithril)': [1529, 3864, 7909, 7910],
  'Gems`High (Thorium-Dark Iron)': [12361, 12799, 12364, 12800, 12363, 9262, 248820],
  'Decor': [279960, 279948, 279952],
}
BS_FIXED = {
  'Bars': [2840, 3576, 2841, 2842, 3575, 3577, 3859, 3860, 6037, 11371, 12359, 12360, 12655, 17771, 249726, 251291, 251290],
  'Stones': [3470, 3478, 3486, 7966, 12644],
  'Sharpening & Weightstones': [2862, 2863, 2871, 7964, 12404, 18262, 3239, 3240, 3241, 7965, 12643],
  'Parts': [6041, 6042, 6043, 6217, 6338, 7071, 7967, 7969, 9060, 11128, 11144, 12645, 15869, 15870, 15871, 15872, 16206],
  'Decor': [279944, 279955, 279988],
}
FOREVER_NEW = lambda i: i >= 239000  # IDs added for Forever (not in the 1.12 / SoD ranges)

def bs_items():
    groups = {k: list(v) for k, v in BS_FIXED.items()}
    fixed = {i for v in BS_FIXED.values() for i in v}
    groups['Armor'] = []; groups['Weapons'] = []; groups['Plans'] = []
    for c in crafts('164'):
        if sod(c['spell']):
            continue
        for it in c['made']:
            if it not in IS or int(it) in fixed:
                continue
            cls = IT[it]['ClassID']; b = IS[it]['Bonding']
            if b == '1':
                continue  # BoP, can't be sold
            if cls == '4': groups['Armor'].append(int(it))
            elif cls == '2': groups['Weapons'].append(int(it))
            else: raise SystemExit('unclassified BS output %s %s' % (it, IS[it]['Display_lang']))
    for i, r in IS.items():
        it = IT.get(i)
        if it and it['ClassID'] == '9' and it['SubclassID'] == '4' and r['Bonding'] != '1' and not (200000 <= int(i) < 239000):
            groups['Plans'].append(int(i))
    return {k: sorted(set(v)) for k, v in groups.items()}

# ---------- operations (TSM 4.15 schemas, Forever client) ----------
COMMON = {'ignorePlayer': {}, 'ignoreFactionrealm': {}, 'relationships': {}}
def auc(**kw):
    d = dict(ignoreLowDuration=0, postCap='50000', keepQuantity='0', maxExpires='0', duration=2, bidPercent=1,
             undercut='0c', minPrice='szmin', normalPrice='max(szvalue, szmin)', maxPrice='szmax', priceReset='none',
             aboveMax='maxPrice', cancelUndercut=True, cancelRepost=True, cancelRepostThreshold='5s')
    d.update(kw); d.update(COMMON); return d
OPS = {
  'Auctioning': {
    'SZ Commodity': auc(),
    'SZ Gear': auc(postCap='1', duration=3, minPrice='max(szfloor, szvalue * 0.5)', normalPrice='szvalue', cancelRepostThreshold='50s'),
  },
  'Crafting': {'SZ Craft': dict(minRestock='1', maxRestock='3', minProfit='szcraft * 0.1', craftPriceMethod='szvalue', **COMMON)},
  'Shopping': {
    'SZ Buy': dict(restockQuantity='0', maxPrice='szmat', showAboveMaxPrice=True,
                   restockSources={'alts': False, 'auctions': False, 'bank': False, 'guild': False}, **COMMON),
    'SZ Buy Gear': dict(restockQuantity='0', maxPrice='szvalue * 0.9', showAboveMaxPrice=True,
                        restockSources={'alts': False, 'auctions': False, 'bank': False, 'guild': False}, **COMMON),
  },
  'Sniper': {'SZ Snipe': dict(belowPrice='szsnipe', **COMMON)},
  'Warehousing': {'SZ Bank': dict(moveQuantity='0', keepBagQuantity='20', keepBankQuantity='0', restockQuantity='0',
                                  stackSize='0', restockKeepBankQuantity='0', restockStackSize='0', **COMMON)},
}
ROOT_OPS = {'Auctioning': ['SZ Commodity'], 'Crafting': ['SZ Craft'], 'Shopping': ['SZ Buy'], 'Sniper': ['SZ Snipe'], 'Warehousing': ['SZ Bank']}
GEAR_OPS = {'Auctioning': ['SZ Gear'], 'Shopping': ['SZ Buy Gear']}
GEAR_GROUPS = {'Armor', 'Weapons', 'Plans', 'Decor'}

def gop(over):
    t = {}
    for m in MODULES:
        if m in over:
            d = {i + 1: n for i, n in enumerate(over[m])}; d['override'] = True; t[m] = d
        else:
            t[m] = {}
    return t

def build(name, sub):
    items, groups, go = {}, {'': True}, {'': gop(ROOT_OPS)}
    for path, ids in sub.items():
        parts = path.split('`')
        for i in range(1, len(parts) + 1):
            p = '`'.join(parts[:i]); groups[p] = True; go.setdefault(p, gop({}))
        if parts[0] in GEAR_GROUPS:
            go[parts[0]] = gop(GEAR_OPS)
        for i in ids:
            k = 'i:%d' % i
            assert str(i) in IS, ('not in Forever ItemSparse', i)
            assert k not in items, ('duplicate', i)
            items[k] = path
    used = {m: {} for m in MODULES}
    for t in go.values():
        for m, lst in t.items():
            for k, n in lst.items():
                if k != 'override': used[m][n] = OPS[m][n]
    return items, groups, go, used

def encode(name, items, groups, go, ops):
    L = LL.LuaRuntime(unpack_returned_tuples=True, encoding=None)
    L.execute(b'strmatch=string.match strsub=string.sub strfind=string.find gsub=string.gsub format=string.format strbyte=string.byte strchar=string.char tinsert=table.insert wipe=function(t) for k in pairs(t) do t[k]=nil end return t end')
    for f in ['LibTSMClass/LibStub/LibStub.lua', 'LibTSMUtil/EmbeddedLibs/LibSerialize/LibSerialize.lua', 'LibTSMUtil/EmbeddedLibs/LibDeflate/LibDeflate.lua']:
        L.execute(open(TSM + f, 'rb').read())
    L.execute(('ARGS={%s,%s,%s,%s,%s,{}}' % (lua(name), lua(items), lua(groups), lua(go), lua(ops))).encode())
    ser = L.execute(b'return LibStub("LibSerialize"):SerializeEx({stable=true,errorOnUnserializableType=true}, "TSM_EXPORT", 1, ARGS[1], ARGS[2], ARGS[3], ARGS[4], ARGS[5], ARGS[6])')
    co = zlib.compressobj(9, zlib.DEFLATED, -15); comp = co.compress(ser) + co.flush()  # raw DEFLATE, as C_EncodingUtil.CompressString
    return L.eval(b'function(s) return LibStub("LibDeflate"):EncodeForPrint(s) end')(comp).decode()

def plain(name, items, sub):
    # legacy TSM group list: group:<path>,i:1,i:2,... (fallback, no operations)
    out = []
    for path, ids in sub.items():
        out.append('group:%s`%s,' % (name, path) + ','.join('i:%d' % i for i in ids))
    return ','.join(out)

OUT = os.path.join(HERE, '..', 'groups')
if __name__ == '__main__':
    BS = bs_items()
    res = {}
    for key, name, sub in [('mining', "Schizzle's Forever Mining", MINING), ('blacksmithing', "Schizzle's Forever Blacksmithing", BS)]:
        items, groups, go, ops = build(name, sub)
        s = encode(name, items, groups, go, ops)
        open(os.path.join(OUT, '%s.txt' % key), 'w').write(s + '\n')
        open(os.path.join(OUT, '%s-items-only.txt' % key), 'w').write(plain(name, items, sub) + '\n')
        res[key] = {'name': name, 'groups': {p: [{'id': i, 'name': IS[str(i)]['Display_lang'], 'forever_new': FOREVER_NEW(i)} for i in ids] for p, ids in sub.items()},
                    'go': go, 'ops': ops, 'len': len(s)}
        print(key, 'items', len(items), 'groups', len(groups), 'chars', len(s), {p: len(v) for p, v in sub.items()})
    mi = {i for v in MINING.values() for i in v}; bi = {i for v in BS.values() for i in v}
    assert not (mi & bi), mi & bi
    json.dump(res, open(os.path.join(HERE, 'items.json'), 'w'), indent=1)
