unit SeqPause;

interface

uses Classes, SeqBaseDialog,
  CastleVectors, CastleUIControls, CastleControls, CastleKeysMouse,
  SeqExhibiter;

type
  TSeqPause = class(TCastleView)
  strict private
    type
      TSeqPauseDialog = class(TSeqBaseDialog)
      public
        function Press(const Event: TInputPressRelease): Boolean; override;
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

  FDialog:= TSeqPauseDialog.CreateNew('castle-data:/pause.castle-user-interface', FreeAtStop);
  FDialog.Anchor(hpMiddle);
  FDialog.Anchor(vpMiddle);
  FDialog.FullSize:= True;
  FDialog.Title:= 'Timer Paused';
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
