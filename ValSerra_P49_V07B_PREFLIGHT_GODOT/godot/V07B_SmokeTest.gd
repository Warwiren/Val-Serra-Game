extends SceneTree
## V07B Godot runtime smoke-test. Run from project root:
## godot --headless --path . --script res://ValSerra_P49_V07B_PREFLIGHT_GODOT/godot/V07B_SmokeTest.gd
## Does NOT validate GPU rendering or visual quality.
const SCENE := "res://ValSerra_P49_V07B_PREFLIGHT_GODOT/godot/P49_V07_Foret_Test.tscn"

func _initialize() -> void:
    call_deferred("_check")

func _check() -> void:
    var err := change_scene_to_file(SCENE)
    if err != OK:
        push_error("V07B smoke FAIL: unable to load scene: " + str(err))
        quit(1)
        return
    for _i in range(90):
        await process_frame
    if current_scene == null:
        push_error("V07B smoke FAIL: scene did not instantiate")
        quit(1)
        return
    var scene := current_scene
    var hero := scene.get_node_or_null("Aren_test")
    var ilya := scene.get_node_or_null("Ilya_test")
    var forest := scene.get_node_or_null("FORET_V07_Quaternius_CC0")
    if hero == null or ilya == null or forest == null:
        push_error("V07B smoke FAIL: missing characters or forest root")
        quit(1)
        return
    var hero_anim: RefCounted = scene.get("_hero_anim")
    var ilya_anim: RefCounted = scene.get("_ilya_anim")
    if hero_anim == null or ilya_anim == null:
        push_error("V07B smoke FAIL: character animation controllers unavailable")
        quit(1)
        return
    var aren_stride := float(hero_anim.get("stride_m"))
    var ilya_stride := float(ilya_anim.get("stride_m"))
    if absf(aren_stride - .12) > .025 or absf(ilya_stride - .12) > .025:
        push_error("V07B smoke FAIL: invalid P4.8 stride %.3f %.3f m/image" % [aren_stride, ilya_stride])
        quit(1)
        return
    print("V07B SMOKE PASS: scene, characters, forest and P4.8 stride loaded. GPU/visual still untested.")
    quit(0)
