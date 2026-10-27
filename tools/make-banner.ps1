# Dev-only: render the Nexus header image (1280x720) with GDI+, no external tools.
param([string]$Out = (Join-Path (Split-Path $PSScriptRoot -Parent) "dist\banner.png"))
Add-Type -AssemblyName System.Drawing
$w = 1280; $h = 720
$bmp = New-Object System.Drawing.Bitmap $w, $h
$g = [System.Drawing.Graphics]::FromImage($bmp)
$g.SmoothingMode = "AntiAlias"; $g.TextRenderingHint = "AntiAliasGridFit"
$bg = New-Object System.Drawing.Drawing2D.LinearGradientBrush ([System.Drawing.Rectangle]::new(0,0,$w,$h)), ([System.Drawing.Color]::FromArgb(18,20,24)), ([System.Drawing.Color]::FromArgb(40,30,22)), 60
$g.FillRectangle($bg, 0, 0, $w, $h)
# scanline texture
$pen = New-Object System.Drawing.Pen ([System.Drawing.Color]::FromArgb(18,255,255,255)), 1
for ($y = 0; $y -lt $h; $y += 4) { $g.DrawLine($pen, 0, $y, $w, $y) }
# radio "waveform" that gets flat-lined
$amber = [System.Drawing.Color]::FromArgb(255,176,56)
$wave = New-Object System.Drawing.Pen $amber, 4
$pts = @(); for ($x = 80; $x -le 640; $x += 8) { $a = 60 * [math]::Sin($x / 23.0) * [math]::Sin($x / 97.0); $pts += [System.Drawing.PointF]::new($x, 540 + $a) }
$g.DrawLines($wave, $pts)
$flat = New-Object System.Drawing.Pen $amber, 4
$g.DrawLine($flat, 640, 540, 1200, 540)
$g.DrawLine((New-Object System.Drawing.Pen ([System.Drawing.Color]::FromArgb(255,80,80)), 4), 640, 505, 640, 575)
# text
$f1 = New-Object System.Drawing.Font "Impact", 110, ([System.Drawing.FontStyle]::Regular), ([System.Drawing.GraphicsUnit]::Pixel)
if ($f1.Name -ne "Impact") { $f1 = New-Object System.Drawing.Font "Arial Black", 100, ([System.Drawing.FontStyle]::Bold), ([System.Drawing.GraphicsUnit]::Pixel) }
$f2 = New-Object System.Drawing.Font "Segoe UI", 38, ([System.Drawing.FontStyle]::Regular), ([System.Drawing.GraphicsUnit]::Pixel)
$f3 = New-Object System.Drawing.Font "Segoe UI", 26, ([System.Drawing.FontStyle]::Regular), ([System.Drawing.GraphicsUnit]::Pixel)
$white = [System.Drawing.Brushes]::White
$g.DrawString("SHUT UP, WESLEY", $f1, (New-Object System.Drawing.SolidBrush $amber), 76, 150)
$g.DrawString("Silences the repetitive Clan radio banter in MechWarrior 5: Mercenaries", $f2, $white, 80, 290)
$g.DrawString("Clan pilots  |  base commanders  |  rival Clanners  |  lance chatter", $f3, (New-Object System.Drawing.SolidBrush ([System.Drawing.Color]::FromArgb(200,200,200))), 82, 350)
$g.DrawString("Cockpit computer, briefings and story dialogue untouched", $f3, (New-Object System.Drawing.SolidBrush ([System.Drawing.Color]::FromArgb(200,200,200))), 82, 392)
$g.DrawString("Silent  /  Quiet variants", $f3, (New-Object System.Drawing.SolidBrush $amber), 82, 620)
$g.Dispose()
New-Item -ItemType Directory -Force (Split-Path $Out) | Out-Null
$bmp.Save($Out, [System.Drawing.Imaging.ImageFormat]::Png); $bmp.Dispose()
"wrote $Out $((Get-Item $Out).Length) bytes"
