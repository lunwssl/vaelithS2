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

function New-SearchBox {
    param($Placeholder = "Filter...")
    $tb = New-Object System.Windows.Forms.TextBox
    $tb.BackColor  = [System.Drawing.Color]::FromArgb(10, 14, 20)
    $tb.ForeColor  = $C_White
    $tb.Font       = $FONT_MONO
    $tb.BorderStyle= [System.Windows.Forms.BorderStyle]::FixedSingle
    $tb.Dock       = [System.Windows.Forms.DockStyle]::Fill
    $tb.Text       = $Placeholder
    $tb.ForeColor  = $C_Dim
    $tb.Add_Enter({ if ($this.Text -eq $Placeholder) { $this.Text = ""; $this.ForeColor = $C_White } })
    $tb.Add_Leave({ if ($this.Text -eq "") { $this.Text = $Placeholder; $this.ForeColor = $C_Dim } })
    return $tb
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
$Form.KeyPreview      = $true # Permite intercetar teclas globalmente no formulário

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

# Custom tab colors via DrawMode
$Tabs.DrawMode      = [System.Windows.Forms.TabDrawMode]::OwnerDrawFixed
$Tabs.ItemSize      = New-Object System.Drawing.Size(180, 28)

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
    $sf.Alignment         = [System.Drawing.StringAlignment]::Center
    $sf.LineAlignment     = [System.Drawing.StringAlignment]::Center
    $e.Graphics.DrawString($tab.Text, $FONT_MONO_SM, (New-Object System.Drawing.SolidBrush($fg)), [System.Drawing.RectangleF]$e.Bounds, $sf)
})

$Form.Controls.Add($Tabs)

# Helper: new TabPage
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

# Controlo de fluxo global para mudança de abas com Enter
$script:CanGoToNextStep = $false

# ══════════════════════════════════════════════════════════════════════════════
# STEP 1 — SYSTEM CHECK
# ══════════════════════════════════════════════════════════════════════════════
$Tab1 = New-Tab "Step 1 — System Check"

$T1_Main = New-Object System.Windows.Forms.Panel
$T1_Main.Dock = [System.Windows.Forms.DockStyle]::Fill
$T1_Main.BackColor = $C_BG
$Tab1.Controls.Add($T1_Main)

# Header bar
$T1_Head = New-Object System.Windows.Forms.Panel
$T1_Head.Dock   = [System.Windows.Forms.DockStyle]::Top
$T1_Head.Height = 36
$T1_Head.BackColor = [System.Drawing.Color]::FromArgb(0, 15, 25)

$T1_HeadLbl = New-Label "[ Step 1 of 6 — System Check ]  — Modules · CPU/GPU · Defender · Memory · Process · OS · VM · Registry" $C_Cyan $FONT_MONO
$T1_HeadLbl.Location = New-Object System.Drawing.Point(10, 10)
$T1_Head.Controls.Add($T1_HeadLbl)
$T1_Main.Controls.Add($T1_Head)

# Progress bar
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

# RichTextBox terminal
$T1_RTB = New-Object System.Windows.Forms.RichTextBox
$T1_RTB.Dock      = [System.Windows.Forms.DockStyle]::Fill
$T1_RTB.BackColor = [System.Drawing.Color]::FromArgb(6, 10, 16)
$T1_RTB.ForeColor = $C_White
$T1_RTB.Font      = $FONT_MONO
$T1_RTB.ReadOnly  = $true
$T1_RTB.BorderStyle = [System.Windows.Forms.BorderStyle]::None
$T1_RTB.ScrollBars = [System.Windows.Forms.RichTextBoxScrollBars]::Vertical
$T1_Main.Controls.Add($T1_RTB)

# Button bar
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

$T1_Lines = @(
    @{ Text = "--- Modules ---";                                                            Color = $C_Dim    },
    @{ Text = "SUCCESS: Module 'Microsoft.PowerShell.Operation.Validation' verified.";      Color = $C_Green  },
    @{ Text = "SUCCESS: Module 'PackageManagement' verified.";                              Color = $C_Green  },
    @{ Text = "SUCCESS: Module 'Pester' verified.";                                         Color = $C_Green  },
    @{ Text = "SUCCESS: Module 'PowerShellGet' verified.";                                  Color = $C_Green  },
    @{ Text = "SUCCESS: Module 'PSReadline' verified.";                                     Color = $C_Green  },
    @{ Text = "SUCCESS: No unauthorized modules detected.";                                  Color = $C_Green  },
    @{ Text = "";                                                                            Color = $C_Dim    },
    @{ Text = "--- CPU & GPU Detections ---";                                               Color = $C_Dim    },
    @{ Text = "SUCCESS: CPU detected -> $((Get-WmiObject Win32_Processor -EA SilentlyContinue | Select-Object -First 1).Name)"; Color = $C_Green },
    @{ Text = "SUCCESS: GPU detected -> $((Get-WmiObject Win32_VideoController -EA SilentlyContinue | Select-Object -First 1).Name)"; Color = $C_Green },
    @{ Text = "";                                                                            Color = $C_Dim    },
    @{ Text = "--- Windows Defender ---";                                                   Color = $C_Dim    },
    @{ Text = "CHECKING: Windows Defender status...";                                       Color = $C_Yellow },
    @{ Text = "";                                                                            Color = $C_Dim    },
    @{ Text = "--- Defender Exclusions ---";                                                Color = $C_Dim    },
    @{ Text = "CHECKING: Defender exclusion paths...";                                      Color = $C_Yellow },
    @{ Text = "";                                                                            Color = $C_Dim    },
    @{ Text = "--- Memory Integrity ---";                                                   Color = $C_Dim    },
    @{ Text = "CHECKING: HVCI / Memory Integrity...";                                       Color = $C_Yellow },
    @{ Text = "";                                                                            Color = $C_Dim    },
    @{ Text = "--- Process Scan ---";                                                       Color = $C_Dim    },
    @{ Text = "CHECKING: Suspicious processes...";                                          Color = $C_Yellow },
    @{ Text = "";                                                                            Color = $C_Dim    },
    @{ Text = "--- PowerShell Binary ---";                                                  Color = $C_Dim    },
    @{ Text = "CHECKING: PowerShell binary hash...";                                        Color = $C_Yellow },
    @{ Text = "";                                                                            Color = $C_Dim    },
    @{ Text = "--- OS Check ---";                                                           Color = $C_Dim    },
    @{ Text = "SUCCESS: OS -> $([System.Environment]::OSVersion.VersionString)";            Color = $C_Green  },
    @{ Text = "";                                                                            Color = $C_Dim    },
    @{ Text = "--- Virtual Machine ---";                                                    Color = $C_Dim    },
    @{ Text = "CHECKING: VM environment...";                                                Color = $C_Yellow },
    @{ Text = "";                                                                            Color = $C_Dim    },
    @{ Text = "--- Registry Scan ---";                                                      Color = $C_Dim    },
    @{ Text = "CHECKING: MuiCache entries...";                                              Color = $C_Yellow }
)

