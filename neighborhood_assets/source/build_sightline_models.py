# Run in Blender background mode using --python on this file.
import bpy, math, json, random, csv
from pathlib import Path
from mathutils import Vector

PROJECT=Path(__file__).resolve().parents[2]
OUT=PROJECT/'neighborhood_assets'
random.seed(34)
bpy.ops.object.select_all(action='SELECT'); bpy.ops.object.delete(use_global=False)
for c in list(bpy.data.collections):
    if c.name!='Collection': bpy.data.collections.remove(c)

def linear(v): return v/12.92 if v<=.04045 else ((v+.055)/1.055)**2.4
def mat(name,hexval,metal=0,rough=.8):
    m=bpy.data.materials.new(name);m.use_nodes=True
    rgb=[linear(int(hexval[i:i+2],16)/255) for i in (0,2,4)]
    m.diffuse_color=(*rgb,1);s=m.node_tree.nodes.get('Principled BSDF')
    s.inputs['Base Color'].default_value=(*rgb,1);s.inputs['Metallic'].default_value=metal;s.inputs['Roughness'].default_value=rough
    return m
M={k:mat(k,v) for k,v in dict(mint='61CB8B',leaf='4EAC76',lightleaf='8DDD9B',grass='A3CDA0',grass2='91BC8E',cream='F9EFDA',wood='B07853',woodlight='D9A571',slate='515566',dark='38383D',metal='7B8295',blue='6794D9',glass='AFD9DF',coral='FF7E44',yellow='F7C66F',pink='E9A3B4',stone='B7B8B3',concrete='D2D2CD',soil='755642',white='FCF8EC').items()}
M['metal'].node_tree.nodes.get('Principled BSDF').inputs['Metallic'].default_value=.25
parts=[]; catalog=[]; roots=[]; current=''
def finish(ob,name,material):
    ob.name=current+'__'+name
    if material:ob.data.materials.append(M[material])
    parts.append(ob);return ob
def box(name,loc,dim,material,bevel=.025):
    bpy.ops.mesh.primitive_cube_add(size=1,location=loc);o=bpy.context.object;o.dimensions=dim
    bpy.ops.object.transform_apply(location=False,rotation=False,scale=True)
    if bevel:
        mod=o.modifiers.new('Soft edges','BEVEL');mod.width=min(bevel,min(dim)*.35);mod.segments=2
        bpy.ops.object.modifier_apply(modifier=mod.name)
        mod=o.modifiers.new('Weighted normals','WEIGHTED_NORMAL');mod.keep_sharp=True
        bpy.ops.object.modifier_apply(modifier=mod.name)
    return finish(o,name,material)
def cyl(name,loc,r,depth,material,vertices=12,r2=None,rotation=None):
    bpy.ops.mesh.primitive_cone_add(vertices=vertices,radius1=r,radius2=r if r2 is None else r2,depth=depth,location=loc)
    o=bpy.context.object
    if rotation:o.rotation_euler=rotation
    return finish(o,name,material)
def ball(name,loc,scale,material,sub=1):
    bpy.ops.mesh.primitive_ico_sphere_add(subdivisions=sub,radius=1,location=loc);o=bpy.context.object;o.scale=scale
    bpy.ops.object.transform_apply(location=False,rotation=False,scale=True)
    return finish(o,name,material)
def beam(name,a,b,r,material,vertices=8):
    a=Vector(a);b=Vector(b);o=cyl(name,(a+b)/2,r,(b-a).length,material,vertices)
    o.rotation_euler=(b-a).to_track_quat('Z','Y').to_euler();return o
def torus(name,loc,major,minor,material,rot=(0,0,0),segments=20):
    bpy.ops.mesh.primitive_torus_add(major_segments=segments,minor_segments=6,location=loc,major_radius=major,minor_radius=minor,rotation=rot)
    return finish(bpy.context.object,name,material)
def mesh(name,verts,faces,material):
    me=bpy.data.meshes.new(name);me.from_pydata(verts,[],faces);me.update();o=bpy.data.objects.new(name,me);bpy.context.collection.objects.link(o)
    return finish(o,name,material)
