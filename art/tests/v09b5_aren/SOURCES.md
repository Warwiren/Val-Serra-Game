# V09B.5 — cycles candidats de marche et de course d'Aren (profil droit) — DOSSIER DE TEST

**Statut : CANDIDATS, NON VALIDÉS.** Essai réversible dans la forêt F5 (touche **B**). Les sprites P4.8 d'Aren
(`art/p45/chars/aren/`) ne sont ni modifiés ni remplacés.

| Élément | Origine |
|---|---|
| `walk_96x112/`, `run_96x112/` | pack Drive `Assets/ValSerra_V09B5_Aren_Marche_Course_ANIMATIONS.zip`, dossiers `frames_walk_96x112/`, `frames_run_96x112/` (`walk_right_00.png` → `walk_right_0.png`), copiés **sans retouche** |
| `walk_64x72/`, `run_64x72/` | même pack, `frames_walk_64x72/`, `frames_run_64x72/` (`*_PREVIEW.png`), copiés **sans retouche** |
| `cadence_v09b5.json` | mesures de cette intégration : ligne de sol, hauteur du personnage, foulée et recul du pied d'appui image par image (`tools/p49/foulee_v09b5.py`, contrôle à l'œil) |

Les poses viennent de planches générées, puis ont été réduites automatiquement par le pack (pas de repixelisation
manuelle) ; seul le profil droit existe. Les GIF, la vidéo, les planches sources et les spritesheets du pack restent
sur le Drive (projet léger). Import Godot : sans compression, sans mipmaps, `detect_3d/compress_to=0`.

Empreintes SHA-256 des images copiées :

```
23b6efdf429dab572b4f0a15c5aa953e46a938bee43213fa7fad3acbc4fa035c  run_64x72/run_right_0.png
db6b9718763b055a92a2dec05e5b5ff4f31bcf28d34af60270327f7248ed56ff  run_64x72/run_right_1.png
057d5c82e66b4fc97f720beb14493877dcb6d51d62f025369d488503fb4ad3e1  run_64x72/run_right_2.png
673d4670953fa51100d2f5188db4e4d0b456621411b80a45fa1043acb92df7b5  run_64x72/run_right_3.png
0134f3cbfbe929d3b0741ee329aacfb68d0480c9d48fe1ba9d362cf318857f98  run_64x72/run_right_4.png
76a183bf5e2612aa209cffbd1a6b4e8fe7a4658391b38b7bd1ba7e9381bb9063  run_64x72/run_right_5.png
a7ac6e8c9812113113d559188b457c97c4d17b189a9c467e7c9f318d051e5006  run_64x72/run_right_6.png
60c7ad698683dee325653d5c161bdf92cc979f0f1ef497020172bec51113f853  run_64x72/run_right_7.png
f9d5852df58ac16e9d1dabfc7fce1de039f360bf95a1b6e7d0d0c6f2dcd29a78  run_96x112/run_right_0.png
72d7843422a115ffa25ca442ed324711b99ef4e6d6871e426134717bca06cf71  run_96x112/run_right_1.png
04f3f1002cfc7644929838bbfa9ed7800756c81b935250db88a2471b55fe9cd4  run_96x112/run_right_2.png
c6852c143e6bc7b6204b4d2ec5b60b766169ba79a0978c2e29f2b430a1c501d2  run_96x112/run_right_3.png
3eb134dff7824fb90b222d8d56f29e21f87a82b5d92f13986093a23fb5a730af  run_96x112/run_right_4.png
6535debb76f6d5949498a78704997957abe21c5094e9509fa229fadbaaf251ad  run_96x112/run_right_5.png
98810e6fdd8e1bf697b1ecde4376d9688c084fa16ec0cace0ee621b1c3995911  run_96x112/run_right_6.png
c7e2b0bc23edd88f65ba55ee90fd758c3b0149d9aa6412ef6f7899e93f401fc4  run_96x112/run_right_7.png
2b5b582a573983c81a818bf0518810e6f1728851f7db2346f41b632d7581d755  walk_64x72/walk_right_0.png
3b5f8c05247700cddc5dd2d68e7f5bae1859b37263ba3d0c7b7705b305d91a79  walk_64x72/walk_right_1.png
520c9b0455016e524e29aa8683b74b160500efa1b83af8d0860261db5e52130a  walk_64x72/walk_right_2.png
e51b147caf51be493361318f315ef94f3f7658f3668f8535565d5016b977cd81  walk_64x72/walk_right_3.png
802590286b31db2d96b2bbc86d2d710fcbbf71e5be468e3b7f7915a8aba832ec  walk_64x72/walk_right_4.png
f470f2c2e87b0cf555a59a26c0bc721c4af0dfee85bd12cbb64863f0979efdd1  walk_64x72/walk_right_5.png
22acf9f1921c8a9f3a5f05e61ee039807cab0ede675ebe8215582e5c9214063a  walk_64x72/walk_right_6.png
f01f60c67616921aae276343ec3aee083d954cd5f59853558757df5ea1799416  walk_64x72/walk_right_7.png
182bead2c531854a547add43f6cf0459de45edb6f346d8c262b58f4f3f7405c3  walk_96x112/walk_right_0.png
7560feead9d854cd9b6c359542cba0cd11d0cef431f411123d29ba87fc8030a9  walk_96x112/walk_right_1.png
008274b0ea370a146a6ce20a9b867758b560d42ac67b99672fd3450cdafe70c8  walk_96x112/walk_right_2.png
b959acc319d50d123151cad50c4aaa71a6ce4ee3879597a18a14ebb9a67afa6d  walk_96x112/walk_right_3.png
f27ef47ba3d14d64fbaf8ced8142a1ade5b1cbf571510e0f57e79593e7187569  walk_96x112/walk_right_4.png
578b3b1698d20956f7bd7619890da0bc0d3205157a27dac50cef9e51d22bdf5b  walk_96x112/walk_right_5.png
897c27051668db2c9f52b0084170d0bcc14b1c3fa2e271fd8c66cdd2d34cd309  walk_96x112/walk_right_6.png
6d9b3495369148828513991d7a2d25279d5436d249f93d55e07513aa514245f8  walk_96x112/walk_right_7.png
```
