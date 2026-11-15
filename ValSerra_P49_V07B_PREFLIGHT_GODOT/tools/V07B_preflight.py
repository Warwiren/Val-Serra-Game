#!/usr/bin/env python3
"""Preflight V07B — static files only; never claims a Godot runtime test."""
from pathlib import Path
import json,sys,struct
ROOT=Path(__file__).resolve().parent.parent
D=json.loads((ROOT/'docs/V07_WORLD.json').read_text(encoding='utf-8'))
G=(ROOT/'godot/P49_V07_Foret_Test.gd').read_text(encoding='utf-8')
T=(ROOT/'godot/P49_V07_Foret_Test.tscn').read_text(encoding='utf-8')
checks=[]
def test(name, ok):
    checks.append((name,bool(ok)))
    print(('PASS' if ok else 'FAIL')+' | '+name)

test('manifest and root path',D['root_expected']==ROOT.name and (ROOT.name+'/') in G and (ROOT.name+'/') in T)
test('terrain count',len(D['terrain_tiles'])==1)
test('water count',len(D['water_assets'])==2)
test('three exploration routes',len(D['routes'])==3)
test('route heights match waypoints', all(len(D['route_ground_y'][key])==len(route) for key,route in D['routes'].items()))
test('P4.8 stride conversion in both characters', 'set_scale_k(25.2 / 63.0)' in G and 'set_scale_k(26.0 / 65.0)' in G)
test('toggle N controls collision', 'obstacle.set_deferred("collision_layer", 1 if enabled else 0)' in G and 'KEY_N: _set_forest_visible(' in G)
test('boundaries cover sculpted height', 'Vector3(.5, 9.0, 29)' in G and 'Vector3(37, 9.0, .5)' in G)
test('spawn placement based on ground height', 'spawn_ground_y' in G and all(0<=h<=2.3 for h in D['spawn_ground_y'].values()))
test('route debug marker height', 'ground_y + .075' in G)
test('fog toggle includes volumetric mode', '_world_env.volumetric_fog_enabled = fog_active' in G)
test('runtime smoke script provided',(ROOT/'godot/V07B_SmokeTest.gd').is_file())

assets=[]
for p in D['placements']:
    assets.append(p['asset'])
assets+= D['terrain_tiles']+D['water_assets']+D['non_colliding_decor']
test('648 placements in data',len(D['placements'])==648)
test('all referenced models & terrain files exist',all((ROOT/'assets'/name).is_file() for name in assets))

missing_deps=[]
for path in (ROOT/'assets/models').glob('*.gltf'):
    obj=json.loads(path.read_text(encoding='utf-8'))
    uris=[b.get('uri') for b in obj.get('buffers',[])] + [i.get('uri') for i in obj.get('images',[])]
    for uri in uris:
        if not uri or uri.startswith('data:'):continue
        if not (path.parent/uri).is_file(): missing_deps.append((path.name,uri))
test('glTF bin & texture dependencies',not missing_deps)

bad_glbs=[]
for path in (ROOT/'assets').rglob('*.glb'):
    dat=path.open('rb').read(12)
    if len(dat)!=12 or dat[:4]!=b'glTF' or int.from_bytes(dat[4:8],'little')!=2 or int.from_bytes(dat[8:12],'little')!=path.stat().st_size:
        bad_glbs.append(path.name)
test('glTF 2.0 binary headers/lengths',not bad_glbs)

test('Quaternius license retained',(ROOT/'docs/Licence_Quaternius_Standard_CC0.txt').is_file())
print('\nTOTAL: %s/%s static checks PASS. No Godot or GPU run.' %(sum(ok for _,ok in checks),len(checks)))
sys.exit(0 if all(ok for _,ok in checks) else 1)
