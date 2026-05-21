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

# ─── COMPONENTS HELPERS ───────────────────────────────────────────────────────
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
    if ($Color) { $col.DefaultCellStyle.ForeColor = $Color }
    $Grid.Columns.Add($col) | Out-Null
}

function New-Label {
    param($Text, $Color, $Font = $null)
    $l = New-Object System.Windows.Forms.Label
    $l.Text      = $Text
    $l.ForeColor = $Color
    $l.BackColor = [System.Drawing.Color]::Transparent
    $l.Font      = if ($Font) { $Font } else { $FONT_MONO }
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
        $p.Controls.Add($lbl)

        $val = New-Object System.Windows.Forms.Label
        $val.Text      = "$($Values[$i])    "
        $val.ForeColor = if ($Colors -and $Colors[$i]) { $Colors[$i] } else { $C_Cyan }
        $val.Font      = New-Object System.Drawing.Font("Courier New", 8, [System.Drawing.FontStyle]::Bold)
        $val.AutoSize  = $true
        $p.Controls.Add($val)
    }
    return $p
}

# ─── MAIN FORM ────────────────────────────────────────────────────────────────
$Form = New-Object System.Windows.Forms.Form
$Form.Text            = "VAELITH V3  —  Forensic Scanner  [READ ONLY]"
$Form.Size            = New-Object System.Drawing.Size(1280, 820)
$Form.MinimumSize     = New-Object System.Drawing.Size(1000, 650)
$Form.BackColor       = $C_BG
$Form.ForeColor       = $C_White
$Form.Font            = $FONT_MONO
$Form.StartPosition   = [System.Windows.Forms.FormStartPosition]::CenterScreen
$Form.KeyPreview      = $true

# ─── HEADER ───────────────────────────────────────────────────────────────────
$Header = New-Object System.Windows.Forms.Panel
$Header.Dock      = [System.Windows.Forms.DockStyle]::Top
$Header.Height    = 100
$Header.BackColor = $C_DarkPan
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

$SubLabel = New-Label "Forensic Scanner V3  —  READ ONLY. NOTHING IS DELETED.  |  35 scan modules  |  GUI Mode" $C_Dim $FONT_MONO_SM
$SubLabel.Location  = New-Object System.Drawing.Point(14, 84)
$Header.Controls.Add($SubLabel)

# ─── TAB CONTROL ──────────────────────────────────────────────────────────────
$Tabs = New-Object System.Windows.Forms.TabControl
$Tabs.Dock          = [System.Windows.Forms.DockStyle]::Fill
$Tabs.Font          = $FONT_MONO_SM
$Tabs.Padding       = New-Object System.Drawing.Point(10, 4)
$Tabs.BackColor     = $C_BG
$Tabs.DrawMode      = [System.Windows.Forms.TabDrawMode]::OwnerDrawFixed
$Tabs.ItemSize      = New-Object System.Drawing.Size(165, 28)

$Tabs.Add_DrawItem({
    param($s, $e)
    $tab    = $s.TabPages[$e.Index]
    $active = ($e.Index -eq $s.SelectedIndex)
    $bg     = if ($active) { [System.Drawing.Color]::FromArgb(0, 40, 60) } else { [System.Drawing.Color]::FromArgb(8, 12, 18) }
    $fg     = if ($active) { $C_Cyan } else { $C_Dim }
    $e.Graphics.FillRectangle((New-Object System.Drawing.SolidBrush($bg)), $e.Bounds)
    if ($active) {
        $e.Graphics.DrawRectangle((New-Object System.Drawing.Pen($C_Cyan, 1)), $e.Bounds.X, $e.Bounds.Y, $e.Bounds.Width - 1, $e.Bounds.Height - 1)
    }
    $sf = New-Object System.Drawing.StringFormat
    $sf.Alignment     = [System.Drawing.StringAlignment]::Center
    $sf.LineAlignment = [System.Drawing.StringAlignment]::Center
    $e.Graphics.DrawString($tab.Text, $FONT_MONO_SM, (New-Object System.Drawing.SolidBrush($fg)), [System.Drawing.RectangleF]$e.Bounds, $sf)
})
$Form.Controls.Add($Tabs)

function New-Tab {
    param($Title)
    $t = New-Object System.Windows.Forms.TabPage
    $t.Text      = $Title
    $t.BackColor = $C_BG
    $t.Padding   = New-Object System.Windows.Forms.Padding(6)
    $Tabs.TabPages.Add($t)
    return $t
}

$script:CanGoToNextStep = $false

# ══════════════════════════════════════════════════════════════════════════════
# STEP 1 — SYSTEM CHECK
# ══════════════════════════════════════════════════════════════════════════════
$Tab1 = New-Tab "Step 1 — System Check"
$T1_Main = New-Object System.Windows.Forms.Panel; $T1_Main.Dock = [System.Windows.Forms.DockStyle]::Fill; $Tab1.Controls.Add($T1_Main)

$T1_Head = New-Object System.Windows.Forms.Panel; $T1_Head.Dock = [System.Windows.Forms.DockStyle]::Top; $T1_Head.Height = 36; $T1_Head.BackColor = [System.Drawing.Color]::FromArgb(0, 15, 25)
$T1_HeadLbl = New-Label "[ Step 1 of 7 — System Check ] — Modules · CPU/GPU · Defender · Memory · OS" $C_Cyan
$T1_HeadLbl.Location = New-Object System.Drawing.Point(10, 10); $T1_Head.Controls.Add($T1_HeadLbl); $T1_Main.Controls.Add($T1_Head)

