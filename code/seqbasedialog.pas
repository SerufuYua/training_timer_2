unit SeqBaseDialog;

{$mode ObjFPC}{$H+}

interface

uses
  Classes, SysUtils, CastleUIControls, CastleControls, CastleComponentSerialize,
  SeqExhibiter;

type
  TSeqBaseDialog = class(TCastleUserInterface)
  protected
    FUiOwner: TComponent;
    FTitle: String;
    LabelTitle: TCastleLabel;
    Exhibiter: TSeqExhibiter;
    ButtonClose: TCastleButton;
    procedure ControlHover(const Sender: TCastleUserInterface);
    procedure ClickClose(Sender: TObject);
    procedure ShowClose;
    procedure DoClose(Sender: TObject);
    procedure SetTitle(AValue: String);
  public
    Closed: Boolean;
    constructor CreateNew(const AUrl: String; AOwner: TComponent); virtual;
    procedure Start; virtual;

    property Title: String read FTitle write SetTitle;
  end;

implementation

uses
  GameSound;

constructor TSeqBaseDialog.CreateNew(const AUrl: String; AOwner: TComponent);
var
  Ui: TCastleUserInterface;
begin
  inherited Create(AOwner);
  Closed:= False;

  // FUiOwner is useful to keep reference to all components loaded from the design
  FUiOwner:= TComponent.Create(Self);

  { Load designed user interface }
  Ui:= UserInterfaceLoad(AUrl, FUiOwner);
  InsertFront(Ui);

  { Find components, by name, that we need to access from code }
  LabelTitle:= FUiOwner.FindRequiredComponent('LabelTitle') as TCastleLabel;
  Exhibiter:= FUiOwner.FindRequiredComponent('Exhibiter') as TSeqExhibiter;
  ButtonClose:= FUiOwner.FindRequiredComponent('ButtonClose') as TCastleButton;
  ButtonClose.OnClick:= {$ifdef FPC}@{$endif}ClickClose;
  ButtonClose.OnInternalMouseEnter:= {$ifdef FPC}@{$endif}ControlHover;
end;

procedure TSeqBaseDialog.Start;
begin
  inherited;
  Exhibiter.ShowType:= Appear;
  Exhibiter.ExecuteOnce:= True;
end;

procedure TSeqBaseDialog.SetTitle(AValue: String);
begin
  if (FTitle = AValue) then Exit;

  if Assigned(LabelTitle) then
  begin
    FTitle:= AValue;
    LabelTitle.Caption:= FTitle;
  end;
end;

procedure TSeqBaseDialog.ControlHover(const Sender: TCastleUserInterface);
begin
  PlaySfx(TSfxType.PointerHover);
end;

procedure TSeqBaseDialog.ClickClose(Sender: TObject);
begin
  PlaySfx(TSfxType.ClickCancel);
  ShowClose;
end;

procedure TSeqBaseDialog.ShowClose;
begin
  Exhibiter.ShowType:= Disappear;
  Exhibiter.OnFinish:= {$ifdef FPC}@{$endif}DoClose;
  Exhibiter.ExecuteOnce:= True;
end;

procedure TSeqBaseDialog.DoClose(Sender: TObject);
begin
  Closed:= True;
end;

end.

