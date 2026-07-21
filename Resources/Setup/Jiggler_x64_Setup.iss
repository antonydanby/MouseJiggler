; -- Jiggler_x64_Setup.iss --
; Copy _x64 executable into same folder as this scripts

[Setup]
AppName=Jiggler
AppVersion=1.0.0.3
WizardStyle=modern dynamic
DefaultDirName={autopf}\Jiggler
DefaultGroupName=My Program
UninstallDisplayIcon={app}\Jiggler.exe
Compression=lzma2
SolidCompression=yes
OutputDir=.
; "ArchitecturesAllowed=x64compatible" specifies that Setup cannot run
; on anything but x64 and Windows 11 on Arm.
ArchitecturesAllowed=x64compatible
; "ArchitecturesInstallIn64BitMode=x64compatible" requests that the
; install be done in "64-bit mode" on x64 or Windows 11 on Arm,
; meaning it should use the native 64-bit Program Files directory and
; the 64-bit view of the registry.
ArchitecturesInstallIn64BitMode=x64compatible

[Files]
Source: "Jiggler_x64.exe"; DestDir: "{app}"; DestName: "Jiggler.exe"
; Source: "MyProg.chm"; DestDir: "{app}"
; Source: "Readme.txt"; DestDir: "{app}"; Flags: isreadme

[Icons]
Name: "{group}\My Program"; Filename: "{app}\Jiggler.exe"
