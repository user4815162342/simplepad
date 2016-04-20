unit gtk_textwidget;

{$mode objfpc}{$H+}

interface

{$IFDEF LCLGTK2}
uses
  Classes, SysUtils, RichMemo, gtk2, Gtk2RichMemo;

type
  {
  Basically extends TRichMemo to allow more direct access to the GTK functionality,
  since the abstraction layer removes some features. This does mean this is
  platform dependent, but in theory I could *not* compile this if I'm not using
  GTK2, and therefore the application simply wouldn't support this mechanism.

  units with useful information in richmemopackage:
  - RichMemo
  - Gtk2RichMemo

  TODO: Need to wrap the various pointers in helper types that aren't pointers.

  https://developer.gnome.org/gtk2/stable/TextWidget.html
  }

  { TGTKTextWidget }

  TGTKTextWidget = class(TRichMemo)
  private
    function GetAcceptsTab: Boolean;
    function GetBuffer: PGtkTextBuffer;
    function GetCursorVisible: Boolean;
    function GetDefaultAttributes: PGtkTextAttributes;
    function GetEditable: Boolean;
    function GetIndent: Longint;
    function GetJustification: TGtkJustification;
    function GetLeftMargin: Longint;
    function GetOverwrite: Boolean;
    function GetPixelsAboveLines: Longint;
    function GetPixelsBelowLines: Longint;
    function GetPixelsInsideWrap: Longint;
    function GetRightMargin: Longint;
    function GetTextView: PGtkTextView;
    function GetWrapMode: TGtkWrapMode;
    procedure SetAcceptsTab(AValue: Boolean);
    procedure SetBuffer(AValue: PGtkTextBuffer);
    procedure SetCursorVisible(AValue: Boolean);
    procedure SetDefaultAttributes(AValue: PGtkTextAttributes);
    procedure SetEditable(AValue: Boolean);
    procedure SetIndent(AValue: Longint);
    procedure SetJustification(AValue: TGtkJustification);
    procedure SetLeftMargin(AValue: Longint);
    procedure SetOverwrite(AValue: Boolean);
    procedure SetPixelsAboveLines(AValue: Longint);
    procedure SetPixelsBelowLines(AValue: Longint);
    procedure SetPixelsInsideWrap(AValue: Longint);
    procedure SetRightMargin(AValue: Longint);
    procedure SetWrapMode(AValue: TGtkWrapMode);
  protected
    property TextView: PGtkTextView read GetTextView;
  public
    property Buffer: PGtkTextBuffer read GetBuffer write SetBuffer;
    procedure ScrollToMark;
    function ScrollToIter: Boolean;
    procedure ScrollMarkOnscreen;
    function MoveMarkOnscreen: Boolean;
    function PlaceCursorOnscreen: Boolean;
    //void 	gtk_text_view_get_visible_rect ()
    procedure GetIterLocation;
    procedure GetLineAtY;
    procedure GetLineYRange;
    procedure GetIterAtLocation;
    procedure GetIterAtPosition;
    //void 	gtk_text_view_buffer_to_window_coords ()
    //void 	gtk_text_view_window_to_buffer_coords ()
    //GdkWindow * 	gtk_text_view_get_window ()
    //GtkTextWindowType 	gtk_text_view_get_window_type ()
    //void 	gtk_text_view_set_border_window_size ()
    //gint 	gtk_text_view_get_border_window_size ()
    function ForwardDisplayLine: Boolean;
    function BackwardDisplayLine: Boolean;
    function ForwardDisplayLineEnd: Boolean;
    function BackwardDisplayLineStart: Boolean;
    function StartsDisplayLine: Boolean;
    function MoveVisually: Boolean;
    //void 	gtk_text_view_add_child_at_anchor ()
    //GtkTextChildAnchor * 	gtk_text_child_anchor_new ()
    //GList * 	gtk_text_child_anchor_get_widgets ()
    //gboolean 	gtk_text_child_anchor_get_deleted ()
    //void 	gtk_text_view_add_child_in_window ()
    //void 	gtk_text_view_move_child ()
    property WrapMode: TGtkWrapMode read GetWrapMode write SetWrapMode;
    property Editable: Boolean read GetEditable write SetEditable;
    property Cursorvisible: Boolean read GetCursorVisible write SetCursorVisible;
    property Overwrite: Boolean read GetOverwrite write SetOverwrite;
    property PixelsAboveLines: Longint read GetPixelsAboveLines write SetPixelsAboveLines;
    property PixelsBelowLines: Longint read GetPixelsBelowLines write SetPixelsBelowLines;
    property PixelsInsideWrap: Longint read GetPixelsInsideWrap write SetPixelsInsideWrap;
    property Justification: TGtkJustification read GetJustification write SetJustification;
    property LeftMargin: Longint read GetLeftMargin write SetLeftMargin;
    property RightMargin: Longint read GetRightMargin write SetRightMargin;
    property Indent: Longint read GetIndent write SetIndent;
    //void 	gtk_text_view_set_tabs ()
    //PangoTabArray * 	gtk_text_view_get_tabs ()
    property AcceptsTab: Boolean read GetAcceptsTab write SetAcceptsTab;
    property DefaultAttributes: PGtkTextAttributes read GetDefaultAttributes write SetDefaultAttributes;
    function ImContextFilterKeypress: Boolean;
    procedure ResetImContext;
    function GetHAdjustment: TGtkAdjustment;
    function GetVAdjustment: TGtkAdjustment;
  end;

{$ENDIF}
implementation

{$IFDEF LCLGTK2}
uses
  glib2;

{ TGTKTextWidget }

function TGTKTextWidget.GetAcceptsTab: Boolean;
begin
  result := gtk_text_view_get_accepts_tab(TextView);
end;

