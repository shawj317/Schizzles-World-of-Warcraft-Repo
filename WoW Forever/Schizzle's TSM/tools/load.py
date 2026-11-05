import csv,collections,os
D=os.environ.get('FOREVER_DB', os.path.join(os.path.dirname(os.path.abspath(__file__)),'db'))+'/'
def rd(n): return list(csv.DictReader(open(D+n+'.csv',encoding='utf-8')))
IS={r['ID']:r for r in rd('ItemSparse')}
IT={r['ID']:r for r in rd('Item')}
SN={r['ID']:r['Name_lang'] for r in rd('SpellName')}
SE=collections.defaultdict(list)
for r in rd('SpellEffect'): SE[r['SpellID']].append(r)
SR={r['SpellID']:r for r in rd('SpellReagents')}
SLA=rd('SkillLineAbility')
def name(i): r=IS.get(str(i)); return r['Display_lang'] if r else '?'
def reagents(sp):
    r=SR.get(sp); out=[]
    if r:
        for k in range(8):
            if r['Reagent_%d'%k] not in ('0',''): out.append((r['Reagent_%d'%k],int(r['ReagentCount_%d'%k])))
    return out
def crafts(skill):
    res=[]
    for a in SLA:
        if a['SkillLine']!=skill: continue
        sp=a['Spell']
        made=[e['EffectItemType'] for e in SE.get(sp,[]) if e['Effect']=='24' and e['EffectItemType']!='0']
        res.append(dict(spell=sp,spname=SN.get(sp,'?'),rank=int(a['MinSkillLineRank']),acq=a['AcquireMethod'],made=made,reag=reagents(sp)))
    return res
IE={r['ID']:r for r in rd('ItemEffect')}
IXE=collections.defaultdict(list)
for r in rd('ItemXItemEffect'): IXE[r['ItemID']].append(IE.get(r['ItemEffectID']))
def taught(item):
    out=[]
    for e in IXE.get(str(item),[]):
        if not e: continue
        sp=e['SpellID']
        for se in SE.get(sp,[]):
            if se['Effect']=='36' and se['EffectTriggerSpell']!='0': out.append(se['EffectTriggerSpell'])
        if not SE.get(sp): out.append(sp)
    return out
def sod(sp): return 400000<=int(sp)<1230000
