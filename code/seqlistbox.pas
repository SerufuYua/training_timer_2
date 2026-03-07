unit SeqListBox;

interface

uses Classes, sysutils,
  CastleVectors, CastleUIControls, CastleControls, SeqExhibiter;

type
  TReturnIndex = procedure(AValue: Integer) of object;

  TSeqListBox = class(TCastleView)
  strict private
    type
      TSeqListBoxDialog = class(TCastleUserInterface)
      private
        FList: TStringArray;
        FOnReturnIndex: TReturnIndex;
        GroupList: TCastleVerticalGroup;
        ExhibiterList: TSeqExhibiter;
        ButtonClose: TCastleButton;
        procedure PrepareList;
        procedure ClickSequence(Sender: TObject);
        procedure ClickClose(Sender: TObject);
        procedure ShowClose;
        procedure DoClose(Sender: TObject);
      public
        Closed: Boolean;
        constructor Create(AOwner: TComponent); override;
        procedure Start;
      end;
    var
      FList: TStringArray;
      FOnReturnIndex: TReturnIndex;
      FDialog: TSeqListBoxDialog;
  public
    constructor CreateUntilStopped(AList: TStringArray; AOnReturnIndex: TReturnIndex);
    procedure Start; override;
    procedure Update(const SecondsPassed: Single; var HandleInput: boolean); override;
  end;

implementation

uses
  CastleComponentSerialize, CastleFonts;

{ ========= ------------------------------------------------------------------ }
{ TSeqListBoxDialog ---------------------------------------------------------- }
{ ========= ------------------------------------------------------------------ }

constructor TSeqListBox.TSeqListBoxDialog.Create(AOwner: TComponent);
var
  UiOwner: TComponent;
  Ui: TCastleUserInterface;
begin
  inherited;
  Closed:= False;

  // UiOwner is useful to keep reference to all components loaded from the design
  UiOwner := TComponent.Create(Self);

  { Load designed user interface }
  Ui := UserInterfaceLoad('castle-data:/listbox.castle-user-interface', UiOwner);
  InsertFront(Ui);

  { Find components, by name, that we need to access from code }
  GroupList:= UiOwner.FindRequiredComponent('GroupList') as TCastleVerticalGroup;
  ExhibiterList:= UiOwner.FindRequiredComponent('ExhibiterList') as TSeqExhibiter;
  ButtonClose:= UiOwner.FindRequiredComponent('ButtonClose') as TCastleButton;
  ButtonClose.OnClick:= {$ifdef FPC}@{$endif}ClickClose;
end;

procedure TSeqListBox.TSeqListBoxDialog.Start;
begin
  PrepareList;
  ExhibiterList.ShowType:= Appear;
  ExhibiterList.ExecuteOnce:= True;
end;

procedure TSeqListBox.TSeqListBoxDialog.PrepareList;
var
  i: Integer;
  newBtn, sampleBtn: TCastleButton;
  myBtnFactory: TCastleComponentFactory;
  myFont: TCastleAbstractFont;
begin
  { take appearance of button }
  if ((GroupList.ControlsCount > 0) AND
      (GroupList.Controls[0] is TCastleButton)) then
  begin
    sampleBtn:= GroupList.Controls[0] as TCastleButton;
    myFont:= sampleBtn.CustomFont;
    myBtnFactory:= TCastleComponentFactory.Create(self);
    myBtnFactory.LoadFromComponent(sampleBtn);
  end else
  begin
    sampleBtn:= nil;
    myBtnFactory:= nil;
  end;

  GroupList.ClearControls;

  { create button suit part list }
  for i:= 0 to High(FList) do
  begin
    if Assigned(myBtnFactory) then
    begin
      newBtn:= myBtnFactory.ComponentLoad(GroupList) as TCastleButton;
      newBtn.CustomFont:= myFont;
    end else
      newBtn:= TCastleButton.Create(GroupList);

    newBtn.Caption:= FList[i];
    newBtn.Tag:= i;
    newBtn.OnClick:= {$ifdef FPC}@{$endif}ClickSequence;
    GroupList.InsertFront(newBtn);
  end;

  if Assigned(myBtnFactory) then
    FreeAndNil(myBtnFactory);
end;

procedure TSeqListBox.TSeqListBoxDialog.ClickSequence(Sender: TObject);
var
  button: TCastleButton;
begin
  if NOT (Sender is TCastleButton) then Exit;
  button:= Sender as TCastleButton;

  if Assigned(FOnReturnIndex) then
    FOnReturnIndex(button.Tag);

  ShowClose;
end;

procedure TSeqListBox.TSeqListBoxDialog.ClickClose(Sender: TObject);
begin
  ShowClose;
end;

procedure TSeqListBox.TSeqListBoxDialog.ShowClose;
begin
  ExhibiterList.ShowType:= Disappear;
  ExhibiterList.OnFinish:= {$ifdef FPC}@{$endif}DoClose;
  ExhibiterList.ExecuteOnce:= True;
end;

procedure TSeqListBox.TSeqListBoxDialog.DoClose(Sender: TObject);
begin
  Closed:= True;
end;

{ ========= ------------------------------------------------------------------ }
{ TSeqListBox ---------------------------------------------------------------- }
{ ========= ------------------------------------------------------------------ }

constructor TSeqListBox.CreateUntilStopped(AList: TStringArray; AOnReturnIndex: TReturnIndex);
begin
  inherited CreateUntilStopped;
  FList:= AList;
  FOnReturnIndex:= AOnReturnIndex;
  DesignUrl:= 'castle-data:/bgwin.castle-user-interface';
end;

procedure TSeqListBox.Start;
begin
  inherited;
  InterceptInput:= True;

  FDialog:= TSeqListBoxDialog.Create(FreeAtStop);
  FDialog.Anchor(hpMiddle);
  FDialog.Anchor(vpMiddle);
  FDialog.FullSize:= True;
  FDialog.FList:= FList;
  FDialog.FOnReturnIndex:= FOnReturnIndex;
  InsertFront(FDialog);
  FDialog.Start;
end;

procedure TSeqListBox.Update(const SecondsPassed: Single; var HandleInput: boolean);
begin
  inherited;

  if FDialog.Closed then
    Container.PopView(Self);
end;

end.
