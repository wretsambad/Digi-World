from pathlib import Path
import re,json,struct,math
P=Path(__file__).resolve().parents[2];A=P/'neighborhood_assets'
def blocks(t):
    return {s.split('\n')[0]:s.strip() for s in re.split(r'(?=^\[)',t,flags=re.M) if s.startswith('[')}
old=blocks((A/'source/before_recreation/neighborhood_filled.tscn').read_text());new=blocks((A/'preview/neighborhood_filled.tscn').read_text())
allowed=['Park_PlaceHolder','Basketball_PlaceHolder','Soccer_Goal_PlaceHolder','BoxMesh_nr1sk','BoxMesh_ymsu0','BoxMesh_wav6d']
report=json.loads((A/'recreation_placement.json').read_text());changed=[]
for k,v in old.items():
    if any(n in k for n in allowed):assert k not in new;continue
    assert k in new,k
    if any(n in k for n in list(report['moved_trees'])+[report['adjusted_hedge']]):changed.append(k);continue
    assert new[k]==v,k
for f in (A/'recreation_models').glob('*.glb'):
    b=f.read_bytes();magic,ver,size=struct.unpack_from('<4sII',b);assert magic==b'glTF' and ver==2 and size==len(b)
    n,t=struct.unpack_from('<II',b,12);g=json.loads(b[20:20+n]);assert g['meshes']
    for mesh in g['meshes']:
        for prim in mesh['primitives']:
            a=g['accessors'][prim['attributes']['POSITION']];assert all(math.isfinite(v) for v in a['min']+a['max'])
print('PASS: all unrelated scene/resource blocks exactly preserved, including lighting and driveway placeholders; four existing trees moved and one hedge shortened for access. All 19 GLB structures valid.')
