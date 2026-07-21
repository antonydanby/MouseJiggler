unit MouseJiggler;

interface

uses
  System.Classes, System.SysUtils, Vcl.ExtCtrls, Winapi.Windows;

type
  TJigglePattern = (jpUpDown, jpLeftRight, jpRandom, jpReturnToStartPos);
  TJiggleState = (jsError, jsWarning, jsInfo);
  TJiggleFeedbackEvent = procedure(const State: TJiggleState; const Value: string) of object;

  TMouseJiggler = class(TComponent)
  private
    FTimer: TTimer;
    FMovement: Integer;
    FInterval: Cardinal;
    FPattern: TJigglePattern;
    FIsJiggling: Boolean;
    FStartX: Integer;
    FStartY: Integer;
    FStepToggle: Boolean;
    FOnFeedback: TJiggleFeedbackEvent;
    procedure SetInterval(const Value: Cardinal);
    procedure SetMovement(const Value: Integer);
    procedure OnTimerTick(Sender: TObject);
    procedure MoveMouseRelative(DX, DY: Integer);
    procedure MoveMouseAbsolute(X, Y: Integer);
    procedure DoFeedback(const State: TJiggleState; const Value: string);
  public
    constructor Create(AOwner: TComponent); override;
    destructor Destroy; override;
    procedure Start;
    procedure Stop;
  published
    property Movement: Integer read FMovement write SetMovement default 2;
    property Interval: Cardinal read FInterval write SetInterval default 1000;
    property Pattern: TJigglePattern read FPattern write FPattern default jpRandom;
    property IsJiggling: Boolean read FIsJiggling;
    property OnFeedback: TJiggleFeedbackEvent read FOnFeedback write FOnFeedback;
  end;

implementation

constructor TMouseJiggler.Create(AOwner: TComponent);
begin
  inherited Create(AOwner);
  FMovement := 2;
  FInterval := 1000;
  FPattern := jpRandom;
  FIsJiggling := False;
  FStepToggle := False;

  FTimer := TTimer.Create(Self);
  FTimer.Enabled := False;
  FTimer.Interval := FInterval;
  FTimer.OnTimer := OnTimerTick;
end;

destructor TMouseJiggler.Destroy;
begin
  Stop;
  FOnFeedback := nil;
  FTimer.Free;
  inherited Destroy;
end;

procedure TMouseJiggler.DoFeedback(const State: TJiggleState; const Value: string);
begin
  if Assigned(FOnFeedback) then FOnFeedback(State, Value);
end;

procedure TMouseJiggler.SetInterval(const Value: Cardinal);
begin
  if FInterval <> Value then
  begin
    FInterval := Value;
    FTimer.Interval := FInterval;
  end;
end;

procedure TMouseJiggler.SetMovement(const Value: Integer);
begin
  if Value < 0 then
  begin
    FMovement := Abs(Value);
    DoFeedback(jsWarning, 'Negative movement value converted to positive.');
  end
  else
    FMovement := Value;
end;

procedure TMouseJiggler.Start;
var
  CursorPos: TPoint;
begin
  if FIsJiggling then Exit;

  // Capture the initial position for patterns that rely on it
  if GetCursorPos(CursorPos) then
  begin
    FStartX := CursorPos.X;
    FStartY := CursorPos.Y;
  end
  else
    DoFeedback(jsWarning, SysErrorMessage(GetLastError));

  FStepToggle := False;
  FTimer.Enabled := True;
  FIsJiggling := True;
  DoFeedback(jsInfo, 'Mouse jiggler started.');
end;

procedure TMouseJiggler.Stop;
begin
  if not FIsJiggling then Exit;

  FTimer.Enabled := False;
  FIsJiggling := False;
  DoFeedback(jsInfo, 'Mouse jiggler stopped.');
end;

procedure TMouseJiggler.MoveMouseRelative(DX, DY: Integer);
var
  Input: TInput;
begin
  ZeroMemory(@Input, SizeOf(TInput));
  Input.Itype := INPUT_MOUSE;
  Input.mi.dx := DX;
  Input.mi.dy := DY;
  Input.mi.dwFlags := MOUSEEVENTF_MOVE;

  if SendInput(1, Input, SizeOf(TInput)) <> 1
    then DoFeedback(jsError, SysErrorMessage(GetLastError))
    else DoFeedback(jsInfo, Format('Mouse moved relatively by (%d, %d).', [DX, DY]));
end;

procedure TMouseJiggler.MoveMouseAbsolute(X, Y: Integer);
var
  Input: TInput;
begin
  ZeroMemory(@Input, SizeOf(TInput));
  Input.Itype := INPUT_MOUSE;
  // Convert pixels to normalized absolute coordinates (0 to 65535)
  Input.mi.dx := MulDiv(X, 65535, GetSystemMetrics(SM_CXSCREEN));
  Input.mi.dy := MulDiv(Y, 65535, GetSystemMetrics(SM_CYSCREEN));
  Input.mi.dwFlags := MOUSEEVENTF_MOVE or MOUSEEVENTF_ABSOLUTE;

  if SendInput(1, Input, SizeOf(TInput)) <> 1
    then DoFeedback(jsError, SysErrorMessage(GetLastError))
    else DoFeedback(jsInfo, Format('Mouse moved to absolute position (%d, %d).', [X, Y]))
end;

procedure TMouseJiggler.OnTimerTick(Sender: TObject);
var
  DX, DY: Integer;
  CursorPos: TPoint;
begin
  DX := 0;
  DY := 0;
  FStepToggle := not FStepToggle;

  case FPattern of
    jpUpDown:
      begin
        if FStepToggle then DY := FMovement else DY := -FMovement;
        MoveMouseRelative(DX, DY);
      end;

    jpLeftRight:
      begin
        if FStepToggle then DX := FMovement else DX := -FMovement;
        MoveMouseRelative(DX, DY);
      end;

    jpRandom:
      begin
        // Randomly choose direction -Movement, 0, or +Movement
        DX := (Random(3) - 1) * FMovement;
        DY := (Random(3) - 1) * FMovement;
        MoveMouseRelative(DX, DY);
      end;

    jpReturnToStartPos:
      begin
        if GetCursorPos(CursorPos) then
        begin
          // Only jiggle if the user hasn't actively hijacked the mouse elsewhere
          if (Abs(CursorPos.X - FStartX) <= FMovement) and (Abs(CursorPos.Y - FStartY) <= FMovement) then
          begin
            if FStepToggle then
              MoveMouseAbsolute(FStartX + FMovement, FStartY + FMovement)
            else
              MoveMouseAbsolute(FStartX, FStartY);
          end
          else
          begin
            // If user moved the mouse away, reset the anchor point to the new location
            FStartX := CursorPos.X;
            FStartY := CursorPos.Y;
          end;
        end;
      end;
  end;
end;

end.
