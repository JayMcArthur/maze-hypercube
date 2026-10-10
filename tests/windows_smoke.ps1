param([Parameter(Mandatory=$true)][string]$Executable,[Parameter(Mandatory=$true)][string]$OutputDirectory)
$ErrorActionPreference = 'Stop'
Add-Type @'
using System;
using System.Runtime.InteropServices;
public static class MazeWindow {
    [DllImport("user32.dll")] public static extern bool PostMessageW(IntPtr h, uint message, IntPtr key, IntPtr data);
}
'@
New-Item -ItemType Directory -Force -Path $OutputDirectory | Out-Null
$state = Join-Path $OutputDirectory 'windows-smoke-state.json'
Remove-Item $state -ErrorAction SilentlyContinue
$env:HYPERCUBE_MAZE_STATE=$state
$app=Start-Process -FilePath $Executable -PassThru -RedirectStandardError (Join-Path $OutputDirectory 'windows-smoke.log')
try {
    for($i=0;$i -lt 50;$i++) {
        Start-Sleep -Milliseconds 100
        $app.Refresh()
        if($app.HasExited) {throw 'Windows app exited before opening its window'}
        if($app.MainWindowHandle -ne 0) {break}
    }
    if($app.MainWindowHandle -eq 0) {throw 'Windows app did not open a native window'}
    Start-Sleep -Seconds 3
    $saved=Get-Content $state -Raw | ConvertFrom-Json
    if($saved.spec.number -ne 1) {throw 'Windows app did not save its initial state'}
    $app.Refresh()
    Write-Output ("Windows title: " + $app.MainWindowTitle)
    # WSL cannot activate a Windows foreground window in this session. Send the
    # focus and scan-code messages directly to this isolated test window.
    [MazeWindow]::PostMessageW($app.MainWindowHandle,0x6,[IntPtr]1,[IntPtr]0) | Out-Null
    [MazeWindow]::PostMessageW($app.MainWindowHandle,0x7,[IntPtr]0,[IntPtr]0) | Out-Null
    Start-Sleep -Milliseconds 300
    [MazeWindow]::PostMessageW($app.MainWindowHandle,0x100,[IntPtr]0x20,[IntPtr]0x390001) | Out-Null
    Start-Sleep -Milliseconds 100
    [MazeWindow]::PostMessageW($app.MainWindowHandle,0x101,[IntPtr]0x20,[IntPtr]0xC0390001) | Out-Null
    Start-Sleep -Milliseconds 200
    [MazeWindow]::PostMessageW($app.MainWindowHandle,0x100,[IntPtr]0x44,[IntPtr]0x200001) | Out-Null
    Start-Sleep -Milliseconds 100
    [MazeWindow]::PostMessageW($app.MainWindowHandle,0x101,[IntPtr]0x44,[IntPtr]0xC0200001) | Out-Null
    Start-Sleep -Seconds 3
    $saved=Get-Content $state -Raw | ConvertFrom-Json
    if($saved.markers.Count -ne 1 -or $saved.markers[0] -ne 0) {throw 'Windows marker keyboard action failed'}
    if($saved.position[0] -ne 1) {throw 'Windows movement keyboard action failed'}
    $app.CloseMainWindow() | Out-Null
    if(-not $app.WaitForExit(5000)) {throw 'Windows app failed to close normally'}
    $app=Start-Process -FilePath $Executable -PassThru
    Start-Sleep -Seconds 3
    if($app.HasExited) {throw 'Windows app failed to reopen saved progress'}
    $saved=Get-Content $state -Raw | ConvertFrom-Json
    if($saved.position[0] -ne 1 -or $saved.markers[0] -ne 0) {throw 'Windows saved progress did not resume'}
    $app.CloseMainWindow() | Out-Null
    if(-not $app.WaitForExit(5000)) {throw 'Resumed Windows app failed to close normally'}
    $capture=Join-Path $OutputDirectory 'windows-framebuffer.png'
    Remove-Item $capture -ErrorAction SilentlyContinue
    $env:HYPERCUBE_MAZE_CAPTURE=$capture
    $app=Start-Process -FilePath $Executable -PassThru
    if(-not $app.WaitForExit(12000)) {throw 'Windows framebuffer capture timed out'}
    if(-not (Test-Path $capture)) {throw 'Windows renderer did not produce its framebuffer'}
    Add-Type -AssemblyName System.Drawing
    $image=[System.Drawing.Bitmap]::new($capture)
    try {
        $background=$image.GetPixel(3,3)
        if($image.Width -lt 500 -or $image.Height -lt 600 -or $background.R -ne 195 -or $background.G -ne 166 -or $background.B -ne 137) {
            throw 'Windows framebuffer dimensions or maze background are incorrect'
        }
    } finally {$image.Dispose()}
    Write-Output 'PASS: Windows native rendering, keyboard markers, movement, audio path, autosave, normal close, and resume'
}
finally {
    Remove-Item Env:HYPERCUBE_MAZE_CAPTURE -ErrorAction SilentlyContinue
    $app.Refresh()
    if(-not $app.HasExited) {$app.CloseMainWindow() | Out-Null; $app.WaitForExit(3000) | Out-Null}
    $app.Refresh()
    if(-not $app.HasExited) {$app.Kill()}
}
