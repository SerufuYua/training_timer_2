unit SeqEditTimeMinSec;

interface

uses Classes,
  CastleVectors, CastleUIControls, CastleControls, SeqExhibiter;

type
  TReturnSeconds = procedure(AValue: Integer) of object;

  TSeqEditTimeMinSec = class(TCastleView)
  strict private
    type
      TSeqEditTimeMinSecDialog = class(TCastleUserInterface)
      private
        FSec, Fmin: Integer;
        FOnReturnSeconds: TReturnSeconds;
        ExhibiterList: TSeqExhibiter;
        EditMinNumber, EditSecNumber: TCastleEdit;
        ButtonMinIncrease, ButtonMinDecrease: TCastleButton;
        ButtonSecIncrease, ButtonSecDecrease: TCastleButton;
        ButtonClose, ButtonSet: TCastleButton;
        procedure ChangeNumber(Sender: TObject);
        procedure ClickControl(Sender: TObject);
        procedure ShowClose;
        procedure DoClose(Sender: TObject);
        procedure SetSeconds(AValue: Integer);
        function GetSeconds: Integer;
      public
        Closed: Boolean;
        constructor Create(AOwner: TComponent); override;
        procedure Start;

        property Seconds: Integer read GetSeconds write SetSeconds;
      end;
    var
      FSeconds: Integer;
      FOnReturnSeconds: TReturnSeconds;
      FDialog: TSeqEditTimeMinSecDialog;
  public
    constructor CreateUntilStopped(AValue: Integer; AOnReturnSeconds: TReturnSeconds);
    procedure Start; override;
    procedure Update(const SecondsPassed: Single; var HandleInput: boolean); override;
  end;

implementation

uses
  SysUtils, CastleComponentSerialize, CastleFonts, MyTimes;

{ ========= ------------------------------------------------------------------ }
{ TSeqListBoxDialog ---------------------------------------------------------- }
{ ========= ------------------------------------------------------------------ }

constructor TSeqEditTimeMinSec.TSeqEditTimeMinSecDialog.Create(AOwner: TComponent);
var
  UiOwner: TComponent;
  Ui: TCastleUserInterface;
begin
  inherited;
  Closed:= False;
  FSec:= 0;
  Fmin:= 0;

  // UiOwner is useful to keep reference to all components loaded from the design
  UiOwner := TComponent.Create(Self);

  { Load designed user interface }
  Ui := UserInterfaceLoad('castle-data:/edittime_min_sec.castle-user-interface', UiOwner);
  InsertFront(Ui);

  { Find components, by name, that we need to access from code }
  EditMinNumber:= UiOwner.FindRequiredComponent('EditMinNumber') as TCastleEdit;
  EditSecNumber:= UiOwner.FindRequiredComponent('EditSecNumber') as TCastleEdit;
  ButtonMinIncrease:= UiOwner.FindRequiredComponent('ButtonMinIncrease') as TCastleButton;
  ButtonMinDecrease:= UiOwner.FindRequiredComponent('ButtonMinDecrease') as TCastleButton;
  ButtonSecIncrease:= UiOwner.FindRequiredComponent('ButtonSecIncrease') as TCastleButton;
  ButtonSecDecrease:= UiOwner.FindRequiredComponent('ButtonSecDecrease') as TCastleButton;
  ExhibiterList:= UiOwner.FindRequiredComponent('ExhibiterList') as TSeqExhibiter;
  ButtonClose:= UiOwner.FindRequiredComponent('ButtonClose') as TCastleButton;
  ButtonSet:= UiOwner.FindRequiredComponent('ButtonSet') as TCastleButton;
  EditMinNumber.OnChange:= {$ifdef FPC}@{$endif}ChangeNumber;
  EditSecNumber.OnChange:= {$ifdef FPC}@{$endif}ChangeNumber;
  ButtonMinIncrease.OnClick:= {$ifdef FPC}@{$endif}ChangeNumber;
  ButtonMinDecrease.OnClick:= {$ifdef FPC}@{$endif}ChangeNumber;
  ButtonSecIncrease.OnClick:= {$ifdef FPC}@{$endif}ChangeNumber;
  ButtonSecDecrease.OnClick:= {$ifdef FPC}@{$endif}ChangeNumber;
  ButtonClose.OnClick:= {$ifdef FPC}@{$endif}ClickControl;
  ButtonSet.OnClick:= {$ifdef FPC}@{$endif}ClickControl;