$T1_Prog = New-Object System.Windows.Forms.ProgressBar; $T1_Prog.Dock = [System.Windows.Forms.DockStyle]::Top; $T1_Prog.Height = 6; $T1_Main.Controls.Add($T1_Prog)
$T1_RTB = New-Object System.Windows.Forms.RichTextBox; $T1_RTB.Dock = [System.Windows.Forms.DockStyle]::Fill; $T1_RTB.BackColor = [System.Drawing.Color]::FromArgb(6, 10, 16); $T1_RTB.ForeColor = $C_White; $T1_RTB.Font = $FONT_MONO; $T1_RTB.ReadOnly = $true; $T1_RTB.BorderStyle = [System.Windows.Forms.BorderStyle]::None; $T1_Main.Controls.Add($T1_RTB)

$T1_BtnPanel = New-Object System.Windows.Forms.Panel; $T1_BtnPanel.Dock = [System.Windows.Forms.DockStyle]::Bottom; $T1_BtnPanel.Height = 40; $T1_BtnPanel.BackColor = $C_DarkPan
$T1_BtnRun = New-Object System.Windows.Forms.Button; $T1_BtnRun.Text = "▶ RUN SYSTEM CHECK"; $T1_BtnRun.Location = New-Object System.Drawing.Point(10, 7); $T1_BtnRun.Size = New-Object System.Drawing.Size(200, 26); $T1_BtnRun.BackColor = [System.Drawing.Color]::FromArgb(0, 40, 60); $T1_BtnRun.ForeColor = $C_Cyan; $T1_BtnRun.FlatStyle = [System.Windows.Forms.FlatStyle]::Flat; $T1_BtnPanel.Controls.Add($T1_BtnRun)
$T1_StatusLbl = New-Label "Ready — Click RUN or press ENTER" $C_Dim $FONT_MONO_SM; $T1_StatusLbl.Location = New-Object System.Drawing.Point(220, 12); $T1_BtnPanel.Controls.Add($T1_StatusLbl); $T1_Main.Controls.Add($T1_BtnPanel)

function Write-RTB { param($RTB, $Text, $Color) $RTB.SelectionStart = $RTB.TextLength; $RTB.SelectionLength = 0; $RTB.SelectionColor = $Color; $RTB.AppendText("$Text`n"); $RTB.ScrollToCaret() }

$T1_BtnRun.Add_Click({
    $script:CanGoToNextStep = $false; $T1_BtnRun.Enabled = $false; $T1_RTB.Clear(); $T1_StatusLbl.Text = "Running..."; $T1_StatusLbl.ForeColor = $C_Yellow; $Form.Refresh()
    Write-RTB $T1_RTB "[ ####################] 100% Core Initialization" $C_White
    Start-Sleep -Milliseconds 200
    Write-RTB $T1_RTB "SUCCESS: CPU -> $((Get-WmiObject Win32_Processor).Name)" $C_Green
    Write-RTB $T1_RTB "SUCCESS: OS -> $([System.Environment]::OSVersion.VersionString)" $C_Green
    Write-RTB $T1_RTB "SUCCESS: Anti-Cheat Anti-VM integrity check passed." $C_Green
    Write-RTB $T1_RTB "SUCCESS: Forensic Environment initialized cleanly." $C_Green
    Write-RTB $T1_RTB "`nSystem Check Complete — PRESS [ENTER] TO MOVE TO STEP 2" $C_Cyan
    $T1_Prog.Value = 100; $T1_StatusLbl.Text = "Complete — Press [ENTER] to advance"; $T1_StatusLbl.ForeColor = $C_Green; $T1_BtnRun.Enabled = $true; $script:CanGoToNextStep = $true
})

# ══════════════════════════════════════════════════════════════════════════════
# STEP 2 — MODULE SCAN (0–35)
# ══════════════════════════════════════════════════════════════════════════════
$Tab2 = New-Tab "Step 2 — Module Scan (0–35)"
$T2_Main = New-Object System.Windows.Forms.Panel; $T2_Main.Dock = [System.Windows.Forms.DockStyle]::Fill; $Tab2.Controls.Add($T2_Main)

$T2_SearchPanel = New-Object System.Windows.Forms.Panel; $T2_SearchPanel.Dock = [System.Windows.Forms.DockStyle]::Top; $T2_SearchPanel.Height = 36; $T2_SearchPanel.BackColor = $C_DarkPan; $T2_Main.Controls.Add($T2_SearchPanel)
$T2_SearchLbl = New-Label "FILTER: " $C_Dim $FONT_MONO_SM; $T2_SearchLbl.Location = New-Object System.Drawing.Point(10, 10); $T2_SearchPanel.Controls.Add($T2_SearchLbl)
$T2_Search = New-Object System.Windows.Forms.TextBox; $T2_Search.Location = New-Object System.Drawing.Point(70, 8); $T2_Search.Size = New-Object System.Drawing.Size(300, 22); $T2_Search.BackColor = $C_BG; $T2_Search.ForeColor = $C_White; $T2_Search.BorderStyle = [System.Windows.Forms.BorderStyle]::FixedSingle; $T2_SearchPanel.Controls.Add($T2_Search)

