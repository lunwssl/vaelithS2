<#
    ██╗   ██╗ █████╗ ███████╗██╗     ██╗████████╗██╗  ██╗
    ██║   ██║██╔══██╗██╔════╝██║     ██║╚══██╔══╝██║  ██║
    ██║   ██║███████║█████╗  ██║     ██║   ██║   ███████║
    ╚██╗ ██╔╝██╔══██║██╔══╝  ██║     ██║   ██║   ██╔══██║
     ╚████╔╝ ██║  ██║███████╗███████╗██║   ██║   ██║  ██║
      ╚═══╝  ╚═╝  ╚═╝╚══════╝╚══════╝╚═╝   ╚═╝   ╚═╝  ╚═╝
    Forensic Scanner — V3  [SCAN ONLY — NO CHANGES MADE]
    Run from an ELEVATED (Admin) PowerShell session.

    MODULES:
      [1]  File System (Temp, Prefetch, Recent, Crash)
      [2]  ShimCache / AppCompatCache
      [3]  BAM — Background Activity Monitor
      [4]  Registry Execution Artifacts
      [5]  UserAssist (ROT13)
      [6]  Prefetch Files
      [7]  Archive Files (.zip / .rar / .7z / .tar)
      [8]  Windows Defender / Antivirus History
      [9]  Windows Event Viewer Logs
      [10] Browser History (Edge / Chrome / Firefox)
      [11] Jump Lists
      [12] Thumbnail Cache DB names
      [13] Windows Search Index (WordWheelQuery)
      [14] Scheduled Tasks
      [15] Network Artifacts (DNS Cache, Firewall Logs)
      [16] Recycle Bin ($Recycle.Bin)
      [17] LNK / Shortcut Files (deep scan)
      [18] Volume Shadow Copies (VSS) paths
      [19] PowerShell History
      [20] WMI Subscriptions
#>

# ==========================================
# --- ELEVATION CHECK ---
# ==========================================
$id = [System.Security.Principal.WindowsIdentity]::GetCurrent()
$p  = New-Object System.Security.Principal.WindowsPrincipal($id)
if (-not $p.IsInRole([System.Security.Principal.WindowsBuiltInRole]::Administrator)) {
    Write-Warning "VAELITH V3 requires Administrator privileges."
    Write-Warning "Right-click and choose 'Run as Administrator'."
    Read-Host "Press Enter to exit..."; exit
}

# ==========================================
# --- COLORS ---
# ==========================================
$C_Found  = "Red"
$C_Clean  = "Green"
$C_Info   = "Cyan"
$C_Warn   = "Yellow"
$C_Dim    = "DarkGray"
$C_White  = "White"
$C_Magenta = "Magenta"

Clear-Host
Write-Host ""
Write-Host "  ██╗   ██╗ █████╗ ███████╗██╗     ██╗████████╗██╗  ██╗" -ForegroundColor $C_Info
Write-Host "  ██║   ██║██╔══██╗██╔════╝██║     ██║╚══██╔══╝██║  ██║" -ForegroundColor $C_Info
Write-Host "  ██║   ██║███████║█████╗  ██║     ██║   ██║   ███████║" -ForegroundColor $C_Info
Write-Host "  ╚██╗ ██╔╝██╔══██║██╔══╝  ██║     ██║   ██║   ██╔══██║" -ForegroundColor $C_Info
Write-Host "   ╚████╔╝ ██║  ██║███████╗███████╗██║   ██║   ██║  ██║" -ForegroundColor $C_Info
Write-Host "    ╚═══╝  ╚═╝  ╚═╝╚══════╝╚══════╝╚═╝   ╚═╝   ╚═╝  ╚═╝" -ForegroundColor $C_Info
Write-Host "  Forensic Scanner V3  —  READ ONLY. NOTHING IS DELETED." -ForegroundColor DarkCyan
Write-Host "  20 scan modules | Archives | Defender | Event Logs | Browser" -ForegroundColor $C_Dim
Write-Host ""

# ==========================================
# --- INPUT ---
# ==========================================
$userInput = Read-Host "  Enter the name/term to scan for (e.g., matcha)"

if ([string]::IsNullOrWhiteSpace($userInput)) {
    Write-Host "  No search term provided. Exiting..." -ForegroundColor $C_Found
    exit
}

$searchTerm = "*$userInput*"
$regexTerm  = [regex]::Escape($userInput)

# ==========================================
# --- TIMER START ---
# ==========================================
$scanStart = Get-Date
Write-Host ""
Write-Host "  Scan started at: $($scanStart.ToString('HH:mm:ss'))" -ForegroundColor $C_Dim

# Results collector
$results = [System.Collections.Generic.List[PSCustomObject]]::new()

function Add-Result {
    param($Category, $Location, $Detail)
    $results.Add([PSCustomObject]@{
        Category = $Category
        Location = $Location
        Detail   = $Detail
        Time     = (Get-Date).ToString("HH:mm:ss")
    })
    Write-Host "    [FOUND] [$Category] $Location" -ForegroundColor $C_Found
    if ($Detail) {
        Write-Host "            $Detail" -ForegroundColor $C_Warn
    }
}

Write-Host ""
Write-Host "  ==========================================" -ForegroundColor $C_Info
Write-Host "   SCANNING FOR: $($userInput.ToUpper())" -ForegroundColor $C_White
Write-Host "  ==========================================" -ForegroundColor $C_Info

# ==========================================
# --- COLLECT USER SIDs ---
# ==========================================
$userSIDs = Get-ChildItem "Registry::HKEY_USERS" -ErrorAction SilentlyContinue |
    Where-Object { $_.PSChildName -match "^S-1-5-21-\d+-\d+-\d+-\d+$" } |
    Select-Object -ExpandProperty PSChildName

# ==========================================
# --- [1] FILE SYSTEM ---
# ==========================================
Write-Host "`n  [1/20] File System Scan" -ForegroundColor $C_White
Write-Host "  ──────────────────────────────────────────" -ForegroundColor $C_Dim

$knownPaths = @(
    "C:\$userInput",
    (Join-Path $env:APPDATA         $userInput),
    (Join-Path $env:LOCALAPPDATA    $userInput),
    (Join-Path $env:APPDATA         "Microsoft\Windows\Recent\$userInput.lnk"),
    (Join-Path $env:APPDATA         "Microsoft\Windows\Recent\$userInput (2).lnk"),
    (Join-Path $env:APPDATA         "Microsoft\Windows\Recent\$userInput.sln.lnk"),
    (Join-Path $env:LOCALAPPDATA    "Microsoft\VisualStudio\BackupFiles\$userInput")
)

$scanRoots = @(
    "$env:APPDATA\Microsoft\Windows\Recent",
    "$env:LOCALAPPDATA\Microsoft\VisualStudio\BackupFiles",
    "$env:LOCALAPPDATA\CrashDumps",
    "$env:WINDIR\Prefetch",
    "$env:TEMP",
    "$env:LOCALAPPDATA\Temp",
    "$env:USERPROFILE\Desktop",
    "$env:USERPROFILE\Documents",
    "$env:USERPROFILE\Downloads"
)

$scannedPaths = @()

foreach ($path in $knownPaths) {
    if (Test-Path $path) {
        Add-Result "FILE" $path $null
        $scannedPaths += $path
    }
}

foreach ($root in $scanRoots) {
    if (Test-Path $root) {
        Get-ChildItem -Path $root -Force -ErrorAction SilentlyContinue |
            Where-Object { $_.Name -match $regexTerm } |
            ForEach-Object {
                if ($_.FullName -notin $scannedPaths) {
                    Add-Result "FILE" $_.FullName "Size: $([math]::Round($_.Length/1KB,1)) KB | Modified: $($_.LastWriteTime)"
                    $scannedPaths += $_.FullName
                }
            }
    }
}

if ($scannedPaths.Count -eq 0) {
    Write-Host "    [CLEAN] No file traces found." -ForegroundColor $C_Clean
}

# ==========================================
# --- [2] SHIMCACHE / APPCOMPATCACHE ---
# ==========================================
Write-Host "`n  [2/20] ShimCache / AppCompatCache" -ForegroundColor $C_White
Write-Host "  ──────────────────────────────────────────" -ForegroundColor $C_Dim
Write-Host "    (Execution history — survives reboots)" -ForegroundColor $C_Dim

$shimPath = "HKLM:\SYSTEM\CurrentControlSet\Control\Session Manager\AppCompatCache"

if (Test-Path $shimPath) {
    try {
        $shimRaw  = (Get-ItemProperty -Path $shimPath -Name "AppCompatCache" -ErrorAction Stop).AppCompatCache
        $shimStr  = [System.Text.Encoding]::Unicode.GetString($shimRaw)
        if ($shimStr -match $regexTerm) {
            Add-Result "SHIMCACHE" $shimPath "Binary data contains '$userInput' path(s). Requires full cache flush to clear."
        } else {
            Write-Host "    [CLEAN] '$userInput' not found in ShimCache." -ForegroundColor $C_Clean
        }
    } catch {
        Write-Host "    [ERROR] Cannot read ShimCache: $($_.Exception.Message)" -ForegroundColor Red
    }
} else {
    Write-Host "    [SKIP] ShimCache path not found." -ForegroundColor $C_Dim
}

