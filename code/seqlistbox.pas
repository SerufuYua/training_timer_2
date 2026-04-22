unit SeqListBox;

interface

uses Classes, sysutils, SeqBaseDialog,
  CastleVectors, CastleUIControls, CastleControls, CastleListBox, SeqExhibiter;

type
  TReturnIndex = procedure(AValue: Integer) of object;

  TSeqListBox = class(TCastleView)
  strict private
    type
      TSeqListBoxDialog = class(TSeqBaseDialog)
      protected
        FOnReturnIndex: TReturnIndex;
        ListBox: TCastleListBox;
        procedure ListPressed(Sender: TObject);
        procedure ListHovered(Sender: TObject; AIndex: Integer);
        procedure ClickList(Sender: TObject);
      public
        constructor CreateNew(const AUrl: String; AOwner: TComponent); override;
        procedure SetList(AList: TStringArray);
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
  CastleComponentSerialize, CastleFonts, GameSound;

{ ========= ------------------------------------------------------------------ }
{ TSeqListBoxDialog ---------------------------------------------------------- }
{ ========= ------------------------------------------------------------------ }

constructor TSeqListBox.TSeqListBoxDialog.CreateNew(const AUrl: String; AOwner: TComponent);
begin
  inherited;

  { Find components, by name, that we need to access from code }
  ListBox:= FUiOwner.FindRequiredComponent('ListBox') as TCastleListBox;
  ListBox.OnCursorArrive:= {$ifdef FPC}@{$endif}ClickList;
  ListBox.OnChange:=       {$ifdef FPC}@{$endif}ListPressed;
  ListBox.OnLineHover:=    {$ifdef FPC}@{$endif}ListHovered;
end;

procedure TSeqListBox.TSeqListBoxDialog.SetList(AList: TStringArray);
var
  line: String;
begin
  ListBox.List.Clear;

  for line in AList do
    ListBox.List.Add(line);
end;

procedure TSeqListBox.TSeqListBoxDialog.ListPressed(Sender: TObject);
begin
  PlaySfx(TSfxType.ClickEdit);
end;

procedure TSeqListBox.TSeqListBoxDialog.ListHovered(Sender: TObject; AIndex: Integer);
begin
  PlaySfx(TSfxType.ListHover);
end;

procedure TSeqListBox.TSeqListBoxDialog.ClickList(Sender: TObject);
begin
  if ((Sender is TCastleListBox) AND Assigned(FOnReturnIndex)) then
  begin
    PlaySfx(TSfxType.ClickOk);
    FOnReturnIndex((Sender as TCastleListBox).Index);
  end;

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
  FDialog.SetList(FList);
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
