#!/usr/bin/env python3
"""GABARITS TECHNIQUES des bâtiments (P2, lot A) — géométrie exacte dans la projection du jeu, sans Blender.

Chaque bâtiment est décrit en MÈTRES (volumes simples : soubassement, murs, pignons, toit à deux pans avec débords,
cheminée) et rendu avec la caméra orthographique du jeu (plongée 35°, rotation 20°, projection exacte de
docs/media/gabarits_exploration/gabarits.json : 20 px natifs/m au sol, 1 m de hauteur = 16,38 px natifs), à la taille
d'affichage (2 px d'écran par px natif, comme les autres illustrations). Rendu par tampon de profondeur (z-buffer).

Sorties, docs/media/gabarits_batiments/<nom>/ :
  gabarit.png   volumes ombrés neutres, fond transparent : SUPPORT DE L'ILLUSTRATION (même cadre, même taille)
  zones.png     carte des matières (couleurs unies, légende dans gabarits.json)
  trait.png     arêtes des volumes et contours des ouvertures
  reperes.png   gabarit + emprise au sol (collision), ligne de tri, pied (pivot), point d'interaction de la porte,
                cotes en mètres et silhouette d'Aren (taille de jeu) devant la porte
et docs/media/gabarits_batiments/gabarits.json : dimensions, taille de texture, pivot, emprise et repères en px natifs
relatifs au pied, ouvertures en px de texture — directement utilisables par decor.json / zone.json.
    python3 tools/explore/gabarits_batiments.py
"""
import json
import math
import os
import numpy as np
from PIL import Image, ImageDraw, ImageFont

ROOT = os.path.dirname(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))
OUT = os.path.join(ROOT, "docs/media/gabarits_batiments")
proj = json.load(open(os.path.join(ROOT, "docs/media/gabarits_exploration/gabarits.json")))["projection_sol_vers_natif"]
AX, AY = np.array(proj["x"][:2]), np.array(proj["y"][:2])
HZ = 16.38                                  # px natifs par mètre de hauteur
SS = 2                                      # px d'écran par px natif
# direction vers la caméra (produit vectoriel des lignes de projection) : sert à la profondeur et à l'ombrage
_a = np.array([AX[0], AX[1], 0.0]); _b = np.array([AY[0], AY[1], -HZ])
TOWARD_CAM = -np.cross(_a, _b); TOWARD_CAM /= np.linalg.norm(TOWARD_CAM)
LIGHT = np.array([-0.55, -0.35, 0.76]); LIGHT /= np.linalg.norm(LIGHT)     # lune haute, depuis l'avant gauche

ZONES = {"pierre": (196, 196, 203), "enduit": (249, 237, 203), "poutre": (178, 136, 88), "bois": (255, 187, 88),
         "ardoise": (224, 108, 108), "vitre": (255, 255, 0), "porte": (120, 70, 200), "cheminee": (150, 150, 255),
         "planches": (210, 150, 90)}


def native(p):
    """(x, y, z) mètres -> px natifs (origine arbitraire, ramenée au pied ensuite)."""
    x, y, z = p
    return np.array([AX[0] * x + AX[1] * y, AY[0] * x + AY[1] * y - HZ * z])


