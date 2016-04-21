unit gui_documentframe;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, FileUtil, Forms, Controls, fgl, Graphics, sys_types;

type

  TDocumentFrameClass = class of TDocumentFrame;

  TDocumentFrameClassRegistry = specialize TFPGMap<String,TDocumentFrameClass>;
  TDocumentFrameNameRegistry = specialize TFPGMap<String,String>;

  TParagraphStyle = (psNormal, psHeader1, psHeader2, psHeader3, psHeader4, psHeader5, psHeader6, psBullettedList, psNumberedList, psBlockQuote);
  TTextStyle = (tsBold, tsItalic);

  { TDocumentFrame }

  TDocumentFrame = class(TFrame)
  private
    { private declarations }
    fFileName: TFilename;
    fFileFormatID: String;
    fOnCaptionChanged: TNotifyEvent;
    FOnLoaded: TNotifyEvent;
    fModified: boolean;
    class var fFileFormatFrameRegistry: TDocumentFrameClassRegistry;
    class var fFileFormatNameRegistry: TDocumentFrameNameRegistry;
    class var fFrameDefaultFormatRegistry: TDocumentFrameNameRegistry;
    class var fDefaultFileFormatID: String;
    class function GetEditor(aExtension: String): TDocumentFrameClass; static;
    class function GetFileFormatIDS(aIndex: Integer): String; static;
    class function GetFileFormatNames(aExtension: String): String; static;
    class function GetFormatsForFrameClass(aFrame: TDocumentFrameClass
      ): TStringArray;
    class function GetFrameID(aFrame: TDocumentFrameClass): String;
  protected
    procedure LoadText(aText: UTF8String; aEditorTypeID: UTF8String); virtual; abstract;
    function GetSaveText(aEditorTypeID: UTF8String): UTF8String; virtual; abstract;
    procedure ClearModified; virtual;
    procedure DisplayLoadError(aText: String); virtual; abstract;
    procedure CreateNewDocument; virtual; abstract;
    function GetIsModified: Boolean; virtual;
    procedure SetOnLoaded(AValue: TNotifyEvent);
    procedure SetOnCaptionChanged(AValue: TNotifyEvent);
    procedure DoLoaded;
    procedure SetCaption;
    class constructor Create;
    class destructor Destroy;
  public
    { public declarations }
    procedure Load(aFilename: UTF8String; aFormatID: UTF8String);
    procedure New;
    procedure Save;
    procedure SaveAs(aFilename: UTF8String; aFormatID: UTF8String);
    property FileName: TFilename read fFileName;
    property FileFormatID: String read fFileFormatID;
    property IsModified: Boolean read GetIsModified;
    procedure SetModified; virtual;
    // regular editing actions
    function CanPaste: Boolean; virtual;
    function CanRedo: Boolean; virtual;
    function CanCut: Boolean; virtual;
    function CanCopy: Boolean; virtual;
    function CanUndo: Boolean; virtual;
    procedure Cut; virtual;
    procedure Copy; virtual;
    procedure Paste; virtual;
    procedure Undo; virtual;
    procedure Redo; virtual;
    procedure SelectAll; virtual;
    function FindReplace(aSearchText: String; aForward: Boolean = true; aWrap: Boolean = false; aDoReplace: Boolean = false; aReplaceText: String = ''): Boolean; virtual; abstract;
    // formatted editing actions
    function CanFormat: Boolean; virtual; deprecated;
    procedure SetParagraphStyle({%H-}aFormat: TParagraphStyle); virtual; deprecated;
    function GetParagraphStyle: TParagraphStyle; virtual; deprecated;
    procedure ToggleTextStyle({%H-}aFormat: TTextStyle); virtual; deprecated;
    function HasTextStyle({%H-}aFormat: TTextStyle): boolean; virtual; deprecated;
    procedure ClearTextStyles; virtual; deprecated;
    procedure DecreaseListIndent; virtual; deprecated;
    procedure IncreaseListIndent; virtual; deprecated;

    procedure MakeNotFullscreen; virtual;
    procedure MakeFullscreen; virtual;
    procedure MakeRevealTags; virtual;
    procedure MakeNotRevealTags; virtual;

    procedure Print; virtual; abstract;

    property OnLoaded: TNotifyEvent read FOnLoaded write SetOnLoaded;
    property OnCaptionChanged: TNotifyEvent read fOnCaptionChanged write SetOnCaptionChanged;

    procedure TestOfTheDay; virtual;


    // class factory stuff... file types...


    // class factory stuff for file types and format...
    // a file type is a general file type, like "Formatted Text", etc.
    // A given TDocumentFrame can only ever handle one file type.
    // a file format is a specific format for loading and saving the document.
    // A given TDocumentFrame can handle loading and saving to multiple formats.

    // returns the specified file type for the given document frame class.
    class function FindFormatIDForFile(aFile: TFilename): String;
    class function FindEditorForFormatID(aID: String): TDocumentFrameClass;
    class function FindNameOfFormatID(aID: String): String;
    class function FindDefaultFormatID(aFrame: TDocumentFrameClass): String;
    class function FindDefaultFormatID: String;
    class function RegisterFormatEditor(const aFileFormat: String; aExtension: String; aFrameClass: TDocumentFrameClass; aDefaultFormat: Boolean = false): String;
    class function EditorDialogFilters(aFrame: TDocumentFrameClass): String;
    function EditorDialogFilters: String;
    class function FindExtensionForFormatFilterIndex(aFrame: TDocumentFrameClass;
      aIndex: Integer): String;
    function FindExtensionForFormatFilterIndex(aIndex: Integer): String;
    class function FindFormatFilterIndexForFile(aFrame: TDocumentFrameClass;
      aFile: TFilename): Integer;
    function FindFormatFilterIndexForFile: Integer;
    class function FileFormatIDCount: Integer;
    class property FileFormatIDS[aIndex: Integer]: String read GetFileFormatIDS;

  end;

