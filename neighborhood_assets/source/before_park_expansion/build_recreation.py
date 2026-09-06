from pathlib import Path
P=Path(__file__).resolve().parents[2]
exec((P/'neighborhood_assets/source/build_sightline_models.py').read_text().split("E=OUT/'sightline_models'")[0].replace('PROJECT=Path(__file__).resolve().parents[2]','PROJECT=P'))
E=OUT/'recreation_models';E.mkdir(exist_ok=True)
for k,h in dict(court='487F88',courtkey='D79B79',rubber='DCB574',sand='EAD39B',net='D2DED6',turf='79B080',turf2='70A677').items():M[k]=mat(k,h)
catalog=[];roots=[]
def line(a,b,width=.055,z=.031,material='white'):
    dx=b[0]-a[0];dy=b[1]-a[1];l=math.hypot(dx,dy);nx=-dy/l*width/2;ny=dx/l*width/2
    mesh('Paint',[(a[0]+nx,a[1]+ny,z),(a[0]-nx,a[1]-ny,z),(b[0]-nx,b[1]-ny,z),(b[0]+nx,b[1]+ny,z)],[(0,1,2,3)],material)
def rect(x,y,w,d,z=.031):
    p=[(x-w/2,y-d/2),(x+w/2,y-d/2),(x+w/2,y+d/2),(x-w/2,y+d/2)]
    for i in range(4):line(p[i],p[(i+1)%4],z=z)
def arc(x,y,r,a=0,b=math.tau,z=.031):
    n=max(10,int(abs(b-a)*15));ps=[(x+r*math.cos(a+(b-a)*i/n),y+r*math.sin(a+(b-a)*i/n)) for i in range(n+1)]
    for p,q in zip(ps,ps[1:]):line(p,q,z=z)

begin('basketball_court','sport_surface')
box('Concrete foundation',(0,0,-.06),(12,18,.12),'stone',.05)
box('Teal court',(0,0,.006),(11.8,17.8,.025),'court',.025)
for s in [-1,1]:box('Painted key',(0,s*6.2,.022),(3.6,3.6,.012),'courtkey',0)
rect(0,0,10,16);line((-5,0),(5,0));arc(0,0,1.25)
for s in [-1,1]:
    rect(0,s*6.2,3.6,3.6);arc(0,s*4.4,1.8)
    arc(0,s*7.3,4.3,0 if s<0 else math.pi,math.pi if s<0 else math.tau)
save(current,'sport_surface','Compact neighborhood two-hoop court, 12 x 18m including runoff; decorative linework, not a regulation venue.')

begin('basketball_hoop','sports_equipment')
box('Foot',(0,.65,.08),(.7,.8,.16),'slate');box('Padded post',(0,.65,1.35),(.24,.24,2.7),'teal')
beam('Cantilever',(0,.65,2.7),(0,0,3.05),.085,'slate')
box('Backboard',(0,0,3.1),(1.65,.09,1),'cream',.035)
for x in [-.3,.3]:box('Target sides',(x,-.052,3.04),(.035,.016,.36),'coral',0)
for z in [2.86,3.22]:box('Target top bottom',(0,-.052,z),(.63,.016,.035),'coral',0)
beam('Rim bracket',(0,0,2.85),(0,-.4,2.85),.04,'coral')
torus('Rim',(0,-.47,2.85),.235,.023,'coral',segments=24)
for i in range(12):
    a=i*math.tau/12;b=a+.25
    beam('Net cord',(.23*math.cos(a),-.47+.23*math.sin(a),2.83),(.14*math.cos(b),-.47+.14*math.sin(b),2.46),.009,'net',5)
torus('Net hem',(0,-.47,2.46),.14,.009,'net',segments=16)
save(current,'sports_equipment','Standalone hoop with backboard, target, padded post, rim and open net.')

begin('basketball','sports_prop');ball('Ball',(0,0,.12),(.12,)*3,'coral',3)
for rot in [(0,0,0),(math.pi/2,0,0),(0,math.pi/2,0)]:torus('Seam',(0,0,.12),.119,.003,'dark',rot,32)
save(current,'sports_prop')