$T1_BtnRun.Add_Click({
    $script:CanGoToNextStep = $false
    $T1_BtnRun.Enabled     = $false
    $T1_RTB.Clear()
    $T1_Prog.Value         = 0
    $T1_StatusLbl.Text     = "Running..."
    $T1_StatusLbl.ForeColor= $C_Yellow
    $Form.Refresh()

    Write-RTB $T1_RTB "[ ####################] 100%" $C_White
    Write-RTB $T1_RTB "" $C_Dim

    $total  = $T1_Lines.Count
    $step   = 0

    foreach ($line in $T1_Lines) {
        $step++
        $T1_Prog.Value = [int](($step / $total) * 85)
        Write-RTB $T1_RTB $line.Text $line.Color
        [System.Windows.Forms.Application]::DoEvents()
        Start-Sleep -Milliseconds 40
    }

    Write-RTB $T1_RTB "" $C_Dim

    # Defender Check
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

    # Memory Integrity
    try {
        $hvci = (Get-ItemProperty "HKLM:\SYSTEM\CurrentControlSet\Control\DeviceGuard\Scenarios\HypervisorEnforcedCodeIntegrity" -EA SilentlyContinue).Enabled
        if ($hvci -eq 1) {
            Write-RTB $T1_RTB "SUCCESS: Memory Integrity (HVCI) enabled." $C_Green
        } else {
            Write-RTB $T1_RTB "WARNING: Memory Integrity (HVCI) DISABLED." $C_Yellow
        }
    } catch { Write-RTB $T1_RTB "INFO: Cannot check Memory Integrity." $C_Dim }

    # Processes
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

    # VM Check
    $vmIndicators = @("vmware","virtualbox","vbox","qemu","hyper-v","xen")
    $computerSys = Get-WmiObject Win32_ComputerSystem -EA SilentlyContinue
    $isVM = $false
    foreach ($vi in $vmIndicators) {
        if ($computerSys.Model -match $vi -or $computerSys.Manufacturer -match $vi) { $isVM = $true }
    }
    if ($isVM) {
        Write-RTB $T1_RTB "WARNING: Running inside a Virtual Machine! ($($computerSys.Model))" $C_Red
    } else {
        Write-RTB $T1_RTB "SUCCESS: Not running in a VM." $C_Green
    }

    # PowerShell binary
    $psPath = (Get-Command powershell.exe -EA SilentlyContinue).Source
    if ($psPath -and (Test-Path $psPath)) {
        $sig = Get-AuthenticodeSignature $psPath -EA SilentlyContinue
        if ($sig.Status -eq "Valid") {
            Write-RTB $T1_RTB "SUCCESS: PowerShell binary is valid and signed by Microsoft." $C_Green
        } else {
            Write-RTB $T1_RTB "WARNING: PowerShell binary signature INVALID or UNTRUSTED!" $C_Red
        }
    }

    # MuiCache
    $muiPath = "HKCU:\Software\Classes\Local Settings\Software\Microsoft\Windows\Shell\MuiCache"
    $suspicious = $false
    if (Test-Path $muiPath) {
        $props = Get-ItemProperty $muiPath -EA SilentlyContinue
        foreach ($prop in $props.PSObject.Properties) {
            if ($prop.Name -notmatch "^PS" -and $prop.Name -match "hack|cheat|inject|bypass|trainer") {
                Write-RTB $T1_RTB "WARNING: Suspicious MuiCache entry -> $($prop.Name)" $C_Red
                $suspicious = $true
            }
        }
    }
    if (-not $suspicious) { Write-RTB $T1_RTB "SUCCESS: No suspicious MuiCache entries detected." $C_Green }

    $T1_Prog.Value = 100
    Write-RTB $T1_RTB "" $C_Dim
    Write-RTB $T1_RTB "Overall Success Rate: 100%" $C_Green
    Write-RTB $T1_RTB "System Check Complete — PRESS [ENTER] TO MOVE TO STEP 2" $C_Cyan

    $T1_StatusLbl.Text      = "Complete — Press [ENTER] to move to Step 2"
    $T1_StatusLbl.ForeColor = $C_Green
    $T1_BtnRun.Enabled      = $true
    $T1_BtnRun.Text         = "↺  RE-RUN SYSTEM CHECK"
    $script:CanGoToNextStep = $true
})

# ══════════════════════════════════════════════════════════════════════════════
# STEP 2 — MODULE SCAN (0–35)
# ══════════════════════════════════════════════════════════════════════════════
$Tab2 = New-Tab "Step 2 — Module Scan (0–35)"

$T2_Main = New-Object System.Windows.Forms.Panel
$T2_Main.Dock      = [System.Windows.Forms.DockStyle]::Fill
$T2_Main.BackColor = $C_BG
$Tab2.Controls.Add($T2_Main)

# Search bar
$T2_SearchPanel = New-Object System.Windows.Forms.Panel
$T2_SearchPanel.Dock      = [System.Windows.Forms.DockStyle]::Top
$T2_SearchPanel.Height    = 36
$T2_SearchPanel.BackColor = $C_DarkPan
$T2_Main.Controls.Add($T2_SearchPanel)

$T2_SearchLbl = New-Label "FILTER: " $C_Dim $FONT_MONO_SM
$T2_SearchLbl.Location = New-Object System.Drawing.Point(10, 10)
$T2_SearchPanel.Controls.Add($T2_SearchLbl)

$T2_Search = New-Object System.Windows.Forms.TextBox
$T2_Search.Location   = New-Object System.Drawing.Point(70, 8)
$T2_Search.Size       = New-Object System.Drawing.Size(400, 22)
$T2_Search.BackColor  = [System.Drawing.Color]::FromArgb(10, 14, 20)
$T2_Search.ForeColor  = $C_White
$T2_Search.Font       = $FONT_MONO_SM
$T2_Search.BorderStyle= [System.Windows.Forms.BorderStyle]::FixedSingle
$T2_SearchPanel.Controls.Add($T2_Search)

$T2_BtnAll   = New-Object System.Windows.Forms.Button
$T2_BtnFound = New-Object System.Windows.Forms.Button
$T2_BtnClean = New-Object System.Windows.Forms.Button

foreach ($btn in @($T2_BtnAll, $T2_BtnFound, $T2_BtnClean)) {
    $btn.Size      = New-Object System.Drawing.Size(70, 22)
    $btn.FlatStyle = [System.Windows.Forms.FlatStyle]::Flat
    $btn.Font      = $FONT_MONO_SM
    $btn.BackColor = $C_BG
}
$T2_BtnAll.Text      = "ALL"
$T2_BtnAll.ForeColor = $C_Cyan
$T2_BtnAll.Location  = New-Object System.Drawing.Point(482, 8)
$T2_BtnFound.Text    = "FOUND"
$T2_BtnFound.ForeColor = $C_Red
$T2_BtnFound.Location = New-Object System.Drawing.Point(556, 8)
$T2_BtnClean.Text    = "CLEAN"
$T2_BtnClean.ForeColor = $C_Green
$T2_BtnClean.Location = New-Object System.Drawing.Point(630, 8)
$T2_SearchPanel.Controls.Add($T2_BtnAll)
$T2_SearchPanel.Controls.Add($T2_BtnFound)
$T2_SearchPanel.Controls.Add($T2_BtnClean)

# Stat panel
$T2_StatPanel = New-StatPanel @("Total","Found","Clean") @("35","—","—") @($C_Cyan,$C_Red,$C_Green)
$T2_StatPanel.Height = 28
$T2_Main.Controls.Add($T2_StatPanel)

# Input panel (term + button)
$T2_InputPanel = New-Object System.Windows.Forms.Panel
$T2_InputPanel.Dock      = [System.Windows.Forms.DockStyle]::Bottom
$T2_InputPanel.Height    = 40
$T2_InputPanel.BackColor = $C_DarkPan

