from pathlib import Path
import json,math,random,re,hashlib
P=Path(__file__).resolve().parents[2];A=P/'neighborhood_assets';random.seed(531)
routes=json.loads((A/'sightline_routes.json').read_text());newmodels={r['name'] for r in json.loads((A/'sightline_catalog.json').read_text())}
expanded={r['name'] for r in json.loads((A/'expanded_catalog.json').read_text())}
items=[]
def add(name,x,z,y=0,angle=0,scale=1,category='SightlineGardens'):
    if isinstance(scale,(int,float)):scale=(scale,scale,scale)
    items.append(dict(name=name,x=x,z=z,y=y,angle=angle,scale=scale,category=category))
def prop(name,x,z,y=.025,angle=0,scale=5,category='SightlineGardens'):add(name,x,z,y,angle,scale,category)
def segdist(p,a,b):
    dx=b[0]-a[0];dz=b[1]-a[1];t=max(0,min(1,((p[0]-a[0])*dx+(p[1]-a[1])*dz)/(dx*dx+dz*dz)))
    return math.hypot(p[0]-a[0]-t*dx,p[1]-a[1]-t*dz)
def pathdist(p):return min(segdist(p,a,b) for route in routes.values() for a,b in zip(route['points'],route['points'][1:]))

# Compact infill sits in existing gaps, without moving any authored homes or bedroom objects.
drive_z=[53,29,5,-19,-43]
for side in [-1,1]:
    for j,z in enumerate([9,-15,-39]):
        x=side*(20.5+(j%2)*.6);name='house_cedar' if (j+(side>0))%2 else 'house_peach';angle=90 if side<0 else -90
        add(name,x,z,angle=angle,category='SightlineInfillHouses')
        add('garden_path_large',side*10.8,z,.065,angle=angle,scale=(1,1,1.65))
        prop('garden_gate',side*6.8,z,angle=90)
        for dz in [-3.8,-1.8,1.8,3.8]:
            if all(abs(z+dz-d)>2.75 for d in drive_z):prop('hedge_straight',side*6.85,z+dz,angle=90,scale=(4.1,6.3,5))
        for dz in [-2.9,2.9]:
            prop('flowerbed',side*12.7,z+dz,angle=angle,scale=5.7)
            prop('shrub_round',side*16.1,z+dz,scale=7.2)
        prop('mailbox',side*7.5,z+.95,angle=angle)
        prop('flowerpot',side*15.1,z+1.4,.08,scale=6.4)
        prop('bench',side*11.6,z-2.8,angle=angle)
        add('tree_poplar_large',side*27.8,z-2,scale=1.1,category='SightlineTrees')
        # Mid-height plant masses prevent looking through empty lawns beneath high crowns.
        for dz in [-4,0,4]:prop('hedge_straight',side*28,z+dz,angle=90,scale=(8.3,9,8))

# Richer turning views along both sides of the cross street.
for side in [-1,1]:
    for i,xabs in enumerate([29,40,53]):
        x=side*xabs
        add('tree_maple_large',x,-57.3,scale=1.03+(i%2)*.12,category='SightlineTrees')
        add('tree_poplar_large',x+side*4,-50,scale=1.2,category='SightlineTrees')
        for dx in [-3.6,0,3.6]:prop('hedge_straight',x+dx,-59.4,scale=(7.6,7.8,7))
        prop('bench',x,-56.3,angle=180,scale=6)
        prop('flowerbed',x,-60.6,scale=6.3)
        prop('flowerbed',x+side*3.6,-55.1,angle=90,scale=6)
        prop('litter_bin',x-side*2.7,-56.2,scale=5.5)
        for k in range(4):prop('stepping_stone',x+side*3,-61.6+k*.9,.03,scale=5)
    for xabs in [11,22,36,61]:
        x=side*xabs
        add('tree_oak_large',x,-78.5,scale=1.0,category='SightlineTrees')
        prop('shrub_round',x-1.7,-76.5,scale=9)
    # Fill the missing corner sidewalk square and connect each straight to its continuation.
    add('sidewalk_slab_large',side*5.775,-63.35,angle=90,scale=(1,1,.225),category='SightlinePaving')
    for zoff in [-4.65,4.65]:
        add('sidewalk_slab_large',side*62.8,-68+zoff,angle=90,scale=(1,1,.8),category='SightlinePaving')
    for zoff in [-3.675,3.675]:add('curb_large',side*62.8,-68+zoff,angle=90,scale=(1,1,.8),category='SightlinePaving')
    for z,length in [(66.6,1),(68.6,1),(70.6,1),(72.2,.6)]:
        add('sidewalk_slab_large',side*4.65,z,scale=(1,1,length),category='SightlinePaving')
        add('curb_large',side*3.675,z,scale=(1,1,length),category='SightlinePaving')

# Short winding continuations keep the road from ending at a visible straight cut.
for name,route in routes.items():
    ox,oz=route['origin']
    for part in ['road','sidewalk','curb']:add(f'continuation_{name}_{part}',ox,oz,category='SightlineRoadContinuation')
    points=route['points'];distance=0;last_tree=-99;last_hedge=-99;last_lamp=-99
    for i in range(1,len(points)-1):
        x,z=points[i];px,pz=points[i-1];distance+=math.hypot(x-px,z-pz)
        tx=points[i+1][0]-px;tz=points[i+1][1]-pz;l=math.hypot(tx,tz);tx/=l;tz/=l;nx=-tz;nz=tx
        along=-math.degrees(math.atan2(tz,tx))
        if distance-last_tree>7.3:
            for side in [-1,1]:
                offset=side*(8.5+random.uniform(.1,1.5));sx=x+nx*offset;sz=z+nz*offset
                add('tree_oak_large' if i%3 else 'tree_poplar_large',sx,sz,scale=random.uniform(.96,1.3),category='SightlineTrees')
                prop('shrub_round',x+nx*side*6.45,z+nz*side*6.45,scale=8.5)
                # A staggered second row closes gaps between foreground trunks.
                if i%2:add('tree_maple_large',x+nx*side*16.5,z+nz*side*16.5,scale=1.25,category='SightlineTrees')
            last_tree=distance
        if distance-last_hedge>3.9:
            for side in [-1,1]:prop('hedge_straight',x+nx*side*6.9,z+nz*side*6.9,angle=along,scale=(8.5,8.2,7))
            last_hedge=distance
        if distance-last_lamp>17 and distance<route['length']-12:
            prop('streetlamp',x+nx*5.1,z+nz*5.1,.16,angle=along+90,scale=6.8,category='SightlineStreetFurniture');last_lamp=distance

