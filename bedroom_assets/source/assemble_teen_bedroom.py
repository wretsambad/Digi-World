from pathlib import Path
import json,math,random,re
P=Path(__file__).resolve().parents[2];A=P/'bedroom_assets';random.seed(79)
if (A/'learning_house_detailed.tscn').exists():
    raise SystemExit("Use source/connect_bedroom.gd to rebuild the connected bedroom; this is the archived standalone assembler.")
catalog=json.loads((A/'catalog.json').read_text());resources=[];ids={};nodes=[];items=[]
assert len({e['name'] for e in catalog})==len(catalog)
for e in catalog:
    id='m'+str(len(ids));ids[e['name']]=id;resources.append(f'[ext_resource type="PackedScene" path="res://bedroom_assets/models/{e["name"]}.glb" id="{id}"]\n')
def tf(p,angle=0,scale=(1,1,1)):
    if isinstance(scale,(int,float)):scale=(scale,)*3
    x,y,z=p;sx,sy,sz=scale;c=math.cos(math.radians(angle));s=math.sin(math.radians(angle))
    return f'Transform3D({c*sx:.7f},0,{s*sz:.7f},0,{sy:.7f},0,{-s*sx:.7f},0,{c*sz:.7f},{x:.6f},{y:.6f},{z:.6f})'
def group(n,p=(0,0,0),angle=0,parent='.',metadata=None):
    nodes.append(f'[node name="{n}" type="Node3D" parent="{parent}"]\ntransform = {tf(p,angle)}\n'+''.join('metadata/'+k+' = '+json.dumps(v)+'\n' for k,v in (metadata or {}).items())+'\n')
def add(model,p,parent,angle=0,scale=1,name=None):
    name=name or model+'_'+str(len(items)).zfill(3)
    nodes.append(f'[node name="{name}" parent="{parent}" instance=ExtResource("{ids[model]}")]\ntransform = {tf(p,angle,scale)}\n\n')
    items.append(dict(name=name,model=model,parent=parent,position=p,rotation_y=angle,scale=scale))
def marker(name,p,parent):nodes.append(f'[node name="{name}" type="Marker3D" parent="{parent}"]\nposition = Vector3{str(tuple(p))}\n\n')

group('Architecture');group('Floorboards',parent='Architecture')
for i in range(20):
    for j in range(4):add('floor_plank',(-3.515+i*.37,0,-2.475+j*1.65),'Architecture/Floorboards',angle=180 if (i+j)%2 else 0)
add('wall_back',(0,0,-3.38),'Architecture',name='NorthWall')
add('wall_sage',(3.78,0,0),'Architecture',90,name='SageWall')
add('wall_window',(-3.78,0,0),'Architecture',90,name='WindowWall')
add('wall_door',(0,0,3.38),'Architecture',name='DoorWall')
add('ceiling',(0,3.26,0),'Architecture',name='Ceiling')
for x,z,angle,length in [(0,-3.29,0,7.4),(-3.69,0,90,6.6),(3.69,0,90,6.6),(-1.6,3.29,0,4.2),(2.6,3.29,0,2.2)]:add('skirting',(x,0,z),'Architecture',angle,(length,1,1))
add('door_leaf',(.53,0,3.28),'Architecture',-22,name='Door_Ajar')
add('light_switch',(1.72,1.22,3.285),'Architecture',180)
for x,z,angle in [(-2.9,-3.285,0),(2.1,-3.285,0),(-2.9,3.285,180),(3.685,.5,-90)]:add('outlet',(x,.3,z),'Architecture',angle)
group('WestWindow',(-3.68,0,0),90,parent='Architecture')
add('window_frame',(0,0,0),'Architecture/WestWindow')
add('window_leaf',(-1.015,.95,0),'Architecture/WestWindow',72,name='OpenSash')
add('window_leaf',(.025,.95,0),'Architecture/WestWindow',name='OtherSash')
for x in [-1.42,1.42]:add('curtain',(x,0,.12),'Architecture/WestWindow')
nodes.append('[node name="CurtainRod" type="MeshInstance3D" parent="Architecture/WestWindow"]\nposition = Vector3(0,2.74,.12)\nrotation_degrees = Vector3(0,0,90)\nmesh = SubResource("curtain_rod")\n\n')
marker('FutureWindowPassage',(-3.7,1.85,.55),'Architecture')

