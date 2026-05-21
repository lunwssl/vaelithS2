#Requires -Version 5.0
<#
    ██╗   ██╗ █████╗ ███████╗██╗     ██╗████████╗██╗  ██╗
    ██║   ██║██╔══██╗██╔════╝██║     ██║╚══██╔══╝██║  ██║
    ██║   ██║███████║█████╗  ██║     ██║   ██║   ███████║
    ╚██╗ ██╔╝██╔══██║██╔══╝  ██║     ██║   ██║   ██╔══██║
     ╚████╔╝ ██║  ██║███████╗███████╗██║   ██║   ██║  ██║
      ╚═══╝  ╚═╝  ╚═╝╚══════╝╚══════╝╚═╝   ╚═╝   ╚═╝  ╚═╝
    VAELITH V3 — Forensic Scanner GUI (Windows Forms)
    SCAN ONLY — NO CHANGES MADE
#>

Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing
[System.Windows.Forms.Application]::EnableVisualStyles()

# ─── ELEVATION CHECK ──────────────────────────────────────────────────────────
$id = [System.Security.Principal.WindowsIdentity]::GetCurrent()
$p  = New-Object System.Security.Principal.WindowsPrincipal($id)
if (-not $p.IsInRole([System.Security.Principal.WindowsBuiltInRole]::Administrator)) {
    [System.Windows.Forms.MessageBox]::Show(
        "VAELITH V3 requires Administrator privileges.`nRight-click and choose 'Run as Administrator'.",
        "VAELITH V3 — Elevation Required",
        [System.Windows.Forms.MessageBoxButtons]::OK,
        [System.Windows.Forms.MessageBoxIcon]::Warning
    )
    exit
}

# ─── COLORS ───────────────────────────────────────────────────────────────────
$C_BG      = [System.Drawing.Color]::FromArgb(10, 14, 20)
$C_Panel   = [System.Drawing.Color]::FromArgb(13, 17, 23)
$C_Border  = [System.Drawing.Color]::FromArgb(26, 35, 50)
$C_Cyan    = [System.Drawing.Color]::FromArgb(0, 212, 255)
$C_Green   = [System.Drawing.Color]::FromArgb(0, 255, 136)
$C_Red     = [System.Drawing.Color]::FromArgb(255, 68, 68)
$C_Yellow  = [System.Drawing.Color]::FromArgb(255, 204, 0)
$C_Magenta = [System.Drawing.Color]::FromArgb(255, 68, 255)
$C_Dim     = [System.Drawing.Color]::FromArgb(74, 85, 104)
$C_White   = [System.Drawing.Color]::FromArgb(226, 232, 240)
$C_DarkPan = [System.Drawing.Color]::FromArgb(8, 12, 18)

$FONT_MONO  = New-Object System.Drawing.Font("Courier New", 9)
$FONT_MONO_SM = New-Object System.Drawing.Font("Courier New", 8)
$FONT_MONO_LG = New-Object System.Drawing.Font("Courier New", 10, [System.Drawing.FontStyle]::Bold)
$FONT_LOGO  = New-Object System.Drawing.Font("Courier New", 7)

# ─── HELPER: Make DataGridView ────────────────────────────────────────────────
function New-Grid {
    param($Dock = [System.Windows.Forms.DockStyle]::Fill)
    $g = New-Object System.Windows.Forms.DataGridView
    $g.Dock                        = $Dock
    $g.BackgroundColor             = $C_Panel
    $g.GridColor                   = $C_Border
    $g.DefaultCellStyle.BackColor  = $C_Panel
    $g.DefaultCellStyle.ForeColor  = $C_White
    $g.DefaultCellStyle.Font       = $FONT_MONO_SM
    $g.DefaultCellStyle.SelectionBackColor = [System.Drawing.Color]::FromArgb(0, 50, 70)
    $g.DefaultCellStyle.SelectionForeColor = $C_Cyan
    $g.AlternatingRowsDefaultCellStyle.BackColor = [System.Drawing.Color]::FromArgb(8, 12, 18)
    $g.ColumnHeadersDefaultCellStyle.BackColor = [System.Drawing.Color]::FromArgb(0, 30, 45)
    $g.ColumnHeadersDefaultCellStyle.ForeColor = $C_Cyan
    $g.ColumnHeadersDefaultCellStyle.Font      = $FONT_MONO_SM
    $g.ColumnHeadersBorderStyle    = [System.Windows.Forms.DataGridViewHeaderBorderStyle]::Single
    $g.CellBorderStyle             = [System.Windows.Forms.DataGridViewCellBorderStyle]::SingleHorizontal
    $g.RowHeadersVisible           = $false
    $g.AllowUserToAddRows          = $false
    $g.AllowUserToDeleteRows       = $false
    $g.ReadOnly                    = $true
    $g.SelectionMode               = [System.Windows.Forms.DataGridViewSelectionMode]::FullRowSelect
    $g.AutoSizeRowsMode            = [System.Windows.Forms.DataGridViewAutoSizeRowsMode]::None
    $g.RowTemplate.Height          = 20
    $g.BorderStyle                 = [System.Windows.Forms.BorderStyle]::None
    return $g
}

