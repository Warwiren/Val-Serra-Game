#!/usr/bin/env python3
"""External lookdev validation. VTK render of *actual* Quaternius geometry and diffuse textures.
Not a Godot Forward+ screenshot: lighting, shadow softness, reflections differ.
"""
import os, math, json, collections
from pathlib import Path
import numpy as np
from PIL import Image, ImageDraw, ImageFont
import vtk
from vtk.util.numpy_support import numpy_to_vtk
from vtkmodules.vtkRenderingCore import vtkWindowToImageFilter
from vtkmodules.vtkIOImage import vtkPNGWriter
import trimesh

ROOT=Path('/mnt/data/ValSerra_P49_V07_FORET_STYLISEE_TEST')
WORLD=json.load(open(ROOT/'docs/V07_WORLD.json'))
PRE=ROOT/'previews'
PRE.mkdir(exist_ok=True)
window=vtk.vtkRenderWindow();window.SetOffScreenRendering(True);window.SetSize(1280,800);window.SetMultiSamples(0)
rend=vtk.vtkRenderer();rend.GradientBackgroundOn();rend.SetBackground(.068,.101,.115);rend.SetBackground2(.19,.235,.25);window.AddRenderer(rend)

MAPPERS={};TX={}

def as_poly(g):
 poly=vtk.vtkPolyData()
 v=np.asarray(g.vertices,dtype=np.float32)
 pts=vtk.vtkPoints();pts.SetData(numpy_to_vtk(v,deep=True));poly.SetPoints(pts)
 faces=np.asarray(g.faces,np.int64)
 c=np.column_stack([np.full(len(faces),3,dtype=np.int64),faces]).ravel()
 ca=vtk.vtkCellArray();ca.SetCells(len(faces),numpy_to_vtk(c,deep=True,array_type=vtk.VTK_ID_TYPE));poly.SetPolys(ca)
 vis=g.visual
 if isinstance(vis,trimesh.visual.texture.TextureVisuals) and vis.uv is not None:
  uv=np.asarray(vis.uv,dtype=np.float32)
  arr=numpy_to_vtk(uv,deep=True);arr.SetName('UV');arr.SetNumberOfComponents(2);poly.GetPointData().SetTCoords(arr)
 normal=vtk.vtkPolyDataNormals();normal.SetInputData(poly);normal.ComputePointNormalsOn();normal.ConsistencyOn();normal.SplittingOff();normal.Update()
 mapper=vtk.vtkPolyDataMapper();mapper.SetInputData(normal.GetOutput());mapper.ScalarVisibilityOff()
 return mapper

def vtktex(image,max_size=512):
 if image is None:return None
 if not isinstance(image,Image.Image):image=Image.fromarray(np.asarray(image))
 im=image.convert('RGBA')
 im.thumbnail((max_size,max_size),Image.Resampling.LANCZOS)
 aa=np.flipud(np.asarray(im)).copy();h,w=aa.shape[:2]
 data=vtk.vtkImageData();data.SetDimensions(w,h,1)
 val=numpy_to_vtk(aa.reshape(-1,4),deep=True,array_type=vtk.VTK_UNSIGNED_CHAR)
 val.SetNumberOfComponents(4);data.GetPointData().SetScalars(val)
 tx=vtk.vtkTexture();tx.SetInputData(data);tx.InterpolateOn();tx.RepeatOn();tx.MipmapOn()
 return tx

def load_model(model,geom_path=None):
 path=(ROOT/'assets/models'/(model+'.gltf')) if geom_path is None else geom_path
 s=trimesh.load(path,force='scene',process=False)
 objects=[]
 # geometry with any scene node transforms applied
 for idx,g in enumerate(s.dump(concatenate=False)):
  if len(g.faces)==0: continue
  mapper=as_poly(g)
  mat=getattr(g.visual,'material',None)
  tex=getattr(mat,'baseColorTexture',None)
  name=f'{model}_{idx}'
  tx=vtktex(tex,512 if model!='terrain' else 768)
  fac=getattr(mat,'baseColorFactor',None)
  fac=np.asarray(fac[:3],float)/255 if fac is not None and max(fac)>1 else (fac[:3] if fac is not None else (1.,1.,1.))
  objects.append((mapper,tx,fac))
 return objects

models={}
used=sorted({p['name'] for p in WORLD['placements']})
for n in used:
 models[n]=load_model(n)
models['terrain']=load_model('terrain',ROOT/'assets/geometry/SOL07_terrain_sculpte_36x28.glb')
models['skirt']=load_model('skirt',ROOT/'assets/geometry/DEC07_jupe_foret_HORS_JEU.glb')
models['water1']=load_model('water1',ROOT/'assets/eau/EAU061_eau_calme.glb')
models['water2']=load_model('water2',ROOT/'assets/eau/EAU061_courant_leger.glb')
print('loaded',len(models),'model variants; primitives',sum(map(len,models.values())),flush=True)