def textmesh(name,body,loc,size,material,rotation=(math.pi/2,0,0)):
    cu=bpy.data.curves.new(name,'FONT');cu.body=body;cu.align_x='CENTER';cu.align_y='CENTER';cu.size=size;cu.extrude=.001;cu.resolution_u=2
    o=bpy.data.objects.new(name,cu);bpy.context.collection.objects.link(o);o.location=loc;o.rotation_euler=rotation
    bpy.context.view_layer.objects.active=o;o.select_set(True);bpy.ops.object.convert(target='MESH');o.select_set(False)
    return finish(o,name,material)
def begin(name,category):
    global current,parts
    current=name;parts=[]
    col=bpy.data.collections.new(name);bpy.context.scene.collection.children.link(col)
    bpy.context.view_layer.active_layer_collection=bpy.context.view_layer.layer_collection.children[name]
    return category
def save(name,category,notes=''):
    root=bpy.data.objects.new(name,None);bpy.context.collection.objects.link(root)
    for o in parts:
        o.parent=root;o.location*=.2
        if o.type=='MESH':
            for v in o.data.vertices:v.co*=.2
    bpy.context.view_layer.update()
    vs=[o.matrix_world@Vector(v) for o in parts for v in o.bound_box]
    lo=[min(v[i] for v in vs) for i in range(3)];hi=[max(v[i] for v in vs) for i in range(3)]
    # Align all ground objects exactly at Y=0 in the exported Godot coordinate system.
    for o in parts:o.location.z-=lo[2]
    for o in bpy.context.selected_objects:o.select_set(False)
    root.select_set(True)
    for o in parts:o.select_set(True)
    bpy.context.view_layer.objects.active=root
    bpy.ops.export_scene.gltf(filepath=str(OUT/'models'/(name+'.glb')),export_format='GLB',use_selection=True,export_apply=True,export_yup=True,export_cameras=False,export_lights=False,export_animations=False)
    tris=0
    for o in parts:o.data.calc_loop_triangles();tris+=len(o.data.loop_triangles)
    catalog.append(dict(name=name,category=category,width=round(hi[0]-lo[0],4),height=round(hi[2]-lo[2],4),depth=round(hi[1]-lo[1],4),triangles=tris,notes=notes))
    roots.append(root)

def flower(x,y,z,petal='yellow',size=.11):
    beam('Stem',(x,y,z),(x,y,z+.38),.019,'leaf')
    for i in range(5):
        a=math.tau*i/5;ball('Petal',(x+math.cos(a)*size*.7,y+math.sin(a)*size*.7,z+.38),(size*.64,size*.64,size*.3),petal)
    ball('Flower center',(x,y,z+.405),(size*.35,)*3,'coral')
    ball('Leaf',(x+.055,y,z+.2),(.11,.04,.035),'leaf')

E=OUT/'expanded_models';E.mkdir(exist_ok=True)
for k,h in dict(teal='407E80',roofblue='5D7598',clay='BC765B',sage='759E86',lavender='9487AD',butter='F4DEAA',peach='F0C9AF',pale_blue='D2E5E9',wall='F4E9D5',interior='F6EDDD',rug='659D9C',linen='F2E6C9').items():M[k]=mat(k,h)
catalog=[];roots=[]

def save(name,category,notes=''):
    """Keep individual source parts; export one mesh with shared material surfaces."""
    root=bpy.data.objects.new(name,None);bpy.context.collection.objects.link(root)
    for o in parts:o.parent=root
    bpy.context.view_layer.update()
    verts=[o.matrix_world@Vector(v) for o in parts for v in o.bound_box]
    lo=[min(v[i] for v in verts) for i in range(3)];hi=[max(v[i] for v in verts) for i in range(3)]
    for o in bpy.context.selected_objects:o.select_set(False)
    copies=[]
    for o in parts:
        d=o.copy();d.data=o.data.copy();bpy.context.collection.objects.link(d);d.parent=None;d.matrix_world=o.matrix_world.copy();d.select_set(True);copies.append(d)
    bpy.context.view_layer.objects.active=copies[0];bpy.ops.object.join();joined=bpy.context.object
    mats=[];mapping={}
    for i,m in enumerate(joined.data.materials):
        if m not in mats:mats.append(m)
        mapping[i]=mats.index(m)
    indexes=[mapping[p.material_index] for p in joined.data.polygons];joined.data.materials.clear()
    for m in mats:joined.data.materials.append(m)
    for p,i in zip(joined.data.polygons,indexes):p.material_index=i
    bpy.context.scene.cursor.location=(0,0,0);bpy.ops.object.origin_set(type='ORIGIN_CURSOR');joined.name=name+'_Mesh'
    bpy.ops.export_scene.gltf(filepath=str(E/(name+'.glb')),export_format='GLB',use_selection=True,export_apply=True,export_yup=True,export_cameras=False,export_lights=False,export_animations=False)
    joined.data.calc_loop_triangles();tris=len(joined.data.loop_triangles);bpy.data.objects.remove(joined,do_unlink=True)
    roots.append(root);catalog.append(dict(name=name,category=category,width=round(hi[0]-lo[0],3),height=round(hi[2]-lo[2],3),depth=round(hi[1]-lo[1],3),triangles=tris,notes=notes))

