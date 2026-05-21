import { useState, useEffect, useRef } from "react";

const DARK = {
  bg: "#0a0e14",
  panel: "#0d1117",
  border: "#1a2332",
  cyan: "#00d4ff",
  green: "#00ff88",
  red: "#ff4444",
  yellow: "#ffcc00",
  magenta: "#ff44ff",
  dim: "#4a5568",
  white: "#e2e8f0",
  darkPanel: "#080c12",
};

const ASCII_LOGO = `  ██╗   ██╗ █████╗ ███████╗██╗     ██╗████████╗██╗  ██╗
  ██║   ██║██╔══██╗██╔════╝██║     ██║╚══██╔══╝██║  ██║
  ██║   ██║███████║█████╗  ██║     ██║   ██║   ███████║
  ╚██╗ ██╔╝██╔══██║██╔══╝  ██║     ██║   ██║   ██╔══██║
   ╚████╔╝ ██║  ██║███████╗███████╗██║   ██║   ██║  ██║
    ╚═══╝  ╚═╝  ╚═╝╚══════╝╚══════╝╚═╝   ╚═╝   ╚═╝  ╚═╝`;

// ─── FAKE DATA ───────────────────────────────────────────────────────────────

const SYSTEM_CHECK_LINES = [
  { delay: 100,  color: DARK.cyan,   text: "[ Step 1 of 6 – System Check ]" },
  { delay: 300,  color: DARK.white,  text: "[ ####################] 100%" },
  { delay: 500,  color: DARK.dim,    text: "" },
  { delay: 600,  color: DARK.dim,    text: "--- Modules ---" },
  { delay: 800,  color: DARK.green,  text: "SUCCESS: Module 'Microsoft.PowerShell.Operation.Validation' verified." },
  { delay: 950,  color: DARK.green,  text: "SUCCESS: Module 'PackageManagement' verified." },
  { delay: 1100, color: DARK.green,  text: "SUCCESS: Module 'Pester' verified." },
  { delay: 1250, color: DARK.green,  text: "SUCCESS: Module 'PowerShellGet' verified." },
  { delay: 1400, color: DARK.green,  text: "SUCCESS: Module 'PSReadline' verified." },
  { delay: 1550, color: DARK.green,  text: "SUCCESS: No unauthorized modules detected." },
  { delay: 1700, color: DARK.dim,    text: "" },
  { delay: 1750, color: DARK.dim,    text: "--- CPU & GPU Detections ---" },
  { delay: 1900, color: DARK.green,  text: "SUCCESS: CPU detected -> AMD Ryzen 5 5600GT with Radeon Graphics" },
  { delay: 2050, color: DARK.green,  text: "SUCCESS: GPU detected -> AMD Radeon RX 580 2048SP" },
  { delay: 2200, color: DARK.dim,    text: "" },
  { delay: 2250, color: DARK.dim,    text: "--- Windows Defender ---" },
  { delay: 2400, color: DARK.green,  text: "SUCCESS: Windows Defender real-time protection enabled." },
  { delay: 2550, color: DARK.dim,    text: "" },
  { delay: 2600, color: DARK.dim,    text: "--- Defender Exclusions ---" },
  { delay: 2750, color: DARK.green,  text: "SUCCESS: No Defender exclusions." },
  { delay: 2900, color: DARK.dim,    text: "" },
  { delay: 2950, color: DARK.dim,    text: "--- Memory Integrity ---" },
  { delay: 3100, color: DARK.green,  text: "SUCCESS: Memory Integrity enabled." },
  { delay: 3250, color: DARK.dim,    text: "" },
  { delay: 3300, color: DARK.dim,    text: "--- Process Scan ---" },
  { delay: 3450, color: DARK.green,  text: "SUCCESS: No suspicious processes detected." },
  { delay: 3600, color: DARK.dim,    text: "" },
  { delay: 3650, color: DARK.dim,    text: "--- Key Checker ---" },
  { delay: 3800, color: DARK.green,  text: "SUCCESS: No KeyAuth cheat folders." },
  { delay: 3950, color: DARK.dim,    text: "" },
  { delay: 4000, color: DARK.dim,    text: "--- PowerShell Binary ---" },
  { delay: 4150, color: DARK.green,  text: "SUCCESS: PowerShell binary authentic." },
  { delay: 4300, color: DARK.dim,    text: "" },
  { delay: 4350, color: DARK.dim,    text: "--- OS Check ---" },
  { delay: 4500, color: DARK.green,  text: "SUCCESS: OS verified." },
  { delay: 4650, color: DARK.dim,    text: "" },
  { delay: 4700, color: DARK.dim,    text: "--- Virtual Machine ---" },
  { delay: 4850, color: DARK.green,  text: "SUCCESS: Not running in VM." },
  { delay: 5000, color: DARK.dim,    text: "" },
  { delay: 5050, color: DARK.dim,    text: "--- Registry Scan ---" },
  { delay: 5200, color: DARK.green,  text: "SUCCESS: No suspicious MuiCache entries detected." },
  { delay: 5350, color: DARK.dim,    text: "" },
  { delay: 5500, color: DARK.green,  text: "Overall Success Rate: 100%" },
  { delay: 5700, color: DARK.cyan,   text: "Press Enter to continue to Step 2..." },
];

