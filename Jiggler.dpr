program Jiggler;

uses
  Winapi.Windows,
  Vcl.Forms,
  Main in 'Source\Main.pas' {MainForm},
  MouseJiggler in 'Source\MouseJiggler.pas',
  VersionInfo in 'Source\VersionInfo.pas',
  JSONConfig in 'Source\JSONConfig.pas';

{$R *.res}

var
  InstanceMutex: THandle;

begin
  InstanceMutex := CreateMutex(nil, True, 'Local\JigglerSingleInstanceMutex');
  if (InstanceMutex <> 0) and (GetLastError = ERROR_ALREADY_EXISTS) then
  begin
    MessageBox(0, 'You can only run one instance of Jiggler at any time!', 'Jiggler', MB_OK or MB_ICONINFORMATION);
    CloseHandle(InstanceMutex);
    Exit;
  end;

  try
    Application.Initialize;
    Application.MainFormOnTaskbar := True;
    Application.CreateForm(TMainForm, MainForm);
  Application.Run;
  finally
    if InstanceMutex <> 0 then
      CloseHandle(InstanceMutex);
  end;
end.
