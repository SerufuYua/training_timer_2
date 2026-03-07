unit SeqEditString;

interface

uses Classes,
  CastleVectors, CastleUIControls, CastleControls, SeqExhibiter;

type
  TReturnString = procedure(AValue: String) of object;

  TSeqEditString = class(TCastleView)
  strict private
    type
      TSeqEditStringDialog = class(TCastleUserInterface)
      private
        FOnReturnString: TReturnString;
        GroupList: TCastleVerticalGroup;
        ExhibiterList: TSeqExhibiter;
        EditString: TCastleEdit;
        ButtonClose, ButtonSet: TCastleButton;
        procedure ClickControl(Sender: TObject);
        procedure ShowClose;
        procedure DoClose(Sender: TObject);
        procedure SetString(AValue: String);
      public
        Closed: Boolean;
        constructor Create(AOwner: TComponent); override;
        procedure Start;

        property StringForEdit: String write SetString;
      end;
    var
      FString: String;
      FOnReturnString: TReturnString;
      FDialog: TSeqEditStringDialog;
  public
    constructor CreateUntilStopped(AValue: String; AOnReturnString: TReturnString);
    procedure Start; override;
    procedure Update(const SecondsPassed: Single; var HandleInput: boolean); override;
  end;

implementation

uses
  SysUtils, CastleComponentSerialize, CastleFonts;

{ ========= ------------------------------------------------------------------ }
{ TSeqListBoxDialog ---------------------------------------------------------- }
{ ========= ------------------------------------------------------------------ }

constructor TSeqEditString.TSeqEditStringDialog.Create(AOwner: TComponent);
var
  UiOwner: TComponent;
  Ui: TCastleUserInterface;
begin
  inherited;
  Closed:= False;

  // UiOwner is useful to keep reference to all components loaded from the design
  UiOwner := TComponent.Create(Self);

  { Load designed user interface }
  Ui := UserInterfaceLoad('castle-data:/editstring.castle-user-interface', UiOwner);
  InsertFront(Ui);

  { Find components, by name, that we need to access from code }
  EditString:= UiOwner.FindRequiredComponent('EditString') as TCastleEdit;
  ExhibiterList:= UiOwner.FindRequiredComponent('ExhibiterList') as TSeqExhibiter;
  ButtonClose:= UiOwner.FindRequiredComponent('ButtonClose') as TCastleButton;
  ButtonSet:= UiOwner.FindRequiredComponent('ButtonSet') as TCastleButton;
  ButtonClose.OnClick:= {$ifdef FPC}@{$endif}ClickControl;
  ButtonSet.OnClick:= {$ifdef FPC}@{$endif}ClickControl;
end;

procedure TSeqEditString.TSeqEditStringDialog.Start;
begin
  ExhibiterList.ShowType:= Appear;
  ExhibiterList.ExecuteOnce:= True;
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

procedure TSeqEditString.TSeqEditStringDialog.ShowClose;
begin
  ExhibiterList.ShowType:= Disappear;
  ExhibiterList.OnFinish:= {$ifdef FPC}@{$endif}DoClose;
  ExhibiterList.ExecuteOnce:= True;
end;

procedure TSeqEditString.TSeqEditStringDialog.DoClose(Sender: TObject);
begin
  Closed:= True;
end;

{ ========= ------------------------------------------------------------------ }
{ TSeqEditString ------------------------------------------------------------ }
{ ========= ------------------------------------------------------------------ }

constructor TSeqEditString.CreateUntilStopped(AValue: String; AOnReturnString: TReturnString);
begin
  inherited CreateUntilStopped;
  FString:= AValue;
  FOnReturnString:= AOnReturnString;
  DesignUrl:= 'castle-data:/bgwin.castle-user-interface';
end;

procedure TSeqEditString.Start;
begin
  inherited;
  InterceptInput:= True;

  FDialog:= TSeqEditStringDialog.Create(FreeAtStop);
  FDialog.Anchor(hpMiddle);
  FDialog.Anchor(vpMiddle);
  FDialog.FullSize:= True;
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