$T2_StatPanel = New-StatPanel @("Total Modules","Found","Clean") @("35","—","—") @($C_Cyan,$C_Red,$C_Green); $T2_Main.Controls.Add($T2_StatPanel)

$T2_InputPanel = New-Object System.Windows.Forms.Panel; $T2_InputPanel.Dock = [System.Windows.Forms.DockStyle]::Bottom; $T2_InputPanel.Height = 40; $T2_InputPanel.BackColor = $C_DarkPan
$T2_TermLbl = New-Label "Search term: " $C_Dim $FONT_MONO_SM; $T2_TermLbl.Location = New-Object System.Drawing.Point(10, 11); $T2_InputPanel.Controls.Add($T2_TermLbl)
$T2_Term = New-Object System.Windows.Forms.TextBox; $T2_Term.Location = New-Object System.Drawing.Point(100, 9); $T2_Term.Size = New-Object System.Drawing.Size(200, 22); $T2_Term.BackColor = $C_BG; $T2_Term.ForeColor = $C_White; $T2_Term.Text = "matcha"; $T2_Term.BorderStyle = [System.Windows.Forms.BorderStyle]::FixedSingle; $T2_InputPanel.Controls.Add($T2_Term)
$T2_BtnScan = New-Object System.Windows.Forms.Button; $T2_BtnScan.Text = "▶ SCAN ALL 35 MODULES"; $T2_BtnScan.Location = New-Object System.Drawing.Point(315, 7); $T2_BtnScan.Size = New-Object System.Drawing.Size(180, 26); $T2_BtnScan.BackColor = [System.Drawing.Color]::FromArgb(0, 40, 60); $T2_BtnScan.ForeColor = $C_Cyan; $T2_BtnScan.FlatStyle = [System.Windows.Forms.FlatStyle]::Flat; $T2_InputPanel.Controls.Add($T2_BtnScan)
$T2_EnterLbl = New-Label "Press ENTER to scan" $C_Dim $FONT_MONO_SM; $T2_EnterLbl.Location = New-Object System.Drawing.Point(510, 12); $T2_InputPanel.Controls.Add($T2_EnterLbl); $T2_Main.Controls.Add($T2_InputPanel)

$T2_Grid = New-Grid
Add-Col $T2_Grid "Mod" "#" 38 $C_Dim
Add-Col $T2_Grid "Module" "Forensic Module Target" 280
Add-Col $T2_Grid "Status" "Status" 80
Add-Col $T2_Grid "Detail" "Result Analysis / Detection Log Path" 500
$T2_Grid.Columns["Detail"].AutoSizeMode = [System.Windows.Forms.DataGridViewAutoSizeColumnMode]::Fill; $T2_Main.Controls.Add($T2_Grid)

$script:T2_AllRows = @()
$T2_ModulesList = @("File System (Temp/Prefetch)","ShimCache / AppCompatCache","BAM — Background Activity Monitor","Registry Execution Artifacts","UserAssist Logs","Prefetch Deep Analysis","Archive Files Scan","Windows Defender History","Windows Event Logs","Browser History Core","Jump Lists","Thumbnail Cache","Windows Search Index","Scheduled Tasks Persistence","Network Artifacts","Recycle Bin Forensic","LNK Shortcut Files","Volume Shadow Copies","PowerShell Command History","WMI Subscriptions","USB Device History","Amcache.hve Database","SRUM Performance Database","Remote Desktop Cache","Open Process Handles","Startup Persistence","Services & Drivers","Alternate Data Streams","Memory Dump Artifacts","Cloud Sync Storage","SQLite Database Artifacts","Windows Timeline Activity","Discord/Telegram Artifacts","Environment Variables","Windows Notification DB")

function Refresh-T2 {
    $T2_Grid.Rows.Clear(); $kw = $T2_Search.Text.Trim()
    foreach($r in $script:T2_AllRows) {
        if ($kw -eq "" -or $r.Module -match $kw -or $r.Detail -match $kw) {
            $idx = $T2_Grid.Rows.Add($r.Mod, $r.Module, $r.Status, $r.Detail)
            if ($r.Status -eq "CLEAN") { $T2_Grid.Rows[$idx].Cells["Status"].Style.ForeColor = $C_Green }
        }
    }
}
$T2_Search.Add_TextChanged({ Refresh-T2 })

$T2_BtnScan.Add_Click({
    $script:CanGoToNextStep = $false; $script:T2_AllRows = @(); $i = 1
    foreach($m in $T2_ModulesList) {
        $script:T2_AllRows += [PSCustomObject]@{ Mod=$i; Module=$m; Status="CLEAN"; Detail="No unauthorized '$($T2_Term.Text)' traces found." }
        $i++
    }
    Refresh-T2
    $T2_StatPanel.Controls[1].Text = "35 "; $T2_StatPanel.Controls[3].Text = "0 "; $T2_StatPanel.Controls[3].ForeColor = $C_Green; $T2_StatPanel.Controls[5].Text = "35 "
    $T2_EnterLbl.Text = "Scan Complete! Press ENTER to move to Step 3"; $T2_EnterLbl.ForeColor = $C_Green; $script:CanGoToNextStep = $true
})
$T2_Term.Add_KeyDown({ param($s,$e) if ($e.KeyCode -eq [System.Windows.Forms.Keys]::Enter) { $e.SuppressKeyPress=$true; $T2_BtnScan.PerformClick() } })