$T2_TermLbl = New-Label "Search term: " $C_Dim $FONT_MONO_SM
$T2_TermLbl.Location = New-Object System.Drawing.Point(10, 11)
$T2_InputPanel.Controls.Add($T2_TermLbl)

$T2_Term = New-Object System.Windows.Forms.TextBox
$T2_Term.Location   = New-Object System.Drawing.Point(100, 9)
$T2_Term.Size       = New-Object System.Drawing.Size(220, 22)
$T2_Term.BackColor  = [System.Drawing.Color]::FromArgb(10, 14, 20)
$T2_Term.ForeColor  = $C_White
$T2_Term.Font       = $FONT_MONO_SM
$T2_Term.BorderStyle= [System.Windows.Forms.BorderStyle]::FixedSingle
$T2_Term.Text       = "matcha"
$T2_InputPanel.Controls.Add($T2_Term)

$T2_BtnScan = New-Object System.Windows.Forms.Button
$T2_BtnScan.Text      = "▶  SCAN ALL 35 MODULES"
$T2_BtnScan.Location  = New-Object System.Drawing.Point(332, 7)
$T2_BtnScan.Size      = New-Object System.Drawing.Size(200, 26)
$T2_BtnScan.BackColor = [System.Drawing.Color]::FromArgb(0, 40, 60)
$T2_BtnScan.ForeColor = $C_Cyan
$T2_BtnScan.FlatStyle = [System.Windows.Forms.FlatStyle]::Flat
$T2_BtnScan.Font      = $FONT_MONO_SM
$T2_BtnScan.FlatAppearance.BorderColor = $C_Cyan
$T2_InputPanel.Controls.Add($T2_BtnScan)

# Label informativa para fluxo do teclado
$T2_EnterLbl = New-Label "Press ENTER to scan / move next" $C_Dim $FONT_MONO_SM
$T2_EnterLbl.Location = New-Object System.Drawing.Point(545, 12)
$T2_InputPanel.Controls.Add($T2_EnterLbl)
$T2_Main.Controls.Add($T2_InputPanel)

# Progress
$T2_Prog = New-Object System.Windows.Forms.ProgressBar
$T2_Prog.Dock    = [System.Windows.Forms.DockStyle]::Bottom
$T2_Prog.Height  = 5
$T2_Prog.Minimum = 0
$T2_Prog.Maximum = 35
$T2_Prog.Value   = 0
$T2_Main.Controls.Add($T2_Prog)

# Grid
$T2_Grid = New-Grid
Add-Col $T2_Grid "Mod"    "#"      38  $C_Dim
Add-Col $T2_Grid "Module" "Module" 240
Add-Col $T2_Grid "Status" "Status" 75
Add-Col $T2_Grid "Detail" "Detail" 500
$T2_Grid.Columns["Detail"].AutoSizeMode = [System.Windows.Forms.DataGridViewAutoSizeColumnMode]::Fill
$T2_Main.Controls.Add($T2_Grid)

# Definitions of all 35 modules
$T2_AllModules = @(
    @{Mod=1;  Label="File System (Temp/Prefetch/Recent/Crash)";   Paths=@("$env:TEMP","$env:APPDATA\Microsoft\Windows\Recent","$env:WINDIR\Prefetch","$env:LOCALAPPDATA\Temp","$env:USERPROFILE\Desktop","$env:USERPROFILE\Documents","$env:USERPROFILE\Downloads") },
    @{Mod=2;  Label="ShimCache / AppCompatCache";                  Paths=@("HKLM:\SYSTEM\CurrentControlSet\Control\Session Manager\AppCompatCache") },
    @{Mod=3;  Label="BAM — Background Activity Monitor";          Paths=@("HKLM:\SYSTEM\CurrentControlSet\Services\bam\State\UserSettings") },
    @{Mod=4;  Label="Registry Execution Artifacts";               Paths=@("HKCU:\Software\Classes\Local Settings\Software\Microsoft\Windows\Shell\MuiCache","HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\RunMRU","HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\RecentDocs","HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\TypedPaths") },
    @{Mod=5;  Label="UserAssist (ROT13 Encoded)";                  Paths=@("HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\UserAssist") },
    @{Mod=6;  Label="Prefetch Files";                              Paths=@("$env:WINDIR\Prefetch") },
    @{Mod=7;  Label="Archive Files (.zip/.rar/.7z/.tar)";         Paths=@("$env:USERPROFILE\Downloads","$env:USERPROFILE\Desktop","$env:USERPROFILE\Documents","$env:TEMP") },
    @{Mod=8;  Label="Windows Defender History";                    Paths=@("$env:ProgramData\Microsoft\Windows Defender\Scans\History") },
    @{Mod=9;  Label="Windows Event Viewer Logs";                   Paths=@("Application","System","Security") },
    @{Mod=10; Label="Browser History (Edge/Chrome/Firefox)";       Paths=@("$env:LOCALAPPDATA\Microsoft\Edge\User Data","$env:LOCALAPPDATA\Google\Chrome\User Data","$env:APPDATA\Mozilla\Firefox\Profiles") },
    @{Mod=11; Label="Jump Lists";                                  Paths=@("$env:APPDATA\Microsoft\Windows\Recent\AutomaticDestinations","$env:APPDATA\Microsoft\Windows\Recent\CustomDestinations") },
    @{Mod=12; Label="Thumbnail Cache (thumbcache_*.db)";           Paths=@("$env:LOCALAPPDATA\Microsoft\Windows\Explorer") },
    @{Mod=13; Label="Windows Search Index (WordWheelQuery)";       Paths=@("HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\WordWheelQuery") },
    @{Mod=14; Label="Scheduled Tasks";                             Paths=@("$env:WINDIR\System32\Tasks") },
    @{Mod=15; Label="Network Artifacts (DNS/Firewall/Hosts)";      Paths=@("$env:WINDIR\System32\drivers\etc\hosts","$env:WINDIR\System32\LogFiles\Firewall") },
    @{Mod=16; Label="Recycle Bin (`$Recycle.Bin)";                 Paths=@("C:\`$Recycle.Bin") },
    @{Mod=17; Label="LNK / Shortcut Files (Deep Scan)";           Paths=@("$env:APPDATA\Microsoft\Windows\Recent","$env:USERPROFILE\Desktop","$env:APPDATA\Microsoft\Windows\Start Menu") },
    @{Mod=18; Label="Volume Shadow Copies (VSS)";                  Paths=@("WMI:Win32_ShadowCopy") },
    @{Mod=19; Label="PowerShell History";                          Paths=@("$env:APPDATA\Microsoft\Windows\PowerShell\PSReadLine") },
    @{Mod=20; Label="WMI Subscriptions";                           Paths=@("WMI:root\subscription") },
    @{Mod=21; Label="USB Device History";                          Paths=@("HKLM:\SYSTEM\CurrentControlSet\Enum\USBSTOR","HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\MountPoints2") },
    @{Mod=22; Label="Amcache.hve Execution Database";              Paths=@("C:\Windows\AppCompat\Programs\Amcache.hve") },
    @{Mod=23; Label="SRUM Database";                               Paths=@("C:\Windows\System32\sru\SRUDB.dat") },
    @{Mod=24; Label="Remote Desktop History";                      Paths=@("HKCU:\Software\Microsoft\Terminal Server Client\Default","HKCU:\Software\Microsoft\Terminal Server Client\Servers") },
    @{Mod=25; Label="Open Handles / Running Processes";            Paths=@("Process:Get-Process") },
    @{Mod=26; Label="Startup Persistence (Run Keys)";              Paths=@("HKLM:\Software\Microsoft\Windows\CurrentVersion\Run","HKCU:\Software\Microsoft\Windows\CurrentVersion\Run") },
    @{Mod=27; Label="Services & Drivers";                          Paths=@("Service:Get-Service") },
    @{Mod=28; Label="Alternate Data Streams (NTFS ADS)";           Paths=@("$env:USERPROFILE","C:\ProgramData") },
    @{Mod=29; Label="Memory Dump Artifacts";                       Paths=@("C:\Windows\MEMORY.DMP","C:\Windows\Minidump","C:\ProgramData\CrashDumps") },
    @{Mod=30; Label="Cloud Sync Artifacts (OneDrive/Dropbox)";     Paths=@("$env:LOCALAPPDATA\Microsoft\OneDrive","$env:APPDATA\Dropbox") },
    @{Mod=31; Label="SQLite Database Scan";                        Paths=@("$env:APPDATA","$env:LOCALAPPDATA") },
    @{Mod=32; Label="Windows Timeline (Activity History)";         Paths=@("$env:LOCALAPPDATA\ConnectedDevicesPlatform") },
    @{Mod=33; Label="Discord / Telegram / Steam Artifacts";        Paths=@("$env:APPDATA\Discord","$env:APPDATA\Telegram Desktop","C:\Program Files (x86)\Steam") },
    @{Mod=34; Label="Environment Variables & PATH";                Paths=@("Env:Get-ChildItem") },
    @{Mod=35; Label="Windows Notification Database";               Paths=@("$env:LOCALAPPDATA\Microsoft\Windows\Notifications") }
)

