; -- Jiggler_x86_Setup.iss --
; Copy _x86 executable into same folder as this scripts


[Setup]
AppName=Jiggler
AppVersion=1.0.0.0
WizardStyle=modern dynamic
DefaultDirName={autopf}\Jiggler
DefaultGroupName=My Program
UninstallDisplayIcon={app}\Jiggler.exe
Compression=lzma2
SolidCompression=yes
OutputDir=.

[Files]
Source: "Jiggler_x86.exe"; DestDir: "{app}"; DestName: "Jiggler.exe"
; Source: "MyProg.chm"; DestDir: "{app}"
; Source: "Readme.txt"; DestDir: "{app}"; Flags: isreadme

[Icons]
Name: "{group}\My Program"; Filename: "{app}\Jiggler.exe"