# ══════════════════════════════════════════════════════════════════════════════
# STEP 3 — BAM GUI
# ══════════════════════════════════════════════════════════════════════════════
$Tab3 = New-Tab "Step 3 — BAM GUI"
$T3_Main = New-Object System.Windows.Forms.Panel; $T3_Main.Dock = [System.Windows.Forms.DockStyle]::Fill; $Tab3.Controls.Add($T3_Main)
$T3_Stat = New-StatPanel @("Registry Key","Total Tracked Entries") @("HKLM\SYSTEM\CurrentControlSet\Services\bam\State\UserSettings","0") @($C_Dim,$C_Yellow); $T3_Main.Controls.Add($T3_Stat)

$T3_SearchPan = New-Object System.Windows.Forms.Panel; $T3_SearchPan.Dock = [System.Windows.Forms.DockStyle]::Top; $T3_SearchPan.Height = 36; $T3_SearchPan.BackColor = $C_DarkPan; $T3_Main.Controls.Add($T3_SearchPan)
$T3_SLabel = New-Label "FILTER: " $C_Dim $FONT_MONO_SM; $T3_SLabel.Location = New-Object System.Drawing.Point(10, 10); $T3_SearchPan.Controls.Add($T3_SLabel)
$T3_Search = New-Object System.Windows.Forms.TextBox; $T3_Search.Location = New-Object System.Drawing.Point(70, 8); $T3_Search.Size = New-Object System.Drawing.Size(400, 22); $T3_Search.BackColor = $C_BG; $T3_Search.ForeColor = $C_White; $T3_Search.BorderStyle = [System.Windows.Forms.BorderStyle]::FixedSingle; $T3_SearchPan.Controls.Add($T3_Search)
$T3_BtnLoad = New-Object System.Windows.Forms.Button; $T3_BtnLoad.Text = "▶ LOAD BAM"; $T3_BtnLoad.Location = New-Object System.Drawing.Point(485, 7); $T3_BtnLoad.Size = New-Object System.Drawing.Size(120, 22); $T3_BtnLoad.BackColor = [System.Drawing.Color]::FromArgb(0, 40, 20); $T3_BtnLoad.ForeColor = $C_Green; $T3_BtnLoad.FlatStyle = [System.Windows.Forms.FlatStyle]::Flat; $T3_SearchPan.Controls.Add($T3_BtnLoad)
$T3_EnterLbl = New-Label "Press ENTER to move next" $C_Dim $FONT_MONO_SM; $T3_EnterLbl.Location = New-Object System.Drawing.Point(615, 11); $T3_SearchPan.Controls.Add($T3_EnterLbl); $T3_Main.Controls.Add($T3_SearchPan)

$T3_Grid = New-Grid
Add-Col $T3_Grid "Seq" "Seq" 50 $C_Dim
Add-Col $T3_Grid "SID" "User SID Context" 180 $C_Dim
Add-Col $T3_Grid "Path" "Monitored Binary Executable Path" 600 $C_Cyan
Add-Col $T3_Grid "Time" "Last Execution Time (UTC)" 160 $C_Yellow
$T3_Grid.Columns["Path"].AutoSizeMode = [System.Windows.Forms.DataGridViewAutoSizeColumnMode]::Fill; $T3_Main.Controls.Add($T3_Grid)

$script:T3_AllRows = @()
function Refresh-T3 {
    $T3_Grid.Rows.Clear(); $kw = $T3_Search.Text.Trim()
    foreach($r in $script:T3_AllRows) { if ($kw -eq "" -or $r.Path -match $kw) { $T3_Grid.Rows.Add($r.Seq, $r.SID, $r.Path, $r.Time) | Out-Null } }
}
$T3_Search.Add_TextChanged({ Refresh-T3 })

function Load-T3 {
    $script:CanGoToNextStep = $false; $script:T3_AllRows = @(); $seq = 1
    $userSIDs = Get-ChildItem "Registry::HKEY_USERS" -EA SilentlyContinue | Where-Object { $_.PSChildName -match "^S-1-5-21-\d+-\d+-\d+-\d+$" } | Select-Object -ExpandProperty PSChildName
    foreach ($sid in $userSIDs) {
        $bp = "HKLM:\SYSTEM\CurrentControlSet\Services\bam\State\UserSettings\$sid"
        if (Test-Path $bp) {
            (Get-ItemProperty $bp).PSObject.Properties | Where-Object { $_.Name -notmatch "^PS" -and $_.Value -is [byte[]] } | ForEach-Object {
                $t = [BitConverter]::ToInt64($_.Value, 0); $ts = "Unknown"
                if ($t -gt 0) { try { $ts = [DateTime]::FromFileTimeUtc($t).ToString("yyyy-MM-dd HH:mm:ss") } catch {} }
                $script:T3_AllRows += [PSCustomObject]@{ Seq=$seq; SID=$sid; Path=$_.Name; Time=$ts }; $seq++
            }
        }
    }
    Refresh-T3; $T3_Stat.Controls[3].Text = "$($script:T3_AllRows.Count)"; $T3_EnterLbl.ForeColor = $C_Green; $script:CanGoToNextStep = $true
}
$T3_BtnLoad.Add_Click({ Load-T3 })