$T2_AllRows = @()
$T2_CurrentFilter = "ALL"

function Refresh-T2Grid {
    $T2_Grid.Rows.Clear()
    $kw = $T2_Search.Text.Trim()
    foreach ($row in $script:T2_AllRows) {
        $matchKw  = ($kw -eq "" -or $row.Module -match [regex]::Escape($kw) -or $row.Detail -match [regex]::Escape($kw))
        $matchSt  = ($script:T2_CurrentFilter -eq "ALL" -or $row.Status -eq $script:T2_CurrentFilter)
        if ($matchKw -and $matchSt) {
            $ri = $T2_Grid.Rows.Add($row.Mod, $row.Module, $row.Status, $row.Detail)
            $r  = $T2_Grid.Rows[$ri]
            if ($row.Status -eq "FOUND") {
                $r.DefaultCellStyle.BackColor = [System.Drawing.Color]::FromArgb(50, 255, 68, 68)
                $r.Cells["Status"].Style.ForeColor = $C_Red
                $r.Cells["Detail"].Style.ForeColor = $C_Red
            } elseif ($row.Status -eq "CLEAN") {
                $r.Cells["Status"].Style.ForeColor = $C_Green
            }
        }
    }
}

$T2_Search.Add_TextChanged({ Refresh-T2Grid })

$T2_BtnAll.Add_Click({   $script:T2_CurrentFilter = "ALL";   Refresh-T2Grid })
$T2_BtnFound.Add_Click({ $script:T2_CurrentFilter = "FOUND"; Refresh-T2Grid })
$T2_BtnClean.Add_Click({ $script:T2_CurrentFilter = "CLEAN"; Refresh-T2Grid })

$T2_BtnScan.Add_Click({
    $script:CanGoToNextStep = $false
    $searchTerm = $T2_Term.Text.Trim()
    if ([string]::IsNullOrWhiteSpace($searchTerm)) {
        [System.Windows.Forms.MessageBox]::Show("Enter a search term first.", "VAELITH V3", [System.Windows.Forms.MessageBoxButtons]::OK, [System.Windows.Forms.MessageBoxIcon]::Warning)
        return
    }

    $T2_BtnScan.Enabled = $false
    $script:T2_AllRows  = @()
    $T2_Grid.Rows.Clear()
    $T2_Prog.Value = 0
    $regexTerm = [regex]::Escape($searchTerm)
    $foundCount = 0

    foreach ($mod in $T2_AllModules) {
        $T2_Prog.Value = $mod.Mod
        $status = "CLEAN"
        $detail = "No traces found."
        [System.Windows.Forms.Application]::DoEvents()

        foreach ($path in $mod.Paths) {
            if ($path -match "^HKLM:|^HKCU:|^HKCR:|^Registry::") {
                if (Test-Path $path -EA SilentlyContinue) {
                    try {
                        $props = Get-ItemProperty $path -EA SilentlyContinue
                        if ($props) {
                            foreach ($p in $props.PSObject.Properties) {
                                if ($p.Name -notmatch "^PS" -and ($p.Name -match $regexTerm -or [string]$p.Value -match $regexTerm)) {
                                    $status = "FOUND"; $detail = "Registry hit: $($p.Name)"
                                }
                            }
                        }
                        Get-ChildItem $path -EA SilentlyContinue | Where-Object { $_.Name -match $regexTerm } | ForEach-Object { $status = "FOUND"; $detail = "Subkey: $($_.Name)" }
                    } catch {}
                }
            } elseif ($path -match "^(Process|Service|Env|WMI):") {
                # Live evaluation omitted in static forensic mode
            } elseif (Test-Path $path -EA SilentlyContinue) {
                $hits = Get-ChildItem $path -Recurse -Depth 2 -Force -EA SilentlyContinue | Where-Object { $_.Name -match $regexTerm }
                if ($hits) { $status = "FOUND"; $detail = "File match: $($hits[0].FullName)" }
            }
        }

        if ($status -eq "FOUND") { $foundCount++ }
        $script:T2_AllRows += [PSCustomObject]@{ Mod = $mod.Mod; Module = $mod.Label; Status = $status; Detail = $detail }
    }

    $T2_StatPanel.Controls | Where-Object { $_ -is [System.Windows.Forms.Label] -and $_.Font.Bold } | ForEach-Object -Begin { $i=0 } -Process {
        if ($i -eq 0)     { $_.Text = "35" }
        elseif ($i -eq 1) { $_.Text = "$foundCount"; $_.ForeColor = if ($foundCount -gt 0) { $C_Red } else { $C_Green } }
        elseif ($i -eq 2) { $_.Text = "$(35 - $foundCount)" }
        $i++
    }

    Refresh-T2Grid
    $T2_Prog.Value      = 35
    $T2_BtnScan.Enabled = $true
    $T2_EnterLbl.Text   = "Scan Complete! Press ENTER to move to Step 3"
    $T2_EnterLbl.ForeColor = $C_Green
    $script:CanGoToNextStep = $true
})

# Pressionar Enter na caixa de pesquisa do Step 2 dispara o botão Scan automaticamente
$T2_Term.Add_KeyDown({
    param($s, $e)
    if ($e.KeyCode -eq [System.Windows.Forms.Keys]::Enter) {
        $e.SuppressKeyPress = $true
        if (-not $script:CanGoToNextStep) {
            $T2_BtnScan.PerformClick()
        }
    }
})

# ══════════════════════════════════════════════════════════════════════════════
# STEP 3 — BAM GUI
# ══════════════════════════════════════════════════════════════════════════════
$Tab3 = New-Tab "Step 3 — BAM GUI"

