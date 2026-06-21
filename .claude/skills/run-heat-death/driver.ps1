<#
  Heat Death — run/validate/screenshot driver (Windows / PowerShell 5.1)

  This is the agent-facing harness for the Heat Death Godot 4.7 game.
  It is NOT a Linux container: it drives the real game on the user's
  Windows desktop with the Steam Godot binary.

  Usage:
    powershell -ExecutionPolicy Bypass -File driver.ps1 validate [-Seconds 10]
    powershell -ExecutionPolicy Bypass -File driver.ps1 screenshot [-Out path.png] [-Seconds 6]
    powershell -ExecutionPolicy Bypass -File driver.ps1 launch          # windowed, blocks until you close it

  validate   -> headless run, scans output for GDScript/scene errors, exit 1 if any
  screenshot -> launches the game windowed, waits, grabs the Godot window to a PNG, kills it
  launch     -> plain windowed launch (human path), foreground
#>

[CmdletBinding()]
param(
  [Parameter(Position = 0)]
  [ValidateSet('validate', 'screenshot', 'play', 'pause', 'launch', 'help')]
  [string]$Command = 'help',

  [int]$Seconds = 0,
  [string]$Out = ''
)

$ErrorActionPreference = 'Stop'

# --- locate the project (driver lives at <proj>/.claude/skills/run-heat-death/) ---
$ProjectDir = (Resolve-Path (Join-Path $PSScriptRoot '..\..\..')).Path

# --- locate the Godot 4.7 Steam binary ---
function Find-Godot {
  $known = 'D:\app-games\steamapps\common\Godot Engine\godot.windows.opt.tools.64.exe'
  if (Test-Path $known) { return $known }
  $roots = @(
    'D:\app-games\steamapps\common',
    'C:\Program Files (x86)\Steam\steamapps\common',
    "$env:ProgramFiles\Godot",
    "${env:ProgramFiles(x86)}\Godot"
  )
  foreach ($r in $roots) {
    if (Test-Path $r) {
      $hit = Get-ChildItem $r -Recurse -Filter 'godot*.exe' -ErrorAction SilentlyContinue |
        Where-Object { $_.Name -match 'tools' } | Select-Object -First 1
      if ($hit) { return $hit.FullName }
    }
  }
  $cmd = Get-Command godot -ErrorAction SilentlyContinue
  if ($cmd) { return $cmd.Source }
  throw "Godot binary not found. Edit Find-Godot in driver.ps1 with your path."
}

$Godot = Find-Godot