class Building:
    def __init__(self, name):
        self.name = name
        self.tris = []          # (3 points 3D, zone, normale)
        self.openings = []      # (nom, type, face, 4 points 3D)
        self.beams = []         # bandes de colombage : (face, 4 points 3D)
        self.dims = {}

    def quad(self, p, zone, center=None):
        p = [np.array(q, float) for q in p]
        n = np.cross(p[1] - p[0], p[2] - p[0]); n /= np.linalg.norm(n) + 1e-9
        if center is not None:                                  # normale extérieure ; face cachée -> non rendue
            if (np.mean(p, 0) - np.array(center, float)) @ n < 0:
                n = -n
            if n @ TOWARD_CAM <= 1e-6:
                return
        elif n @ TOWARD_CAM < 0:
            n = -n
        self.tris.append((p, zone, n))                        # face plane entière (pas de diagonale)

    def tri(self, p, zone, center=None):
        p = [np.array(q, float) for q in p]
        n = np.cross(p[1] - p[0], p[2] - p[0]); n /= np.linalg.norm(n) + 1e-9
        if center is not None:
            if (np.mean(p, 0) - np.array(center, float)) @ n < 0:
                n = -n
            if n @ TOWARD_CAM <= 1e-6:
                return
        elif n @ TOWARD_CAM < 0:
            n = -n
        self.tris.append((p, zone, n))

    def box(self, x0, x1, y0, y1, z0, z1, zone, top=True):
        c = lambda x, y, z: (x, y, z)
        k = ((x0 + x1) / 2, (y0 + y1) / 2, (z0 + z1) / 2)
        self.quad([c(x0, y0, z0), c(x1, y0, z0), c(x1, y0, z1), c(x0, y0, z1)], zone, k)      # avant (-y)
        self.quad([c(x0, y1, z0), c(x1, y1, z0), c(x1, y1, z1), c(x0, y1, z1)], zone, k)      # arrière
        self.quad([c(x0, y0, z0), c(x0, y1, z0), c(x0, y1, z1), c(x0, y0, z1)], zone, k)      # gauche (-x)
        self.quad([c(x1, y0, z0), c(x1, y1, z0), c(x1, y1, z1), c(x1, y0, z1)], zone, k)      # droite
        if top:
            self.quad([c(x0, y0, z1), c(x1, y0, z1), c(x1, y1, z1), c(x0, y1, z1)], zone, k)

    def gabled(self, W, D, z0, H1, RH, wall, roof, ov_side, ov_front, thick=0.16):
        """Murs W×D (centrés), pignons sur les côtés, toit à deux pans (faîtage parallèle à la façade)."""
        x0, x1, y0, y1 = -W / 2, W / 2, -D / 2, D / 2
        self.box(x0, x1, y0, y1, z0, H1, wall, top=False)
        k = (0, 0, H1)
        for x in (x0, x1):
            self.tri([(x, y0, H1), (x, y1, H1), (x, 0, H1 + RH)], wall, k)
        slope = RH / (D / 2)
        ze = H1 - ov_front * slope                              # hauteur de l'égout au bord du débord
        X0, X1 = x0 - ov_side, x1 + ov_side
        for s in (-1, 1):
            ye = s * (D / 2 + ov_front)
            self.quad([(X0, ye, ze), (X1, ye, ze), (X1, 0, H1 + RH), (X0, 0, H1 + RH)], roof, k)
            # épaisseur visible de la rive (bord du toit)
            self.quad([(X0, ye, ze), (X1, ye, ze), (X1, ye, ze - thick), (X0, ye, ze - thick)], "poutre", k)
        for X in (X0, X1):                                     # tranche des pignons du toit
            for s in (-1, 1):
                ye = s * (D / 2 + ov_front)
                self.quad([(X, ye, ze), (X, 0, H1 + RH), (X, 0, H1 + RH - thick), (X, ye, ze - thick)], "poutre", k)

    def opening(self, name, kind, face, u0, u1, z0, z1, W, D):
        """Ouverture rectangulaire sur une face (« avant » : u le long de x ; « gauche » : u le long de y)."""
        eps = 0.02
        if face == "avant":
            p = [(u0, -D / 2 - eps, z0), (u1, -D / 2 - eps, z0), (u1, -D / 2 - eps, z1), (u0, -D / 2 - eps, z1)]
        else:
            p = [(-W / 2 - eps, u0, z0), (-W / 2 - eps, u1, z0), (-W / 2 - eps, u1, z1), (-W / 2 - eps, u0, z1)]
        self.openings.append((name, kind, face, [np.array(q, float) for q in p]))

    def beam(self, face, a, b, w, W, D):
        """Poutre de colombage (bande de largeur w, en mètres) entre deux points (u, z) d'une face."""
        a, b = np.array(a, float), np.array(b, float)
        d = b - a; d /= np.linalg.norm(d); n = np.array([-d[1], d[0]]) * w / 2
        pts = [a - n, b - n, b + n, a + n]
        eps = 0.015
        if face == "avant":
            P = [(u, -D / 2 - eps, z) for u, z in pts]
        else:
            P = [(-W / 2 - eps, u, z) for u, z in pts]
        self.beams.append([np.array(q, float) for q in P])


