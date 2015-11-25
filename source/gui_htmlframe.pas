unit gui_htmlframe;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, FileUtil, Forms, Controls, Graphics, Dialogs, Menus, 
    gui_documentframe, LazWebkitCtrls, LazWebkitSettings, fpjson, jsonparser, LazWebkitDownload;

type

  {
  TODO:
  - Consider the possibility of use a "Simple" version of HTML instead of html,
    wherein we're just dealing with the very basic tags. We're already doing this
    to some extent by not including the header, but there might be other things
    I need to do. This also requires 'cleaning up' the HTML when it's brought in,
    to make sure it doesn't contain tags/attributes that we can't use.

  TODO: Markdown support is not great. I've got two different tools being used for
    converting to and converting from Markdown, which means that it's quite possible
    for the markdown produced to have different appearance when pulled in. I either
    need to come up with a better JavaScript tool, or find some other way to convert.
  }

  TDocumentFormat = (dfFormattedTextMarkup, dfHTML, dfMarkdown);

  TDocumentContents = record
    Length: Integer;
    Contents: String;
  end;

  { THTMLFrame }

  THTMLFrame = class(TDocumentFrame)
    HTMLEditor: TFramedWebkitComposer;
    HTMLMenu: TPopupMenu;
    procedure HTMLEditorDownloadRequest(Sender: TObject;
      const {%H-}Download: TWebkitDownloadRequest; var Accept: Boolean);
    procedure HTMLEditorLinkActivation(Sender: TObject; {%H-}URI: String;
      var Accept: Boolean);
    procedure HTMLEditorLoaded(Sender: TObject);
    procedure HTMLEditorLoadError(Sender: TObject; const {%H-}FrameName, {%H-}URI,
      Error: String);
    procedure HTMLEditorStatusTextChange(Sender: TObject;
      const ContextText: String);
    procedure HTMLEditorUserChangeContent(Sender: TObject);
  private
    { private declarations }
    fScriptResult: String;
    class var fFTMFileTypeID: String;
    class var fHTMLFileTypeID: String;
    class var fMarkdownFileTypeID: String;
    class var fEditorHTML: String;
    class var fEditorBaseURI: String;
  protected
    procedure LoadDocument(aText: String; aFormat: TDocumentFormat);
    procedure CreateNewDocument; override;
    procedure DisplayLoadError(aText: String); override;
    procedure LoadText(aText: UTF8String; aEditorTypeID: UTF8String); override;
    function GetSaveText(aEditorTypeID: UTF8String): UTF8String; override;
    procedure ExecCommand(aCommand: String; aArgument: String);
    function EvaluateScriptExpression(aScript: String): TJSONData; overload;
    function GetEditorContents(aFormat: TDocumentFormat): TDocumentContents;
    procedure HandleScriptMessage(aCommand: String; aData: String);
    procedure OverwriteSelection(aText: String);
    class constructor Create;
  public
    { public declarations }
    function CanPaste: Boolean; override;
    function CanRedo: Boolean; override;
    function CanCut: Boolean; override;
    function CanCopy: Boolean; override;
    function CanUndo: Boolean; override;
    procedure Cut; override;
    procedure Copy; override;
    procedure Paste; override;
    procedure Undo; override;
    procedure Redo; override;
    procedure SelectAll; override;
    function FindReplace(aSearchText: String; aForward: Boolean=true; aWrap: Boolean = false;
       aDoReplace: Boolean=false; aReplaceText: String=''): boolean; override;

    procedure Print; override;

    function CanFormat: Boolean; override;

    procedure MakeFullscreen; override;
    procedure MakeNotFullscreen; override;
    procedure MakeRevealTags; override;
    procedure MakeNotRevealTags; override;

    procedure TestOfTheDay; override;

    procedure SetParagraphStyle(aFormat: TParagraphStyle); override;
    function GetParagraphStyle: TParagraphStyle; override;
    procedure ToggleTextStyle(aFormat: TTextStyle); override;
    function HasTextStyle({%H-}aFormat: TTextStyle): boolean; override;
    procedure ClearTextStyles; override;
    procedure DecreaseListIndent; override;
    procedure IncreaseListIndent; override;

  end;

implementation

uses
  gui_main;

const
  ReturnResultCommand = 'return';
  EditorFormats: array[TDocumentFormat] of UTF8String =
    ('simplepad.FTM_FORMAT','simplepad.HTML_FORMAT','simplepad.MARKDOWN_FORMAT');

