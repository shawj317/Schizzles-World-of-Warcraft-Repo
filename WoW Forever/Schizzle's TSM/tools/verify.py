"""Decode out/*.txt with TSM v4.15.2's real GroupImport.lua + Encoder.lua (Group/Operation stubbed with the 4.15 Forever schemas)."""
import sys, zlib, json
import os
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from cs415 import load, R
from luagen import lua
from formulas import CUSTOM_SOURCES, SETUP_LUA
# Operation schemas copied from LibTSMSystem/Source/Operation/*Operation.lua (v4.15.2, Forever: no stackSize)
S = {
 'Auctioning': dict(ignoreLowDuration='number', postCap='string', keepQuantity='string', maxExpires='string', duration='number', bidPercent='number',
                    undercut='string', minPrice='string', maxPrice='string', normalPrice='string', priceReset='string', aboveMax='string',
                    cancelUndercut='boolean', cancelRepost='boolean', cancelRepostThreshold='string'),
 'Crafting': dict(minRestock='string', maxRestock='string', minProfit='string', craftPriceMethod='string'),
 'Shopping': dict(restockQuantity='string', maxPrice='string', showAboveMaxPrice='boolean', restockSources='table'),
 'Sniper': dict(belowPrice='string'),
 'Vendoring': dict(sellAfterExpired='string', sellSoulbound='boolean', keepQty='string', restockQty='string', restockSources='table', enableBuy='boolean',
                   enableSell='boolean', vsMarketValue='string', vsMaxMarketValue='string', vsDestroyValue='string', vsMaxDestroyValue='string'),
 'Warehousing': dict(moveQuantity='string', keepBagQuantity='string', keepBankQuantity='string', restockQuantity='string', stackSize='string',
                     restockKeepBankQuantity='string', restockStackSize='string'),
 'Mailing': dict(maxQtyEnabled='boolean', maxQty='number', target='string', restock='boolean', restockSources='table', keepQty='number'),
}
for v in S.values(): v.update(ignorePlayer='table', ignoreFactionrealm='table', relationships='table')
MAXN = dict(Auctioning=20, Crafting=1, Shopping=1, Sniper=1, Vendoring=1, Warehousing=12, Mailing=50)

def inflate_raw(b):
    return zlib.decompress(bytes(b), -15)

STUBS = r'''
LOG={}
local Real=ADDON.LibTSMTypes
local Util=Real:From("LibTSMUtil")
local Mods={}
Mods["Util.Log"]={Info=function(...) LOG[#LOG+1]="I "..string.format(...) end, Err=function(...) LOG[#LOG+1]="E "..string.format(...) end, Warn=function(...) LOG[#LOG+1]="W "..string.format(...) end}
Mods["Group"]={GetRootPath=function() return "" end,
  SplitPath=function(p) local a,b=p:match("^(.+)`([^`]+)$"); if a then return a,b elseif p~="" then return "",p else return nil,p end end,
  Exists=function() return false end, IsItemInGroup=function() return false end}
local okP,P=pcall(function() return Real:Include("Group.Path") end)
assert(okP, tostring(P))
Mods["Group"]={GetRootPath=P.GetRoot, SplitPath=P.Split, GetParent=P.GetParent, GetTopLevel=P.GetTopLevel, GetRelativePath=P.GetRelative, JoinPath=P.Join,
  Exists=function() return false end, IsItemInGroup=function() return false end}
Mods["Operation"]={TypeExists=function(t) return SCHEMA[t]~=nil end, IsValidName=function(n) return n==strtrim(n) and n~="" end,
  GetMaxNumber=function(t) return MAXN[t] end, Exists=function() return false end,
  SanitizeSettings=function(t,name,s,silent)
    local reset=false
    -- Auctioning custom sanitize on Forever (defaultZeroUndercut): undercut below 1s becomes "0c"
    for k,v in pairs(s) do local ty=SCHEMA[t][k]; if not ty then s[k]=nil; LOG[#LOG+1]="E extra key "..t.."/"..name.."/"..k elseif type(v)~=ty then reset=true; LOG[#LOG+1]="E type "..t.."/"..name.."/"..k end end
    for k,ty in pairs(SCHEMA[t]) do if s[k]==nil then if ty=="boolean" then s[k]=false elseif not (silent and (k=="ignorePlayer" or k=="ignoreFactionrealm" or k=="relationships")) then reset=true; LOG[#LOG+1]="E missing "..t.."/"..name.."/"..k else s[k]={} end end end
    return reset end}
Mods["Operation"].CustomStringSettingKeyIterator=function(t) local keys={} for k,ty in pairs(SCHEMA[t]) do if ty=="string" and k~="priceReset" and k~="aboveMax" and k~="target" then keys[#keys+1]=k end end local i=0 return function() i=i+1 return keys[i] end end
Mods["GroupOperation"]={}
local Proxy={}
function Proxy:DefineClassType(n) CAP=LibStub("LibTSMClass").DefineClass(n); return CAP end
function Proxy:Include(n) if Mods[n] then return Mods[n] end return Real:Include(n) end
function Proxy:From(lib) local o={}; function o:Include(n) if Mods[n] then return Mods[n] end return Util:Include(n) end; function o:IncludeClassType(n) return Util:IncludeClassType(n) end; return o end
GADDON={LibTSMTypes=Proxy}
'''
def verify(path):
    L = load()
    L.globals().PYINFLATE = lambda s: inflate_raw(s)
    L.execute(b'C_EncodingUtil={DecompressString=function(s) local r=PYINFLATE(s) return r end, CompressString=function() error("unused") end}')
    L.execute(b'strtrim=strtrim or function(s) return (s:gsub("^%s+",""):gsub("%s+$","")) end; wipe=wipe; tremove=table.remove; gmatch=string.gmatch; strrev=string.reverse')
    L.execute(('SCHEMA=%s MAXN=%s' % (lua(S), lua(MAXN))).encode())
    L.execute(b'strtrim=function(s) return (s:gsub("^%s+",""):gsub("%s+$","")) end')
    L.execute(open(R+'EmbeddedLibs/AceSerializer-3.0/AceSerializer-3.0.lua','rb').read())
    L.execute(SETUP_LUA.encode())
    L.execute(('local rem={} CSX.LoadCustomSources(%s, rem) local n=0 for _ in pairs(rem) do n=n+1 end assert(n==0, "custom source rejected")' % lua(CUSTOM_SOURCES)).encode())
    L.execute(STUBS.encode())
    chunk = L.eval(b'function(src) local f,e=loadstring(src,"GroupImport.lua"); if not f then error(e) end; return f("TradeSkillMaster",GADDON) end')
    chunk(open(R + 'LibTSMTypes/Source/ImportExport/GroupImport.lua', 'rb').read())
    L.globals().STR = open(path).read().strip().encode()
    out = L.execute(b'''
local obj=CAP.New("Imported Group", CSX.IsCustomSourceRegistered, {"Mailing"})
local ok,ninv,nchg=obj:Process(STR)
local r={ok=tostring(ok), ninv=ninv, nchg=nchg, log=table.concat(LOG,"\\n")}
if ok then
  local a,b,c,d,e,f=obj:GetTotals(); r.totals=table.concat({a,b,c,d,e,f},","); local cs={} for k in pairs(obj._customSources) do cs[#cs+1]=k end table.sort(cs) r.customSourcesReferenced=table.concat(cs,",")
  local o2=CAP.New("Imported Group", function() return false end, {"Mailing"})
  local gn,items,groups,go,ops,cs,isNew=o2:RawDecode(STR)
  r.gn=gn; r.isNew=tostring(isNew); local n=0 for _ in pairs(items) do n=n+1 end r.nitems=n
  local g=0 for _ in pairs(groups) do g=g+1 end r.ngroups=g
  local und={} for name,st in pairs(ops.Auctioning or {}) do und[#und+1]=name.."="..st.undercut.."/d"..st.duration end r.undercut=table.concat(und,";")
end
return r''')
    return {k.decode(): (v.decode() if isinstance(v, bytes) else v) for k, v in dict(out.items()).items()}

if __name__ == '__main__':
    for f in sys.argv[1:]:
        print(f, json.dumps(verify(f), indent=1))