end;

procedure TSeqEditTimeMinSec.TSeqEditTimeMinSecDialog.Start;
begin
  ExhibiterList.ShowType:= Appear;
  ExhibiterList.ExecuteOnce:= True;
end;

procedure TSeqEditTimeMinSec.TSeqEditTimeMinSecDialog.ChangeNumber(Sender: TObject);
var
  component: TComponent;
  edit: TCastleEdit;
begin
  if (NOT (Sender is TComponent)) then Exit;

  component:= Sender as TComponent;
  case component.Name of
    'ButtonMinIncrease':
      Seconds:= Seconds + 60;
    'ButtonMinDecrease':
      Seconds:= Seconds - 60;
    'ButtonSecIncrease':
      Seconds:= Seconds + 1;
    'ButtonSecDecrease':
      Seconds:= Seconds - 1;
    'EditMinNumber':
    begin
      edit:= Sender as TCastleEdit;
      Seconds:= MinSecToSeconds(StrToIntDef(edit.Text, 0), FSec);
    end;
    'EditSecNumber':
    begin
      edit:= Sender as TCastleEdit;
      Seconds:= MinSecToSeconds(FMin, StrToIntDef(edit.Text, 0));
    end;
  end;
end;

procedure TSeqEditTimeMinSec.TSeqEditTimeMinSecDialog.SetSeconds(AValue: Integer);
begin
  if (AValue >=0) then
  begin
    SecondsToMinSec(AValue, FMin, FSec);
    EditMinNumber.Text:= IntToStr(FMin);
    EditSecNumber.Text:= IntToStr(FSec);
  end;
end;

function TSeqEditTimeMinSec.TSeqEditTimeMinSecDialog.GetSeconds: Integer;
begin
  Result:= MinSecToSeconds(FMin, FSec);
end;

procedure TSeqEditTimeMinSec.TSeqEditTimeMinSecDialog.ClickControl(Sender: TObject);
var
  button: TCastleButton;
begin
  if NOT (Sender is TCastleButton) then Exit;
  button:= Sender as TCastleButton;

  if ((button.Name = 'ButtonSet') AND Assigned(FOnReturnSeconds)) then
    FOnReturnSeconds(Seconds);

  ShowClose;
end;

procedure TSeqEditTimeMinSec.TSeqEditTimeMinSecDialog.ShowClose;
begin
  ExhibiterList.ShowType:= Disappear;
  ExhibiterList.OnFinish:= {$ifdef FPC}@{$endif}DoClose;
  ExhibiterList.ExecuteOnce:= True;
end;

procedure TSeqEditTimeMinSec.TSeqEditTimeMinSecDialog.DoClose(Sender: TObject);
begin
  Closed:= True;
end;

{ ========= ------------------------------------------------------------------ }
{ TSeqEditTimeMinSec ------------------------------------------------------------ }
{ ========= ------------------------------------------------------------------ }

constructor TSeqEditTimeMinSec.CreateUntilStopped(AValue: Integer; AOnReturnSeconds: TReturnSeconds);
begin
  inherited CreateUntilStopped;
  FSeconds:= AValue;
  FOnReturnSeconds:= AOnReturnSeconds;
  DesignUrl:= 'castle-data:/bgwin.castle-user-interface';
end;

procedure TSeqEditTimeMinSec.Start;
begin
  inherited;
  InterceptInput:= True;

  FDialog:= TSeqEditTimeMinSecDialog.Create(FreeAtStop);
  FDialog.Anchor(hpMiddle);
  FDialog.Anchor(vpMiddle);
  FDialog.FullSize:= True;
  FDialog.Seconds:= FSeconds;
  FDialog.FOnReturnSeconds:= FOnReturnSeconds;
  InsertFront(FDialog);
  FDialog.Start;
end;

procedure TSeqEditTimeMinSec.Update(const SecondsPassed: Single; var HandleInput: boolean);
begin
  inherited;

  if FDialog.Closed then
    Container.PopView(Self);
end;

end.