{$R *.lfm}

{ THTMLFrame }

procedure THTMLFrame.HTMLEditorStatusTextChange(Sender: TObject;
  const ContextText: String);
var
  lPos: Integer;
  lCommand: String;
  lData: String;
begin
  if ContextText > '' then
  begin
    // this is the only way I can find (apart from title changing)
    // to get data from the document.
    lPos := Pos('|',ContextText);
    if lPos > 0 then
    begin
      lCommand := system.Copy(ContextText,1,lPos - 1);
      lData := system.Copy(ContextText,lPos + 1, Length(ContextText));
      HandleScriptMessage(lCommand,lData);
    end;
  end;
end;

procedure THTMLFrame.HTMLEditorLoadError(Sender: TObject; const FrameName, URI,
  Error: String);
begin
  ShowMessage('Error loading HTML: ' + Error);
end;

procedure THTMLFrame.HTMLEditorLoaded(Sender: TObject);
begin
  DoLoaded;

end;

procedure THTMLFrame.HTMLEditorDownloadRequest(Sender: TObject;
  const Download: TWebkitDownloadRequest; var Accept: Boolean);
begin
  Accept := false;
end;

procedure THTMLFrame.HTMLEditorLinkActivation(Sender: TObject; URI: String;
  var Accept: Boolean);
begin
  Accept := false;
end;

procedure THTMLFrame.HTMLEditorUserChangeContent(Sender: TObject);
begin
  SetModified;

end;

procedure THTMLFrame.LoadDocument(aText: String; aFormat: TDocumentFormat);
var
  lContents: String;
  lWindowColor: String;
  lButtonColor: String;
  lWindowTextColor: String;
  lButtonTextColor: String;
  lButtonShadowColor: String;
begin
  // TODO: Specify the format to save the document in.
  lWindowColor := '#'+HexStr(ColorToRGB(clWindow),6);
  lWindowTextColor := '#'+HexStr(ColorToRGB(clWindowText),6);
  lButtonColor := '#'+HexStr(ColorToRGB(clBtnFace),6);
  lButtonTextColor := '#'+HexStr(ColorToRGB(clBtnText),6);
  lButtonShadowColor:= '#'+HexStr(ColorToRGB(clBtnShadow),6);

  lContents := fEditorHTML;
  lContents := StringReplace(lContents,'%WINDOW_COLOR%',lWindowColor,[rfReplaceAll]);
  lContents := StringReplace(lContents,'%WINDOW_TEXT_COLOR%',lWindowTextColor,[rfReplaceAll]);
  lContents := StringReplace(lContents,'%BUTTON_FACE_COLOR%',lButtonColor,[rfReplaceAll]);
  lContents := StringReplace(lContents,'%BUTTON_TEXT_COLOR%',lButtonTextColor,[rfReplaceAll]);
  lContents := StringReplace(lContents,'%BUTTON_SHADOW_COLOR%',lButtonShadowColor,[rfReplaceAll]);
  lContents := StringReplace(lContents,'%FILE_CONTENT%', '"'+StringToJSONString(aText)+'"',[]);
  lContents := StringReplace(lContents,'%FILE_FORMAT%', EditorFormats[aFormat],[]);
  HTMLEditor.LoadContent(lContents,'text/html','UTF-8',fEditorBaseURI);

end;

procedure THTMLFrame.CreateNewDocument;
begin
  LoadDocument('<p></p>',dfHTML);
end;

procedure THTMLFrame.DisplayLoadError(aText: String);
begin
    ShowMessage('Error: ' + aText)

end;

procedure THTMLFrame.LoadText(aText: UTF8String; aEditorTypeID: UTF8String);
var
  lFormat: TDocumentFormat;
begin
  if aEditorTypeID = fHTMLFileTypeID then
  begin
      lFormat := dfHTML
  end
  else if aEditorTypeID = fMarkdownFileTypeID then
  begin
    lFormat := dfMarkdown;
  end
  else if aEditorTypeID = fFTMFileTypeID then
  begin
    lFormat := dfFormattedTextMarkup;
  end
  else
  begin
    raise Exception.Create('The HTML editor can''t convert documents from that format');
  end;
  LoadDocument(aText,lFormat);

end;

function THTMLFrame.GetSaveText(aEditorTypeID: UTF8String): UTF8String;
var
  lContents: TDocumentContents;
  lFormat: TDocumentFormat;
