unit gui_gtktextwidgetframe;

{$mode objfpc}{$H+}

interface

{$IFDEF LCLGTK2}
uses
  Classes, SysUtils, FileUtil, Forms, Controls, Graphics, Dialogs,
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
  lStart: TTextIter;
  lSelStart: TTextIter;
  lSelEnd: TTextIter;
  lMatchStart: TTextIter;
  lMatchEnd: TTextIter;

begin
  fTextView.Buffer.SelectionBounds(lSelStart,lSelEnd);
  if aForward then
  begin
    if aWrap then
    begin
      lStart := fTextView.Buffer.StartIter;
      result := lStart.ForwardSearch(aSearchText,[sfTextOnly,sfVisibleOnly],lMatchStart,lMatchEnd,lSelStart);
    end
    else
      result := lSelEnd.ForwardSearch(aSearchText,[sfTextOnly,sfVisibleOnly],lMatchStart,lMatchEnd,fTextView.Buffer.EndIter);
  end
  else
  begin
    if aWrap then
    begin
      lStart := fTextView.Buffer.EndIter;
      result := lStart.BackwardSearch(aSearchText,[sfTextOnly,sfVisibleOnly],lMatchStart,lMatchEnd,lSelEnd);
    end
    else
      result := lSelStart.BackwardSearch(aSearchText,[sfTextOnly,sfVisibleOnly],lMatchStart,lMatchEnd,fTextView.Buffer.StartIter);
  end;

  if result then
  begin
    fTextView.Buffer.SelectRange(lMatchStart,lMatchEnd);
  end;
  // TODO: Still have to handle replace...

end;

procedure TGTKTextWidgetFrame.Print;
begin
  // TODO: Still have to handle this...

end;

{$ENDIF}

end.