# ==========================================
# --- [3] BAM (Background Activity Monitor) ---
# ==========================================
Write-Host "`n  [3/20] BAM — Background Activity Monitor" -ForegroundColor $C_White
Write-Host "  ──────────────────────────────────────────" -ForegroundColor $C_Dim
Write-Host "    (Tracks every executed binary with timestamp)" -ForegroundColor $C_Dim

$bamRoots = @(
    "HKLM:\SYSTEM\ControlSet001\Services\bam\State\UserSettings",
    "HKLM:\SYSTEM\CurrentControlSet\Services\bam\State\UserSettings"
)

$bamFound = $false
foreach ($bamRoot in $bamRoots) {
    foreach ($sid in $userSIDs) {
        $bamPath = "$bamRoot\$sid"
        if (Test-Path $bamPath) {
            $props = Get-ItemProperty -Path $bamPath -ErrorAction SilentlyContinue
            if ($null -ne $props) {
                foreach ($prop in $props.PSObject.Properties) {
                    if ($prop.Name -notmatch "^PS" -and ($prop.Name -like $searchTerm)) {
                        Add-Result "BAM" $bamPath "Value: $($prop.Name)"
                        $bamFound = $true
                    }
                }
            }
        }
    }
}

if (-not $bamFound) {
    Write-Host "    [CLEAN] No BAM entries found for '$userInput'." -ForegroundColor $C_Clean
}

# ==========================================
# --- [4] REGISTRY — EXECUTION ARTIFACTS ---
# ==========================================
Write-Host "`n  [4/20] Registry — Execution Artifacts" -ForegroundColor $C_White
Write-Host "  ──────────────────────────────────────────" -ForegroundColor $C_Dim

$regPaths = @(
    @{ Path = "HKCU:\Software\Classes\Local Settings\Software\Microsoft\Windows\Shell\MuiCache";                     Label = "MuiCache (HKCU)" },
    @{ Path = "HKCR:\Local Settings\Software\Microsoft\Windows\Shell\MuiCache";                                       Label = "MuiCache (HKCR)" },
    @{ Path = "HKCU:\Software\Microsoft\Windows NT\CurrentVersion\AppCompatFlags\Compatibility Assistant\Store";      Label = "AppCompatFlags\Store" },
    @{ Path = "HKCU:\Software\Microsoft\Windows NT\CurrentVersion\AppCompatFlags\Layers";                             Label = "AppCompatFlags\Layers" },
    @{ Path = "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\FeatureUsage\AppSwitched";                    Label = "FeatureUsage\AppSwitched" },
    @{ Path = "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\FeatureUsage\ShowJumpView";                   Label = "FeatureUsage\ShowJumpView" },
    @{ Path = "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\FeatureUsage\AppBadgeUpdated";                Label = "FeatureUsage\AppBadgeUpdated" },
    @{ Path = "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\RunMRU";                                      Label = "RunMRU (Win+R)" },
    @{ Path = "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\RecentDocs";                                  Label = "RecentDocs" },
    @{ Path = "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\ComDlg32\LastVisitedPidlMRU";                Label = "ComDlg32\LastVisitedPidlMRU" },
    @{ Path = "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\ComDlg32\OpenSavePidlMRU";                   Label = "ComDlg32\OpenSavePidlMRU" },
    @{ Path = "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\TypedPaths";                                  Label = "TypedPaths (Explorer bar)" },
    @{ Path = "HKLM:\SOFTWARE\Microsoft\Windows Defender\Exclusions\Paths";                                           Label = "Defender\Exclusions\Paths" },
    @{ Path = "HKLM:\SOFTWARE\Microsoft\Windows Defender\Exclusions\Processes";                                       Label = "Defender\Exclusions\Processes" },
    @{ Path = "HKLM:\SOFTWARE\Microsoft\RADAR\HeapLeakDetection\DiagnosedApplications";                              Label = "RADAR\DiagnosedApplications" },
    @{ Path = "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall";                                            Label = "Uninstall (x64)" },
    @{ Path = "HKLM:\SOFTWARE\WOW6432Node\Microsoft\Windows\CurrentVersion\Uninstall";                               Label = "Uninstall (x86)" },
    @{ Path = "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Map Network Drive MRU";                       Label = "Map Network Drive MRU" },
    @{ Path = "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\ComDlg32\CIDSizeMRU";                        Label = "ComDlg32\CIDSizeMRU" },
    @{ Path = "HKCU:\Software\Microsoft\Internet Explorer\TypedURLs";                                                 Label = "IE TypedURLs" },
    @{ Path = "HKCU:\Software\Microsoft\Windows\CurrentVersion\Search\RecentApps";                                    Label = "Search RecentApps" }
)

foreach ($sid in $userSIDs) {
    $regPaths += @{ Path = "Registry::HKEY_USERS\$sid\Software\Classes\Local Settings\Software\Microsoft\Windows\Shell\MuiCache"; Label = "MuiCache [$sid]" }
    $regPaths += @{ Path = "Registry::HKEY_USERS\$sid\Software\Microsoft\Windows NT\CurrentVersion\AppCompatFlags\Compatibility Assistant\Store"; Label = "AppCompatFlags\Store [$sid]" }
    $regPaths += @{ Path = "Registry::HKEY_USERS\$sid\Software\Microsoft\Windows\CurrentVersion\Explorer\RecentDocs"; Label = "RecentDocs [$sid]" }
    $regPaths += @{ Path = "Registry::HKEY_USERS\${sid}_Classes\Local Settings\Software\Microsoft\Windows\Shell\MuiCache"; Label = "MuiCache _Classes [$sid]" }
}

$regFound = $false

foreach ($entry in $regPaths) {
    $psPath = $entry.Path
    $label  = $entry.Label

    if (Test-Path -Path $psPath -ErrorAction SilentlyContinue) {

        $subkeys = Get-ChildItem -Path $psPath -ErrorAction SilentlyContinue
        foreach ($key in $subkeys) {
            if ($key.PSChildName -like $searchTerm) {
                Add-Result "REGISTRY" "$label \ [SUBKEY] $($key.PSChildName)" $null
                $regFound = $true
            }

            if ($label -match "UserAssist|FileExts|ComDlg32|RecentDocs|LastVisited|OpenSave") {
                $subProps = Get-ItemProperty -Path $key.PSPath -ErrorAction SilentlyContinue
                if ($null -ne $subProps) {
                    foreach ($prop in $subProps.PSObject.Properties) {
                        if ($prop.Name -notmatch "^PS" -and (
                            $prop.Name -like $searchTerm -or [string]$prop.Value -like $searchTerm
                        )) {
                            Add-Result "REGISTRY" "$label \ $($key.PSChildName) \ $($prop.Name)" "Value: $($prop.Value)"
                            $regFound = $true
                        }
                    }
                }
            }
        }

        $props = Get-ItemProperty -Path $psPath -ErrorAction SilentlyContinue
        if ($null -ne $props) {
            foreach ($prop in $props.PSObject.Properties) {
                if ($prop.Name -notmatch "^PS" -and (
                    $prop.Name -like $searchTerm -or [string]$prop.Value -like $searchTerm
                )) {
                    Add-Result "REGISTRY" "$label \ $($prop.Name)" "Value: $($prop.Value)"
                    $regFound = $true
                }
            }
        }
    }
}

if (-not $regFound) {
    Write-Host "    [CLEAN] No registry execution artifacts found." -ForegroundColor $C_Clean
}

# ==========================================
# --- [5] USERASSIST (ROT13 encoded) ---
# ==========================================
Write-Host "`n  [5/20] UserAssist (Encoded Execution Counter)" -ForegroundColor $C_White
Write-Host "  ──────────────────────────────────────────" -ForegroundColor $C_Dim
Write-Host "    (Tracks GUI app launches — entries are ROT13 encoded)" -ForegroundColor $C_Dim

function Decode-ROT13 {
    param([string]$s)
    -join ($s.ToCharArray() | ForEach-Object {
        $c = [int]$_
        if    ($c -ge 65 -and $c -le 90)  { [char](( ($c - 65 + 13) % 26 ) + 65) }
        elseif($c -ge 97 -and $c -le 122) { [char](( ($c - 97 + 13) % 26 ) + 97) }
        else                               { $_ }
    })
}

$uaRoots = @("HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\UserAssist")
foreach ($sid in $userSIDs) {
    $uaRoots += "Registry::HKEY_USERS\$sid\Software\Microsoft\Windows\CurrentVersion\Explorer\UserAssist"
}

$uaFound = $false
foreach ($uaRoot in $uaRoots) {
    if (Test-Path $uaRoot -ErrorAction SilentlyContinue) {
        Get-ChildItem -Path $uaRoot -ErrorAction SilentlyContinue | ForEach-Object {
            $guidPath  = $_.PSPath
            $countPath = Join-Path $guidPath "Count"
            if (Test-Path $countPath -ErrorAction SilentlyContinue) {
                $countProps = Get-ItemProperty -Path $countPath -ErrorAction SilentlyContinue
                if ($null -ne $countProps) {
                    foreach ($prop in $countProps.PSObject.Properties) {
                        if ($prop.Name -notmatch "^PS") {
                            $decoded = Decode-ROT13 $prop.Name
                            if ($decoded -match $regexTerm) {
                                Add-Result "USERASSIST" $countPath "Decoded: $decoded"
                                $uaFound = $true
                            }
                        }
                    }
                }
            }
        }
    }
}