const MODULES_OUTPUT = [
  { mod: 1,  label: "File System",                    status: "CLEAN",  detail: "No file traces found." },
  { mod: 2,  label: "ShimCache / AppCompatCache",      status: "CLEAN",  detail: "'target' not found in ShimCache." },
  { mod: 3,  label: "BAM – Background Activity",       status: "CLEAN",  detail: "No BAM entries found." },
  { mod: 4,  label: "Registry Execution Artifacts",    status: "CLEAN",  detail: "No registry artifacts found." },
  { mod: 5,  label: "UserAssist (ROT13)",              status: "CLEAN",  detail: "No UserAssist entries found." },
  { mod: 6,  label: "Prefetch Files",                  status: "CLEAN",  detail: "No Prefetch files found." },
  { mod: 7,  label: "Archive Files",                   status: "CLEAN",  detail: "No archive references found." },
  { mod: 8,  label: "Windows Defender History",        status: "CLEAN",  detail: "No Defender artifacts found." },
  { mod: 9,  label: "Windows Event Viewer Logs",       status: "CLEAN",  detail: "No Event Log entries found." },
  { mod: 10, label: "Browser History",                 status: "FOUND",  detail: "Edge History DB contains 'target'" },
  { mod: 11, label: "Jump Lists",                      status: "CLEAN",  detail: "No Jump List references found." },
  { mod: 12, label: "Thumbnail Cache",                 status: "CLEAN",  detail: "No thumbnail cache references." },
  { mod: 13, label: "Windows Search Index",            status: "FOUND",  detail: "WordWheelQuery entry: 'target'" },
  { mod: 14, label: "Scheduled Tasks",                 status: "CLEAN",  detail: "No scheduled tasks referencing." },
  { mod: 15, label: "Network Artifacts",               status: "CLEAN",  detail: "No network artifacts found." },
  { mod: 16, label: "Recycle Bin",                     status: "CLEAN",  detail: "No Recycle Bin items found." },
  { mod: 17, label: "LNK / Shortcut Files",            status: "CLEAN",  detail: "No LNK shortcut references." },
  { mod: 18, label: "Volume Shadow Copies",            status: "CLEAN",  detail: "No VSS references found." },
  { mod: 19, label: "PowerShell History",              status: "CLEAN",  detail: "No PS history references." },
  { mod: 20, label: "WMI Subscriptions",               status: "CLEAN",  detail: "No WMI subscription references." },
  { mod: 21, label: "USB Device History",              status: "CLEAN",  detail: "No USB history references." },
  { mod: 22, label: "Amcache.hve",                     status: "CLEAN",  detail: "No Amcache references." },
  { mod: 23, label: "SRUM Database",                   status: "CLEAN",  detail: "No SRUM references." },
  { mod: 24, label: "Remote Desktop History",          status: "CLEAN",  detail: "No RDP references." },
  { mod: 25, label: "Open Handles / Locked Files",     status: "CLEAN",  detail: "No suspicious handles." },
  { mod: 26, label: "Startup Persistence",             status: "CLEAN",  detail: "No startup persistence." },
  { mod: 27, label: "Services & Drivers",              status: "CLEAN",  detail: "No tracking signatures." },
  { mod: 28, label: "Alternate Data Streams",          status: "CLEAN",  detail: "No ADS found." },
  { mod: 29, label: "Memory Dump Artifacts",           status: "CLEAN",  detail: "No memory dump traces." },
  { mod: 30, label: "Cloud Sync Artifacts",            status: "CLEAN",  detail: "No cloud storage traces." },
  { mod: 31, label: "SQLite Database Scan",            status: "CLEAN",  detail: "No tracking databases." },
  { mod: 32, label: "Windows Timeline",                status: "CLEAN",  detail: "No timeline activity data." },
  { mod: 33, label: "Discord / Telegram / Steam",      status: "CLEAN",  detail: "No communication logs." },
  { mod: 34, label: "Environment Variables",           status: "CLEAN",  detail: "No rogue environment strings." },
  { mod: 35, label: "Windows Notification Database",   status: "CLEAN",  detail: "No notification strings." },
];

const BAM_ENTRIES = [
  { sid: "S-1-5-21-3842...-1001", path: "\\Device\\HarddiskVolume3\\Windows\\System32\\svchost.exe",      lastRun: "2026-05-21 12:44:01", seq: 1289 },
  { sid: "S-1-5-21-3842...-1001", path: "\\Device\\HarddiskVolume3\\Program Files\\Opera\\opera.exe",     lastRun: "2026-05-21 12:43:55", seq: 1288 },
  { sid: "S-1-5-21-3842...-1001", path: "\\Device\\HarddiskVolume3\\Windows\\System32\\conhost.exe",      lastRun: "2026-05-21 12:43:50", seq: 1287 },
  { sid: "S-1-5-21-3842...-1001", path: "\\Device\\HarddiskVolume3\\Windows\\System32\\powershell.exe",   lastRun: "2026-05-21 12:43:48", seq: 1286 },
  { sid: "S-1-5-21-3842...-1001", path: "\\Device\\HarddiskVolume3\\Windows\\System32\\smartscreen.exe",  lastRun: "2026-05-21 12:43:30", seq: 1285 },
  { sid: "S-1-5-21-3842...-1001", path: "\\Device\\HarddiskVolume3\\Windows\\System32\\consent.exe",      lastRun: "2026-05-21 12:43:20", seq: 1284 },
  { sid: "S-1-5-21-3842...-1001", path: "\\Device\\HarddiskVolume3\\Users\\Master\\AppData\\Local\\Temp\\PROCEXP64.EXE", lastRun: "2026-05-21 12:42:10", seq: 1283 },
  { sid: "S-1-5-21-3842...-1001", path: "\\Device\\HarddiskVolume3\\Windows\\System32\\RuntimeBroker.exe",lastRun: "2026-05-21 12:41:05", seq: 1282 },
  { sid: "S-1-5-21-3842...-1001", path: "\\Device\\HarddiskVolume3\\Windows\\System32\\backgroundTaskHost.exe", lastRun: "2026-05-21 12:40:00", seq: 1281 },
  { sid: "S-1-5-21-3842...-1001", path: "\\Device\\HarddiskVolume3\\Windows\\explorer.exe",               lastRun: "2026-05-21 12:38:44", seq: 1280 },
  { sid: "S-1-5-21-3842...-1001", path: "\\Device\\HarddiskVolume3\\Program Files\\Claude\\claude.exe",   lastRun: "2026-05-21 12:35:11", seq: 1279 },
  { sid: "S-1-5-21-3842...-1001", path: "\\Device\\HarddiskVolume3\\Windows\\System32\\MicrosoftEdgeUpdate.exe", lastRun: "2026-05-21 12:30:00", seq: 1278 },
];