group('SleepCorner')
add('bed_frame',(2.56,0,-1.61),'SleepCorner')
add('mattress',(2.56,.48,-1.61),'SleepCorner')
add('duvet',(2.56,.75,-1.4),'SleepCorner')
for x,ang in [(2.22,-6),(2.89,7)]:add('pillow',(x,.81,-2.38),'SleepCorner',ang)
add('accent_pillow',(2.52,.84,-2.1),'SleepCorner',-8)
add('throw_blanket',(2.56,.95,-.57),'SleepCorner',3)
add('bedside_table',(2.7,0,.13),'SleepCorner')
add('desk_lamp',(2.88,.628,.09),'SleepCorner',-28)
add('book',(2.63,.12,.21),'SleepCorner',90,1.1)
add('notebook',(2.56,.636,.24),'SleepCorner',-6)
group('Lesson_Phone',(2.55,.68,.2),parent='.',metadata={'lesson_id':'message_detective','status':'visual_placeholder','topic':'Spot suspicious messages'})
add('phone',(0,0,0),'Lesson_Phone',-12,name='Phone')
marker('FocusAnchor',(0,.13,0),'Lesson_Phone')
add('wardrobe',(3.35,0,1.93),'SleepCorner',-90)
add('storage_bin',(3.28,2.09,1.51),'SleepCorner',-90)
add('storage_bin',(3.28,2.09,2.06),'SleepCorner',-90)
add('laundry_basket',(2.0,0,2.84),'SleepCorner')
add('hoodie',(2.0,.46,2.84),'SleepCorner',14,.8)
add('sneaker',(2.08,0,1.04),'SleepCorner',-22)
add('sneaker',(2.31,0,1.15),'SleepCorner',8)
add('basketball',(1.61,0,2.59),'SleepCorner')

group('StudyCorner')
add('desk',(-1.87,0,-2.82),'StudyCorner')
add('office_chair',(-1.55,0,-1.78),'StudyCorner',166)
add('hoodie',(-1.66,.99,-1.52),'StudyCorner',-14,.7)
group('Lesson_Computer',(-2.05,.81,-2.89),parent='.',metadata={'lesson_id':'password_builder','status':'visual_placeholder','topic':'Protect accounts'})
add('computer_monitor',(0,0,0),'Lesson_Computer',name='Computer')
marker('FocusAnchor',(0,.49,.08),'Lesson_Computer')
add('keyboard',(-2.05,.813,-2.55),'StudyCorner',-3)
add('mouse',(-1.66,.813,-2.56),'StudyCorner')
add('computer_tower',(-.79,.81,-2.86),'StudyCorner')
for x in [-2.74,-1.38]:add('speaker',(x,.81,-3.08),'StudyCorner')
add('desk_lamp',(-3.06,.81,-2.9),'StudyCorner',-25)
add('headphones',(-2.95,.81,-2.6),'StudyCorner',22)
add('open_notebook',(-1.2,.81,-2.57),'StudyCorner',9)
add('pencil_cup',(-1.4,.81,-3.07),'StudyCorner')
add('mug',(-.62,.81,-2.57),'StudyCorner')
add('water_bottle',(-3.07,.81,-3.07),'StudyCorner')
add('cable_loop',(-1.15,.03,-3.01),'StudyCorner')
add('power_strip',(-1.6,.03,-3.01),'StudyCorner')
add('backpack',(-.9,0,-1.9),'StudyCorner',-10)
add('wall_shelf',(-1.82,2.16,-3.13),'StudyCorner')
for i in range(7):add(['book','book_sage','book_navy'][i%3],(-2.43+i*.08,2.2,-3.04),'StudyCorner',0,1+(i%3)*.12)
add('plant',(-1.27,2.19,-3.06),'StudyCorner',0,.72)
add('game_controller',(-1.56,2.2,-2.99),'StudyCorner')

