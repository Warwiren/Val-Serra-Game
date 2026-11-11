@echo off
rem Val'Serra - mesure GPU des variantes de camera A et C (Godot 4.7.2).
rem Usage : glisser Godot_v4.7.2-stable_win64.exe sur ce fichier, ou double-cliquer puis coller son chemin.
rem Resultat : dossier mesures_gpu\ a la racine du projet, avec RESUME_GPU.md a renvoyer.
rem Voir docs\PROTOCOLE_VALIDATION_CAMERA_GPU.md
setlocal
for %%I in ("%~dp0..\..") do set "PROJ=%%~fI"
set "GODOT=%~1"
if "%GODOT%"=="" set /p "GODOT=Glissez ici Godot_v4.7.2-stable_win64.exe puis appuyez sur Entree : "
set "GODOT=%GODOT:"=%"
if not exist "%GODOT%" (
  echo Fichier introuvable : %GODOT%
  pause
  exit /b 1
)
set "OUT=%PROJ%\mesures_gpu"
if not exist "%OUT%" mkdir "%OUT%"
echo.
echo 7 parcours automatiques d'environ une minute chacun. Ne pas toucher au clavier ni a la souris,
echo laisser la fenetre du jeu au premier plan, fermer les applications lourdes.
echo.
call :run C forward_plus     3d    fplus          --disable-vsync
call :run A forward_plus     3d    fplus          --disable-vsync
call :run C gl_compatibility 3d    compat         --disable-vsync
call :run A gl_compatibility 3d    compat         --disable-vsync
call :run C forward_plus     aucun fplus          --disable-vsync
call :run C forward_plus     3d    fplus_ecran    --disable-vsync --fullscreen
call :run C forward_plus     3d    fplus_vsync
echo.
echo Resume...
"%GODOT%" --headless --path "%PROJ%" --script res://tools/perf/resume_gpu.gd -- --dir="%OUT%"
echo.
echo Termine. Fichier a renvoyer : %OUT%\RESUME_GPU.md
pause
exit /b 0

:run
echo   variante %1 - rendu %2 - paysage %3 (%4)
start "" /wait "%GODOT%" --path "%PROJ%" --rendering-method %2 --resolution 1280x720 %5 %6 res://scenes/explore25/camera_variante_%1.tscn -- --route=temoin --quit --nodebug --paysage=%3 --tag=%4 --out="%OUT%"
exit /b 0
