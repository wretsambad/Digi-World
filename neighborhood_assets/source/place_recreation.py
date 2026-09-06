from pathlib import Path
import re,math,json,shutil
P=Path(__file__).resolve().parents[2];A=P/'neighborhood_assets';scene=A/'preview/neighborhood_filled.tscn'
B=A/'source/before_recreation';B.mkdir(exist_ok=True)
if not (B/scene.name).exists():shutil.copy2(scene,B/scene.name)
original=(B/scene.name).read_text();pieces=re.split(r'(?=^\[)',original,flags=re.M)
removed=[];kept=[]
for s in pieces:
    if s.startswith('[node ') and any(k in s.split('\n')[0] for k in ['Park_PlaceHolder','Basketball_PlaceHolder','Soccer_Goal_PlaceHolder']):removed.append(s.split('\n')[0]);continue
    if s.startswith('[sub_resource ') and any('id="'+v+'"' in s for v in ['BoxMesh_nr1sk','BoxMesh_ymsu0','BoxMesh_wav6d']):continue
    kept.append(s)
pieces=kept
moved={'GardenTrees_tree_oak_large_1026':(39.2,0,64),'GardenTrees_tree_oak_large_1010':(-39,0,64),'TreeBelt_tree_poplar_large_914':(69.8,0,-32),'TreeBelt_tree_oak_large_912':(73,0,-40)}
for i,s in enumerate(pieces):
    m=re.match(r'\[node name="([^"]+)"',s)
    if m and m[1] in moved:
        t=re.search(r'transform = Transform3D\(([^)]+)\)',s);v=t[1].split(',');v[-3:]=[str(x) for x in moved[m[1]]]
        pieces[i]=s[:t.start(1)]+','.join(v)+s[t.end(1):]
    elif m and m[1]=='Fill_hedge_straight_184':
        pieces[i]=s.replace('Transform3D(7.6, 0, 0, 0, 7.8, 0, 0, 0, 7, 49.4, 0.025, -59.4)','Transform3D(3.8, 0, 0, 0, 7.8, 0, 0, 0, 7, 50.4, 0.025, -59.4)')
paths={}
for s in pieces:
    if s.startswith('[ext_resource'):
        paths[re.search(r'path="([^"]+)"',s)[1]]=re.search(r'\bid="([^"]+)"',s)[1]
resources=[];nodes=[];items=[]
groups={'BasketballCourt':(23.501232,0,64.36063),'WillowPark':(-26.88798,0,63.20904),'SoccerArea':(56.00514,0,-40.214054)}
def transform(x,y,z,angle,scale):
    sx,sy,sz=scale;c=math.cos(math.radians(angle));s=math.sin(math.radians(angle))
    return f'Transform3D({c*sx:.6f},0,{s*sz:.6f},0,{sy:.6f},0,{-s*sx:.6f},0,{c*sz:.6f},{x:.6f},{y:.6f},{z:.6f})'
def add(group,name,x,z,y=.035,angle=0,scale=1,folder='recreation_models'):
    if isinstance(scale,(float,int)):scale=(scale,)*3
    resource=f'res://neighborhood_assets/{folder}/{name}.glb'
    if resource not in paths:
        id='recreation_'+str(len(resources));paths[resource]=id;resources.append(f'[ext_resource type="PackedScene" path="{resource}" id="{id}"]\n\n')
    node=f'{name}_{len(items):03}'
    nodes.append(f'[node name="{node}" parent="ExistingNeighborhood/{group}" instance=ExtResource("{paths[resource]}" )]\ntransform = {transform(x,y,z,angle,scale)}\n\n'.replace('" )','")'))
    items.append(dict(group=group,name=name,node=node,position=[x,y,z],angle=angle,scale=scale))
def group(name):
    x,y,z=groups[name];nodes.append(f'[node name="{name}" type="Node3D" parent="ExistingNeighborhood"]\nposition = Vector3({x},{y},{z})\n\n')