begin
  // Important: Don't put a semi-colon in here. It gets wrapped in parantheses.
  if aEditorTypeID = fHTMLFileTypeID then
  begin
      lFormat := dfHTML
  end
  else if aEditorTypeID = fMarkdownFileTypeID then
  begin
    lFormat := dfHTML;

  end
  else if aEditorTypeID = fFTMFileTypeID then
  begin
    lFormat := dfFormattedTextMarkup;

  end
  else
  begin
    // keep a default format so we don't lose the data...
    lFormat := dfHTML;
  end;

  lContents := GetEditorContents(lFormat);
  // I need to do some sanity checks, because I can find no specs saying that
  // there isn't a limit to the length of window.status, so this will allow me to know.
  if lContents.Length <> Length(lContents.Contents) then
     raise Exception.Create('Actual length of content (' + IntToStr(Length(lContents.Contents)) + ') does not match reported length (' + IntToStr(lContents.Length) + ').');
  result := lContents.Contents;

end;

procedure THTMLFrame.ExecCommand(aCommand: String; aArgument: String);
begin
  HTMLEditor.ExecuteScript('document.execCommand("' + aCommand + '",true,"' + aArgument + '")');
end;

function THTMLFrame.EvaluateScriptExpression(aScript: String): TJSONData;
begin
  fScriptResult := 'undefined';
  // NOTE: Only works with synchronous commands...
  HTMLEditor.ExecuteScript('window.status = "' + ReturnResultCommand + '|" + JSON.stringify(' + aScript + ')');
  if fScriptResult <> 'undefined' then
  begin
    result := GetJSON(fScriptResult);
  end
  else
     result := CreateJSON;
end;

function THTMLFrame.GetEditorContents(aFormat: TDocumentFormat
  ): TDocumentContents;
var
  lJSon: TJSONData;
  lJObject: TJSONObject;
begin
  lJSon := EvaluateScriptExpression('simplepad.getContents(' + EditorFormats[aFormat] + ')');
  try
    if lJSon.JSONType <> jtObject then
       raise Exception.Create('Invalid value returned from simplepad.getContents');
    lJObject := lJSon as TJSONObject;
    if lJObject['length'].JSONType <> jtNumber then
       raise Exception.Create('Invalid length value returned from simplepad.getContents');
    result.Contents := lJObject['contents'].AsString;
    result.Length := lJObject['length'].AsInteger;
  finally
     lJSon.Free;
  end;

end;

procedure THTMLFrame.HandleScriptMessage(aCommand: String; aData: String);
begin
  case aCommand of
    ReturnResultCommand:
      fScriptResult := aData;
    // TODO: Do something depending on the message...
  end;
end;

procedure THTMLFrame.OverwriteSelection(aText: String);
begin
  // TODO: Test this...
  HTMLEditor.ExecuteScript('simplepad.overwriteSelection("' + StringToJSONString(aText) + '")');
end;

class constructor THTMLFrame.Create;
var
  lStream: TFileStream;
  lStrings: TStringList;
  lEditorHTMLFile: String;
begin
  fFTMFileTypeID := TDocumentFrame.RegisterEditor('Formatted Text Markup File','ftm',THTMLFrame,true);
  fHTMLFileTypeID := TDocumentFrame.RegisterEditor('HTML File','html',THTMLFrame);
  fMarkdownFileTypeID := TDocumentFrame.RegisterEditor('Markdown File','md',THTMLFrame);

  fEditorBaseURI := IncludeTrailingPathDelimiter(IncludeTrailingPathDelimiter(FileUtil.ProgramDirectory) + 'resources');
  lEditorHTMLFile := fEditorBaseURI + 'gui_editor.html';
  fEditorBaseURI := 'file://' + fEditorBaseURI;

  try
    lStream := TFileStream.Create(lEditorHTMLFile,fmOpenRead);
    try
      lStrings := TStringList.Create;
      try
        lStrings.LoadFromStream(lStream);
        fEditorHTML:=lStrings.Text;

      finally
        lStrings.Free;
      end;
    finally
      lStream.Free;
    end;
  except
    on E: Exception do
       ShowMessage(E.Message);
  end;
end;

function THTMLFrame.CanPaste: Boolean;
begin
  result := HTMLEditor.CanPasteClipboard;
end;