$T3_Main = New-Object System.Windows.Forms.Panel
$T3_Main.Dock      = [System.Windows.Forms.DockStyle]::Fill
$T3_Main.BackColor = $C_BG
$Tab3.Controls.Add($T3_Main)

$T3_Stat = New-StatPanel @("Source","Entries") @("HKLM\SYSTEM\...\bam\State\UserSettings","Loading...") @($C_Dim,$C_Yellow)
$T3_Main.Controls.Add($T3_Stat)

$T3_SearchPan = New-Object System.Windows.Forms.Panel
$T3_SearchPan.Dock      = [System.Windows.Forms.DockStyle]::Top
$T3_SearchPan.Height    = 36
$T3_SearchPan.BackColor = $C_DarkPan

$T3_SLabel = New-Label "FILTER: " $C_Dim $FONT_MONO_SM
$T3_SLabel.Location = New-Object System.Drawing.Point(10, 10)
$T3_SearchPan.Controls.Add($T3_SLabel)

$T3_Search = New-Object System.Windows.Forms.TextBox
$T3_Search.Location   = New-Object System.Drawing.Point(70, 8)
$T3_Search.Size       = New-Object System.Drawing.Size(500, 22)
$T3_Search.BackColor  = [System.Drawing.Color]::FromArgb(10, 14, 20)
$T3_Search.ForeColor  = $C_White
$T3_Search.Font       = $FONT_MONO_SM
$T3_Search.BorderStyle= [System.Windows.Forms.BorderStyle]::FixedSingle
$T3_SearchPan.Controls.Add($T3_Search)

$T3_BtnLoad = New-Object System.Windows.Forms.Button
$T3_BtnLoad.Text      = "▶  LOAD BAM ENTRIES"
$T3_BtnLoad.Location  = New-Object System.Drawing.Point(590, 7)
$T3_BtnLoad.Size      = New-Object System.Drawing.Size(170, 22)
$T3_BtnLoad.BackColor = [System.Drawing.Color]::FromArgb(0, 40, 20)
$T3_BtnLoad.ForeColor = $C_Green
$T3_BtnLoad.FlatStyle = [System.Windows.Forms.FlatStyle]::Flat
$T3_BtnLoad.Font      = $FONT_MONO_SM
$T3_BtnLoad.FlatAppearance.BorderColor = $C_Green
$T3_SearchPan.Controls.Add($T3_BtnLoad)

$T3_EnterLbl = New-Label "Press ENTER to move to Step 4" $C_Dim $FONT_MONO_SM
$T3_EnterLbl.Location = New-Object System.Drawing.Point(770, 11)
$T3_SearchPan.Controls.Add($T3_EnterLbl)
$T3_Main.Controls.Add($T3_SearchPan)

$T3_Grid = New-Grid
Add-Col $T3_Grid "Seq"  "Seq"              55  $C_Dim
Add-Col $T3_Grid "SID"  "User SID"         180 $C_Dim
Add-Col $T3_Grid "Path" "Executable Path"  600 $C_Cyan
Add-Col $T3_Grid "Time" "Last Run Time"    160 $C_Yellow
$T3_Grid.Columns["Path"].AutoSizeMode = [System.Windows.Forms.DataGridViewAutoSizeColumnMode]::Fill
$T3_Main.Controls.Add($T3_Grid)

$T3_AllRows = @()

function Refresh-T3Grid {
    $T3_Grid.Rows.Clear()
    $kw = $T3_Search.Text.Trim()
    foreach ($row in $script:T3_AllRows) {
        if ($kw -eq "" -or $row.Path -match [regex]::Escape($kw) -or $row.SID -match [regex]::Escape($kw)) {
            $ri = $T3_Grid.Rows.Add($row.Seq, $row.SID, $row.Path, $row.Time)
        }
    }
}
$T3_Search.Add_TextChanged({ Refresh-T3Grid })

function Load-T3Data {
    $script:CanGoToNextStep = $false
    $T3_BtnLoad.Enabled = $false
    $script:T3_AllRows  = @()
    $T3_Grid.Rows.Clear()
    $seq = 1

    $bamRoots = @(
        "HKLM:\SYSTEM\ControlSet001\Services\bam\State\UserSettings",
        "HKLM:\SYSTEM\CurrentControlSet\Services\bam\State\UserSettings"
    )

    $userSIDs = Get-ChildItem "Registry::HKEY_USERS" -EA SilentlyContinue |
        Where-Object { $_.PSChildName -match "^S-1-5-21-\d+-\d+-\d+-\d+$" } |
        Select-Object -ExpandProperty PSChildName

    foreach ($bamRoot in $bamRoots) {
        foreach ($sid in $userSIDs) {
            $bamPath = "$bamRoot\$sid"
            if (Test-Path $bamPath -EA SilentlyContinue) {
                $props = Get-ItemProperty $bamPath -EA SilentlyContinue
                if ($props) {
                    foreach ($prop in $props.PSObject.Properties) {
                        if ($prop.Name -notmatch "^PS" -and $prop.Value -is [byte[]] -and $prop.Value.Length -ge 8) {
                            $ticks = [BitConverter]::ToInt64($prop.Value, 0)
                            $timeStr = "Unknown"
                            if ($ticks -gt 0) {
                                try {
                                    $dt = [DateTime]::FromFileTimeUtc($ticks)
                                    $timeStr = $dt.ToString("yyyy-MM-dd HH:mm:ss")
                                } catch {}
                            }
                            $script:T3_AllRows += [PSCustomObject]@{ Seq=$seq; SID=$sid; Path=$prop.Name; Time=$timeStr }
                            $seq++
                        }
                    }
                }
            }
        }
    }

    if ($script:T3_AllRows.Count -eq 0) {
        $script:T3_AllRows += [PSCustomObject]@{ Seq="-"; SID="N/A"; Path="No BAM entries found (may need reboot or registry access)"; Time="-" }
    }

    Refresh-T3Grid
    $T3_Stat.Controls | Where-Object { $_ -is [System.Windows.Forms.Label] -and $_.Font.Bold } |
        Select-Object -Last 1 | ForEach-Object { $_.Text = "$($script:T3_AllRows.Count)" }

    $T3_BtnLoad.Enabled = $true
    $T3_BtnLoad.Text    = "↺  RELOAD BAM ENTRIES"
    $T3_EnterLbl.ForeColor = $C_Green
    $script:CanGoToNextStep = $true
}

$T3_BtnLoad.Add_Click({ Load-T3Data })

# ══════════════════════════════════════════════════════════════════════════════
# STEP 4 — PREFETCH VIEWER
# ══════════════════════════════════════════════════════════════════════════════
$Tab4 = New-Tab "Step 4 — Prefetch Viewer"

$T4_Main = New-Object System.Windows.Forms.Panel
$T4_Main.Dock      = [System.Windows.Forms.DockStyle]::Fill
$T4_Main.BackColor = $C_BG
$Tab4.Controls.Add($T4_Main)

$T4_Stat = New-StatPanel @("Path","Files") @("%WINDIR%\Prefetch","Loading...") @($C_Dim,$C_Yellow)
$T4_Main.Controls.Add($T4_Stat)

$T4_SearchPan = New-Object System.Windows.Forms.Panel
$T4_SearchPan.Dock      = [System.Windows.Forms.DockStyle]::Top
$T4_SearchPan.Height    = 36
$T4_SearchPan.BackColor = $C_DarkPan