implementation


uses
  strutils;

{$R *.lfm}

{ TDocumentFrame }

class function TDocumentFrame.GetEditor(aExtension: String
  ): TDocumentFrameClass; static;
begin
  result := fFileFormatFrameRegistry[aExtension];
end;

class function TDocumentFrame.GetFileFormatIDS(aIndex: Integer): String; static;
begin
  result := fFileFormatFrameRegistry.Keys[aIndex];
end;

class function TDocumentFrame.GetFileFormatNames(aExtension: String): String;
  static;
begin
  result := fFileFormatNameRegistry[aExtension];
end;

class function TDocumentFrame.GetFormatsForFrameClass(aFrame: TDocumentFrameClass): TStringArray;
var
  i: Integer;
  lExt: String;
begin
  // All Files|*|RTF Files|*.rtf...
  SetLength(result,0);
  for i := 0 to fFileFormatFrameRegistry.Count - 1 do
  begin
    if (aFrame <> nil) and (fFileFormatFrameRegistry.Data[i] <> aFrame) then
       continue;
    lExt := fFileFormatFrameRegistry.Keys[i];
    SetLength(Result,Length(Result) + 1);
    Result[Length(Result) - 1] := lExt;
  end;
end;

class function TDocumentFrame.GetFrameID(aFrame: TDocumentFrameClass): String;
begin
  result := aFrame.UnitName + aFrame.ClassName;
end;

procedure TDocumentFrame.SetOnCaptionChanged(AValue: TNotifyEvent);
begin
  if fOnCaptionChanged=AValue then Exit;
  fOnCaptionChanged:=AValue;
end;

procedure TDocumentFrame.ClearModified;
begin
  fModified := false;
  SetCaption;
end;

function TDocumentFrame.GetIsModified: Boolean;
begin
  result := fModified;
end;

procedure TDocumentFrame.SetOnLoaded(AValue: TNotifyEvent);
begin
  if FOnLoaded=AValue then Exit;
  FOnLoaded:=AValue;
end;

procedure TDocumentFrame.DoLoaded;
begin
  if FOnLoaded <> nil then
     FOnLoaded(Self);
end;

procedure TDocumentFrame.SetCaption;
var
  lCaption: String;
begin
  if fFileName = '' then
     lCaption := '(Untitled)'
  else
  begin
     lCaption := ExtractFileName(fFileName);
     if not FileExists(fFileName) then
        lCaption := '(' + lCaption + ')';
  end;
  if IsModified then
     lCaption := lCaption + '*';
  if Caption <> lCaption then
  begin
    Caption := lCaption;
    if fOnCaptionChanged <> nil then
      fOnCaptionChanged(Self);
  end;
end;

class constructor TDocumentFrame.Create;
begin
  fFileFormatFrameRegistry := TDocumentFrameClassRegistry.Create;
  fFileFormatNameRegistry := TDocumentFrameNameRegistry.Create;
  fFrameDefaultFormatRegistry := TDocumentFrameNameRegistry.Create;
end;

class destructor TDocumentFrame.Destroy;
begin
  FreeAndNil(fFileFormatNameRegistry);
  FreeAndNil(fFileFormatFrameRegistry);
  FreeAndNil(fFrameDefaultFormatRegistry);
end;

