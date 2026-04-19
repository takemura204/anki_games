# Windows: flutter_tools の -d を推定し、Android ならエミュレーターを前面へ（iOS は未対応）。
$ErrorActionPreference = 'SilentlyContinue'
$deviceId = $null
$procs = Get-CimInstance Win32_Process |
    Where-Object { $_.CommandLine -match 'flutter_tools.*\.snapshot.*\b(run|attach)\b' }
foreach ($p in $procs) {
    if ($p.CommandLine -match '(^|\s)-d=(\S+)') { $deviceId = $Matches[2]; break }
    if ($p.CommandLine -match '(^|\s)-d\s+(\S+)') { $deviceId = $Matches[2]; break }
    if ($p.CommandLine -match '--device-id=(\S+)') { $deviceId = $Matches[1]; break }
}

$kind = 'unknown'
if ($deviceId) {
    $d = $deviceId.ToLowerInvariant()
    if ($d -match '^(chrome|edge|windows|win32|linux|macos|wasm|dart-vm)$' -or $d.StartsWith('web-')) {
        exit 0
    }
    if ($deviceId.StartsWith('emulator-')) { $kind = 'android' }
    elseif (Get-Command adb -ErrorAction SilentlyContinue) {
        $st = & adb -s $deviceId get-state 2>$null
        if ($st -eq 'device' -or $st -eq 'authorizing') { $kind = 'android' }
    }
}
else {
    $adbN = 0
    if (Get-Command adb -ErrorAction SilentlyContinue) {
        $adbN = (& adb devices 2>$null | Select-String "`tdevice$").Count
    }
    if ($adbN -ge 1) { $kind = 'android' }
}

if ($kind -eq 'android') {
    $shell = New-Object -ComObject WScript.Shell
    [void]$shell.AppActivate('Android Emulator')
}
