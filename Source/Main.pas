unit Main;

interface

uses
  Winapi.Windows, Winapi.Messages,
  System.SysUtils, System.Variants, System.Classes, System.IOUtils,
  Vcl.Graphics, Vcl.Controls, Vcl.Forms, Vcl.Dialogs,
  Vcl.StdCtrls, Vcl.ExtCtrls, Vcl.Menus,

  MouseJiggler, VersionInfo, JSONConfig, Vcl.Imaging.jpeg, Vcl.Imaging.pngimage;

type
  TMainForm = class(TForm)
    lblPattern: TLabel;
    lblMovement: TLabel;
    lblInterval: TLabel;
    cmbPattern: TComboBox;
    btnMovementDown: TButton;
    edtMovement: TEdit;
    btnMovementUp: TButton;
    btnIntervalDown: TButton;
    edtInterval: TEdit;
    btnIntervalUp: TButton;
    btnStartStop: TButton;
    btnExit: TButton;
    TrayIcon: TTrayIcon;
    TrayPopupMenu: TPopupMenu;
    miRestore: TMenuItem;
    miStartStop: TMenuItem;
    miSeparator: TMenuItem;
    miExit: TMenuItem;
    Image1: TImage;
    lblFeedback: TLabel;
    procedure FormCreate(Sender: TObject);
    procedure FormDestroy(Sender: TObject);
    procedure FormCloseQuery(Sender: TObject; var CanClose: Boolean);
    procedure FormResize(Sender: TObject);
    procedure cmbPatternChange(Sender: TObject);
    procedure btnMovementDownClick(Sender: TObject);
    procedure btnMovementUpClick(Sender: TObject);
    procedure btnIntervalDownClick(Sender: TObject);
    procedure btnIntervalUpClick(Sender: TObject);
    procedure btnStartStopClick(Sender: TObject);
    procedure btnExitClick(Sender: TObject);
    procedure TrayIconDblClick(Sender: TObject);
    procedure miRestoreClick(Sender: TObject);
    procedure miStartStopClick(Sender: TObject);
    procedure miExitClick(Sender: TObject);
  private
    FMouseJiggler: TMouseJiggler;
    FMovementIndex: Integer;
    FIntervalIndex: Integer;
    FAllowClose: Boolean;
    FConfig: TJSONConfig;
    FConfigFile: string;
    function ResolutionKey: string;
    procedure LoadConfig;
    procedure SaveConfig;
    procedure ChangeMovement(Delta: Integer);
    procedure ChangeInterval(Delta: Integer);
    procedure RestoreFromTray;
    procedure SetJiggling(Value: Boolean);
    procedure UpdateControls;
    procedure JigglerFeedback(const State: TJiggleState; const Value: string);
  public
    { Public declarations }
  end;

var
  MainForm: TMainForm;

implementation

{$R *.dfm}

const
  MovementOptions: array[0..4] of Integer = (5, 10, 15, 20, 25);
  IntervalOptions: array[0..4] of Integer = (10, 15, 30, 60, 120);

function TMainForm.ResolutionKey: string;
begin
  Result := Format('Resolution_%dx%d', [Screen.Width, Screen.Height]);
end;

procedure TMainForm.LoadConfig;
var
  key: string;
  l, t, w, h: Integer;
begin
  try
    FConfig.LoadFromFile(FConfigFile, True);
  except
    FConfig.Clear; // unreadable config is treated as no config
  end;

  key := ResolutionKey;
  try
    if not (FConfig.HasKey(key + '.Left') and FConfig.HasKey(key + '.Top') and
            FConfig.HasKey(key + '.Width') and FConfig.HasKey(key + '.Height')) then
      Exit;

    l := FConfig.GetInteger(key + '.Left', Left);
    t := FConfig.GetInteger(key + '.Top', Top);
    w := FConfig.GetInteger(key + '.Width', Width);
    h := FConfig.GetInteger(key + '.Height', Height);
  except
    Exit;
  end;

  if (w < 100) or (h < 100) or (w > Screen.DesktopWidth) or (h > Screen.DesktopHeight) then
    Exit;
  // Must lie on the virtual desktop spanning all monitors, not just the primary
  if (l < Screen.DesktopLeft) or (t < Screen.DesktopTop) or
     (l + w > Screen.DesktopLeft + Screen.DesktopWidth) or
     (t + h > Screen.DesktopTop + Screen.DesktopHeight) then
    Exit;

  Position := poDesigned;
  SetBounds(l, t, w, h);
end;

procedure TMainForm.SaveConfig;
var
  key: string;
  placement: TWindowPlacement;
  r: TRect;
begin
  if FConfig = nil then
    Exit;

  placement.length := SizeOf(placement);
  if HandleAllocated and GetWindowPlacement(Handle, @placement) then
    r := placement.rcNormalPosition
  else
    r := BoundsRect;

  key := ResolutionKey;
  FConfig.SetInteger(key + '.Left', r.Left);
  FConfig.SetInteger(key + '.Top', r.Top);
  FConfig.SetInteger(key + '.Width', r.Right - r.Left);
  FConfig.SetInteger(key + '.Height', r.Bottom - r.Top);

  try
    FConfig.SaveToFile(FConfigFile);
  except
    // failing to persist settings must not block closing
  end;
end;