procedure TDocumentFrame.Load(aFilename: UTF8String; aFormatID: UTF8String);
var
  lStream: TFileStream;
  lString: TStringStream;
begin
  fFileName := aFilename;
  fFileFormatID := aFormatID;
  SetCaption;
  if FileExists(aFilename) then
  begin
    try
      lStream := TFileStream.Create(aFilename,fmOpenRead);
      try
        lString := TStringStream.Create('');
        try
          lString.CopyFrom(lStream,0);
          LoadText(lString.DataString,aFormatID);
          ClearModified;
        finally
          lString.Free;
        end;
      finally
        lStream.Free;
      end;

    except
      on E: Exception do
      begin
         DisplayLoadError('Unable to open file: ' + aFilename);
      end;
    end;
  end
  else
  begin
    // we are creating it with a file that does not exist. Create a new document
    // instead. This allows you to create and edit the file from a command
    // line, which is really convenient.
    CreateNewDocument;
    ClearModified;
  end;
end;

procedure TDocumentFrame.New;
begin
  fFileName := '';
  fFileFormatID:= '';
  SetCaption;
  CreateNewDocument;
  ClearModified;
end;

procedure TDocumentFrame.Save;
begin
  if fFileName = '' then
     raise Exception.Create('No filename has been specified. Please use "SaveAs"');

  SaveAs(fFileName,fFileFormatID);
end;

procedure TDocumentFrame.SaveAs(aFilename: UTF8String; aFormatID: UTF8String
  );
var
  lStream: TFileStream;
  lText: UTF8String;
begin
  // First things first, get the text in appropriate save format, because
  // if we can't save in this format then an error should be raised
  // immediately.
  lText := GetSaveText(aFormatID);
  fFileName := aFilename;
  fFileFormatID := aFormatID;
  SetCaption;
  lStream := TFileStream.Create(aFilename,fmCreate);
  try
    lStream.Write(lText[1],Length(lText));
    ClearModified;
  finally
    lStream.Free;
  end;

end;

procedure TDocumentFrame.SetModified;
begin
  fModified := true;
  SetCaption;
end;

function TDocumentFrame.CanPaste: Boolean;
begin
  // Must be overridden
  // This seems to be handled completely by the control,
  // so I don't know how to turn this off if there's nothing useful to paste.
  result := true;
end;

function TDocumentFrame.CanRedo: Boolean;
begin
  // Must be overridden
  result := false;

end;

function TDocumentFrame.CanCut: Boolean;
begin
  // Must be overridden
  // This seems to be handled completely by the control,
  // so I don't know how to turn this off.
  result := true;
end;

function TDocumentFrame.CanCopy: Boolean;
begin
  // Must be overridden
  // This seems to be handled completely by the control,
  // so I don't know how to turn this off.
  result := true;
end;

function TDocumentFrame.CanUndo: Boolean;
begin
  // Must be overridden
  result := false;

end;

procedure TDocumentFrame.Cut;
begin
  // Must be overridden

end;

procedure TDocumentFrame.Copy;
begin
  // Must be overridden

end;

procedure TDocumentFrame.Paste;
begin
  // Must be overridden

end;

procedure TDocumentFrame.Undo;
begin
  // Must be overridden

end;

procedure TDocumentFrame.Redo;
begin
  // Must be overridden

end;

procedure TDocumentFrame.SelectAll;
begin
  // Must be overridden

end;

procedure TDocumentFrame.DecreaseListIndent;
begin
  // Must be overridden

end;

procedure TDocumentFrame.IncreaseListIndent;
begin
  // Must be overridden

end;

procedure TDocumentFrame.MakeNotFullscreen;
begin

end;

procedure TDocumentFrame.MakeFullscreen;
begin

end;

procedure TDocumentFrame.MakeRevealTags;
begin

end;

procedure TDocumentFrame.MakeNotRevealTags;
begin

end;

procedure TDocumentFrame.TestOfTheDay;
begin

end;

function TDocumentFrame.CanFormat: Boolean;
begin
  result := false;
end;

procedure TDocumentFrame.SetParagraphStyle(aFormat: TParagraphStyle);
begin
  // Must be overridden
end;

function TDocumentFrame.GetParagraphStyle: TParagraphStyle;
begin
  result := psNormal;
  // Must be overridden
end;

procedure TDocumentFrame.ToggleTextStyle(aFormat: TTextStyle);
begin
  // Must be overridden
end;

function TDocumentFrame.HasTextStyle(aFormat: TTextStyle): boolean;
begin
  result := false;
  // Must be overridden

end;

procedure TDocumentFrame.ClearTextStyles;
begin
  // Must be overridden

