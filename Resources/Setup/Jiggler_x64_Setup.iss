; -- Jiggler_x64_Setup.iss --
; Copy _x64 executable into same folder as this scripts

[Setup]
AppName=Jiggler
AppVersion=1.0.0.5
WizardStyle=modern dynamic
DefaultDirName={autopf}\Jiggler
DefaultGroupName=My Program
UninstallDisplayIcon={app}\Jiggler.exe
Compression=lzma2
SolidCompression=yes
OutputDir=.
ArchitecturesAllowed=x64compatible
ArchitecturesInstallIn64BitMode=x64compatible

DisableWelcomePage=yes
LicenseFile=license.txt
;InfoBeforeFile=readme.txt
UserInfoPage=no
DisableDirPage=no
DisableProgramGroupPage=yes
;InfoAfterFile=readme.txt

[Files]
Source: "Jiggler_x64.exe"; DestDir: "{app}"; DestName: "Jiggler.exe"
Source: "Readme.txt"; DestDir: "{app}"; Flags: isreadme

[Icons]
Name: "{group}\My Program"; Filename: "{app}\Jiggler.exe"
