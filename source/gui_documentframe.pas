unit gui_documentframe;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, FileUtil, Forms, Controls, fgl, Graphics;

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
    fFileTypeID: String;
    FOnLoaded: TNotifyEvent;
    class var fFrameRegistry: TDocumentFrameClassRegistry;
    class var fNameRegistry: TDocumentFrameNameRegistry;
    class var fDefaultID: String;
    class function GetEditor(aExtension: String): TDocumentFrameClass; static;
    class function GetFileTypeIDS(aIndex: Integer): String; static;
    class function GetFileTypeNames(aExtension: String): String; static;
  protected
    procedure LoadText(aText: UTF8String; aEditorTypeID: UTF8String); virtual; abstract;
    function GetSaveText(aEditorTypeID: UTF8String): UTF8String; virtual; abstract;
    procedure ClearModified; virtual; abstract;
    procedure DisplayLoadError(aText: String); virtual; abstract;
    procedure CreateNewDocument; virtual; abstract;
    function GetIsModified: Boolean; virtual; abstract;
    procedure SetOnLoaded(AValue: TNotifyEvent);
    procedure DoLoaded;
    class constructor Create;
    class destructor Destroy;
  public
    { public declarations }
    procedure Load(aFilename: UTF8String; aEditorTypeID: UTF8String);
    procedure New;
    procedure Save;
    procedure SaveAs(aFilename: UTF8String; aEditorTypeID: UTF8String);
    property FileName: TFilename read fFileName;
    property FileTypeID: String read fFileTypeID;
    property IsModified: Boolean read GetIsModified;
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

    procedure Print; virtual; abstract;

    property OnLoaded: TNotifyEvent read FOnLoaded write SetOnLoaded;

    procedure TestOfTheDay; virtual;



    // class factory stuff...
    class function FindFileTypeIDForFile(aFile: TFilename): String;
    class function FindEditorForID(aID: String): TDocumentFrameClass;
    class function FindFileTypeNameForID(aID: String): String;
    class function FindDefaultFileTypeID: String;
    class function RegisterEditor(const aFileType: String; aExtension: String; aFrameClass: TDocumentFrameClass; aDefault: Boolean = false): String;
    class function EditorDialogFilters: String;
    class function FindFileTypeIDForFilterIndex(aIndex: Integer; aFilename: TFilename): String;
    class function FileTypeIDCount: Integer;
    class property FileTypeIDS[aIndex: Integer]: String read GetFileTypeIDS;
  end;

implementation

uses
  ComCtrls, strutils;

{$R *.lfm}

{ TDocumentFrame }

class function TDocumentFrame.GetEditor(aExtension: String
  ): TDocumentFrameClass; static;
begin
  result := fFrameRegistry[aExtension];
end;

class function TDocumentFrame.GetFileTypeIDS(aIndex: Integer): String; static;
begin
  result := fFrameRegistry.Keys[aIndex];
end;

class function TDocumentFrame.GetFileTypeNames(aExtension: String): String;
  static;
begin
  result := fNameRegistry[aExtension];
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

class constructor TDocumentFrame.Create;
begin
  fFrameRegistry := TDocumentFrameClassRegistry.Create;
  fNameRegistry := TDocumentFrameNameRegistry.Create;
end;

class destructor TDocumentFrame.Destroy;
begin
  FreeAndNil(fNameRegistry);
  FreeAndNil(fFrameRegistry);
end;

procedure TDocumentFrame.Load(aFilename: UTF8String; aEditorTypeID: UTF8String);
var
  lStream: TFileStream;
  lString: TStringStream;
begin
  fFileName := aFilename;
  fFileTypeID := aEditorTypeID;
  if Parent is TTabSheet then
     (Parent as TTabSheet).Caption := ExtractFileNameOnly(aFilename);
  try
    lStream := TFileStream.Create(aFilename,fmOpenRead);
    try
      lString := TStringStream.Create('');
      try
        lString.CopyFrom(lStream,0);
        LoadText(lString.DataString,aEditorTypeID);
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
end;

procedure TDocumentFrame.New;
begin
  fFileName := '';
  fFileTypeID:= '';
  if Parent is TTabSheet then
     (Parent as TTabSheet).Caption := 'Untitled';
  CreateNewDocument;
  ClearModified;
end;

procedure TDocumentFrame.Save;
begin
  if fFileName = '' then
     raise Exception.Create('No filename has been specified. Please use "SaveAs"');

  SaveAs(fFileName,fFileTypeID);
end;

procedure TDocumentFrame.SaveAs(aFilename: UTF8String; aEditorTypeID: UTF8String
  );
var
  lStream: TFileStream;
  lText: UTF8String;
begin
  // First things first, get the text in appropriate save format, because
  // if we can't save in this format then an error should be raised
  // immediately.
  lText := GetSaveText(aEditorTypeID);
  fFileName := aFilename;
  fFileTypeID := aEditorTypeID;
  lStream := TFileStream.Create(aFilename,fmCreate);
  try
    lStream.Write(lText[1],Length(lText));
    ClearModified;
    if Parent is TTabSheet then
       (Parent as TTabSheet).Caption := ExtractFileNameOnly(aFilename);
  finally
    lStream.Free;
  end;

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

class function TDocumentFrame.FindFileTypeIDForFile(aFile: TFilename): String;
begin
  result := TrimLeftSet(LowerCase(ExtractFileExt(aFile)),['.']);
end;

class function TDocumentFrame.FindEditorForID(aID: String): TDocumentFrameClass;
var
  lIndex: Integer;
begin
  lIndex := fFrameRegistry.IndexOf(aID);
  if lIndex >= 0 then
     result := fFrameRegistry.Data[lIndex]
  else
     result := nil;

end;

class function TDocumentFrame.FindFileTypeNameForID(aID: String): String;
var
  lIndex: Integer;
begin
  lIndex := fNameRegistry.IndexOf(aID);
  if lIndex >= 0 then
     result := fNameRegistry.Data[lIndex]
  else
     result := '';

end;

class function TDocumentFrame.FindDefaultFileTypeID: String;
begin
  result := fDefaultID;
end;

class function TDocumentFrame.RegisterEditor(const aFileType: String;
  aExtension: String; aFrameClass: TDocumentFrameClass; aDefault: Boolean
  ): String;
begin
  if aDefault or (fDefaultID = '') then
     fDefaultID := aExtension;
  fFrameRegistry.Add(aExtension,aFrameClass);
  fNameRegistry.Add(aExtension,aFileType);
  result := aExtension;

end;

class function TDocumentFrame.EditorDialogFilters: String;
var
  i: Integer;
  lType: String;
  lExt: String;
begin
  // All Files|*|RTF Files|*.rtf...
  result := 'All Files|*';
  for i := 0 to fNameRegistry.Count - 1 do
  begin
    lExt := fNameRegistry.Keys[i];
    lType := fNameRegistry.Data[i];
    result := result + '|' + lType + '|*.' + LowerCase(lExt);
  end;

end;

class function TDocumentFrame.FindFileTypeIDForFilterIndex(aIndex: Integer;
  aFilename: TFilename): String;
begin
  if (aIndex > 0) and (aIndex <= fNameRegistry.Count) then
  begin
    result := fNameRegistry.Keys[aIndex - 1];
  end
  else
    result := FindFileTypeIDForFile(aFilename);
end;

class function TDocumentFrame.FileTypeIDCount: Integer;
begin
  result := fFrameRegistry.Count;

end;

end.

