from pathlib import Path
P=Path(__file__).resolve().parents[2]
exec((Path(__file__).parent/'bedroom_helpers.py').read_text())
OUT=P/'bedroom_assets';E=OUT/'models';E.mkdir(parents=True,exist_ok=True);(OUT/'source').mkdir(exist_ok=True)
catalog=[];roots=[]
for k,h in dict(plaster='E8E6D9',sagewall='97B2A5',oak='C79B6F',oaklight='DBB78D',oakdark='AF8058',ink='344E60',denim='59778A',rust='C77F62',mustard='D9B65F',paper='F3EBD9',fabric='D3D6C9',screen='254858',screenlight='79BCAD',cork='BD9265',rubber='3D454B',claypot='D2997E').items():M[k]=mat(k,h)
M['screenlight'].node_tree.nodes.get('Principled BSDF').inputs['Emission Color'].default_value=(*M['screenlight'].diffuse_color[:3],1)
M['screenlight'].node_tree.nodes.get('Principled BSDF').inputs['Emission Strength'].default_value=.45
def G(p):return(p[0],-p[2],p[1])
def B(n,p,d,m,bev=.02):return box(n,G(p),(d[0],d[2],d[1]),m,bev)
def C(n,p,r,h,m,verts=16,r2=None):return cyl(n,G(p),r,h,m,verts,r2)
def S(n,p,s,m,sub=2):return ball(n,G(p),(s[0],s[2],s[1]),m,sub)
def L(n,a,b,r,m,verts=8):return beam(n,G(a),G(b),r,m,verts)
def T(n,body,p,size,m='paper'):return textmesh(n,body,G(p),size,m)
def R(n,p,r,t,m,rot=(0,0,0),seg=28):return torus(n,G(p),r,t,m,rot,seg)
def start(n):begin(n,'teen_bedroom')
def done(note=''):save(current,'teen_bedroom',note)
def knob(x,y,z):C('Knob',(x,y,z),.024,.025,'metal',12).rotation_euler.x=math.pi/2

start('floor_plank');B('Oak plank',(0,-.022,0),(.368,.044,1.645),'oak',.006)
for x in [-.13,.04,.12]:B('Fine grain',(x,.0005,0),(.003,.001,1.54),'oakdark',0)
done('One floorboard, repeated as individually editable planks.')
start('wall_back');B('Plaster',(0,1.6,0),(7.6,3.2,.16),'plaster',.008);done()
start('wall_sage');B('Painted wall',(0,1.6,0),(6.6,3.2,.16),'sagewall',.008);done()
start('wall_window')
# Wall along X with an actual 2.1m-wide opening, later turned onto the west side.
for x,w in [(-2.175,2.25),(2.175,2.25)]:B('Pier',(x,1.6,0),(w,3.2,.16),'plaster',.008)
B('Below window',(0,.475,0),(2.1,.95,.16),'plaster',.008);B('Lintel',(0,2.9,0),(2.1,.6,.16),'plaster',.008);done('Open aperture from Y .95 to 2.6, width 2.1m.')
start('wall_door')
for x,w in [(-1.6,4.2),(2.6,2.2)]:B('Wall',(x,1.6,0),(w,3.2,.16),'plaster',.008)
B('Door lintel',(1,2.7,0),(1,1,.16),'plaster',.008);done('Door opening centered X=1, width1m, height2.2m.')
start('ceiling');B('Ceiling',(0,0,0),(7.6,.12,6.8),'plaster');done()
start('skirting');B('Baseboard',(0,.065,0),(1,.13,.035),'paper',.005);done()
start('window_frame')
for x in [-1.09,1.09]:B('Upright',(x,1.775,0),(.09,1.83,.14),'paper')
for y in [.91,2.64]:B('Cross trim',(0,y,0),(2.28,.09,.14),'paper')
B('Sill',(0,.9,.1),(2.4,.07,.36),'oaklight');B('Fixed middle',(0,1.775,0),(.055,1.65,.07),'paper');done('Open center and two leaf mounting edges; no opaque glass across the passage.')
start('window_leaf')
for x in [0,1.0]:B('Stile',(x,.825,0),(.048,1.65,.045),'paper',.007)
for y in [0,.825,1.65]:B('Rail',(.5,y,0),(1.05,.048,.045),'paper',.007)
B('Handle',(.89,.76,.055),(.035,.16,.025),'metal',.005);done('Hinge at left edge; airy open sash frame, no collision across its void.')
start('curtain')
verts=[];faces=[]
for j in range(2):
    for i in range(25):
        x=-.26+i*.52/24;verts.append((x, -.08*math.cos(i*math.tau/6),.4+j*2.23))
