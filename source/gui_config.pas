unit gui_config;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, forms, fpjson;

type

  { TConfiguration }

  TConfiguration = class(TComponent)
  protected
    function GetFilename: String;
    function GetResourceName: String; virtual; abstract;
    procedure SaveToJSON(aTarget: TJSONObject); virtual; abstract;
    procedure LoadFromJSON(aSource: TJSONObject); virtual; abstract;

    function LoadJSON: TJSONObject;
  public
    constructor Create(AOwner: TComponent); override;
    procedure Save;
    procedure Load;
  end;

  { TScreenConfiguration }

  TScreenConfiguration = class(TConfiguration)
  private
    fTarget: TForm;
  protected
    function GetResourceName: String; override;
    procedure LoadFromJSON(aSource: TJSONObject); override;
    procedure SaveToJSON(aTarget: TJSONObject); override;
  public
    constructor Create(AOwner: TComponent); override;
  end;



implementation

uses
  typinfo, LCLProc, jsonparser;

{ TConfiguration }

function TConfiguration.GetFilename: String;
begin
  result := IncludeTrailingPathDelimiter(GetAppConfigDir(false)) + GetResourceName + '.json';
end;

function TConfiguration.LoadJSON: TJSONObject;
var
  lFile: String;
  lStream: TFileStream;
  lData: TJSONData;
begin
  result := nil;
  lFile := GetFilename;

  if FileExists(lFile) then
  begin
    lStream := TFileStream.Create(lFile,fmOpenRead);
    try
      lData := GetJSON(lStream);
      try
        result := lData as TJSONObject;
      finally
        if lData = nil then
          lData.Free;
      end;
    finally
      lStream.Free;
    end;
  end;

  if result = nil then
     result := TJSONObject.Create();

end;

constructor TConfiguration.Create(AOwner: TComponent);
begin
  inherited Create(AOwner);
  Load;
end;

procedure TConfiguration.Save;
var
  lFile: String;
  lStream: TFileStream;
  lJSON: TJSONObject;
  lData: String;
begin
  lFile := GetFilename;
  ForceDirectories(ExtractFileDir(lFile));
  // need to load the json first, so we have the defaults...
  lJSON := LoadJSON;
  try
    lStream := TFileStream.Create(GetFilename,fmCreate);
    try
        SaveToJSON(lJSON);
        lData := lJSON.AsJSON;
        lStream.Write(lData[1],Length(lData));
    finally
      lStream.Free;
    end;
  finally
    lJSON.Free;
  end;

end;

procedure TConfiguration.Load;
var
  lJSON: TJSONObject;
begin
  lJSON := LoadJSON;
  try
    LoadFromJSON(lJSON);
  finally
    lJSON.Free;
  end;
end;

{ TScreenConfiguration }

function TScreenConfiguration.GetResourceName: String;
begin
  result := 'screen';
end;

procedure TScreenConfiguration.LoadFromJSON(aSource: TJSONObject);
begin
  fTarget.Height := aSource.Get('height',fTarget.Height);
  fTarget.Width := aSource.Get('width',fTarget.Width);
  fTarget.WindowState := TWindowState(GetEnumValueDef(TypeInfo(TWindowState),aSource.Get('state',''),ord(fTarget.WindowState)));
end;

procedure TScreenConfiguration.SaveToJSON(aTarget: TJSONObject);
begin
  if fTarget.WindowState = wsNormal then
  begin
    // only save the dimensions if the windowstate is normal.
    // Otherwise, next time, we'll reload the original heights...
    aTarget.Add('height',fTarget.Height);
    aTarget.Add('width',fTarget.Width);
  end;
  aTarget.Add('state',GetEnumName(TypeInfo(TWindowState),ord(fTarget.WindowState)));

end;

constructor TScreenConfiguration.Create(AOwner: TComponent);
var
  lParent: TComponent;
begin
  if AOwner is TForm then
     fTarget := AOwner as TForm
  else if AOwner <> nil then
  begin
    lParent := AOwner.Owner;
    while (lParent <> nil) and (not (lParent is TForm)) do
       lParent := lParent.Owner;
    if lParent is TForm then
       fTarget := lParent as TForm;
  end;
  if fTarget = nil then
    raise Exception.Create('Screen configuration requires a form');
  inherited Create(AOwner);
end;

end.

