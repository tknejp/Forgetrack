param(
  [Parameter(Mandatory = $true)]
  [string]$SourceIconPath
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

Add-Type -AssemblyName System.Drawing

$workspaceRoot = Split-Path -Parent $PSScriptRoot
$brandDir = Join-Path $workspaceRoot 'assets/branding'
$androidResDir = Join-Path $workspaceRoot 'android/app/src/main/res'
$iosIconDir = Join-Path $workspaceRoot 'ios/Runner/Assets.xcassets/AppIcon.appiconset'
$iosLaunchDir = Join-Path $workspaceRoot 'ios/Runner/Assets.xcassets/LaunchImage.imageset'
$macosIconDir = Join-Path $workspaceRoot 'macos/Runner/Assets.xcassets/AppIcon.appiconset'
$webDir = Join-Path $workspaceRoot 'web'
$webIconsDir = Join-Path $webDir 'icons'
$windowsIconPath = Join-Path $workspaceRoot 'windows/runner/resources/app_icon.ico'

$brandBackdrop = [System.Drawing.Color]::FromArgb(255, 0x22, 0x1F, 0x2D)
$sourceResolved = (Resolve-Path $SourceIconPath).Path
$launcherIconScale = 0.82
$adaptiveForegroundScale = 0.74
$launchImageScale = 0.80
$androidLauncherOffsetY = 0.04
$androidAdaptiveOffsetY = 0.04

function New-CanvasBitmap {
  param(
    [int]$Width,
    [int]$Height,
    [System.Drawing.Color]$BackgroundColor
  )

  $bitmap = New-Object System.Drawing.Bitmap $Width, $Height, ([System.Drawing.Imaging.PixelFormat]::Format32bppArgb)
  $graphics = [System.Drawing.Graphics]::FromImage($bitmap)
  $graphics.Clear($BackgroundColor)
  $graphics.CompositingQuality = [System.Drawing.Drawing2D.CompositingQuality]::HighQuality
  $graphics.InterpolationMode = [System.Drawing.Drawing2D.InterpolationMode]::HighQualityBicubic
  $graphics.PixelOffsetMode = [System.Drawing.Drawing2D.PixelOffsetMode]::HighQuality
  $graphics.SmoothingMode = [System.Drawing.Drawing2D.SmoothingMode]::HighQuality

  return @{
    Bitmap = $bitmap
    Graphics = $graphics
  }
}

function Save-Png {
  param(
    [System.Drawing.Bitmap]$Bitmap,
    [string]$Path
  )

  $directory = Split-Path -Parent $Path
  if (-not (Test-Path $directory)) {
    New-Item -ItemType Directory -Path $directory -Force | Out-Null
  }

  $Bitmap.Save($Path, [System.Drawing.Imaging.ImageFormat]::Png)
}

function New-SquareBitmap {
  param(
    [System.Drawing.Image]$Source,
    [int]$Size,
    [bool]$OpaqueBackground,
    [double]$Scale = 1.0,
    [double]$OffsetXRatio = 0.0,
    [double]$OffsetYRatio = 0.0
  )

  $background = if ($OpaqueBackground) { $brandBackdrop } else { [System.Drawing.Color]::Transparent }
  $surface = New-CanvasBitmap -Width $Size -Height $Size -BackgroundColor $background
  $scaledSize = [Math]::Round($Size * $Scale)
  $baseOffset = [Math]::Round(($Size - $scaledSize) / 2.0)
  $offsetX = $baseOffset + [Math]::Round($Size * $OffsetXRatio)
  $offsetY = $baseOffset + [Math]::Round($Size * $OffsetYRatio)
  $surface.Graphics.DrawImage(
    $Source,
    [System.Drawing.Rectangle]::new($offsetX, $offsetY, $scaledSize, $scaledSize),
    [System.Drawing.Rectangle]::new(0, 0, $Source.Width, $Source.Height),
    [System.Drawing.GraphicsUnit]::Pixel
  )

  $surface.Graphics.Dispose()
  return $surface.Bitmap
}

function Save-ResizedPng {
  param(
    [System.Drawing.Image]$Source,
    [string]$Path,
    [int]$Size,
    [bool]$OpaqueBackground = $true,
    [double]$Scale = 1.0,
    [double]$OffsetXRatio = 0.0,
    [double]$OffsetYRatio = 0.0
  )

  $bitmap = New-SquareBitmap -Source $Source -Size $Size -OpaqueBackground:$OpaqueBackground -Scale $Scale -OffsetXRatio $OffsetXRatio -OffsetYRatio $OffsetYRatio
  try {
    Save-Png -Bitmap $bitmap -Path $Path
  } finally {
    $bitmap.Dispose()
  }
}

function Get-PngBytes {
  param(
    [System.Drawing.Image]$Source,
    [int]$Size,
    [double]$Scale = 1.0,
    [double]$OffsetXRatio = 0.0,
    [double]$OffsetYRatio = 0.0
  )

  $bitmap = New-SquareBitmap -Source $Source -Size $Size -OpaqueBackground:$true -Scale $Scale -OffsetXRatio $OffsetXRatio -OffsetYRatio $OffsetYRatio
  try {
    $stream = New-Object System.IO.MemoryStream
    try {
      $bitmap.Save($stream, [System.Drawing.Imaging.ImageFormat]::Png)
      return $stream.ToArray()
    } finally {
      $stream.Dispose()
    }
  } finally {
    $bitmap.Dispose()
  }
}

function Save-Ico {
  param(
    [System.Drawing.Image]$Source,
    [string]$Path,
    [int[]]$Sizes,
    [double]$Scale = 1.0,
    [double]$OffsetXRatio = 0.0,
    [double]$OffsetYRatio = 0.0
  )

  $directory = Split-Path -Parent $Path
  if (-not (Test-Path $directory)) {
    New-Item -ItemType Directory -Path $directory -Force | Out-Null
  }

  $entries = foreach ($size in $Sizes) {
    @{
      Size = $size
      Bytes = Get-PngBytes -Source $Source -Size $size -Scale $Scale -OffsetXRatio $OffsetXRatio -OffsetYRatio $OffsetYRatio
    }
  }

  $file = [System.IO.File]::Open($Path, [System.IO.FileMode]::Create, [System.IO.FileAccess]::Write)
  $writer = New-Object System.IO.BinaryWriter $file
  try {
    $writer.Write([UInt16]0)
    $writer.Write([UInt16]1)
    $writer.Write([UInt16]$entries.Count)

    $offset = 6 + (16 * $entries.Count)
    foreach ($entry in $entries) {
      $iconSize = if ($entry.Size -ge 256) { 0 } else { $entry.Size }
      $writer.Write([byte]$iconSize)
      $writer.Write([byte]$iconSize)
      $writer.Write([byte]0)
      $writer.Write([byte]0)
      $writer.Write([UInt16]1)
      $writer.Write([UInt16]32)
      $writer.Write([UInt32]$entry.Bytes.Length)
      $writer.Write([UInt32]$offset)
      $offset += $entry.Bytes.Length
    }

    foreach ($entry in $entries) {
      $writer.Write($entry.Bytes)
    }
  } finally {
    $writer.Dispose()
    $file.Dispose()
  }
}

if (-not (Test-Path $brandDir)) {
  New-Item -ItemType Directory -Path $brandDir -Force | Out-Null
}

$brandSourcePath = Join-Path $brandDir 'app-icon.png'
if ([System.StringComparer]::OrdinalIgnoreCase.Compare($sourceResolved, $brandSourcePath) -ne 0) {
  Copy-Item -LiteralPath $sourceResolved -Destination $brandSourcePath -Force
}

$sourceImage = [System.Drawing.Image]::FromFile($sourceResolved)
try {
  Save-ResizedPng -Source $sourceImage -Path (Join-Path $brandDir 'app-icon-square.png') -Size 1024 -Scale $launcherIconScale
  Save-ResizedPng -Source $sourceImage -Path (Join-Path $brandDir 'app-icon-foreground.png') -Size 1024 -OpaqueBackground:$false

  $androidLegacySizes = @{
    'mipmap-mdpi' = 48
    'mipmap-hdpi' = 72
    'mipmap-xhdpi' = 96
    'mipmap-xxhdpi' = 144
    'mipmap-xxxhdpi' = 192
  }

  foreach ($density in $androidLegacySizes.Keys) {
    $size = $androidLegacySizes[$density]
    $dir = Join-Path $androidResDir $density
    Save-ResizedPng -Source $sourceImage -Path (Join-Path $dir 'ic_launcher.png') -Size $size -Scale $launcherIconScale -OffsetYRatio $androidLauncherOffsetY
    Save-ResizedPng -Source $sourceImage -Path (Join-Path $dir 'ic_launcher_round.png') -Size $size -Scale $launcherIconScale -OffsetYRatio $androidLauncherOffsetY
  }

  $androidAdaptiveSizes = @{
    'mipmap-mdpi' = 108
    'mipmap-hdpi' = 162
    'mipmap-xhdpi' = 216
    'mipmap-xxhdpi' = 324
    'mipmap-xxxhdpi' = 432
  }

  foreach ($density in $androidAdaptiveSizes.Keys) {
    $size = $androidAdaptiveSizes[$density]
    $dir = Join-Path $androidResDir $density
    Save-ResizedPng -Source $sourceImage -Path (Join-Path $dir 'ic_launcher_foreground.png') -Size $size -OpaqueBackground:$false -Scale $adaptiveForegroundScale -OffsetYRatio $androidAdaptiveOffsetY
  }

  Save-ResizedPng -Source $sourceImage -Path (Join-Path $iosLaunchDir 'LaunchImage.png') -Size 220 -OpaqueBackground:$false -Scale $launchImageScale
  Save-ResizedPng -Source $sourceImage -Path (Join-Path $iosLaunchDir 'LaunchImage@2x.png') -Size 440 -OpaqueBackground:$false -Scale $launchImageScale
  Save-ResizedPng -Source $sourceImage -Path (Join-Path $iosLaunchDir 'LaunchImage@3x.png') -Size 660 -OpaqueBackground:$false -Scale $launchImageScale

  $iosIconSizes = @(
    @{ Name = 'Icon-App-20x20@2x.png'; Size = 40 }
    @{ Name = 'Icon-App-20x20@3x.png'; Size = 60 }
    @{ Name = 'Icon-App-29x29@1x.png'; Size = 29 }
    @{ Name = 'Icon-App-29x29@2x.png'; Size = 58 }
    @{ Name = 'Icon-App-29x29@3x.png'; Size = 87 }
    @{ Name = 'Icon-App-40x40@1x.png'; Size = 40 }
    @{ Name = 'Icon-App-40x40@2x.png'; Size = 80 }
    @{ Name = 'Icon-App-40x40@3x.png'; Size = 120 }
    @{ Name = 'Icon-App-60x60@2x.png'; Size = 120 }
    @{ Name = 'Icon-App-60x60@3x.png'; Size = 180 }
    @{ Name = 'Icon-App-20x20@1x.png'; Size = 20 }
    @{ Name = 'Icon-App-76x76@1x.png'; Size = 76 }
    @{ Name = 'Icon-App-76x76@2x.png'; Size = 152 }
    @{ Name = 'Icon-App-83.5x83.5@2x.png'; Size = 167 }
    @{ Name = 'Icon-App-1024x1024@1x.png'; Size = 1024 }
  )

  foreach ($entry in $iosIconSizes) {
    Save-ResizedPng -Source $sourceImage -Path (Join-Path $iosIconDir $entry.Name) -Size $entry.Size -Scale $launcherIconScale
  }

  $macosIconSizes = @(
    @{ Name = 'app_icon_16.png'; Size = 16 }
    @{ Name = 'app_icon_32.png'; Size = 32 }
    @{ Name = 'app_icon_64.png'; Size = 64 }
    @{ Name = 'app_icon_128.png'; Size = 128 }
    @{ Name = 'app_icon_256.png'; Size = 256 }
    @{ Name = 'app_icon_512.png'; Size = 512 }
    @{ Name = 'app_icon_1024.png'; Size = 1024 }
  )

  foreach ($entry in $macosIconSizes) {
    Save-ResizedPng -Source $sourceImage -Path (Join-Path $macosIconDir $entry.Name) -Size $entry.Size -Scale $launcherIconScale
  }

  Save-ResizedPng -Source $sourceImage -Path (Join-Path $webDir 'favicon.png') -Size 64 -Scale $launcherIconScale
  Save-ResizedPng -Source $sourceImage -Path (Join-Path $webIconsDir 'Icon-192.png') -Size 192 -Scale $launcherIconScale
  Save-ResizedPng -Source $sourceImage -Path (Join-Path $webIconsDir 'Icon-512.png') -Size 512 -Scale $launcherIconScale
  Save-ResizedPng -Source $sourceImage -Path (Join-Path $webIconsDir 'Icon-maskable-192.png') -Size 192 -Scale $launcherIconScale
  Save-ResizedPng -Source $sourceImage -Path (Join-Path $webIconsDir 'Icon-maskable-512.png') -Size 512 -Scale $launcherIconScale

  Save-Ico -Source $sourceImage -Path $windowsIconPath -Sizes @(16, 24, 32, 48, 64, 128, 256) -Scale $launcherIconScale
} finally {
  $sourceImage.Dispose()
}

Write-Output 'Branding assets generated successfully.'