const PREFETCH_ENTRIES = [
  { name: "AI.EXE-BFCE48F9.pf",                  size: 29.76,  lastAccess: "2026-05-21 00:35:35", lastRun: "Unknown" },
  { name: "AMDDMLFILTERS.EXE-250E5F71.pf",        size: 16.04,  lastAccess: "2026-05-21 00:35:35", lastRun: "Unknown" },
  { name: "AMDIDENTIFYWINDOW.EXE-6DDB66AF.pf",    size: 21.02,  lastAccess: "2026-05-21 00:35:35", lastRun: "Unknown" },
  { name: "AMDRSSRCEXT.EXE-A391DDC1.pf",          size: 27.23,  lastAccess: "2026-05-21 00:35:35", lastRun: "Unknown" },
  { name: "ANYDESK.EXE-DB935E04.pf",              size: 21.44,  lastAccess: "2026-05-21 00:35:35", lastRun: "Unknown" },
  { name: "APP.EXE-050E0522.pf",                  size: 17.02,  lastAccess: "2026-05-21 00:35:35", lastRun: "Unknown" },
  { name: "APP.EXE-2290F258.pf",                  size: 20.46,  lastAccess: "2026-05-21 00:35:35", lastRun: "Unknown" },
  { name: "APP.EXE-39E61A72.pf",                  size: 24.94,  lastAccess: "2026-05-21 00:35:35", lastRun: "Unknown" },
  { name: "APP.EXE-41153D92.pf",                  size: 21.33,  lastAccess: "2026-05-21 00:35:35", lastRun: "Unknown" },
  { name: "APP.EXE-8949B0E7.pf",                  size: 21.16,  lastAccess: "2026-05-21 00:35:35", lastRun: "Unknown" },
  { name: "APPLICATIONFRAMEHOST.EXE-8CE9A1EE.pf", size: 15.83,  lastAccess: "2026-05-21 00:35:35", lastRun: "Unknown" },
  { name: "ASUSUPDATE.EXE-C5D92B78.pf",           size: 17.3,   lastAccess: "2026-05-21 00:35:35", lastRun: "Unknown" },
  { name: "AUDIODG.EXE-AB22E9A6.pf",              size: 5.29,   lastAccess: "2026-05-21 00:35:35", lastRun: "Unknown" },
  { name: "BACKGROUNDTASKHOST.EXE-1E8A2D20.pf",   size: 7.2,    lastAccess: "2026-05-21 00:35:35", lastRun: "Unknown" },
  { name: "BACKGROUNDTASKHOST.EXE-332B0729.pf",   size: 14.48,  lastAccess: "2026-05-21 00:06:25", lastRun: "Unknown" },
  { name: "BACKGROUNDTASKHOST.EXE-78FD9AAB.pf",   size: 11.88,  lastAccess: "2026-05-21 00:51:12", lastRun: "Unknown" },
  { name: "BDEUISRV.EXE-7BC33651.pf",             size: 4.16,   lastAccess: "2026-05-21 00:35:35", lastRun: "Unknown" },
  { name: "CAPCUT.EXE-66891E04.pf",               size: 4.62,   lastAccess: "2026-05-21 00:35:35", lastRun: "Unknown" },
  { name: "CAPCUT.EXE-F0316570.pf",               size: 71.15,  lastAccess: "2026-05-21 00:35:35", lastRun: "Unknown" },
  { name: "CAPCUT.EXE-F0316571.pf",               size: 32.85,  lastAccess: "2026-05-21 00:35:35", lastRun: "Unknown" },
  { name: "CAPCUT.EXE-F0316572.pf",               size: 37.71,  lastAccess: "2026-05-21 00:35:35", lastRun: "Unknown" },
  { name: "CAPCUT.EXE-F0316578.pf",               size: 49.7,   lastAccess: "2026-05-21 00:35:35", lastRun: "Unknown" },
  { name: "CHROME.EXE-AED7BA3C.pf",               size: 160.38, lastAccess: "2026-05-21 00:35:35", lastRun: "Unknown" },
  { name: "CHROME.EXE-AED7BA44.pf",               size: 30.48,  lastAccess: "2026-05-21 00:35:35", lastRun: "Unknown" },
  { name: "CHXSMARTSCREEN.EXE-33A0432C.pf",        size: 29.5,   lastAccess: "2026-05-21 00:35:35", lastRun: "Unknown" },
  { name: "CLAUDE.EXE-E474E44D.pf",               size: 70.79,  lastAccess: "2026-05-21 00:35:35", lastRun: "Unknown" },
  { name: "CLAUDE.EXE-E474E455.pf",               size: 38.95,  lastAccess: "2026-05-21 00:35:35", lastRun: "Unknown" },
  { name: "CLINFO.EXE-4552FFE4.pf",               size: 15.49,  lastAccess: "2026-05-21 00:35:35", lastRun: "Unknown" },
  { name: "CMD.EXE-0BD30981.pf",                  size: 2.05,   lastAccess: "2026-05-21 00:35:35", lastRun: "Unknown" },
  { name: "CNCMD.EXE-12D2F4DA.pf",                size: 9.5,    lastAccess: "2026-05-21 00:35:35", lastRun: "Unknown" },
];

const PROCESSES = [
  { name: "Interrupts",           cpu: 1.09,  privBytes: "0 K",       ws: "0 K",       pid: "n/a", company: "",                          vt: "",         path: "" },
  { name: "System Idle Process",  cpu: 75.74, privBytes: "60 K",      ws: "8 K",       pid: "0",   company: "",                          vt: "",         path: "" },
  { name: "Secure System",        cpu: null,  privBytes: "184 K",     ws: "45,944 K",  pid: "64",  company: "",                          vt: "",         path: "[A device attached to the system is not functioning.]", alert: true },
  { name: "System",               cpu: 1.55,  privBytes: "196 K",     ws: "148 K",     pid: "4",   company: "",                          vt: "",         path: "" },
  { name: "smss.exe",             cpu: null,  privBytes: "1,100 K",   ws: "1,088 K",   pid: "408", company: "",                          vt: "",         path: "[Access is denied.]" },
  { name: "Lsalso.exe",           cpu: null,  privBytes: "1,272 K",   ws: "3,084 K",   pid: "836", company: "",                          vt: "",         path: "[Invalid access to memory location.]" },
  { name: "unsecapp.exe",         cpu: "< 0.01", privBytes: "1,436 K",ws: "7,640 K",   pid: "15716",company: "Microsoft Corporation",    vt: "Hash sub...", path: "C:\\Windows\\System32\\wbem\\unsecapp.exe" },
  { name: "dllhost.exe",          cpu: "< 0.01", privBytes: "1,464 K",ws: "6,920 K",   pid: "9484", company: "Microsoft Corporation",    vt: "Hash sub...", path: "C:\\Windows\\System32\\dllhost.exe" },
  { name: "wininit.exe",          cpu: null,  privBytes: "1,480 K",   ws: "5,908 K",   pid: "744", company: "",                          vt: "",         path: "[Access is denied.]" },
  { name: "cncmd.exe",            cpu: "< 0.01", privBytes: "1,544 K",ws: "1,060 K",   pid: "10016",company: "Advanced Micro De...",     vt: "Hash sub...", path: "C:\\Program Files\\AMD\\CNext\\CNext\\cncmd.exe" },
  { name: "CompPkgSrv.exe",       cpu: "< 0.01", privBytes: "1,660 K",ws: "8,332 K",   pid: "2056", company: "Microsoft Corporation",    vt: "Hash sub...", path: "C:\\Windows\\System32\\CompPkgSrv.exe" },
  { name: "GameSDK.exe",          cpu: "< 0.01", privBytes: "1,744 K",ws: "7,068 K",   pid: "4100", company: "ASUS Inc.",                vt: "Hash sub...", path: "C:\\Program Files (x86)\\ASUS\\GameSDK Service\\GameSDK.exe" },
  { name: "svchost.exe",          cpu: "< 0.01", privBytes: "1,756 K",ws: "7,872 K",   pid: "2572", company: "Microsoft Corporation",    vt: "Hash sub...", path: "C:\\Windows\\System32\\svchost.exe" },
  { name: "Spotify.exe",          cpu: "< 0.01", privBytes: "2,108 K",ws: "6,692 K",   pid: "7852", company: "Spotify Ltd",              vt: "Hash sub...", path: "C:\\Program Files\\WindowsApps\\SpotifyAB.SpotifyMusic_1.284.476.0_x64\\Spotify.exe" },
  { name: "CPUMetricsServer.exe", cpu: "< 0.01", privBytes: "2,112 K",ws: "3,960 K",   pid: "7372", company: "Advanced Micro De...",     vt: "Hash sub...", path: "C:\\Program Files\\AMD\\CNext\\CNext\\cpumetricsserver.exe" },
  { name: "RuntimeBroker.exe",    cpu: "< 0.01", privBytes: "2,212 K",ws: "13,176 K",  pid: "17244",company: "Microsoft Corporation",    vt: "Hash sub...", path: "C:\\Windows\\System32\\RuntimeBroker.exe" },
  { name: "AsusCertService.exe",  cpu: "< 0.01", privBytes: "2,244 K",ws: "8,116 K",   pid: "1904", company: "Asustek Computer Inc.",    vt: "Hash sub...", path: "C:\\Program Files (x86)\\ASUS\\AsusCertService\\1.2.40\\AsusCertService.exe" },
  { name: "UserOOBEBroker.exe",   cpu: "< 0.01", privBytes: "2,308 K",ws: "9,880 K",   pid: "13444",company: "Microsoft Corporation",    vt: "Hash sub...", path: "C:\\Windows\\System32\\oobe\\UserOOBEBroker.exe" },
];