for i in range(24):faces.append((i,i+1,26+i,25+i))
ob=mesh('Pleated linen',verts,faces,'fabric');M['fabric'].use_backface_culling=False
for i in range(6):R('Curtain ring',(-.22+i*.088,2.69,0),.035,.008,'metal',(math.pi/2,0,0),12)
B('Hem',(0,.42,0),(.52,.04,.06),'paper',.01);done()
start('door_leaf');B('Door',(.46,1.06,0),(.92,2.12,.045),'oaklight')
for y in [.55,1.55]:B('Inset panel',(.46,y,.027),(.7,.75,.012),'oak',.015)
L('Lever',(.78,1,.06),(.9,1,.06),.018,'metal');done('Pivot at left jamb for later opening animation.')
start('outlet');B('Plate',(0,0,0),(.11,.16,.018),'paper',.015)
for x in [-.02,.02]:
    for y in [-.037,.037]:B('Socket',(x,y,.012),(.009,.02,.006),'ink',0)
done()
start('light_switch');B('Plate',(0,0,0),(.09,.13,.02),'paper');B('Rocker',(0,0,.02),(.04,.07,.01),'fabric');done()
start('pendant')
L('Cord',(0,0,0),(0,-.38,0),.009,'ink');C('Shade',(0,-.48,0),.3,.25,'paper',32,r2=.15);C('Diffuser',(0,-.61,0),.26,.014,'screenlight',32);done()

start('bed_frame')
for x in [-.72,.72]:
    for z in [-1.02,1.02]:B('Foot',(x,.18,z),(.1,.36,.1),'oakdark')
B('Storage base',(0,.32,0),(1.65,.38,2.3),'oak')
for z in [-.58,.58]:B('Drawer front',(-.837,.3,z),(.035,.26,1.03),'oaklight');L('Drawer pull',(-.86,.36,z-.18),(-.86,.36,z+.18),.015,'ink')
B('Headboard',(0,.75,-1.13),(1.75,1.22,.11),'oaklight')
for x in [-.72,-.48,-.24,0,.24,.48,.72]:B('Headboard slat',(x,.84,-1.065),(.13,.64,.028),'oak',.01)
done()
start('mattress');B('Mattress',(0,.15,0),(1.56,.3,2.15),'paper',.1)
for x in [-.78,.78]:L('Piping',(x,.21,-1),(x,.21,1),.009,'fabric')
done()
start('duvet')
verts=[];faces=[];nx=18;nz=24
for j in range(nz+1):
    z=-.86+j*1.94/nz
    for i in range(nx+1):
        x=-.83+i*1.66/nx;y=.14+.025*math.sin(i*.9+j*.55)+.012*math.sin(j*1.3)
        if abs(x)>.7:y-=(abs(x)-.7)*1.5
        verts.append(G((x,y,z)))
for j in range(nz):
    for i in range(nx):
        k=j*(nx+1)+i;faces.append((k,k+nx+1,k+nx+2,k+1))
