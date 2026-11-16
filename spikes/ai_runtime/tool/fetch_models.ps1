# Downloads the M3 reference models (Google MediaPipe EfficientNet-Lite0,
# generic ImageNet classifier, Apache-2.0 per Google's model cards) and
# verifies their SHA-256. Used only to test the runtime; never shipped.
$ErrorActionPreference = 'Stop'
$dir = Join-Path $PSScriptRoot '..\assets\models'
New-Item -ItemType Directory -Force $dir | Out-Null
$base = 'https://storage.googleapis.com/mediapipe-models/image_classifier/efficientnet_lite0'
$models = @{
  'int8'    = 'bc2ffe19c1118de0c0c2a9088992da5589722656e0fba81421385300a4a34b16'
  'float32' = '6c7ab0a6e5dcbf38a8c33b960996a55a3b4300b36a018c4545801de3a3c8bde0'
}
foreach ($variant in $models.Keys) {
  $file = Join-Path $dir "efficientnet_lite0_$variant.tflite"
  Invoke-WebRequest "$base/$variant/1/efficientnet_lite0.tflite" -OutFile $file -UseBasicParsing
  $hash = (Get-FileHash $file -Algorithm SHA256).Hash.ToLower()
  if ($hash -ne $models[$variant]) {
    Remove-Item $file
    throw "SHA-256 mismatch for $variant ($hash)"
  }
  Write-Output "OK $variant $hash"
}
