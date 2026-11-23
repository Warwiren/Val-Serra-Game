from pathlib import Path
import json, collections, math, hashlib, zipfile, os
import numpy as np
from PIL import Image,ImageDraw,ImageFont,ImageFilter
import trimesh
ROOT=Path('/mnt/data')
P=ROOT/'ValSerra_P49_V07_FORET_STYLISEE_TEST'
world=json.loads((P/'docs/V07_WORLD.json').read_text());qa=json.loads((P/'docs/V07_QA.json').read_text())
FONT='/usr/share/fonts/truetype/dejavu/DejaVuSans.ttf'
f0=ImageFont.truetype(FONT,38);f1=ImageFont.truetype(FONT,24);f2=ImageFont.truetype(FONT,18);f3=ImageFont.truetype(FONT,15)
W,H=1650,1050
im=Image.new('RGB',(W,H),'#151e1d');dr=ImageDraw.Draw(im)
# card map area
MAP=(55,124,1216,995)
dr.rounded_rectangle((24,23,W-24,H-21),radius=25,fill='#202c29',outline='#5a6f59',width=2)
dr.text((57,45),'VAL’SERRA   /   P4.9 V07',font=f0,fill='#f1e4c7')
dr.text((57,92),'Implantation réelle : zone jouable 36 × 28 m, P30, ruisseau conservé',font=f2,fill='#b2bfad')
left,top,right,bottom=MAP
# use x -18..18,z -14..14. z -14 is top (north)
def pcoord(x,z):return (int(left+(x+18)/36*(right-left)), int(top+(z+14)/28*(bottom-top)))
dr.rounded_rectangle((left-2,top-2,right+2,bottom+2),radius=12,fill='#536247',outline='#b3aa7d',width=3)
# subtle contour bands, emphasize V06 sculpted terrain not fake photogrammetry
from scipy.ndimage import gaussian_filter
HMAP=np.zeros((189,241))
mesh=next(iter(trimesh.load(P/'assets/geometry/SOL07_terrain_sculpte_36x28.glb',force='scene').geometry.values()))
v=mesh.vertices
for pt in v:
 ix=int(round((pt[0]+18)/36*240));iz=int(round((pt[2]+14)/28*188));HMAP[iz,ix]=pt[1]
# sample colored height texture via gradient
rgb=np.zeros((600,800,3),dtype='uint8')
for iz in range(rgb.shape[0]):
 z=-14+iz/(rgb.shape[0]-1)*28
 for ix in range(rgb.shape[1]):
  x=-18+ix/(rgb.shape[1]-1)*36
  h=float(HMAP[min(188,int((z+14)/28*188)),min(240,int((x+18)/36*240))])
  q=min(1,max(0,h/2.15))
  rgb[iz,ix]=[round(57+24*q),round(78+24*q),round(52+16*q)]
map_img=Image.fromarray(rgb,'RGB').resize((right-left,bottom-top),Image.Resampling.BILINEAR)
im.paste(map_img,(left,top));dr=ImageDraw.Draw(im)
# coarse stylized contour guide at height levels, no other metadata
try:
 from skimage.measure import find_contours
 for lev in [.45,.9,1.3,1.7]:
  for curve in find_contours(HMAP,lev):
   if len(curve)<12:continue
   pts=[pcoord(-18+xy[1]/240*36,-14+xy[0]/188*28) for xy in curve[::2]]
   if len(pts)>1:dr.line(pts,fill='#81906f',width=2)
