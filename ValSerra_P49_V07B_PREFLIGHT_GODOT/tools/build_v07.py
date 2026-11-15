#!/usr/bin/env python3
"""Val'Serra P4.9 V07 -- reproducible Quaternius stylized forest lookdev.
Data sources: user-supplied Quaternius Standard CC0 pack and local V06.1 terrain/stream.
No changes to upstream source assets, GitHub or Drive.
"""
from __future__ import annotations
from pathlib import Path
import json, math, random, shutil, os, zipfile, collections
import numpy as np
from PIL import Image, ImageDraw, ImageFont, ImageEnhance
import trimesh
from scipy.ndimage import map_coordinates

ROOT=Path('/mnt/data')
SRC=ROOT/'quaternius_unpack'
V06=ROOT/'ValSerra_P49_V06_1_RUISSEAU_TEST'
OUT=ROOT/'ValSerra_P49_V07_FORET_STYLISEE_TEST'
for sub in ['assets/geometry','assets/models','assets/eau','shaders','godot','docs','previews','tools']:
 (OUT/sub).mkdir(parents=True,exist_ok=True)

# Inputs -- full geometry and shader plus declared licence.
for name in ['SOL061_terrain_ravin_36x28.glb']:
 shutil.copy2(V06/'assets'/name,OUT/'assets/geometry'/name)
for name in ['EAU061_eau_calme.glb','EAU061_courant_leger.glb','EAU061_bruit_rides.png']:
 shutil.copy2(V06/'assets'/name,OUT/'assets/eau'/name)
shutil.copy2(V06/'shaders/EAU061_courant_stylise_CANDIDAT.gdshader',OUT/'shaders/EAU061_courant_stylise_CANDIDAT.gdshader')
shutil.copy2(SRC/'License_Standard.txt',OUT/'docs/Licence_Quaternius_Standard_CC0.txt')

SELECT=[
'CommonTree_2','CommonTree_4','CommonTree_5','Pine_1','Pine_2','Pine_4',
'TwistedTree_1','TwistedTree_3','DeadTree_2',
'Rock_Medium_1','Rock_Medium_2','Rock_Medium_3',
'RockPath_Round_Thin','RockPath_Round_Wide','RockPath_Square_Small_2',
'Pebble_Round_2','Pebble_Round_4','Pebble_Square_2','Pebble_Square_5',
'Bush_Common','Bush_Common_Flowers','Grass_Common_Short','Grass_Common_Tall',
'Grass_Wispy_Short','Grass_Wispy_Tall','Fern_1','Plant_1','Plant_7',
'Clover_2','Flower_3_Group','Flower_4_Group','Mushroom_Common'
]
# Use original glTF structures, textures and .bin; do not flatten material submeshes.
texused=set()
source_geos={}
for name in SELECT:
 original=SRC/'glTF'/(name+'.gltf')
 assert original.exists(),name
 info=json.loads(original.read_text())
 for image in info.get('images',[]):
  uri=image.get('uri','')
  assert '/' not in uri and '\\' not in uri and (SRC/'glTF'/uri).is_file(),(name,uri)
  texused.add(uri)
 assert (SRC/'glTF'/(name+'.bin')).is_file(),name
 shutil.copy2(original,OUT/'assets/models'/(name+'.gltf'))
 shutil.copy2(SRC/'glTF'/(name+'.bin'),OUT/'assets/models'/(name+'.bin'))
 source_geos[name]=trimesh.load(original,force='scene',process=False)
for tex in sorted(texused):shutil.copy2(SRC/'glTF'/tex,OUT/'assets/models'/tex)