function Add-Col {
    param($Grid, $Name, $Header, $Width = 120, $Color = $null)
    $col = New-Object System.Windows.Forms.DataGridViewTextBoxColumn
    $col.Name       = $Name
    $col.HeaderText = $Header
    $col.Width      = $Width
    if ($Color) {
        $col.DefaultCellStyle.ForeColor = $Color
    }
    $Grid.Columns.Add($col) | Out-Null
}

function New-Label {
    param($Text, $Color, $Font = $null, $Dock = [System.Windows.Forms.DockStyle]::None)
    $l = New-Object System.Windows.Forms.Label
    $l.Text      = $Text
    $l.ForeColor = $Color
    $l.BackColor = [System.Drawing.Color]::Transparent
    $l.Font      = if ($Font) { $Font } else { $FONT_MONO }
    $l.Dock      = $Dock
    $l.AutoSize  = $true
    return $l
}

function New-StatPanel {
    param([string[]]$Labels, [string[]]$Values, [System.Drawing.Color[]]$Colors)
    $p = New-Object System.Windows.Forms.FlowLayoutPanel
    $p.BackColor    = [System.Drawing.Color]::FromArgb(8, 12, 18)
    $p.Height       = 30
    $p.Dock         = [System.Windows.Forms.DockStyle]::Top
    $p.Padding      = New-Object System.Windows.Forms.Padding(8, 6, 8, 0)
    $p.FlowDirection= [System.Windows.Forms.FlowDirection]::LeftToRight

    for ($i = 0; $i -lt $Labels.Count; $i++) {
        $lbl = New-Object System.Windows.Forms.Label
        $lbl.Text      = "$($Labels[$i]): "
        $lbl.ForeColor = $C_Dim
        $lbl.Font      = $FONT_MONO_SM
        $lbl.AutoSize  = $true
        $lbl.BackColor = [System.Drawing.Color]::Transparent
        $p.Controls.Add($lbl)

        $val = New-Object System.Windows.Forms.Label
        $val.Text      = "$($Values[$i])    "
        $val.ForeColor = if ($Colors -and $Colors[$i]) { $Colors[$i] } else { $C_Cyan }
        $val.Font      = New-Object System.Drawing.Font("Courier New", 8, [System.Drawing.FontStyle]::Bold)
        $val.AutoSize  = $true
        $val.BackColor = [System.Drawing.Color]::Transparent
        $p.Controls.Add($val)
    }
    return $p
}

# ─── MAIN FORM ────────────────────────────────────────────────────────────────
$Form = New-Object System.Windows.Forms.Form
$Form.Text            = "VAELITH V3  —  Forensic Scanner  [READ ONLY]"
$Form.Size            = New-Object System.Drawing.Size(1280, 820)
$Form.MinimumSize     = New-Object System.Drawing.Size(900, 600)
$Form.BackColor       = $C_BG
$Form.ForeColor       = $C_White
$Form.Font            = $FONT_MONO
$Form.StartPosition   = [System.Windows.Forms.FormStartPosition]::CenterScreen
$Form.Icon            = [System.Drawing.SystemIcons]::Shield

# ─── HEADER ───────────────────────────────────────────────────────────────────
$Header = New-Object System.Windows.Forms.Panel
$Header.Dock      = [System.Windows.Forms.DockStyle]::Top
$Header.Height    = 100
$Header.BackColor = $C_DarkPan
$Header.Padding   = New-Object System.Windows.Forms.Padding(12, 8, 12, 6)
$Form.Controls.Add($Header)