def old(g,name,x,z,y=.035,angle=0,scale=5):add(g,name,x,z,y,angle,scale,'models')
def path(g,x,z,length,angle=0):add(g,'path_tile',x,z,.095,angle,(1,1,length))

g='BasketballCourt';group(g)
add(g,'basketball_court',0,0,.045,90)
for x,rot in [(-7.9,90),(7.9,-90)]:add(g,'basketball_hoop',x,0,.045,rot)
add(g,'basketball',-3,-1.3,.08)
for x in [-7.5,-4.5,-1.5,1.5,4.5,7.5]:add(g,'sports_fence_panel',x,6.25)
for x in [-9.25,9.25]:
    for z in [-4.5,4.5]:add(g,'sports_fence_panel',x,z,angle=90)
path(g,-13.48,-1.8,8.95,90)
old(g,'bench',-3,-7.3,angle=180);old(g,'bench',3,-7.3,angle=180)
add(g,'drinking_fountain',-6.6,-7.35)
old(g,'litter_bin',6.6,-7.25)
add(g,'court_sign',-10.1,-5.5,angle=-90)
for z in [-3.15,-.45]:add(g,'park_bollard',-17.5,z)

g='WillowPark';group(g)
add(g,'park_path_loop',0,0,.06);add(g,'playground_surface',0,0,.045)
add(g,'play_tower_slide',-2,0,.095)
add(g,'swing_set',2.4,-1.6,.095,90)
add(g,'sandbox',2.3,2.55,.095)
for x in [-5.5,5.5]:add(g,'picnic_table',x,-3.8,.045,90)
old(g,'bench',-5.6,3.8,angle=-90);old(g,'bench',5.6,4,angle=90)
old(g,'flowerbed',-5.5,-5.05,scale=4);old(g,'flowerbed',5.5,-5.05,scale=4)
path(g,15.16,0,12.32,90)
add(g,'park_sign',11.5,-1.5,angle=90)
old(g,'litter_bin',8.8,-2);old(g,'recycling_bin',8.8,-3)
add(g,'drinking_fountain',7.5,2)
old(g,'bicycle_rack',11,3.3,angle=90);old(g,'bicycle',11.1,3.5,angle=90)
for z in [-1.3,1.3]:add(g,'park_bollard',20.5,z)
for x,z in [(-6.5,-4.6),(-6.5,4.7),(6.5,-4.5),(6.5,4.7)]:old(g,'shrub_round',x,z,scale=4.5)

g='SoccerArea';group(g)
add(g,'soccer_pitch',0,0,.045)
for z,rot in [(-8,0),(8,180)]:add(g,'soccer_goal',0,z,.065,rot)
add(g,'soccer_ball',.7,-.4,.065)
for z in [-9.6,9.6]:
    for x in [-4.5,-1.5,1.5,4.5]:add(g,'sports_fence_panel',x,z)
old(g,'bench',-7.1,3.4,angle=90);old(g,'bench',-7.1,6,angle=90)
path(g,-7.8,-10.8,21.6);path(g,-6.8,0,2,90)
add(g,'soccer_sign',-6.2,-11.4)
old(g,'litter_bin',-7.1,8.2);add(g,'drinking_fountain',-7.1,-2.1)

index=next(i for i,s in enumerate(pieces) if s.startswith('[sub_resource') or s.startswith('[node'))
pieces[index:index]=resources
index=next(i for i,s in enumerate(pieces) if s.startswith('[node name="WorldEnvironment"'))
pieces[index:index]=nodes
scene.write_text(''.join(pieces))
(A/'recreation_placement.json').write_text(json.dumps(dict(scene=str(scene),groups=groups,objects=items,moved_trees=moved,adjusted_hedge='Fill_hedge_straight_184',removed_placeholders=removed),indent=2))
print('PLACED',len(items),'separate models in three local Node3D groups; replaced three placeholders, moved four trees; other original blocks retained.')