# Artistic correction following the first textured VTK review:
# Quaternius Bush_Common uses a scarlet TwistedTree atlas; a field of scarlet bushes
# makes the place feel like a game-kit showcase, not Val'Serra's deep green forest.
# Create a bush-only forest variant; the lone twisted tree retains its original copper.
from colorsys import rgb_to_hsv, hsv_to_rgb
leaf=Image.open(OUT/'assets/models/Leaves_TwistedTree_C.png').convert('RGBA')
a=np.asarray(leaf,dtype=np.float32).copy();l=(a[:,:,:3]*[.29,.59,.12]).sum(axis=2)/255
# Preserve shaded highlights via luminance; painterly blue-green, desaturated sage.
shade=np.clip((l-.09)/.72,0,1)
a[:,:,0]=(45+66*shade);a[:,:,1]=(72+78*shade);a[:,:,2]=(55+46*shade)
a=a.astype('uint8')
Image.fromarray(a,'RGBA').save(OUT/'assets/models/Leaves_Bush_ValSerra_C.png',optimize=True)
for name in ['Bush_Common','Bush_Common_Flowers']:
 f=OUT/'assets/models'/(name+'.gltf')
 info=json.loads(f.read_text())
 for im in info.get('images',[]):
  if im.get('uri')=='Leaves_TwistedTree_C.png':im['uri']='Leaves_Bush_ValSerra_C.png'
 f.write_text(json.dumps(info,separators=(',',':')))
# Preserve ONE warm autumn silhouette; replace scarlet with subdued copper/gold.
fall=Image.open(OUT/'assets/models/Leaves_TwistedTree_C.png').convert('RGBA')
farr=np.asarray(fall,dtype=np.float32).copy()
fl=(farr[:,:,:3]*[.34,.53,.13]).sum(axis=2)/255.
shade=np.clip((fl-.09)/.70,0,1)
farr[:,:,0]=80+105*shade
farr[:,:,1]=46+85*shade
farr[:,:,2]=34+50*shade
Image.fromarray(np.uint8(farr),'RGBA').save(OUT/'assets/models/Leaves_ValSerra_Cuivre_C.png',optimize=True)
for name in ['TwistedTree_1','TwistedTree_3']:
 f=OUT/'assets/models'/(name+'.gltf')
 info=json.loads(f.read_text())
 for im in info.get('images',[]):
  if im.get('uri')=='Leaves_TwistedTree_C.png':im['uri']='Leaves_ValSerra_Cuivre_C.png'
 f.write_text(json.dumps(info,separators=(',',':')))
# Tone down grass without erasing its original illustrated leaf pattern.
for nm,mult in [('Grass.png',[.88,.86,.81]),('Leaves_NormalTree_C.png',[.85,.88,.80])]:
 f=OUT/'assets/models'/nm
 im=Image.open(f).convert('RGBA')
 ar=np.asarray(im,dtype=np.float32).copy()
 ar[:,:,:3]=np.clip(ar[:,:,:3]*np.array(mult)[None,None,:],0,255)
 Image.fromarray(ar.astype('uint8'),'RGBA').save(f,optimize=True)

# Ground: original geometry and major paths remain untouched, color grading is done by optional
# low-frequency grading map on a copy so the level remains reversible.
terrain=trimesh.load(V06/'assets/SOL061_terrain_ravin_36x28.glb',force='scene',process=False)
mesh=list(terrain.geometry.values())[0]
verts=mesh.vertices
assert len(mesh.faces)==90240 and (verts[:,0].max()-verts[:,0].min())>35.99
# The grid ordering was verified from the original 241x189 V06 exports.
from scipy.interpolate import LinearNDInterpolator
# bilinear height sampling from grid regular coordinates, with an exact fallback on nearby mesh cell.
xyz=verts
ix=np.unique(np.round(xyz[:,0],4)); iz=np.unique(np.round(xyz[:,2],4))
assert len(ix)==241 and len(iz)==189,(len(ix),len(iz))
height_grid=np.zeros((len(iz),len(ix)))
xi=np.clip(np.rint((xyz[:,0]+18)/36*240).astype(int),0,240)
zi=np.clip(np.rint((xyz[:,2]+14)/28*188).astype(int),0,188)
height_grid[zi,xi]=xyz[:,1]
def height(x,z):
 return float(map_coordinates(height_grid, [[(z+14)/28*188],[(x+18)/36*240]],order=1,mode='nearest')[0])

