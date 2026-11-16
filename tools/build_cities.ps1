# Builds assets/cities/cities.json from GeoNames' cities15000.zip.
#
# Source: https://download.geonames.org/export/dump/cities15000.zip
# Licence: Creative Commons Attribution 4.0 (GeoNames). Attribution is shown
# in the app's Live weather settings.
#
# Kept: populated places with population >= 50 000, plus capitals (PPLC).
# Coordinates are rounded to 2 decimals (~1 km): the app never needs, and
# therefore can never send, anything more precise (DECISIONS D-36).
#
# Output: compact JSON array of [id, name, asciiName, countryCode, lat, lon,
# population], sorted by population (descending), then id.
#
# Usage: pwsh tools/build_cities.ps1 -Zip path\to\cities15000.zip
param(
  [Parameter(Mandatory = $true)][string]$Zip,
  [int]$MinPopulation = 50000,
  [string]$Out = (Join-Path $PSScriptRoot '..\assets\cities\cities.json')
)
$ErrorActionPreference = 'Stop'
Add-Type -AssemblyName System.IO.Compression.FileSystem
$archive = [IO.Compression.ZipFile]::OpenRead((Resolve-Path $Zip))
try {
  $entry = $archive.Entries | Where-Object { $_.Name -eq 'cities15000.txt' }
  if (-not $entry) { throw 'cities15000.txt not found in archive' }
  $reader = New-Object IO.StreamReader($entry.Open(), [Text.Encoding]::UTF8)
  $inv = [Globalization.CultureInfo]::InvariantCulture
  $rows = New-Object System.Collections.Generic.List[object]
  while (($line = $reader.ReadLine()) -ne $null) {
    $f = $line.Split("`t")
    if ($f.Count -lt 15) { continue }
    $pop = [int64]$f[14]
    $capital = $f[7] -eq 'PPLC'
    if ($pop -lt $MinPopulation -and -not $capital) { continue }
    $rows.Add([pscustomobject]@{
      id   = [int64]$f[0]
      name = $f[1]
      ascii = $f[2]
      cc   = $f[8]
      lat  = [math]::Round([double]::Parse($f[4], $inv), 2)
      lon  = [math]::Round([double]::Parse($f[5], $inv), 2)
      pop  = $pop
    })
  }
  $reader.Close()
} finally {
  $archive.Dispose()
}
$sorted = $rows | Sort-Object @{ Expression = 'pop'; Descending = $true }, id
$sb = New-Object Text.StringBuilder
[void]$sb.Append('[')
$first = $true
foreach ($r in $sorted) {
  if (-not $first) { [void]$sb.Append(',') }
  $first = $false
  $name = ($r.name | ConvertTo-Json -Compress)
  $ascii = ($r.ascii | ConvertTo-Json -Compress)
  [void]$sb.Append("[$($r.id),$name,$ascii,`"$($r.cc)`",")
  [void]$sb.Append($r.lat.ToString($inv) + ',' + $r.lon.ToString($inv) + ',' + $r.pop + ']')
}
[void]$sb.Append(']')
New-Item -ItemType Directory -Force (Split-Path $Out) | Out-Null
[IO.File]::WriteAllText($Out, $sb.ToString(), (New-Object Text.UTF8Encoding($false)))
Write-Output ("{0} cities -> {1} ({2:N0} KB)" -f $rows.Count, $Out, ((Get-Item $Out).Length / 1KB))
