unit gui_main;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, FileUtil, Forms, Controls, Graphics, Dialogs, ComCtrls,
  ActnList, Menus, ExtCtrls, StdCtrls, Buttons, simpleipc, gui_documentframe,
  sys_types, gui_config;

type
  // TODO: "Project Explorer" should be more configurable... we should be able
  // to set which project is open.

  TUpdateActionEvent = procedure(Sender: TAction; var aEnabled: Boolean; var aChecked: Boolean; var aVisible: Boolean) of object;

  { TAppAction }

  TAppAction = class(TAction)
  private
    FAssignedToMenu: Boolean;
    FOnUpdateAction: TUpdateActionEvent;
    procedure SetAssignedToMenu(AValue: Boolean);
    procedure SetOnUpdateAction(AValue: TUpdateActionEvent);
  public
    function Update: Boolean; override;
    property AssignedToMenu: Boolean read FAssignedToMenu write SetAssignedToMenu;
    property OnUpdateAction: TUpdateActionEvent read FOnUpdateAction write SetOnUpdateAction;
  end;

  { TNewDocumentAction }

  TNewDocumentAction = class(TAppAction)
  private
    fFileType: String;
    procedure SetFileType(AValue: String);
  public
    property FileType: String read fFileType write SetFileType;
  end;

  EMaxProjectSizeReached = class(Exception);

  TOpenAfterLoad = class;

  { TMainForm }
  TMainForm = class(TForm)
    FindPreviousButton: TButton;
    FindNextButton: TButton;
    LeftSidebar: TPanel;
    ReplaceCheckbox: TCheckBox;
    FindEdit: TEdit;
    ReplaceEdit: TEdit;
    FindLabel: TLabel;
    MainFormActions: TActionList;
    DocumentTabs: TPageControl;
    MainFormMenu: TMainMenu;
    DocumentOpenDialog: TOpenDialog;
    DocumentSaveAsDialog: TSaveDialog;
    FindReplacePanel: TPanel;
    CloseFindReplacePanelButton: TSpeedButton;
    LeftSidebarSplitter: TSplitter;
    ProjectTreeView: TTreeView;
    ProjectOpenDialog: TSelectDirectoryDialog;
    procedure CloseFindReplacePanelButtonClick(Sender: TObject);
    procedure DocumentCaptionChanged(Sender: TObject);
    procedure DocumentFrameLoaded(Sender: TObject);
    procedure DocumentTabsChange(Sender: TObject);
    procedure DocumentTabsCloseTabClicked(Sender: TObject);
    procedure FindEditKeyUp(Sender: TObject; var Key: Word; {%H-}Shift: TShiftState);
    procedure FormClose(Sender: TObject; var {%H-}CloseAction: TCloseAction);
    procedure FormCloseQuery(Sender: TObject; var CanClose: boolean);
    procedure FormCreate(Sender: TObject);
    procedure FormKeyDown(Sender: TObject; var Key: Word; {%H-}Shift: TShiftState);
    procedure FormKeyUp(Sender: TObject; var Key: Word; {%H-}Shift: TShiftState);
    procedure FormShow(Sender: TObject);
    procedure FormWindowStateChange(Sender: TObject);
    procedure IPCServer_CheckMessage(Sender: TObject);
    procedure IPCServer_ReceiveMessage(Sender: TObject);
    procedure ProjectTreeViewDblClick(Sender: TObject);
    procedure RegisterAction(const aName: UTF8String;
      const aMenuCaption: UTF8String; const aFullCaption: UTF8String;
  aExecute: TNotifyEvent = nil; aUpdate: TUpdateActionEvent = nil);
    procedure RegisterNewFileAction(const aFileType: String);
    procedure ReplaceCheckboxClick(Sender: TObject);
    procedure ReplaceEditKeyUp(Sender: TObject; var Key: Word;
      {%H-}Shift: TShiftState);
    procedure UpdateCheckGrammarAction(Sender: TAction; var aEnabled: Boolean;
      var {%H-}aChecked: Boolean; var {%H-}aVisible: Boolean);
    procedure UpdateCheckSpellingAction(Sender: TAction; var aEnabled: Boolean;
      var {%H-}aChecked: Boolean; var {%H-}aVisible: Boolean);
    procedure UpdateCopyAction(Sender: TAction; var aEnabled: Boolean;
      var {%H-}aChecked: Boolean;{%H-} var aVisible: Boolean);
    procedure UpdateFindNextAction(Sender: TAction; var aEnabled: Boolean;
      var {%H-}aChecked: Boolean;{%H-} var aVisible: Boolean);
    procedure UpdateFindPreviousAction(Sender: TAction; var aEnabled: Boolean;
      var {%H-}aChecked: Boolean; var {%H-}aVisible: Boolean);
    procedure UpdateFormatAction(Sender: TAction; var {%H-}aEnabled: Boolean;
      var {%H-}aChecked: Boolean; var {%H-}aVisible: Boolean);
    procedure UpdatePasteAction(Sender: TAction; var aEnabled: Boolean;
      var {%H-}aChecked: Boolean; var {%H-}aVisible: Boolean);
    procedure UpdateListAction(Sender: TAction; var {%H-}aEnabled: Boolean;
      var {%H-}aChecked: Boolean;{%H-} var aVisible: Boolean);
    procedure UpdateRedoAction(Sender: TAction; var aEnabled: Boolean;
      var {%H-}aChecked: Boolean;{%H-} var aVisible: Boolean);
    procedure UpdateSaveFileAction(Sender: TAction; var aEnabled: Boolean;
      var {%H-}aChecked: Boolean;{%H-} var aVisible: Boolean);
    procedure UpdateCutAction(Sender: TAction; var aEnabled: Boolean;
      var {%H-}aChecked: Boolean;{%H-} var aVisible: Boolean);
    procedure UpdateUndoAction(Sender: TAction; var aEnabled: Boolean;
      var {%H-}aChecked: Boolean;{%H-} var aVisible: Boolean);
  private
    { private declarations }
    fIPCServer: TSimpleIPCServer;
    fIPCClient: TSimpleIPCClient;
    fOpenAfterLoad: TOpenAfterLoad;
    fScreenConfiguration: TScreenConfiguration;
    fFullscreen: Boolean;
    fRevealTags: Boolean;
    fOriginalState: TWindowState;
    fProjectDirectory: UTF8String;
    const fMaxProjectSize = 4096;
    procedure InitializeIPCServer;
    procedure InitializeIPCClient;
    procedure SetupDialogs;
    procedure RegisterActions;
    procedure BuildMenu;
    procedure AssignKeyboardShortcuts;
    function CreateFrame(aEditorType: TDocumentFrameClass): TDocumentFrame;
    function SaveFrame(aFrame: TDocumentFrame): Boolean;
    function SaveFrameAs(aFrame: TDocumentFrame): Boolean;
    function CloseTab(aTab: TTabSheet): Boolean;
    function CanCloseTab(aTab: TTabSheet): Boolean;
    function GetFrame(index: Integer): TDocumentFrame;
    function GetFrame(aTab: TTabsheet): TDocumentFrame;
    function GetTab(aFrame: TDocumentFrame): TTabSheet;
    function GetCurrentFrame: TDocumentFrame;
    function HasFrame: Boolean;
    procedure ToggleFullscreen;
    procedure FullScreenChanged; virtual;
    procedure ToggleRevealTags;
    procedure ToggleProjectExplorer;
    function IsProjectExplorerVisible: Boolean;
    procedure HideProjectExplorer;
    procedure ShowProjectExplorer;
    procedure ShowMenu;
    procedure HideMenu;
    procedure ShowTabs;
    procedure HideTabs;
    procedure SetCaption;
    procedure MakeDocumentsNotFullscreen;
    procedure MakeDocumentsFullscreen;
    procedure MakeDocumentsNotRevealTags;
    procedure MakeDocumentsRevealTags;
    procedure NotImplemented(aFunction: String);
    procedure LoadProjectFiles(aDirectory: UTF8String; aNode: TTreeNode;
      var vCounter: Longint);
  public
    { public declarations }
    procedure OpenFile(aFileName: UTF8String); overload;
    procedure OpenFile(aFileName: UTF8String; aEditorType: TDocumentFrameClass;
      aEditorFormatID: String);
    procedure OpenProject(aDirectoryName: UTF8String);
    procedure RefreshProjectView;
    procedure NewFile(aEditorType: TDocumentFrameClass);
    procedure CloseCurrentTabAction(Sender: TObject);
    procedure ExecuteAboutAction(Sender: TObject);
    procedure OpenFileAction(Sender: TObject);
    procedure QuitApplicationAction(Sender: TObject);
    procedure SaveAllFilesAction(Sender: TObject);
    procedure SaveFileAction(Sender: TObject);
    procedure SaveFileAsAction(Sender: TObject);
    procedure PrintAction(Sender: TObject);
    procedure BodyTextAction(Sender: TObject);
    procedure BoldAction(Sender: TObject);
    procedure BullettedListAction(Sender: TObject);
    procedure CheckSpellingAction(Sender: TObject);
    procedure ClearFormattingAction(Sender: TObject);
    procedure CopyAction(Sender: TObject);
    procedure CutAction(Sender: TObject);
    procedure DecreaseIndentAction(Sender: TObject);
    procedure FindAction(Sender: TObject);
    procedure FindNextAction(Sender: TObject);
    procedure FindPreviousAction(Sender: TObject);
    procedure FullscreenAction(Sender: TObject);
    procedure HeaderAction(Sender: TObject);
    procedure IncreaseIndentAction(Sender: TObject);
    procedure ItalicAction(Sender: TObject);
    procedure NumberedListAction(Sender: TObject);
    procedure PasteAction(Sender: TObject);
    procedure RedoAction(Sender: TObject);
    procedure ReplaceAction(Sender: TObject);
    procedure SelectAllAction(Sender: TObject);
    procedure UndoAction(Sender: TObject);
    procedure NewFileAction(Sender: TObject);
    procedure BlockQuoteAction(Sender: TObject);
    procedure CheckGrammarAction(Sender: TObject);
    procedure NextTabAction(Sender: TObject);
    procedure OpenProjectAction(Sender: TObject);
    procedure PreviousTabAction(Sender: TObject);
    procedure RevealTagsAction(Sender: TObject);
    procedure ToggleProjectExplorerAction(Sender: TObject);
    procedure TestOfTheDayAction(Sender: TObject);
  end;

  { TOpenAfterLoad }

  TOpenAfterLoad = class(TComponent)
    procedure ApplicationLoaded(Sender: TObject; var {%H-}Done: Boolean);
  private
    fFiles: TStringArray;
    fMainForm: TMainForm;
    fLoaded: Boolean;
  public
    constructor Create(AOwner: TComponent); override;
    procedure AddFile(aFilename: String);
    property Loaded: Boolean read fLoaded;
  end;