# Include a more stylized, less noisy terrain color study; retain texture-UV geometry.
# This is a diffuse grade, not a shader/mesh replacement. Avoid photogrammetric detail.
soil_old=Image.open(V06/'assets/SOL061_albedo_berges.png').convert('RGB')
soil_arr=np.asarray(soil_old).astype(np.float32)
# Desaturate the ochre path, retain readable golden pool under forest sun.
soil_new=np.clip(soil_arr*np.array([.88,.89,.89])[None,None,:]+np.array([3.5,3.0,2.5])[None,None,:],0,255).astype('uint8')
soil_img=Image.fromarray(soil_new,'RGB')
soil_img.save(OUT/'assets/geometry/SOL07_couleur_sous_bois.png',optimize=True)
mesh.visual.material.baseColorTexture=soil_img
mesh.visual.material.name='SOL07_terre_sous_bois_stylisee'
mesh.export(OUT/'assets/geometry/SOL07_terrain_sculpte_36x28.glb')

# Peripheral NON-WALKABLE art skirt prevents a void at P30 camera edges.
# Exact shared border heights; NO collision and NO new playable area.
from trimesh.visual.texture import TextureVisuals
from trimesh.visual.material import PBRMaterial
from PIL import ImageFilter
back_patch=soil_img
back_patch.save(OUT/'assets/geometry/SOL07_fond_foret.png',optimize=True)
xs=np.linspace(-28,28,113);zs=np.linspace(-24,24,97)
V=[];UV=[]
for z in zs:
 for x in xs:
  xc=float(np.clip(x,-18,18));zc=float(np.clip(z,-14,14))
  dist=math.hypot(x-xc,z-zc)
  hh=height(xc,zc)+0.035*dist+0.06*math.sin(x*.23+z*.12)*min(1,dist)
  V.append([x,hh,z]);UV.append([(xc+18)/36,(zc+14)/28])
F=[];nx=len(xs)
for izz in range(len(zs)-1):
 for ixx in range(len(xs)-1):
  cx=(xs[ixx]+xs[ixx+1])/2;cz=(zs[izz]+zs[izz+1])/2
  if abs(cx)<18 and abs(cz)<14:continue
  k=izz*nx+ixx
  F.extend([[k,k+nx,k+1],[k+1,k+nx,k+nx+1]])
ring=trimesh.Trimesh(vertices=np.array(V),faces=np.array(F),process=False,
    visual=TextureVisuals(uv=np.array(UV),material=PBRMaterial(name='DEC07_peripherie_non_jouable',
                       baseColorTexture=back_patch,roughnessFactor=.95,metallicFactor=0)))
ring.export(OUT/'assets/geometry/DEC07_jupe_foret_HORS_JEU.glb')
# Original included for comparison and QA. Only SOL07 is loaded in V07.

BASE_MAN=json.load(open(V06/'docs/P49_V061_GODOT_MANIFEST.json'))
ROUTES=BASE_MAN['routes']
route_arrays={k:np.asarray(v,float) for k,v in ROUTES.items()}

def dist_to_route(x,z,which=None):
 routes=[route_arrays[which]] if which else route_arrays.values()
 result=1e5
 for pts in routes:
  for a,b in zip(pts[:-1],pts[1:]):
   v=b-a;t=float(np.clip(np.dot([x-a[0],z-a[1]],v)/np.dot(v,v),0,1));h=a+v*t
   result=min(result,float(math.hypot(x-h[0],z-h[1])))
 return result

def zcreek(x):return -11.95 +.27*math.sin(.49*(x+1))+.10*math.sin(.96*x)
def dist_to_water(x,z):
 if x<.85 or x>15.75:return 100.0
 return abs(z-zcreek(x))

rng=random.Random(74219)
placements=[]
errors=[]
role_counts=collections.Counter()
style_colors={
 'forest':[0.76,0.88,0.73],
 'deep':[0.64,0.75,0.72],
 'sage':[0.84,0.86,0.73],
 'gold':[0.92,0.80,0.62],
 'bark':[0.88,0.84,0.78],
 'stone':[0.90,0.89,0.82],
 'fern':[0.72,0.87,0.74],
 'grass':[0.80,0.85,0.66],
 'accent':[0.93,0.78,0.67],
}