# ------------------------------------------------------------------------------------- rendu (z-buffer)
def render(b, margin=24):
    pts = np.array([native(p) for t in b.tris for p in t[0]]) * SS
    mn = np.floor(pts.min(0)) - margin
    mx = np.ceil(pts.max(0)) + margin
    Wt, Ht = int(mx[0] - mn[0]), int(mx[1] - mn[1])
    to_px = lambda p: native(p) * SS - mn
    zbuf = np.full((Ht, Wt), -1e9)
    shade = np.zeros((Ht, Wt), np.float32)
    zone = np.zeros((Ht, Wt), np.int32) - 1
    names = list(ZONES)

    def raster(P3, val_zone, val_shade, layer_eps=0.0):
        """Face plane convexe : couverture par polygone (bords inclus), profondeur = plan affine exact."""
        P = np.array([to_px(p) for p in P3])
        d = np.array([p @ TOWARD_CAM for p in P3]) + layer_eps
        x0, y0 = np.floor(P.min(0)).astype(int); x1, y1 = np.ceil(P.max(0)).astype(int)
        x0, y0 = max(x0, 0), max(y0, 0); x1, y1 = min(x1, Wt - 1), min(y1, Ht - 1)
        if x1 < x0 or y1 < y0:
            return
        m = Image.new("L", (x1 - x0 + 1, y1 - y0 + 1), 0)
        ImageDraw.Draw(m).polygon([(px - x0 - 0.5, py - y0 - 0.5) for px, py in P], fill=255)
        ins = np.asarray(m) > 0
        A = np.c_[P[:3], np.ones(3)]
        if abs(np.linalg.det(A)) < 1e-9:
            return
        ca = np.linalg.solve(A, d[:3])
        gy, gx = np.mgrid[y0:y1 + 1, x0:x1 + 1].astype(np.float64) + 0.5
        dep = ca[0] * gx + ca[1] * gy + ca[2]
        sub = zbuf[y0:y1 + 1, x0:x1 + 1]
        upd = ins & (dep >= sub - 1e-6)
        sub[upd] = dep[upd]
        if val_zone is not None:
            zone[y0:y1 + 1, x0:x1 + 1][upd] = val_zone
        if val_shade is not None:
            shade[y0:y1 + 1, x0:x1 + 1][upd] = val_shade

    for P3, zn, n in b.tris:
        # le toit l'emporte sur les arêtes des murs qui le touchent exactement (pas de liseré parasite)
        raster(P3, names.index(zn), 0.35 + 0.65 * max(0.0, float(n @ LIGHT)), 0.03 if zn == "ardoise" else 0.0)
    # colombage puis ouvertures, posés sur leurs faces (léger décalage vers la caméra)
    for P in b.beams:
        raster(P, names.index("poutre"), None, 1e-3)
    if getattr(b, "door_split", None):
        u, z0, z1 = b.door_split
        y = -b.dims["profondeur_m"] / 2 - 0.03
        raster([np.array(q, float) for q in [(u - 0.05, y, z0), (u + 0.05, y, z0), (u + 0.05, y, z1), (u - 0.05, y, z1)]], names.index("poutre"), None, 3e-3)
    for name, kind, face, P in b.openings:
        raster(P, names.index("porte" if kind == "porte" else "vitre"), None, 2e-3)
    alpha = zone >= 0
    base = np.array([[150, 150, 158], [235, 228, 210], [120, 92, 64], [190, 140, 80], [120, 112, 140], [70, 70, 80],
                     [96, 70, 50], [140, 136, 150], [168, 124, 80]], np.float32)       # teintes neutres par matière
    col = base[np.clip(zone, 0, None)] * shade[..., None]
    gab = np.dstack([np.clip(col, 0, 255), alpha * 255]).astype(np.uint8)
    zcol = np.array([ZONES[k] for k in names], np.uint8)[np.clip(zone, 0, None)]
    zones_img = np.dstack([zcol, alpha * 255]).astype(np.uint8)
    # arêtes : changement de profondeur ou de zone
    dz = np.zeros_like(alpha)
    zn = np.where(alpha, zone, -1)
    dz[:-1] |= zn[:-1] != zn[1:]; dz[:, :-1] |= zn[:, :-1] != zn[:, 1:]
    zb = np.where(alpha, zbuf, -50)
    dz[:-1] |= np.abs(zb[:-1] - zb[1:]) > 0.25; dz[:, :-1] |= np.abs(zb[:, :-1] - zb[:, 1:]) > 0.25
    trait = np.zeros((Ht, Wt, 4), np.uint8); trait[dz] = (30, 26, 36, 255)
    return {"mn": mn, "size": (Wt, Ht), "gabarit": gab, "zones": zones_img, "trait": trait, "to_px": to_px}


