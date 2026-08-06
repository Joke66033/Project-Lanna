$files = @(
    'D:\project_lanna\lanna\lib\page\lean\leaning\consonant.dart',
    'D:\project_lanna\lanna\lib\page\lean\leaning\number.dart',
    'D:\project_lanna\lanna\lib\page\lean\leaning\spelling.dart',
    'D:\project_lanna\lanna\lib\page\lean\leaning\tone.dart',
    'D:\project_lanna\lanna\lib\page\lean\leaning\vowel.dart',
    'D:\project_lanna\lanna\lib\page\lean\train\writing_canvas.dart'
)
foreach ($f in $files) {
    $content = Get-Content $f -Raw
    $updated = $content -replace "fontFamily: 'sans-serif'", "fontFamily: 'LannaAkkhara'"
    Set-Content -Path $f -Value $updated -Encoding UTF8
    Write-Host "Done: $f"
}
Write-Host "All files updated!"