var
  MainForm: TMainForm;

const
  IPCIdentifier = 'simplepad.townsedgetechnology.com';
  IPCOpenFileMessage = 1;
  IPCBringToFrontMessage = 2;

implementation

uses
  LCLType, LCLProc, LCLStrConsts;

{$R *.lfm}


{ TOpenAfterLoad }

procedure TOpenAfterLoad.ApplicationLoaded(Sender: TObject; var Done: Boolean);
var
  i: Integer;
begin
  fLoaded := true;
  Application.RemoveOnIdleHandler(@ApplicationLoaded);
  if Length(fFiles) > 0 then
  begin
    for i := 0 to Length(fFiles) - 1 do
       fMainForm.OpenFile(fFiles[i]);
  end
  else
    fMainForm.NewFile(TDocumentFrame.FindEditorForFileType(TDocumentFrame.FindDefaultFileType));
end;

constructor TOpenAfterLoad.Create(AOwner: TComponent);
begin
  inherited Create(AOwner);
  fLoaded := false;
  if AOwner is TMainForm then
  begin
     fMainForm := AOwner as TMainForm
  end
  else
  begin
     fMainForm := MainForm;
  end;
  Application.AddOnIdleHandler(@ApplicationLoaded);
end;

procedure TOpenAfterLoad.AddFile(aFilename: String);
begin
  SetLength(fFiles,Length(fFiles) + 1);
  fFiles[Length(fFiles) - 1] := aFilename;

end;

{ TNewDocumentAction }

procedure TNewDocumentAction.SetFileType(AValue: String);
begin
  if fFileType=AValue then Exit;
  fFileType:=AValue;
end;

{ TAppAction }

procedure TAppAction.SetAssignedToMenu(AValue: Boolean);
begin
  if FAssignedToMenu=AValue then Exit;
  FAssignedToMenu:=AValue;
end;

procedure TAppAction.SetOnUpdateAction(AValue: TUpdateActionEvent);
begin
  if FOnUpdateAction=AValue then Exit;
  FOnUpdateAction:=AValue;
end;

function TAppAction.Update: Boolean;
var
  lEnabled: Boolean;
  lChecked: Boolean;
  lVisible: Boolean;
begin
  if FOnUpdateAction <> nil then
  begin
    lEnabled := Enabled;
    lChecked := Checked;
    lVisible := Visible;
    FOnUpdateAction(Self,lEnabled,lChecked,lVisible);
    Enabled := lEnabled;
    Checked := lChecked;
    Visible := lVisible;
  end
  else
    Result:=inherited Update;
end;

{ TMainForm }

procedure TMainForm.FormCreate(Sender: TObject);
var
  i: Integer;
begin
  fFullscreen:=false;
  fRevealTags := false;


  InitializeIPCClient;
  if fIPCClient.ServerRunning then
  begin
    //A instance is already running
    //Send a message and then exit
    fIPCClient.Active := True;
    // bring the required one to the front (the open will be done in OpenFile).
    fIPCClient.SendStringMessage(IPCBringToFrontMessage,'');
    Application.ShowMainForm := False;
    Application.Terminate;
  end
  else
  begin
    InitializeIPCServer;
    // no longer need the client, so free it... This
    // also serves to make sure that the OpenFile doesn't
    // get sent to the server.
    FreeAndNil(fIPCClient);
  end;

  if not Application.Terminated then
  begin
    // we need to set up the user interface...
    fOpenAfterLoad := TOpenAfterLoad.Create(Self);
    SetCaption;
    SetupDialogs;
    RegisterActions;
    AssignKeyboardShortcuts;
    BuildMenu;
  end;

  i := 1;
  while (i <= ParamCount) do
  begin
    case ParamStrUTF8(i) of
       '--lazarus':
       begin
          // This is code to be called if this is running from lazarus
          OpenFile(ExpandFileNameUTF8('../test/test.ftm'));
       end;
    else
       OpenFile(ExpandFileNameUTF8(ParamStr(i)));
    end;
    inc(i);
  end;


end;

procedure TMainForm.FormKeyDown(Sender: TObject; var Key: Word;
  Shift: TShiftState);
begin
  // VK_MENU is the alt key
  if (Key = VK_MENU) and fFullscreen then
     ShowMenu;
end;

procedure TMainForm.FormKeyUp(Sender: TObject; var Key: Word; Shift: TShiftState
  );
begin
  // VK_MENU is the alt key
  if (Key = VK_MENU) and fFullscreen then
     HideMenu;

end;

procedure TMainForm.FormShow(Sender: TObject);
begin
  // has to be done here in order to make sure it sets the unmaximized
  // heights appropriately. In FormCreate, the heights will be overwritten
  // after setting the WindowState, and next session the normal state will
  // look almost maximized.
  fScreenConfiguration := TScreenConfiguration.Create(Self);
  fFullscreen := WindowState = wsFullScreen;
  FullScreenChanged;