except Exception:pass
# paths: dark moss border then natural soil warm center
for name,path in world['routes'].items():
 points=[pcoord(x,z) for x,z in path]
 width=51 if name=='main' else 38
 dr.line(points,fill='#3c4635',width=width+16,joint='curve')
 dr.line(points,fill='#a88a62',width=width,joint='curve')
 dr.line(points,fill='#c2a578',width=max(4,width//3),joint='curve')
# stream approximate meander
stream=[]
for x in np.linspace(.85,15.75,165):
 z=-11.95+.27*math.sin(.49*(x+1))+.10*math.sin(.96*x)
 stream.append(pcoord(x,z))
dr.line(stream,fill='#33483e',width=73,joint='curve')
dr.line(stream,fill='#448f90',width=57,joint='curve')
dr.line(stream,fill='#72b8b2',width=12,joint='curve')
# approximate culling below small foliage, but all placements are REAL from manifest
for item in world['placements']:
 if item['role'] in ('tree','backdrop','rock'):continue
 x,_,z=item['xyz'];r=item['role'];sc=item['scale']
 if abs(x)>18 or abs(z)>14:continue
 cx,cy=pcoord(x,z)
 if r=='flower': c='#bd9974';rad=3
 elif r in ('path_stone','pebble'):c='#b2ab93';rad=2
 elif r in ('stream_plant','understory'):c='#375744';rad=3
 else:c='#6f9460';rad=2
 dr.ellipse((cx-rad,cy-rad,cx+rad,cy+rad),fill=c)
# rocks and trees overlay
for item in world['placements']:
 x,_,z=item['xyz'];r=item['role'];sc=item['scale']
 if abs(x)>18 or abs(z)>14:continue
 cx,cy=pcoord(x,z)
 if r=='rock':
  rd=max(4,round(sc*12));dr.ellipse((cx-rd,cy-rd,cx+rd,cy+rd),fill='#787d6d',outline='#acb39a',width=2)
 if r=='tree':
  rad=int(23*sc) if item['name'].startswith('Pine') else int(26*sc)
  c={'gold':'#aa9455','deep':'#304d43','sage':'#6c8758','forest':'#426d4b'}.get(item['style'],'#416e4e')
  dr.ellipse((cx-rad,cy-rad,cx+rad,cy+rad),fill=c,outline='#9db47e',width=2)
  dr.ellipse((cx-4,cy-4,cx+4,cy+4),fill='#453b2c')
# boundaries & focus
for point,name,color in [((-16,0),'ENTRÉE','#e9dab7'),((-2.5,-.5),'VORGANE','#e2b3ad'),((8,-11.7),'EAU','#90d1d1')]:
 cx,cy=pcoord(*point);dr.ellipse((cx-9,cy-9,cx+9,cy+9),fill=color,outline='#2b3648',width=3)
 dr.rounded_rectangle((cx+13,cy-22,cx+154,cy+10),radius=8,fill='#1c2925');dr.text((cx+20,cy-17),name,font=f3,fill='#e6e5d3')
# right legend
LX=1262
dr.text((LX,158),'V07 — forêt stylisée',font=f1,fill='#f4e9cc')
dr.line((LX,198,1605,198),fill='#718371',width=2)
stat=[('Zone jouable','36 × 28 m'),('Chemins conservés','3 parcours'),('Ruisseau','≈ 15 m'),('Placements','648'),('Arbres jouables','31'),('Arbres fond','26'),('Collisions déco','35 objets')]
y=220
for key,val in stat:
 dr.text((LX,y),key,font=f3,fill='#b2c0b2');dr.text((LX,y+21),val,font=f1,fill='#f0e4cc');y+=72
# palette chips
for j,(name,color) in enumerate([('vert sombre','#304d43'),('terre','#b99c70'),('Aether / eau','#448f90'),('roche','#777d6c')]):
 y=790+j*46;dr.rounded_rectangle((LX,y,LX+42,y+27),radius=7,fill=color);dr.text((LX+56,y+3),name,font=f3,fill='#e7e7d7')
# provenance
im.save(P/'previews/V07_PLAN_IMPLANTATION.png')

# Structural validation and exact file dependency checks.
used=set()
for p in world['placements']:
 fn=p['asset'];used.add(fn)
 assert (P/'assets'/fn).exists(),fn
for gltf in (P/'assets/models').glob('*.gltf'):
 j=json.loads(gltf.read_text())
 for image in j.get('images',[]):
  assert (gltf.parent/image['uri']).is_file(),(gltf.name,image['uri'])
 for buffer in j.get('buffers',[]):
  assert (gltf.parent/buffer['uri']).is_file(),(gltf.name,buffer['uri'])
for glb in ['geometry/SOL07_terrain_sculpte_36x28.glb','geometry/DEC07_jupe_foret_HORS_JEU.glb','eau/EAU061_eau_calme.glb','eau/EAU061_courant_leger.glb']:
 s=trimesh.load(P/'assets'/glb,force='scene',process=False)
 assert s.geometry and s.is_empty==False
 assert sum(len(g.faces) for g in s.geometry.values())>0
# Verify alignment of walkable routes and water stream, model list and files.
assert len(world['placements'])==qa['number_placements']
assert len(world['routes'])==3
assert qa['blocking_assets']==35
script=(P/'godot/P49_V07_Foret_Test.gd').read_text()
assert 'res://ValSerra_P49_V07_FORET_STYLISEE_TEST/' in script
assert 'V07_WORLD.json' in script and 'VEG061_blocages_NON_FINAUX' not in script
assert 'KEY_N:' in script and '_forest_root.add_child(body)' in script
readme='''# Val’Serra — P4.9 V07 · Forêt stylisée Quaternius (TEST)

**Statut : prototype artistique et technique, non validé dans Godot.** Aucun des assets n’est déclaré final. Cette V07 remplace les silhouettes provisoires de la forêt sur un **banc de test autonome** : elle ne modifie pas la scène F5 ni le gameplay de la branche P4.8.

## Contenu réalisé
- **Terrain sculpté 36 × 28 m** hérité de V06.1, avec diffuse harmonisée en ton forestier, sans changer la géométrie et les trois axes de marche.
- **Ruisseau sculpté** conservé au nord-est (eau calme + léger courant). Shader animé optionnel, non exécuté dans Godot.
- **648 placements**, dont **31 arbres sur la zone jouable** (collisions tronc), **26 arbres de décor au-delà de la limite jouable**, **33 rochers**, bosquets de sous-bois et végétation basse (non bloquants).
- **32 références de modèles Quaternius** sélectionnées (certaines réservées aux prochaines compositions). Les 3D et textures source sont dans `assets/models/`; les textures source ne sont pas réécrites.
- **Adaptations locales** : buissons de couleur sapin, feuillage d’un arbre exceptionnel en cuivre, herbes légèrement désaturées ; sol moins saturé.
- **Ceinture de décor NON JOUABLE** (sans collision) pour masquer le vide quand la caméra P30 voit au-delà des limites de test.
- **Scène F6 indépendante** avec chargement des vrais `.gltf`, sprites P4.8 depuis le projet hôte, eau et éclairage.

## Démarrage prévu (nécessite Godot 4.7.2)
1. Dans le projet du dépôt `Warwiren/Val-Serra-Game` sur **`p4-8-marche`**, décompresser **le dossier complet** `ValSerra_P49_V07_FORET_STYLISEE_TEST` à la racine du projet.
2. Ouvrir `res://ValSerra_P49_V07_FORET_STYLISEE_TEST/godot/P49_V07_Foret_Test.tscn`.
3. **F6** pour lancer cette scène uniquement. **F5 n’est pas modifié**.
4. Commandes prévues : ZQSD/flèches (marche), Maj (course), `1/2/3` (zooms ×2/×2,5/×3), `M` (parcours), `N` (basculer végétation + collisions associées), `V` (shader d’eau), `F` (brume), `H` (HUD), `R` (réinitialiser).

## Décisions artistiques
**Référence : tes quatre captures HD-2D, notamment les forêts ombragées avec chemins dorés, lumière dirigée, reliefs et arrière-plan atmosphérique.** Ici, le rendu est volontairement forestier vert sombre, avec une petite note cuivrée. Les assets Quaternius sont un point de départ stylisé à retravailler, pas des équivalents directs aux modèles d’Octopath Traveler II.

### Ce que V07 améliore par rapport aux maquettes V05/V06
- Des arbres réellement volumétriques avec textures d’origine, branches différenciées et variantes de silhouette.
- Moins d’uniformité de palette, bois et feuilles harmonisés, sous-bois regroupé autour de masses végétales.
- Des rochers plus lisibles en 3D, petits galets près du ruisseau, fleurs utilisées parcimonieusement.
- Davantage de profondeur autour de la scène avec une ceinture périphérique, sans agrandir la navigation.
- Un banc d’essai P30 avec la marche P4.8, trois parcours et comparaison végétation ON/OFF.

### Ce qui n’est PAS encore au niveau des inspirations
- Les formes Quaternius restent plus simples et plus « jeu stylisé » que les environnements d’Octopath II.
- Le terrain existant manque encore de **cassures de relief**, de transitions peintes détaillées, de falaises et de roches enracinées.
- La densité du feuillage et les ombres devront être évaluées **dans le vrai rendu Forward+** ; les vues VTK ne simulent pas le brouillard ni les ombres portées Godot.
- L’eau est statique sur les captures. Reflets, transparences, alpha sorting et shader restent à valider en GPU.
- Les cycles P4.8 d’Aren/Ilya restent provisoires ; ne pas confondre le progrès du décor avec la finition des personnages.

## Pièges et limites
- **Pas de Blender ni de Godot 4.7.2 exécutables** dans cette session : pas de test GPU, collision, shader, transparence ni performance mesurée.
- La scène n’est pas prête à remplacer l’avant-poste : c’est un laboratoire de rendu et de déplacement.
- Les captures dans `previews/` utilisent VTK et un échantillonnage partiel de la végétation basse pour la rapidité ; le **manifeste charge 100 % des 648 placements** sous Godot. Elles ne sont pas des captures du jeu.
- Le terrain plus vaste demeure borné par des collisions invisibles, afin d’éviter les sorties de carte.

## Provenance et licences
Les modèles et textures sont issus du fichier fourni par l’utilisateur `Stylized Nature MegaKit[Standard].zip`, **Quaternius — CC0 1.0**, texte de licence inclus dans `docs/Licence_Quaternius_Standard_CC0.txt`. Géométrie du terrain et de l’eau : packs Val’Serra V06.1 déjà préparés. La V07 a été faite comme adaptation/assemblage original pour Val’Serra, sans modifier les sources téléchargées.
'''
(P/'README_A_TESTER.md').write_text(readme)
(P/'docs/DECISION_ARTISTIQUE_V07.md').write_text('''# Décision DA — V07

**Verdict : amélioration réelle du décor et bon candidat pour un premier test P30, mais NON VALIDÉ artistiquement comme cible Octopath II.**

L'intégration dans Godot Forward+ doit être notre prochain jalon, sans passer du temps sur une V08 procédurale avant de voir le vrai rendu. À ce stade, on peut juger les silhouettes et le placement. On ne peut pas encore juger l’illumination, les ombres, les reflets ou le pixel art in situ.

### Porte de qualité
1. P30 ×2.5 : chemin et héros lisibles, aucune couronne parasite qui masque le joueur.
2. Marcher et courir sur les trois parcours, notamment à la lisière du ruisseau ; collision tronc / rocher cohérente.
3. Aucun scintillement d’alpha des arbres, ni disparition des végétaux au mouvement de caméra.
4. Comparer avec et sans brume, shader d’eau animé ON/OFF, et zoom ×3.
5. Vérifier FPS sur machine équipée GPU, log import, et captures PNG du **vrai moteur**.
6. Comparaison cote à cote avec les quatre références : juger composition, échelle, profondeur et direction lumineuse ; toute comparaison doit distinguer moteur réel et prévisualisation externe.

### Ordre des corrections après les premiers tests
- Priorité 1 : lumière / ombres / qualité de terrain et transitions, pas davantage de petits objets.
- Priorité 2 : bande riveraine et arbres à fortes silhouettes ; améliorer les modèles réellement visibles en P30.
- Priorité 3 : sprites/animations, puis extension aux bâtiments et autres zones.

Aucune mission Claude n’a été envoyée. Une seule tâche d’intégration se justifiera après revue des captures F6 si des erreurs restent à corriger.
''')
(P/'docs/SOURCES_ET_LICENCES.md').write_text('''# Provenance V07

- **Quaternius Stylized Nature MegaKit [Standard]** — fourni par l’utilisateur, fichier `Stylized Nature MegaKit[Standard].zip`. La version Standard indique **CC0 1.0 Universal** ; preuve : `docs/Licence_Quaternius_Standard_CC0.txt` reproduit le texte joint au zip. L’archive d’origine contient 68 modèles glTF ; V07 en sélectionne 32, avec 15 images de base et deux variantes de couleur locales.
- **Val’Serra P4.9 V06.1** — terrain GLB et ruisseau/risque de collisions selon manifestes fournis ; topographie jouable conservée, texture sol recalibrée, jupe de décor non jouable ajoutée.
- **Godot** — le script de test se base sur `src/explore25/actor25.gd` de la branche `p4-8-marche` déjà dans le projet. Les sprites Aren/Ilya restent externes au pack V07 et sont lus dans le projet de jeu.
- **Références photographiques de jeux** — les captures Octopath II fournies dans la conversation ont servi de *référence* et ne sont PAS repackagées ni reproduites dans les fichiers.

Le pack ne prétend pas être associé officiellement à Quaternius, Square Enix ni aux développeurs d'Octopath.
''')
(P/'docs/TESTS_GODOT_A_EXECUTER.md').write_text('''# Revue moteur Godot 4.7.2 -- V07

À exécuter par le créateur après extraction complète dans la branche `p4-8-marche` ; les tests ci-dessous ne sont pas exécutés dans cet environnement :

- [ ] **Importer** tous les `*.gltf` et `*.glb` sans messages rouges.
- [ ] **F6**, caméra P30, aucun crash ; **F5** reste sur l'avant-poste.
- [ ] **×2 / ×2,5 / ×3** : silhouettes lisibles, couronnes n'obscurcissant pas Aren/Ilya.
- [ ] **Marche** 2,2 m/s / **course** 3,6 m/s / halte / demi-tours : pas d'instabilité des animations P4.8.
- [ ] **3 parcours** : aucun trou, aucun blocage imprévu ; collisions des arbres vérifiées.
- [ ] **Ruisseau** : pas de passage possible dans l'eau (barrières); berge visible; V eau animée test.
- [ ] **N** : retirer la végétation et ses collisions (sans toucher au terrain ni à l'eau).
- [ ] **F** : brume ON/OFF ; vérifier ombres et transparences à la caméra.
- [ ] **Performances** : GPU, résolution et FPS sur ×2,5 et ×3 pendant déplacement.
- [ ] **Captures** de 3 points de vue, avec rapport visuel sur les quatre références.

Conseil : ne pas demander à Claude de refaire des assets non validés en programmant des retouches. Les ressources et l'éclairage doivent être évalués séparément.
''')
# Project note: Godot 4.7.2 target is user-specified; no engine execution claimed.
# SHA256 for key sources, exact artifacts and packet integrity.
checks={}
for file in [P/'assets/geometry/SOL07_terrain_sculpte_36x28.glb',P/'assets/geometry/DEC07_jupe_foret_HORS_JEU.glb',P/'godot/P49_V07_Foret_Test.gd',P/'docs/V07_WORLD.json']:
 checks[str(file.relative_to(P))]=hashlib.sha256(file.read_bytes()).hexdigest()
(P/'docs/CONTROLE_INTEGRITE_SHA256.json').write_text(json.dumps(checks,indent=2))
# F6 pack self-contained relative to source game Actor25.
print('EXACT SOURCE FOLDERS OK; model_count=',len(list((P/'assets/models').glob('*.gltf'))),'placements=',len(world['placements']))
print('PNG plan', (P/'previews/V07_PLAN_IMPLANTATION.png').stat().st_size)
