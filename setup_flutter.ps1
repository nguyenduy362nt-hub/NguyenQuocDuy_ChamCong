# Chạy 1 lần trong PowerShell, đứng tại thư mục này:  .\setup_flutter.ps1
# Tạo khung Android cho dự án Flutter "nguyenquocduy_chamcong", cấp quyền vị trí/camera, cho phép http://10.0.2.2.
$ErrorActionPreference = 'Stop'
$root = $PSScriptRoot
$app  = Join-Path $root 'nguyenquocduy_chamcong'
$tmp  = Join-Path $root '_tmp_create'

if (-not (Test-Path (Join-Path $app 'android'))) {
    flutter create $tmp --org com.nguyenquocduy --project-name nguyenquocduy_chamcong --platforms android
    Copy-Item (Join-Path $tmp 'android') $app -Recurse
    foreach ($f in '.metadata','analysis_options.yaml','.gitignore') {
        if (Test-Path (Join-Path $tmp $f)) { Copy-Item (Join-Path $tmp $f) $app -Force }
    }
    Remove-Item $tmp -Recurse -Force
}

# --- AndroidManifest: quyền + cho phép http ---
$mf = Join-Path $app 'android\app\src\main\AndroidManifest.xml'
$t  = Get-Content $mf -Raw -Encoding UTF8
if ($t -notmatch 'ACCESS_FINE_LOCATION') {
    $perm = @"
    <uses-permission android:name="android.permission.INTERNET"/>
    <uses-permission android:name="android.permission.ACCESS_FINE_LOCATION"/>
    <uses-permission android:name="android.permission.ACCESS_COARSE_LOCATION"/>
    <uses-permission android:name="android.permission.CAMERA"/>
    <uses-feature android:name="android.hardware.camera" android:required="false"/>
    <application android:usesCleartextTraffic="true"
"@
    $idx = $t.IndexOf('<application')
    $t = $t.Remove($idx, '<application'.Length).Insert($idx, $perm.TrimEnd())
    Set-Content $mf $t -Encoding UTF8
}

# --- minSdk = 23 (mobile_scanner yêu cầu) ---
foreach ($g in 'build.gradle.kts','build.gradle') {
    $gp = Join-Path $app "android\app\$g"
    if (Test-Path $gp) {
        $c = Get-Content $gp -Raw -Encoding UTF8
        $c = $c.Replace('flutter.minSdkVersion', '23')
        Set-Content $gp $c -Encoding UTF8
    }
}

Set-Location $app
flutter pub get
Write-Host "`nXong! Mở thư mục nguyenquocduy_chamcong bằng Android Studio, chọn máy ảo Pixel 7 rồi Run." -ForegroundColor Green
