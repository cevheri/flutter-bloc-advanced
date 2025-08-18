# Poppins font dosyalarını indirmek için PowerShell script
# Google Fonts'tan Poppins fontunu indir

$fontsDir = "assets/fonts"
$baseUrl = "https://fonts.gstatic.com/s/poppins/v20"

# Font dosyalarını indir
$fonts = @(
    @{name="Poppins-Regular.ttf"; url="$baseUrl/pxiEyp8kv8JHgFVrJJfecg.woff2"},
    @{name="Poppins-Medium.ttf"; url="$baseUrl/pxiByp8kv8JHgFVrLGT9Z1xlFQ.woff2"},
    @{name="Poppins-Bold.ttf"; url="$baseUrl/pxiByp8kv8JHgFVrLCz7Z1xlFQ.woff2"}
)

foreach ($font in $fonts) {
    $outputPath = Join-Path $fontsDir $font.name
    Write-Host "Downloading $($font.name)..."
    
    try {
        Invoke-WebRequest -Uri $font.url -OutFile $outputPath
        Write-Host "Successfully downloaded $($font.name)"
    }
    catch {
        Write-Host "Failed to download $($font.name): $($_.Exception.Message)"
        Write-Host "Please download manually from: https://fonts.google.com/specimen/Poppins"
    }
}

Write-Host "Font download completed!"
Write-Host "Please run: flutter pub get"
Write-Host "Then: flutter run"
