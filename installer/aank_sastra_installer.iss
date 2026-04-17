; =====================================================================
;  Aank Sastra Software — Inno Setup Installer Script
;  Version: 1.0.0
;  This script creates a professional Windows installer that:
;    ✅ Installs all app files to Program Files
;    ✅ Creates a Desktop shortcut
;    ✅ Creates a Start Menu entry
;    ✅ Registers the app in Windows "Add/Remove Programs"
;    ✅ Provides a clean Uninstaller
; =====================================================================

#define MyAppName      "Aank Sastra"
#define MyAppVersion   "1.0.0"
#define MyAppPublisher "Aank Sastra"
#define MyAppURL       "https://aanksastra.com"
#define MyAppExeName   "aank_sastra_software.exe"
#define MyAppIcon      "..\windows\runner\resources\app_icon.ico"

[Setup]
; Unique Application ID — regenerate if forking
AppId={{A1B2C3D4-E5F6-7890-ABCD-EF1234567890}
AppName={#MyAppName}
AppVersion={#MyAppVersion}
AppPublisherURL={#MyAppURL}
AppSupportURL={#MyAppURL}
AppUpdatesURL={#MyAppURL}
AppPublisher={#MyAppPublisher}

; Install into Program Files
DefaultDirName={autopf}\{#MyAppName}
DefaultGroupName={#MyAppName}

; Output installer file settings
OutputDir=..\build\installer
OutputBaseFilename=AankSastra_Setup_v{#MyAppVersion}
SetupIconFile={#MyAppIcon}

; Compression
Compression=lzma2/ultra64
SolidCompression=yes
LZMAUseSeparateProcess=yes

; Windows installer settings
WizardStyle=modern
PrivilegesRequired=admin
ArchitecturesAllowed=x64compatible
ArchitecturesInstallIn64BitMode=x64compatible

; Uninstaller
UninstallDisplayIcon={app}\{#MyAppExeName}
UninstallDisplayName={#MyAppName}

; Minimum Windows version: Windows 10
MinVersion=10.0

; Show license if you have one (optional — comment out if no license file)
; LicenseFile=..\LICENSE

; Installer branding (optional custom wizard image)
; WizardImageFile=wizard_image.bmp
; WizardSmallImageFile=wizard_small.bmp

[Languages]
Name: "english"; MessagesFile: "compiler:Default.isl"

[Tasks]
; Desktop shortcut checkbox — checked by default
Name: "desktopicon"; Description: "{cm:CreateDesktopIcon}"; GroupDescription: "{cm:AdditionalIcons}"; Flags: unchecked
Name: "quicklaunchicon"; Description: "{cm:CreateQuickLaunchIcon}"; GroupDescription: "{cm:AdditionalIcons}"; Flags: unchecked; OnlyBelowVersion: 6.1; Check: not IsAdminInstallMode

[Files]
; Main executable
Source: "..\build\windows\x64\runner\Release\{#MyAppExeName}"; DestDir: "{app}"; Flags: ignoreversion

; All DLL dependencies and data files from the Release folder
Source: "..\build\windows\x64\runner\Release\*.dll";  DestDir: "{app}"; Flags: ignoreversion recursesubdirs createallsubdirs
Source: "..\build\windows\x64\runner\Release\data\*"; DestDir: "{app}\data"; Flags: ignoreversion recursesubdirs createallsubdirs

; Bundle Visual C++ Redistributable
Source: "vc_redist.x64.exe"; DestDir: "{tmp}"; Flags: deleteafterinstall

[Icons]
; Start Menu shortcut
Name: "{group}\{#MyAppName}";          Filename: "{app}\{#MyAppExeName}"; IconFilename: "{app}\{#MyAppExeName}"
Name: "{group}\Uninstall {#MyAppName}"; Filename: "{uninstallexe}"

; Desktop shortcut (only if user ticked the checkbox)
Name: "{autodesktop}\{#MyAppName}"; Filename: "{app}\{#MyAppExeName}"; Tasks: desktopicon

[Run]
; Launch the app after installation completes
Filename: "{app}\{#MyAppExeName}"; \
  Description: "{cm:LaunchProgram,{#StringChange(MyAppName, '&', '&&')}}"; \
  Flags: nowait postinstall skipifsilent

; Install VC++ Redistributable silently
Filename: "{tmp}\vc_redist.x64.exe"; \
  Parameters: "/install /quiet /norestart"; \
  Check: not VCInstalled; \
  StatusMsg: "Installing Microsoft Visual C++ Redistributable..."

[UninstallDelete]
; Clean up any leftover files after uninstall
Type: filesandordirs; Name: "{app}"

[Code]
// ---------------------------------------------------------------
// Optional: Detect if a previous version is installed and offer
// to uninstall it before installing the new one.
// ---------------------------------------------------------------
function InitializeSetup(): Boolean;
var
  UninstallPath: String;
  ResultCode: Integer;
begin
  Result := True;

  // Check registry for a previous installation
  if RegQueryStringValue(HKLM,
    'SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\{A1B2C3D4-E5F6-7890-ABCD-EF1234567890}_is1',
    'UninstallString', UninstallPath) then
  begin
    if MsgBox(
      'A previous version of Aank Sastra is already installed. ' +
      'It is recommended to uninstall it first.' + #13#10 +
      'Would you like to uninstall it now?',
      mbConfirmation, MB_YESNO) = IDYES then
    begin
      Exec(RemoveQuotes(UninstallPath), '/SILENT', '', SW_SHOW, ewWaitUntilTerminated, ResultCode);
    end;
  end;
end;

// Helper to check if VC++ Redist is installed
function VCInstalled(): Boolean;
begin
  // Check for VS 2015-2022 Redistributable (x64)
  Result := RegKeyExists(HKLM64, 'SOFTWARE\Microsoft\VisualStudio\14.0\VC\Runtimes\x64');
end;
