extends "res://tests/test_case.gd"
## P4.6 — taille constante entre l'attente et la marche (Ilya en combat : voir test_p47_corrections.gd).

const P45 := "res://art/p45/"


func _img(p: String) -> Image:
	return (load(p) as Texture2D).get_image()


func _height(img: Image) -> int:
	return img.get_used_rect().size.y


## Largeur de la tête : plus grande largeur dans les 15 % supérieurs de la silhouette.
func _head_w(img: Image) -> int:
	var r := img.get_used_rect()
	var best := 0
	for y in range(r.position.y, r.position.y + maxi(2, int(r.size.y * 0.15))):
		var x0 := -1
		var x1 := -1
		for x in img.get_width():
			if img.get_pixel(x, y).a > 0.5:
				if x0 < 0:
					x0 = x
				x1 = x
		best = maxi(best, x1 - x0 + 1)
	return best


## Symétrie gauche/droite du haut du corps (60 % supérieurs), autour de l'axe de la tête, sur ±8 px.
func _symmetry(img: Image) -> float:
	var r := img.get_used_rect()
	var xs: Array = []
	for y in range(r.position.y, r.position.y + int(r.size.y * 0.18)):
		for x in img.get_width():
			if img.get_pixel(x, y).a > 0.5:
				xs.append(x)
	var c := int((xs.min() + xs.max()) / 2)
	var same := 0
	var n := 0
	for y in range(r.position.y, r.position.y + int(r.size.y * 0.6)):
		for dx in range(-8, 9):
			n += 1
			if (img.get_pixel(c + dx, y).a > 0.5) == (img.get_pixel(c - dx, y).a > 0.5):
				same += 1
	return float(same) / n


func test_size_is_the_same_standing_and_walking() -> void:
	for who in ["aren", "ilya", "garde"]:
		for d in ["face", "back", "left", "right"]:
			var idle := _img(P45 + "chars/%s/idle_%s.png" % [who, d])
			var hs: Array = []
			var ws: Array = []
			for i in 4:
				var w := _img(P45 + "chars/%s/walk_%s_%d.png" % [who, d, i])
				hs.append(_height(w))
				ws.append(_head_w(w))
			hs.sort()
			ws.sort()
			var mh: float = (hs[1] + hs[2]) / 2.0
			var mw: float = (ws[1] + ws[2]) / 2.0
			check(absf(_height(idle) - mh) <= 3.0, "%s %s : même hauteur à l'arrêt (%d) qu'en marche (%.1f)" % [who, d, _height(idle), mh])
			check(absf(_head_w(idle) - mw) <= 3.0, "%s %s : même taille de tête à l'arrêt (%d) qu'en marche (%.1f)" % [who, d, _head_w(idle), mw])