group('SharingCorner')
add('cubby_shelf',(.36,0,-3.02),'SharingCorner',0,.66)
for x in [-.01,.64]:add('storage_bin',(x,.06,-2.99),'SharingCorner',0,.75)
add('plant',(.68,.63,-2.99),'SharingCorner')
add('notebook',(.02,.63,-2.89),'SharingCorner',6)
group('Lesson_SharingBoard',(.35,1.77,-3.245),metadata={'lesson_id':'share_safely','status':'visual_placeholder','topic':'Choose what to share'})
add('corkboard',(0,0,0),'Lesson_SharingBoard',name='SharingBoard')
for x,y,ang in [(-.4,.14,-6),(-.11,.17,5),(.25,.13,-4),(-.31,-.2,4)]:
    # Turn the small cards within the wall plane for an informal pinned arrangement.
    name='PinnedPhoto_'+str(len(items));add('photo_card',(x,y,.064),'Lesson_SharingBoard',name=name)
    nodes[-1]=nodes[-1].replace('\n\n',f'\nrotation_degrees = Vector3(0,0,{ang})\n\n')
for x,y in [(.05,-.19),(.39,-.19)]:add('sticky_note',(x,y,.065),'Lesson_SharingBoard')
marker('FocusAnchor',(0,0,.14),'Lesson_SharingBoard')

group('CreativeCorner')
add('cubby_shelf',(-2.35,0,2.97),'CreativeCorner',180)
for x in [-3.03,-1.76]:add('storage_bin',(x,.07,2.95),'CreativeCorner',180)
for i in range(8):add(['book_navy','book','book_sage'][i%3],(-3.14+i*.08,.51,2.88),'CreativeCorner',180,1+(i%3)*.12)
for i in range(5):add(['book_sage','book_navy','book'][i%3],(-2.14+i*.075,.51,2.88),'CreativeCorner',180,.9+(i%2)*.17)
add('plant',(-3.08,.95,2.91),'CreativeCorner')
group('Lesson_BackupRobot',(-1.96,.95,2.89),180,metadata={'lesson_id':'recover_project','status':'visual_placeholder','topic':'Back up and restore files'})
add('toy_robot',(0,0,0),'Lesson_BackupRobot',name='BackupRobot')
add('backup_drive',(.3,0,.04),'Lesson_BackupRobot',-8,name='BackupDrive')
add('cable_loop',(.21,0,.14),'Lesson_BackupRobot',-12,.65)
marker('FocusAnchor',(.1,.34,.12),'Lesson_BackupRobot')
add('notebook',(-2.64,.95,2.89),'CreativeCorner',12)
add('guitar',(-3.25,0,1.97),'CreativeCorner',135)
add('skateboard',(-2.32,0,2.28),'CreativeCorner',68)
add('wall_shelf',(-2.35,2.18,3.14),'CreativeCorner',180)
for x in [-2.91,-2.52]:add('storage_bin',(x,2.22,3.0),'CreativeCorner',180,.62)
add('plant',(-1.87,2.22,2.99),'CreativeCorner',0,.65)

group('PersonalDetails')
add('rug',(-.15,.005,.3),'PersonalDetails')
add('poster_orbit',(3.682,2.07,-1.99),'PersonalDetails',-90)
add('poster_sound',(3.682,2.12,-.95),'PersonalDetails',-90,.78)
add('fairy_lights',(3.67,2.72,-1.64),'PersonalDetails',-90)
add('poster_make',(-1.1,1.67,3.275),'PersonalDetails',180,.82)
add('wall_clock',(.18,2.76,-3.285),'PersonalDetails')
for x,z,ang in [(-3.59,-1.37,90),(-3.59,1.43,90)]:add('photo_card',(x,1.5,z),'PersonalDetails',ang,1.05)
add('plant',(-3.48,.94,.7),'PersonalDetails',0,.8)
add('pendant',(0,3.17,0),'PersonalDetails')

