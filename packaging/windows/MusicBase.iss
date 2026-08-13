#define AppVersion "1.0.0"

[Setup]
AppId={{C1D5F55B-9C7E-4C2A-9E8B-0B3B74C6A2D1}
AppName=Music Base
AppVersion={#AppVersion}
AppPublisher=Music Base
DefaultDirName={localappdata}\Programs\Music Base
DefaultGroupName=Music Base
DisableProgramGroupPage=yes
PrivilegesRequired=lowest
ArchitecturesAllowed=x64compatible
ArchitecturesInstallIn64BitMode=x64compatible
OutputBaseFilename=MusicBase-Setup
SetupIconFile=..\..\windows\runner\resources\app_icon.ico
Compression=lzma
SolidCompression=yes
WizardStyle=modern
UninstallDisplayName=Music Base

[Languages]
Name: "english"; MessagesFile: "compiler:Default.isl"

[Tasks]
Name: "startmenu"; Description: "Create a Start Menu shortcut"; GroupDescription: "Additional shortcuts:"; Flags: checkedonce
Name: "desktop"; Description: "Create a desktop shortcut"; GroupDescription: "Additional shortcuts:"

[Files]
Source: "..\..\build\windows\x64\runner\Release\*"; DestDir: "{app}"; Flags: ignoreversion recursesubdirs createallsubdirs

[Icons]
Name: "{autoprograms}\Music Base"; Filename: "{app}\music_base.exe"; Tasks: startmenu
Name: "{autodesktop}\Music Base"; Filename: "{app}\music_base.exe"; Tasks: desktop

[Run]
Filename: "{app}\music_base.exe"; Description: "Launch Music Base"; Flags: nowait postinstall skipifsilent