if (-not $uaFound) {
    Write-Host "    [CLEAN] No UserAssist entries found for '$userInput'." -ForegroundColor $C_Clean
}

# ==========================================
# --- [6] PREFETCH ---
# ==========================================
Write-Host "`n  [6/20] Prefetch Files" -ForegroundColor $C_White
Write-Host "  ──────────────────────────────────────────" -ForegroundColor $C_Dim
Write-Host "    (Windows caches the first 8 seconds of execution)" -ForegroundColor $C_Dim

$prefetchPath = "$env:WINDIR\Prefetch"
$pfFound = $false

if (Test-Path $prefetchPath) {
    Get-ChildItem -Path $prefetchPath -Filter "*.pf" -ErrorAction SilentlyContinue |
        Where-Object { $_.Name -match $regexTerm } |
        ForEach-Object {
            Add-Result "PREFETCH" $_.FullName "Last Modified: $($_.LastWriteTime)"
            $pfFound = $true
        }
}

if (-not $pfFound) {
    Write-Host "    [CLEAN] No Prefetch files found for '$userInput'." -ForegroundColor $C_Clean
}

# ==========================================
# --- [7] ARCHIVE FILES (.zip .rar .7z .tar .gz) ---
# ==========================================
Write-Host "`n  [7/20] Archive Files (.zip / .rar / .7z / .tar / .gz)" -ForegroundColor $C_White
Write-Host "  ──────────────────────────────────────────" -ForegroundColor $C_Dim
Write-Host "    (Scanning common user locations for archives matching the term)" -ForegroundColor $C_Dim

$archiveExtensions = @("*.zip","*.rar","*.7z","*.tar","*.gz","*.tar.gz","*.bz2","*.xz","*.cab","*.iso")
$archiveRoots = @(
    "$env:USERPROFILE\Downloads",
    "$env:USERPROFILE\Desktop",
    "$env:USERPROFILE\Documents",
    "$env:TEMP",
    "$env:LOCALAPPDATA\Temp",
    "C:\Temp"
)

$archFound = $false
foreach ($root in $archiveRoots) {
    if (Test-Path $root) {
        foreach ($ext in $archiveExtensions) {
            Get-ChildItem -Path $root -Filter $ext -Recurse -Depth 3 -Force -ErrorAction SilentlyContinue |
                Where-Object { $_.Name -match $regexTerm } |
                ForEach-Object {
                    Add-Result "ARCHIVE" $_.FullName "Type: $($_.Extension.ToUpper()) | Size: $([math]::Round($_.Length/1MB,2)) MB | Modified: $($_.LastWriteTime)"
                    $archFound = $true
                }
        }
    }
}

# Also check if any archive *contains* the term (only for ZIP — others require external tools)
Write-Host "    Checking ZIP contents for embedded references..." -ForegroundColor $C_Dim
foreach ($root in $archiveRoots) {
    if (Test-Path $root) {
        Get-ChildItem -Path $root -Filter "*.zip" -Recurse -Depth 2 -Force -ErrorAction SilentlyContinue |
            ForEach-Object {
                try {
                    Add-Type -AssemblyName System.IO.Compression.FileSystem -ErrorAction SilentlyContinue
                    $zip = [System.IO.Compression.ZipFile]::OpenRead($_.FullName)
                    $match = $zip.Entries | Where-Object { $_.FullName -match $regexTerm }
                    if ($match) {
                        $match | ForEach-Object {
                            Add-Result "ARCHIVE-CONTENT" $_.FullName "Entry inside ZIP: $($_.FullName)"
                            $archFound = $true
                        }
                    }
                    $zip.Dispose()
                } catch { }
            }
    }
}

if (-not $archFound) {
    Write-Host "    [CLEAN] No archive files found referencing '$userInput'." -ForegroundColor $C_Clean
}

# ==========================================
# --- [8] WINDOWS DEFENDER / ANTIVIRUS ---
# ==========================================
Write-Host "`n  [8/20] Windows Defender / Antivirus History" -ForegroundColor $C_White
Write-Host "  ──────────────────────────────────────────" -ForegroundColor $C_Dim
Write-Host "    (Detection history, quarantine, exclusions)" -ForegroundColor $C_Dim

$defFound = $false

# Defender Detection History folder
$defHistoryPath = "$env:ProgramData\Microsoft\Windows Defender\Scans\History\Service\DetectionHistory"
if (Test-Path $defHistoryPath) {
    Get-ChildItem -Path $defHistoryPath -Recurse -Force -ErrorAction SilentlyContinue |
        ForEach-Object {
            try {
                $content = Get-Content $_.FullName -Raw -ErrorAction SilentlyContinue
                if ($content -and $content -match $regexTerm) {
                    Add-Result "DEFENDER-HISTORY" $_.FullName "Detection history file references '$userInput'"
                    $defFound = $true
                }
            } catch { }
        }
}

# Quarantine folder (binary, but file names may match)
$quarantinePath = "$env:ProgramData\Microsoft\Windows Defender\Quarantine"
if (Test-Path $quarantinePath) {
    Get-ChildItem -Path $quarantinePath -Recurse -Force -ErrorAction SilentlyContinue |
        Where-Object { $_.Name -match $regexTerm } |
        ForEach-Object {
            Add-Result "DEFENDER-QUARANTINE" $_.FullName "Quarantined file name matches '$userInput'"
            $defFound = $true
        }
}

# Defender Exclusions (registry)
$defExclusions = @(
    "HKLM:\SOFTWARE\Microsoft\Windows Defender\Exclusions\Paths",
    "HKLM:\SOFTWARE\Microsoft\Windows Defender\Exclusions\Processes",
    "HKLM:\SOFTWARE\Microsoft\Windows Defender\Exclusions\Extensions",
    "HKLM:\SOFTWARE\Microsoft\Windows Defender\Exclusions\TemporaryPaths"
)
foreach ($excl in $defExclusions) {
    if (Test-Path $excl -ErrorAction SilentlyContinue) {
        $props = Get-ItemProperty -Path $excl -ErrorAction SilentlyContinue
        if ($null -ne $props) {
            foreach ($prop in $props.PSObject.Properties) {
                if ($prop.Name -notmatch "^PS" -and (
                    $prop.Name -like $searchTerm -or [string]$prop.Value -like $searchTerm
                )) {
                    Add-Result "DEFENDER-EXCLUSION" $excl "Exclusion: $($prop.Name) = $($prop.Value)"
                    $defFound = $true
                }
            }
        }
    }
}

# Attempt to read MpCmdRun log
$mpLog = "$env:ProgramData\Microsoft\Windows Defender\Support\MpCmdRun.log"
if (Test-Path $mpLog) {
    try {
        $mpContent = Get-Content $mpLog -ErrorAction SilentlyContinue | Select-String -Pattern $regexTerm
        if ($mpContent) {
            $mpContent | ForEach-Object {
                Add-Result "DEFENDER-LOG" $mpLog "MpCmdRun.log line: $($_.Line.Trim())"
                $defFound = $true
            }
        }
    } catch { }
}

if (-not $defFound) {
    Write-Host "    [CLEAN] No Defender/AV artifacts found for '$userInput'." -ForegroundColor $C_Clean
}

# ==========================================
# --- [9] WINDOWS EVENT VIEWER LOGS ---
# ==========================================
Write-Host "`n  [9/20] Windows Event Viewer Logs" -ForegroundColor $C_White
Write-Host "  ──────────────────────────────────────────" -ForegroundColor $C_Dim
Write-Host "    (Application, Security, System, PowerShell logs)" -ForegroundColor $C_Dim
Write-Host "    NOTE: Large logs may take a moment to scan..." -ForegroundColor $C_Dim

$evFound = $false

$eventLogs = @(
    @{ LogName = "Application";                          MaxEvents = 2000 },
    @{ LogName = "System";                               MaxEvents = 2000 },
    @{ LogName = "Security";                             MaxEvents = 500  },
    @{ LogName = "Microsoft-Windows-PowerShell/Operational"; MaxEvents = 1000 },
    @{ LogName = "Microsoft-Windows-AppLocker/EXE and DLL";  MaxEvents = 500  },
    @{ LogName = "Microsoft-Windows-AppLocker/MSI and Script";MaxEvents = 500  },
    @{ LogName = "Microsoft-Windows-TerminalServices-LocalSessionManager/Operational"; MaxEvents = 200 },
    @{ LogName = "Microsoft-Windows-Bits-Client/Operational"; MaxEvents = 500  },
    @{ LogName = "Microsoft-Windows-TaskScheduler/Operational"; MaxEvents = 500 }
)

foreach ($logEntry in $eventLogs) {
    $logName  = $logEntry.LogName
    $maxEvts  = $logEntry.MaxEvents
    Write-Host "    Scanning: $logName ..." -ForegroundColor $C_Dim
    try {
        $events = Get-WinEvent -LogName $logName -MaxEvents $maxEvts -ErrorAction SilentlyContinue |
            Where-Object { $_.Message -match $regexTerm }

        if ($events) {
            foreach ($evt in $events) {
                $snippet = ($evt.Message -split "`n" | Where-Object { $_ -match $regexTerm } | Select-Object -First 1).Trim()
                Add-Result "EVENT-LOG" "$logName (EventID: $($evt.Id))" "Time: $($evt.TimeCreated) | $snippet"
                $evFound = $true
            }
        }
    } catch {
        Write-Host "    [SKIP] Cannot read '$logName': $($_.Exception.Message)" -ForegroundColor $C_Dim
    }
}

