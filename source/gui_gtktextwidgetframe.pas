unit gui_gtktextwidgetframe;

{$mode objfpc}{$H+}

interface

{$IFDEF LCLGTK2}
uses
  Classes, SysUtils, FileUtil, RichMemo, Forms, Controls, Graphics, Dialogs,
  StdCtrls, gui_documentframe, gtk_textwidget;

type

  // https://developer.gnome.org/gtk2/stable/TextWidget.html
  { TGTKTextWidgetFrame }
  TGTKTextWidgetFrame = class(TDocumentFrame)
  private
    { private declarations }
    fTextView: TGTKTextWidget;
    class var fGTKFileFormatID: String;
  protected
    procedure CreateNewDocument; override;
    procedure DisplayLoadError(aText: String); override;
    function GetSaveText(aEditorTypeID: UTF8String): UTF8String; override;
    procedure LoadText(aText: UTF8String; aEditorTypeID: UTF8String); override;
    class constructor Create;

  public
    constructor Create(aOwner: TComponent); override;
    function FindReplace(aSearchText: String; aForward: Boolean=true;
      aWrap: Boolean=false; aDoReplace: Boolean=false; aReplaceText: String=''
      ): Boolean; override;
    procedure Print; override;
    { public declarations }
    class function GetFileType: String; override;

  end;
{$ENDIF}

implementation

{$IFDEF LCLGTK2}
{$R *.lfm}

{ TGTKTextWidgetFrame }

procedure TGTKTextWidgetFrame.CreateNewDocument;
begin
    // TODO:
end;

procedure TGTKTextWidgetFrame.DisplayLoadError(aText: String);
begin
  // TODO:

end;

function TGTKTextWidgetFrame.GetSaveText(aEditorTypeID: UTF8String): UTF8String;
begin
  // TODO:

end;

procedure TGTKTextWidgetFrame.LoadText(aText: UTF8String;
  aEditorTypeID: UTF8String);
begin
  // TODO:

end;

class constructor TGTKTextWidgetFrame.Create;
begin
  fGTKFileFormatID := TDocumentFrame.RegisterFormatEditor('Dumb Binary Text File','dbtf',TGTKTextWidgetFrame,false);

end;

constructor TGTKTextWidgetFrame.Create(aOwner: TComponent);
begin
  inherited Create(aOwner);
  fTextView := TGTKTextWidget.Create(Self);
  fTextView.Parent := Self;
  fTextView.Align:= alClient;
end;

function TGTKTextWidgetFrame.FindReplace(aSearchText: String;
  aForward: Boolean; aWrap: Boolean; aDoReplace: Boolean; aReplaceText: String
  ): Boolean;
begin
  // TODO:

end;

procedure TGTKTextWidgetFrame.Print;
begin
  // TODO:

end;

class function TGTKTextWidgetFrame.GetFileType: String;
begin
  Result:='Dumb Binary Text File';
end;

{$ENDIF}

end.

