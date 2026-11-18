# Downloads the inpainting candidates and checks the SHA-256 published by
# Hugging Face for each file (LFS oid). Used only by this spike; never
# shipped. Licences: MI-GAN MIT (Picsart AI Research), LaMa-Dilated
# Apache-2.0 (LaMa authors; LiteRT conversion by mlboydaisuke).
$ErrorActionPreference = 'Stop'
$dir = Join-Path $PSScriptRoot '..\assets\models'
New-Item -ItemType Directory -Force $dir | Out-Null
$models = @(
  @{ file = 'migan_fp16.tflite'
     url = 'https://huggingface.co/litert-community/MI-GAN-512-Places2-LiteRT/resolve/main/migan_fp16.tflite'
     sha = 'ef53f8dca69e5ce29629441128322c4d9a0a527b2a043703e0ab497f2463c25f' },
  @{ file = 'lama_dilated.tflite'
     url = 'https://huggingface.co/mlboydaisuke/LaMa-Dilated-LiteRT/resolve/main/lama_dilated.tflite'
     sha = 'a2ac8ed174be1233e4e518c8ef57fb943ea97162696dcd2d428c056280efe583' }
)
foreach ($m in $models) {
  $out = Join-Path $dir $m.file
  if (-not (Test-Path $out)) {
    $tmp = "$out.part"
    Invoke-WebRequest $m.url -OutFile $tmp -UseBasicParsing
    Move-Item $tmp $out
  }
  $hash = (Get-FileHash $out -Algorithm SHA256).Hash.ToLower()
  if ($hash -ne $m.sha) {
    Remove-Item $out
    throw "SHA-256 mismatch for $($m.file) ($hash)"
  }
  Write-Output "OK $($m.file) $hash"
}