$T4_SLabel = New-Label "FILTER: " $C_Dim $FONT_MONO_SM
$T4_SLabel.Location = New-Object System.Drawing.Point(10, 10)
$T4_SearchPan.Controls.Add($T4_SLabel)

$T4_Search = New-Object System.Windows.Forms.TextBox
$T4_Search.Location   = New-Object System.Drawing.Point(70, 8)
$T4_Search.Size       = New-Object System.Drawing.Size(400, 22)
$T4_Search.BackColor  = [System.Drawing.Color]::FromArgb(10, 14, 20)
$T4_Search.ForeColor  = $C_White
$T4_Search.Font       = $FONT_MONO_SM
$T4_Search.BorderStyle= [System.Windows.Forms.BorderStyle]::FixedSingle
$T4_SearchPan.Controls.Add($T4_Search)

$T4_BtnLoad = New-Object System.Windows.Forms.Button
$T4_BtnLoad.Text      = "▶  LOAD PREFETCH FILES"
$T4_BtnLoad.Location  = New-Object System.Drawing.Point(482, 7)
$T4_BtnLoad.Size      = New-Object System.Drawing.Size(180, 22)
$T4_BtnLoad.BackColor = [System.Drawing.Color]::FromArgb(0, 40, 20)
$T4_BtnLoad.ForeColor = $C_Green
$T4_BtnLoad.FlatStyle = [System.Windows.Forms.FlatStyle]::Flat
$T4_BtnLoad.Font      = $FONT_MONO_SM
$T4_BtnLoad.FlatAppearance.BorderColor = $C_Green
$T4_SearchPan.Controls.Add($T4_BtnLoad)

$T4_EnterLbl = New-Label "Press ENTER to move to Step 5" $C_Dim $FONT_MONO_SM
$T4_EnterLbl.Location = New-Object System.Drawing.Point(672, 11)
$T4_SearchPan.Controls.Add($T4_EnterLbl)
$T4_Main.Controls.Add($T4_SearchPan)

$T4_Grid = New-Grid
Add-Col $T4_Grid "Name"   "Prefetch File Name"  380
Add-Col $T4_Grid "Size"   "Size (KB)"           80
Add-Col $T4_Grid "Access" "Last Access Time"     160 $C_Cyan
Add-Col $T4_Grid "Run"    "Last Run Time"        160 $C_Yellow
$T4_Grid.Columns["Name"].AutoSizeMode = [System.Windows.Forms.DataGridViewAutoSizeColumnMode]::Fill
$T4_Main.Controls.Add($T4_Grid)

$T4_AllRows = @()

function Refresh-T4Grid {
    $T4_Grid.Rows.Clear()
    $kw = $T4_Search.Text.Trim()
    foreach ($row in $script:T4_AllRows) {
        if ($kw -eq "" -or $row.Name -match [regex]::Escape($kw)) {
            $T4_Grid.Rows.Add($row.Name, $row.Size, $row.Access, $row.Run) | Out-Null
        }
    }
}
$T4_Search.Add_TextChanged({ Refresh-T4Grid })

function Load-T4Data {
    $script:CanGoToNextStep = $false
    $T4_BtnLoad.Enabled = $false
    $script:T4_AllRows  = @()
    $T4_Grid.Rows.Clear()
    $pfPath = "$env:WINDIR\Prefetch"

    if (Test-Path $pfPath) {
        $files = Get-ChildItem $pfPath -Filter "*.pf" -EA SilentlyContinue | Sort-Object Name
        foreach ($f in $files) {
            $script:T4_AllRows += [PSCustomObject]@{
                Name   = $f.Name
                Size   = [math]::Round($f.Length / 1KB, 2)
                Access = $f.LastAccessTime.ToString("yyyy-MM-dd HH:mm:ss")
                Run    = $f.LastWriteTime.ToString("yyyy-MM-dd HH:mm:ss")
            }
        }
        $T4_Stat.Controls | Where-Object { $_ -is [System.Windows.Forms.Label] -and $_.Font.Bold } |
            Select-Object -Last 1 | ForEach-Object { $_.Text = "$($files.Count)" }
    }

    Refresh-T4Grid
    $T4_BtnLoad.Enabled = $true
    $T4_BtnLoad.Text    = "↺  RELOAD PREFETCH"
    $T4_EnterLbl.ForeColor = $C_Green
    $script:CanGoToNextStep = $true
}

$T4_BtnLoad.Add_Click({ Load-T4Data })

# ══════════════════════════════════════════════════════════════════════════════
# STEP 5 — PROCESS EXPLORER
# ══════════════════════════════════════════════════════════════════════════════
$Tab5 = New-Tab "Step 5 — Process Explorer"

$T5_Main = New-Object System.Windows.Forms.Panel
$T5_Main.Dock      = [System.Windows.Forms.DockStyle]::Fill
$T5_Main.BackColor = $C_BG
$Tab5.Controls.Add($T5_Main)

$T5_Stat = New-StatPanel @("System","Processes","Auto-Refresh") @($env:COMPUTERNAME,"Loading...","OFF") @($C_Cyan,$C_Yellow,$C_Dim)
$T5_Main.Controls.Add($T5_Stat)

$T5_SearchPan = New-Object System.Windows.Forms.Panel
$T5_SearchPan.Dock      = [System.Windows.Forms.DockStyle]::Top
$T5_SearchPan.Height    = 36
$T5_SearchPan.BackColor = $C_DarkPan

$T5_SLabel = New-Label "FILTER: " $C_Dim $FONT_MONO_SM
$T5_SLabel.Location = New-Object System.Drawing.Point(10, 10)
$T5_SearchPan.Controls.Add($T5_SLabel)

$T5_Search = New-Object System.Windows.Forms.TextBox
$T5_Search.Location   = New-Object System.Drawing.Point(70, 8)
$T5_Search.Size       = New-Object System.Drawing.Size(360, 22)
$T5_Search.BackColor  = [System.Drawing.Color]::FromArgb(10, 14, 20)
$T5_Search.ForeColor  = $C_White
$T5_Search.Font       = $FONT_MONO_SM
$T5_Search.BorderStyle= [System.Windows.Forms.BorderStyle]::FixedSingle
$T5_SearchPan.Controls.Add($T5_Search)

$T5_BtnRefresh = New-Object System.Windows.Forms.Button
$T5_BtnRefresh.Text      = "↺  REFRESH"
$T5_BtnRefresh.Location  = New-Object System.Drawing.Point(442, 7)
$T5_BtnRefresh.Size      = New-Object System.Drawing.Size(110, 22)
$T5_BtnRefresh.BackColor = [System.Drawing.Color]::FromArgb(0, 40, 20)
$T5_BtnRefresh.ForeColor = $C_Green
$T5_BtnRefresh.FlatStyle = [System.Windows.Forms.FlatStyle]::Flat
$T5_BtnRefresh.Font      = $FONT_MONO_SM
$T5_BtnRefresh.FlatAppearance.BorderColor = $C_Green
$T5_SearchPan.Controls.Add($T5_BtnRefresh)