function TGTKTextWidget.GetBuffer: PGtkTextBuffer;
begin
  result := gtk_text_view_get_buffer(TextView);
end;

function TGTKTextWidget.GetCursorVisible: Boolean;
begin
  result := gtk_text_view_get_cursor_visible(TextView);
end;

function TGTKTextWidget.GetDefaultAttributes: PGtkTextAttributes;
begin
  result := gtk_text_view_get_default_attributes(TextView);
end;

function TGTKTextWidget.GetEditable: Boolean;
begin
  result := gtk_text_view_get_editable(TextView);
end;

function TGTKTextWidget.GetIndent: Longint;
begin
  result := gtk_text_view_get_indent(TextView);
end;

function TGTKTextWidget.GetJustification: TGtkJustification;
begin
  result := gtk_text_view_get_justification(TextView);
end;

function TGTKTextWidget.GetLeftMargin: Longint;
begin
  result := gtk_text_view_get_left_margin(TextView);
end;

function TGTKTextWidget.GetOverwrite: Boolean;
begin
  result := gtk_text_view_get_overwrite(TextView);
end;

function TGTKTextWidget.GetPixelsAboveLines: Longint;
begin
  result := gtk_text_view_get_pixels_above_lines(TextView);
end;

function TGTKTextWidget.GetPixelsBelowLines: Longint;
begin
  result := gtk_text_view_get_pixels_below_lines(TextView);
end;

function TGTKTextWidget.GetPixelsInsideWrap: Longint;
begin
  result := gtk_text_view_get_pixels_inside_wrap(TextView);
end;

function TGTKTextWidget.GetRightMargin: Longint;
begin
  result := gtk_text_view_get_right_margin(TextView);
end;

function TGTKTextWidget.GetTextView: PGtkTextView;
var
  Widget     : PGtkWidget;
  list       : PGList;
begin
  result:=nil;
  Widget := PGtkWidget(PtrUInt(Handle));

  list := gtk_container_get_children(PGtkContainer(Widget));
  if not Assigned(list) then Exit;

  result := PGtkTextView(list^.data);
end;

function TGTKTextWidget.GetWrapMode: TGtkWrapMode;
begin
  result := gtk_text_view_get_wrap_mode(TextView);
end;

procedure TGTKTextWidget.SetAcceptsTab(AValue: Boolean);
begin
hereiam;
end;

procedure TGTKTextWidget.SetBuffer(AValue: PGtkTextBuffer);
begin
hereiam;
end;

procedure TGTKTextWidget.SetCursorVisible(AValue: Boolean);
begin
hereiam;
end;

procedure TGTKTextWidget.SetDefaultAttributes(AValue: TGtkTextAttributes);
begin
hereiam;
end;

procedure TGTKTextWidget.SetEditable(AValue: Boolean);
begin
hereiam;
end;

procedure TGTKTextWidget.SetIndent(AValue: Longint);
begin
hereiam;
end;

procedure TGTKTextWidget.SetJustification(AValue: TGtkJustification);
begin
hereiam;
end;

procedure TGTKTextWidget.SetLeftMargin(AValue: Longint);
begin
hereiam;
end;

procedure TGTKTextWidget.SetOverwrite(AValue: Boolean);
begin
hereiam;
end;

procedure TGTKTextWidget.SetPixelsAboveLines(AValue: Longint);
begin
hereiam;
end;

procedure TGTKTextWidget.SetPixelsBelowLines(AValue: Longint);
begin
hereiam;
end;

procedure TGTKTextWidget.SetPixelsInsideWrap(AValue: Longint);
begin
hereiam;
end;

procedure TGTKTextWidget.SetRightMargin(AValue: Longint);
begin
hereiam;
end;

procedure TGTKTextWidget.SetWrapMode(AValue: TGtkWrapMode);
begin
hereiam;
end;

procedure TGTKTextWidget.ScrollToMark;
begin
hereiam;
end;

function TGTKTextWidget.ScrollToIter: Boolean;
begin
hereiam;
end;

procedure TGTKTextWidget.ScrollMarkOnscreen;
begin
hereiam;
end;

function TGTKTextWidget.MoveMarkOnscreen: Boolean;
begin
hereiam;
end;

function TGTKTextWidget.PlaceCursorOnscreen: Boolean;
begin
hereiam;
end;

procedure TGTKTextWidget.GetIterLocation;
begin
hereiam;
end;

procedure TGTKTextWidget.GetLineAtY;
begin
hereiam;
end;

procedure TGTKTextWidget.GetLineYRange;
begin
hereiam;
end;

procedure TGTKTextWidget.GetIterAtLocation;
begin
hereiam;
end;

procedure TGTKTextWidget.GetIterAtPosition;
begin
hereiam;
end;

function TGTKTextWidget.ForwardDisplayLine: Boolean;
begin
hereiam;
end;

function TGTKTextWidget.BackwardDisplayLine: Boolean;
begin
hereiam;
end;

function TGTKTextWidget.ForwardDisplayLineEnd: Boolean;
begin
hereiam;
end;

function TGTKTextWidget.BackwardDisplayLineStart: Boolean;
begin
hereiam;
end;

function TGTKTextWidget.StartsDisplayLine: Boolean;
begin
hereiam;
end;

function TGTKTextWidget.MoveVisually: Boolean;
begin
hereiam;
end;

function TGTKTextWidget.ImContextFilterKeypress: Boolean;
begin
hereiam;
end;

procedure TGTKTextWidget.ResetImContext;
begin
hereiam;
end;

function TGTKTextWidget.GetHAdjustment: TGtkAdjustment;
begin
hereiam;
end;

function TGTKTextWidget.GetVAdjustment: TGtkAdjustment;
begin
hereiam;
end;
{$ENDIF}
end.