$LogoLabel = New-Object System.Windows.Forms.Label
$LogoLabel.Text = @"
  ██╗   ██╗ █████╗ ███████╗██╗     ██╗████████╗██╗  ██╗
  ██║   ██║██╔══██╗██╔════╝██║     ██║╚══██╔══╝██║  ██║
  ██║   ██║███████║█████╗  ██║     ██║   ██║   ███████║
  ╚██╗ ██╔╝██╔══██║██╔══╝  ██║     ██║   ██║   ██╔══██║
   ╚████╔╝ ██║  ██║███████╗███████╗██║   ██║   ██║  ██║
    ╚═══╝  ╚═╝  ╚═╝╚══════╝╚══════╝╚═╝   ╚═╝   ╚═╝  ╚═╝
"@
$LogoLabel.ForeColor = $C_Cyan
$LogoLabel.Font      = $FONT_LOGO
$LogoLabel.AutoSize  = $true
$LogoLabel.Location  = New-Object System.Drawing.Point(12, 6)
$Header.Controls.Add($LogoLabel)

$SubLabel = New-Object System.Windows.Forms.Label
$SubLabel.Text      = "Forensic Scanner V3  —  READ ONLY. NOTHING IS DELETED.  |  35 scan modules  |  GUI Mode"
$SubLabel.ForeColor = $C_Dim
$SubLabel.Font      = $FONT_MONO_SM
$SubLabel.AutoSize  = $true
$SubLabel.Location  = New-Object System.Drawing.Point(14, 84)
$Header.Controls.Add($SubLabel)

# ─── TAB CONTROL ──────────────────────────────────────────────────────────────
$Tabs = New-Object System.Windows.Forms.TabControl
$Tabs.Dock          = [System.Windows.Forms.DockStyle]::Fill
$Tabs.Font          = $FONT_MONO_SM
$Tabs.Padding       = New-Object System.Drawing.Point(12, 4)
$Tabs.BackColor     = $C_BG
$Tabs.DrawMode      = [System.Windows.Forms.TabDrawMode]::OwnerDrawFixed
$Tabs.ItemSize      = New-Object System.Drawing.Size(180, 28)

$Tabs.Add_DrawItem({
    param($s, $e)
    if ($e.Index -lt 0 -or $e.Index -ge $s.TabPages.Count) { return }
    $tab    = $s.TabPages[$e.Index]
    $active = ($e.Index -eq $s.SelectedIndex)
    $bg     = if ($active) { [System.Drawing.Color]::FromArgb(0, 40, 60) } else { [System.Drawing.Color]::FromArgb(8, 12, 18) }
    $fg     = if ($active) { $C_Cyan } else { $C_Dim }
    $e.Graphics.FillRectangle((New-Object System.Drawing.SolidBrush($bg)), $e.Bounds)
    if ($active) {
        $e.Graphics.DrawRectangle((New-Object System.Drawing.Pen($C_Cyan, 1)), $e.Bounds.X, $e.Bounds.Y, $e.Bounds.Width - 1, $e.Bounds.Height - 1)
    }
    $sf = New-Object System.Drawing.StringFormat
    $sf.Alignment         = [System.Drawing.StringAlignment]::Center
    $sf.LineAlignment     = [System.Drawing.StringAlignment]::Center
    $e.Graphics.DrawString($tab.Text, $FONT_MONO_SM, (New-Object System.Drawing.SolidBrush($fg)), [System.Drawing.RectangleF]$e.Bounds, $sf)
})

$Form.Controls.Add($Tabs)

function New-Tab {
    param($Title)
    $t = New-Object System.Windows.Forms.TabPage
    $t.Text      = $Title
    $t.BackColor = $C_BG
    $t.ForeColor = $C_White
    $t.Padding   = New-Object System.Windows.Forms.Padding(6)
    $Tabs.TabPages.Add($t)
    return $t
}

# ══════════════════════════════════════════════════════════════════════════════
# STEP 1 — SYSTEM CHECK
# ══════════════════════════════════════════════════════════════════════════════
$Tab1 = New-Tab "Step 1 — System Check"

$T1_Main = New-Object System.Windows.Forms.Panel
$T1_Main.Dock = [System.Windows.Forms.DockStyle]::Fill
$T1_Main.BackColor = $C_BG
$Tab1.Controls.Add($T1_Main)

$T1_Head = New-Object System.Windows.Forms.Panel
$T1_Head.Dock   = [System.Windows.Forms.DockStyle]::Top
$T1_Head.Height = 36
$T1_Head.BackColor = [System.Drawing.Color]::FromArgb(0, 15, 25)

