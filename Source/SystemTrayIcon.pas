unit SystemTrayIcon;

interface

uses
  System.Classes, Vcl.Forms, Vcl.Menus, Winapi.Messages, Winapi.Windows, Winapi.ShellAPI, Vcl.Graphics,
  Vcl.Controls, System.SysUtils;

const
  WM_TRAYICON = WM_USER + 1000;
  TRAY_ID = 1;

type
  TSystemTrayIcon = class(TComponent)
  private
    fApplicationForm: TForm;
    fPopupMenu: TPopupMenu;
    fIcon: TIcon;
    fHint: string;
    fIsIconVisible: Boolean;
    fWindowHandle: HWND; // Internal handle to receive messages
    fRestoreOnLeftClick: Boolean;
    procedure SetIcon(const Value: TIcon);
    procedure SetHint(const Value: string);
    procedure SetPopupMenu(const Value: TPopupMenu);
    // The internal window procedure
    procedure WndProc(var Msg: TMessage);
    procedure UpdateTrayIcon(Operation: UINT);
  protected
    procedure Loaded; override;
    procedure Notification(AComponent: TComponent; Operation: TOperation); override;
  public
    constructor Create(AOwner: TComponent); override;
    destructor Destroy; override;
    procedure ShowIcon;
    procedure HideIcon;
    procedure RestoreApplication;
  published
    property ApplicationForm: TForm read fApplicationForm write fApplicationForm;
    property Icon: TIcon read fIcon write SetIcon;
    property Hint: string read fHint write SetHint;
    property PopupMenu: TPopupMenu read fPopupMenu write SetPopupMenu;
    property RestoreOnLeftClick: Boolean read fRestoreOnLeftClick write fRestoreOnLeftClick default True;
  end;

procedure Register;

implementation

procedure Register;
begin
  RegisterComponents('l53n', [TSystemTrayIcon]);
end;

{ TSystemTrayIcon }

constructor TSystemTrayIcon.Create(AOwner: TComponent);
begin
  inherited Create(AOwner);
  fIcon := TIcon.Create;
  fIsIconVisible := False;
  fRestoreOnLeftClick := True; // Default to standard behavior
  // Create a hidden window to receive tray messages
  fWindowHandle := AllocateHWnd(WndProc);
end;

destructor TSystemTrayIcon.Destroy;
begin
  HideIcon;
  if fWindowHandle <> 0 then
    DeallocateHWnd(fWindowHandle);
  fIcon.Free;
  inherited Destroy;
end;

procedure TSystemTrayIcon.WndProc(var Msg: TMessage);
var
  P: TPoint;
begin
  if Msg.Msg = WM_TRAYICON then
  begin
    case Msg.LParam of
      WM_LBUTTONUP: // Single left click
        begin
          if fRestoreOnLeftClick then
            RestoreApplication;
        end;

      WM_LBUTTONDBLCLK: // Double left click
        begin
          // If not already restored by single click, restore now
          if not fRestoreOnLeftClick then
            RestoreApplication;
        end;

      WM_RBUTTONUP: // Right click
        begin
          if Assigned(fPopupMenu) then
          begin
            GetCursorPos(P);
            // Required so the menu disappears when clicking away
            SetForegroundWindow(fWindowHandle);
            fPopupMenu.Popup(P.X, P.Y);
            PostMessage(fWindowHandle, WM_NULL, 0, 0);
          end;
        end;
    end;
  end
  else
    Msg.Result := DefWindowProc(fWindowHandle, Msg.Msg, Msg.WParam, Msg.LParam);
end;

procedure TSystemTrayIcon.Loaded;
begin
  inherited Loaded;
  if (fApplicationForm = nil) and (Owner is TForm) then
    fApplicationForm := TForm(Owner);
end;

procedure TSystemTrayIcon.Notification(AComponent: TComponent; Operation: TOperation);
begin
  inherited Notification(AComponent, Operation);
  if Operation = opRemove then
  begin
    if AComponent = fPopupMenu then
      fPopupMenu := nil;
    if AComponent = fApplicationForm then
      fApplicationForm := nil;
  end;
end;

procedure TSystemTrayIcon.SetIcon(const Value: TIcon);
begin
  fIcon.Assign(Value);
  if fIsIconVisible then UpdateTrayIcon(NIM_MODIFY);
end;

procedure TSystemTrayIcon.SetHint(const Value: string);
begin
  if fHint <> Value then
  begin
    fHint := Value;
    if fIsIconVisible then UpdateTrayIcon(NIM_MODIFY);
  end;
end;

procedure TSystemTrayIcon.SetPopupMenu(const Value: TPopupMenu);
begin
  if fPopupMenu <> Value then
  begin
    if fPopupMenu <> nil then fPopupMenu.RemoveFreeNotification(Self);
    fPopupMenu := Value;
    if fPopupMenu <> nil then fPopupMenu.FreeNotification(Self);
  end;
end;

procedure TSystemTrayIcon.UpdateTrayIcon(Operation: UINT);
var
  NID: TNotifyIconData;
begin
  ZeroMemory(@NID, SizeOf(NID));
  NID.cbSize := SizeOf(NID);
  // Route messages to our internal hidden window, not the Form
  NID.Wnd := fWindowHandle;
  NID.uID := TRAY_ID;
  NID.uFlags := NIF_MESSAGE or NIF_ICON or NIF_TIP;
  NID.uCallbackMessage := WM_TRAYICON;

  if fIcon.HandleAllocated then
    NID.hIcon := fIcon.Handle
  else
    NID.hIcon := Application.Icon.Handle;

  StrPLCopy(NID.szTip, fHint, Length(NID.szTip) - 1);

  Shell_NotifyIcon(Operation, @NID);
end;

procedure TSystemTrayIcon.ShowIcon;
begin
  if not fIsIconVisible then
  begin
    UpdateTrayIcon(NIM_ADD);
    fIsIconVisible := True;
  end;
end;

procedure TSystemTrayIcon.HideIcon;
begin
  if fIsIconVisible then
  begin
    UpdateTrayIcon(NIM_DELETE);
    fIsIconVisible := False;
  end;
end;

procedure TSystemTrayIcon.RestoreApplication;
begin
  if Assigned(fApplicationForm) then
  begin
    fApplicationForm.Show;
    fApplicationForm.WindowState := wsNormal;
    fApplicationForm.BringToFront;
    HideIcon;
  end;
end;

end.