if (-not $evFound) {
    Write-Host "    [CLEAN] No Event Log entries found for '$userInput'." -ForegroundColor $C_Clean
}

# ==========================================
# --- [10] BROWSER HISTORY ---
# ==========================================
Write-Host "`n  [10/20] Browser History (Edge / Chrome / Firefox)" -ForegroundColor $C_White
Write-Host "  ──────────────────────────────────────────" -ForegroundColor $C_Dim
Write-Host "    (SQLite history DBs — scanned as binary text)" -ForegroundColor $C_Dim

$brFound = $false

# Chromium-based: Edge and Chrome store history in SQLite
$chromiumProfiles = @(
    "$env:LOCALAPPDATA\Microsoft\Edge\User Data",
    "$env:LOCALAPPDATA\Google\Chrome\User Data",
    "$env:LOCALAPPDATA\BraveSoftware\Brave-Browser\User Data",
    "$env:LOCALAPPDATA\Vivaldi\User Data",
    "$env:LOCALAPPDATA\Opera Software\Opera Stable"
)

foreach ($browserBase in $chromiumProfiles) {
    if (Test-Path $browserBase) {
        $histFiles = Get-ChildItem -Path $browserBase -Filter "History" -Recurse -Depth 3 -Force -ErrorAction SilentlyContinue
        foreach ($hf in $histFiles) {
            try {
                # Read as bytes converted to string (binary sqlite contains readable URLs)
                $bytes  = [System.IO.File]::ReadAllBytes($hf.FullName)
                $asText = [System.Text.Encoding]::UTF8.GetString($bytes)
                if ($asText -match $regexTerm) {
                    $browserName = Split-Path (Split-Path $hf.DirectoryName) -Leaf
                    Add-Result "BROWSER-HISTORY" $hf.FullName "Browser: $browserName — History DB contains '$userInput'"
                    $brFound = $true
                }
            } catch { }
        }

        # Also check Favicons, Top Sites
        foreach ($dbName in @("Top Sites","Favicons","Visited Links","Shortcuts")) {
            $dbFiles = Get-ChildItem -Path $browserBase -Filter $dbName -Recurse -Depth 3 -Force -ErrorAction SilentlyContinue
            foreach ($dbf in $dbFiles) {
                try {
                    $bytes  = [System.IO.File]::ReadAllBytes($dbf.FullName)
                    $asText = [System.Text.Encoding]::UTF8.GetString($bytes)
                    if ($asText -match $regexTerm) {
                        Add-Result "BROWSER-HISTORY" $dbf.FullName "Browser DB '$dbName' references '$userInput'"
                        $brFound = $true
                    }
                } catch { }
            }
        }
    }
}

# Firefox
$ffBase = "$env:APPDATA\Mozilla\Firefox\Profiles"
if (Test-Path $ffBase) {
    $ffHistory = Get-ChildItem -Path $ffBase -Filter "places.sqlite" -Recurse -Depth 3 -Force -ErrorAction SilentlyContinue
    foreach ($ffh in $ffHistory) {
        try {
            $bytes  = [System.IO.File]::ReadAllBytes($ffh.FullName)
            $asText = [System.Text.Encoding]::UTF8.GetString($bytes)
            if ($asText -match $regexTerm) {
                Add-Result "BROWSER-HISTORY" $ffh.FullName "Firefox history (places.sqlite) contains '$userInput'"
                $brFound = $true
            }
        } catch { }
    }

    # Firefox formhistory
    $ffForms = Get-ChildItem -Path $ffBase -Filter "formhistory.sqlite" -Recurse -Depth 3 -Force -ErrorAction SilentlyContinue
    foreach ($fff in $ffForms) {
        try {
            $bytes  = [System.IO.File]::ReadAllBytes($fff.FullName)
            $asText = [System.Text.Encoding]::UTF8.GetString($bytes)
            if ($asText -match $regexTerm) {
                Add-Result "BROWSER-HISTORY" $fff.FullName "Firefox form history contains '$userInput'"
                $brFound = $true
            }
        } catch { }
    }
}

if (-not $brFound) {
    Write-Host "    [CLEAN] No browser history references found for '$userInput'." -ForegroundColor $C_Clean
}

# ==========================================
# --- [11] JUMP LISTS ---
# ==========================================
Write-Host "`n  [11/20] Jump Lists" -ForegroundColor $C_White
Write-Host "  ──────────────────────────────────────────" -ForegroundColor $C_Dim
Write-Host "    (Taskbar pinned/recent items per app)" -ForegroundColor $C_Dim

$jlFound = $false
$jumpListRoots = @(
    "$env:APPDATA\Microsoft\Windows\Recent\AutomaticDestinations",
    "$env:APPDATA\Microsoft\Windows\Recent\CustomDestinations"
)

foreach ($jlRoot in $jumpListRoots) {
    if (Test-Path $jlRoot) {
        Get-ChildItem -Path $jlRoot -Force -ErrorAction SilentlyContinue |
            ForEach-Object {
                try {
                    $bytes  = [System.IO.File]::ReadAllBytes($_.FullName)
                    $asText = [System.Text.Encoding]::Unicode.GetString($bytes)
                    if ($asText -match $regexTerm) {
                        Add-Result "JUMPLIST" $_.FullName "Jump list binary references '$userInput' | Modified: $($_.LastWriteTime)"
                        $jlFound = $true
                    }
                } catch { }
            }
    }
}

if (-not $jlFound) {
    Write-Host "    [CLEAN] No Jump List references found." -ForegroundColor $C_Clean
}

# ==========================================
# --- [12] THUMBNAIL CACHE ---
# ==========================================
Write-Host "`n  [12/20] Thumbnail Cache (thumbs.db / thumbcache_*.db)" -ForegroundColor $C_White
Write-Host "  ──────────────────────────────────────────" -ForegroundColor $C_Dim
Write-Host "    (File Explorer caches thumbnails — db may contain filenames)" -ForegroundColor $C_Dim

$tcFound = $false
$thumbCachePath = "$env:LOCALAPPDATA\Microsoft\Windows\Explorer"

if (Test-Path $thumbCachePath) {
    Get-ChildItem -Path $thumbCachePath -Filter "thumbcache_*.db" -ErrorAction SilentlyContinue |
        ForEach-Object {
            try {
                $bytes  = [System.IO.File]::ReadAllBytes($_.FullName)
                $asText = [System.Text.Encoding]::Unicode.GetString($bytes)
                if ($asText -match $regexTerm) {
                    Add-Result "THUMBCACHE" $_.FullName "Thumbnail DB references '$userInput' | Size: $([math]::Round($_.Length/1KB,1)) KB"
                    $tcFound = $true
                }
            } catch { }
        }
}

if (-not $tcFound) {
    Write-Host "    [CLEAN] No thumbnail cache references found." -ForegroundColor $C_Clean
}

# ==========================================
# --- [13] WINDOWS SEARCH INDEX ---
# ==========================================
Write-Host "`n  [13/20] Windows Search Index (WordWheelQuery / SearchHistory)" -ForegroundColor $C_White
Write-Host "  ──────────────────────────────────────────" -ForegroundColor $C_Dim
Write-Host "    (Start Menu / Explorer search bar history)" -ForegroundColor $C_Dim

$wsFound = $false

# WordWheelQuery = Start Menu search history
$wwqPath = "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\WordWheelQuery"
if (Test-Path $wwqPath -ErrorAction SilentlyContinue) {
    $wwqProps = Get-ItemProperty -Path $wwqPath -ErrorAction SilentlyContinue
    if ($null -ne $wwqProps) {
        foreach ($prop in $wwqProps.PSObject.Properties) {
            if ($prop.Name -notmatch "^PS") {
                $valStr = ""
                try {
                    if ($prop.Value -is [byte[]]) {
                        $valStr = [System.Text.Encoding]::Unicode.GetString($prop.Value).TrimEnd([char]0)
                    } else {
                        $valStr = [string]$prop.Value
                    }
                } catch { }
                if ($valStr -match $regexTerm) {
                    Add-Result "SEARCH-HISTORY" $wwqPath "WordWheelQuery entry: '$valStr'"
                    $wsFound = $true
                }
            }
        }
    }
}

foreach ($sid in $userSIDs) {
    $sidWWQ = "Registry::HKEY_USERS\$sid\Software\Microsoft\Windows\CurrentVersion\Explorer\WordWheelQuery"
    if (Test-Path $sidWWQ -ErrorAction SilentlyContinue) {
        $wwqProps = Get-ItemProperty -Path $sidWWQ -ErrorAction SilentlyContinue
        if ($null -ne $wwqProps) {
            foreach ($prop in $wwqProps.PSObject.Properties) {
                if ($prop.Name -notmatch "^PS") {
                    $valStr = ""
                    try {
                        if ($prop.Value -is [byte[]]) {
                            $valStr = [System.Text.Encoding]::Unicode.GetString($prop.Value).TrimEnd([char]0)
                        } else {
                            $valStr = [string]$prop.Value
                        }
                    } catch { }
                    if ($valStr -match $regexTerm) {
                        Add-Result "SEARCH-HISTORY" $sidWWQ "WordWheelQuery [$sid]: '$valStr'"
                        $wsFound = $true
                    }
                }
            }
        }
    }
}

