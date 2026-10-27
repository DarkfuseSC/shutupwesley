# Dev-only: package ShutUpWesley exactly the way the editor's Package Mod button does,
# but headless. Runs PGI's PackageMW5Mod UAT command.
param(
  [string]$Variant = "Silent",
  [string]$Editor = $(if ($env:MW5_EDITOR) { $env:MW5_EDITOR } else { "D:\Epic Games\Epic Games\MechWarrior5Editor" })
)
$ed  = $Editor
$proj = "$ed\MW5Mercs\MW5Mercs.uproject"
$mod  = "$ed\MW5Mercs\Plugins\ShutUpWesley"
$out  = "$ed\MW5Mercs\Mods"
$log  = Join-Path (Split-Path $PSScriptRoot -Parent) "package-$Variant.log"
New-Item -ItemType Directory -Force $out | Out-Null
$args = @(
  "PackageMW5Mod",
  "-Project=`"$proj`"",
  "-PluginPath=`"$mod`"",
  "-basedonreleaseversion=`"1.0`"",
  "-ModName=`"ShutUpWesley`"",
  # Bare folder name, NOT a path: UAT (MW5.cs) builds <plugin>/<name>/ itself and the
  # pak response file maps Saved/Cooked/.../<name>/* onto ../../../MW5Mercs/Content/.
  "-ModSubstitionFolder=ModOverride",
  "-DeployDirectory=`"$out`""
)
"running RunUAT $($args -join ' ')" | Set-Content $log
$p = Start-Process -FilePath "$ed\Engine\Build\BatchFiles\RunUAT.bat" -ArgumentList $args -WindowStyle Hidden -PassThru -RedirectStandardOutput "$log.out" -RedirectStandardError "$log.err"
"pid $($p.Id)"