# Support terrain and obscured roof hints beyond the bends, not whole extra housing blocks.
add('lawn_tile',48,116,-.025,scale=(27,1,19),category='SightlineGround')
for x,z,rot in [(48,-109,15),(-49,-110,-20),(40,113,30)]:
    add('distant_roofline',x,z,1.0,angle=rot,category='SightlineRoofHints')
    for dx in [-5,-1,3,7]:prop('hedge_straight',x+dx,z+4,scale=(8.5,13,10))
for x,z in [(48,-128),(-48,-128),(57,133)]:
    add('landscape_mound',x,z,-1.8,scale=(1.0,.95,.85),category='SightlineTerminalScreen')
    for dx,dz in [(-8,0),(-2,-3),(5,0),(10,4)]:add('tree_oak_large',x+dx,z+dz,scale=1.4,category='SightlineTrees')

# Don't place new trees/hedges on another branch of a winding road.
items=[a for a in items if not (a['category']=='SightlineTrees' and pathdist((a['x'],a['z']))<6.7)]

def sections(text):return re.split(r'(?=^\[)',text,flags=re.M)
def node_name(s):
    m=re.match(r'\[node name="([^"]+)"',s);return m.group(1) if m else None
def position(s):
    m=re.search(r'transform = Transform3D\(([^)]+)\)',s)
    if not m:return None
    p=[float(v.strip()) for v in m.group(1).split(',')];return p[-3],p[-1]
def patch(path):
    text=path.read_text();pieces=sections(text);removed=[]
    # Idempotence: remove only prior additions from this pass, never regenerate original nodes.
    pieces=[s for s in pieces if not (node_name(s) or '').startswith('Fill_') and not (s.startswith('[ext_resource') and 'id="fill_' in s)]
    clean=[]
    for s in pieces:
        n=node_name(s);p=position(s)
        if n and p and ('metadata/category = "TreeBelt"' in s or 'metadata/category = "GardenTrees"' in s or 'metadata/category = "BackdropHills"' in s):
            limit=21 if 'BackdropHills' in s else 6.5
            if pathdist(p)<limit:removed.append(n);continue
        clean.append(s)
    pieces=clean
    paths={}
    for s in pieces:
        if s.startswith('[ext_resource'):
            p=re.search(r'path="([^"]+)"',s);id=re.search(r'\bid="([^"]+)"',s)
            if p and id:paths[p[1]]=id[1]
    resources=[];nodes=[]
    included=[]
    dressing=path.name=='neighborhood_dressing.tscn'
    for i,a in enumerate(items):
        if dressing and a['category']=='SightlineInfillHouses':continue
        folder='sightline_models' if a['name'] in newmodels else ('expanded_models' if a['name'] in expanded else 'models')
        resource=f'res://neighborhood_assets/{folder}/{a["name"]}.glb'
        if resource not in paths:
            id='fill_'+str(len(resources));paths[resource]=id
            resources.append(f'[ext_resource type="PackedScene" path="{resource}" id="{id}"]\n\n')
        sx,sy,sz=a['scale'];ang=math.radians(a['angle']);c=math.cos(ang);s=math.sin(ang)
        transform=f'Transform3D({c*sx:.6f}, 0, {s*sz:.6f}, 0, {sy:.6f}, 0, {-s*sx:.6f}, 0, {c*sz:.6f}, {a["x"]:.5f}, {a["y"]:.5f}, {a["z"]:.5f})'
        nodes.append(f'[node name="Fill_{a["name"]}_{i:03}" parent="ExistingNeighborhood" instance=ExtResource("{paths[resource]}"))]\ntransform = {transform}\nmetadata/category = "{a["category"]}"\n\n'.replace('))]',')]'))
        included.append(a)
    rindex=next(i for i,s in enumerate(pieces) if s.startswith('[sub_resource') or s.startswith('[node'))
    pieces[rindex:rindex]=resources
    # Insert after the ExistingNeighborhood children, before root lights/cameras when present.
    index=next((i for i,s in enumerate(pieces) if s.startswith('[node name="WorldEnvironment"')),len(pieces))
    pieces[index:index]=nodes
    result=''.join(pieces)
    path.write_text(result)
    return dict(path=str(path),added=len(included),removed_scenery=removed,model_instances=len(re.findall(r'^\[node .*parent="ExistingNeighborhood".*instance=',result,re.M)))

reports=[]
for path in [A/'preview'/'neighborhood_filled.tscn',P/'houses.tscn',A/'preview'/'neighborhood_dressing.tscn']:reports.append(patch(path))
(A/'sightline_placement.json').write_text(json.dumps(items,indent=2))
(A/'sightline_changes.json').write_text(json.dumps(reports,indent=2))
print('SIGHTLINES_FILLED',len(items),'additions;',[(Path(r['path']).name,r['model_instances'],len(r['removed_scenery'])) for r in reports])