def add(model,x,z,scale,role='foliage',angle=None,style='forest',blocking=False,limit_route=None,water_buffer=None,base_offset=0.0,group=''):
 x=float(x);z=float(z);scale=float(scale)
 if abs(x)>17.65 or abs(z)>13.65:return False
 if limit_route is not None and dist_to_route(x,z)<limit_route:return False
 if water_buffer is not None and dist_to_water(x,z)<water_buffer:return False
 y=height(x,z)+base_offset
 item={'asset':'models/'+model+'.gltf','name':model,'xyz':[round(x,4),round(y,4),round(z,4)],
       'scale':round(scale,4),'rotation_y_deg':round(angle if angle is not None else rng.uniform(0,360),1),
       'role':role,'style':style,'tint':style_colors[style],'blocking':bool(blocking),'group':group or role}
 placements.append(item);role_counts[role]+=1
 return True

# Big silhouettes deliberately hand-spotted first; crowns overlap paths but trunks do not.
# Two protective rings frame the path, plus a tight north-west thicket, an opening at the Vorgane,
# and a diagonal line of willows/twisted trees above the creek.
HERO_TREES=[
 (-15.7,-4.9,'CommonTree_2',.86,'deep'),(-15.8,4.9,'CommonTree_4',.81,'forest'),
 (-12.7,-12.4,'Pine_2',.80,'deep'),(-9.4,-12.8,'Pine_4',.75,'deep'),(-5.8,-12.4,'CommonTree_5',.73,'forest'),
 (-9.3,-4.45,'CommonTree_4',.78,'forest'),(-5.5,-4.5,'CommonTree_2',.76,'sage'),
 (-0.9,-4.7,'CommonTree_2',.78,'forest'),(3.0,-4.8,'Pine_2',.65,'deep'),
 (11.9,-3.8,'CommonTree_2',.76,'forest'),(14.4,-6.8,'CommonTree_5',.71,'deep'),
 (-16.1,11.9,'Pine_1',.82,'deep'),(-12.5,12.0,'CommonTree_2',.74,'sage'),
 (-8.5,12.8,'CommonTree_5',.75,'forest'),(-4.2,12.55,'Pine_2',.76,'deep'),
 (1.0,12.6,'CommonTree_2',.87,'forest'),(6.6,12.1,'CommonTree_4',.80,'sage'),
 (12.5,12.8,'Pine_4',.77,'deep'),(16.5,11.3,'CommonTree_5',.75,'forest'),
 (-8.2,4.1,'CommonTree_5',.75,'forest'),(-2.7,4.25,'CommonTree_4',.81,'gold'),
 (3.3,4.25,'CommonTree_5',.76,'forest'),(14.0,4.7,'CommonTree_2',.77,'deep'),
 (16.0,-1.9,'Pine_2',.72,'deep'),
 (-16.0,-10.6,'CommonTree_2',.73,'forest'),(-2.8,-12.8,'Pine_1',.72,'deep'),
 (15.3,-12.8,'Pine_2',.66,'deep'),(-16.3,8.0,'Pine_2',.68,'deep'),
]
for idx,(x,z,n,s,sty) in enumerate(HERO_TREES):
 ok=add(n,x,z,s,role='tree',angle=rng.uniform(-145,145),style=sty,blocking=True,limit_route=1.92,water_buffer=1.5,base_offset=-.17*s,group='canopy')
 if not ok:errors.append((idx,x,z,n,round(dist_to_route(x,z),2),round(dist_to_water(x,z),2)))
# Organic, dramatic small-tree punctuation in the distance.
for x,z,n,s,sty in [(-14.,-8.7,'Pine_4',.45,'deep'),(-4.5,7.1,'DeadTree_2',.48,'bark'),
                     (14.2,-9.0,'TwistedTree_1',.34,'deep'),(9.5,12.5,'CommonTree_2',.66,'gold'),
                     (-2.8,-6.4,'CommonTree_4',.48,'deep')]:
 add(n,x,z,s,'tree',style=sty,blocking=True,limit_route=1.70,water_buffer=1.6,base_offset=-.12*s,group='accents')