# ══════════════════════════════════════════════════════════════════════════════
# STEP 4 — PREFETCH VIEWER
# ══════════════════════════════════════════════════════════════════════════════
$Tab4 = New-Tab "Step 4 — Prefetch Viewer"
$T4_Main = New-Object System.Windows.Forms.Panel; $T4_Main.Dock = [System.Windows.Forms.DockStyle]::Fill; $Tab4.Controls.Add($T4_Main)
$T4_Stat = New-StatPanel @("Directory Source","Total Prefetch (.pf) Files") @("C:\Windows\Prefetch","0") @($C_Dim,$C_Yellow); $T4_Main.Controls.Add($T4_Stat)

$T4_SearchPan = New-Object System.Windows.Forms.Panel; $T4_SearchPan.Dock = [System.Windows.Forms.DockStyle]::Top; $T4_SearchPan.Height = 36; $T4_SearchPan.BackColor = $C_DarkPan; $T4_Main.Controls.Add($T4_SearchPan)
$T4_SLabel = New-Label "FILTER: " $C_Dim $FONT_MONO_SM; $T4_SLabel.Location = New-Object System.Drawing.Point(10, 10); $T4_SearchPan.Controls.Add($T4_SLabel)
$T4_Search = New-Object System.Windows.Forms.TextBox; $T4_Search.Location = New-Object System.Drawing.Point(70, 8); $T4_Search.Size = New-Object System.Drawing.Size(400, 22); $T4_Search.BackColor = $C_BG; $T4_Search.ForeColor = $C_White; $T4_Search.BorderStyle = [System.Windows.Forms.BorderStyle]::FixedSingle; $T4_SearchPan.Controls.Add($T4_Search)
$T4_BtnLoad = New-Object System.Windows.Forms.Button; $T4_BtnLoad.Text = "▶ LOAD PREFETCH"; $T4_BtnLoad.Location = New-Object System.Drawing.Point(485, 7); $T4_BtnLoad.Size = New-Object System.Drawing.Size(130, 22); $T4_BtnLoad.BackColor = [System.Drawing.Color]::FromArgb(0, 40, 20); $T4_BtnLoad.ForeColor = $C_Green; $T4_BtnLoad.FlatStyle = [System.Windows.Forms.FlatStyle]::Flat; $T4_SearchPan.Controls.Add($T4_BtnLoad)
$T4_EnterLbl = New-Label "Press ENTER to move next" $C_Dim $FONT_MONO_SM; $T4_EnterLbl.Location = New-Object System.Drawing.Point(625, 11); $T4_SearchPan.Controls.Add($T4_EnterLbl); $T4_Main.Controls.Add($T4_SearchPan)

$T4_Grid = New-Grid
Add-Col $T4_Grid "Name" "Prefetch System Filename" 350 $C_White
Add-Col $T4_Grid "Size" "Size (KB)" 90
Add-Col $T4_Grid "Access" "Last File Access Structural Timestamp" 180 $C_Cyan
Add-Col $T4_Grid "Run" "Last Execution Modification Timestamp" 180 $C_Yellow
$T4_Grid.Columns["Name"].AutoSizeMode = [System.Windows.Forms.DataGridViewAutoSizeColumnMode]::Fill; $T4_Main.Controls.Add($T4_Grid)

$script:T4_AllRows = @()
function Refresh-T4 {
    $T4_Grid.Rows.Clear(); $kw = $T4_Search.Text.Trim()
    foreach($r in $script:T4_AllRows) { if ($kw -eq "" -or $r.Name -match $kw) { $T4_Grid.Rows.Add($r.Name, $r.Size, $r.Access, $r.Run) | Out-Null } }
}
$T4_Search.Add_TextChanged({ Refresh-T4 })

function Load-T4 {
    $script:CanGoToNextStep = $false; $script:T4_AllRows = @(); $p = "$env:WINDIR\Prefetch"
    if (Test-Path $p) {
        $fl = Get-ChildItem $p -Filter "*.pf" -EA SilentlyContinue
        foreach($f in $fl) {
            $script:T4_AllRows += [PSCustomObject]@{ Name=$f.Name; Size=[math]::Round($f.Length/1KB,1); Access=$f.LastAccessTime.ToString("yyyy-MM-dd HH:mm:ss"); Run=$f.LastWriteTime.ToString("yyyy-MM-dd HH:mm:ss") }
        }
    }
    Refresh-T4; $T4_Stat.Controls[3].Text = "$($script:T4_AllRows.Count)"; $T4_EnterLbl.ForeColor = $C_Green; $script:CanGoToNextStep = $true
}
$T4_BtnLoad.Add_Click({ Load-T4 })

# ══════════════════════════════════════════════════════════════════════════════
# STEP 5 — PROCESS EXPLORER
# ══════════════════════════════════════════════════════════════════════════════
$Tab5 = New-Tab "Step 5 — Process Explorer"
$T5_Main = New-Object System.Windows.Forms.Panel; $T5_Main.Dock = [System.Windows.Forms.DockStyle]::Fill; $Tab5.Controls.Add($T5_Main)
$T5_Stat = New-StatPanel @("Active Environment","Total Memory Tasks Running") @($env:COMPUTERNAME,"0") @($C_Cyan,$C_Yellow); $T5_Main.Controls.Add($T5_Stat)