def make_actor(geom,texture,factor,color=(1,1,1),light=True):
 a=vtk.vtkActor();a.SetMapper(geom)
 prop=a.GetProperty();prop.SetInterpolationToPhong();prop.SetAmbient(.32 if light else .65);prop.SetDiffuse(.75 if light else .45);prop.SetSpecular(.035)
 rgb=np.asarray(color,dtype=float)*np.asarray(factor,dtype=float)
 prop.SetColor(*np.clip(rgb,.0,1.0))
 if texture is not None: a.SetTexture(texture)
 return a

# Ground and peripheral non-walkable skirt from the actual GLBs.
for mapper,texture,factor in models['skirt']:
 a=make_actor(mapper,texture,factor,(.84,.9,.79));a.GetProperty().SetAmbient(.48);rend.AddActor(a)
# Ground is textured as it exists in the pack. Water static approximation only.
for mapper,texture,factor in models['terrain']:
 a=make_actor(mapper,texture,factor,(1,1,1));a.GetProperty().SetAmbient(.52);rend.AddActor(a)
for idx,n in enumerate(['water1','water2']):
 for mapper,texture,factor in models[n]:
  a=make_actor(mapper,texture,(1.,1.,1.),(.14,.43,.44));a.GetProperty().SetAmbient(.30);a.GetProperty().SetDiffuse(.42);a.GetProperty().SetSpecular(.10);rend.AddActor(a)

# Real original meshes, transformed and textured; no external invented visuals.
for i,p in enumerate(WORLD['placements']):
 if p['role'] in ('understory','herb','grass','pebble','path_stone','flower') and i%2==1:continue
 n=p['name'];model=models[n];x,y,z=p['xyz'];ang=p['rotation_y_deg'];sc=p['scale']
 for mapper,tex,factor in model:
  a=make_actor(mapper,tex,factor,p['tint'])
  a.SetScale(sc,sc,sc);a.RotateY(ang);a.SetPosition(x,y,z)
  if p['role'] in ('grass','herb','understory'):
   a.GetProperty().SetAmbient(.44)
  rend.AddActor(a)
print('VTK actors:',rend.GetActors().GetNumberOfItems(),flush=True)
# Warm sun, cool fill (same intent for Godot). Soft shadow simulation unsupported in this renderer.
key=vtk.vtkLight();key.SetLightTypeToSceneLight();key.SetPosition(-35,38,15);key.SetFocalPoint(0,0,0);key.SetColor(1.,.84,.64);key.SetIntensity(1.25);rend.AddLight(key)
fill=vtk.vtkLight();fill.SetLightTypeToSceneLight();fill.SetPosition(18,22,-25);fill.SetFocalPoint(0,0,0);fill.SetColor(.61,.73,.86);fill.SetIntensity(.32);rend.AddLight(fill)
rend.AutomaticLightCreationOff()

cam=rend.GetActiveCamera()
font='/usr/share/fonts/truetype/dejavu/DejaVuSans.ttf'
FNT=ImageFont.truetype(font,23) if os.path.exists(font) else ImageFont.load_default()
SM=ImageFont.truetype(font,17) if os.path.exists(font) else ImageFont.load_default()

def snap(target,distance,heading,fname,angle=(20,30)):
 yaw,pitch=map(math.radians,angle)
 p=(target[0]+math.sin(yaw)*math.cos(pitch)*distance,target[1]+math.sin(pitch)*distance,target[2]+math.cos(yaw)*math.cos(pitch)*distance)
 cam.SetPosition(*p);cam.SetFocalPoint(*target);cam.SetViewUp(0,1,0);cam.SetViewAngle(30)
 rend.ResetCameraClippingRange();window.Render()
 grab=vtkWindowToImageFilter();grab.SetInput(window);grab.SetInputBufferTypeToRGB();grab.ReadFrontBufferOff();grab.Update()
 writer=vtkPNGWriter();writer.SetFileName(str(PRE/fname));writer.SetInputConnection(grab.GetOutputPort());writer.Write()
 im=Image.open(PRE/fname).convert('RGB');draw=ImageDraw.Draw(im)
 draw.rounded_rectangle((18,16,1018,74),radius=13,fill=(23,32,32))
 draw.text((34,22),heading,font=FNT,fill=(243,232,202))
 draw.text((35,52),'Aperçu VTK (végétation basse 1/2) | hors Godot',font=SM,fill=(184,196,187))
 im.save(PRE/fname)
 print('saved',fname,'cam',p,flush=True)

snap((-9.,.8,1.),28,'01  |  Entrée de la lisière  /  P30', 'V07_01_entree_P30.png')
snap((-1.5,.55,0.),32,'02  |  Clairière et chemin  /  P30','V07_02_clairiere_P30.png')
snap((7.,.85,-8.7),27,'03  |  Ruisseau et sous-bois  /  P30','V07_03_ruisseau_P30.png')
# Overview deferred to live Godot scene; prototype full placements in manifest