# ------------------------------------------------------------------------------------- bâtiments pilotes
def habitation():
    """HABITATION DE VILLAGE (concept « Village cottage ») : un étage et demi à colombages sur soubassement de
    pierre, pignon à gauche, cheminée côté gauche. Un peu plus grande que la maison de l'avant-poste (6,4 × 4,6 m,
    murs 4,6 m) parce qu'elle a un étage habitable : 7,2 × 5,0 m, murs 5,4 m."""
    b = Building("habitation")
    W, D, BASE, H1, RH = 7.2, 5.0, 0.8, 5.4, 2.4
    b.box(-W / 2 - 0.08, W / 2 + 0.08, -D / 2 - 0.08, D / 2 + 0.08, 0, BASE, "pierre")
    b.gabled(W, D, BASE, H1, RH, "enduit", "ardoise", ov_side=0.4, ov_front=0.55)
    cx, cy = -W / 2 + 1.3, 0.9                                   # cheminée (côté gauche, derrière le faîtage)
    b.box(cx - 0.42, cx + 0.42, cy - 0.42, cy + 0.42, H1, H1 + RH + 1.1, "cheminee")
    b.box(-0.55, 1.25, -D / 2 - 0.7, -D / 2 - 0.08, 0, 0.18, "pierre")          # marche devant la porte
    b.opening("porte", "porte", "avant", -0.25, 0.95, 0.18, 2.4, W, D)
    b.opening("fenetre_rdc_g", "fenetre", "avant", -2.55, -1.55, 1.3, 2.3, W, D)
    b.opening("fenetre_rdc_d", "fenetre", "avant", 1.8, 2.8, 1.3, 2.3, W, D)
    b.opening("fenetre_etage_g", "fenetre", "avant", -2.35, -1.45, 3.6, 4.5, W, D)
    b.opening("fenetre_etage_d", "fenetre", "avant", 1.6, 2.5, 3.6, 4.5, W, D)
    b.opening("fenetre_pignon", "fenetre", "gauche", -0.35, 0.35, 5.7, 6.4, W, D)
    b.opening("fenetre_cote", "fenetre", "gauche", -0.5, 0.4, 1.4, 2.3, W, D)
    for u in (-W / 2 + 0.1, -0.45, 1.15, W / 2 - 0.1):                            # colombage : poteaux
        b.beam("avant", (u, BASE), (u, H1), 0.2, W, D)
    for z in (BASE + 0.08, 3.1, H1 - 0.12):                                       # sablières (sous l'égout)
        b.beam("avant", (-W / 2, z), (W / 2, z), 0.18, W, D)
        b.beam("gauche", (-D / 2, z), (D / 2, z), 0.18, W, D)
    for u in (-D / 2 + 0.1, D / 2 - 0.1):
        b.beam("gauche", (u, BASE), (u, H1), 0.2, W, D)
    b.beam("avant", (-W / 2 + 0.2, 3.1), (-2.7, H1 - 0.2), 0.15, W, D)          # écharpes
    b.beam("avant", (W / 2 - 0.2, 3.1), (2.85, H1 - 0.2), 0.15, W, D)
    b.dims = {"largeur_facade_m": W, "profondeur_m": D, "soubassement_m": BASE, "hauteur_murs_m": H1,
              "faitage_m": H1 + RH, "debord_toit_m": {"pignons": 0.4, "facade": 0.55}, "porte_m": [1.2, 2.22],
              "fenetres_m": {"rdc": [1.0, 1.0], "etage": [0.9, 0.9]}}
    b.footprint = [(-W / 2, -D / 2), (W / 2, -D / 2), (W / 2, D / 2), (-W / 2, D / 2)]
    b.door = ("porte", (0.35, -D / 2 - 0.95))                      # point d'interaction : devant la marche
    return b