# Windows Search DB (Windows.edb)
$searchDB = "$env:ProgramData\Microsoft\Search\Data\Applications\Windows\Windows.edb"
if (Test-Path $searchDB) {
    Write-Host "    [INFO] Windows Search DB found at $searchDB" -ForegroundColor $C_Dim
    Write-Host "    [NOTE] Full ESE/JET DB scanning requires specialized tools (e.g. NirSoft SearchMyFiles)." -ForegroundColor $C_Dim
    Add-Result "SEARCH-DB" $searchDB "Windows.edb exists — binary scan skipped. Use NirSoft SearchMyFiles for deep inspection."
    $wsFound = $true
}

if (-not $wsFound) {
    Write-Host "    [CLEAN] No Windows Search history found for '$userInput'." -ForegroundColor $C_Clean
}

# ==========================================
# --- [14] SCHEDULED TASKS ---
# ==========================================
Write-Host "`n  [14/20] Scheduled Tasks" -ForegroundColor $C_White
Write-Host "  ──────────────────────────────────────────" -ForegroundColor $C_Dim
Write-Host "    (Task Scheduler — persistent execution triggers)" -ForegroundColor $C_Dim

$stFound = $false

try {
    $tasks = Get-ScheduledTask -ErrorAction SilentlyContinue |
        Where-Object {
            $_.TaskName  -match $regexTerm -or
            $_.TaskPath  -match $regexTerm -or
            ($_.Actions | ForEach-Object { $_.Execute, $_.Arguments } | Where-Object { $_ -match $regexTerm })
        }

    foreach ($task in $tasks) {
        $actionStr = ($task.Actions | ForEach-Object { "$($_.Execute) $($_.Arguments)" }) -join " | "
        Add-Result "SCHED-TASK" "\$($task.TaskPath)$($task.TaskName)" "Actions: $actionStr | State: $($task.State)"
        $stFound = $true
    }
} catch {
    Write-Host "    [ERROR] Cannot enumerate scheduled tasks: $($_.Exception.Message)" -ForegroundColor Red
}

# Also scan XML files in Tasks folder
$taskXmlRoot = "$env:WINDIR\System32\Tasks"
if (Test-Path $taskXmlRoot) {
    Get-ChildItem -Path $taskXmlRoot -Recurse -Filter "*.xml" -ErrorAction SilentlyContinue |
        ForEach-Object {
            try {
                $xml = Get-Content $_.FullName -Raw -ErrorAction SilentlyContinue
                if ($xml -match $regexTerm) {
                    Add-Result "SCHED-TASK-XML" $_.FullName "Task XML references '$userInput'"
                    $stFound = $true
                }
            } catch { }
        }
    Get-ChildItem -Path $taskXmlRoot -Recurse -File -ErrorAction SilentlyContinue |
        Where-Object { $_.Extension -eq "" } |
        ForEach-Object {
            try {
                $xml = Get-Content $_.FullName -Raw -ErrorAction SilentlyContinue
                if ($xml -match $regexTerm) {
                    Add-Result "SCHED-TASK-XML" $_.FullName "Task file references '$userInput'"
                    $stFound = $true
                }
            } catch { }
        }
}

if (-not $stFound) {
    Write-Host "    [CLEAN] No scheduled tasks found referencing '$userInput'." -ForegroundColor $C_Clean
}

# ==========================================
# --- [15] NETWORK ARTIFACTS ---
# ==========================================
Write-Host "`n  [15/20] Network Artifacts (DNS Cache / Firewall / Hosts)" -ForegroundColor $C_White
Write-Host "  ──────────────────────────────────────────" -ForegroundColor $C_Dim

$netFound = $false

# DNS Cache
try {
    $dnsCache = Get-DnsClientCache -ErrorAction SilentlyContinue |
        Where-Object { $_.Entry -match $regexTerm -or $_.RecordName -match $regexTerm }
    foreach ($dns in $dnsCache) {
        Add-Result "DNS-CACHE" "DNS Cache" "Entry: $($dns.Entry) | Record: $($dns.RecordName) | TTL: $($dns.TimeToLive)"
        $netFound = $true
    }
} catch {
    Write-Host "    [SKIP] Cannot read DNS cache." -ForegroundColor $C_Dim
}

# Hosts file
$hostsFile = "$env:WINDIR\System32\drivers\etc\hosts"
if (Test-Path $hostsFile) {
    $hostsContent = Get-Content $hostsFile -ErrorAction SilentlyContinue | Select-String -Pattern $regexTerm
    if ($hostsContent) {
        $hostsContent | ForEach-Object {
            Add-Result "HOSTS-FILE" $hostsFile "Line: $($_.Line.Trim())"
            $netFound = $true
        }
    }
}

# Windows Firewall Logs
$fwLogPath = "$env:WINDIR\System32\LogFiles\Firewall\pfirewall.log"
if (Test-Path $fwLogPath) {
    try {
        $fwMatches = Get-Content $fwLogPath -ErrorAction SilentlyContinue | Select-String -Pattern $regexTerm
        if ($fwMatches) {
            $fwMatches | Select-Object -First 5 | ForEach-Object {
                Add-Result "FIREWALL-LOG" $fwLogPath "Line: $($_.Line.Trim())"
                $netFound = $true
            }
        }
    } catch { }
}

# Network connections history (registry)
$netHistPaths = @(
    "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\NetworkList\Profiles",
    "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\NetworkList\Signatures\Unmanaged",
    "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\NetworkList\Signatures\Managed"
)
foreach ($nhp in $netHistPaths) {
    if (Test-Path $nhp -ErrorAction SilentlyContinue) {
        Get-ChildItem -Path $nhp -ErrorAction SilentlyContinue | ForEach-Object {
            $props = Get-ItemProperty -Path $_.PSPath -ErrorAction SilentlyContinue
            if ($null -ne $props) {
                foreach ($prop in $props.PSObject.Properties) {
                    if ($prop.Name -notmatch "^PS" -and [string]$prop.Value -match $regexTerm) {
                        Add-Result "NETWORK-HISTORY" $_.PSPath "$($prop.Name): $($prop.Value)"
                        $netFound = $true
                    }
                }
            }
        }
    }
}

if (-not $netFound) {
    Write-Host "    [CLEAN] No network artifacts found for '$userInput'." -ForegroundColor $C_Clean
}

# ==========================================
# --- [16] RECYCLE BIN ---
# ==========================================
Write-Host "`n  [16/20] Recycle Bin (`$Recycle.Bin)" -ForegroundColor $C_White
Write-Host "  ──────────────────────────────────────────" -ForegroundColor $C_Dim
Write-Host "    (Deleted files still on disk)" -ForegroundColor $C_Dim

$rbFound = $false
$drives = Get-PSDrive -PSProvider FileSystem -ErrorAction SilentlyContinue | Select-Object -ExpandProperty Root

foreach ($drive in $drives) {
    $rbPath = Join-Path $drive '$Recycle.Bin'
    if (Test-Path $rbPath -ErrorAction SilentlyContinue) {
        Get-ChildItem -Path $rbPath -Recurse -Force -ErrorAction SilentlyContinue |
            Where-Object { $_.Name -match $regexTerm } |
            ForEach-Object {
                Add-Result "RECYCLE-BIN" $_.FullName "Size: $([math]::Round($_.Length/1KB,1)) KB | Deleted ~: $($_.LastWriteTime)"
                $rbFound = $true
            }

        # Read $I metadata files (contain original path)
        Get-ChildItem -Path $rbPath -Recurse -Force -ErrorAction SilentlyContinue |
            Where-Object { $_.Name -match '^\$I' } |
            ForEach-Object {
                try {
                    $bytes  = [System.IO.File]::ReadAllBytes($_.FullName)
                    $asText = [System.Text.Encoding]::Unicode.GetString($bytes)
                    if ($asText -match $regexTerm) {
                        Add-Result "RECYCLE-BIN-META" $_.FullName "Recycle metadata references '$userInput' (original path)"
                        $rbFound = $true
                    }
                } catch { }
            }
    }
}

if (-not $rbFound) {
    Write-Host "    [CLEAN] No Recycle Bin items found for '$userInput'." -ForegroundColor $C_Clean
}

# ==========================================
# --- [17] LNK / SHORTCUT DEEP SCAN ---
# ==========================================
Write-Host "`n  [17/20] LNK / Shortcut Files (Deep Scan)" -ForegroundColor $C_White
Write-Host "  ──────────────────────────────────────────" -ForegroundColor $C_Dim
Write-Host "    (Shortcuts store target paths even after deletion)" -ForegroundColor $C_Dim

$lnkFound = $false
$lnkRoots = @(
    "$env:APPDATA\Microsoft\Windows\Recent",
    "$env:USERPROFILE\Desktop",
    "$env:PROGRAMDATA\Microsoft\Windows\Start Menu",
    "$env:APPDATA\Microsoft\Windows\Start Menu",
    "$env:USERPROFILE\AppData\Roaming\Microsoft\Internet Explorer\Quick Launch"
)

