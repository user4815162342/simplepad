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
    class var fFileTypeFrameRegistry: TDocumentFrameClassRegistry;
    class var fFileTypeDefaultFormatRegistry: TDocumentFrameNameRegistry;
    class var fDefaultFileType: String;
    class function GetEditor(aExtension: String): TDocumentFrameClass; static;
    class function GetFileFormatIDS(aIndex: Integer): String; static;
    class function GetFileFormatNames(aExtension: String): String; static;
    class function GetFileTypeIDS(aIndex: Integer): String; static;
    class function GetFormatsForFileTypeID(aID: String): TStringArray;
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
    class function GetFileType: String; virtual;
    class function FindFormatIDForFile(aFile: TFilename): String;
    class function FindEditorForFormatID(aID: String): TDocumentFrameClass;
    class function FindEditorForFiletype(aType: String): TDocumentFrameClass;
    class function FindNameOfFormatID(aID: String): String;
    class function FindDefaultFormatID(aFileType: String): String;
    class function FindDefaultFileType: String;
    class function RegisterFormatEditor(const aFileFormat: String; aExtension: String; aFrameClass: TDocumentFrameClass; aDefaultFormat: Boolean = false): String;
    class function EditorDialogFilters(aFileType: String): String;
    class function FindExtensionForFormatFilterIndex(aFileType: String; aIndex: Integer): String;
    class function FindFormatFilterIndexForFile(aFileType: String; aFile: TFilename): Integer;
    class function FileFormatIDCount: Integer;
    class property FileFormatIDS[aIndex: Integer]: String read GetFileFormatIDS;
    class function FileTypeCount: Integer;
    class property FileTypeIDS[aIndex: Integer]: String read GetFileTypeIDS;

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

class function TDocumentFrame.GetFileTypeIDS(aIndex: Integer): String; static;
begin
  result := fFileTypeFrameRegistry.Keys[aIndex];
end;

class function TDocumentFrame.GetFormatsForFileTypeID(aID: String
  ): TStringArray;
var
  i: Integer;
  lFrame: TDocumentFrameClass;
  lExt: String;
begin
  // All Files|*|RTF Files|*.rtf...
  SetLength(result,0);
  for i := 0 to fFileFormatNameRegistry.Count - 1 do
  begin
    lExt := fFileFormatNameRegistry.Keys[i];
    if aID <> '' then
    begin
      lFrame := FindEditorForFormatID(lExt);
      if (lFrame = nil) or (lFrame.GetFileType <> aID) then
         continue;
    end;
    SetLength(Result,Length(Result) + 1);
    Result[Length(Result) - 1] := lExt;
  end;
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
  fFileTypeFrameRegistry := TDocumentFrameClassRegistry.Create;
  fFileTypeDefaultFormatRegistry := TDocumentFrameNameRegistry.Create;
end;

class destructor TDocumentFrame.Destroy;
begin
  FreeAndNil(fFileFormatNameRegistry);
  FreeAndNil(fFileFormatFrameRegistry);
  FreeAndNil(fFileTypeFrameRegistry);
  FreeAndNil(fFileTypeDefaultFormatRegistry);
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

class function TDocumentFrame.GetFileType: String;
begin
  result := 'Unknown';
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

class function TDocumentFrame.FindEditorForFiletype(aType: String
  ): TDocumentFrameClass;
var
  lIndex: Integer;
begin
  lIndex := fFileTypeFrameRegistry.IndexOf(aType);
  if lIndex >= 0 then
     result := fFileTypeFrameRegistry.Data[lIndex]
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

class function TDocumentFrame.FindDefaultFormatID(aFileType: String): String;
var
  lIndex: Integer;
begin
  lIndex := fFileTypeDefaultFormatRegistry.IndexOf(aFileType);
  if lIndex >= 0 then
     result := fFileTypeDefaultFormatRegistry.Data[lIndex]
  else
     raise Exception.Create('Unknown file type: "' + aFileType + '"');
end;

class function TDocumentFrame.FindDefaultFileType: String;
begin
  result := fDefaultFileType;
end;

class function TDocumentFrame.RegisterFormatEditor(const aFileFormat: String;
  aExtension: String; aFrameClass: TDocumentFrameClass; aDefaultFormat: Boolean
  ): String;
var
  lFileType: String;
  lIndex: Integer;
begin
  fFileFormatFrameRegistry.Add(aExtension,aFrameClass);
  fFileFormatNameRegistry.Add(aExtension,aFileFormat);
  result := aExtension;
  lFileType := aFrameClass.GetFileType;
  if fFileTypeFrameRegistry.IndexOf(lFileType) < 0 then
     fFileTypeFrameRegistry.Add(lFileType,aFrameClass);
  lIndex := fFileTypeDefaultFormatRegistry.IndexOf(lFileType);
  if (lIndex < 0) then
     fFileTypeDefaultFormatRegistry.Add(lFileType,aExtension)
  else if aDefaultFormat then
     fFileTypeDefaultFormatRegistry.Data[lIndex] := aExtension;
  if fDefaultFileType = '' then
     fDefaultFileType := aFrameClass.GetFileType;

end;

class function TDocumentFrame.EditorDialogFilters(aFileType: String): String;
var
  lList: TStringArray;
  i: Integer;
  lType: String;
  lExt: String;
begin
  // All Files|*|RTF Files|*.rtf...
  result := 'All Files|*';
  lList := GetFormatsForFileTypeID(aFileType);
  for i := 0 to Length(lList) - 1 do
  begin
    lExt := lList[i];
    lType := FindNameOfFormatID(lExt);
    result := result + '|' + lType + '|*.' + LowerCase(lExt);
  end;

end;

class function TDocumentFrame.FindExtensionForFormatFilterIndex(
  aFileType: String; aIndex: Integer): String;
var
  lList: TStringArray;
begin
  lList := GetFormatsForFileTypeID(aFileType);
  if (aIndex > 0) and (aIndex <= Length(lList)) then
  begin
     result := lList[aIndex - 1]
  end
  else
    result := FindDefaultFormatID(aFileType);

end;

class function TDocumentFrame.FindFormatFilterIndexForFile(aFileType: String;
  aFile: TFilename): Integer;
var
  lID: String;
  lList: TStringArray;
  i: Integer;
begin
  lID := FindFormatIDForFile(aFile);
  lList := GetFormatsForFileTypeID(aFileType);
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

{class function TDocumentFrame.FindFileTypeIDForFilterIndex(aIndex: Integer;
  aFilename: TFilename): String;
begin
  if (aIndex > 0) and (aIndex <= fNameRegistry.Count) then
  begin
    result := fNameRegistry.Keys[aIndex - 1];
  end
  else
    result := FindFileTypeIDForFile(aFilename);
end;}

class function TDocumentFrame.FileFormatIDCount: Integer;
begin
  result := fFileFormatFrameRegistry.Count;

end;

class function TDocumentFrame.FileTypeCount: Integer;
begin
  result := fFileTypeFrameRegistry.Count;
end;

end.