def remise():
    """REMISE / ANNEXE (concept « Shed / annex ») : volume bas en planches sur un seuil de pierre, toit à deux pans,
    double porte. Le bûcher, les tonneaux et la lanterne du concept sont des ACCESSOIRES séparés."""
    b = Building("remise")
    W, D, BASE, H1, RH = 4.4, 3.2, 0.25, 2.7, 1.25
    b.box(-W / 2 - 0.06, W / 2 + 0.06, -D / 2 - 0.06, D / 2 + 0.06, 0, BASE, "pierre")
    b.gabled(W, D, BASE, H1, RH, "planches", "ardoise", ov_side=0.35, ov_front=0.45)
    b.opening("porte", "porte", "avant", -0.95, 0.85, 0.12, 2.25, W, D)
    b.opening("lucarne_cote", "fenetre", "gauche", -0.3, 0.3, 1.55, 2.05, W, D)
    b.door_split = (-0.05, 0.12, 2.25)                          # montant central des deux vantaux
    for u in (-W / 2 + 0.08, W / 2 - 0.08):
        b.beam("avant", (u, BASE), (u, H1), 0.16, W, D)
    for u in (-D / 2 + 0.08, D / 2 - 0.08):
        b.beam("gauche", (u, BASE), (u, H1), 0.16, W, D)
    b.beam("avant", (-W / 2, H1 - 0.12), (W / 2, H1 - 0.12), 0.16, W, D)
    b.beam("gauche", (-D / 2, H1 - 0.12), (D / 2, H1 - 0.12), 0.16, W, D)
    b.dims = {"largeur_facade_m": W, "profondeur_m": D, "seuil_m": BASE, "hauteur_murs_m": H1, "faitage_m": H1 + RH,
              "debord_toit_m": {"pignons": 0.35, "facade": 0.45}, "porte_double_m": [1.8, 2.13]}
    b.footprint = [(-W / 2, -D / 2), (W / 2, -D / 2), (W / 2, D / 2), (-W / 2, D / 2)]
    b.door = ("porte", (-0.05, -D / 2 - 0.6))
    return b


# ------------------------------------------------------------------------------------- sorties
def foot_native(fp):
    """Pied du jeu (element_foot) : abscisse moyenne de l'emprise, ordonnée = bord avant (y maximal)."""
    pts = np.array([native((x, y, 0)) for x, y in fp])
    return np.array([pts[:, 0].mean(), pts[:, 1].max()]), pts


def aren_sprite():
    p = os.path.join(ROOT, "art/explore_hd2d/chars/aren/idle_face.png")
    im = Image.open(p).convert("RGBA")
    return im.resize((im.width * SS, im.height * SS), Image.NEAREST)