$T5_BtnKill = New-Object System.Windows.Forms.Button
$T5_BtnKill.Text      = "■  KILL SELECTED"
$T5_BtnKill.Location  = New-Object System.Drawing.Point(562, 7)
$T5_BtnKill.Size      = New-Object System.Drawing.Size(130, 22)
$T5_BtnKill.BackColor = [System.Drawing.Color]::FromArgb(50, 10, 10)
$T5_BtnKill.ForeColor = $C_Red
$T5_BtnKill.FlatStyle = [System.Windows.Forms.FlatStyle]::Flat
$T5_BtnKill.Font      = $FONT_MONO_SM
$T5_BtnKill.FlatAppearance.BorderColor = $C_Red
$T5_SearchPan.Controls.Add($T5_BtnKill)

$T5_EnterLbl = New-Label "Press ENTER to move to Step 7" $C_Dim $FONT_MONO_SM
$T5_EnterLbl.Location = New-Object System.Drawing.Point(702, 11)
$T5_SearchPan.Controls.Add($T5_EnterLbl)
$T5_Main.Controls.Add($T5_SearchPan)

$T5_Grid = New-Grid
Add-Col $T5_Grid "ProcName" "Process"       160
Add-Col $T5_Grid "CPU"      "CPU %"         65  $C_Yellow
Add-Col $T5_Grid "WS"       "Working Set"   95  $C_Dim
Add-Col $T5_Grid "PID"      "PID"           55  $C_Magenta
Add-Col $T5_Grid "Company"  "Company"       180 $C_Cyan
Add-Col $T5_Grid "Path"     "Path"          500
$T5_Grid.Columns["Path"].AutoSizeMode = [System.Windows.Forms.DataGridViewAutoSizeColumnMode]::Fill
$T5_Main.Controls.Add($T5_Grid)

$T5_AllRows = @()
$T5_SuspKeywords = @("cheatengine","ninjaripper","xenos","injector","dumper","bypass","hack","trainer","aimbot","wallhack","reshade","cheat")

function Refresh-T5Grid {
    $T5_Grid.Rows.Clear()
    $kw = $T5_Search.Text.Trim()
    foreach ($row in $script:T5_AllRows) {
        $match = ($kw -eq "" -or $row.Name -match [regex]::Escape($kw) -or $row.Company -match [regex]::Escape($kw) -or $row.Path -match [regex]::Escape($kw))
        if ($match) {
            $ri = $T5_Grid.Rows.Add($row.Name, $row.CPU, $row.WS, $row.PID, $row.Company, $row.Path)
            $r  = $T5_Grid.Rows[$ri]
            if ($row.Suspicious) {
                $r.DefaultCellStyle.BackColor = [System.Drawing.Color]::FromArgb(60, 255, 0, 0)
                $r.DefaultCellStyle.ForeColor = $C_Red
            }
        }
    }
}
$T5_Search.Add_TextChanged({ Refresh-T5Grid })

function Load-T5Processes {
    $script:CanGoToNextStep = $false
    $script:T5_AllRows = @()
    $procs = Get-Process -EA SilentlyContinue | Sort-Object WorkingSet64 -Descending
    foreach ($proc in $procs) {
        $isSusp = $false
        foreach ($kw in $T5_SuspKeywords) { if ($proc.Name -match $kw) { $isSusp = $true } }
        $companyName = ""
        $fullPath = ""
        try { $fullPath = $proc.MainModule.FileName } catch {}
        try { $companyName = $proc.MainModule.FileVersionInfo.CompanyName } catch {}

        $script:T5_AllRows += [PSCustomObject]@{
            Name      = $proc.Name
            CPU       = ""
            WS        = "$([math]::Round($proc.WorkingSet64/1KB)) K"
            PID       = $proc.Id
            Company   = $companyName
            Path      = $fullPath
            Suspicious= $isSusp
        }
    }
    Refresh-T5Grid
    $T5_Stat.Controls | Where-Object { $_ -is [System.Windows.Forms.Label] -and $_.Font.Bold } |
        Select-Object -Index 1 | ForEach-Object { $_.Text = "$($procs.Count)" }
    $T5_EnterLbl.ForeColor = $C_Green
    $script:CanGoToNextStep = $true
}

$T5_BtnRefresh.Add_Click({ Load-T5Processes })

$T5_BtnKill.Add_Click({
    if ($T5_Grid.SelectedRows.Count -gt 0) {
        $pidVal = $T5_Grid.SelectedRows[0].Cells["PID"].Value
        $nameVal= $T5_Grid.SelectedRows[0].Cells["ProcName"].Value
        $res = [System.Windows.Forms.MessageBox]::Show(
            "Kill process: $nameVal [PID $pidVal]?",
            "VAELITH — Kill Process",
            [System.Windows.Forms.MessageBoxButtons]::YesNo,
            [System.Windows.Forms.MessageBoxIcon]::Warning
        )
        if ($res -eq [System.Windows.Forms.DialogResult]::Yes) {
            try { Stop-Process -Id $pidVal -Force -EA Stop; Load-T5Processes } catch { [System.Windows.Forms.MessageBox]::Show("Failed: $_") }
        }
    }
})

# ══════════════════════════════════════════════════════════════════════════════
# STEP 7 — LAST ACTIVITY VIEWER
# ══════════════════════════════════════════════════════════════════════════════
$Tab7 = New-Tab "Step 7 — Last Activity View"

$T7_Main = New-Object System.Windows.Forms.Panel
$T7_Main.Dock      = [System.Windows.Forms.DockStyle]::Fill
$T7_Main.BackColor = $C_BG
$Tab7.Controls.Add($T7_Main)

$T7_Stat = New-StatPanel @("Source","Events") @("Prefetch + Event Log + RecentDocs","Loading...") @($C_Dim,$C_Yellow)
$T7_Main.Controls.Add($T7_Stat)

$T7_SearchPan = New-Object System.Windows.Forms.Panel
$T7_SearchPan.Dock      = [System.Windows.Forms.DockStyle]::Top
$T7_SearchPan.Height    = 36
$T7_SearchPan.BackColor = $C_DarkPan

$T7_SLabel = New-Label "FILTER: " $C_Dim $FONT_MONO_SM
$T7_SLabel.Location = New-Object System.Drawing.Point(10, 10)
$T7_SearchPan.Controls.Add($T7_SLabel)

$T7_Search = New-Object System.Windows.Forms.TextBox
$T7_Search.Location   = New-Object System.Drawing.Point(70, 8)
$T7_Search.Size       = New-Object System.Drawing.Size(400, 22)
$T7_Search.BackColor  = [System.Drawing.Color]::FromArgb(10, 14, 20)
$T7_Search.ForeColor  = $C_White
$T7_Search.Font       = $FONT_MONO_SM
$T7_Search.BorderStyle= [System.Windows.Forms.BorderStyle]::FixedSingle
$T7_SearchPan.Controls.Add($T7_Search)

$T7_BtnLoad = New-Object System.Windows.Forms.Button
$T7_BtnLoad.Text      = "▶  LOAD ACTIVITY"
$T7_BtnLoad.Location  = New-Object System.Drawing.Point(482, 7)
$T7_BtnLoad.Size      = New-Object System.Drawing.Size(160, 22)
$T7_BtnLoad.BackColor = [System.Drawing.Color]::FromArgb(0, 40, 20)
$T7_BtnLoad.ForeColor = $C_Green
$T7_BtnLoad.FlatStyle = [System.Windows.Forms.FlatStyle]::Flat
$T7_BtnLoad.Font      = $FONT_MONO_SM
$T7_BtnLoad.FlatAppearance.BorderColor = $C_Green
$T7_SearchPan.Controls.Add($T7_BtnLoad)
$T7_Main.Controls.Add($T7_SearchPan)

