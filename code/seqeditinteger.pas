unit SeqEditInteger;

interface

uses Classes,
  CastleVectors, CastleUIControls, CastleControls, SeqExhibiter;

type
  TReturnInteger = procedure(AValue: Integer) of object;

  TSeqEditInteger = class(TCastleView)
  strict private
    type
      TSeqEditIntegerDialog = class(TCastleUserInterface)
      private
        FTitle: String;
        FNumber, FMin, FMax: Integer;
        FOnReturnInteger: TReturnInteger;
        LabelTitle: TCastleLabel;
        ExhibiterList: TSeqExhibiter;
        EditNumber: TCastleEdit;
        ButtonIncrease, ButtonDecrease: TCastleButton;
        ButtonClose, ButtonSet: TCastleButton;
        procedure ChangeNumber(Sender: TObject);
        procedure ClickControl(Sender: TObject);
        procedure ShowClose;
        procedure DoClose(Sender: TObject);
        procedure SetNumber(AValue: Integer);
        procedure SetTitle(AValue: String);
      public
        Closed: Boolean;
        constructor Create(AOwner: TComponent); override;
        procedure Start;

        property Number: Integer read FNumber write SetNumber;
        property Title: String read FTitle write SetTitle;
      end;
    var
      FTitle: String;
      FNumber, FMin, FMax: Integer;
      FOnReturnInteger: TReturnInteger;
      FDialog: TSeqEditIntegerDialog;
  public
    constructor CreateUntilStopped(AValue, AMin, AMax: Integer; ATitle: String; AOnReturnInteger: TReturnInteger);
    procedure Start; override;
    procedure Update(const SecondsPassed: Single; var HandleInput: boolean); override;
  end;

implementation

uses
  SysUtils, CastleComponentSerialize, CastleFonts;

{ ========= ------------------------------------------------------------------ }
{ TSeqListBoxDialog ---------------------------------------------------------- }
{ ========= ------------------------------------------------------------------ }

constructor TSeqEditInteger.TSeqEditIntegerDialog.Create(AOwner: TComponent);
var
  UiOwner: TComponent;
  Ui: TCastleUserInterface;
begin
  inherited;
  Closed:= False;
  FNumber:= 0;
  Fmin:= 0;
  FMax:= 10000;

  // UiOwner is useful to keep reference to all components loaded from the design
  UiOwner := TComponent.Create(Self);

  { Load designed user interface }
  Ui := UserInterfaceLoad('castle-data:/editinteger.castle-user-interface', UiOwner);
  InsertFront(Ui);

  { Find components, by name, that we need to access from code }
  LabelTitle:= UiOwner.FindRequiredComponent('LabelTitle') as TCastleLabel;
  EditNumber:= UiOwner.FindRequiredComponent('EditNumber') as TCastleEdit;
  ButtonIncrease:= UiOwner.FindRequiredComponent('ButtonIncrease') as TCastleButton;
  ButtonDecrease:= UiOwner.FindRequiredComponent('ButtonDecrease') as TCastleButton;
  ExhibiterList:= UiOwner.FindRequiredComponent('ExhibiterList') as TSeqExhibiter;
  ButtonClose:= UiOwner.FindRequiredComponent('ButtonClose') as TCastleButton;
  ButtonSet:= UiOwner.FindRequiredComponent('ButtonSet') as TCastleButton;
  EditNumber.OnChange:= {$ifdef FPC}@{$endif}ChangeNumber;
  ButtonIncrease.OnClick:= {$ifdef FPC}@{$endif}ChangeNumber;
  ButtonDecrease.OnClick:= {$ifdef FPC}@{$endif}ChangeNumber;
  ButtonClose.OnClick:= {$ifdef FPC}@{$endif}ClickControl;
  ButtonSet.OnClick:= {$ifdef FPC}@{$endif}ClickControl;
end;

procedure TSeqEditInteger.TSeqEditIntegerDialog.Start;
begin
  ExhibiterList.ShowType:= Appear;
  ExhibiterList.ExecuteOnce:= True;
end;

procedure TSeqEditInteger.TSeqEditIntegerDialog.ChangeNumber(Sender: TObject);
var
  component: TComponent;
  edit: TCastleEdit;
begin
  if (NOT (Sender is TComponent)) then Exit;

  component:= Sender as TComponent;
  case component.Name of
    'EditNumber':
    begin
      edit:= Sender as TCastleEdit;
      Number:= StrToIntDef(edit.Text, 0);
    end;
    'ButtonIncrease':
      Number:= Number + 1;
    'ButtonDecrease':
      Number:= Number - 1;
  end;
end;

procedure TSeqEditInteger.TSeqEditIntegerDialog.SetNumber(AValue: Integer);
begin
  if (AValue < Fmin) then
    AValue:= Fmin
  else
  if (AValue > FMax) then
    AValue:= FMax;

  if (FNumber <> AValue) then
  begin
    FNumber:= AValue;
    EditNumber.Text:= IntToStr(FNumber);
  end;
end;

procedure TSeqEditInteger.TSeqEditIntegerDialog.SetTitle(AValue: String);
begin
  if (FTitle = AValue) then Exit;

  FTitle:= AValue;
  LabelTitle.Caption:= FTitle;
end;

procedure TSeqEditInteger.TSeqEditIntegerDialog.ClickControl(Sender: TObject);
var
  button: TCastleButton;
begin
  if NOT (Sender is TCastleButton) then Exit;
  button:= Sender as TCastleButton;

  if ((button.Name = 'ButtonSet') AND Assigned(FOnReturnInteger)) then
    FOnReturnInteger(Number);

  ShowClose;
end;

procedure TSeqEditInteger.TSeqEditIntegerDialog.ShowClose;
begin
  ExhibiterList.ShowType:= Disappear;
  ExhibiterList.OnFinish:= {$ifdef FPC}@{$endif}DoClose;
  ExhibiterList.ExecuteOnce:= True;
end;

procedure TSeqEditInteger.TSeqEditIntegerDialog.DoClose(Sender: TObject);
begin
  Closed:= True;
end;

{ ========= ------------------------------------------------------------------ }
{ TSeqEditInteger ------------------------------------------------------------ }
{ ========= ------------------------------------------------------------------ }

constructor TSeqEditInteger.CreateUntilStopped(AValue, AMin, AMax: Integer; ATitle: String; AOnReturnInteger: TReturnInteger);
begin
  inherited CreateUntilStopped;
  FTitle:= ATitle;
  FMin:= AMin;
  FMax:= AMax;
  FNumber:= AValue;
  FOnReturnInteger:= AOnReturnInteger;
  DesignUrl:= 'castle-data:/bgwin.castle-user-interface';
end;

procedure TSeqEditInteger.Start;
begin
  inherited;
  InterceptInput:= True;

  FDialog:= TSeqEditIntegerDialog.Create(FreeAtStop);
  FDialog.Anchor(hpMiddle);
  FDialog.Anchor(vpMiddle);
  FDialog.Title:= FTitle;
  FDialog.FullSize:= True;
  FDialog.FMin:= FMin;
  FDialog.FMax:= FMax;
  FDialog.Number:= FNumber;
  FDialog.FOnReturnInteger:= FOnReturnInteger;
  InsertFront(FDialog);
  FDialog.Start;
end;

procedure TSeqEditInteger.Update(const SecondsPassed: Single; var HandleInput: boolean);
begin
  inherited;

  if FDialog.Closed then
    Container.PopView(Self);
end;

end.