def main():
    os.makedirs(OUT, exist_ok=True)
    meta = {"_doc": "Gabarits techniques des bâtiments (P2 lot A). Textures en px d'ÉCRAN (affichées à l'échelle 0,5 "
                    "comme les illustrations du décor). Positions natives RELATIVES AU PIED (élément de zone.json : "
                    "abscisse moyenne de l'emprise, ordonnée du bord avant). Générés par tools/explore/gabarits_batiments.py.",
            "projection": {"sol_vers_natif": proj, "hauteur_1m_natif": HZ, "px_ecran_par_px_natif": SS,
                           "camera": "orthographique, plongée 35°, rotation 20° ; faces visibles : avant (-y), gauche (-x), dessus"},
            "legende_zones": {k: "#%02X%02X%02X" % v for k, v in ZONES.items()},
            "reference_echelle": {"maison_avant_poste_m": [6.4, 4.6, 4.6], "aren_hauteur_px_natif": 29, "aren_hauteur_m": 1.77},
            "batiments": {}}
    font = ImageFont.load_default()
    for b in (habitation(), remise()):
        r = render(b)
        d = os.path.join(OUT, b.name)
        os.makedirs(d, exist_ok=True)
        Image.fromarray(r["gabarit"], "RGBA").save(os.path.join(d, "gabarit.png"))
        Image.fromarray(r["zones"], "RGBA").save(os.path.join(d, "zones.png"))
        Image.fromarray(r["trait"], "RGBA").save(os.path.join(d, "trait.png"))
        foot, fp_nat = foot_native(b.footprint)
        to_tex = lambda q: q * SS - r["mn"]                      # natif -> px de texture
        pivot = to_tex(foot)
        rel = lambda q: [round(float(q[0] - foot[0]), 1), round(float(q[1] - foot[1]), 1)]
        door_nat = native((b.door[1][0], b.door[1][1], 0))
        ops = {}
        for name, kind, face, P in b.openings:
            px = np.array([r["to_px"](p) for p in P])
            ops[name] = {"type": kind, "face": face, "quadrilatere_texture": [[round(float(x), 1), round(float(y), 1)] for x, y in px]}
        # repères
        rep = Image.new("RGBA", r["size"], (34, 40, 34, 255))
        rep.alpha_composite(Image.fromarray(r["gabarit"], "RGBA"))
        rep.alpha_composite(Image.fromarray(r["trait"], "RGBA"))
        dr = ImageDraw.Draw(rep)
        fpt = [tuple(to_tex(q)) for q in fp_nat]
        dr.polygon(fpt, outline=(255, 70, 70, 255))
        dr.line(fpt + [fpt[0]], fill=(255, 70, 70, 255), width=3)
        dr.line([(0, pivot[1]), (r["size"][0], pivot[1])], fill=(80, 200, 255, 255), width=1)
        dr.ellipse([pivot[0] - 5, pivot[1] - 5, pivot[0] + 5, pivot[1] + 5], fill=(80, 200, 255, 255))
        dp = to_tex(door_nat)
        ar = aren_sprite()
        rep.alpha_composite(ar, (int(dp[0] - ar.width / 2), int(dp[1] - ar.height)))
        dr.ellipse([dp[0] - 6, dp[1] - 3, dp[0] + 6, dp[1] + 3], outline=(255, 220, 60, 255), width=2)
        txt = [b.name.upper(),
               "%.1f x %.1f m, murs %.1f m, faitage %.1f m" % (b.dims["largeur_facade_m"], b.dims["profondeur_m"], b.dims["hauteur_murs_m"], b.dims["faitage_m"]),
               "texture %d x %d px (ecran)" % r["size"],
               "rouge : emprise = collision ; bleu : ligne de tri + pied",
               "jaune : point d'interaction porte ; Aren a l'echelle du jeu"]
        for i, t in enumerate(txt):
            dr.text((6, 6 + 12 * i), t, fill=(255, 255, 255, 255), font=font)
        rep.save(os.path.join(d, "reperes.png"))
        meta["batiments"][b.name] = {
            "dimensions": b.dims,
            "texture_px": list(r["size"]),
            "pivot_texture_px": [round(float(pivot[0]), 1), round(float(pivot[1]), 1)],
            "emprise_natif_relative_au_pied": [rel(q) for q in fp_nat],
            "collision": "emprise des murs (soubassement compris) ; débords de toit et marche non bloquants",
            "ligne_de_tri": "bord avant de l'emprise (géré par depth_z du jeu, y compris en biais)",
            "point_interaction_porte_natif": rel(door_nat),
            "ouvertures": ops,
        }
        print("%-11s texture %4d×%-4d pivot %s emprise %s porte %s" % (b.name, *r["size"], meta["batiments"][b.name]["pivot_texture_px"],
              meta["batiments"][b.name]["emprise_natif_relative_au_pied"], meta["batiments"][b.name]["point_interaction_porte_natif"]))
    json.dump(meta, open(os.path.join(OUT, "gabarits.json"), "w"), ensure_ascii=False, indent=1)


if __name__ == "__main__":
    main()