def import_model(path,factor=1):
    before=set(bpy.data.objects);bpy.ops.import_scene.gltf(filepath=str(path));new=set(bpy.data.objects)-before
    meshes=[o for o in new if o.type=='MESH'];bpy.context.view_layer.update()
    for o in meshes:
        world=o.matrix_world.copy();o.parent=None;o.matrix_world=world
        bpy.context.view_layer.objects.active=o
        for v in o.data.vertices:v.co=world@v.co*factor
        o.matrix_world.identity();parts.append(o)
    for o in new:
        if o.type!='MESH':bpy.data.objects.remove(o,do_unlink=True)
    # Import can change the active collection; bring all meshes into this model's collection.
    col=bpy.data.collections[current]
    for o in meshes:
        for c in list(o.users_collection):c.objects.unlink(o)
        col.objects.link(o)
    bpy.context.view_layer.active_layer_collection=bpy.context.view_layer.layer_collection.children[current]
    return meshes

def recolor_house(objects,roof,wall):
    for o in objects:
        uv=o.data.uv_layers.active
        im=next((n.image for m in o.data.materials if m and m.use_nodes for n in m.node_tree.nodes if n.type=='TEX_IMAGE' and n.image),None)
        if not im or not uv:continue
        px=list(im.pixels);w,h=im.size;materials=[];chosen=[];cache={}
        for face in o.data.polygons:
            coords=[uv.data[i].uv for i in face.loop_indices];u=sum(c.x for c in coords)/len(coords);v=sum(c.y for c in coords)/len(coords)
            off=(min(h-1,max(0,int(v*h)))*w+min(w-1,max(0,int(u*w))))*4
            rgb=px[off:off+3];z=sum(o.data.vertices[i].co.z for i in face.vertices)/len(face.vertices)
            if rgb[1]>rgb[0]*1.3 and rgb[1]>rgb[2]*1.15 and z>1.7:m=M[roof]
            elif min(rgb)>.76 and max(rgb)-min(rgb)<.2:m=M[wall]
            else:
                hx=''.join(f'{round(max(0,min(1,x))*255):02X}' for x in rgb)
                if hx not in cache:cache[hx]=M.get('original_'+hx) or mat('original_'+hx,hx);M['original_'+hx]=cache[hx]
                m=cache[hx]
            if m not in materials:materials.append(m)
            chosen.append(materials.index(m))
        o.data.materials.clear()
        for m in materials:o.data.materials.append(m)
        for f,i in zip(o.data.polygons,chosen):f.material_index=i

E=OUT/'sightline_models';E.mkdir(exist_ok=True)
M['asphalt']=mat('asphalt','5C6062');M['sidewalk']=mat('sidewalk','D9D7CA')
routes={}

def catmull(points,ghost,steps=24):
    p=[Vector(ghost)]+[Vector(v) for v in points]+[Vector(points[-1])*2-Vector(points[-2])]
    path=[]
    for i in range(1,len(p)-2):
        for j in range(steps):
            t=j/steps;a,b,c,d=p[i-1:i+3]
            v=.5*((2*b)+(-a+c)*t+(2*a-5*b+4*c-d)*t*t+(-a+3*b-3*c+d)*t*t*t)
            path.append(v)
    path.append(Vector(points[-1]));return path