# Scenic perimeter beyond the playable rectangle: deepen perspective at camera P30.
# These models are non-colliding, entirely outside the 36x28 playable test bounds.
PERIMETER=[(-22,-17),(-18.5,-18),(-12,-19),(-6,-18.2),(1,-19.5),(7,-18.7),(14,-19),(21,-16.6),
           (-24,-9),(-23,-2),(-23,5),(-22,13),(-20,18),(-13,19.3),(-5,18.9),(3,19),(11,19.6),(19,18.8),
           (23,11),(23,4),(23,-3),(23,-10),(16,-16.6),(-24,-15),(-18,18),(22,-17.7)]
for i,(x,z) in enumerate(PERIMETER):
 n=rng.choice(['CommonTree_2','CommonTree_4','CommonTree_5','Pine_2','Pine_4'])
 sc=rng.uniform(.65,.98)
 # No collision, sample the nearest height at border; enough for out-of-map sight lines.
 xc=float(np.clip(x,-18,18));zc=float(np.clip(z,-14,14))
 y=height(xc,zc)+0.035*math.hypot(x-xc,z-zc)-.1*sc
 placements.append({'asset':'models/'+n+'.gltf','name':n,'xyz':[x,round(y,4),z],
   'scale':round(sc,4),'rotation_y_deg':round(rng.uniform(0,360),1),
   'role':'backdrop','style':'deep','tint':style_colors['deep'],'blocking':False,'group':'non_playable_perimeter'})
 role_counts['backdrop']+=1

# Rock stacks set into talus, avoid a game-board sprinkle.
ROCK_ANCHORS=[(-14.5,-7.9),(-10.6,-5.2),(-7.0,-4.0),(-2.9,-6.0),(1.2,-5.4),(10.,-4.4),
              (15.,-7.6),(-11.8,5.6),(-6.5,5.2),(-.6,5.9),(7.1,5.3),(13.6,7.0),
              (-14.5,10.3),(-8.0,12.0),(5.3,12.4),(-11.5,-11.5),(-6.3,-11.1),(12.1,11.1)]
for i,(x,z) in enumerate(ROCK_ANCHORS):
 for j in range(rng.choice([1,2,2,3])):
  X=x+rng.uniform(-.65,.65);Z=z+rng.uniform(-.58,.58)
  n=rng.choice(['Rock_Medium_1','Rock_Medium_2','Rock_Medium_3'])
  s=rng.uniform(.24,.49) if j else rng.uniform(.45,.70)
  add(n,X,Z,s,'rock',style='stone',blocking=False,limit_route=1.37,water_buffer=.63,base_offset=-.17*s,group='rock_groups')

# Larger sculptural stone masses break the smooth V06 talus profile.
for x,z,n,s in [(-12.4,11.3,'Rock_Medium_2',1.10),(10.3,10.8,'Rock_Medium_1',.95),
                (-1.2,-5.2,'Rock_Medium_3',.96),(14.1,9.7,'Rock_Medium_1',1.04)]:
 add(n,x,z,s,'rock',style='stone',blocking=True,limit_route=3.15,water_buffer=2.,base_offset=-.33*s,group='sculptural_boulders')

# Around each tree cluster, undergrowth in asymmetric arcs, not uniform grid noise.
TREES=[p for p in placements if p['role']=='tree']
for i,t in enumerate(TREES):
 x,_,z=t['xyz']
 r0=rng.uniform(.9,1.8)
 for j in range(rng.randint(5,9)):
  ang=(j/7.0*2*math.pi)+rng.uniform(-.26,.26)+i*.14
  r=r0+rng.uniform(-.30,1.10)
  X=x+math.cos(ang)*r; Z=z+math.sin(ang)*r
  kind=rng.choices(['Bush_Common','Fern_1','Plant_1','Plant_7'],weights=[2,4,2,2])[0]
  s=(rng.uniform(.55,1.0) if kind=='Bush_Common' else rng.uniform(.34,.69))
  sty=rng.choice(['deep','forest','sage','fern'])
  add(kind,X,Z,s,'understory',style=sty,limit_route=1.0,water_buffer=.6,base_offset=-.03,group='tree_bases')