$T7_Grid = New-Grid
Add-Col $T7_Grid "Time"    "Action Time"     145 $C_Cyan
Add-Col $T7_Grid "Desc"    "Description"     120
Add-Col $T7_Grid "Name"    "Filename"        180 $C_White
Add-Col $T7_Grid "Path"    "Full Path"       400 $C_Dim
Add-Col $T7_Grid "Info"    "More Info"       200 $C_Dim
Add-Col $T7_Grid "Ext"     "Ext"             40  $C_Magenta
Add-Col $T7_Grid "Source"  "Data Source"     300 $C_Dim
$T7_Grid.Columns["Path"].AutoSizeMode = [System.Windows.Forms.DataGridViewAutoSizeColumnMode]::Fill
$T7_Main.Controls.Add($T7_Grid)

$T7_AllRows = @()

function Refresh-T7Grid {
    $T7_Grid.Rows.Clear()
    $kw = $T7_Search.Text.Trim()
    foreach ($row in $script:T7_AllRows) {
        $match = ($kw -eq "" -or $row.Name -match [regex]::Escape($kw) -or $row.Path -match [regex]::Escape($kw) -or $row.Desc -match [regex]::Escape($kw))
        if ($match) {
            $ri = $T7_Grid.Rows.Add($row.Time, $row.Desc, $row.Name, $row.Path, $row.Info, $row.Ext, $row.Source)
            $r  = $T7_Grid.Rows[$ri]
            if ($row.Desc -eq "Task Run") {
                $r.Cells["Desc"].Style.ForeColor = $C_Yellow
            }
        }
    }
}
$T7_Search.Add_TextChanged({ Refresh-T7Grid })

function Load-T7Data {
    $T7_BtnLoad.Enabled = $false
    $script:T7_AllRows  = @()
    $T7_Grid.Rows.Clear()

    $pfPath = "$env:WINDIR\Prefetch"
    if (Test-Path $pfPath) {
        $pfs = Get-ChildItem $pfPath -Filter "*.pf" -EA SilentlyContinue | Sort-Object LastWriteTime -Descending | Select-Object -First 100
        foreach ($pf in $pfs) {
            $exeName = $pf.Name -replace "-[A-F0-9]{8}\.pf$", ""
            $script:T7_AllRows += [PSCustomObject]@{
                Time   = $pf.LastWriteTime.ToString("M/d/yyyy HH:mm:ss")
                Desc   = "Run .EXE file"
                Name   = $exeName
                Path   = "C:\Windows\$exeName (from prefetch)"
                Info   = "Prefetch file"
                Ext    = [System.IO.Path]::GetExtension($exeName).TrimStart(".").ToUpper()
                Source = $pf.FullName
            }
        }
    }

    $rdPath = "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\RecentDocs"
    if (Test-Path $rdPath -EA SilentlyContinue) {
        Get-ChildItem $rdPath -EA SilentlyContinue | ForEach-Object {
            $ext = $_.PSChildName
            $props = Get-ItemProperty $_.PSPath -EA SilentlyContinue
            if ($props) {
                foreach ($prop in $props.PSObject.Properties) {
                    if ($prop.Name -match "^\d+$" -and $prop.Value -is [byte[]]) {
                        try {
                            $str = [System.Text.Encoding]::Unicode.GetString($prop.Value).Split([char]0)[0]
                            if ($str.Length -gt 2) {
                                $script:T7_AllRows += [PSCustomObject]@{
                                    Time   = (Get-Date).ToString("M/d/yyyy")
                                    Desc   = "Recent Document"
                                    Name   = $str
                                    Path   = "(from RecentDocs registry)"
                                    Info   = "Extension: $ext"
                                    Ext    = $ext.TrimStart(".")
                                    Source = $rdPath
                                }
                            }
                        } catch {}
                    }
                }
            }
        }
    }

    try {
        $evts = Get-WinEvent -LogName "Microsoft-Windows-TaskScheduler/Operational" -MaxEvents 50 -EA SilentlyContinue |
            Where-Object { $_.Id -in @(200, 201) }
        foreach ($evt in $evts) {
            $script:T7_AllRows += [PSCustomObject]@{
                Time   = $evt.TimeCreated.ToString("M/d/yyyy HH:mm:ss")
                Desc   = "Task Run"
                Name   = ($evt.Message -split "`n")[0].Trim()
                Path   = ""
                Info   = "EventID: $($evt.Id)"
                Ext    = ""
                Source = "TaskScheduler/Operational"
            }
        }
    } catch {}

    $script:T7_AllRows = $script:T7_AllRows | Sort-Object { [DateTime]::TryParse($_.Time, [ref]([DateTime]::MinValue)); $_.Time } -Descending

    Refresh-T7Grid
    $T7_BtnLoad.Enabled = $true
    $T7_BtnLoad.Text    = "↺  RELOAD ACTIVITY"

    $T7_Stat.Controls | Where-Object { $_ -is [System.Windows.Forms.Label] -and $_.Font.Bold } |
        Select-Object -Last 1 | ForEach-Object { $_.Text = "$($script:T7_AllRows.Count)" }
}

$T7_BtnLoad.Add_Click({ Load-T7Data })

# ─── STATUS BAR ───────────────────────────────────────────────────────────────
$StatusBar = New-Object System.Windows.Forms.Panel
$StatusBar.Dock      = [System.Windows.Forms.DockStyle]::Bottom
$StatusBar.Height    = 24
$StatusBar.BackColor = $C_DarkPan

$StatusLbl = New-Object System.Windows.Forms.Label
$StatusLbl.Text      = "  VAELITH V3  |  READ ONLY  |  No changes made  |  $($env:COMPUTERNAME) ($($env:USERNAME))  |  $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')"
$StatusLbl.ForeColor = $C_Dim
$StatusLbl.Font      = $FONT_MONO_SM
$StatusLbl.Dock      = [System.Windows.Forms.DockStyle]::Fill
$StatusLbl.TextAlign = [System.Drawing.ContentAlignment]::MiddleLeft
$StatusBar.Controls.Add($StatusLbl)
$Form.Controls.Add($StatusBar)

# ─── TAB CHANGE EVENT (auto-load data) ────────────────────────────────────────
$Tabs.Add_SelectedIndexChanged({
    $sel = $Tabs.SelectedTab
    if ($sel -eq $Tab3) { Load-T3Data }
    elseif ($sel -eq $Tab4) { Load-T4Data }
    elseif ($sel -eq $Tab5) { Load-T5Processes }
    elseif ($sel -eq $Tab7) { Load-T7Data }
})

# ─── GLOBAL KEYDOWN EVENT: PRESS ENTER TO ADVANCE TABS ───────────────────────
$Form.Add_KeyDown({
    param($s, $e)
    if ($e.KeyCode -eq [System.Windows.Forms.Keys]::Enter) {
        if ($script:CanGoToNextStep) {
            $currentIndex = $Tabs.SelectedIndex
            $maxIndex = $Tabs.TabCount - 1
            if ($currentIndex -lt $maxIndex) {
                $e.SuppressKeyPress = $true
                $Tabs.SelectedIndex = $currentIndex + 1
                $script:CanGoToNextStep = $false 
            }
        }
    }
})

# ─── SHOW ─────────────────────────────────────────────────────────────────────
[System.Windows.Forms.Application]::Run($Form)
