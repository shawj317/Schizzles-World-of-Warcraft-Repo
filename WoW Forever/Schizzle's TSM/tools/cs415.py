import sys
import os
sys.path.insert(0,os.path.dirname(os.path.abspath(__file__)))
import lupa.lua51 as LL
R=os.environ.get('TSM_SRC','/workspace/tsm415/TradeSkillMaster').rstrip('/')+'/'
PRE=open(os.path.join(os.path.dirname(os.path.abspath(__file__)),'wowstubs.lua')).read()
PRE=PRE.replace('WOW_PROJECT_ID=19','WOW_PROJECT_CAMELOT=99; WOW_PROJECT_ID=99').replace('v4.14.54','v4.15.2')
import re as _re
UTIL=[x.replace('\\','/') for x in _re.findall(r'Script file="([^"]+)"',open(R+'LibTSMUtil/LibTSMUtil.xml').read())]
TYPES=['Source/Core.lua','Source/Item/BonusIds.lua','Source/Item/ItemString.lua','Source/Item/Conversion.lua']+['Source/CustomString/Internal/%s.lua'%x for x in 'Types Utils Sources Tokenizer TokenProcessor Optimizer AST CodeGen Object'.split()]+['Source/CustomString/CustomString.lua','Source/Group/Internal/Path.lua']
def load():
    L=LL.LuaRuntime(unpack_returned_tuples=True, encoding=None)
    L.execute(b'strmatch=string.match strsub=string.sub strfind=string.find gsub=string.gsub format=string.format strbyte=string.byte strchar=string.char tinsert=table.insert')
    L.execute(PRE.encode())
    ld=L.eval(b'function(src,name) local f,e=loadstring(src,name); if not f then error(e) end; return f("TradeSkillMaster",ADDON) end')
    for f in ['LibTSMClass/LibStub/LibStub.lua','LibTSMUtil/EmbeddedLibs/LibDeflate/LibDeflate.lua','LibTSMUtil/EmbeddedLibs/LibSerialize/LibSerialize.lua','LibTSMClass/LibTSMClass.lua','LibBonusId/LibBonusId.lua','LibTSMCore/Source/Core.lua']+['LibTSMUtil/'+x for x in UTIL]:
        ld(open(R+f,'rb').read(), f.encode())
    # stub components the Types core depends on
    L.execute(b'for _,n in ipairs({"LibTSMDatabase","LibTSMReactive"}) do ADDON[n]=ADDON.LibTSMCore.NewComponent(n) end')
    for f in ['Core','Convert/Transform','Convert/VendorTrade','Destroy/Disenchant','Destroy/Mill','Destroy/Prospect']:
        ld(open(R+'LibTSMData/'+f+'.lua','rb').read(), f.encode())
    for f in ['LibTSMTypes/'+x for x in TYPES]:
        ld(open(R+f,'rb').read(), f.encode())
    L.execute(b'ADDON.LibTSMCore.LoadAll()')
    return L
if __name__=='__main__':
    L=load(); print('loaded')