const ACTIVITY_ENTRIES = [
  { time: "5/21/2026 12:56:...", desc: "Run .EXE file", filename: "PROCEXP64.EXE",         path: "C:\\Users\\Master\\AppData\\Local\\Temp\\PR...",  info: "Sysinternals - www.sysin...", ext: "EXE", src: "C:\\Windows\\Prefetch\\PROCEXP64.EXE-80C496E5.pf" },
  { time: "5/21/2026 12:55:...", desc: "Run .EXE file", filename: "FILECOAUTH.EXE",         path: "C:\\PROGRAM FILES\\MICROSOFT ONEDRI...",          info: "Microsoft Corporation, ...",  ext: "EXE", src: "C:\\Windows\\Prefetch\\FILECOAUTH.EXE-557CE499.pf" },
  { time: "5/21/2026 12:55:...", desc: "Run .EXE file", filename: "RUNTIMEBROKER.EXE",      path: "C:\\WINDOWS\\SYSTEM32\\RUNTIMEBROKE...",          info: "Microsoft Corporation, ...",  ext: "EXE", src: "C:\\Windows\\Prefetch\\RUNTIMEBROKER.EXE-DA85E0A1.pf" },
  { time: "5/21/2026 12:55:...", desc: "Run .EXE file", filename: "BACKGROUNDTASKHOS...",   path: "C:\\WINDOWS\\SYSTEM32\\BACKGROUNDTASK...",        info: "Microsoft Corporation, ...",  ext: "EXE", src: "C:\\Windows\\Prefetch\\BACKGROUNDTASKHOST.EXE-78FD9AA..." },
  { time: "5/21/2026 12:55:...", desc: "Run .EXE file", filename: "SCREENCLIPPINGHOST....", path: "C:\\WINDOWS\\SYSTEMAPPS\\MICROSOFTWI...",          info: "Microsoft Corporation, ...",  ext: "EXE", src: "C:\\Windows\\Prefetch\\SCREENCLIPPINGHOST.EXE-7337D47F.pf" },
  { time: "5/21/2026 12:54:...", desc: "Run .EXE file", filename: "opera.exe",              path: "C:\\Users\\Master\\AppData\\Local\\Programs...", info: "Opera Software, Opera ...",    ext: "exe", src: "C:\\Windows\\Prefetch\\OPERA.EXE-D57A8470.pf" },
  { time: "5/21/2026 12:54:...", desc: "Run .EXE file", filename: "MICROSOFTEDGEUPDAT...", path: "C:\\PROGRAM FILES (X86)\\MICROSOFT\\ED...",        info: "Microsoft Corporation, ...",  ext: "EXE", src: "C:\\Windows\\Prefetch\\MICROSOFTEDGEUPDATE.EXE-7A59532..." },
  { time: "5/21/2026 12:54:...", desc: "Task Run",      filename: "MicrosoftEdgeUpdate.exe",path: "C:\\Program Files (x86)\\Microsoft\\EdgeUpd...", info: "MicrosoftEdgeUpdateTa...",    ext: "exe", src: "" },
  { time: "5/21/2026 12:51:...", desc: "Run .EXE file", filename: "CONSENT.EXE",            path: "C:\\WINDOWS\\SYSTEM32\\CONSENT.EXE",              info: "Microsoft Corporation, ...",  ext: "EXE", src: "C:\\Windows\\Prefetch\\CONSENT.EXE-40419367.pf" },
  { time: "5/21/2026 12:51:...", desc: "Run .EXE file", filename: "RUNTIMEBROKER.EXE",      path: "C:\\WINDOWS\\SYSTEM32\\RUNTIMEBROKE...",          info: "Microsoft Corporation, ...",  ext: "EXE", src: "C:\\Windows\\Prefetch\\RUNTIMEBROKER.EXE-DA85E0A1.pf" },
  { time: "5/21/2026 12:50:...", desc: "Run .EXE file", filename: "CONHOST.EXE",            path: "C:\\WINDOWS\\SYSTEM32\\CONHOST.EXE",              info: "Microsoft Corporation, ...",  ext: "EXE", src: "C:\\Windows\\Prefetch\\CONHOST.EXE-0C6456FB.pf" },
  { time: "5/21/2026 12:50:...", desc: "Run .EXE file", filename: "POWERSHELL.EXE",         path: "C:\\Windows\\System32\\WINDOWSPOWERSHELL...",     info: "Microsoft Corporation, ...",  ext: "EXE", src: "C:\\Windows\\Prefetch\\POWERSHELL.EXE-CA1AE517.pf" },
  { time: "5/21/2026 12:50:...", desc: "Run .EXE file", filename: "CONSENT.EXE",            path: "C:\\WINDOWS\\SYSTEM32\\CONSENT.EXE",              info: "Microsoft Corporation, ...",  ext: "EXE", src: "C:\\Windows\\Prefetch\\CONSENT.EXE-40419367.pf" },
  { time: "5/21/2026 12:50:...", desc: "Run .EXE file", filename: "SMARTSCREEN.EXE",        path: "C:\\WINDOWS\\SYSTEM32\\SMARTSCREEN.EXE",          info: "Microsoft Corporation, ...",  ext: "EXE", src: "C:\\Windows\\Prefetch\\SMARTSCREEN.EXE-EACC1250.pf" },
  { time: "5/21/2026 12:47:...", desc: "Run .EXE file", filename: "WmiPrvSE.exe",           path: "C:\\Windows\\System32\\wbem\\WmiPrvSE.exe",       info: "Microsoft Corporation, ...",  ext: "exe", src: "C:\\Windows\\Prefetch\\WMIPRVSE.EXE-E8B8DD29.pf" },
  { time: "5/21/2026 12:47:...", desc: "Run .EXE file", filename: "UNSECAPP.EXE",           path: "C:\\WINDOWS\\SYSTEM32\\WBEM\\UNSECAP...",         info: "Microsoft Corporation, ...",  ext: "EXE", src: "C:\\Windows\\Prefetch\\UNSECAPP.EXE-72B9DDB3.pf" },
  { time: "5/21/2026 12:47:...", desc: "Task Run",      filename: "unifiedconsent.dll",     path: "C:\\Windows\\System32\\unifiedconsent.dll",       info: "UnifiedConsentSyncTask...",  ext: "dll", src: "" },
  { time: "5/21/2026 12:47:...", desc: "Run .EXE file", filename: "opera.exe",              path: "C:\\Users\\Master\\AppData\\Local\\Programs...", info: "Opera Software, Opera ...",   ext: "exe", src: "C:\\Windows\\Prefetch\\OPERA.EXE-D57A8469.pf" },
];

