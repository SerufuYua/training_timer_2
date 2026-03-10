unit SeqEditString;

interface

uses Classes, SeqBaseDialog,
  CastleVectors, CastleUIControls, CastleControls, SeqExhibiter;

type
  TReturnString = procedure(AValue: String) of object;

  TSeqEditString = class(TCastleView)
  strict private
    type
      TSeqEditStringDialog = class(TSeqBaseDialog)
      protected
        FOnReturnString: TReturnString;
        GroupList: TCastleVerticalGroup;
        EditString: TCastleEdit;
        ButtonSet: TCastleButton;
        procedure ClickControl(Sender: TObject);
        procedure SetString(AValue: String);
      public
        constructor CreateNew(const AUrl: String; AOwner: TComponent); override;

        property StringForEdit: String write SetString;
      end;
    var
      FTitle: String;
      FString: String;
      FOnReturnString: TReturnString;
      FDialog: TSeqEditStringDialog;
  public
    constructor CreateUntilStopped(AValue, ATitle: String; AOnReturnString: TReturnString);
    procedure Start; override;
    procedure Update(const SecondsPassed: Single; var HandleInput: boolean); override;
  end;

implementation

uses
  SysUtils, CastleComponentSerialize, CastleFonts;

{ ========= ------------------------------------------------------------------ }
{ TSeqListBoxDialog ---------------------------------------------------------- }
{ ========= ------------------------------------------------------------------ }

constructor TSeqEditString.TSeqEditStringDialog.CreateNew(const AUrl: String; AOwner: TComponent);
begin
  inherited;

  { Find components, by name, that we need to access from code }
  EditString:= FUiOwner.FindRequiredComponent('EditString') as TCastleEdit;
  ButtonSet:= FUiOwner.FindRequiredComponent('ButtonSet') as TCastleButton;
  ButtonSet.OnClick:= {$ifdef FPC}@{$endif}ClickControl;
end;

procedure TSeqEditString.TSeqEditStringDialog.ClickControl(Sender: TObject);
var
  button: TCastleButton;
begin
  if NOT (Sender is TCastleButton) then Exit;
  button:= Sender as TCastleButton;

  if ((button.Name = 'ButtonSet') AND Assigned(FOnReturnString)) then
    FOnReturnString(EditString.Text);

  ShowClose;
end;

procedure TSeqEditString.TSeqEditStringDialog.SetString(AValue: String);
begin
  EditString.Text:= AValue;
end;

{ ========= ------------------------------------------------------------------ }
{ TSeqEditString ------------------------------------------------------------ }
{ ========= ------------------------------------------------------------------ }

constructor TSeqEditString.CreateUntilStopped(AValue, ATitle: String; AOnReturnString: TReturnString);
begin
  inherited CreateUntilStopped;
  FTitle:= ATitle;
  FString:= AValue;
  FOnReturnString:= AOnReturnString;
  DesignUrl:= 'castle-data:/bgwin.castle-user-interface';
end;

procedure TSeqEditString.Start;
begin
  inherited;
  InterceptInput:= True;

  FDialog:= TSeqEditStringDialog.CreateNew('castle-data:/editstring.castle-user-interface', FreeAtStop);
  FDialog.Anchor(hpMiddle);
  FDialog.Anchor(vpMiddle);
  FDialog.FullSize:= True;
  FDialog.Title:= FTitle;
  FDialog.StringForEdit:= FString;
  FDialog.FOnReturnString:= FOnReturnString;
  InsertFront(FDialog);
  FDialog.Start;
end;

procedure TSeqEditString.Update(const SecondsPassed: Single; var HandleInput: boolean);
begin
  inherited;

  if FDialog.Closed then
    Container.PopView(Self);
end;

end.