function THTMLFrame.CanRedo: Boolean;
begin
  result := HTMLEditor.CanRedo;

end;

function THTMLFrame.CanCut: Boolean;
begin
  result := HTMLEditor.CanCutClipboard;

end;

function THTMLFrame.CanCopy: Boolean;
begin
  result := HTMLEditor.CanCopyClipboard;
end;

function THTMLFrame.CanUndo: Boolean;
begin
  result := HTMLEditor.CanUndo;

end;

procedure THTMLFrame.Cut;
begin
  HTMLEditor.CutClipboard();

end;

procedure THTMLFrame.Copy;
begin
  HTMLEditor.CopyClipboard();

end;

procedure THTMLFrame.Paste;
begin
  HTMLEditor.PasteClipboard();

end;

procedure THTMLFrame.Undo;
begin
  HTMLEditor.Undo();

end;

procedure THTMLFrame.Redo;
begin
  HTMLEditor.Redo();

end;

procedure THTMLFrame.SelectAll;
begin
  HTMLEditor.SelectAll();
end;

function THTMLFrame.FindReplace(aSearchText: String; aForward: Boolean;
  aWrap: Boolean; aDoReplace: Boolean; aReplaceText: String): boolean;
begin
  result := HTMLEditor.SearchText(aSearchText,false,aForward,aWrap);
  if result and aDoReplace then
  begin
    OverwriteSelection(aReplaceText);
  end;
end;

procedure THTMLFrame.Print;
begin
  HTMLEditor.PrintViewRequest;
end;

function THTMLFrame.CanFormat: Boolean;
begin
  Result:=true;
end;

procedure THTMLFrame.MakeFullscreen;
begin
  HTMLEditor.ExecuteScript('simplepad.turnOnFullscreen()');
end;

procedure THTMLFrame.MakeNotFullscreen;
begin
  HTMLEditor.ExecuteScript('simplepad.turnOffFullscreen()');
end;

procedure THTMLFrame.MakeRevealTags;
begin
  HTMLEditor.ExecuteScript('simplepad.turnOnRevealTags()');
end;

procedure THTMLFrame.MakeNotRevealTags;
begin
  HTMLEditor.ExecuteScript('simplepad.turnOffRevealTags()');
end;

procedure THTMLFrame.TestOfTheDay;
var
  lStream: TFileStream;
  lText: String;
begin
  if MainForm.DocumentSaveAsDialog.Execute then
  begin
    lStream := TFileStream.Create(MainForm.DocumentSaveAsDialog.FileName,fmCreate);
    try
      lText := HTMLEditor.ExtractContent(TWebkitViewContentFormat.wvcfSourceText);
      lStream.Write(lText[1],length(lText));
    finally
      lStream.Free;
    end;
  end;

end;

procedure THTMLFrame.SetParagraphStyle(aFormat: TParagraphStyle);
begin
  case aFormat of
    psNormal:
      HTMLEditor.ExecuteScript('simplepad.normalStyle();');
    psHeader1..psheader6:
      HTMLEditor.ExecuteScript('simplepad.headerStyle(' + IntToStr(ord(aFormat) - ord(psHeader1)) + ');');
    psBullettedList:
      HTMLEditor.ExecuteScript('simplepad.unorderedListStyle();');
    psNumberedList:
      HTMLEditor.ExecuteScript('simplepad.orderedListStyle();');
    psBlockQuote:
      HTMLEditor.ExecuteScript('simplepad.blockQuoteStyle();');
  end;
end;

function THTMLFrame.GetParagraphStyle: TParagraphStyle;
begin
  // TODO:
  result := psNormal;;
end;

procedure THTMLFrame.ToggleTextStyle(aFormat: TTextStyle);
begin
  case aFormat of
    tsBold:
    begin
      HTMLEditor.ExecuteScript('simplepad.toggleBold();');
    end;
    tsItalic:
      HTMLEditor.ExecuteScript('simplepad.toggleItalic();');
  end;
end;

function THTMLFrame.HasTextStyle(aFormat: TTextStyle): boolean;
begin
  result := false;
  // TODO:
end;

procedure THTMLFrame.ClearTextStyles;
begin
  HTMLEditor.ExecuteScript('simplepad.clearTextStyle();');
end;

procedure THTMLFrame.DecreaseListIndent;
begin
  // TODO:
end;

procedure THTMLFrame.IncreaseListIndent;
begin
  // TODO:
end;

end.