// ─── COMPONENTS ──────────────────────────────────────────────────────────────

const styles = {
  app: {
    background: DARK.bg,
    minHeight: "100vh",
    fontFamily: "'Courier New', 'Lucida Console', monospace",
    color: DARK.white,
    padding: "0",
    overflowX: "hidden",
  },
  header: {
    background: DARK.darkPanel,
    borderBottom: `1px solid ${DARK.border}`,
    padding: "16px 20px 12px",
  },
  logo: {
    color: DARK.cyan,
    fontSize: "10px",
    lineHeight: "1.2",
    whiteSpace: "pre",
    marginBottom: "6px",
    letterSpacing: "0",
  },
  subtitle: {
    color: DARK.dim,
    fontSize: "11px",
  },
  stepsBar: {
    display: "flex",
    gap: "2px",
    padding: "8px 20px",
    background: "#060a0f",
    borderBottom: `1px solid ${DARK.border}`,
    overflowX: "auto",
  },
  stepBtn: (active, done) => ({
    padding: "5px 12px",
    fontSize: "11px",
    border: `1px solid ${active ? DARK.cyan : done ? DARK.green : DARK.border}`,
    background: active ? "rgba(0,212,255,0.08)" : done ? "rgba(0,255,136,0.05)" : "transparent",
    color: active ? DARK.cyan : done ? DARK.green : DARK.dim,
    cursor: "pointer",
    whiteSpace: "nowrap",
    transition: "all 0.15s",
    borderRadius: "2px",
  }),
  content: {
    padding: "16px 20px",
    maxWidth: "1400px",
  },
  panel: {
    background: DARK.panel,
    border: `1px solid ${DARK.border}`,
    borderRadius: "3px",
    marginBottom: "12px",
  },
  panelHeader: {
    padding: "8px 12px",
    borderBottom: `1px solid ${DARK.border}`,
    display: "flex",
    alignItems: "center",
    gap: "8px",
    fontSize: "11px",
    color: DARK.cyan,
    background: "rgba(0,212,255,0.04)",
  },
  panelBody: {
    padding: "0",
    maxHeight: "420px",
    overflowY: "auto",
  },
  termLine: (color) => ({
    padding: "1px 12px",
    fontSize: "12px",
    color: color || DARK.white,
    whiteSpace: "pre",
    lineHeight: "1.5",
    fontFamily: "'Courier New', monospace",
  }),
  table: {
    width: "100%",
    borderCollapse: "collapse",
    fontSize: "11px",
  },
  th: {
    padding: "6px 10px",
    textAlign: "left",
    color: DARK.cyan,
    borderBottom: `1px solid ${DARK.border}`,
    background: "rgba(0,212,255,0.04)",
    fontWeight: "normal",
    whiteSpace: "nowrap",
    position: "sticky",
    top: 0,
  },
  td: (highlight) => ({
    padding: "4px 10px",
    borderBottom: `1px solid rgba(26,35,50,0.6)`,
    color: highlight ? DARK.red : DARK.white,
    fontSize: "11px",
    whiteSpace: "nowrap",
    overflow: "hidden",
    textOverflow: "ellipsis",
    maxWidth: "300px",
  }),
  badge: (color) => ({
    display: "inline-block",
    padding: "1px 6px",
    borderRadius: "2px",
    fontSize: "10px",
    fontWeight: "bold",
    background: color === "FOUND" ? "rgba(255,68,68,0.15)" : "rgba(0,255,136,0.1)",
    color: color === "FOUND" ? DARK.red : DARK.green,
    border: `1px solid ${color === "FOUND" ? "rgba(255,68,68,0.3)" : "rgba(0,255,136,0.2)"}`,
  }),
  searchBar: {
    display: "flex",
    gap: "8px",
    padding: "10px 12px",
    borderBottom: `1px solid ${DARK.border}`,
    background: "rgba(0,0,0,0.2)",
    alignItems: "center",
  },
  input: {
    background: "#0a0e14",
    border: `1px solid ${DARK.border}`,
    color: DARK.white,
    padding: "4px 10px",
    fontSize: "12px",
    fontFamily: "'Courier New', monospace",
    outline: "none",
    flex: 1,
    borderRadius: "2px",
  },
  btn: (color) => ({
    padding: "4px 14px",
    background: "transparent",
    border: `1px solid ${color || DARK.cyan}`,
    color: color || DARK.cyan,
    fontSize: "11px",
    cursor: "pointer",
    fontFamily: "'Courier New', monospace",
    borderRadius: "2px",
  }),
  statBox: {
    display: "flex",
    gap: "12px",
    padding: "10px 12px",
    borderBottom: `1px solid ${DARK.border}`,
    flexWrap: "wrap",
  },
  stat: {
    fontSize: "11px",
    color: DARK.dim,
  },
  statVal: (color) => ({
    color: color || DARK.cyan,
    fontWeight: "bold",
  }),
};