begin('soccer_pitch','sport_surface')
box('Turf base',(0,0,-.025),(12,18,.05),'turf',.025)
for i in range(6):box('Mown stripe',(0,-7.5+i*3,.003),(11.95,3,.008),'turf' if i%2 else 'turf2',0)
rect(0,0,10,16,z=.014);line((-5,0),(5,0),z=.014);arc(0,0,1.65,z=.014)
for s in [-1,1]:rect(0,s*6.5,5,3,z=.014);rect(0,s*7.4,3.6,1.2,z=.014)
cyl('Center spot',(0,0,.016),.09,.008,'white',16)
save(current,'sport_surface','Small 12 x 18m recreational soccer area; 10 x 16m marked pitch.')

begin('soccer_goal','sports_equipment')
for x in [-1.5,1.5]:
    beam('Upright',(x,0,.06),(x,0,1.8),.055,'white')
    beam('Rear brace',(x,0,1.8),(x,1.15,.05),.035,'metal')
    beam('Foot',(x,0,.04),(x,1.15,.04),.04,'white')
beam('Crossbar',(-1.5,0,1.8),(1.5,0,1.8),.055,'white');beam('Rear base',(-1.5,1.15,.04),(1.5,1.15,.04),.03,'white')
for i in range(16):
    x=-1.5+i*.2;beam('Rear net',(x,0,1.77),(x,1.15,.07),.009,'net',5)
for i in range(10):
    t=i/9;beam('Cross net',(-1.5,1.15*t,1.77-1.7*t),(1.5,1.15*t,1.77-1.7*t),.009,'net',5)
for x in [-1.5,1.5]:
    for i in range(1,9):
        t=i/9;beam('Side net',(x,0,1.77-1.7*t),(x,1.15*t,1.77-1.7*t),.009,'net',5)
save(current,'sports_equipment','3m wide goal with visible open net; opening faces Godot +Z.')

begin('soccer_ball','sports_prop');o=ball('Ball',(0,0,.115),(.115,)*3,'white',2);o.data.materials.append(M['slate'])
for i,p in enumerate(o.data.polygons):p.material_index=1 if i%7 in [0,1] else 0
save(current,'sports_prop')

begin('sports_fence_panel','boundary')
for x in [-1.5,1.5]:cyl('Post',(x,0,1.25),.045,2.5,'teal')
for z in [.15,2.4]:beam('Rail',(-1.5,0,z),(1.5,0,z),.03,'teal')
for i in range(1,15):beam('Mesh vertical',(-1.5+i*.2,0,.15),(-1.5+i*.2,0,2.4),.008,'metal',4)
for i in range(1,12):beam('Mesh horizontal',(-1.5,0,.15+i*.19),(1.5,0,.15+i*.19),.008,'metal',4)
save(current,'boundary','3m-wide open sports fence, no glass or opaque backdrop.')

begin('park_path_loop','park_surface')
for x in [-8,8]:box('Path',(x,0,.015),(2,14,.03),'concrete',.04)
for y in [-6,6]:box('Path',(0,y,.015),(14,2,.03),'concrete',.04)
save(current,'park_surface','18 x 14m walking loop with 2m-wide paths and grassy center.')
begin('path_tile','park_surface');box('Path',(0,0,.015),(2,1,.03),'concrete',.02);save(current,'park_surface','2m-wide modular path; scale length to connect paths.')
begin('playground_surface','park_surface');box('Soft play surface',(0,0,.025),(10,8,.05),'rubber',.09);save(current,'park_surface')

begin('play_tower_slide','play_equipment')
for x in [-.7,.7]:
    for y in [-.65,.65]:box('Timber post',(x,y,1.25),(.13,.13,2.5),'wood')
box('Deck',(0,0,1.2),(1.6,1.5,.12),'woodlight')
for x in [-.74,.74]:
    beam('Side rail',(x,-.7,1.9),(x,.7,1.9),.05,'teal')
    for y in [-.45,0,.45]:box('Baluster',(x,y,1.56),(.05,.05,.7),'cream')
