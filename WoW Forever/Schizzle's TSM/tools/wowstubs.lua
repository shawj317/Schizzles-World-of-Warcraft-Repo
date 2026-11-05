-- Minimal WoW API stubs so TSM v4.15.2 Lua loads outside the game (verification only).

WOW_PROJECT_CLASSIC=2; WOW_PROJECT_BURNING_CRUSADE_CLASSIC=5; WOW_PROJECT_MISTS_CLASSIC=19; WOW_PROJECT_MAINLINE=1; WOW_PROJECT_CAMELOT=99; WOW_PROJECT_ID=99
C_AddOns={GetAddOnMetadata=function() return "v4.15.2" end}
GetTime=function() return os.clock() end; time=os.time; date=os.date; debugstack=function() return "" end; geterrorhandler=function() return print end
strlower=string.lower; strupper=string.upper; strlen=string.len; strrep=string.rep; strtrim=function(s,c) return (s:gsub("^%s+",""):gsub("%s+$","")) end
strsplit=function(sep,s,n) local r={} for p in (s..sep):gmatch("(.-)"..sep:gsub("%p","%%%0")) do r[#r+1]=p end return unpack(r) end
strjoin=function(sep,...) return table.concat({...},sep) end; tremove=table.remove; sort=table.sort; floor=math.floor; ceil=math.ceil; abs=math.abs; min=math.min; max=math.max; mod=math.fmod
tostringall=function(...) local t={...} for i=1,select("#",...) do t[i]=tostring(t[i]) end return unpack(t,1,select("#",...)) end
strlenutf8=string.len; issecretvalue=function() return false end
LARGE_NUMBER_SEPERATOR=","; DECIMAL_SEPERATOR="."; GOLD_AMOUNT_SYMBOL="g"; SILVER_AMOUNT_SYMBOL="s"; COPPER_AMOUNT_SYMBOL="c"
bit={band=function(a,b) local r,m=0,1 while a>0 and b>0 do if a%2==1 and b%2==1 then r=r+m end a=math.floor(a/2) b=math.floor(b/2) m=m*2 end return r end}
CopyTable=function(t) local r={} for k,v in pairs(t) do r[k]=type(v)=="table" and CopyTable(v) or v end return r end
wipe=function(t) for k in pairs(t) do t[k]=nil end return t end
ADDON={}