function Invoke-Validate {
  if ($Seconds -le 0) { $Seconds = 10 }
  $frames = [int]($Seconds * 60)
  Write-Host "[validate] $Godot --headless --quit-after $frames"
  $errFile = Join-Path $env:TEMP "heatdeath_stderr_$PID.txt"
  $outFile = Join-Path $env:TEMP "heatdeath_stdout_$PID.txt"
  # Godot prints script/runtime errors to stderr; --quit-after counts frames.
  $p = Start-Process -FilePath $Godot `
    -ArgumentList @('--headless', '--path', $ProjectDir, '--quit-after', "$frames") `
    -NoNewWindow -PassThru -Wait `
    -RedirectStandardError $errFile -RedirectStandardOutput $outFile
  $log = @()
  if (Test-Path $outFile) { $log += Get-Content $outFile }
  if (Test-Path $errFile) { $log += Get-Content $errFile }
  Remove-Item $errFile, $outFile -ErrorAction SilentlyContinue
  $errors = $log | Where-Object {
    $_ -match 'SCRIPT ERROR' -or $_ -match 'Parse Error' -or
    $_ -match 'Node not found' -or $_ -match 'Cannot call method' -or
    $_ -match 'Invalid call' -or $_ -match 'Failed to load' -or
    ($_ -match '^\s*E \d' )
  }
  if ($errors) {
    Write-Host "`n[validate] FAILED - errors detected:`n" -ForegroundColor Red
    $errors | ForEach-Object { Write-Host "  $_" -ForegroundColor Red }
    exit 1
  }
  Write-Host "[validate] OK - no script/scene errors in $Seconds s." -ForegroundColor Green
  exit 0
}

# Win32 helpers: read a window rect AND force it to the foreground.
# SetForegroundWindow alone is blocked for background processes, so we use the
# AttachThreadInput trick (attach to the current foreground thread first).
function Add-Win32 {
  if (-not ('Win32Rect' -as [type])) {
    Add-Type @"
using System;
using System.Runtime.InteropServices;
public struct RECT { public int Left, Top, Right, Bottom; }
public class Win32Rect {
  [DllImport("user32.dll")] public static extern bool GetWindowRect(IntPtr hWnd, out RECT r);
  [DllImport("user32.dll")] public static extern bool SetForegroundWindow(IntPtr hWnd);
  [DllImport("user32.dll")] public static extern bool BringWindowToTop(IntPtr hWnd);
  [DllImport("user32.dll")] public static extern bool ShowWindow(IntPtr hWnd, int n);
  [DllImport("user32.dll")] public static extern IntPtr GetForegroundWindow();
  [DllImport("user32.dll")] public static extern uint GetWindowThreadProcessId(IntPtr hWnd, IntPtr pid);
  [DllImport("user32.dll")] public static extern bool AttachThreadInput(uint a, uint b, bool attach);
  [DllImport("kernel32.dll")] public static extern uint GetCurrentThreadId();
  [DllImport("user32.dll")] public static extern bool SetCursorPos(int x, int y);
  [DllImport("user32.dll")] public static extern void mouse_event(uint f, uint dx, uint dy, uint d, IntPtr e);
  [DllImport("user32.dll")] public static extern void keybd_event(byte vk, byte scan, uint flags, IntPtr extra);
  [DllImport("user32.dll")] public static extern uint MapVirtualKey(uint code, uint mapType);
  public static void ClickAt(int x, int y) {
    SetCursorPos(x, y);
    System.Threading.Thread.Sleep(120);
    mouse_event(0x02, 0, 0, 0, IntPtr.Zero); // LEFTDOWN
    mouse_event(0x04, 0, 0, 0, IntPtr.Zero); // LEFTUP
  }
  public static void Key(byte vk) {
    // Godot mappa le azioni per physical_keycode (scan code): serve KEYEVENTF_SCANCODE.
    byte scan = (byte)MapVirtualKey(vk, 0);
    keybd_event(0, scan, 0x08, IntPtr.Zero);        // down (SCANCODE)
    System.Threading.Thread.Sleep(40);
    keybd_event(0, scan, 0x08 | 0x02, IntPtr.Zero); // up (SCANCODE | KEYUP)
  }
  public static void Force(IntPtr hWnd) {
    uint fg = GetWindowThreadProcessId(GetForegroundWindow(), IntPtr.Zero);
    uint me = GetCurrentThreadId();
    AttachThreadInput(fg, me, true);
    ShowWindow(hWnd, 9);        // SW_RESTORE
    BringWindowToTop(hWnd);
    SetForegroundWindow(hWnd);
    AttachThreadInput(fg, me, false);
  }
}
"@
  }
}

# launch windowed, wait for the window handle, force it on top
function Start-GameWindowed {
  Add-Win32
  $p = Start-Process -FilePath $Godot -ArgumentList @('--path', $ProjectDir) -PassThru
  $deadline = (Get-Date).AddSeconds(20)
  while ($p.MainWindowHandle -eq 0 -and (Get-Date) -lt $deadline) {
    Start-Sleep -Milliseconds 250; $p.Refresh()
  }
  if ($p.MainWindowHandle -eq 0) { $p.Kill(); throw "Godot window never appeared." }
  [Win32Rect]::Force($p.MainWindowHandle)
  return $p
}

# capture the process's window (whole window incl. title bar) to a PNG
function Save-WindowShot([System.Diagnostics.Process]$p, [string]$path) {
  Add-Type -AssemblyName System.Drawing
  [Win32Rect]::Force($p.MainWindowHandle)
  Start-Sleep -Milliseconds 600
  $r = New-Object RECT
  [Win32Rect]::GetWindowRect($p.MainWindowHandle, [ref]$r) | Out-Null
  $w = $r.Right - $r.Left; $h = $r.Bottom - $r.Top
  if ($w -le 0 -or $h -le 0) { throw "Bad window rect ${w}x${h}." }
  $bmp = New-Object System.Drawing.Bitmap $w, $h
  $g = [System.Drawing.Graphics]::FromImage($bmp)
  $g.CopyFromScreen($r.Left, $r.Top, 0, 0, $bmp.Size)
  $bmp.Save($path, [System.Drawing.Imaging.ImageFormat]::Png)
  $g.Dispose(); $bmp.Dispose()
  Write-Host "[shot] saved $path (${w}x${h}, $((Get-Item $path).Length) bytes)" -ForegroundColor Green
  return @{ Left = $r.Left; Top = $r.Top; W = $w; H = $h }
}

function Invoke-Screenshot {
  if ($Seconds -le 0) { $Seconds = 6 }
  if (-not $Out) { $Out = Join-Path $ProjectDir 'heat_death_screenshot.png' }
  Write-Host "[screenshot] launching windowed..."
  $p = Start-GameWindowed
  try {
    Start-Sleep -Seconds $Seconds
    Save-WindowShot $p $Out | Out-Null
  }
  finally { if (-not $p.HasExited) { $p.Kill(); $p.WaitForExit(3000) } }
}

# launch, click the Start button, screenshot live gameplay
function Invoke-Play {
  if ($Seconds -le 0) { $Seconds = 5 }   # seconds of gameplay before the shot
  if (-not $Out) { $Out = Join-Path $ProjectDir 'heat_death_gameplay.png' }
  Write-Host "[play] launching windowed..."
  $p = Start-GameWindowed
  try {
    Start-Sleep -Seconds 4                # let the menu settle
    # re-assert foreground right before clicking: Godot loses focus to the
    # parent shell during the wait, so a stale click would miss the button.
    [Win32Rect]::Force($p.MainWindowHandle)
    Start-Sleep -Milliseconds 500
    $r = New-Object RECT
    [Win32Rect]::GetWindowRect($p.MainWindowHandle, [ref]$r) | Out-Null
    $w = $r.Right - $r.Left; $h = $r.Bottom - $r.Top
    # Start button sits at ~50% width, ~48% height of the window (see menu shot)
    $cx = $r.Left + [int]($w * 0.50)
    $cy = $r.Top + [int]($h * 0.48)
    Write-Host "[play] clicking Start at screen ($cx,$cy)"
    [Win32Rect]::ClickAt($cx, $cy)
    Start-Sleep -Milliseconds 300
    [Win32Rect]::ClickAt($cx, $cy)        # 2nd click in case the 1st only activated
    Start-Sleep -Seconds $Seconds          # play out a few seconds
    Save-WindowShot $p $Out | Out-Null
  }
  finally { if (-not $p.HasExited) { $p.Kill(); $p.WaitForExit(3000) } }
}

# launch, click Start, then press P to open the pause menu and screenshot it
function Invoke-Pause {
  if (-not $Out) { $Out = Join-Path $ProjectDir 'heat_death_pause.png' }
  Write-Host "[pause] launching windowed..."
  $p = Start-GameWindowed
  try {
    Start-Sleep -Seconds 4
    [Win32Rect]::Force($p.MainWindowHandle)
    Start-Sleep -Milliseconds 500
    $r = New-Object RECT
    [Win32Rect]::GetWindowRect($p.MainWindowHandle, [ref]$r) | Out-Null
    $w = $r.Right - $r.Left; $h = $r.Bottom - $r.Top
    $cx = $r.Left + [int]($w * 0.50); $cy = $r.Top + [int]($h * 0.48)
    [Win32Rect]::ClickAt($cx, $cy)
    Start-Sleep -Milliseconds 300
    [Win32Rect]::ClickAt($cx, $cy)
    Start-Sleep -Seconds 3                  # gioca qualche secondo (accumula stat)
    [Win32Rect]::Force($p.MainWindowHandle)
    Start-Sleep -Milliseconds 400
    [Win32Rect]::Key(0x50)                  # P -> apre la pausa
    Start-Sleep -Seconds 1
    Save-WindowShot $p $Out | Out-Null
  }
  finally { if (-not $p.HasExited) { $p.Kill(); $p.WaitForExit(3000) } }
}

function Invoke-Launch {
  Write-Host "[launch] $Godot --path $ProjectDir  (close the window to return)"
  & $Godot --path $ProjectDir
}

switch ($Command) {
  'validate'   { Invoke-Validate }
  'screenshot' { Invoke-Screenshot }
  'play'       { Invoke-Play }
  'pause'      { Invoke-Pause }
  'launch'     { Invoke-Launch }
  default {
    Write-Host "Heat Death driver. Commands:"
    Write-Host "  validate [-Seconds 10]      headless error check, exit 1 on errors"
    Write-Host "  screenshot [-Out f.png] [-Seconds 6]   windowed launch + PNG of the menu"
    Write-Host "  play [-Out f.png] [-Seconds 5]         launch, click Start, PNG of gameplay"
    Write-Host "  pause [-Out f.png]                     launch, Start, press P, PNG of pause menu"
    Write-Host "  launch                      plain windowed launch (human path)"
  }
}