# Creek: banks feel damp and low, distinct from dry clearing; stones not placed in midwater.
for i in range(44):
 x=rng.uniform(1.15,15.3);side=rng.choice([-1,1]);z=zcreek(x)+side*rng.uniform(1.07,1.75)
 if rng.random()<.58:
  n=rng.choice(['Pebble_Round_2','Pebble_Round_4','Pebble_Square_2'])
  add(n,x,z,rng.uniform(.13,.29),'pebble',style='stone',limit_route=.70,water_buffer=.7,base_offset=-.015,group='stream_pebbles')
 else:
  n=rng.choice(['Fern_1','Grass_Wispy_Tall','Plant_7'])
  add(n,x,z,rng.uniform(.27,.51),'stream_plant',style='fern',limit_route=.75,water_buffer=.7,base_offset=-.025,group='stream_banks')

# Stonelets mark the edge and turns of paths, maintaining a clear walking corridor.
for route_name,route in route_arrays.items():
 for a,b in zip(route[:-1],route[1:]):
  delta=b-a;length=float(np.linalg.norm(delta));normal=np.array([-delta[1],delta[0]])/length
  segments=max(2,int(length/1.30))
  for i in range(segments):
   if rng.random()>.44:continue
   p=a+delta*((i+rng.random())/segments)+normal*rng.choice([-1,1])*rng.uniform(1.38,2.18)
   n=rng.choice(['RockPath_Round_Thin','RockPath_Square_Small_2','Pebble_Round_4','Pebble_Square_5'])
   add(n,p[0],p[1],rng.uniform(.13,.30),'path_stone',style='stone',limit_route=1.23,water_buffer=.65,base_offset=-.03,group='path_edges')

# Deliberate foliage pools at compositional nodes (south sunlit meadow, deep north shade).
CLUSTERS=[(-12,6.6,2.0,'sage'),(-7,6.5,1.55,'forest'),(4.9,5.9,1.9,'sage'),(12.7,8.7,2.4,'forest'),
          (-10,-3.9,1.5,'deep'),(-3.8,-3.8,1.8,'fern'),(8,-3.8,1.4,'fern'),(-4.2,-10.8,1.4,'deep'),
          (8.4,-9.3,1.7,'fern'),(13,-10.4,1.1,'fern'),(-6.5,10.8,1.4,'sage'),(0,10.4,1.7,'sage')]
for cx,cz,spread,sty in CLUSTERS:
 for _ in range(rng.randint(12,20)):
  r=spread*math.sqrt(rng.random());a=rng.random()*2*math.pi
  X=cx+r*math.cos(a);Z=cz+r*math.sin(a)
  n=rng.choices(['Grass_Common_Short','Grass_Wispy_Short','Grass_Wispy_Tall','Fern_1','Clover_2','Bush_Common'],weights=[5,4,2,1,2,1])[0]
  s=rng.uniform(.27,.53) if n.startswith('Grass') else rng.uniform(.3,.65)
  add(n,X,Z,s,'herb',style=sty if n!='Fern_1' else 'fern',limit_route=.80,water_buffer=.6,base_offset=-.015,group='vegetation_pools')

# Sparse border grass in luminous patches, with flowers as rare marks rather than confetti.
for _ in range(150):
 x=rng.uniform(-17.2,17.2);z=rng.uniform(-13.1,13.1)
 if rng.random()<.80 and dist_to_route(x,z)>4.7:continue
 kind=rng.choice(['Grass_Common_Short','Grass_Wispy_Short','Grass_Common_Tall','Grass_Wispy_Tall'])
 add(kind,x,z,rng.uniform(.20,.51),'grass',style=rng.choice(['forest','grass','sage']),limit_route=.72,water_buffer=.65,base_offset=-.015,group='scatter_secondary')
