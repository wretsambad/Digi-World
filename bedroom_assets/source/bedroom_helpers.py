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

E=OUT/'expanded_models'
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