for s in [-1,1]:mesh('Canopy',[(0,-.92,3),(0,.92,3),(s*.95,.92,2.48),(s*.95,-.92,2.48)],[(3,2,1,0)] if s>0 else [(0,1,2,3)],'mint')
# Slide descends toward Godot +Z, with raised side cheeks.
profile=[(-.7,1.24),(-1.05,1.2),(-2.45,.22),(-2.95,.12)]
for i in range(len(profile)-1):
    y,z=profile[i];yy,zz=profile[i+1]
    mesh('Slide bed',[(-.5,y,z),(.5,y,z),(.5,yy,zz),(-.5,yy,zz)],[(3,2,1,0)],'coral')
    for x in [-.53,.53]:beam('Slide rim',(x,y,z+.14),(x,yy,zz+.14),.055,'yellow')
for x in [-.5,.5]:beam('Ladder rail',(x,.7,1.2),(x,1.8,.05),.06,'wood')
for i in range(5):
    t=(i+.5)/5;beam('Ladder rung',(-.5,.7+1.1*t,1.2-1.15*t),(.5,.7+1.1*t,1.2-1.15*t),.045,'cream')
save(current,'play_equipment','Small sheltered play tower with open ladder, side rails and slide.')

begin('swing_set','play_equipment')
for x in [-2.1,2.1]:
    for y in [-1,1]:beam('A-frame',(x,y,.04),(x,0,2.75),.085,'wood')
    beam('Brace',(x,-.6,1.15),(x,.6,1.15),.055,'woodlight')
beam('Top bar',(-2.3,0,2.75),(2.3,0,2.75),.09,'teal')
for x in [-.9,.9]:
    box('Swing seat',(x,0,.52),(.72,.36,.085),'coral',.04)
    for dx in [-.3,.3]:beam('Hanger',(x+dx,0,.55),(x+dx,0,2.69),.014,'metal',6)
save(current,'play_equipment','Two-seat timber swing frame with separate visible hangers.')

begin('sandbox','play_equipment')
box('Sand',(0,0,.11),(2.9,2.3,.22),'sand',.07)
for x in [-1.5,1.5]:box('Timber rim',(x,0,.16),(.18,2.65,.32),'woodlight')
for y in [-1.25,1.25]:box('Timber rim',(0,y,.16),(2.85,.18,.32),'woodlight')
for x,y in [(-.7,.2),(.55,-.45)]:cyl('Sand turret',(x,y,.37),.15,.25,'sand',8,r2=.11)
save(current,'play_equipment')

begin('picnic_table','park_furniture')
for y in [-.42,-.21,0,.21,.42]:box('Table slat',(0,y,.78),(1.85,.18,.07),'woodlight')
for y in [-.78,.78]:box('Bench',(0,y,.44),(2,.28,.08),'woodlight')
for x in [-.62,.62]:
    for s in [-1,1]:beam('A legs',(x,s*.7,.05),(x,s*.3,.76),.055,'teal')
    beam('Seat brace',(x,-.9,.37),(x,.9,.37),.05,'teal')
save(current,'park_furniture')

begin('drinking_fountain','park_furniture')
box('Pedestal',(0,0,.46),(.28,.32,.92),'teal',.04)
cyl('Bowl',(0,0,.94),.23,.08,'metal',16)
beam('Spout',(.1,0,.99),(.04,0,1.07),.025,'metal')
save(current,'park_furniture')

begin('park_bollard','park_furniture');cyl('Post',(0,0,.4),.06,.8,'teal');cyl('Reflector',(0,0,.69),.067,.065,'cream');save(current,'park_furniture')
for name,label in [('park_sign','WILLOW PARK'),('court_sign','COURT'),('soccer_sign','KICKABOUT')]:
    begin(name,'wayfinding')
    for x in [-.5,.5]:box('Posts',(x,0,.75),(.075,.075,1.5),'wood')
    box('Signboard',(0,0,1.43),(1.8,.09,.47),'teal',.045)
    textmesh('Lettering',label,(0,-.055,1.43),.18,'cream')
    save(current,'wayfinding')
for i,r in enumerate(roots):r.location=((i%5)*24,-(i//5)*25,0)
bpy.context.preferences.filepaths.save_version=0
bpy.ops.wm.save_as_mainfile(filepath=str(OUT/'source/recreation_amenities.blend'))
(OUT/'recreation_catalog.json').write_text(json.dumps(catalog,indent=2))
print('RECREATION_COMPLETE',len(catalog),'models',sum(e['triangles'] for e in catalog),'triangles')
