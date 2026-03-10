unit SeqListBox;

interface

uses Classes, sysutils, SeqBaseDialog,
  CastleVectors, CastleUIControls, CastleControls, SeqExhibiter;

type
  TReturnIndex = procedure(AValue: Integer) of object;

  TSeqListBox = class(TCastleView)
  strict private
    type
      TSeqListBoxDialog = class(TSeqBaseDialog)
      protected
        FList: TStringArray;
        FOnReturnIndex: TReturnIndex;
        GroupList: TCastleVerticalGroup;
        procedure PrepareList;
        procedure ClickSequence(Sender: TObject);
      public
        constructor CreateNew(const AUrl: String; AOwner: TComponent); override;
        procedure Start; override;
      end;
    var
      FTitle: String;
      FList: TStringArray;
      FOnReturnIndex: TReturnIndex;
      FDialog: TSeqListBoxDialog;
  public
    constructor CreateUntilStopped(AList: TStringArray; ATitle: String; AOnReturnIndex: TReturnIndex);
    procedure Start; override;
    procedure Update(const SecondsPassed: Single; var HandleInput: boolean); override;
  end;

implementation

uses
  CastleComponentSerialize, CastleFonts;

{ ========= ------------------------------------------------------------------ }
{ TSeqBaseDialog ---------------------------------------------------------- }
{ ========= ------------------------------------------------------------------ }

constructor TSeqListBox.TSeqListBoxDialog.CreateNew(const AUrl: String; AOwner: TComponent);
begin
  inherited;

  { Find components, by name, that we need to access from code }
  GroupList:= FUiOwner.FindRequiredComponent('GroupList') as TCastleVerticalGroup;
end;

procedure TSeqListBox.TSeqListBoxDialog.Start;
begin
  PrepareList;
  inherited;
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

{ ========= ------------------------------------------------------------------ }
{ TSeqListBox ---------------------------------------------------------------- }
{ ========= ------------------------------------------------------------------ }

constructor TSeqListBox.CreateUntilStopped(AList: TStringArray; ATitle: String; AOnReturnIndex: TReturnIndex);
begin
  inherited CreateUntilStopped;
  FTitle:= ATitle;
  FList:= AList;
  FOnReturnIndex:= AOnReturnIndex;
  DesignUrl:= 'castle-data:/bgwin.castle-user-interface';
end;

procedure TSeqListBox.Start;
begin
  inherited;
  InterceptInput:= True;

  FDialog:= TSeqListBoxDialog.CreateNew('castle-data:/listbox.castle-user-interface', FreeAtStop);
  FDialog.Anchor(hpMiddle);
  FDialog.Anchor(vpMiddle);
  FDialog.FullSize:= True;
  FDialog.Title:= FTitle;
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