end;


procedure TMainForm.FormWindowStateChange(Sender: TObject);
begin
  {
  There appears to be an issue with WindowState. After setting WindowState
  to wsFullscreen the first time, there's some message or other which causes
  the Form to think it's state is wsNormal again, even if it's still displayed
  full screen.

  Which means, if I use the actual WindowState as a flag to determine whether
  I should toggle fullscreen, then what happens is this:
  1. User toggles fullscreen (expecting it to turn on)
  2. WindowState is not wsFullscreen, so WindowState set to wsFullscreen
  3. Some Message (Resize?) response sets fWindowState back to wsNormal
     (However, form still appears fullscreen)
  4. Form now appears fullscreen, despite thinking it's not
  5. User attempts to toggle fullscreen (expecting to turn it off)
  6. WindowState is not wsFullscreen, so WindowState set to wsFullscreen
  7. Window remains fullscreen, although on a good note the weird message did
     not change it back to normal.
  8. User, frustrated, attempts to toggle fullscreen again (expecting it to turn off)
  9. WindowState is wsFullscreen, so WindowState set to wsNormal.
  10. Window appears non-fullscreen.
  (Basically, the user has to "toggle" it twice to get it back out of fullscreen)

  Okay, so, I can't depend on WindowState to get an actual idea of what my state is,
  so, I set up a fFullscreen flag to track it instead, so now:
  1. User toggles fullscreen (expecting it to turn on)
  2. fFullscreen is false, so WindowState set to wsFullscreen and fFullscreen set to true.
  3. Some Message (Resize?) response sets fWindowState back to wsNormal
     (However, form still appears fullscreen)
  4. Form now appears fullscreen, despite thinking it's not
  5. User attempts to toggle fullscreen (expecting to turn it off)
  6. fFullscreen is true, so WindowState set to wsNormal and fFullscreen set to false.
  7. The form thinks that WindowState is already wsNormal, so it does nothing.
  8. User, frustrated, attempts to toggle fullscreen again (expecting it to turn off)
  9. fFullscreen is false, so WindowState set to wsFullscreen and fFullscreen set to true.
  10. Now, Window thinks it's fullscreen and it *is* fullscreen.
  11. Window remains fullscreen, although on a good note the weird message did
     not change it back to normal.
  12. User, frustrated twice, attempts to toggle fullscreen again (expecting it to turn off one of these times)
  13. WindowState is wsFullscreen, so WindowState set to wsNormal.
  15. Window appears non-fullscreen.
  (Basically, the user has to "toggle" it *thrice* to get it back out of fullscreen)

  And so, we add this code. Whenever the Form changes it's WindowState, we check
  our flag to see if we've toggled it either way, and if the flag is *true* then
  we force it back to fullscreen. Thus:
  1. User toggles fullscreen (expecting it to turn on)
  2. fFullscreen is false, so WindowState set to wsFullscreen and fFullscreen set to true.
  3. Some Message (Resize?) response sets fWindowState back to wsNormal
     (However, form still appears fullscreen)
  4. This triggers this event (NOTE: event is not triggered when we set it ourselves)
  5. Our flag says we are *supposed* to be fullscreen, so set WindowState to wsFullscreen again.
  6. Now, the window is fullscreen, and thinks it's fullscreen.
  7. User attempts to toggle fullscreen (expecting to turn it off)
  8. fFullscreen is true, so WindowState set to wsNormal and fFullscreen set to false.
  9. The form switches to normal, and thinks it's normal, and everything works right.
  YAY!!!! Fullscreen.

  }
  if fFullscreen then
    WindowState := wsFullScreen;
end;

procedure TMainForm.FullscreenAction(Sender: TObject);
begin
  ToggleFullscreen;
end;

procedure TMainForm.HeaderAction(Sender: TObject);
begin
//  GetCurrentFrame.SetParagraphStyle(psHeader1);
end;

procedure TMainForm.IncreaseIndentAction(Sender: TObject);
begin
//  GetCurrentFrame.IncreaseListIndent;
end;

procedure TMainForm.FormCloseQuery(Sender: TObject; var CanClose: boolean);
var
  i: Integer;
begin
  // first, look for an existing tab...
  for i := 0 to DocumentTabs.PageCount - 1 do
  begin
    CanClose := CanCloseTab(DocumentTabs.Pages[i]);
    if not CanClose then
       Exit;
  end;
end;

procedure TMainForm.BlockQuoteAction(Sender: TObject);
begin
//  GetCurrentFrame.SetParagraphStyle(psBlockQuote);
end;

procedure TMainForm.CheckGrammarAction(Sender: TObject);
begin
  NotImplemented('Check Grammar');
  // This requires internet access, but I might be able
  // to specify a command line executable to do this.
  // http://www.afterthedeadline.com/api.slp
end;

procedure TMainForm.CloseFindReplacePanelButtonClick(Sender: TObject);
begin
  FindReplacePanel.Visible := false;
end;

procedure TMainForm.DocumentCaptionChanged(Sender: TObject);
begin
  GetTab(Sender as TDocumentFrame).Caption := (Sender as TDocumentFrame).Caption;
  SetCaption;
end;

procedure TMainForm.DocumentFrameLoaded(Sender: TObject);
begin
  if fFullscreen then
     (Sender as TDocumentFrame).MakeFullscreen;
  if fRevealTags then
     (Sender as TDocumentFrame).MakeRevealTags;
end;

procedure TMainForm.DocumentTabsChange(Sender: TObject);
begin
  SetCaption;
end;

procedure TMainForm.DocumentTabsCloseTabClicked(Sender: TObject);
var
  lTab: TTabSheet;
begin
  lTab := Sender as TTabSheet;
  CloseTab(lTab);
end;

procedure TMainForm.FindEditKeyUp(Sender: TObject; var Key: Word;
  Shift: TShiftState);
begin
  if (Key = VK_RETURN) and (FindEdit.Text <> '') then
  begin
    // if default isn't set, as it won't be the first time, then we
    // need to call click ourselves.
    if (not FindPreviousButton.Default) and (not FindNextButton.Default) then
       FindNextButton.Click;
  end
  else if (key = VK_ESCAPE) then
  begin
    CloseFindReplacePanelButton.Click;
  end;
end;

procedure TMainForm.FormClose(Sender: TObject; var CloseAction: TCloseAction);
begin
  fScreenConfiguration.Save;
end;

procedure TMainForm.CutAction(Sender: TObject);
begin
  if FindEdit.Focused then
     FindEdit.CutToClipboard
  else if ReplaceEdit.Focused then
     ReplaceEdit.CutToClipboard
  else
     GetCurrentFrame.Cut;

end;

procedure TMainForm.DecreaseIndentAction(Sender: TObject);
begin
//  GetCurrentFrame.DecreaseListIndent;
end;

procedure TMainForm.FindAction(Sender: TObject);
begin
  FindReplacePanel.Visible := true;
  ReplaceCheckbox.Checked := false;
  FindEdit.SetFocus;
end;

procedure TMainForm.FindNextAction(Sender: TObject);
begin
  FindReplacePanel.Visible := true;
  FindNextButton.Default := true;
  if not GetCurrentFrame.FindReplace(FindEdit.Text,true,false,ReplaceCheckbox.Checked,ReplaceEdit.Text) then
  begin
    if MessageDlg('Search string not found. Continue from the beginning?',TMsgDlgType.mtConfirmation,mbYesNo,0) = mrYes then
    begin
      if not GetCurrentFrame.FindReplace(FindEdit.Text,true,true,ReplaceCheckbox.Checked,ReplaceEdit.Text) then
         ShowMessage('Search string not found.');
    end;
  end;
end;

