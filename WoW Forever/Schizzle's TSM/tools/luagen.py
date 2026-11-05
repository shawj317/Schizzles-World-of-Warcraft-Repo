def lua(v):
    if isinstance(v,bool): return 'true' if v else 'false'
    if isinstance(v,(int,float)): return repr(v)
    if isinstance(v,str):
        return '"'+v.replace('\\','\\\\').replace('"','\\"').replace('\n','\\n')+'"'
    if isinstance(v,list): return '{'+','.join(lua(x) for x in v)+'}'
    if isinstance(v,dict):
        parts=[]
        for k,x in v.items():
            parts.append(f'[{lua(k)}]={lua(x)}')
        return '{'+','.join(parts)+'}'
    raise TypeError(v)