o=mesh('Soft quilt',verts,faces,'denim');o.data.materials.append(M['ink'])
for j,p in enumerate(o.data.polygons):p.material_index=1 if (j//nx)//5%2 else 0
for z in [-.65,-.2,.25,.7]:
    j=(z+.86)*nz/1.94
    for i in range(2,nx-2):
        def q(k):
            x=-.83+k*1.66/nx
            return (x,.144+.025*math.sin(k*.9+j*.55)+.012*math.sin(j*1.3),z)
        L('Stitch',q(i),q(i+1),.002,'fabric',5)
done()
start('pillow');B('Pillow',(0,.11,0),(.65,.22,.43),'fabric',.1);B('Seam',(0,.095,.214),(.56,.018,.007),'paper',.006);done()
start('accent_pillow');B('Cushion',(0,.14,0),(.42,.28,.36),'mustard',.1)
for x in [-.11,0,.11]:B('Woven stripe',(x,.278,0),(.016,.006,.27),'paper',.005)
done()
start('throw_blanket')
verts=[];faces=[]
for j in range(8):
    z=-.3+j*.6/7
    for i in range(25):
        x=-.86+i*1.72/24;y=.014*math.sin(i*.8+j*.4)-max(0,abs(x)-.7)*1.4
        verts.append(G((x,y,z)))
for j in range(7):
    for i in range(24):
        k=j*25+i;faces.append((k,k+25,k+26,k+1))
mesh('Woven throw',verts,faces,'rust')
for i in range(15):
    x=-.79+i*.112
    for z in [-.3,.3]:L('Fringe',(x,-max(0,abs(x)-.7)*1.4,z),(x,-max(0,abs(x)-.7)*1.4-.025,z+(.055 if z>0 else -.055)),.004,'paper')
done()
start('bedside_table');B('Body',(0,.32,0),(.62,.52,.55),'oak')
B('Top',(0,.6,0),(.68,.05,.6),'oaklight');B('Drawer',(0,.45,.281),(.53,.19,.03),'paper');L('Pull',(-.08,.45,.31),(.08,.45,.31),.012,'ink')
B('Shelf',(0,.16,0),(.56,.035,.49),'oaklight');done()
start('desk')
B('Desktop',(0,.775,0),(2.7,.065,.8),'oaklight',.028)
for x in [-1.2,1.2]:
    for z in [-.27,.27]:B('Leg',(x,.37,z),(.055,.74,.055),'ink')
L('Crossbrace',(-1.2,.22,-.27),(1.2,.22,-.27),.023,'ink')
B('Drawer cabinet',(.82,.49,0),(.65,.48,.66),'oak')
for y in [.36,.59]:B('Drawer',(.82,y,.34),(.6,.2,.025),'paper');L('Handle',(.71,y,.37),(.93,y,.37),.012,'ink')
B('Cable tray',(-.25,.69,-.26),(1.15,.07,.14),'ink');done()
start('computer_monitor')
B('Base',(0,.025,0),(.36,.04,.22),'ink');B('Stem',(0,.2,-.06),(.055,.35,.055),'metal')
B('Screen body',(0,.49,-.04),(1.05,.63,.045),'ink',.025);B('Display',(0,.5,-.013),(.98,.545,.012),'screen',.014)
B('App window',(0,.5,-.004),(.74,.35,.003),'denim',.018)
T('Digi World','Digi-World',(0,.56,.001),.083);T('Start hint','MAKE. LEARN. EXPLORE.',(0,.44,.001),.023,'fabric')
for x in [-.44,-.39,-.34]:C('Indicator',(x,.742,.002),.008,.003,'screenlight').rotation_euler.x=math.pi/2
done('Visual password-lesson computer; screen is static geometry.')
start('keyboard');B('Board',(0,.018,0),(.48,.035,.17),'ink',.017)
for j in range(4):
    for i in range(13):B('Key',(-.216+i*.036,.045,-.06+j*.035),(.027,.016,.025),'paper' if j<3 else 'fabric',.004)
B('Space bar',(0,.045,.087),(.18,.016,.026),'mustard',.004);done()
start('mouse');B('Mouse',(0,.035,0),(.07,.055,.12),'ink',.026);B('Wheel',(0,.064,-.024),(.012,.015,.025),'screenlight');done()
start('computer_tower');B('Case',(0,.24,0),(.23,.48,.4),'ink',.025)
for y in [.14,.31]:C('Vent',(0,y,.205),.069,.008,'metal',20).rotation_euler.x=math.pi/2;R('Fan rim',(0,y,.211),.05,.006,'screenlight',(math.pi/2,0,0),24)
B('Power indicator',(.07,.433,.211),(.017,.007,.004),'screenlight');done()
start('phone');B('Case',(0,.011,0),(.084,.022,.163),'rust',.014);B('Glass',(0,.024,0),(.074,.006,.148),'ink',.012)
for z in [-.043,-.012,.025]:B('Message bubble',(0,.028,z),(.051,.002,.018),'screenlight',.007)
B('Camera island',(0,.03,-.061),(.024,.003,.006),'rubber',.003);done('Static phone, with fictional message shapes and no personal data.')
start('desk_lamp')
C('Base',(0,.025,0),.12,.05,'mustard',20);L('Lower arm',(0,.04,0),(.03,.34,-.04),.016,'ink');L('Upper arm',(.03,.34,-.04),(.16,.49,.01),.016,'ink')
C('Shade',(.16,.45,.01),.09,.12,'mustard',24,r2=.045);C('Light',(.16,.383,.01),.075,.012,'paper',24);done()
start('headphones')
for x in [-.11,.11]:B('Ear pad',(x,.07,0),(.065,.13,.1),'ink',.028)
for i in range(12):
    a=math.pi*i/12;b=math.pi*(i+1)/12
    L('Headband',(.13*math.cos(a),.09+.14*math.sin(a),0),(.13*math.cos(b),.09+.14*math.sin(b),0),.016,'mustard')
done()
start('speaker');B('Speaker',(0,.11,0),(.13,.22,.13),'oakdark')
C('Driver',(0,.11,.069),.042,.008,'ink',20).rotation_euler.x=math.pi/2;done()
start('office_chair')
C('Column',(0,.27,0),.035,.4,'metal')
for i in range(5):
    a=i*math.tau/5;x=.31*math.cos(a);z=.31*math.sin(a);L('Foot',(0,.1,0),(x,.07,z),.024,'ink');S('Caster',(x,.045,z),(.035,.045,.035),'rubber')
B('Seat',(0,.49,0),(.56,.12,.5),'denim',.05);B('Back',(0,.83,-.22),(.54,.62,.11),'ink',.06)
for x in [-.34,.34]:L('Arm support',(x,.43,0),(x,.69,0),.019,'metal');B('Arm pad',(x,.72,0),(.065,.06,.34),'denim')
done()
start('wardrobe');B('Cabinet',(0,1.02,0),(1.6,2.04,.58),'oak',.025)
for x in [-.395,.395]:
    B('Door',(x,1.05,.302),(.775,1.94,.035),'paper',.018)
    L('Pull',(x+(.27 if x<0 else -.27),.9,.335),(x+(.27 if x<0 else -.27),1.14,.335),.012,'ink')
B('Top cap',(0,2.06,0),(1.65,.045,.63),'oaklight');done()
start('cubby_shelf')
for x in [-1.1,0,1.1]:B('Divider',(x,.47,0),(.045,.9,.5),'oak')
for y in [.035,.46,.91]:B('Shelf',(0,y,0),(2.25,.055,.56),'oaklight')
B('Back',(0,.47,-.26),(2.2,.9,.025),'sagewall');done()
start('wall_shelf');B('Shelf',(0,0,0),(1.5,.05,.27),'oaklight')
for x in [-.56,.56]:L('Bracket',(x,-.21,-.08),(x,-.025,.1),.012,'ink')
done()
start('storage_bin');B('Woven box',(0,.15,0),(.44,.3,.4),'fabric',.025)
for y in [.06,.11,.16,.21,.26]:B('Weave',(0,y,.204),(.42,.012,.008),'paper',.003)
B('Label',(0,.2,.212),(.13,.055,.006),'oaklight');done()
start('book');B('Pages',(0,.115,0),(.045,.23,.16),'paper',.002)
for x in [-.03,.03]:B('Cover',(x,.115,0),(.008,.24,.17),'denim',.003)
B('Spine',(0,.115,.081),(.065,.24,.01),'rust',.005)
for y in [.055,.17]:B('Spine rule',(0,y,.088),(.05,.007,.003),'paper',0)
done()
start('notebook');B('Cover',(0,.015,0),(.2,.03,.27),'mustard',.009);B('Pages',(0,.018,0),(.184,.015,.26),'paper',.003)
for z in [-.1,-.06,-.02,.02,.06,.1]:R('Binding',(-.098,.023,z),.012,.003,'metal',(math.pi/2,0,0),10)
done()
start('open_notebook')
for x in [-.11,.11]:B('Page',(x,.012,0),(.21,.024,.28),'paper',.005)
for z in [-.09,-.05,-.01,.03,.07]:
    for x in [-.11,.11]:B('Writing',(x,.025,z),(.15,.002,.003),'denim',0)
done()
start('pencil_cup');C('Cup',(0,.065,0),.045,.13,'sagewall',16)
for i in range(6):
    a=i*math.tau/6;x=.025*math.cos(a);z=.025*math.sin(a);L('Pencil',(x,.025,z),(x*1.4,.21+(i%2)*.025,z*1.4),.005,'mustard' if i%2 else 'rust',6)
done()
start('mug');C('Ceramic',(0,.05,0),.041,.1,'paper',24);C('Tea',(0,.101,0),.034,.002,'wooddark' if 'wooddark' in M else 'oakdark',24);R('Handle',(.048,.055,0),.025,.007,'paper',(math.pi/2,0,0),18);done()
start('water_bottle');C('Bottle',(0,.12,0),.037,.24,'sagewall',20);C('Cap',(0,.254,0),.029,.03,'ink',20);B('Sticker',(0,.13,.038),(.03,.06,.004),'mustard');done()
start('plant')
C('Pot',(0,.09,0),.115,.18,'claypot',16,r2=.095);C('Soil',(0,.183,0),.091,.007,'soil',16)
for i in range(9):
    a=i*math.tau/9;x=.1*math.cos(a);z=.1*math.sin(a);L('Stem',(0,.18,0),(x,.28+i%3*.07,z),.009,'leaf');S('Leaf',(x,.32+i%3*.07,z),(.095,.045,.065),'leaf' if i%2 else 'lightleaf')
done()
start('wall_clock');C('Case',(0,0,0),.19,.035,'oak',32).rotation_euler.x=math.pi/2;C('Face',(0,0,.025),.168,.008,'paper',32).rotation_euler.x=math.pi/2
for i in range(12):
    a=i*math.tau/12;S('Tick',(.145*math.sin(a),.145*math.cos(a),.034),(.009,.009,.003),'ink',1)
L('Minute',(0,0,.042),(.075,.075,.042),.008,'ink');L('Hour',(0,0,.043),(-.048,.04,.043),.01,'ink');done()

for name,title,base in [('poster_orbit','ORBIT CLUB','ink'),('poster_make','MAKE\nSOMETHING','sagewall'),('poster_sound','SIDE A','rust')]:
    start(name);B('Paper',(0,0,0),(.65,.87,.012),base,.004)
    for x in [-.29,.29]:B('Tape',(x,.405,.01),(.07,.055,.006),'mustard',.003)
    T('Title',title,(0,.26,.011),.072,'paper')
    if name=='poster_orbit':
        C('Planet',(0,-.1,.02),.14,.012,'mustard',32).rotation_euler.x=math.pi/2
        R('Orbit',(0,-.1,.026),.23,.007,'paper',(math.pi/2,0,0),48)
    elif name=='poster_make':
        for i in range(4):B('Blocks',(-.2+i*.13,-.19+(i%2)*.1,.02),(.1,.1,.014),'rust' if i%2 else 'mustard')
    else:
        for i in range(15):B('Soundbar',(-.25+i*.036,-.15,.02),(.017,.08+.19*abs(math.sin(i*.9)),.008),'paper',.003)
    done()
start('corkboard')
B('Frame',(0,0,0),(1.4,.95,.075),'oakdark');B('Cork',(0,0,.045),(1.29,.84,.025),'cork',.009)
for x in [-.61,.61]:S('Corner pin',(x,.36,.067),(.012,)*3,'metal',1)
done('Sharing lesson board; separate photos and notes can later be inspected.')
start('photo_card');B('Paper',(0,0,0),(.22,.27,.007),'paper',.003);B('Picture',(0,.022,.005),(.185,.18,.006),'denim',.002)
C('Sun',(.045,.065,.01),.025,.003,'mustard',16).rotation_euler.x=math.pi/2
B('Land',(0,-.025,.012),(.182,.07,.003),'sagewall',.002);S('Mountain',(-.04,.012,.015),(.065,.055,.006),'ink',1);S('Pin',(0,.123,.015),(.009,)*3,'rust',1);done('Fictional miniature landscape photo; no real personal details.')
start('sticky_note');B('Note',(0,0,0),(.13,.13,.006),'mustard',.002)
for y in [-.025,0,.025]:B('Ink',(0,y,.004),(.075,.003,.002),'ink',0)
done()
start('toy_robot')
for x in [-.095,.095]:B('Foot',(x,.045,.025),(.11,.09,.17),'ink');L('Leg',(x,.075,0),(x,.19,0),.025,'metal')
B('Body',(0,.28,0),(.27,.22,.17),'sagewall',.04);B('Panel',(0,.29,.09),(.16,.11,.02),'paper')
for x in [-.045,0,.045]:S('Indicator',(x,.29,.107),(.014,.014,.007),'screenlight',1)
B('Head',(0,.49,0),(.31,.19,.2),'paper',.045);B('Face',(0,.49,.108),(.245,.1,.012),'ink',.03)
for x in [-.058,.058]:S('Eye',(x,.5,.12),(.022,.025,.008),'screenlight',2)
L('Antenna',(0,.58,0),(.025,.66,0),.009,'metal');S('Tip',(.025,.66,0),(.02,)*3,'mustard')
for x in [-.19,.19]:L('Arm',(x*.75,.35,0),(x,.22,.025),.021,'metal');S('Hand',(x,.205,.025),(.036,)*3,'mustard')
done('Static friendly robot for the backup/recovery lesson; no scripts or animation.')
start('backup_drive');B('Drive',(0,.025,0),(.16,.05,.22),'ink',.02);B('Top label',(0,.053,-.01),(.1,.004,.12),'sagewall');B('Status',(0,.056,.074),(.026,.002,.004),'screenlight');done()
start('cable_loop')
for i in range(28):
    a=i*math.tau/28;b=(i+1)*math.tau/28;L('Cable',(.12*math.cos(a),.008,.07*math.sin(a)),(.12*math.cos(b),.008,.07*math.sin(b)),.004,'ink',6)
B('USB plug',(.14,.01,.01),(.033,.018,.015),'metal');done()
start('skateboard');B('Deck',(0,.12,0),(.22,.035,.76),'rust',.04);B('Grip',(0,.14,0),(.19,.006,.68),'ink',.025)
for z in [-.24,.24]:
    L('Truck',(-.12,.075,z),(.12,.075,z),.013,'metal')
    for x in [-.115,.115]:C('Wheel',(x,.052,z),.031,.025,'mustard',16).rotation_euler.y=math.pi/2
done()
start('basketball');S('Ball',(0,.12,0),(.12,)*3,'rust',3)
for rot in [(0,0,0),(math.pi/2,0,0),(0,math.pi/2,0)]:R('Seam',(0,.12,0),.119,.003,'ink',rot,32)
done()
start('sneaker');B('Sole',(0,.025,0),(.11,.05,.28),'paper',.023);B('Upper',(0,.075,-.01),(.105,.085,.25),'denim',.035)
for z in [-.05,-.015,.02]:L('Lace',(-.035,.115,z),(.035,.115,z+.015),.004,'paper',6)
B('Heel',(0,.095,-.115),(.07,.11,.035),'rust');done()
start('backpack');B('Bag',(0,.24,0),(.32,.48,.18),'rust',.07);B('Pocket',(0,.18,.115),(.25,.2,.085),'mustard',.045)
for x in [-.12,.12]:L('Strap',(x,.4,-.095),(x,.09,-.11),.018,'ink')
R('Handle',(0,.5,0),.04,.01,'ink',(math.pi/2,0,0),16);done()
start('guitar')
S('Lower bout',(0,.22,0),(.2,.24,.075),'oak',3);S('Upper bout',(0,.42,0),(.14,.17,.065),'oaklight',3)
B('Neck',(0,.76,0),(.055,.66,.038),'oakdark');B('Fingerboard',(0,.74,.025),(.049,.59,.012),'ink');B('Headstock',(0,1.12,0),(.08,.18,.03),'oak')
C('Soundhole',(0,.35,.074),.065,.005,'ink',24).rotation_euler.x=math.pi/2
for x in [-.014,-.008,-.002,.004,.01,.016]:L('String',(x,.16,.083),(x,1.17,.044),.0015,'paper',4)
for i in range(8):B('Fret',(0,.5+i*.075,.034),(.048,.003,.003),'metal',0)
for y in [1.06,1.12,1.18]:
    for x in [-.055,.055]:S('Tuner',(x,y,0),(.019,.009,.009),'metal',1)
done()
start('rug');B('Woven rug',(0,.008,0),(3.6,.016,2.8),'fabric',.025)
for x in [-1.64,1.64]:B('Side border',(x,.018,0),(.13,.006,2.7),'denim',.01)
for z in [-1.23,1.23]:B('End border',(0,.018,z),(3.4,.006,.14),'denim',.01)
for x in [-.9,0,.9]:B('Woven motif',(x,.022,0),(.16,.002,.65),'mustard',.01)
done()
start('laundry_basket')
C('Base',(0,.03,0),.23,.06,'fabric',24)
for i in range(24):
    a=i*math.tau/24;L('Woven upright',(.22*math.cos(a),.04,.22*math.sin(a)),(.26*math.cos(a),.5,.26*math.sin(a)),.016,'fabric')
for y in [.12,.25,.38,.5]:R('Woven rim',(0,y,0),.22+y*.08,.016,'paper',seg=32)
done()
start('hoodie');B('Folded sweatshirt',(0,.045,0),(.39,.09,.34),'denim',.035)
for x in [-.22,.22]:B('Folded sleeve',(x,.043,.02),(.12,.075,.28),'denim',.035)
S('Hood',(0,.08,-.11),(.13,.07,.12),'ink');done()
start('power_strip');B('Strip',(0,.018,0),(.22,.035,.055),'paper',.01)
for x in [-.07,0,.07]:B('Socket',(x,.038,0),(.02,.004,.019),'ink',.003)
done()
start('game_controller');B('Center',(0,.027,0),(.13,.05,.075),'ink',.025)
for x in [-.068,.068]:S('Grip',(x,.02,.025),(.04,.03,.065),'ink')
for x in [-.035,.035]:S('Stick',(x,.057,.008),(.014,.009,.014),'metal')
for x,z in [(.044,-.024),(.058,-.015),(.044,-.007)]:S('Button',(x,.054,z),(.005,.005,.005),'mustard',1)
done()

start('fairy_lights')
for i in range(48):
    a=-1.4+i*2.8/48;b=-1.4+(i+1)*2.8/48
    L('Wire',(a,.1*(a/1.4)**2,0),(b,.1*(b/1.4)**2,0),.005,'ink',5)
for i in range(13):
    x=-1.35+i*.225;y=.1*(x/1.4)**2
    L('Pendant wire',(x,y,0),(x,y-.05,0),.004,'ink',5)
    S('Warm bulb',(x,y-.065,.012),(.018,.026,.018),'mustard',2)
done('Decorative static string lights over the bed; no animation.')

for name,color in [('book_sage','sagewall'),('book_navy','ink')]:
    start(name);B('Pages',(0,.115,0),(.048,.23,.16),'paper',.002)
    for x in [-.031,.031]:B('Cover',(x,.115,0),(.008,.24,.17),color,.003)
    B('Spine',(0,.115,.083),(.067,.24,.013),color,.005)
    for y in [.06,.17]:B('Spine detail',(0,y,.091),(.042,.009,.003),'mustard',.002)
    done()

for i,r in enumerate(roots):r.location=((i%8)*9,-(i//8)*10,0)
bpy.context.preferences.filepaths.save_version=0
bpy.ops.wm.save_as_mainfile(filepath=str(OUT/'source/teen_bedroom.blend'))
(OUT/'catalog.json').write_text(json.dumps(catalog,indent=2))
assert len({e['name'] for e in catalog})==len(catalog),'Duplicate model name'
print('TEEN_BEDROOM_MODELS',len(catalog),'models',sum(e['triangles'] for e in catalog),'unique triangles')