def ribbon(name,path,low,high,top,material,bottom=None):
    verts=[]
    for i,p in enumerate(path):
        delta=path[min(i+1,len(path)-1)]-path[max(0,i-1)];delta.normalize();n=Vector((-delta.y,delta.x))
        for off in [low,high]:
            q=p+n*off;verts.append((q.x,-q.y,top))
    faces=[]
    for i in range(len(path)-1):faces.append((i*2,i*2+1,i*2+3,i*2+2))
    if bottom is not None:
        N=len(verts);verts.extend([(x,y,bottom) for x,y,z in list(verts)])
        for i in range(len(path)-1):
            k=i*2;faces.extend([(k,k+2,k+2+N,k+N),(k+1,k+1+N,k+3+N,k+3)])
        faces.extend([(0,N,N+1,1),(N-2,N-1,2*N-1,2*N-2)])
    return mesh(name,verts,faces,material)

east=[(0,0),(14,-3),(25,-20),(19,-39),(-3,-51)]
south=[(0,0),(2,18),(14,27),(32,24),(49,34),(54,50)]
for name,knots,ghost,origin in [('east',east,(-14,-3),(63.6,-68)),('west',[(-x,z) for x,z in east],(14,-3),(-63.6,-68)),('south',south,(2,-18),(0,72.8))]:
    path=catmull(knots,ghost);dist=[0]
    for a,b in zip(path,path[1:]):dist.append(dist[-1]+(b-a).length)
    begin('continuation_'+name+'_road','road_continuation');ribbon('Asphalt',path,-3.6,3.6,0,'asphalt',-.14)
    bucket=[]
    for i,p in enumerate(path):
        if dist[i]%3.4<1.95:bucket.append(p)
        else:
            if len(bucket)>1:ribbon('Dashed center line',bucket,-.07,.07,.012,'cream')
            bucket=[]
    if len(bucket)>1:ribbon('Dashed center line',bucket,-.07,.07,.012,'cream')
    save(current,'road_continuation','Curving scenic continuation; full road width remains 7.2m.')
    begin('continuation_'+name+'_sidewalk','road_continuation')
    for a,b in [(-5.55,-3.75),(3.75,5.55)]:ribbon('Sidewalk',path,a,b,.15,'sidewalk',0)
    save(current,'road_continuation','Continuous 1.8m sidewalks around the bend.')
    begin('continuation_'+name+'_curb','road_continuation')
    for a,b in [(-3.75,-3.6),(3.6,3.75)]:ribbon('Curb',path,a,b,.17,'cream',0)
    save(current,'road_continuation','17cm curb follows road curvature.')
    routes[name]=dict(origin=origin,points=[[round(p.x+origin[0],4),round(p.y+origin[1],4)] for p in path],length=round(dist[-1],2))

# A lightweight upper facade/roof silhouette, only used behind foreground vegetation.
begin('distant_roofline','background_silhouette')
box('Upper facade',(0,0,1.25),(8,5,2.5),'wall',.015)
for s in [-1,1]:
    mesh('Roof',[(s*4.4,-2.85,2.45),(s*4.4,2.85,2.45),(0,2.85,4.3),(0,-2.85,4.3)],[(0,1,2,3)] if s>0 else [(3,2,1,0)],'roofblue')
for y in [-2.51,2.51]:mesh('Gable',[(-4,y,2.5),(4,y,2.5),(0,y,4.2)],[(0,1,2)] if y<0 else [(2,1,0)],'wall')
box('Chimney',(2,1,3.6),(.6,.7,1.8),'peach');box('Cap',(2,1,4.55),(.8,.9,.12),'cream')
save(current,'background_silhouette','Partial roof/facade silhouette, intended behind hedges and trees rather than as a playable house.')
for i,r in enumerate(roots):r.location=((i%3)*100,-(i//3)*100,0)
bpy.context.preferences.filepaths.save_version=0
bpy.ops.wm.save_as_mainfile(filepath=str(OUT/'source'/'sightline_continuations.blend'))
(OUT/'sightline_routes.json').write_text(json.dumps(routes,indent=2))
(OUT/'sightline_catalog.json').write_text(json.dumps(catalog,indent=2))
print('SIGHTLINE_MODELS_COMPLETE',len(catalog))