// ─── STEP 1: System Check ────────────────────────────────────────────────────
function Step1SystemCheck() {
  const [lines, setLines] = useState([]);
  const [done, setDone] = useState(false);
  const ref = useRef(null);

  useEffect(() => {
    setLines([]);
    setDone(false);
    const timers = SYSTEM_CHECK_LINES.map((l, i) =>
      setTimeout(() => {
        setLines(prev => [...prev, l]);
        if (i === SYSTEM_CHECK_LINES.length - 1) setDone(true);
      }, l.delay)
    );
    return () => timers.forEach(clearTimeout);
  }, []);

  useEffect(() => {
    if (ref.current) ref.current.scrollTop = ref.current.scrollHeight;
  }, [lines]);

  return (
    <div style={styles.panel}>
      <div style={styles.panelHeader}>
        <span style={{ color: DARK.yellow }}>●</span>
        <span>[ Step 1 of 6 – System Check ]</span>
        {done && <span style={{ color: DARK.green, marginLeft: "auto" }}>✓ COMPLETE — 100%</span>}
      </div>
      <div style={{ ...styles.panelBody, padding: "8px 0" }} ref={ref}>
        {lines.map((l, i) => (
          <div key={i} style={styles.termLine(l.color)}>{l.text}</div>
        ))}
        {!done && (
          <div style={{ ...styles.termLine(DARK.dim), animation: "pulse 1s infinite" }}>█</div>
        )}
      </div>
    </div>
  );
}

// ─── STEP 2: Module Scan ─────────────────────────────────────────────────────
function Step2Modules() {
  const [search, setSearch] = useState("");
  const [filter, setFilter] = useState("ALL");
  const filtered = MODULES_OUTPUT.filter(m => {
    const matchSearch = m.label.toLowerCase().includes(search.toLowerCase()) || m.detail.toLowerCase().includes(search.toLowerCase());
    const matchFilter = filter === "ALL" || m.status === filter;
    return matchSearch && matchFilter;
  });
  const found = MODULES_OUTPUT.filter(m => m.status === "FOUND").length;
  const clean = MODULES_OUTPUT.filter(m => m.status === "CLEAN").length;

  return (
    <div style={styles.panel}>
      <div style={styles.panelHeader}>
        <span style={{ color: DARK.magenta }}>◈</span>
        <span>[ Step 2 – Full Module Scan (0 → 35) ]</span>
        <span style={{ marginLeft: "auto", color: DARK.dim }}>35 modules</span>
      </div>
      <div style={styles.statBox}>
        <div style={styles.stat}>Total: <span style={styles.statVal()}>{MODULES_OUTPUT.length}</span></div>
        <div style={styles.stat}>Found: <span style={styles.statVal(DARK.red)}>{found}</span></div>
        <div style={styles.stat}>Clean: <span style={styles.statVal(DARK.green)}>{clean}</span></div>
        <div style={{ marginLeft: "auto", display: "flex", gap: "6px" }}>
          {["ALL","CLEAN","FOUND"].map(f => (
            <button key={f} style={{ ...styles.btn(f === "FOUND" ? DARK.red : f === "CLEAN" ? DARK.green : DARK.cyan), background: filter === f ? "rgba(0,212,255,0.08)" : "transparent" }} onClick={() => setFilter(f)}>{f}</button>
          ))}
        </div>
      </div>
      <div style={styles.searchBar}>
        <span style={{ color: DARK.dim, fontSize: "11px" }}>FILTER:</span>
        <input style={styles.input} value={search} onChange={e => setSearch(e.target.value)} placeholder="Search modules..." />
      </div>
      <div style={styles.panelBody}>
        <table style={styles.table}>
          <thead>
            <tr>
              <th style={styles.th}>#</th>
              <th style={styles.th}>Module</th>
              <th style={styles.th}>Status</th>
              <th style={styles.th}>Detail</th>
            </tr>
          </thead>
          <tbody>
            {filtered.map(m => (
              <tr key={m.mod} style={{ background: m.status === "FOUND" ? "rgba(255,68,68,0.04)" : "transparent" }}>
                <td style={{ ...styles.td(), color: DARK.dim, width: "36px" }}>{String(m.mod).padStart(2,"0")}</td>
                <td style={styles.td()}>{m.label}</td>
                <td style={{ ...styles.td(), width: "80px" }}><span style={styles.badge(m.status)}>{m.status}</span></td>
                <td style={styles.td(m.status === "FOUND")}>{m.detail}</td>
              </tr>
            ))}
          </tbody>
        </table>
      </div>
    </div>
  );
}

// ─── STEP 3: BAM GUI ─────────────────────────────────────────────────────────
function Step3BAM() {
  const [search, setSearch] = useState("");
  const filtered = BAM_ENTRIES.filter(e =>
    e.path.toLowerCase().includes(search.toLowerCase()) ||
    e.sid.includes(search)
  );

  return (
    <div style={styles.panel}>
      <div style={styles.panelHeader}>
        <span style={{ color: DARK.yellow }}>⬡</span>
        <span>[ Step 3 – BAM GUI Key Entries ]</span>
        <span style={{ marginLeft: "auto", color: DARK.dim }}>Background Activity Monitor</span>
      </div>
      <div style={styles.statBox}>
        <div style={styles.stat}>Registry: <span style={styles.statVal()}>HKLM\SYSTEM\CurrentControlSet\Services\bam\State\UserSettings</span></div>
        <div style={styles.stat}>Entries: <span style={styles.statVal(DARK.yellow)}>{BAM_ENTRIES.length}</span></div>
      </div>
      <div style={styles.searchBar}>
        <span style={{ color: DARK.dim, fontSize: "11px" }}>FILTER:</span>
        <input style={styles.input} value={search} onChange={e => setSearch(e.target.value)} placeholder="Filter by path or SID..." />
      </div>
      <div style={styles.panelBody}>
        <table style={styles.table}>
          <thead>
            <tr>
              <th style={styles.th}>Seq</th>
              <th style={styles.th}>SID</th>
              <th style={styles.th}>Executable Path</th>
              <th style={styles.th}>Last Run Time</th>
            </tr>
          </thead>
          <tbody>
            {filtered.map((e, i) => (
              <tr key={i}>
                <td style={{ ...styles.td(), color: DARK.dim, width: "48px" }}>{e.seq}</td>
                <td style={{ ...styles.td(), color: DARK.dim, width: "160px" }}>{e.sid}</td>
                <td style={{ ...styles.td(), color: DARK.cyan, maxWidth: "500px" }}>{e.path}</td>
                <td style={{ ...styles.td(), color: DARK.yellow, width: "160px" }}>{e.lastRun}</td>
              </tr>
            ))}
          </tbody>
        </table>
      </div>
    </div>
  );
}

