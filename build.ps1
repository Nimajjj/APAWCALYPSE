# Build APAWCALYPSE pour Windows (executable testable).
#
# Prerequis :
#   - Godot 4.7
#   - Les "export templates" 4.7 installes (editeur : Project > Export > Manage Export Templates)
#   - Un export_presets.cfg present (copier export_presets.cfg.example si besoin)
#
# Usage :
#   ./build.ps1
#   ./build.ps1 -Godot "C:\chemin\Godot_console.exe" -Output "build\windows\APAWCALYPSE.exe"

param(
	[string]$Godot = "C:\Users\omist\Documents\.exe\Godot_v4.7-stable_win64.exe\Godot_v4.7-stable_win64_console.exe",
	[string]$Preset = "Windows Desktop",
	[string]$Output = "build\windows\APAWCALYPSE.exe"
)

$proj = $PSScriptRoot
New-Item -ItemType Directory -Force -Path (Split-Path $Output) | Out-Null
& $Godot --headless --path $proj --export-release $Preset (Join-Path $proj $Output)
if ($LASTEXITCODE -eq 0) { Write-Output "Build OK -> $Output" }
else { Write-Output "Build echoue (code $LASTEXITCODE). Verifier les export templates et export_presets.cfg." }