$wshell = New-Object -ComObject WScript.Shell -ErrorAction SilentlyContinue

foreach ($lnkRoot in $lnkRoots) {
    if (Test-Path $lnkRoot) {
        Get-ChildItem -Path $lnkRoot -Filter "*.lnk" -Recurse -Force -ErrorAction SilentlyContinue |
            ForEach-Object {
                $lnkPath = $_.FullName

                # Name match
                if ($_.BaseName -match $regexTerm) {
                    Add-Result "LNK-NAME" $lnkPath "Shortcut name matches '$userInput'"
                    $lnkFound = $true
                }

                # Target path match via COM
                try {
                    if ($null -ne $wshell) {
                        $sc = $wshell.CreateShortcut($lnkPath)
                        if ($sc.TargetPath -match $regexTerm -or $sc.Arguments -match $regexTerm -or $sc.WorkingDirectory -match $regexTerm) {
                            Add-Result "LNK-TARGET" $lnkPath "Target: $($sc.TargetPath) | Args: $($sc.Arguments)"
                            $lnkFound = $true
                        }
                    }
                } catch { }

                # Binary scan fallback
                try {
                    $bytes  = [System.IO.File]::ReadAllBytes($lnkPath)
                    $asText = [System.Text.Encoding]::Unicode.GetString($bytes)
                    if ($asText -match $regexTerm) {
                        if (-not $lnkFound) {
                            Add-Result "LNK-BINARY" $lnkPath "Binary content of shortcut references '$userInput'"
                            $lnkFound = $true
                        }
                    }
                } catch { }
            }
    }
}

if (-not $lnkFound) {
    Write-Host "    [CLEAN] No LNK shortcut references found." -ForegroundColor $C_Clean
}

# ==========================================
# --- [18] VOLUME SHADOW COPIES (VSS) ---
# ==========================================
Write-Host "`n  [18/20] Volume Shadow Copies (VSS / Restore Points)" -ForegroundColor $C_White
Write-Host "  ──────────────────────────────────────────" -ForegroundColor $C_Dim
Write-Host "    (Previous versions of files — can persist after deletion)" -ForegroundColor $C_Dim

$vssFound = $false