// ─── STEP 4: Prefetch Viewer ──────────────────────────────────────────────────
function Step4Prefetch() {
  const [search, setSearch] = useState("");
  const [sort, setSort] = useState({ col: "name", dir: 1 });

  const filtered = PREFETCH_ENTRIES
    .filter(e => e.name.toLowerCase().includes(search.toLowerCase()))
    .sort((a, b) => {
      const va = a[sort.col], vb = b[sort.col];
      return (va < vb ? -1 : va > vb ? 1 : 0) * sort.dir;
    });

  const toggleSort = (col) => setSort(s => ({ col, dir: s.col === col ? -s.dir : 1 }));
  const Th = ({ col, label }) => (
    <th style={{ ...styles.th, cursor: "pointer" }} onClick={() => toggleSort(col)}>
      {label} {sort.col === col ? (sort.dir === 1 ? "▲" : "▼") : ""}
    </th>
  );

  return (
    <div style={styles.panel}>
      <div style={styles.panelHeader}>
        <span style={{ color: DARK.green }}>◉</span>
        <span>[ Step 4 – Prefetch Viewer ]</span>
        <span style={{ marginLeft: "auto", color: DARK.dim }}>C:\Windows\Prefetch</span>
      </div>
      <div style={styles.statBox}>
        <div style={styles.stat}>Files: <span style={styles.statVal()}>{PREFETCH_ENTRIES.length}</span></div>
        <div style={styles.stat}>Path: <span style={styles.statVal(DARK.yellow)}>%WINDIR%\Prefetch\*.pf</span></div>
      </div>
      <div style={styles.searchBar}>
        <span style={{ color: DARK.dim, fontSize: "11px" }}>FILTER:</span>
        <input style={styles.input} value={search} onChange={e => setSearch(e.target.value)} placeholder="Filter prefetch files..." />
        <span style={{ color: DARK.dim, fontSize: "11px" }}>{filtered.length} results</span>
      </div>
      <div style={styles.panelBody}>
        <table style={styles.table}>
          <thead>
            <tr>
              <Th col="name" label="Prefetch File Name" />
              <Th col="size" label="Size (KB)" />
              <Th col="lastAccess" label="Last Access Time" />
              <Th col="lastRun" label="Last Run Time" />
            </tr>
          </thead>
          <tbody>
            {filtered.map((e, i) => (
              <tr key={i} style={{ background: i % 2 === 0 ? "rgba(0,0,0,0.15)" : "transparent" }}>
                <td style={{ ...styles.td(), color: DARK.white }}>{e.name}</td>
                <td style={{ ...styles.td(), color: DARK.yellow, width: "80px", textAlign: "right" }}>{e.size}</td>
                <td style={{ ...styles.td(), color: DARK.cyan, width: "160px" }}>{e.lastAccess}</td>
                <td style={{ ...styles.td(), color: DARK.dim, width: "100px" }}>{e.lastRun}</td>
              </tr>
            ))}
          </tbody>
        </table>
      </div>
    </div>
  );
}

// ─── STEP 5: Process Explorer ─────────────────────────────────────────────────
function Step5ProcessExplorer() {
  const [search, setSearch] = useState("");
  const [selected, setSelected] = useState(null);

  const filtered = PROCESSES.filter(p =>
    p.name.toLowerCase().includes(search.toLowerCase()) ||
    p.company.toLowerCase().includes(search.toLowerCase()) ||
    p.path.toLowerCase().includes(search.toLowerCase())
  );

  return (
    <div style={styles.panel}>
      <div style={styles.panelHeader}>
        <span style={{ color: DARK.red }}>⬢</span>
        <span>[ Step 5 – Process Explorer ]</span>
        <span style={{ marginLeft: "auto", color: DARK.dim }}>Sysinternals — [DESKTOP-EK1NTC5\Master] (Administrator)</span>
      </div>
      <div style={styles.statBox}>
        <div style={styles.stat}>Processes: <span style={styles.statVal()}>{PROCESSES.length}</span></div>
        <div style={styles.stat}>Alerts: <span style={styles.statVal(DARK.red)}>{PROCESSES.filter(p => p.alert).length}</span></div>
        <div style={styles.stat}>CPU Total: <span style={styles.statVal(DARK.yellow)}>~{PROCESSES.reduce((s,p) => s + (parseFloat(p.cpu)||0), 0).toFixed(2)}%</span></div>
      </div>
      <div style={styles.searchBar}>
        <span style={{ color: DARK.dim, fontSize: "11px" }}>FILTER:</span>
        <input style={styles.input} value={search} onChange={e => setSearch(e.target.value)} placeholder="Filter by name, company, or path..." />
      </div>
      <div style={styles.panelBody}>
        <table style={styles.table}>
          <thead>
            <tr>
              <th style={styles.th}>Process</th>
              <th style={{ ...styles.th, textAlign: "right" }}>CPU</th>
              <th style={{ ...styles.th, textAlign: "right" }}>Private Bytes</th>
              <th style={{ ...styles.th, textAlign: "right" }}>Working Set</th>
              <th style={{ ...styles.th, textAlign: "right" }}>PID</th>
              <th style={styles.th}>Company</th>
              <th style={styles.th}>Path</th>
            </tr>
          </thead>
          <tbody>
            {filtered.map((p, i) => {
              const isAlert = p.alert;
              const rowBg = selected === i ? "rgba(0,212,255,0.07)" : isAlert ? "rgba(255,68,68,0.07)" : i % 2 === 0 ? "rgba(0,0,0,0.12)" : "transparent";
              return (
                <tr key={i} style={{ background: rowBg, cursor: "pointer" }} onClick={() => setSelected(i === selected ? null : i)}>
                  <td style={{ ...styles.td(), color: isAlert ? DARK.red : DARK.white }}>{p.name}</td>
                  <td style={{ ...styles.td(), textAlign: "right", color: DARK.yellow, width: "60px" }}>{p.cpu ?? ""}</td>
                  <td style={{ ...styles.td(), textAlign: "right", color: DARK.dim, width: "100px" }}>{p.privBytes}</td>
                  <td style={{ ...styles.td(), textAlign: "right", color: DARK.dim, width: "100px" }}>{p.ws}</td>
                  <td style={{ ...styles.td(), textAlign: "right", color: DARK.magenta, width: "60px" }}>{p.pid}</td>
                  <td style={{ ...styles.td(), color: DARK.cyan, width: "160px" }}>{p.company}</td>
                  <td style={{ ...styles.td(), color: isAlert ? DARK.yellow : DARK.dim }}>{p.path}</td>
                </tr>
              );
            })}
          </tbody>
        </table>
      </div>
      {selected !== null && filtered[selected] && (
        <div style={{ padding: "10px 12px", borderTop: `1px solid ${DARK.border}`, fontSize: "11px", color: DARK.dim, background: "rgba(0,0,0,0.3)" }}>
          <span style={{ color: DARK.cyan }}>Selected: </span>
          <span style={{ color: DARK.white }}>{filtered[selected].name}</span>
          {filtered[selected].path && <> → <span style={{ color: DARK.yellow }}>{filtered[selected].path}</span></>}
        </div>
      )}
    </div>
  );
}