procedure TMainForm.FormCreate(Sender: TObject);
begin
  Caption := 'Jiggler - Version ' + TVersionInfo.FileVersion;

  FConfig := TJSONConfig.Create;
  FConfigFile := TPath.Combine(ExtractFilePath(ParamStr(0)), 'Jiggler.json');
  LoadConfig;
  FMouseJiggler := TMouseJiggler.Create(Self);
  FMovementIndex := 2;
  FIntervalIndex := 1;
  FAllowClose := False;

  cmbPattern.Items.BeginUpdate;
  try
    cmbPattern.Items.Clear;
    cmbPattern.Items.Add('Up / Down');
    cmbPattern.Items.Add('Left / Right');
    cmbPattern.Items.Add('Random');
    cmbPattern.Items.Add('Return to start position');
  finally
    cmbPattern.Items.EndUpdate;
  end;
  cmbPattern.ItemIndex := Ord(jpRandom);

  FMouseJiggler.Pattern := TJigglePattern(cmbPattern.ItemIndex);
  FMouseJiggler.Movement := MovementOptions[FMovementIndex];
  FMouseJiggler.Interval := Cardinal(IntervalOptions[FIntervalIndex] * 1000);
  FMouseJiggler.OnFeedback := JigglerFeedback;

  lblFeedback.Caption := 'Version: ' + TVersionInfo.FileVersion;

  TrayIcon.Hint := Caption;
  TrayIcon.Icon.Assign(Application.Icon);
  TrayIcon.Visible := True;

  UpdateControls;
end;

procedure TMainForm.FormDestroy(Sender: TObject);
begin
  FMouseJiggler.Stop;
  FConfig.Free;
end;

procedure TMainForm.FormCloseQuery(Sender: TObject; var CanClose: Boolean);
begin
  if FAllowClose then
  begin
    SaveConfig;
    Exit;
  end;

  CanClose := False;
  WindowState := wsMinimized;
  Hide;
  TrayIcon.Visible := True;
end;

procedure TMainForm.FormResize(Sender: TObject);
begin
  if WindowState = wsMinimized then
  begin
    Hide;
    TrayIcon.Visible := True;
  end;
end;

procedure TMainForm.cmbPatternChange(Sender: TObject);
begin
  if cmbPattern.ItemIndex >= 0 then
    FMouseJiggler.Pattern := TJigglePattern(cmbPattern.ItemIndex);
end;

procedure TMainForm.btnMovementDownClick(Sender: TObject);
begin
  ChangeMovement(-1);
end;

procedure TMainForm.btnMovementUpClick(Sender: TObject);
begin
  ChangeMovement(1);
end;

procedure TMainForm.btnIntervalDownClick(Sender: TObject);
begin
  ChangeInterval(-1);
end;

procedure TMainForm.btnIntervalUpClick(Sender: TObject);
begin
  ChangeInterval(1);
end;

procedure TMainForm.btnStartStopClick(Sender: TObject);
begin
  SetJiggling(not FMouseJiggler.IsJiggling);
end;

procedure TMainForm.btnExitClick(Sender: TObject);
begin
  FAllowClose := True;
  Close;
end;

procedure TMainForm.TrayIconDblClick(Sender: TObject);
begin
  RestoreFromTray;
end;

procedure TMainForm.miRestoreClick(Sender: TObject);
begin
  RestoreFromTray;
end;

procedure TMainForm.miStartStopClick(Sender: TObject);
begin
  SetJiggling(not FMouseJiggler.IsJiggling);
end;

procedure TMainForm.miExitClick(Sender: TObject);
begin
  btnExitClick(Sender);
end;

procedure TMainForm.ChangeMovement(Delta: Integer);
begin
  Inc(FMovementIndex, Delta);
  if FMovementIndex < Low(MovementOptions) then
    FMovementIndex := Low(MovementOptions)
  else if FMovementIndex > High(MovementOptions) then
    FMovementIndex := High(MovementOptions);

  FMouseJiggler.Movement := MovementOptions[FMovementIndex];
  UpdateControls;
end;

procedure TMainForm.ChangeInterval(Delta: Integer);
begin
  Inc(FIntervalIndex, Delta);
  if FIntervalIndex < Low(IntervalOptions) then
    FIntervalIndex := Low(IntervalOptions)
  else if FIntervalIndex > High(IntervalOptions) then
    FIntervalIndex := High(IntervalOptions);

  FMouseJiggler.Interval := Cardinal(IntervalOptions[FIntervalIndex] * 1000);
  UpdateControls;
end;

procedure TMainForm.RestoreFromTray;
begin
  Show;
  WindowState := wsNormal;
  Application.Restore;
  BringToFront;
end;

procedure TMainForm.SetJiggling(Value: Boolean);
begin
  if Value then
    FMouseJiggler.Start
  else
    FMouseJiggler.Stop;

  UpdateControls;
end;

procedure TMainForm.UpdateControls;
begin
  edtMovement.Text := MovementOptions[FMovementIndex].ToString;
  edtInterval.Text := IntervalOptions[FIntervalIndex].ToString;

  btnMovementDown.Enabled := FMovementIndex > Low(MovementOptions);
  btnMovementUp.Enabled := FMovementIndex < High(MovementOptions);
  btnIntervalDown.Enabled := FIntervalIndex > Low(IntervalOptions);
  btnIntervalUp.Enabled := FIntervalIndex < High(IntervalOptions);

  if FMouseJiggler.IsJiggling then
  begin
    btnStartStop.Caption := 'Stop';
    miStartStop.Caption := 'Stop';
  end
  else
  begin
    btnStartStop.Caption := 'Start';
    miStartStop.Caption := 'Start';
  end;
end;

procedure TMainForm.JigglerFeedback(const State: TJiggleState; const Value: string);
begin
  case State of
    jsError:    lblFeedback.Font.Color := clRed ;
    jsWarning:  lblFeedback.Font.Color := clWebDarkOrange ;
    jsInfo:     lblFeedback.Font.color := clWebDodgerBlue;
  end;

  lblFeedback.Caption := Value;
end;

end.
