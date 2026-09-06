from pathlib import Path
import re,math,json
P=Path(__file__).resolve().parents[2];A=P/'neighborhood_assets';scene=A/'preview/neighborhood_filled.tscn';B=A/'source/before_park_expansion'
original=(B/scene.name).read_text();pieces=re.split(r'(?=^\[)',original,flags=re.M)
record=json.loads((B/'recreation_placement.json').read_text())
def trans(p,angle,scale):
    x,y,z=p;sx,sy,sz=scale;c=math.cos(math.radians(angle));s=math.sin(math.radians(angle))
    return f'Transform3D({c*sx:.6f},0,{s*sz:.6f},0,{sy:.6f},0,{-s*sx:.6f},0,{c*sz:.6f},{x:.6f},{y:.6f},{z:.6f})'
changes={
 'park_path_loop_022':((0,.06,0),0,(1,1,1)),
 'playground_surface_023':((0,.045,0),0,(1.4,1,1.375)),
 'play_tower_slide_024':((-4.2,.095,-1.2),0,(1,1,1)),
 'swing_set_025':((3.8,.095,-2.5),90,(1,1,1)),
 'sandbox_026':((2.2,.095,4),0,(1,1,1)),
 'picnic_table_027':((-8,.045,-5.5),90,(1,1,1)),
 'picnic_table_028':((8,.045,-5.5),90,(1,1,1)),
 'bench_029':((-7.9,.035,5.5),-90,(5,5,5)),
 'bench_030':((7.9,.035,5.5),90,(5,5,5)),
 'flowerbed_031':((-8,.035,-6.7),0,(4,4,4)),
 'flowerbed_032':((8,.035,-6.7),0,(4,4,4)),
 'path_tile_033':((16.669,.095,0),90,(1,1,9.338)),
 'park_sign_034':((13.5,.035,-1.8),90,(1,1,1)),
 'litter_bin_035':((9.25,.035,-2.9),0,(5,5,5)),
 'recycling_bin_036':((9.25,.035,-3.8),0,(5,5,5)),
 'drinking_fountain_037':((9.25,.035,2.5),0,(1,1,1)),
 'bicycle_rack_038':((14,.035,3.6),90,(5,5,5)),
 'bicycle_039':((14.1,.035,3.8),90,(5,5,5)),
 'shrub_round_042':((-9.5,.035,-6.2),0,(4.5,)*3),
 'shrub_round_043':((-9.5,.035,6.2),0,(4.5,)*3),
 'shrub_round_044':((9.5,.035,-6.2),0,(4.5,)*3),
 'shrub_round_045':((9.5,.035,6.2),0,(4.5,)*3),
}
seen=[]
for i,s in enumerate(pieces):
    m=re.match(r'\[node name="([^"]+)"',s)
    if not m:continue
    n=m[1]
    if n in changes and 'parent="ExistingNeighborhood/WillowPark"' in s:
        p,angle,scale=changes[n];s=re.sub(r'transform = Transform3D\([^)]+\)','transform = '+trans(p,angle,scale),s)
        if n=='park_path_loop_022':s=re.sub(r'instance=ExtResource\("[^"]+"\)', 'instance=ExtResource("park_expand_path")',s)
        seen.append(n)
    if n=='GardenTrees_tree_oak_large_1010':
        t=re.search(r'transform = Transform3D\(([^)]+)\)',s);v=t[1].split(',');v[-3]='-41';s=s[:t.start(1)]+','.join(v)+s[t.end(1):]
    pieces[i]=s
assert set(seen)==set(changes),(set(changes)-set(seen))
for item in record['objects']:
    if item['group']=='WillowPark' and item['node'] in changes:
        p,a,s=changes[item['node']];item.update(position=p,angle=a,scale=s)
        if item['node']=='park_path_loop_022':item['name']='park_path_loop_large'
resources=['[ext_resource type="PackedScene" path="res://neighborhood_assets/recreation_models/park_path_loop_large.glb" id="park_expand_path"]\n\n','[ext_resource type="PackedScene" path="res://neighborhood_assets/recreation_models/park_fence_panel.glb" id="park_expand_fence"]\n\n']
new=[]
def add(name,id,x,z,angle=0,scale=(1,1,1),y=.035):
    node='Expansion_'+name+'_'+str(len(new)).zfill(2)
    new.append(f'[node name="{node}" parent="ExistingNeighborhood/WillowPark" instance=ExtResource("{id}")]\ntransform = {trans((x,y,z),angle,scale)}\n\n')
    record['objects'].append(dict(group='WillowPark',name=name,node=node,position=[x,y,z],angle=angle,scale=scale))
def fence(axis,fixed,a,b):
    n=math.ceil((b-a)/3);length=(b-a)/n
    for i in range(n):
        v=a+(i+.5)*length
        add('park_fence_panel','park_expand_fence',v if axis=='x' else fixed,fixed if axis=='x' else v,0 if axis=='x' else 90,(length/3,1,1))
fence('x',9.25,-12.25,12.25)
fence('x',-9.25,-12.25,-1.5);fence('x',-9.25,1.5,12.25)
fence('z',-12.25,-9.25,9.25)
fence('z',12.25,-9.25,-1.5);fence('z',12.25,1.5,9.25)
# A short northern path leads through the second opening into the garden edge.
path_id=next(re.search(r'\bid="([^"]+)"',s)[1] for s in pieces if s.startswith('[ext_resource') and '/path_tile.glb"' in s)
add('path_tile',path_id,0,-9.75,scale=(1,1,1.5),y=.095)
index=next(i for i,s in enumerate(pieces) if s.startswith('[sub_resource') or s.startswith('[node'));pieces[index:index]=resources
index=next(i for i,s in enumerate(pieces) if s.startswith('[node name="SoccerArea"'));pieces[index:index]=new
scene.write_text(''.join(pieces));record['park_expansion']=dict(size=[24,18],fence_panels=len(new)-1,openings=2,moved_tree='GardenTrees_tree_oak_large_1010')
(A/'recreation_placement.json').write_text(json.dumps(record,indent=2))
print('Expanded park to24x18, spread22objects, added',len(new)-1,'separate fence panels and a northern access path.')
