# Fiche de découpe — livrer un personnage ou un monstre animable

Cette fiche décrit **exactement** ce qu'un illustrateur (ou une production IA + retouche) doit livrer pour
qu'un personnage soit intégré et animé sans changer le code. Les calques actuels du prototype
(`art/hd/hero/`, `art/hd/vorgane/`) en sont des exemples conformes.

## 1. Chasseur (squelette humanoïde commun)

**Canevas** : 400 × 420 px (ou un multiple exact : 800 × 840, 1200 × 1260 pour une peinture haute définition).
Personnage **de profil trois-quarts, tourné vers la droite**, pieds posés sur la ligne y = 400 (×2, ×3…),
centré vers x = 196. Pose de garde légère : jambe avant devant, épée tenue basse vers l'avant.

**Un fichier par calque, tous au même cadrage** (fond transparent, PNG ou SVG) :

| Fichier | Contenu | Zone cachée à compléter |
|---|---|---|
| `cape` | Cape / pans arrière | La partie masquée par le torse |
| `arm_b_up`, `arm_b_lo` | Bras arrière : haut, puis avant-bras + main | L'épaule sous le torse |
| `leg_b_up`, `leg_b_lo` | Jambe arrière : cuisse, puis jambe + botte | Le haut de cuisse sous le manteau |
| `leg_f_up`, `leg_f_lo` | Jambe avant : idem | Idem |
| `pelvis` | Pans de manteau / jupe d'armure | Le haut sous la ceinture |
| `torso` | Torse, ceinture, accessoires, col | Le côté masqué par le bras avant |
| `head` | Tête + cheveux | Le cou sous le col |
| `sword` (ou arme) | Arme seule, tenue dans la main avant | La garde sous les doigts |
| `arm_f_up`, `arm_f_lo` | Bras avant : haut + épaulière, puis avant-bras + poing | L'épaule sous l'épaulière |

**Articulations (pivots)** à reporter dans `data/rig/<personnage>.json` : hanche, cou, épaules, coudes,
poignets, hanches gauche/droite, genoux. Chaque calque doit **déborder un peu au-delà de son articulation**
(arrondi) pour qu'aucun trou n'apparaisse quand le membre tourne.

Tous les Chasseurs qui partagent ce squelette réutilisent **les mêmes animations** (`data/rig/anim_sword.json`
pour l'épée). Une nouvelle famille d'armes = un nouveau fichier d'animations, partagé à son tour.

## 2. Monstre

**Canevas** libre (Vorgane : 760 × 540), **tourné vers la gauche**, pieds sur une ligne commune.

| Calque | Remarque |
|---|---|
| `body` | Tronc + pattes lointaines + patte arrière proche |
| `head`, `jaw` | Tête et mâchoire séparées (gueule qui s'ouvre) |
| `arm` + partie terminale | Patte d'attaque, la partie ciblable (griffe) séparée |
| `tail` | Queue (mouvement secondaire) |
| Pour **chaque partie ciblable** | état **intact** + état **brisé**, au même cadrage |
| Partie qui **éclate** | un calque **par éclat** + un calque de **plaie** dessous |

Points de ciblage (`anchors`) et pivots dans `data/rig/<monstre>.json`.

## 3. Arène 2.5D

6 à 8 plans, 1360 × 760 px (marge de 40 px autour d'un écran 1280 × 720) : ciel, crêtes, forêt lointaine,
forêt moyenne + bâtiments, arbres de cadrage, sol, premier plan, rayons de lumière. Les plans lointains sont
peints nets : **le flou, la brume et la lumière sont ajoutés par le moteur**.

## 4. Utiliser une IA d'image pour la base (conseils pratiques)

1. Générer **une seule image de référence** du personnage, de profil trois-quarts vers la droite, pose neutre,
   fond uni, éclairage simple. Exemple de consigne :
   *« Personnage de fantasy original, chasseur aux armes surdimensionnées, vue de profil trois-quarts tournée
   vers la droite, en pied, pose de combat neutre, épée tenue basse, fond gris uni, style illustration 2D
   peinte, contours nets, éclairage doux venant de la droite. »*
2. Dans Krita / Photoshop / Photopea : **détourer**, puis **découper** selon la liste ci-dessus et
   **redessiner les zones cachées** (épaules, hanches, haut des cuisses). C'est l'étape manuelle principale.
3. Exporter chaque calque au **même cadrage** (ne pas recadrer calque par calque).
4. Relever les pivots (coordonnées en pixels des articulations) dans la fiche JSON.
5. Lancer les tests (`tests/test_runner.tscn`) : ils vérifient fichiers, os et animations.
6. Ouvrir l'**Atelier d'animation** pour juger le résultat, ajuster pivots et débords.

**À éviter** : demander à l'IA plusieurs poses du même personnage (le visage, la tenue et l'arme dérivent),
ou les états brisés en images séparées (incohérents) — les peindre en retouchant le calque intact.

## 5. Estimation de charge (indicative)

| Élément | Illustrateur seul | IA + retouche |
|---|---|---|
| Chasseur découpé (13 calques) | 1 à 2 jours | ½ à 1 jour |
| Variante d'arme (calque `sword`) | 2 à 4 h | 1 à 2 h |
| Monstre articulé avec 3 parties brisables | 2 à 4 jours | 1 à 2 jours |
| Arène en 8 plans | 1 à 2 jours | ½ à 1 jour |
| Intégration (fiche JSON, réglage des pivots) | ½ jour par personnage, ½ à 1 jour par monstre | idem |
