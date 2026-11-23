extends RefCounted
## P4.9 V08A — mode de diagnostic des collisions, construit à partir des VRAIS colliders physiques de la scène.
##   orange : obstacles du décor (troncs, rochers) · turquoise : barrières d'eau · violet : bords de carte
##   jaune : terrain entre 35° et la pente maximale des personnages · rouge : terrain plus raide (infranchissable)
## Dessiné par-dessus le décor, translucide, sans ombre ; ne modifie rien. Emploi :
##   var d = preload("res://src/diag/diagnostic_collisions.gd").construire(racine, maillage_terrain, 45.0)
##   racine.add_child(d) ; d.visible = true / false

const COULEURS := {
	"obstacle": Color(1.0, 0.55, 0.1, 0.55),
	"eau": Color(0.2, 0.95, 0.95, 0.45),
	"bord": Color(0.75, 0.35, 1.0, 0.35),
	"autre": Color(1.0, 1.0, 1.0, 0.35),
	"pente_moyenne": Color(1.0, 0.9, 0.15, 0.45),
	"pente_forte": Color(1.0, 0.12, 0.08, 0.6),
}


static func _mat(c: Color) -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	m.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	m.albedo_color = c
	m.no_depth_test = true
	m.cull_mode = BaseMaterial3D.CULL_DISABLED
	m.disable_fog = true
	m.render_priority = 10
	return m


static func _categorie(body: CollisionObject3D, shape: Shape3D) -> String:
	var n := String(body.name)
	if n.begins_with("Terrain"):
		return ""
	if n.begins_with("River"):
		return "eau"
	if shape is BoxShape3D:
		return "bord" if (shape as BoxShape3D).size.y >= 2.0 else "eau"
	if shape is CylinderShape3D or shape is ConvexPolygonShape3D:
		return "obstacle"
	return "autre"


## pente_max_deg : pente maximale franchissable des personnages (floor_max_angle)
static func construire(racine: Node, terrain: MeshInstance3D, pente_max_deg: float) -> Node3D:
	var out := Node3D.new()
	out.name = "Diagnostic_collisions"
	out.visible = false
	var stack: Array = [racine]
	while not stack.is_empty():
		var n: Node = stack.pop_back()
		stack.append_array(n.get_children())
		if not (n is CollisionShape3D) or not (n.get_parent() is CollisionObject3D):
			continue
		var cs := n as CollisionShape3D
		if cs.shape == null or not (cs.get_parent() is StaticBody3D):
			continue
		var cat := _categorie(cs.get_parent() as CollisionObject3D, cs.shape)
		if cat == "":
			continue
		var mi := MeshInstance3D.new()
		mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		if cs.shape is CylinderShape3D:
			var cy := CylinderMesh.new()
			cy.top_radius = (cs.shape as CylinderShape3D).radius
			cy.bottom_radius = cy.top_radius
			cy.height = (cs.shape as CylinderShape3D).height
			mi.mesh = cy
		elif cs.shape is BoxShape3D:
			var bx := BoxMesh.new()
			bx.size = (cs.shape as BoxShape3D).size
			mi.mesh = bx
		else:
			mi.mesh = cs.shape.get_debug_mesh()
		mi.material_override = _mat(COULEURS[cat])
		out.add_child(mi)
		mi.global_transform = cs.global_transform
	if terrain != null:
		out.add_child(_pentes(terrain, pente_max_deg))
	return out


## triangles du terrain colorés selon leur pente (légèrement surélevés pour ne pas scintiller)
static func _pentes(terrain: MeshInstance3D, pente_max_deg: float) -> MeshInstance3D:
	var xf := terrain.global_transform
	var st_m := SurfaceTool.new()
	var st_f := SurfaceTool.new()
	st_m.begin(Mesh.PRIMITIVE_TRIANGLES)
	st_f.begin(Mesh.PRIMITIVE_TRIANGLES)
	var nm := 0
	var nf := 0
	for s in terrain.mesh.get_surface_count():
		var arr := terrain.mesh.surface_get_arrays(s)
		var v: PackedVector3Array = arr[Mesh.ARRAY_VERTEX]
		var idx: PackedInt32Array = arr[Mesh.ARRAY_INDEX] if arr[Mesh.ARRAY_INDEX] != null else PackedInt32Array(range(v.size()))
		for t in range(0, idx.size() - 2, 3):
			var a: Vector3 = xf * v[idx[t]]
			var b: Vector3 = xf * v[idx[t + 1]]
			var c: Vector3 = xf * v[idx[t + 2]]
			var nrm := (b - a).cross(c - a).normalized()
			var deg := rad_to_deg(acos(clampf(absf(nrm.y), 0.0, 1.0)))
			if deg < 35.0:
				continue
			var st := st_f if deg > pente_max_deg else st_m
			for p in [a, b, c]:
				st.add_vertex(p + Vector3.UP * 0.03)
			if deg > pente_max_deg:
				nf += 1
			else:
				nm += 1
	var mesh := ArrayMesh.new()
	if nm > 0:
		mesh = st_m.commit(mesh)
		mesh.surface_set_material(mesh.get_surface_count() - 1, _mat(COULEURS["pente_moyenne"]))
	if nf > 0:
		mesh = st_f.commit(mesh)
		mesh.surface_set_material(mesh.get_surface_count() - 1, _mat(COULEURS["pente_forte"]))
	var mi := MeshInstance3D.new()
	mi.name = "Pentes_%d_moyennes_%d_fortes" % [nm, nf]
	mi.mesh = mesh
	mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	return mi