end;

class function TDocumentFrame.FindFormatIDForFile(aFile: TFilename): String;
begin
  result := TrimLeftSet(LowerCase(ExtractFileExt(aFile)),['.']);
end;

class function TDocumentFrame.FindEditorForFormatID(aID: String): TDocumentFrameClass;
var
  lIndex: Integer;
begin
  lIndex := fFileFormatFrameRegistry.IndexOf(aID);
  if lIndex >= 0 then
     result := fFileFormatFrameRegistry.Data[lIndex]
  else
     result := nil;

end;

class function TDocumentFrame.FindNameOfFormatID(aID: String): String;
var
  lIndex: Integer;
begin
  lIndex := fFileFormatNameRegistry.IndexOf(aID);
  if lIndex >= 0 then
     result := fFileFormatNameRegistry.Data[lIndex]
  else
     result := '';

end;

class function TDocumentFrame.FindDefaultFormatID(aFrame: TDocumentFrameClass): String;
var
  lIndex: Integer;
begin
  lIndex := fFrameDefaultFormatRegistry.IndexOf(GetFrameID(aFrame));
  if lIndex >= 0 then
     result := fFrameDefaultFormatRegistry.Data[lIndex]
  else
     raise Exception.Create('Unregistered frame: "' + GetFrameID(aFrame) + '"');
end;

class function TDocumentFrame.FindDefaultFormatID: String;
begin
  result := fDefaultFileFormatID;
end;

class function TDocumentFrame.RegisterFormatEditor(const aFileFormat: String;
  aExtension: String; aFrameClass: TDocumentFrameClass; aDefaultFormat: Boolean
  ): String;
var
  lFrameID: String;
  lIndex: Integer;
begin
  fFileFormatFrameRegistry.Add(aExtension,aFrameClass);
  fFileFormatNameRegistry.Add(aExtension,aFileFormat);
  result := aExtension;
  lFrameID := GetFrameID(aFrameClass);
  lIndex := fFrameDefaultFormatRegistry.IndexOf(lFrameID);
  if (lIndex < 0) then
     fFrameDefaultFormatRegistry.Add(lFrameID,aExtension)
  else if aDefaultFormat then
     fFrameDefaultFormatRegistry.Data[lIndex] := aExtension;
  if fDefaultFileFormatID = '' then
     fDefaultFileFormatID := result;

end;

class function TDocumentFrame.EditorDialogFilters(aFrame: TDocumentFrameClass): String;
var
  lList: TStringArray;
  i: Integer;
  lType: String;
  lExt: String;
begin
  // All Files|*|RTF Files|*.rtf...
  result := 'All Files|*';
  lList := GetFormatsForFrameClass(aFrame);
  for i := 0 to Length(lList) - 1 do
  begin
    lExt := lList[i];
    lType := FindNameOfFormatID(lExt);
    result := result + '|' + lType + '|*.' + LowerCase(lExt);
  end;

end;

function TDocumentFrame.EditorDialogFilters: String;
begin
  result := TDocumentFrame.EditorDialogFilters(TDocumentFrameClass(Self.ClassType));
end;

class function TDocumentFrame.FindExtensionForFormatFilterIndex(
  aFrame: TDocumentFrameClass; aIndex: Integer): String;
var
  lList: TStringArray;
begin
  lList := GetFormatsForFrameClass(aFrame);
  if (aIndex > 0) and (aIndex <= Length(lList)) then
  begin
     result := lList[aIndex - 1]
  end
  else
    result := FindDefaultFormatID(aFrame);

end;

function TDocumentFrame.FindExtensionForFormatFilterIndex(aIndex: Integer
  ): String;
begin
  result := FindExtensionForFormatFilterIndex(TDocumentFrameClass(Self.ClassType),aIndex);
end;

class function TDocumentFrame.FindFormatFilterIndexForFile(aFrame: TDocumentFrameClass;
  aFile: TFilename): Integer;
var
  lID: String;
  lList: TStringArray;
  i: Integer;
begin
  lID := FindFormatIDForFile(aFile);
  lList := GetFormatsForFrameClass(aFrame);
  for i := 0 to Length(lList) - 1 do
  begin
    if lList[i] = lID then
    begin
      result := i + 1;
      exit;
    end;
  end;
  result := -1;
end;

function TDocumentFrame.FindFormatFilterIndexForFile: Integer;
begin
  result := FindFormatFilterIndexForFile(TDocumentFrameClass(Self.ClassType),Self.FileName);
end;

class function TDocumentFrame.FileFormatIDCount: Integer;
begin
  result := fFileFormatFrameRegistry.Count;

end;

end.

