unit SeqListColors;

interface

uses Classes, sysutils, SeqBaseDialog,
  CastleVectors, CastleUIControls, CastleControls, CastleColors,
  CastleColorListBox, SeqExhibiter;

type
  TReturnColor = procedure(AValue: TCastleColor) of object;
  TCastleColors = Array of TCastleColor;

  TSeqListColors = class(TCastleView)
  strict private
    type
      TSeqListColorsDialog = class(TSeqBaseDialog)
      protected
        FOnReturnColor: TReturnColor;
        ColorListBox: TCastleColorListBox;
        procedure ClickColor(Sender: TObject);
      public
        constructor CreateNew(const AUrl: String; AOwner: TComponent); override;
        procedure Start; override;
        procedure CustomColors(AColors: TCastleColors);
      end;
    var
      FTitle: String;
      FColors: TCastleColors;
      FOnReturnColor: TReturnColor;
      FDialog: TSeqListColorsDialog;
  public
    constructor CreateUntilStopped(AColors: TCastleColors; ATitle: String; AOnReturnColor: TReturnColor);
    procedure Start; override;
    procedure Update(const SecondsPassed: Single; var HandleInput: boolean); override;
  end;

implementation

uses
  CastleComponentSerialize, CastleFonts;

{ ========= ------------------------------------------------------------------ }
{ TSeqListColorsDialog ------------------------------------------------------- }
{ ========= ------------------------------------------------------------------ }

constructor TSeqListColors.TSeqListColorsDialog.CreateNew(const AUrl: String; AOwner: TComponent);
begin
  inherited;

  { Find components, by name, that we need to access from code }
  ColorListBox:= FUiOwner.FindRequiredComponent('ColorListBox') as TCastleColorListBox;
  ColorListBox.OnChange:= {$ifdef FPC}@{$endif}ClickColor;
end;

procedure TSeqListColors.TSeqListColorsDialog.Start;
begin
  inherited;
end;

procedure TSeqListColors.TSeqListColorsDialog.CustomColors(AColors: TCastleColors);
var
  ccolor: TCastleColor;
begin
  ColorListBox.List.Clear;

  for ccolor in AColors do
    ColorListBox.List.Add(ColorToHex(ccolor));
end;

procedure TSeqListColors.TSeqListColorsDialog.ClickColor(Sender: TObject);
var
  listBox: TCastleColorListBox;
begin
  if NOT (Sender is TCastleColorListBox) then Exit;
  listBox:= Sender as TCastleColorListBox;

  if Assigned(FOnReturnColor) then
    FOnReturnColor(listBox.GetColor(listBox.Index));

  ShowClose;
end;

{ ========= ------------------------------------------------------------------ }
{ TSeqListColors ---------------------------------------------------------------- }
{ ========= ------------------------------------------------------------------ }

constructor TSeqListColors.CreateUntilStopped(AColors: TCastleColors; ATitle: String; AOnReturnColor: TReturnColor);
begin
  inherited CreateUntilStopped;
  FTitle:= ATitle;
  FColors:= AColors;
  FOnReturnColor:= AOnReturnColor;
  DesignUrl:= 'castle-data:/bgwin.castle-user-interface';
end;

procedure TSeqListColors.Start;
begin
  inherited;
  InterceptInput:= True;

  FDialog:= TSeqListColorsDialog.CreateNew('castle-data:/listcolors.castle-user-interface', FreeAtStop);
  FDialog.Anchor(hpMiddle);
  FDialog.Anchor(vpMiddle);
  FDialog.FullSize:= True;
  FDialog.Title:= FTitle;

  if Assigned(FColors) then
    FDialog.CustomColors(FColors);

  FDialog.FOnReturnColor:= FOnReturnColor;
  InsertFront(FDialog);
  FDialog.Start;
end;

procedure TSeqListColors.Update(const SecondsPassed: Single; var HandleInput: boolean);
begin
  inherited;

  if FDialog.Closed then
    Container.PopView(Self);
end;

end.
