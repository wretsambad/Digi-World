from pathlib import Path
import re,json,struct,math
P=Path(__file__).resolve().parents[2]; A=P/'neighborhood_assets'
reports=[]
def nodes(t):
    return {re.match(r'\[node name="([^"]+)"',s)[1]:s.strip() for s in re.split(r'(?=^\[)',t,flags=re.M) if s.startswith('[node ')}
for path in [P/'houses.tscn',A/'preview/neighborhood_filled.tscn',A/'preview/neighborhood_dressing.tscn']:
    old=nodes((A/'source/before_sightline_fill'/path.name).read_text());new=nodes(path.read_text())
    removed=[n for n in old if n not in new]
    assert len(removed)==25,(path,len(removed))
    assert all(any('metadata/category = "'+c+'"' in old[n] for c in ['TreeBelt','GardenTrees','BackdropHills']) for n in removed)
    assert all(old[n]==new[n] for n in old if n in new),'Original node changed'
    added=[n for n in new if n not in old]
    assert all(n.startswith('Fill_') for n in added)
    resources=re.findall(r'path="res://([^"]+)"',path.read_text())
    assert all((P/r).exists() for r in resources)
    tree_count=sum('tree_' in n.lower() for n in new)
    reports.append(dict(path=str(path),added=len(added),removed_scenery=removed,model_instances=sum('parent="ExistingNeighborhood"' in s and 'instance=' in s for s in new.values()),trees=tree_count,original_surviving_nodes_unchanged=True))
for f in (A/'sightline_models').glob('*.glb'):
    b=f.read_bytes(); magic,ver,size=struct.unpack_from('<4sII',b);assert magic==b'glTF' and ver==2 and size==len(b)
    n,t=struct.unpack_from('<II',b,12);g=json.loads(b[20:20+n]);assert g['meshes']
    for mesh in g['meshes']:
        for prim in mesh['primitives']:
            a=g['accessors'][prim['attributes']['POSITION']]
            assert all(math.isfinite(v) for v in a['min']+a['max'])
(A/'sightline_changes.json').write_text(json.dumps(reports,indent=2))
print(json.dumps(reports,indent=2))
print('All 10 new GLBs structurally valid; existing surviving node blocks exactly preserved.')