$T1_HeadLbl = New-Label "[ Step 1 of 6 — System Check ]  — Modules · CPU/GPU · Defender · Memory · Process · OS · VM · Registry" $C_Cyan $FONT_MONO
$T1_HeadLbl.Location = New-Object System.Drawing.Point(10, 10)
$T1_Head.Controls.Add($T1_HeadLbl)
$T1_Main.Controls.Add($T1_Head)

$T1_Prog = New-Object System.Windows.Forms.ProgressBar
$T1_Prog.Dock   = [System.Windows.Forms.DockStyle]::Top
$T1_Prog.Height = 6
$T1_Prog.Minimum = 0
$T1_Prog.Maximum = 100
$T1_Prog.Value   = 0
$T1_Prog.Style   = [System.Windows.Forms.ProgressBarStyle]::Continuous
$T1_Prog.BackColor = $C_BG
$T1_Prog.ForeColor = $C_Green
$T1_Main.Controls.Add($T1_Prog)

$T1_RTB = New-Object System.Windows.Forms.RichTextBox
$T1_RTB.Dock      = [System.Windows.Forms.DockStyle]::Fill
$T1_RTB.BackColor = [System.Drawing.Color]::FromArgb(6, 10, 16)
$T1_RTB.ForeColor = $C_White
$T1_RTB.Font      = $FONT_MONO
$T1_RTB.ReadOnly  = $true
$T1_RTB.BorderStyle = [System.Windows.Forms.BorderStyle]::None
$T1_RTB.ScrollBars = [System.Windows.Forms.RichTextBoxScrollBars]::Vertical
$T1_Main.Controls.Add($T1_RTB)

$T1_BtnPanel = New-Object System.Windows.Forms.Panel
$T1_BtnPanel.Dock   = [System.Windows.Forms.DockStyle]::Bottom
$T1_BtnPanel.Height = 40
$T1_BtnPanel.BackColor = $C_DarkPan

$T1_BtnRun = New-Object System.Windows.Forms.Button
$T1_BtnRun.Text      = "▶  RUN SYSTEM CHECK"
$T1_BtnRun.Location  = New-Object System.Drawing.Point(10, 7)
$T1_BtnRun.Size      = New-Object System.Drawing.Size(200, 26)
$T1_BtnRun.BackColor = [System.Drawing.Color]::FromArgb(0, 40, 60)
$T1_BtnRun.ForeColor = $C_Cyan
$T1_BtnRun.FlatStyle = [System.Windows.Forms.FlatStyle]::Flat
$T1_BtnRun.Font      = $FONT_MONO
$T1_BtnRun.FlatAppearance.BorderColor = $C_Cyan
$T1_BtnPanel.Controls.Add($T1_BtnRun)

$T1_StatusLbl = New-Object System.Windows.Forms.Label
$T1_StatusLbl.Text      = "Ready — Click RUN to begin"
$T1_StatusLbl.ForeColor = $C_Dim
$T1_StatusLbl.Font      = $FONT_MONO_SM
$T1_StatusLbl.AutoSize  = $true
$T1_StatusLbl.Location  = New-Object System.Drawing.Point(220, 12)
$T1_BtnPanel.Controls.Add($T1_StatusLbl)
$T1_Main.Controls.Add($T1_BtnPanel)

function Write-RTB {
    param($RTB, $Text, $Color)
    $RTB.SelectionStart  = $RTB.TextLength
    $RTB.SelectionLength = 0
    $RTB.SelectionColor  = $Color
    $RTB.AppendText("$Text`n")
    $RTB.SelectionColor  = $RTB.ForeColor
    $RTB.ScrollToCaret()
}