group('WindowView')
resources.append('[ext_resource type="PackedScene" path="res://neighborhood_assets/expanded_models/tree_oak_large.glb" id="outside_tree"]\n')
for i,(x,z,s) in enumerate([(-13,4,.8),(-16,-6,.85),(-21,10,1)]):nodes.append(f'[node name="DistantTree{i}" parent="WindowView" instance=ExtResource("outside_tree")]\ntransform = {tf((x,-3.5,z),i*35,s)}\n\n')

lighting='''[sub_resource type="StandardMaterial3D" id="rod_mat"]
albedo_color = Color(0.19,0.24,0.27,1)
roughness = 0.8
[sub_resource type="CylinderMesh" id="curtain_rod"]
material = SubResource("rod_mat")
top_radius = 0.016
bottom_radius = 0.016
height = 3.12
radial_segments = 12
[sub_resource type="ProceduralSkyMaterial" id="sky_mat"]
sky_top_color = Color(0.48,0.67,0.77,1)
sky_horizon_color = Color(0.8,0.86,0.83,1)
ground_bottom_color = Color(0.4,0.49,0.38,1)
[sub_resource type="Sky" id="sky"]
sky_material = SubResource("sky_mat")
[sub_resource type="Environment" id="env"]
background_mode = 2
sky = SubResource("sky")
ambient_light_source = 2
ambient_light_color = Color(0.76,0.80,0.83,1)
ambient_light_energy = 0.32
reflected_light_source = 2
tonemap_mode = 2
ssao_enabled = true
ssao_radius = 0.6
ssao_intensity = 1.35

'''
root='[node name="TeenBedroom" type="Node3D"]\nmetadata/room_dimensions = "7.4 x 6.6 x 3.2 meters"\nmetadata/purpose = "Standalone detailed bedroom; lesson objects are static placeholders"\n\n'
tail='''[node name="WorldEnvironment" type="WorldEnvironment" parent="."]
environment = SubResource("env")
[node name="WindowSun" type="DirectionalLight3D" parent="."]
rotation_degrees = Vector3(-28,-88,0)
light_color = Color(1,0.91,0.76,1)
light_energy = 0.38
shadow_enabled = true
directional_shadow_max_distance = 40.0
[node name="WindowFill" type="OmniLight3D" parent="."]
position = Vector3(-3.3,2,0)
light_color = Color(0.85,0.94,1,1)
light_energy = 0.20
shadow_enabled = true
omni_range = 8.0
[node name="CeilingFill" type="OmniLight3D" parent="."]
position = Vector3(0,2.8,0)
light_color = Color(1,0.91,0.77,1)
light_energy = 0.16
shadow_enabled = true
omni_range = 7.5
[node name="DeskGlow" type="OmniLight3D" parent="."]
position = Vector3(-2.98,1.17,-2.78)
light_color = Color(1,0.79,0.52,1)
light_energy = 0.07
omni_range = 2.2
[node name="BedsideGlow" type="OmniLight3D" parent="."]
position = Vector3(2.92,1.01,0.17)
light_color = Color(1,0.78,0.49,1)
light_energy = 0.06
omni_range = 2.0
'''
# Camera transforms are generated with Godot in a separate assembly-finalization step.
scene_text='[gd_scene format=3]\n\n'+''.join(resources)+'\n'+lighting+root+''.join(nodes)+tail
scene_text=re.sub(r'(?<![\w])(-?)\.(\d)',r'\g<1>0.\2',scene_text)
(A/'teen_bedroom.tscn').write_text(scene_text)
(A/'placement.json').write_text(json.dumps(items,indent=2))
print('ASSEMBLED',len(items),'individual model placements and four static lesson groups in NEW teen_bedroom.tscn')