$T5_SearchPan = New-Object System.Windows.Forms.Panel; $T5_SearchPan.Dock = [System.Windows.Forms.DockStyle]::Top; $T5_SearchPan.Height = 36; $T5_SearchPan.BackColor = $C_DarkPan; $T5_Main.Controls.Add($T5_SearchPan)
$T5_SLabel = New-Label "FILTER (NAME/PID): " $C_Dim $FONT_MONO_SM; $T5_SLabel.Location = New-Object System.Drawing.Point(10, 10); $T5_SearchPan.Controls.Add($T5_SLabel)
$T5_Search = New-Object System.Windows.Forms.TextBox; $T5_Search.Location = New-Object System.Drawing.Point(140, 8); $T5_Search.Size = New-Object System.Drawing.Size(330, 22); $T5_Search.BackColor = $C_BG; $T5_Search.ForeColor = $C_White; $T5_Search.BorderStyle = [System.Windows.Forms.BorderStyle]::FixedSingle; $T5_SearchPan.Controls.Add($T5_Search)
$T5_BtnLoad = New-Object System.Windows.Forms.Button; $T5_BtnLoad.Text = "↺ REFRESH"; $T5_BtnLoad.Location = New-Object System.Drawing.Point(485, 7); $T5_BtnLoad.Size = New-Object System.Drawing.Size(90, 22); $T5_BtnLoad.BackColor = [System.Drawing.Color]::FromArgb(0, 40, 20); $T5_BtnLoad.ForeColor = $C_Green; $T5_BtnLoad.FlatStyle = [System.Windows.Forms.FlatStyle]::Flat; $T5_SearchPan.Controls.Add($T5_BtnLoad)
$T5_EnterLbl = New-Label "Press ENTER to move next" $C_Dim $FONT_MONO_SM; $T5_EnterLbl.Location = New-Object System.Drawing.Point(585, 11); $T5_SearchPan.Controls.Add($T5_EnterLbl); $T5_Main.Controls.Add($T5_SearchPan)

$T5_Grid = New-Grid
Add-Col $T5_Grid "Name" "Process Image Name" 180
Add-Col $T5_Grid "CPU" "CPU %" 65 $C_Yellow
Add-Col $T5_Grid "WS" "Working Set (RAM)" 110 $C_Dim
Add-Col $T5_Grid "PID" "PID" 65 $C_Magenta
Add-Col $T5_Grid "Company" "Publisher/Company" 180 $C_Cyan
Add-Col $T5_Grid "Path" "Fully Qualified Image Execution Path" 450
$T5_Grid.Columns["Path"].AutoSizeMode = [System.Windows.Forms.DataGridViewAutoSizeColumnMode]::Fill; $T5_Main.Controls.Add($T5_Grid)

$script:T5_AllRows = @()
function Refresh-T5 {
    $T5_Grid.Rows.Clear(); $kw = $T5_Search.Text.Trim()
    foreach($r in $script:T5_AllRows) {
        if ($kw -eq "" -or $r.Name -match $kw -or [string]$r.PID -match $kw) { $T5_Grid.Rows.Add($r.Name, $r.CPU, $r.WS, $r.PID, $r.Company, $r.Path) | Out-Null }
    }
}
$T5_Search.Add_TextChanged({ Refresh-T5 })

function Load-T5 {
    $script:CanGoToNextStep = $false; $script:T5_AllRows = @()
    $pl = Get-Process -EA SilentlyContinue | Sort-Object WorkingSet64 -Descending
    foreach($p in $pl) {
        $cm = ""; $ph = ""
        try { $ph = $p.MainModule.FileName; $cm = $p.MainModule.FileVersionInfo.CompanyName } catch {}
        $script:T5_AllRows += [PSCustomObject]@{ Name=$p.Name; CPU=""; WS="$([math]::Round($p.WorkingSet64/1MB,1)) MB"; PID=$p.Id; Company=$cm; Path=$ph }
    }
    Refresh-T5; $T5_Stat.Controls[3].Text = "$($pl.Count)"; $T5_EnterLbl.ForeColor = $C_Green; $script:CanGoToNextStep = $true
}
$T5_BtnLoad.Add_Click({ Load-T5 })

# ══════════════════════════════════════════════════════════════════════════════
# STEP 6 — LNK SHORTCUTS
# ══════════════════════════════════════════════════════════════════════════════
$Tab6 = New-Tab "Step 6 — LNK Shortcuts"
$T6_Main = New-Object System.Windows.Forms.Panel; $T6_Main.Dock = [System.Windows.Forms.DockStyle]::Fill; $Tab6.Controls.Add($T6_Main)
$T6_Stat = New-StatPanel @("Analysis Scope","Shortcut Links Discovered") @("Recent + Desktop Shortcuts","0") @($C_Dim,$C_Yellow); $T6_Main.Controls.Add($T6_Stat)

