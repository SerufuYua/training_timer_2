unit SeqPause;

interface

uses Classes,
  CastleVectors, CastleUIControls, CastleControls, CastleKeysMouse,
  SeqExhibiter;

type
  TSeqPause = class(TCastleView)
  strict private
    type
      TSeqPauseDialog = class(TCastleUserInterface)
      private
        ExhibiterList: TSeqExhibiter;
        ButtonClose: TCastleButton;
        procedure ClickControl(Sender: TObject);
        procedure ShowClose;
        procedure DoClose(Sender: TObject);
      public
        Closed: Boolean;
        constructor Create(AOwner: TComponent); override;
        function Press(const Event: TInputPressRelease): Boolean; override;
        procedure Start;
      end;
    var
      FDialog: TSeqPauseDialog;
  public
    constructor CreateUntilStopped;
    procedure Start; override;
    procedure Update(const SecondsPassed: Single; var HandleInput: boolean); override;
  end;

implementation

uses
  SysUtils, CastleComponentSerialize, CastleFonts;

{ ========= ------------------------------------------------------------------ }
{ TSeqListBoxDialog ---------------------------------------------------------- }
{ ========= ------------------------------------------------------------------ }

constructor TSeqPause.TSeqPauseDialog.Create(AOwner: TComponent);
var
  UiOwner: TComponent;
  Ui: TCastleUserInterface;
begin
  inherited;
  Closed:= False;

  // UiOwner is useful to keep reference to all components loaded from the design
  UiOwner := TComponent.Create(Self);

  { Load designed user interface }
  Ui := UserInterfaceLoad('castle-data:/pause.castle-user-interface', UiOwner);
  InsertFront(Ui);

  { Find components, by name, that we need to access from code }
  ExhibiterList:= UiOwner.FindRequiredComponent('ExhibiterList') as TSeqExhibiter;
  ButtonClose:= UiOwner.FindRequiredComponent('ButtonClose') as TCastleButton;
  ButtonClose.OnClick:= {$ifdef FPC}@{$endif}ClickControl;
end;

procedure TSeqPause.TSeqPauseDialog.Start;
begin
  ExhibiterList.ShowType:= Appear;
  ExhibiterList.ExecuteOnce:= True;
end;

function TSeqPause.TSeqPauseDialog.Press(const Event: TInputPressRelease): Boolean;
begin
  Result:= inherited;
  if Result then Exit; // allow the ancestor to handle keys

  { return pause }
  if (Event.IsKey(TKey.keyEscape) OR
      Event.IsKey(TKey.keySpace) OR
      Event.IsKey(TKey.keyPause) OR
      Event.IsKey(TKey.keyEnter)) then
  begin
    ShowClose;
    Exit(True);
  end;
end;

procedure TSeqPause.TSeqPauseDialog.ClickControl(Sender: TObject);
begin
  ShowClose;
end;

procedure TSeqPause.TSeqPauseDialog.ShowClose;
begin
  ExhibiterList.ShowType:= Disappear;
  ExhibiterList.OnFinish:= {$ifdef FPC}@{$endif}DoClose;
  ExhibiterList.ExecuteOnce:= True;
end;

procedure TSeqPause.TSeqPauseDialog.DoClose(Sender: TObject);
begin
  Closed:= True;
end;

{ ========= ------------------------------------------------------------------ }
{ TSeqPause ------------------------------------------------------------ }
{ ========= ------------------------------------------------------------------ }

constructor TSeqPause.CreateUntilStopped;
begin
  inherited CreateUntilStopped;
  DesignUrl:= 'castle-data:/bgwin.castle-user-interface';
end;

procedure TSeqPause.Start;
begin
  inherited;
  InterceptInput:= True;

  FDialog:= TSeqPauseDialog.Create(FreeAtStop);
  FDialog.Anchor(hpMiddle);
  FDialog.Anchor(vpMiddle);
  FDialog.FullSize:= True;
  InsertFront(FDialog);
  FDialog.Start;
end;

procedure TSeqPause.Update(const SecondsPassed: Single; var HandleInput: boolean);
begin
  inherited;

  if FDialog.Closed then
    Container.PopView(Self);
end;

end.