// ─── STEP 7: Last Activity Viewer ─────────────────────────────────────────────
function Step7LastActivity() {
  const [search, setSearch] = useState("");
  const [filterType, setFilterType] = useState("ALL");

  const types = ["ALL", ...Array.from(new Set(ACTIVITY_ENTRIES.map(e => e.desc)))];
  const filtered = ACTIVITY_ENTRIES.filter(e =>
    (filterType === "ALL" || e.desc === filterType) &&
    (e.filename.toLowerCase().includes(search.toLowerCase()) ||
     e.path.toLowerCase().includes(search.toLowerCase()) ||
     e.info.toLowerCase().includes(search.toLowerCase()))
  );

  return (
    <div style={styles.panel}>
      <div style={styles.panelHeader}>
        <span style={{ color: DARK.magenta }}>◆</span>
        <span>[ Step 7 – Last Activity Viewer ]</span>
        <span style={{ marginLeft: "auto", color: DARK.dim }}>NirSoft LastActivityView</span>
      </div>
      <div style={styles.statBox}>
        <div style={styles.stat}>Events: <span style={styles.statVal()}>{ACTIVITY_ENTRIES.length}</span></div>
        <div style={styles.stat}>Shown: <span style={styles.statVal(DARK.yellow)}>{filtered.length}</span></div>
        <div style={{ marginLeft: "auto", display: "flex", gap: "4px", flexWrap: "wrap" }}>
          {types.slice(0,4).map(t => (
            <button key={t} style={{ ...styles.btn(), fontSize: "10px", padding: "2px 8px", background: filterType === t ? "rgba(0,212,255,0.1)" : "transparent" }} onClick={() => setFilterType(t)}>{t}</button>
          ))}
        </div>
      </div>
      <div style={styles.searchBar}>
        <span style={{ color: DARK.dim, fontSize: "11px" }}>FILTER:</span>
        <input style={styles.input} value={search} onChange={e => setSearch(e.target.value)} placeholder="Filter by filename, path, or info..." />
      </div>
      <div style={styles.panelBody}>
        <table style={styles.table}>
          <thead>
            <tr>
              <th style={styles.th}>Action Time</th>
              <th style={styles.th}>Description</th>
              <th style={styles.th}>Filename</th>
              <th style={styles.th}>Full Path</th>
              <th style={styles.th}>More Information</th>
              <th style={{ ...styles.th, width: "40px" }}>Ext</th>
              <th style={styles.th}>Data Source</th>
            </tr>
          </thead>
          <tbody>
            {filtered.map((e, i) => (
              <tr key={i} style={{ background: i % 2 === 0 ? "rgba(0,0,0,0.12)" : "transparent" }}>
                <td style={{ ...styles.td(), color: DARK.cyan, width: "130px" }}>{e.time}</td>
                <td style={{ ...styles.td(), color: e.desc === "Task Run" ? DARK.yellow : DARK.white, width: "100px" }}>{e.desc}</td>
                <td style={{ ...styles.td(), color: DARK.white, width: "160px" }}>{e.filename}</td>
                <td style={{ ...styles.td(), color: DARK.dim }}>{e.path}</td>
                <td style={{ ...styles.td(), color: DARK.dim }}>{e.info}</td>
                <td style={{ ...styles.td(), color: DARK.magenta, width: "40px" }}>{e.ext}</td>
                <td style={{ ...styles.td(), color: DARK.dim }}>{e.src}</td>
              </tr>
            ))}
          </tbody>
        </table>
      </div>
    </div>
  );
}

// ─── MAIN APP ─────────────────────────────────────────────────────────────────
const STEPS = [
  { id: 1, label: "Step 1 — System Check" },
  { id: 2, label: "Step 2 — Module Scan (0–35)" },
  { id: 3, label: "Step 3 — BAM GUI Entries" },
  { id: 4, label: "Step 4 — Prefetch Viewer" },
  { id: 5, label: "Step 5 — Process Explorer" },
  { id: 7, label: "Step 7 — Last Activity View" },
];

export default function App() {
  const [activeStep, setActiveStep] = useState(1);
  const [completedSteps, setCompletedSteps] = useState(new Set());

  const handleStep = (id) => {
    setActiveStep(id);
    setCompletedSteps(prev => new Set([...prev, id]));
  };

  return (
    <div style={styles.app}>
      <style>{`
        * { box-sizing: border-box; scrollbar-width: thin; scrollbar-color: #1a2332 #060a0f; }
        ::-webkit-scrollbar { width: 6px; height: 6px; }
        ::-webkit-scrollbar-track { background: #060a0f; }
        ::-webkit-scrollbar-thumb { background: #1a2332; border-radius: 3px; }
        tr:hover { background: rgba(0,212,255,0.03) !important; }
        @keyframes pulse { 0%,100% { opacity: 1; } 50% { opacity: 0; } }
      `}</style>

      <div style={styles.header}>
        <pre style={styles.logo}>{ASCII_LOGO}</pre>
        <div style={styles.subtitle}>
          Forensic Scanner V3  —  READ ONLY. NOTHING IS DELETED.  |  35 scan modules  |  Scan Only Mode
        </div>
      </div>

      <div style={styles.stepsBar}>
        {STEPS.map(s => (
          <button
            key={s.id}
            style={styles.stepBtn(activeStep === s.id, completedSteps.has(s.id) && activeStep !== s.id)}
            onClick={() => handleStep(s.id)}
          >
            {completedSteps.has(s.id) && activeStep !== s.id ? "✓ " : ""}{s.label}
          </button>
        ))}
      </div>

      <div style={styles.content}>
        {activeStep === 1 && <Step1SystemCheck />}
        {activeStep === 2 && <Step2Modules />}
        {activeStep === 3 && <Step3BAM />}
        {activeStep === 4 && <Step4Prefetch />}
        {activeStep === 5 && <Step5ProcessExplorer />}
        {activeStep === 7 && <Step7LastActivity />}
      </div>
    </div>
  );
}