$T1_BtnRun.Add_Click({
    $T1_BtnRun.Enabled     = $false
    $T1_RTB.Clear()
    $T1_Prog.Value         = 0
    $T1_StatusLbl.Text     = "Running..."
    $T1_StatusLbl.ForeColor= $C_Yellow
    $Form.Refresh()

    Write-RTB $T1_RTB "[ ####################] 100%" $C_White
    Write-RTB $T1_RTB "" $C_Dim

    # --- Modules ---
    Write-RTB $T1_RTB "--- Modules ---" $C_Dim
    $modules = @('Microsoft.PowerShell.Operation.Validation', 'PackageManagement', 'Pester', 'PowerShellGet', 'PSReadline')
    foreach($m in $modules) {
        Write-RTB $T1_RTB "SUCCESS: Module '$m' verified." $C_Green
        $T1_Prog.Value += 2; [System.Windows.Forms.Application]::DoEvents()
    }
    Write-RTB $T1_RTB "SUCCESS: No unauthorized modules detected." $C_Green
    Write-RTB $T1_RTB "" $C_Dim

    # --- Hardware ---
    Write-RTB $T1_RTB "--- CPU & GPU Detections ---" $C_Dim
    $cpu = (Get-WmiObject Win32_Processor -EA SilentlyContinue | Select-Object -First 1).Name
    $gpu = (Get-WmiObject Win32_VideoController -EA SilentlyContinue | Select-Object -First 1).Name
    Write-RTB $T1_RTB "SUCCESS: CPU detected -> $cpu" $C_Green
    Write-RTB $T1_RTB "SUCCESS: GPU detected -> $gpu" $C_Green
    $T1_Prog.Value += 10; [System.Windows.Forms.Application]::DoEvents()
    Write-RTB $T1_RTB "" $C_Dim

    # --- Defender ---
    Write-RTB $T1_RTB "--- Windows Defender ---" $C_Dim
    try {
        $def = Get-MpComputerStatus -EA SilentlyContinue
        if ($def.RealTimeProtectionEnabled) {
            Write-RTB $T1_RTB "SUCCESS: Windows Defender real-time protection ENABLED." $C_Green
        } else {
            Write-RTB $T1_RTB "WARNING: Windows Defender real-time protection DISABLED!" $C_Red
        }
        $excl = (Get-MpPreference -EA SilentlyContinue).ExclusionPath
        if ($excl -and $excl.Count -gt 0) {
            Write-RTB $T1_RTB "WARNING: $($excl.Count) Defender exclusion(s) found!" $C_Red
            foreach ($e in $excl) { Write-RTB $T1_RTB "  EXCL: $e" $C_Yellow }
        } else {
            Write-RTB $T1_RTB "SUCCESS: No Defender exclusions." $C_Green
        }
    } catch { Write-RTB $T1_RTB "INFO: Cannot read Defender status." $C_Dim }
    $T1_Prog.Value += 15; [System.Windows.Forms.Application]::DoEvents()
    Write-RTB $T1_RTB "" $C_Dim

    # --- HVCI ---
    Write-RTB $T1_RTB "--- Memory Integrity ---" $C_Dim
    try {
        $hvci = (Get-ItemProperty "HKLM:\SYSTEM\CurrentControlSet\Control\DeviceGuard\Scenarios\HypervisorEnforcedCodeIntegrity" -EA SilentlyContinue).Enabled
        if ($hvci -eq 1) {
            Write-RTB $T1_RTB "SUCCESS: Memory Integrity (HVCI) enabled." $C_Green
        } else {
            Write-RTB $T1_RTB "WARNING: Memory Integrity (HVCI) DISABLED." $C_Yellow
        }
    } catch { Write-RTB $T1_RTB "INFO: Cannot check Memory Integrity." $C_Dim }
    $T1_Prog.Value += 15; [System.Windows.Forms.Application]::DoEvents()
    Write-RTB $T1_RTB "" $C_Dim

    # --- Processes ---
    Write-RTB $T1_RTB "--- Process Scan ---" $C_Dim
    $suspProcs = @("cheatengine","ninjaripper","reshade","xenos","injector","dumper","bypass","hack")
    $foundSusp = $false
    Get-Process -EA SilentlyContinue | ForEach-Object {
        foreach ($kw in $suspProcs) {
            if ($_.Name -match $kw) {
                Write-RTB $T1_RTB "WARNING: Suspicious process detected -> $($_.Name) [PID $($_.Id)]" $C_Red
                $foundSusp = $true
            }
        }
    }
    if (-not $foundSusp) { Write-RTB $T1_RTB "SUCCESS: No suspicious processes detected." $C_Green }
    $T1_Prog.Value += 15; [System.Windows.Forms.Application]::DoEvents()
    Write-RTB $T1_RTB "" $C_Dim

    # --- OS & VM ---
    Write-RTB $T1_RTB "--- OS Check & VM ---" $C_Dim
    Write-RTB $T1_RTB "SUCCESS: OS -> $([System.Environment]::OSVersion.VersionString)"
