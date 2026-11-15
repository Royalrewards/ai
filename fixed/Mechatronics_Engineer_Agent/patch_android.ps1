param([string]$Label = "")
$ErrorActionPreference = "Stop"
$manifest = Join-Path $PSScriptRoot "android\app\src\main\AndroidManifest.xml"
if (-not (Test-Path $manifest)) { Write-Host "Manifest not found: $manifest"; exit 1 }
$text = [System.IO.File]::ReadAllText($manifest)
if ($text -notmatch "android.permission.INTERNET") {
  $perm = '<uses-permission android:name="android.permission.INTERNET"/>' + "`r`n    " + '<application'
  $text = [regex]::new('<application').Replace($text, $perm, 1)
  Write-Host "Added INTERNET permission."
}
if ($Label -ne "") {
  $text = [regex]::new('android:label="[^"]*"').Replace($text, ('android:label="' + $Label + '"'), 1)
}
[System.IO.File]::WriteAllText($manifest, $text, (New-Object System.Text.UTF8Encoding($false)))
Write-Host "Android manifest patched."
exit 0
