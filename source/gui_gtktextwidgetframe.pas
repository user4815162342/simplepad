unit gui_gtktextwidgetframe;

{$mode objfpc}{$H+}

interface

{$IFDEF LCLGTK2}
uses
  Classes, SysUtils, FileUtil, RichMemo, Forms, Controls, Graphics, Dialogs,
  gui_documentframe, gtk_textwidget;

type

  // https://developer.gnome.org/gtk2/stable/TextWidget.html
  { TGTKTextWidgetFrame }
  TGTKTextWidgetFrame = class(TDocumentFrame)
  private
    { private declarations }
    fTextView: TTextWidget;
    class var fGTKFileFormatID: String;
    class var fRTFFileFormatID: String;
  protected
    procedure CreateNewDocument; override;
    procedure DisplayLoadError(aText: String); override;
    function GetSaveText(aEditorTypeID: UTF8String): UTF8String; override;
    procedure LoadText(aText: UTF8String; aEditorTypeID: UTF8String); override;
    class constructor Create;

  public
    constructor Create(aOwner: TComponent); override;
    function FindReplace(aSearchText: String; aForward: Boolean=true;
      aWrap: Boolean=false; {%H-}aDoReplace: Boolean=false; {%H-}aReplaceText: String=''
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
  ShowMessage('Error: ' + aText)

end;

// TODO: Should be saving/loading to from streams instead of 'string'.
function TGTKTextWidgetFrame.GetSaveText(aEditorTypeID: UTF8String): UTF8String;
begin
  if aEditorTypeID = fGTKFileFormatID then
     raise Exception.Create('I''m still working on this')
  else if aEditorTypeID = fRTFFileFormatID then
    // TODO: I've got better ideas, but this will work for now...
    result := fTextView.Rtf;

end;

procedure TGTKTextWidgetFrame.LoadText(aText: UTF8String;
  aEditorTypeID: UTF8String);
begin
  if aEditorTypeID = fGTKFileFormatID then
     raise Exception.Create('I''m still working on this')
  else if aEditorTypeID = fRTFFileFormatID then
    // TODO: I've got better ideas, but this will work for now...
     fTextView.Rtf := aText;

end;

class constructor TGTKTextWidgetFrame.Create;
begin
  fGTKFileFormatID := TDocumentFrame.RegisterFormatEditor('Dumb Binary Text File','dbtf',TGTKTextWidgetFrame,false);
  fRTFFileFormatID := TDocumentFrame.RegisterFormatEditor('Rich Text File','rtf',TGTKTextWidgetFrame,false);

end;

constructor TGTKTextWidgetFrame.Create(aOwner: TComponent);
begin
  inherited Create(aOwner);
  fTextView := TTextWidget.Create(Self);
  fTextView.Parent := Self;
  fTextView.Align:= alClient;
end;

function TGTKTextWidgetFrame.FindReplace(aSearchText: String;
  aForward: Boolean; aWrap: Boolean; aDoReplace: Boolean; aReplaceText: String
  ): Boolean;
var
  lPosition: Longint;
begin
  if aForward then
  begin
    lPosition := fTextView.Search(aSearchText,fTextView.SelStart,Length(fTextView.Text),[]);
    if (lPosition < 0) and aWrap then
       lPosition := fTextView.Search(aSearchText,0,fTextView.SelStart,[]);
  end
  else
  begin
    // TODO: not sure if this is right...
    lPosition := fTextView.Search(aSearchText,fTextView.SelStart,Length(fTextView.Text),[soBackward]);
    if (lPosition < 0) and aWrap then
       lPosition := fTextView.Search(aSearchText,Length(fTextView.Text),fTextView.SelStart,[soBackward]);
  end;

  if lPosition > -1 then
     fTextView.SelStart := lPosition;
  result := (lPosition > -1);
  // TODO: Still have to handle replace...

end;

procedure TGTKTextWidgetFrame.Print;
begin
  // TODO: Still have to handle this...

end;

class function TGTKTextWidgetFrame.GetFileType: String;
begin
  Result:='Dumb Binary Text File';
end;

{$ENDIF}

end.

