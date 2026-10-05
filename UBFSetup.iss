#ifndef SetupVersion
  #define SetupVersion "1.0.7"
#endif

#ifndef SetupAppId
  #define SetupAppId "{{5D6F87B7-092D-4D53-8B1D-B6400162E6B0}"
#endif

#ifndef SetupAppName
  #define SetupAppName "UBF Launcher"
#endif

#ifndef SetupOutputDir
  #define SetupOutputDir "dist"
#endif

#ifndef SetupOutputName
  #define SetupOutputName "UBFSetup"
#endif

#ifndef LauncherPayload
  #define LauncherPayload "staging\launcher"
#endif

[Setup]
AppId={#SetupAppId}
AppName={#SetupAppName}
AppVersion={#SetupVersion}
AppVerName={#SetupAppName} {#SetupVersion}
AppPublisher=RPmods
AppPublisherURL=https://github.com/RPmods
AppSupportURL=https://github.com/RPmods/ubf-laucher
AppUpdatesURL=https://github.com/RPmods/ubf-laucher/releases
DefaultDirName={localappdata}\Programs\{#SetupAppName}
DefaultGroupName={#SetupAppName}
DisableProgramGroupPage=yes
DisableWelcomePage=no
UninstallDisplayName={#SetupAppName}
UninstallDisplayIcon={app}\UBFLauncher.exe
OutputDir={#SetupOutputDir}
OutputBaseFilename={#SetupOutputName}
SetupIconFile=assets\logo.ico
ArchitecturesAllowed=x64compatible
ArchitecturesInstallIn64BitMode=x64compatible
PrivilegesRequired=lowest
PrivilegesRequiredOverridesAllowed=commandline
CloseApplications=yes
RestartApplications=no
Compression=lzma2/ultra64
SolidCompression=yes
WizardStyle=modern dynamic
WizardSizePercent=100
WizardKeepAspectRatio=yes
WizardImageFile=assets\wizard-panel.png
WizardSmallImageFile=assets\wizard-mark.png
DisableReadyPage=yes

[Languages]
Name: "spanish"; MessagesFile: "compiler:Languages\Spanish.isl"

[Files]
Source: "{#LauncherPayload}\*"; DestDir: "{app}"; Flags: ignoreversion recursesubdirs createallsubdirs

[InstallDelete]
Type: files; Name: "{app}\UBFLauncher-update.zip"
Type: files; Name: "{app}\UBFLauncher-update.zip.download-*"

[Icons]
Name: "{autodesktop}\{#SetupAppName}"; Filename: "{app}\UBFLauncher.exe"; WorkingDir: "{app}"; IconFilename: "{app}\UBFLauncher.exe"
Name: "{autoprograms}\{#SetupAppName}\{#SetupAppName}"; Filename: "{app}\UBFLauncher.exe"; WorkingDir: "{app}"; IconFilename: "{app}\UBFLauncher.exe"
Name: "{autoprograms}\{#SetupAppName}\Desinstalar {#SetupAppName}"; Filename: "{uninstallexe}"

[Run]
Filename: "{app}\UBFLauncher.exe"; Description: "Abrir UBF Launcher"; Flags: nowait postinstall skipifsilent

[UninstallDelete]
Type: filesandordirs; Name: "{app}\*"