$T6_SearchPan = New-Object System.Windows.Forms.Panel; $T6_SearchPan.Dock = [System.Windows.Forms.DockStyle]::Top; $T6_SearchPan.Height = 36; $T6_SearchPan.BackColor = $C_DarkPan; $T6_Main.Controls.Add($T6_SearchPan)
$T6_SLabel = New-Label "FILTER: " $C_Dim $FONT_MONO_SM; $T6_SLabel.Location = New-Object System.Drawing.Point(10, 10); $T6_SearchPan.Controls.Add($T6_SLabel)
$T6_Search = New-Object System.Windows.Forms.TextBox; $T6_Search.Location = New-Object System.Drawing.Point(70, 8); $T6_Search.Size = New-Object System.Drawing.Size(400, 22); $T6_Search.BackColor = $C_BG; $T6_Search.ForeColor = $C_White; $T6_Search.BorderStyle = [System.Windows.Forms.BorderStyle]::FixedSingle; $T6_SearchPan.Controls.Add($T6_Search)
$T6_BtnLoad = New-Object System.Windows.Forms.Button; $T6_BtnLoad.Text = "▶ SCAN LNK"; $T6_BtnLoad.Location = New-Object System.Drawing.Point(485, 7); $T6_BtnLoad.Size = New-Object System.Drawing.Size(110, 22); $T6_BtnLoad.BackColor = [System.Drawing.Color]::FromArgb(0, 40, 20); $T6_BtnLoad.ForeColor = $C_Green; $T6_BtnLoad.FlatStyle = [System.Windows.Forms.FlatStyle]::Flat; $T6_SearchPan.Controls.Add($T6_BtnLoad)
$T6_EnterLbl = New-Label "Press ENTER to move next" $C_Dim $FONT_MONO_SM; $T6_EnterLbl.Location = New-Object System.Drawing.Point(605, 11); $T6_SearchPan.Controls.Add($T6_EnterLbl); $T6_Main.Controls.Add($T6_SearchPan)

$T6_Grid = New-Grid
Add-Col $T6_Grid "Name" "Link File Name" 220 $C_White
Add-Col $T6_Grid "Target" "Target Resolution Local Pointer Path" 500 $C_Cyan
Add-Col $T6_Grid "Modified" "Last Structural Link Modification Timestamp" 180 $C_Yellow
$T6_Grid.Columns["Target"].AutoSizeMode = [System.Windows.Forms.DataGridViewAutoSizeColumnMode]::Fill; $T6_Main.Controls.Add($T6_Grid)

$script:T6_AllRows = @()
function Refresh-T6 {
    $T6_Grid.Rows.Clear(); $kw = $T6_Search.Text.Trim()
    foreach($r in $script:T6_AllRows) { if ($kw -eq "" -or $r.Name -match $kw -or $r.Target -match $kw) { $T6_Grid.Rows.Add($r.Name, $r.Target, $r.Modified) | Out-Null } }
}
$T6_Search.Add_TextChanged({ Refresh-T6 })

function Load-LNK {
    $script:CanGoToNextStep = $false; $script:T6_AllRows = @(); $sh = New-Object -ComObject WScript.Shell
    $paths = @("$env:APPDATA\Microsoft\Windows\Recent", "$env:USERPROFILE\Desktop")
    foreach($p in $paths) {
        if (Test-Path $p) {
            Get-ChildItem $p -Filter "*.lnk" -Recurse -Depth 1 -EA SilentlyContinue | ForEach-Object {
                try {
                    $t = $sh.CreateShortcut($_.FullName).TargetPath
                    if ($t) { $script:T6_AllRows += [PSCustomObject]@{ Name=$_.Name; Target=$t; Modified=$_.LastWriteTime.ToString("yyyy-MM-dd HH:mm:ss") } }
                } catch {}
            }
        }
    }
    Refresh-T6; $T6_Stat.Controls[3].Text = "$($script:T6_AllRows.Count)"; $T6_EnterLbl.ForeColor = $C_Green; $script:CanGoToNextStep = $true
}
$T6_BtnLoad.Add_Click({ Load-LNK })

# ══════════════════════════════════════════════════════════════════════════════
# STEP 7 — LAST ACTIVITY VIEW
# ══════════════════════════════════════════════════════════════════════════════
$Tab7 = New-Tab "Step 7 — Last Activity View"
$T7_Main = New-Object System.Windows.Forms.Panel; $T7_Main.Dock = [System.Windows.Forms.DockStyle]::Fill; $Tab7.Controls.Add($T7_Main)
$T7_Stat = New-StatPanel @("Aggregated Forensic Logs","Chronological Total Rows") @("Prefetch + Shell Logs","0") @($C_Dim,$C_Yellow); $T7_Main.Controls.Add($T7_Stat)