for cx,cz in [(-6,5.3),(1,4.3),(8,3.1),(-11,4.2),(3,-2.9)]:
 for _ in range(rng.randint(2,4)):
  x=cx+rng.uniform(-.9,.9);z=cz+rng.uniform(-.7,.7)
  add(rng.choice(['Flower_3_Group','Flower_4_Group']),x,z,rng.uniform(.25,.38),'flower',style='accent',limit_route=.95,water_buffer=.6,base_offset=-.01,group='warm_accents')

# QA geometry, route clearance and glTF dependencies.
TREE_ROCK=[p for p in placements if p['role'] in ('tree','rock')]
by_model=collections.Counter(p['name'] for p in placements)
by_style=collections.Counter(p['style'] for p in placements)
for p in placements:
 assert (p['role']=='backdrop' and abs(p['xyz'][0])<=28 and abs(p['xyz'][2])<=24) or (-17.7<=p['xyz'][0]<=17.7 and -13.7<=p['xyz'][2]<=13.7)
 assert (p['role']=='backdrop') or abs(p['xyz'][1]-height(p['xyz'][0],p['xyz'][2])) <= (.42 if p['group']=='sculptural_boulders' else .2)
 if p['blocking']:
  assert dist_to_route(p['xyz'][0],p['xyz'][2])>=1.70
 if p['name'] not in SELECT:raise ValueError('Unknown asset')

MANIFEST={
 'project':'Val\'Serra P4.9 V07 -- Quaternius Stylized Nature MegaKit Standard CC0',
 'status':'F6 LOOKDEV CANDIDAT; GLTF/GLB CHECKED OFFLINE, GODOT NOT RUN',
 'root_expected':'ValSerra_P49_V07_FORET_STYLISEE_TEST',
 'terrain_tiles':['geometry/SOL07_terrain_sculpte_36x28.glb'],
 'non_colliding_decor':['geometry/DEC07_jupe_foret_HORS_JEU.glb'],
 'water_assets':['eau/EAU061_eau_calme.glb','eau/EAU061_courant_leger.glb'],
 'water_barriers':BASE_MAN['water_barriers'],
 'routes':ROUTES,
 'character_start':BASE_MAN['character_start'],
 'camera':{'pitch_deg':30,'yaw_deg':20,'fov_deg':30,'zooms':[2,2.5,3]},
 'palette':style_colors,
 'placements':placements,
 'model_source':'Quaternius Stylized Nature MegaKit [Standard], CC0 1.0',
 'legal_note':'Source license included in docs/Licence_Quaternius_Standard_CC0.txt',
 'path_clearance':'blocking trees >=1.70m from route centerlines; plants/decorative rocks non-blocking',
 'source_files':['V06.1 SOL061_terrain_ravin_36x28.glb','V06.1 EAU061_eau_calme.glb','V06.1 EAU061_courant_leger.glb']
}
(OUT/'docs/V07_WORLD.json').write_text(json.dumps(MANIFEST,ensure_ascii=False,indent=2))
QA={'status':'EXTERNAL STRUCTURAL QA, no Godot playtest','number_models':len(SELECT),
 'number_model_images':len(texused),'number_placements':len(placements),'placements_by_role':dict(role_counts),
 'placements_by_model':dict(by_model),'placements_by_palette':dict(by_style),
 'tree_proposals_rejected':errors,
 'blocking_assets':sum(p['blocking'] for p in placements),
 'bounding_box':[-18,18,-14,14],
 'terrain_grid':{'x':241,'z':189,'triangles':len(mesh.faces)},
 'water_section_count':len(BASE_MAN['water_barriers']),
 'routes_m':{k:round(float(sum(np.linalg.norm(b-a) for a,b in zip(v[:-1],v[1:]))),2) for k,v in route_arrays.items()},
 'valid':True}
(OUT/'docs/V07_QA.json').write_text(json.dumps(QA,ensure_ascii=False,indent=2))
print('QA data:',QA)
print('Output assets:',len(list((OUT/'assets/models').iterdir())))