try {
    $shadows = Get-WmiObject Win32_ShadowCopy -ErrorAction SilentlyContinue
    if ($shadows) {
        Write-Host "    [INFO] Found $($shadows.Count) shadow copy/copies on this system." -ForegroundColor $C_Dim
        foreach ($shadow in $shadows) {
            Write-Host "    Shadow: $($shadow.ID) | Created: $($shadow.InstallDate) | Volume: $($shadow.VolumeName)" -ForegroundColor $C_Dim

            # Mount the shadow and check for the file
            $shadowLink = "C:\vaelith_vss_mount_$(Get-Random)"
            try {
                $shadowDev = $shadow.DeviceObject
                cmd /c "mklink /d `"$shadowLink`" `"$shadowDev\`"" 2>$null | Out-Null
                if (Test-Path $shadowLink) {
                    Get-ChildItem -Path $shadowLink -Recurse -Depth 4 -Force -ErrorAction SilentlyContinue |
                        Where-Object { $_.Name -match $regexTerm } |
                        ForEach-Object {
                            Add-Result "VSS" $_.FullName "Found in shadow copy $($shadow.ID) | Created: $($shadow.InstallDate)"
                            $vssFound = $true
                        }
                    cmd /c "rmdir `"$shadowLink`"" 2>$null | Out-Null
                }
            } catch { }
        }
    } else {
        Write-Host "    [INFO] No Volume Shadow Copies found on this system." -ForegroundColor $C_Dim
    }
} catch {
    Write-Host "    [SKIP] Cannot enumerate VSS: $($_.Exception.Message)" -ForegroundColor $C_Dim
}

if (-not $vssFound) {
    Write-Host "    [CLEAN] No VSS references found for '$userInput'." -ForegroundColor $C_Clean
}

# ==========================================
# --- [19] POWERSHELL HISTORY ---
# ==========================================
Write-Host "`n  [19/20] PowerShell Command History" -ForegroundColor $C_White
Write-Host "  ──────────────────────────────────────────" -ForegroundColor $C_Dim
Write-Host "    (PSReadLine history file — persistent across sessions)" -ForegroundColor $C_Dim

$psFound = $false

# PSReadLine history (the main one)
$psHistoryPaths = @(
    "$env:APPDATA\Microsoft\Windows\PowerShell\PSReadLine\ConsoleHost_history.txt",
    "$env:APPDATA\Microsoft\Windows\PowerShell\PSReadLine\Visual Studio Code Host_history.txt"
)

foreach ($psHist in $psHistoryPaths) {
    if (Test-Path $psHist) {
        $matches = Get-Content $psHist -ErrorAction SilentlyContinue | Select-String -Pattern $regexTerm
        if ($matches) {
            $matches | ForEach-Object {
                Add-Result "PS-HISTORY" $psHist "Command: $($_.Line.Trim())"
                $psFound = $true
            }
        }
    }
}

# PowerShell transcript logs
$transcriptRoots = @(
    "$env:USERPROFILE\Documents",
    "$env:WINDIR\System32\config\systemprofile\Documents",
    "C:\Transcripts"
)
foreach ($tRoot in $transcriptRoots) {
    if (Test-Path $tRoot) {
        Get-ChildItem -Path $tRoot -Filter "PowerShell_transcript*.txt" -Recurse -Depth 3 -Force -ErrorAction SilentlyContinue |
            ForEach-Object {
                try {
                    $m = Get-Content $_.FullName -ErrorAction SilentlyContinue | Select-String -Pattern $regexTerm
                    if ($m) {
                        $m | Select-Object -First 3 | ForEach-Object {
                            Add-Result "PS-TRANSCRIPT" $_.Path "Line: $($_.Line.Trim())"
                            $psFound = $true
                        }
                    }
                } catch { }
            }
    }
}

if (-not $psFound) {
    Write-Host "    [CLEAN] No PowerShell history references found." -ForegroundColor $C_Clean
}

# ==========================================
# --- [20] WMI SUBSCRIPTIONS ---
# ==========================================
Write-Host "`n  [20/20] WMI Event Subscriptions (Persistence Check)" -ForegroundColor $C_White
Write-Host "  ──────────────────────────────────────────" -ForegroundColor $C_Dim
Write-Host "    (Malware often uses WMI for persistence — checking all subscriptions)" -ForegroundColor $C_Dim

$wmiFound = $false

try {
    $wmiFilters = Get-WmiObject -Namespace "root\subscription" -Class "__EventFilter" -ErrorAction SilentlyContinue
    $wmiConsumers = Get-WmiObject -Namespace "root\subscription" -Class "__EventConsumer" -ErrorAction SilentlyContinue
    $wmiBinders = Get-WmiObject -Namespace "root\subscription" -Class "__FilterToConsumerBinding" -ErrorAction SilentlyContinue

    foreach ($filter in $wmiFilters) {
        if ($filter.Name -match $regexTerm -or $filter.Query -match $regexTerm) {
            Add-Result "WMI-FILTER" "root\subscription\__EventFilter" "Name: $($filter.Name) | Query: $($filter.Query)"
            $wmiFound = $true
        }
    }
    foreach ($consumer in $wmiConsumers) {
        $consumerStr = "$($consumer.Name) $($consumer.CommandLineTemplate) $($consumer.ScriptText)"
        if ($consumerStr -match $regexTerm) {
            Add-Result "WMI-CONSUMER" "root\subscription\__EventConsumer" "Name: $($consumer.Name) | Cmd: $($consumer.CommandLineTemplate)"
            $wmiFound = $true
        }
    }

    # Report ALL WMI subscriptions regardless (good forensic practice)
    $totalWmi = ($wmiFilters.Count + $wmiConsumers.Count + $wmiBinders.Count)
    if ($totalWmi -gt 0) {
        Write-Host "    [INFO] Total WMI subscriptions on system: $totalWmi (Filters: $($wmiFilters.Count) | Consumers: $($wmiConsumers.Count) | Bindings: $($wmiBinders.Count))" -ForegroundColor $C_Warn
    }
} catch {
    Write-Host "    [SKIP] Cannot enumerate WMI subscriptions: $($_.Exception.Message)" -ForegroundColor $C_Dim
}

if (-not $wmiFound) {
    Write-Host "    [CLEAN] No WMI subscription references found for '$userInput'." -ForegroundColor $C_Clean
}

# ==========================================
# --- TIMER END ---
# ==========================================
$scanEnd      = Get-Date
$scanDuration = ($scanEnd - $scanStart).TotalSeconds

# ==========================================
# --- FINAL REPORT ---
# ==========================================
Write-Host ""
Write-Host "  ==========================================" -ForegroundColor $C_Info
Write-Host "   VAELITH V3  —  SCAN REPORT" -ForegroundColor $C_White
Write-Host "   Target   : $($userInput.ToUpper())" -ForegroundColor $C_White
Write-Host "   Modules  : 20" -ForegroundColor $C_White
Write-Host "   Duration : $([math]::Round($scanDuration,1)) seconds" -ForegroundColor $C_White
Write-Host "   Total    : $($results.Count) trace(s) found" -ForegroundColor $(if ($results.Count -gt 0) { $C_Found } else { $C_Clean })
Write-Host "  ==========================================" -ForegroundColor $C_Info

if ($results.Count -gt 0) {
    Write-Host ""
    Write-Host "  CATEGORY BREAKDOWN:" -ForegroundColor $C_White

    $grouped = $results | Group-Object Category | Sort-Object Count -Descending
    foreach ($g in $grouped) {
        Write-Host "    $($g.Name.PadRight(20)) : $($g.Count) hit(s)" -ForegroundColor $C_Warn
    }

    # Export report to Desktop
    Write-Host ""
    $reportPath = "$env:USERPROFILE\Desktop\VAELITH_V3_Report_$($userInput)_$(Get-Date -Format 'yyyyMMdd_HHmmss').txt"
    try {
        $header = @"
VAELITH V3 — Forensic Scan Report
Target  : $($userInput.ToUpper())
Date    : $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')
System  : $env:COMPUTERNAME ($env:USERNAME)
Modules : 20
Traces  : $($results.Count)
Duration: $([math]::Round($scanDuration,1)) seconds
============================================================

"@
        $body = $results | Format-Table -AutoSize | Out-String
        $full = $header + $body
        $full | Out-File -FilePath $reportPath -Encoding UTF8
        Write-Host "  [REPORT] Saved to: $reportPath" -ForegroundColor $C_Info
    } catch {
        Write-Host "  [WARN] Could not save report: $($_.Exception.Message)" -ForegroundColor $C_Warn
    }

    Write-Host ""
    Write-Host "  NOTE: This script made NO changes to your system." -ForegroundColor $C_Clean
    Write-Host "  Run VAELITH (v1/v2) to perform the actual cleanup." -ForegroundColor $C_Clean
} else {
    Write-Host ""
    Write-Host "  [CLEAN] System appears clean of '$userInput'." -ForegroundColor $C_Clean
}
<#
    ██╗   ██╗ █████╗ ███████╗██╗     ██╗████████╗██╗  ██╗
    ██║   ██║██╔══██╗██╔════╝██║     ██║╚══██╔══╝██║  ██║
    ██║   ██║███████║█████╗  ██║     ██║   ██║   ███████║
    ╚██╗ ██╔╝██╔══██║██╔══╝  ██║     ██║   ██║   ██╔══██║
     ╚████╔╝ ██║  ██║███████╗███████╗██║   ██║   ██║  ██║
      ╚═══╝  ╚═╝  ╚═╝╚══════╝╚══════╝╚═╝   ╚═╝   ╚═╝  ╚═╝

    VAELITH V3 EXTENDED MODULES (VERSÃO COMPLETA PROG)
    MODULES 21 → 35
#>

# ==========================================
# --- [21/35] USB DEVICE HISTORY ---
# ==========================================
Write-Host "`n  [21/35] USB Device History" -ForegroundColor $C_White
Write-Host "  ──────────────────────────────────────────" -ForegroundColor $C_Dim
Write-Host "    (USB devices, mount points, serial traces)" -ForegroundColor $C_Dim

$usbFound = $false
$usbPaths = @(
    "HKLM:\SYSTEM\CurrentControlSet\Enum\USBSTOR",
    "HKLM:\SYSTEM\MountedDevices",
    "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\MountPoints2"
)

foreach ($up in $usbPaths) {
    if (Test-Path $up) {
        Get-ChildItem -Path $up -Recurse -ErrorAction SilentlyContinue |
            Where-Object { $_.Name -match $regexTerm } |
            ForEach-Object {
                Add-Result "USB-HISTORY" $_.Name "USB artifact located"
                $usbFound = $true
            }
    }
}
if (-not $usbFound) { Write-Host "    [CLEAN] No USB history references found." -ForegroundColor $C_Clean }

# ==========================================
# --- [22/35] AMCACHE.HVE ---
# ==========================================
Write-Host "`n  [22/35] Amcache.hve Execution Database" -ForegroundColor $C_White
Write-Host "  ──────────────────────────────────────────" -ForegroundColor $C_Dim
Write-Host "    (Executed programs, hashes, deleted paths)" -ForegroundColor $C_Dim

$amcacheFound = $false
$amcacheFile = "C:\Windows\AppCompat\Programs\Amcache.hve"

if (Test-Path $amcacheFile) {
    try {
        reg load HKLM\TempAmcache $amcacheFile | Out-Null
        Get-ChildItem "HKLM:\TempAmcache\Root\File" -Recurse -ErrorAction SilentlyContinue |
            Where-Object { $_.Name -match $regexTerm } |
            ForEach-Object {
                Add-Result "AMCACHE" $_.PSPath "Execution artifact"
                $amcacheFound = $true
            }
        reg unload HKLM\TempAmcache | Out-Null
    } catch {}
}
if (-not $amcacheFound) { Write-Host "    [CLEAN] No Amcache references found." -ForegroundColor $C_Clean }

# ==========================================
# --- [23/35] SRUM DATABASE ---
# ==========================================
Write-Host "`n  [23/35] SRUM Database" -ForegroundColor $C_White
Write-Host "  ──────────────────────────────────────────" -ForegroundColor $C_Dim
Write-Host "    (Resource usage and execution telemetry)" -ForegroundColor $C_Dim

$srumFound = $false
$srumDB = "C:\Windows\System32\sru\SRUDB.dat"

if (Test-Path $srumDB) {
    try {
        $bytes = [System.IO.File]::ReadAllBytes($srumDB)
        $text  = [System.Text.Encoding]::Unicode.GetString($bytes)
        if ($text -match $regexTerm) {
            Add-Result "SRUM" $srumDB "SRUM references '$userInput'"
            $srumFound = $true
        }
    } catch {}
}
if (-not $srumFound) { Write-Host "    [CLEAN] No SRUM references found." -ForegroundColor $C_Clean }

# ==========================================
# --- [24/35] REMOTE DESKTOP HISTORY ---
# ==========================================
Write-Host "`n  [24/35] Remote Desktop History" -ForegroundColor $C_White
Write-Host "  ──────────────────────────────────────────" -ForegroundColor $C_Dim
Write-Host "    (RDP servers, usernames, sessions)" -ForegroundColor $C_Dim

$rdpFound = $false
$rdpPaths = @(
    "HKCU:\Software\Microsoft\Terminal Server Client\Default",
    "HKCU:\Software\Microsoft\Terminal Server Client\Servers"
)
foreach ($path in $rdpPaths) {
    if (Test-Path $path) {
        Get-ItemProperty -Path $path -ErrorAction SilentlyContinue | Where-Object { $_.PSObject.Properties.Value -match $regexTerm } | ForEach-Object {
            Add-Result "RDP" $path "RDP history artifact match"
            $rdpFound = $true
        }
    }
}
if (-not $rdpFound) { Write-Host "    [CLEAN] No Remote Desktop references found." -ForegroundColor $C_Clean }

# ==========================================
# --- [25/35] OPEN HANDLES / LOCKED FILES ---
# ==========================================
Write-Host "`n  [25/35] Open Handles / Locked Files" -ForegroundColor $C_White
Write-Host "  ──────────────────────────────────────────" -ForegroundColor $C_Dim
Write-Host "    (Running processes and active locks)" -ForegroundColor $C_Dim

$handlesFound = $false
Get-Process -ErrorAction SilentlyContinue | Where-Object { $_.Name -match $regexTerm -or $_.Path -match $regexTerm } | ForEach-Object {
    Add-Result "HANDLES" $_.Path "Active active process tracking"
    $handlesFound = $true
}
if (-not $handlesFound) { Write-Host "    [CLEAN] No suspicious active handles found." -ForegroundColor $C_Clean }

# ==========================================
# --- [26/35] STARTUP PERSISTENCE ---
# ==========================================
Write-Host "`n  [26/35] Startup Persistence Locations" -ForegroundColor $C_White
Write-Host "  ──────────────────────────────────────────" -ForegroundColor $C_Dim
Write-Host "    (Run keys, RunOnce, startup folders)" -ForegroundColor $C_Dim

$startupFound = $false
$startupPaths = @(
    "HKLM:\Software\Microsoft\Windows\CurrentVersion\Run",
    "HKLM:\Software\Microsoft\Windows\CurrentVersion\RunOnce",
    "HKCU:\Software\Microsoft\Windows\CurrentVersion\Run",
    "HKCU:\Software\Microsoft\Windows\CurrentVersion\RunOnce"
)
foreach ($path in $startupPaths) {
    if (Test-Path $path) {
        Get-ItemProperty -Path $path -ErrorAction SilentlyContinue | Where-Object { $_.PSObject.Properties.Value -match $regexTerm } | ForEach-Object {
            Add-Result "STARTUP" $path "Persistence registry trace found"
            $startupFound = $true
        }
    }
}
if (-not $startupFound) { Write-Host "    [CLEAN] No active startup persistence found." -ForegroundColor $C_Clean }

# ==========================================
# --- [27/35] SERVICES & DRIVERS ---
# ==========================================
Write-Host "`n  [27/35] Services & Drivers" -ForegroundColor $C_White
Write-Host "  ──────────────────────────────────────────" -ForegroundColor $C_Dim
Write-Host "    (Services, drivers, persistence mechanisms)" -ForegroundColor $C_Dim

$srvFound = $false
Get-Service -ErrorAction SilentlyContinue | Where-Object { $_.Name -match $regexTerm -or $_.DisplayName -match $regexTerm } | ForEach-Object {
    Add-Result "SERVICES" $_.Name "Service string tracking match"
    $srvFound = $true
}
if (-not $srvFound) { Write-Host "    [CLEAN] No tracking service signatures found." -ForegroundColor $C_Clean }

# ==========================================
# --- [28/35] ADS STREAMS ---
# ==========================================
Write-Host "`n  [28/35] Alternate Data Streams" -ForegroundColor $C_White
Write-Host "  ──────────────────────────────────────────" -ForegroundColor $C_Dim
Write-Host "    (Hidden NTFS data streams)" -ForegroundColor $C_Dim

$adsFound = $false
$targetDirs = @([System.Environment]::GetFolderPath("UserProfile"), "C:\ProgramData")
foreach ($dir in $targetDirs) {
    if (Test-Path $dir) {
        Get-ChildItem -Path $dir -Recurse -File -ErrorAction SilentlyContinue | ForEach-Object {
            Get-Item $_.FullName -Stream * -ErrorAction SilentlyContinue | Where-Object { $_.Stream -ne ':$DATA' -and $_.Stream -match $regexTerm } | ForEach-Object {
                Add-Result "ADS" $_.FileName "Hidden ADS stream metadata matched"
                $adsFound = $true
            }
        }
    }
}
if (-not $adsFound) { Write-Host "    [CLEAN] No Alternate Data Streams found." -ForegroundColor $C_Clean }

# ==========================================
# --- [29/35] MEMORY DUMPS ---
# ==========================================
Write-Host "`n  [29/35] Memory Dump Artifacts" -ForegroundColor $C_White
Write-Host "  ──────────────────────────────────────────" -ForegroundColor $C_Dim
Write-Host "    (Crash dumps and forensic memory traces)" -ForegroundColor $C_Dim

$dumpFound = $false
$dumpPaths = @("C:\Windows\MEMORY.DMP", "C:\Windows\Minidump", "C:\ProgramData\CrashDumps")
foreach ($path in $dumpPaths) {
    if (Test-Path $path) {
        Get-ChildItem $path -Recurse -ErrorAction SilentlyContinue | Where-Object { $_.Name -match $regexTerm } | ForEach-Object {
            Add-Result "MEMORY-DUMP" $_.FullName "System Memory trace match"
            $dumpFound = $true
        }
    }
}
if (-not $dumpFound) { Write-Host "    [CLEAN] No system memory dump traces found." -ForegroundColor $C_Clean }

# ==========================================
# --- [30/35] CLOUD SYNC ARTIFACTS ---
# ==========================================
Write-Host "`n  [30/35] Cloud Sync Artifacts" -ForegroundColor $C_White
Write-Host "  ──────────────────────────────────────────" -ForegroundColor $C_Dim
Write-Host "    (OneDrive, Dropbox, Google Drive, MEGA)" -ForegroundColor $C_Dim

$cloudFound = $false
$cloudPaths = @(
    "$env:LocalAppData\Microsoft\OneDrive\settings",
    "$env:AppData\Dropbox",
    "$env:LocalAppData\Google\DriveFS"
)
foreach ($cp in $cloudPaths) {
    if (Test-Path $cp) {
        Get-ChildItem $cp -Recurse -ErrorAction SilentlyContinue | Where-Object { $_.Name -match $regexTerm } | ForEach-Object {
            Add-Result "CLOUD-SYNC" $_.FullName "Cloud application reference"
            $cloudFound = $true
        }
    }
}
if (-not $cloudFound) { Write-Host "    [CLEAN] No active cloud storage traces found." -ForegroundColor $C_Clean }

# ==========================================
# --- [31/35] SQLITE DATABASE SCAN ---
# ==========================================
Write-Host "`n  [31/35] SQLite Database Scan" -ForegroundColor $C_White
Write-Host "  ──────────────────────────────────────────" -ForegroundColor $C_Dim
Write-Host "    (Discord, browsers, Electron app databases)" -ForegroundColor $C_Dim

$sqliteFound = $false
$appDataPaths = @($env:AppData, $env:LocalAppData)
foreach ($ad in $appDataPaths) {
    if (Test-Path $ad) {
        Get-ChildItem $ad -Recurse -Filter "*.db" -ErrorAction SilentlyContinue | Where-Object { $_.Name -match $regexTerm } | ForEach-Object {
            Add-Result "SQLITE-DB" $_.FullName "Application Database file match"
            $sqliteFound = $true
        }
    }
}
if (-not $sqliteFound) { Write-Host "    [CLEAN] No tracking storage sqlite databases found." -ForegroundColor $C_Clean }

# ==========================================
# --- [32/35] WINDOWS TIMELINE ---
# ==========================================
Write-Host "`n  [32/35] Windows Timeline" -ForegroundColor $C_White
Write-Host "  ──────────────────────────────────────────" -ForegroundColor $C_Dim
Write-Host "    (Activity history and timeline cache)" -ForegroundColor $C_Dim

$timelineFound = $false
$timelinePath = "$env:LocalAppData\ConnectedDevicesPlatform"
if (Test-Path $timelinePath) {
    Get-ChildItem $timelinePath -Recurse -Filter "*.db" -ErrorAction SilentlyContinue | ForEach-Object {
        try {
            $b = [System.IO.File]::ReadAllBytes($_.FullName)
            $t = [System.Text.Encoding]::UTF8.GetString($b)
            if ($t -match $regexTerm) {
                Add-Result "TIMELINE" $_.FullName "Activity History cached index match"
                $timelineFound = $true
            }
        } catch {}
    }
}
if (-not $timelineFound) { Write-Host "    [CLEAN] No modern timeline activity data found." -ForegroundColor $C_Clean }

# ==========================================
# --- [33/35] DISCORD / TELEGRAM / STEAM ---
# ==========================================
Write-Host "`n  [33/35] Discord / Telegram / Steam Artifacts" -ForegroundColor $C_White
Write-Host "  ──────────────────────────────────────────" -ForegroundColor $C_Dim
Write-Host "    (Chat apps, logs, cache, downloads)" -ForegroundColor $C_Dim

$appsFound = $false
$chatPaths = @(
    "$env:AppData\Discord",
    "$env:AppData\Telegram Desktop",
    "C:\Program Files (x86)\Steam"
)
foreach ($ap in $chatPaths) {
    if (Test-Path $ap) {
        Get-ChildItem $ap -Recurse -ErrorAction SilentlyContinue | Where-Object { $_.Name -match $regexTerm } | ForEach-Object {
            Add-Result "CHAT-GAME-APPS" $_.FullName "Application operational data matched"
            $appsFound = $true
        }
    }
}
if (-not $appsFound) { Write-Host "    [CLEAN] No communication launcher data logs found." -ForegroundColor $C_Clean }

# ==========================================
# --- [34/35] ENVIRONMENT VARIABLES ---
# ==========================================
Write-Host "`n  [34/35] Environment Variables & PATH" -ForegroundColor $C_White
Write-Host "  ──────────────────────────────────────────" -ForegroundColor $C_Dim
Write-Host "    (PATH hijacking and suspicious variables)" -ForegroundColor $C_Dim

$envFound = $false
Get-ChildItem Env: | Where-Object { $_.Name -match $regexTerm -or $_.Value -match $regexTerm } | ForEach-Object {
    Add-Result "ENV-VARIABLES" $_.Name "Environment tracking entry matched"
    $envFound = $true
}
if (-not $envFound) { Write-Host "    [CLEAN] No rogue environment strings found." -ForegroundColor $C_Clean }

# ==========================================
# --- [35/35] WINDOWS NOTIFICATIONS ---
# ==========================================
Write-Host "`n  [35/35] Windows Notification Database" -ForegroundColor $C_White
Write-Host "  ──────────────────────────────────────────" -ForegroundColor $C_Dim
Write-Host "    (Notification database forensic traces)" -ForegroundColor $C_Dim

$notifFound = $false
$notifPath = "$env:LocalAppData\Microsoft\Windows\Notifications"
if (Test-Path $notifPath) {
    Get-ChildItem $notifPath -Recurse -Filter "*.db" -ErrorAction SilentlyContinue | ForEach-Object {
        try {
            $b = [System.IO.File]::ReadAllBytes($_.FullName)
            $t = [System.Text.Encoding]::UTF8.GetString($b)
            if ($t -match $regexTerm) {
                Add-Result "NOTIFICATIONS" $_.FullName "Notification database payload record"
                $notifFound = $true
            }
        } catch {}
    }
}
if (-not $notifFound) { Write-Host "    [CLEAN] No logged push notification strings found." -ForegroundColor $C_Clean }

Write-Host ""
Write-Host "  ==========================================" -ForegroundColor $C_Info
Write-Host "    EXTENDED MODULE PACK LOADED SUCCESSFULLY" -ForegroundColor $C_White
Write-Host "    Total Modules: 35" -ForegroundColor $C_White
Write-Host "  ==========================================" -ForegroundColor $C_Info
Write-Host ""
Read-Host "  Press Enter to exit..."