procedure TMainForm.FindPreviousAction(Sender: TObject);
begin
  FindReplacePanel.Visible := true;
  FindPreviousButton.Default := true;
  if not GetCurrentFrame.FindReplace(FindEdit.Text,false,false,ReplaceCheckbox.Checked,ReplaceEdit.Text) then
  begin
    if MessageDlg('Search string not found. Continue from the end?',TMsgDlgType.mtConfirmation,mbYesNo,0) = mrYes then
    begin
      if not GetCurrentFrame.FindReplace(FindEdit.Text,false,true,ReplaceCheckbox.Checked,ReplaceEdit.Text) then
         ShowMessage('Search string not found.');
    end;
  end;
end;

procedure TMainForm.CopyAction(Sender: TObject);
begin
  if FindEdit.Focused then
     FindEdit.CopyToClipboard
  else if ReplaceEdit.Focused then
     ReplaceEdit.CopyToClipboard
  else
     GetCurrentFrame.Copy;
end;

procedure TMainForm.BoldAction(Sender: TObject);
begin
//  GetCurrentFrame.ToggleTextStyle(tsBold);
end;

procedure TMainForm.BullettedListAction(Sender: TObject);
begin
//  GetCurrentFrame.SetParagraphStyle(psBullettedList);
end;

procedure TMainForm.CheckSpellingAction(Sender: TObject);
begin
  NotImplemented('Check Spelling');
end;

procedure TMainForm.BodyTextAction(Sender: TObject);
begin
//  GetCurrentFrame.SetParagraphStyle(psNormal);
end;

procedure TMainForm.ClearFormattingAction(Sender: TObject);
begin
//  GetCurrentFrame.ClearTextStyles;
end;

procedure TMainForm.CloseCurrentTabAction(Sender: TObject);
begin
  CloseTab(DocumentTabs.ActivePage);
end;