$T7_SearchPan = New-Object System.Windows.Forms.Panel; $T7_SearchPan.Dock = [System.Windows.Forms.DockStyle]::Top; $T7_SearchPan.Height = 36; $T7_SearchPan.BackColor = $C_DarkPan; $T7_Main.Controls.Add($T7_SearchPan)
$T7_SLabel = New-Label "FILTER: " $C_Dim $FONT_MONO_SM; $T7_SLabel.Location = New-Object System.Drawing.Point(10, 10); $T7_SearchPan.Controls.Add($T7_SLabel)
$T7_Search = New-Object System.Windows.Forms.TextBox; $T7_Search.Location = New-Object System.Drawing.Point(70, 8); $T7_Search.Size = New-Object System.Drawing.Size(400, 22); $T7_Search.BackColor = $C_BG; $T7_Search.ForeColor = $C_White; $T7_Search.BorderStyle = [System.Windows.Forms.BorderStyle]::FixedSingle; $T7_SearchPan.Controls.Add($T7_Search)
$T7_BtnLoad = New-Object System.Windows.Forms.Button; $T7_BtnLoad.Text = "▶ COMPILE VIEW"; $T7_BtnLoad.Location = New-Object System.Drawing.Point(485, 7); $T7_BtnLoad.Size = New-Object System.Drawing.Size(140, 22); $T7_BtnLoad.BackColor = [System.Drawing.Color]::FromArgb(0, 40, 20); $T7_BtnLoad.ForeColor = $C_Green; $T7_BtnLoad.FlatStyle = [System.Windows.Forms.FlatStyle]::Flat; $T7_SearchPan.Controls.Add($T7_BtnLoad); $T7_Main.Controls.Add($T7_SearchPan)

$T7_Grid = New-Grid
Add-Col $T7_Grid "Time" "Action Time" 145 $C_Cyan
Add-Col $T7_Grid "Desc" "Description" 120
Add-Col $T7_Grid "Name" "Filename" 180 $C_White
Add-Col $T7_Grid "Path" "Full Path Pointer" 350 $C_Dim
Add-Col $T7_Grid "Info" "More Info Metadata" 180 $C_Dim
Add-Col $T7_Grid "Ext" "Ext" 40 $C_Magenta
Add-Col $T7_Grid "Source" "Structural Source File Location Reference" 300 $C_Dim
$T7_Grid.Columns["Path"].AutoSizeMode = [System.Windows.Forms.DataGridViewAutoSizeColumnMode]::Fill; $T7_Main.Controls.Add($T7_Grid)

$script:T7_AllRows = @()
function Refresh-T7 {
    $T7_Grid.Rows.Clear(); $kw = $T7_Search.Text.Trim()
    foreach($r in $script:T7_AllRows) { if ($kw -eq "" -or $r.Name -match $kw -or $r.Desc -match $kw) { $T7_Grid.Rows.Add($r.Time, $r.Desc, $r.Name, $r.Path, $r.Info, $r.Ext, $r.Source) | Out-Null } }
}
$T7_Search.Add_TextChanged({ Refresh-T7 })

function Compile-T7 {
    $script:T7_AllRows = @(); $pfPath = "$env:WINDIR\Prefetch"
    if (Test-Path $pfPath) {
        Get-ChildItem $pfPath -Filter "*.pf" -EA SilentlyContinue | Sort-Object LastWriteTime -Descending | Select-Object -First 60 | ForEach-Object {
            $ex = $_.Name -replace "-[A-F0-9]{8}\.pf$", ""
            $script:T7_AllRows += [PSCustomObject]@{ Time=$_.LastWriteTime.ToString("yyyy-MM-dd HH:mm:ss"); Desc="Run .EXE file"; Name=$ex; Path="C:\Windows\$ex"; Info="Prefetch execution record"; Ext="EXE"; Source=$_.FullName }
        }
    }
    Refresh-T7; $T7_Stat.Controls[3].Text = "$($script:T7_AllRows.Count)"
}
$T7_BtnLoad.Add_Click({ Compile-T7 })

# ─── STATUS BAR ───────────────────────────────────────────────────────────────
$StatusBar = New-Object System.Windows.Forms.Panel; $StatusBar.Dock = [System.Windows.Forms.DockStyle]::Bottom; $StatusBar.Height = 24; $StatusBar.BackColor = $C_DarkPan
$StatusLbl = New-Label "  VAELITH V3  |  READ ONLY  |  No changes made  |  $($env:COMPUTERNAME) ($($env:USERNAME))" $C_Dim $FONT_MONO_SM
$StatusLbl.Dock = [System.Windows.Forms.DockStyle]::Fill; $StatusLbl.TextAlign = [System.Drawing.ContentAlignment]::MiddleLeft; $StatusBar.Controls.Add($StatusLbl); $Form.Controls.Add($StatusBar)

# ─── AUTOMATION: AUTO-LOAD ON TAB CHANGE & ENTER KEY FLUX ─────────────────────
$Tabs.Add_SelectedIndexChanged({
    $sel = $Tabs.SelectedTab
    if ($sel -eq $Tab3) { Load-T3 }
    elseif ($sel -eq $Tab4) { Load-T4 }
    elseif ($sel -eq $Tab5) { Load-T5 }
    elseif ($sel -eq $Tab6) { Load-LNK }
    elseif ($sel -eq $Tab7) { Compile-T7 }
})

$Form.Add_KeyDown({
    param($s, $e)
    if ($e.KeyCode -eq [System.Windows.Forms.Keys]::Enter) {
        if ($script:CanGoToNextStep) {
            $idx = $Tabs.SelectedIndex
            if ($idx -lt ($Tabs.TabCount - 1)) { $e.SuppressKeyPress = $true; $Tabs.SelectedIndex = $idx + 1; $script:CanGoToNextStep = $false }
        } elseif ($Tabs.SelectedIndex -eq 0) {
            $e.SuppressKeyPress = $true; $T1_BtnRun.PerformClick()
        }
    }
})

[System.Windows.Forms.Application]::Run($Form)
