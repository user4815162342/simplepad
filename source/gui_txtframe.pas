unit gui_txtframe;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, FileUtil, Forms, Controls, Graphics, Dialogs, StdCtrls, 
    gui_documentframe;

type

  { TTXTFrame }

  TTXTFrame = class(TDocumentFrame)
    TXTEditor: TMemo;
  private
    { private declarations }
  protected
    procedure CreateNewDocument; override;
    function GetIsModified: Boolean; override;
    procedure Save(aStream: TStream); override;
    class constructor Create;
  public
    { public declarations }
    procedure Load(aStream: TStream); override;
    procedure DisplayLoadError(aText: String); override;
    function CanUndo: Boolean; override;
    function CanRedo: Boolean; override;
    procedure Paste; override;
    procedure Copy; override;
    procedure Cut; override;
    procedure Undo; override;
    procedure Redo; override;
    procedure SelectAll; override;
  end;

implementation

{$R *.lfm}

{ TTXTFrame }

procedure TTXTFrame.CreateNewDocument;
begin
  TXTEditor.Clear;
  TXTEditor.ReadOnly := false;
  TXTEditor.Modified := false;
end;

function TTXTFrame.GetIsModified: Boolean;
begin
  result := TXTEditor.Modified;
end;

procedure TTXTFrame.Save(aStream: TStream);
begin
  TXTEditor.Lines.SaveToStream(aStream);
  TXTEditor.Modified := false;

end;

class constructor TTXTFrame.Create;
begin
  TDocumentFrame.RegisterEditor('Text File','txt',TTXTFrame);

end;

procedure TTXTFrame.Load(aStream: TStream);
begin
  TXTEditor.Lines.LoadFromStream(aStream);
  TXTEditor.Modified := false;
end;

procedure TTXTFrame.DisplayLoadError(aText: String);
begin

  TXTEditor.Clear;
  TXTEditor.Lines.Text := aText;
  TXTEditor.ReadOnly := true;
  TXTEditor.Modified := false;
end;

function TTXTFrame.CanUndo: Boolean;
begin
  Result:=TXTEditor.CanUndo;
end;

function TTXTFrame.CanRedo: Boolean;
begin
  // TODO:
  Result:=false;
end;

procedure TTXTFrame.Paste;
begin
  TXTEditor.PasteFromClipboard;
end;

procedure TTXTFrame.Copy;
begin
  TXTEditor.CopyToClipboard;
end;

procedure TTXTFrame.Cut;
begin
  TXTEditor.CutToClipboard;
end;

procedure TTXTFrame.Undo;
begin
  TXTEditor.Undo;
end;

procedure TTXTFrame.Redo;
begin
  // TODO:
end;

procedure TTXTFrame.SelectAll;
begin
  TXTEditor.SelectAll;
end;

end.