procedure TMainForm.ExecuteAboutAction(Sender: TObject);
begin
  ShowMessage('You are using SimplePad, by Neil M. Sheldon.' + LineEnding +
              LineEnding +
              'This is a basic formatted text editor which supports editing HTML and Markdown.' + LineEnding +
              LineEnding +
              'Simplepad was created using the following technology: ' + LineEnding +
              #9 + 'FreePascal' + LineEnding +
              #9 + 'Lazarus' + LineEnding +
              #9 + 'LazWebkit' + LineEnding +
              #9 + 'WebKit' + LineEnding +
              #9 + 'medium-editor' + LineEnding +
              #9 + 'font-awesome' + LineEnding +
              #9 + 'marked' + LineEnding +
              #9 + 'to-markdown' + LineEnding +
              #9 + 'js-beautify');
end;

procedure TMainForm.IPCServer_CheckMessage(Sender: TObject);
begin
  FIPCServer.PeekMessage(1, True);
end;

procedure TMainForm.IPCServer_ReceiveMessage(Sender: TObject);
begin
  //MsgType stores ParamCount
  case fIPCServer.MsgType of
     IPCOpenFileMessage:
       OpenFile(fIPCServer.StringMessage);
     IPCBringToFrontMessage:
       BringToFront;
  else
    ShowMessage('Invalid IPC Message Received: ' + IntToStr(fIPCServer.MsgType));
  end;
end;

procedure TMainForm.NextTabAction(Sender: TObject);
begin
  if DocumentTabs.PageIndex < (DocumentTabs.PageCount - 1) then
     DocumentTabs.PageIndex := DocumentTabs.PageIndex + 1
  else
     DocumentTabs.PageIndex := 0;
end;

procedure TMainForm.OpenProjectAction(Sender: TObject);
begin
  if fProjectDirectory <> '' then
  begin
    ProjectOpenDialog.InitialDir := fProjectDirectory;
  end;
  if HasFrame then
  begin
    ProjectOpenDialog.InitialDir := ExtractFileDir(GetCurrentFrame.FileName);
  end
  else
  begin
    ProjectOpenDialog.InitialDir := GetCurrentDir;
  end;
  ProjectOpenDialog.Options := ProjectOpenDialog.Options + [ofFileMustExist];
  if ProjectOpenDialog.Execute then
  begin
    OpenProject(ProjectOpenDialog.FileName);
  end;
end;

procedure TMainForm.PreviousTabAction(Sender: TObject);
begin
  if DocumentTabs.PageIndex > 0 then
     DocumentTabs.PageIndex := DocumentTabs.PageIndex - 1
  else
     DocumentTabs.PageIndex := DocumentTabs.PageCount - 1;
end;

procedure TMainForm.ProjectTreeViewDblClick(Sender: TObject);
var
  lSelectedNode: TTreeNode;
  lPath: UTF8String;
begin
  lSelectedNode := ProjectTreeView.Selected;
  if lSelectedNode <> nil then
  begin
    lPath := lSelectedNode.Text;
    lSelectedNode := lSelectedNode.Parent;
    while lSelectedNode <> nil do
    begin
      lPath := IncludeTrailingPathDelimiter(lSelectedNode.Text) + lPath;
      lSelectedNode := lSelectedNode.Parent;
    end;
    lPath := IncludeTrailingPathDelimiter(fProjectDirectory) + lPath;
    if (not DirectoryExists(lPath)) and FileExists(lPath) then
       OpenFile(lPath);
  end;

end;

procedure TMainForm.NewFileAction(Sender: TObject);
begin
  if Sender is TNewDocumentAction then
  begin
    NewFile(TDocumentFrame.FindEditorForFiletype((Sender as TNewDocumentAction).FileType));
  end
  else
  begin
    NewFile(TDocumentFrame.FindEditorForFileType(TDocumentFrame.FindDefaultFileType));
  end;
end;

procedure TMainForm.ItalicAction(Sender: TObject);
begin
//  GetCurrentFrame.ToggleTextStyle(tsItalic);
end;

procedure TMainForm.NumberedListAction(Sender: TObject);
begin
//  GetCurrentFrame.SetParagraphStyle(psNumberedList);
end;

procedure TMainForm.PasteAction(Sender: TObject);
begin
  if FindEdit.Focused then
     FindEdit.PasteFromClipboard
  else if ReplaceEdit.Focused then
     ReplaceEdit.PasteFromClipboard
  else
     GetCurrentFrame.Paste;
end;

procedure TMainForm.RedoAction(Sender: TObject);
begin
  GetCurrentFrame.Redo;
end;

procedure TMainForm.PrintAction(Sender: TObject);
begin
  GetCurrentFrame.Print;
end;

procedure TMainForm.OpenFileAction(Sender: TObject);
begin
  if HasFrame then
  begin
    DocumentOpenDialog.InitialDir := ExtractFileDir(GetCurrentFrame.FileName);
  end;
  if DocumentOpenDialog.Execute then
  begin
    OpenFile(DocumentOpenDialog.FileName);
  end;
end;

procedure TMainForm.QuitApplicationAction(Sender: TObject);
begin
  Close;
end;

procedure TMainForm.RegisterAction(const aName: UTF8String;
  const aMenuCaption: UTF8String; const aFullCaption: UTF8String;
  aExecute: TNotifyEvent; aUpdate: TUpdateActionEvent);
var
  lAction: TAppAction;
begin
  lAction := TAppAction.Create(MainFormActions);
  lAction.ActionList := MainFormActions;
  lAction.Name := aName;
  lAction.Caption := aMenuCaption;
  lAction.Hint := aFullCaption;
  lAction.OnExecute := aExecute;
  lAction.OnUpdateAction := aUpdate;
  // FUTURE: Assign a glyph based on a registered list of glyphs for
  // a given name.

end;

procedure TMainForm.RegisterNewFileAction(const aFileType: String);
var
  lAction: TNewDocumentAction;
begin
  lAction := TNewDocumentAction.Create(MainFormActions);
  lAction.ActionList := MainFormActions;
  lAction.FileType := aFileType;
  lAction.Name := 'New' + StringReplace(aFileType,' ','_',[rfReplaceAll]) + 'Action';
  lAction.Caption := 'New ' + aFileType;
  lAction.Hint := 'Create New ' + lAction.Caption;
  lAction.OnExecute:=@NewFileAction;
end;

procedure TMainForm.ReplaceCheckboxClick(Sender: TObject);
begin
  ReplaceEdit.Enabled := ReplaceCheckbox.Checked;
  if ReplaceEdit.Enabled then
     ReplaceEdit.Width := 100
  else
     ReplaceEdit.Width := 1;
end;

procedure TMainForm.ReplaceEditKeyUp(Sender: TObject; var Key: Word;
  Shift: TShiftState);
begin
  if (key = VK_ESCAPE) then
  begin
    CloseFindReplacePanelButton.Click;
  end;
end;

procedure TMainForm.RevealTagsAction(Sender: TObject);
begin
  ToggleRevealTags;
end;

procedure TMainForm.ToggleProjectExplorerAction(Sender: TObject);
begin
  ToggleProjectExplorer;
end;

procedure TMainForm.TestOfTheDayAction(Sender: TObject);
begin
  GetCurrentFrame.TestOfTheDay;
end;

procedure TMainForm.UpdateCheckGrammarAction(Sender: TAction;
  var aEnabled: Boolean; var aChecked: Boolean; var aVisible: Boolean);
begin
  aEnabled := false;
end;

procedure TMainForm.ReplaceAction(Sender: TObject);
begin
  FindReplacePanel.Visible := true;
  ReplaceCheckbox.Checked := true;
  FindEdit.SetFocus;
end;

procedure TMainForm.SelectAllAction(Sender: TObject);
begin
  if HasFrame then
  GetCurrentFrame.SelectAll;
end;

procedure TMainForm.UndoAction(Sender: TObject);
begin
  if HasFrame then
  GetCurrentFrame.Undo;
end;

procedure TMainForm.UpdateCheckSpellingAction(Sender: TAction;
  var aEnabled: Boolean; var aChecked: Boolean; var aVisible: Boolean);
begin
  aEnabled := false;
end;

procedure TMainForm.UpdateCopyAction(Sender: TAction; var aEnabled: Boolean;
  var aChecked: Boolean; var aVisible: Boolean);
begin
  aEnabled := (HasFrame and GetCurrentFrame.CanCopy) or (FindEdit.Focused or ReplaceEdit.Focused);
end;

procedure TMainForm.UpdateFindNextAction(Sender: TAction;
  var aEnabled: Boolean; var aChecked: Boolean; var aVisible: Boolean);
begin
  aEnabled := FindEdit.Text <> '';
end;

procedure TMainForm.UpdateFindPreviousAction(Sender: TAction;
  var aEnabled: Boolean; var aChecked: Boolean; var aVisible: Boolean);
begin
  aEnabled := FindEdit.Text <> '';
end;

procedure TMainForm.UpdateFormatAction(Sender: TAction; var aEnabled: Boolean;
  var aChecked: Boolean; var aVisible: Boolean);
begin
//  aEnabled := GetCurrentFrame.CanFormat;
  // TODO: Also need to set the 'checked' value for a bunch of these.
end;

procedure TMainForm.UpdatePasteAction(Sender: TAction; var aEnabled: Boolean;
  var aChecked: Boolean; var aVisible: Boolean);
begin
  aEnabled := (HasFrame and GetCurrentFrame.CanPaste) or (FindEdit.Focused or ReplaceEdit.Focused);
end;

procedure TMainForm.UpdateListAction(Sender: TAction; var aEnabled: Boolean;
  var aChecked: Boolean; var aVisible: Boolean);
begin
//  aEnabled := GetCurrentFrame.CanFormat and (GetCurrentFrame.GetParagraphStyle in [psNumberedList, psBullettedList]);
end;

procedure TMainForm.UpdateRedoAction(Sender: TAction; var aEnabled: Boolean;
  var aChecked: Boolean; var aVisible: Boolean);
begin
  aEnabled := HasFrame and GetCurrentFrame.CanRedo;
end;

procedure TMainForm.SaveFileAction(Sender: TObject);
begin
  // first, look for an existing tab...
  if HasFrame then
  SaveFrame(GetCurrentFrame);
end;

procedure TMainForm.SaveFileAsAction(Sender: TObject);
begin
  // first, look for an existing tab...
  if HasFrame then
  SaveFrameAs(GetCurrentFrame);
end;

procedure TMainForm.UpdateSaveFileAction(Sender: TAction;
  var aEnabled: Boolean; var aChecked: Boolean; var aVisible: Boolean);
begin
  aEnabled := HasFrame and GetCurrentFrame.IsModified;
end;

procedure TMainForm.UpdateCutAction(Sender: TAction; var aEnabled: Boolean;
  var aChecked: Boolean; var aVisible: Boolean);
begin
  aEnabled := (HasFrame and GetCurrentFrame.CanCut) or (FindEdit.Focused or ReplaceEdit.Focused);

end;

procedure TMainForm.UpdateUndoAction(Sender: TAction; var aEnabled: Boolean;
  var aChecked: Boolean; var aVisible: Boolean);
begin
  aEnabled := HasFrame and GetCurrentFrame.CanUndo;
end;

procedure TMainForm.SaveAllFilesAction(Sender: TObject);
var
  i: Integer;
  lTab: TTabSheet;
  lFrame: TDocumentFrame;
begin
  // first, look for an existing tab...
  for i := 0 to DocumentTabs.PageCount - 1 do
  begin
    lTab := DocumentTabs.Pages[i];
    lFrame := GetFrame(lTab);
    if not SaveFrame(lFrame) then
         Exit;
  end;
end;

procedure TMainForm.InitializeIPCServer;
{$IFDEF UNIX}
var
  lTimer: TTimer;
{$ENDIF}
begin
  FIPCServer := TSimpleIPCServer.Create(Self);
  FIPCServer.ServerID := IPCIdentifier;
  FIPCServer.Global := True;
  FIPCServer.StartServer;
  FIPCServer.OnMessage:=@IPCServer_ReceiveMessage;
  // Linux apparently needs a timer to peek at the messages, it doesn't
  // do it automatically.
  {$IFDEF UNIX}
  lTimer := TTimer.Create(Self);
  lTimer.Interval := 1000;
  lTimer.OnTimer:=@IPCServer_CheckMessage;
  {$ENDIF}
end;

procedure TMainForm.InitializeIPCClient;
begin
  fIPCClient := TSimpleIPCClient.Create(Self);
  fIPCClient.ServerId := IPCIdentifier;
end;

procedure TMainForm.SetupDialogs;
begin
  DocumentOpenDialog.Filter := TDocumentFrame.EditorDialogFilters('');
end;

procedure TMainForm.OpenFile(aFileName: UTF8String);
var
  lFrameClass: TDocumentFrameClass;
  lEditorID: String;
begin
  if fIPCClient <> nil then
  begin
    fIPCClient.SendStringMessage(IPCOpenFileMessage,aFileName);
  end
  else
  begin
    if fOpenAfterLoad.Loaded then
    begin
       lEditorID := TDocumentFrame.FindFormatIDForFile(aFileName);
       lFrameClass := TDocumentFrame.FindEditorForFormatID(lEditorID);
       OpenFile(aFileName,lFrameClass,lEditorID)
    end
    else
       fOpenAfterLoad.AddFile(aFileName);
  end;

end;

procedure TMainForm.OpenFile(aFileName: UTF8String;
  aEditorType: TDocumentFrameClass; aEditorFormatID: String);
var
  i: Integer;
  lTab: TTabSheet;
  lFrame: TDocumentFrame;
begin
  // first, look for an existing tab...
  for i := 0 to DocumentTabs.PageCount - 1 do
  begin
    lTab := DocumentTabs.Pages[i];
    lFrame := GetFrame(lTab);
    if CompareFilenames(aFileName,lFrame.FileName,true) = 0 then
    begin
       DocumentTabs.PageIndex := lTab.PageIndex;
       Exit;
    end;
  end;

  // now, check if the current tab is a blank, unedited file of the correct type,
  // if it is, then we need to replace it. This will happen when we start up the
  // editor and have a blank screen that we want to open the file into.
  if HasFrame then
  begin
    lFrame := GetCurrentFrame;
    if (lFrame is aEditorType) and
       (lFrame.FileName = '') and
       (not lFrame.IsModified) then
    begin
      lFrame.Load(aFileName,aEditorFormatID);
      Exit;
    end;
  end;

  CreateFrame(aEditorType).Load(aFileName,aEditorFormatID);

end;

procedure TMainForm.OpenProject(aDirectoryName: UTF8String);
begin
  fProjectDirectory := aDirectoryName;
  ShowProjectExplorer;

end;

procedure TMainForm.RefreshProjectView;
var
  lCounter: Longint;
begin
  if (LeftSidebar.Width > 1) then
  begin

    ProjectTreeView.Items.Clear;
    if fProjectDirectory <> '' then;
    begin
      lCounter := 0;
      try
        LoadProjectFiles(fProjectDirectory,nil,lCounter);

      except
        on E: EMaxProjectSizeReached do
           ProjectTreeView.Items.AddChild(nil,'//...Project is too big to load...//');
      end;
    end;

  end;
end;

procedure TMainForm.NewFile(aEditorType: TDocumentFrameClass);
begin
  CreateFrame(aEditorType).New;
end;

procedure TMainForm.RegisterActions;
var
  i: Integer;
begin
  // I don't want to have to go through the gui interface to create
  // these actions in the action list editor, so I'm doing this by code...
  for i := 0 to TDocumentFrame.FileTypeCount - 1 do
  begin
    RegisterNewFileAction(TDocumentFrame.FileTypeIDS[i]);
  end;
  RegisterAction('NewFileAction','&New','New file',@NewFileAction);
  RegisterAction('OpenFileAction','&Open','Open a file',@OpenFileAction);
  RegisterAction('SaveFileAction','&Save','Save the file',@SaveFileAction,@UpdateSaveFileAction);
  RegisterAction('SaveFileAsAction','Save &As...','Save the file under a new name',@SaveFileAsAction);
  RegisterAction('SaveAllAction','Save All','Save all open files',@SaveAllFilesAction);
  RegisterAction('OpenProjectAction','Open Project','Open a Simplepad Project',@OpenProjectAction);
  RegisterAction('PrintAction','&Print','Print the file',@PrintAction);
  RegisterAction('CloseTabAction','&Close','Close active file',@CloseCurrentTabAction);
  RegisterAction('QuitAction','&Quit','Quit application',@QuitApplicationAction);
  RegisterAction('UndoAction','&Undo','Undo last edit',@UndoAction,@UpdateUndoAction);
  RegisterAction('RedoAction','&Redo','Redo last undone edit',@RedoAction,@UpdateRedoAction);
  RegisterAction('CutAction','Cu&t','Remove selected text and put it in the clipboard',@CutAction,@UpdateCutAction);
  RegisterAction('CopyAction','&Copy','Copy the selected text and put it in the clipboard',@CopyAction,@UpdateCopyAction);
  RegisterAction('PasteAction','&Paste','Paste contents from the clipboard into the editor',@PasteAction,@UpdatePasteAction);
  RegisterAction('SelectAllAction','Select &All','Select all text in document',@SelectAllAction);
  RegisterAction('FindAction','&Find...','Find text',@FindAction);
  RegisterAction('FindNextAction','Find &Next','Find next instance of the search text',@FindNextAction,@UpdateFindNextAction);
  RegisterAction('FindPreviousAction','Find &Previous','Find previous instance of the search text',@FindPreviousAction,@UpdateFindPreviousAction);
  RegisterAction('ReplaceAction','&Replace...','Find text and replace it with something else.',@ReplaceAction);
  //RegisterAction('BoldAction','Bold','Toggle selection to a bold font',@BoldAction,@UpdateFormatAction);
  //RegisterAction('ItalicAction','Italic','Toggle selection to an italic font',@ItalicAction,@UpdateFormatAction);
  //RegisterAction('ClearFormattingAction','Clear Formatting','Clear formatting from selected text.',@ClearFormattingAction,@UpdateFormatAction);
  //RegisterAction('HeaderAction','Header','Set current paragraph to a header style',@HeaderAction,@UpdateFormatAction);
  //RegisterAction('BodyTextAction','Body Text','Set current paragraph to a normal style',@BodyTextAction,@UpdateFormatAction);
  //RegisterAction('BlockQuoteAction','Block Quote','Set current paragraph to a blockquote style',@BlockQuoteAction,@UpdateFormatAction);
  //RegisterAction('NumberedListAction','Numbered List','Set current paragraph to be an item in a numbered list',@NumberedListAction,@UpdateFormatAction);
  //RegisterAction('BullettedListAction','Bulletted List','Set current paragraph to be an item in a bulletted list',@BullettedListAction,@UpdateFormatAction);
  //RegisterAction('IncreaseIndentAction','Increase Indent','Increase left indent of current paragraph',@IncreaseIndentAction,@UpdateListAction);
  //RegisterAction('DecreaseIndentAction','Decrease Indent','Decrease left indent of current paragraph',@DecreaseIndentAction,@UpdateListAction);
  RegisterAction('FullscreenAction','&Fullscreen','Toggle fullscreen display',@FullscreenAction);
  RegisterAction('RevealTagsAction','&Reveal Tags','Toggle display of tag hints for better understanding of formats.',@RevealTagsAction);
  RegisterAction('ProjectExplorerAction','Project Explorer','Show a file directory explorer.',@ToggleProjectExplorerAction);
  RegisterAction('CheckSpellingAction','&Spelling','Check spelling of document',@CheckSpellingAction,@UpdateCheckSpellingAction);
  RegisterAction('CheckGrammarAction','&Grammar','Run grammar check on document text',@CheckGrammarAction,@UpdateCheckGrammarAction);
  RegisterAction('AboutAction','&About','Show information about this application',@ExecuteAboutAction);
  RegisterAction('TestOfTheDayAction','Test Of The Day','Run a document function which was set up for testing at the last compile',@TestOfTheDayAction);

  // Some actions which need keyboard shortcuts but not menus
  RegisterAction('NextTabAction','Next','Switch to next tab',@NextTabAction);
  RegisterAction('PreviousTabAction','Previous','Switch to previous tab',@PreviousTabAction);

  // Hook the findreplacepanel up to actions...
  FindNextButton.Action := MainFormActions.ActionByName('FindNextAction');
  FindNextButton.Caption := 'Next...';
  FindPreviousButton.Action := MainFormActions.ActionByName('FindPreviousAction');
  FindPreviousButton.Caption := 'Previous...';
end;

procedure TMainForm.BuildMenu;
var
  lMenu: TMenuItem;

  procedure NewMainMenu(aCaption: UTF8String);
  begin
    lMenu := TMenuItem.Create(MainFormMenu);
    lMenu.Caption := aCaption;
    MainFormMenu.Items.Add(lMenu);
  end;

  procedure NewSubMenu(aCaption: UTF8String);
  var
    lSub: TMenuItem;
  begin
    lSub := TMenuItem.Create(lMenu);
    lSub.Caption := aCaption;
    lMenu.Add(lSub);
    lMenu := lSub;

  end;

  procedure EndSubMenu;
  begin
    lMenu := lMenu.Parent;
  end;

  procedure AddItem(aAction: TContainedAction);
  var
    lItem: TMenuItem;
  begin
    lItem := TMenuItem.Create(lMenu);
    lMenu.Add(lItem);
    lItem.Action := aAction;
    if aAction is TAppAction then
       (aAction as TAppAction).AssignedToMenu:=true;

  end;

  procedure AddItem(aAction: UTF8String);
  var
    lAction: TAppAction;
  begin
    lAction := MainFormActions.ActionByName(aAction) as TAppAction;
    if lAction <> nil then
    begin
       AddItem(lAction);
    end;
  end;

var
  i: Integer;
//  lFoundUnassignedAction: Boolean;

begin
  NewMainMenu('&File');
  if TDocumentFrame.FileTypeCount > 1 then
  begin
    NewSubMenu('New');
    for i := 0 to TDocumentFrame.FileTypeCount - 1 do
    begin
      AddItem('New' + StringReplace(TDocumentFrame.FileTypeIDS[i],' ','_',[rfReplaceAll]) + 'Action');
    end;
    EndSubMenu;
  end
  else if TDocumentFrame.FileTypeCount > 0 then;
    AddItem('NewFileAction');
  AddItem('OpenFileAction');
  lMenu.AddSeparator;
  AddItem('SaveFileAction');
  AddItem('SaveFileAsAction');
  AddItem('SaveAllAction');
  lMenu.AddSeparator;
  AddItem('OpenProjectAction');
  lMenu.AddSeparator;
  AddItem('PrintAction');
  lMenu.AddSeparator;
  AddItem('CloseTabAction');
  AddItem('QuitAction');
  NewMainMenu('&Edit');
  AddItem('UndoAction');
  AddItem('RedoAction');
  lMenu.AddSeparator;
  AddItem('CutAction');
  AddItem('CopyAction');
  AddItem('PasteAction');
  lMenu.AddSeparator;
  AddItem('SelectAllAction');
  NewMainMenu('&Search');
  AddItem('FindAction');
  AddItem('FindNextAction');
  AddItem('FindPreviousAction');
  AddItem('ReplaceAction');
  //NewMainMenu('Format');
  //AddItem('BoldAction');
  //AddItem('ItalicAction');
  //AddItem('ClearFormattingAction');
  //lMenu.AddSeparator;
  //AddItem('HeaderAction');
  //AddItem('BodyTextAction');
  //AddItem('BlockQuoteAction');
  //lMenu.AddSeparator;
  //AddItem('NumberedListAction');
  //AddItem('BullettedListAction');
  //AddItem('IncreaseIndentAction');
  //AddItem('DecreaseIndentAction');
  NewMainMenu('&Tools');
  AddItem('FullscreenAction');
  AddItem('RevealTagsAction');
  AddItem('ProjectExplorerAction');
  lMenu.AddSeparator;
  AddItem('CheckSpellingAction');
  AddItem('CheckGrammarAction');
  //lMenu.AddSeparator;
  //AddItem('TestOfTheDayAction');
  NewMainMenu('&Help');
  AddItem('AboutAction');


  {
  // I don't want to accidentally *lose* new items during development,
  // so add them to other.
  lFoundUnassignedAction := false;
  for i := 0 to MainFormActions.ActionCount - 1 do
  begin
    if not (MainFormActions.Actions[i] as TAppAction).AssignedToMenu then
    begin
       if not lFoundUnassignedAction then
       begin
          lFoundUnassignedAction := true;
          NewMainMenu('Other');
       end;
       AddItem(MainFormActions.Actions[i] as TAppAction);

    end;
  end;}

end;

procedure TMainForm.AssignKeyboardShortcuts;
  procedure AssignShortCut(aAction: UTF8String; Key: Word; Shift: TShiftState = []);
  var
    lAction: TAppAction;
  begin
    lAction := MainFormActions.ActionByName(aAction) as TAppAction;
    if lAction <> nil then
    begin
       if lAction.ShortCut = 0 then
       begin
          lAction.ShortCut := ShortCut(Key,Shift);
       end
       else
       begin
         lAction.SecondaryShortCuts.Add(ShortCutToText(ShortCut(Key,Shift)));
       end;

    end;

  end;

begin
  AssignShortCut('OpenFileAction',VK_O,[ssCtrl]);
  AssignShortCut('NewFileAction',VK_N,[ssCtrl]);
  AssignShortCut('SaveFileAction',VK_S,[ssCtrl]);
  AssignShortCut('SaveAllAction',VK_S,[ssCtrl,ssShift]);
  AssignShortcut('PrintAction',VK_P,[ssCtrl]);
  AssignShortcut('CloseTabAction',VK_F4,[ssCtrl]);
  AssignShortcut('UndoAction',VK_Z,[ssCtrl]);
  AssignShortcut('RedoAction',VK_Z,[ssCtrl,ssShift]);
  AssignShortcut('CutAction',VK_X,[ssCtrl]);
  AssignShortcut('CopyAction',VK_C,[ssCtrl]);
  AssignShortcut('PasteAction',VK_V,[ssCtrl]);
  AssignShortcut('SelectAllAction',VK_A,[ssCtrl]);
  AssignShortcut('FindAction',VK_F,[ssCtrl]);
  AssignShortcut('FindNextAction',VK_F3);
  AssignShortcut('FindPreviousAction',VK_F3,[ssShift]);
  AssignShortcut('ReplaceAction',VK_R,[ssCtrl]);
  AssignShortcut('ReplaceAction',VK_H,[ssCtrl]);
  //AssignShortcut('BoldAction',VK_B,[ssCtrl]);
  //AssignShortcut('ItalicAction',VK_I,[ssCtrl]);
  //AssignShortcut('ClearFormattingAction',VK_D,[ssCtrl]);
  //AssignShortcut('IncreaseIndentAction',VK_OEM_COMMA,[ssCtrl]);
  //AssignShortCut('DecreaseIndentAction',VK_OEM_PERIOD,[ssCtrl]);
  AssignShortCut('FullscreenAction',VK_F11);
  AssignShortCut('CheckSpellingAction',VK_F7);
  AssignShortCut('ProjectExplorerAction',VK_P,[ssCtrl,ssAlt]);

  AssignShortCut('NextTabAction',VK_TAB,[ssCtrl]);
  AssignShortCut('PreviousTabAction',VK_TAB,[ssCtrl,ssShift]);
end;

function TMainForm.CreateFrame(aEditorType: TDocumentFrameClass
  ): TDocumentFrame;
var
  lTab: TTabSheet;
begin

    lTab := TTabSheet.Create(DocumentTabs);
    lTab.Parent := DocumentTabs;
    result := aEditorType.Create(lTab);
    result.Parent := lTab;
    result.Align := alClient;
    result.OnLoaded:=@DocumentFrameLoaded;
    result.OnCaptionChanged:=@DocumentCaptionChanged;
    DocumentTabs.PageIndex := lTab.PageIndex;

end;

function TMainForm.SaveFrame(aFrame: TDocumentFrame): Boolean;
begin
  if aFrame.IsModified then
  begin

    if (aFrame.FileName = '') or
    // also need to show save as if the file's directory does not exist.
    // This catches at least some cases where they provided a non-existent filename
    // from the command line (in order to create a file), but were starting
    // from a different directory than they thought they were.
    // Anyway, that's the way Leafpad behaves, and gedit shows an error message
    // in this case.
       (not DirectoryExists(ExtractFileDir(aFrame.FileName))) then
    begin
      result := SaveFrameAs(aFrame)
    end
    else
    begin
      aFrame.Save;
      result := true;
    end;
  end;

end;

function TMainForm.SaveFrameAs(aFrame: TDocumentFrame): Boolean;
var
  lOriginalFileName: String;
begin
  DocumentSaveAsDialog.Filter := TDocumentFrame.EditorDialogFilters(aFrame.GetFileType);
  lOriginalFileName := aFrame.FileName;
  if lOriginalFileName <> '' then
  begin
      DocumentSaveAsDialog.FileName := aFrame.FileName;
      DocumentSaveAsDialog.FilterIndex := TDocumentFrame.FindFormatFilterIndexForFile(aFrame.FileFormatID,aFrame.FileName) + 1;
  end
  else
  begin
      DocumentSaveAsDialog.FileName := IncludeTrailingPathDelimiter(ExtractFileDir(DocumentSaveAsDialog.FileName)) + 'Untitled.ftm';
      DocumentSaveAsDialog.FilterIndex := 1;
  end;

  if DocumentSaveAsDialog.Execute then
  begin
    if ExtractFileExt(DocumentSaveAsDialog.FileName) = '' then
    begin
    // index is 1-based in the dialog...
       DocumentSaveAsDialog.FileName := ChangeFileExt(DocumentSaveAsDialog.FileName,'.' + TDocumentFrame.FindExtensionForFormatFilterIndex(aFrame.GetFileType,DocumentSaveAsDialog.FilterIndex - 1));
       if FileExists(DocumentSaveAsDialog.FileName) and
          (MessageDlg(rsfdOverwriteFile,
                         Format(rsfdFileAlreadyExists,[DocumentSaveAsDialog.FileName]),
                         mtConfirmation,[mbOk,mbCancel],0) <> mrOk) then
          begin
            result := false;
            Exit;
          end;
    end;
    // save according to the format specified for the filename chosen, no
    // matter what the filter says.
    aFrame.SaveAs(DocumentSaveAsDialog.FileName,TDocumentFrame.FindFormatIDForFile(DocumentSaveAsDialog.FileName));
    result := true;
  end
  else
    result := false;


end;

function TMainForm.CloseTab(aTab: TTabSheet): Boolean;
begin
  result := CanCloseTab(aTab);
  if result then
  begin
     aTab.Free;
     if DocumentTabs.PageCount = 0 then
        NewFile(TDocumentFrame.FindEditorForFileType(TDocumentFrame.FindDefaultFileType));
  end;
end;

function TMainForm.CanCloseTab(aTab: TTabSheet): Boolean;
var
  lFrame: TDocumentFrame;
begin
  result := true;
  lFrame := GetFrame(aTab);
  if lFrame.IsModified then
  begin
    DocumentTabs.ActivePage := aTab;
    case MessageDlg('Document is modified. Do you want to save?', mtConfirmation, mbYesNoCancel, 0) of
       mrYes:
       begin
         result := SaveFrame(lFrame);
       end;
       mrNo:
         result := true;
       mrCancel:
       begin
         result := false;
       end;

    end;
  end;

end;

function TMainForm.GetFrame(index: Integer): TDocumentFrame;
begin
  result := GetFrame(DocumentTabs.Pages[index]);
end;

function TMainForm.GetFrame(aTab: TTabsheet): TDocumentFrame;
begin
  if (aTab.ComponentCount > 0) and (aTab.Components[0] is TDocumentFrame) then
     result := aTab.Components[0] as TDocumentFrame
  else
     result := nil;
end;

function TMainForm.GetTab(aFrame: TDocumentFrame): TTabSheet;
begin
  result := aFrame.Parent as TTabSheet;
end;

function TMainForm.GetCurrentFrame: TDocumentFrame;
begin
  if HasFrame then
  result := GetFrame(DocumentTabs.ActivePage);
end;

function TMainForm.HasFrame: Boolean;
begin
  result := DocumentTabs.PageCount > 0;
end;

procedure TMainForm.ToggleFullscreen;
begin

  // I can't depend on WindowState to report the actual value, see
  // extensive notes in FormWindowStateChange.
  if fFullscreen then
  begin
    fFullscreen := false;
    WindowState := fOriginalState;
  end
  else
  begin
    fFullscreen := true;
    fOriginalState := WindowState;
    WindowState := wsFullScreen;
  end;
  FullScreenChanged;

end;

procedure TMainForm.FullScreenChanged;
begin
  if fFullscreen then
  begin
    HideMenu;
    HideTabs;
    MakeDocumentsFullscreen;
  end
  else
  begin
    ShowMenu;
    ShowTabs;
    MakeDocumentsNotFullscreen;
  end;

end;

procedure TMainForm.ToggleProjectExplorer;
begin
  if IsProjectExplorerVisible then
     HideProjectExplorer
  else
     ShowProjectExplorer;
end;

function TMainForm.IsProjectExplorerVisible: Boolean;
begin
  result := LeftSidebar.Visible and (LeftSidebar.Width > 1);
end;

procedure TMainForm.HideProjectExplorer;
begin
  LeftSidebar.Width := 1;
end;

procedure TMainForm.ShowProjectExplorer;
begin
  if (fProjectDirectory = '') then
  begin
    OpenProjectAction(nil);
  end
  else
  begin
    LeftSidebar.Width := 170;
    RefreshProjectView;
  end;

end;

procedure TMainForm.ToggleRevealTags;
begin
  if fRevealTags then
  begin
    fRevealTags := false;
    MakeDocumentsNotRevealTags;
  end
  else
  begin
    fRevealTags := true;
    MakeDocumentsRevealTags;
  end;

end;

procedure TMainForm.ShowMenu;
begin
  Menu := MainFormMenu;
end;

procedure TMainForm.HideMenu;
begin
  Menu := nil;
end;

procedure TMainForm.ShowTabs;
begin
  DocumentTabs.ShowTabs := true;
end;

procedure TMainForm.HideTabs;
begin
  DocumentTabs.ShowTabs := false;
end;


procedure TMainForm.SetCaption;
var
  lCaption: String;
begin
  lCaption := 'Simplepad';
  if HasFrame then
     lCaption := lCaption + ' - ' +GetCurrentFrame.Caption;
  Caption := lCaption;
end;

procedure TMainForm.MakeDocumentsNotFullscreen;
var
  i: Integer;
begin
  for i := 0 to DocumentTabs.PageCount - 1 do
  begin
    GetFrame(i).MakeNotFullscreen;
  end;

end;

procedure TMainForm.MakeDocumentsFullscreen;
var
  i: Integer;
begin
  for i := 0 to DocumentTabs.PageCount - 1 do
  begin
    GetFrame(i).MakeFullscreen;
  end;

end;

procedure TMainForm.MakeDocumentsNotRevealTags;
var
  i: Integer;
begin
  for i := 0 to DocumentTabs.PageCount - 1 do
  begin
    GetFrame(i).MakeNotRevealTags;
  end;
end;

procedure TMainForm.MakeDocumentsRevealTags;
var
  i: Integer;
begin
  for i := 0 to DocumentTabs.PageCount - 1 do
  begin
    GetFrame(i).MakeRevealTags;
  end;
end;

procedure TMainForm.NotImplemented(aFunction: String);
begin
  ShowMessage(aFunction + ' is not implemented yet.');
end;

procedure TMainForm.LoadProjectFiles(aDirectory: UTF8String; aNode: TTreeNode;
  var vCounter: Longint);
var
  lSearch: LongInt;
  lSearchRec: TSearchRec;
  lNode: TTreeNode;
begin
  lSearch := FindFirst(IncludeTrailingPathDelimiter(aDirectory) + '*',faDirectory,lSearchRec);
  try
    while lSearch = 0 do
    begin
      if vCounter >= fMaxProjectSize then
         raise EMaxProjectSizeReached.Create('Maximum project size reached');
      inc(vCounter);
      if lSearchRec.Name[1] <> '.' then
      begin
         if (lSearchRec.Attr and faDirectory) = faDirectory then
         begin
           lNode := ProjectTreeView.Items.AddChild(aNode,lSearchRec.Name);
           LoadProjectFiles(IncludeTrailingPathDelimiter(aDirectory) + lSearchRec.Name,lNode,vCounter);
           if lNode.Count = 0 then
              ProjectTreeView.Items.Delete(lNode);
         end
         else if TDocumentFrame.FindEditorForFormatID(
                     TDocumentFrame.FindFormatIDForFile(lSearchRec.Name)) <> nil then
         begin
           lNode := ProjectTreeView.Items.AddChild(aNode,lSearchRec.Name);
         end;

      end;

      lSearch := FindNext(lSearchRec);
    end;
  finally
    FindClose(lSearchRec);
  end;

end;


end.

