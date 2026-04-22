unit SeqConfirm;

interface

uses
  SysUtils, Classes, SeqBaseDialog,
  CastleVectors, CastleUIControls, CastleControls, SeqExhibiter;

type
  TSeqConfirm = class(TCastleView)
  strict private
    type
      TSeqConfirmDialog = class(TSeqBaseDialog)
      protected
        FOnReturnOk: TNotifyEvent;
        LabelQuestion: TCastleLabel;
        ButtonSet: TCastleButton;
        procedure ClickControl(Sender: TObject);
        procedure SetQuestion(AValue: TStringArray);
      public
        constructor CreateNew(const AUrl: String; AOwner: TComponent); override;

        property Question: TStringArray write SetQuestion;
      end;
    var
      FTitle: String;
      FQuestion: TStringArray;
      FOnReturnOk: TNotifyEvent;
      FDialog: TSeqConfirmDialog;
  public
    constructor CreateUntilStopped(AQuestion: TStringArray; ATitle: String; AOnReturnOk: TNotifyEvent);
    procedure Start; override;
    procedure Update(const SecondsPassed: Single; var HandleInput: boolean); override;
  end;

implementation

uses
  CastleComponentSerialize, CastleFonts, GameSound;

{ ========= ------------------------------------------------------------------ }
{ TSeqConfirmDialog ---------------------------------------------------------- }
{ ========= ------------------------------------------------------------------ }

constructor TSeqConfirm.TSeqConfirmDialog.CreateNew(const AUrl: String; AOwner: TComponent);
begin
  inherited;

  { Find components, by name, that we need to access from code }
  LabelQuestion:= FUiOwner.FindRequiredComponent('LabelQuestion') as TCastleLabel;
  ButtonSet:= FUiOwner.FindRequiredComponent('ButtonSet') as TCastleButton;
  ButtonSet.OnClick:= {$ifdef FPC}@{$endif}ClickControl;
  ButtonSet.OnInternalMouseEnter:= {$ifdef FPC}@{$endif}ControlHover;
end;

procedure TSeqConfirm.TSeqConfirmDialog.SetQuestion(AValue: TStringArray);
var
  line: String;
begin
  LabelQuestion.Text.Clear;

  for line in AValue do
    LabelQuestion.Text.Add(line);
end;

procedure TSeqConfirm.TSeqConfirmDialog.ClickControl(Sender: TObject);
var
  button: TCastleButton;
begin
  if NOT (Sender is TCastleButton) then Exit;
  button:= Sender as TCastleButton;

  if ((button.Name = 'ButtonSet') AND Assigned(FOnReturnOk)) then
  begin
    PlaySfx(TSfxType.ClickOk);
    FOnReturnOk(self);
  end;

  ShowClose;
end;

{ ========= ------------------------------------------------------------------ }
{ TSeqConfirm ------------------------------------------------------------ }
{ ========= ------------------------------------------------------------------ }

constructor TSeqConfirm.CreateUntilStopped(AQuestion: TStringArray; ATitle: String; AOnReturnOk: TNotifyEvent);
begin
  inherited CreateUntilStopped;
  FTitle:= ATitle;
  FQuestion:= AQuestion;
  FOnReturnOk:= AOnReturnOk;
  DesignUrl:= 'castle-data:/bgwin.castle-user-interface';
end;

procedure TSeqConfirm.Start;
begin
  inherited;
  InterceptInput:= True;

  FDialog:= TSeqConfirmDialog.CreateNew('castle-data:/confirm.castle-user-interface', FreeAtStop);
  FDialog.Anchor(hpMiddle);
  FDialog.Anchor(vpMiddle);
  FDialog.FullSize:= True;
  FDialog.Title:= FTitle;
  FDialog.Question:= FQuestion;
  FDialog.FOnReturnOk:= FOnReturnOk;
  InsertFront(FDialog);
  FDialog.Start;
end;

procedure TSeqConfirm.Update(const SecondsPassed: Single; var HandleInput: boolean);
begin
  inherited;

  if FDialog.Closed then
    Container.PopView(Self);
end;

end.
