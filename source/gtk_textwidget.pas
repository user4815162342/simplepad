unit gtk_textwidget;

{$mode objfpc}{$H+}

interface

{$IFDEF LCLGTK2}
uses
  Classes, SysUtils, RichMemo, gtk2, gdk2, glib2, pango, Gtk2RichMemo, graphics;

type
  {
  Basically extends TRichMemo to allow more direct access to the GTK functionality,
  since the abstraction layer removes some features. This does mean this is
  platform dependent, but in theory I could *not* compile this if I'm not using
  GTK2, and therefore the application simply wouldn't support this mechanism.

  units with useful information in richmemopackage:
  - RichMemo
  - Gtk2RichMemo

  TODO: Before we go further on this, see if this helps us in anyway. Can I get
  any of the stuff to run? Mostly, I want to make sure I can work with tags,
  so I can control that stuff, instead of the paragraph metrics used by the
  default TRichMemo (or whatever). So, I need to handle buffers, iters and
  tags in the buffers.

  TODO: For testing, I'm going to use a "dumb" binary format. First of all,
  each tag will have an const id number, that is maintained for each instance.
  The tag ids must be within 2-127. (1 would represent "normal text").
  Files are stored using TStream.WriteByte and TStream.WriteANSIString. The beginning
  of a tag is written with WriteByte, and the normal tag value. A closing tag
  is the 255 minus the tag id. When writing a string, it would print out the
  normal text tag, then use WriteAnsiString to write out the contents of the
  string. Reading is a process of reading the tag ID byte, and if it is normal
  text, calling ReadAnsiString. This is not particularly clean, but it makes
  reading and writing quite easy. Eventually, I can create a FTM parser once
  this gtk stuff works.

  TODO: Note that some functions simply won't be implemented. If it turns out
  I need them, then maybe I'll add them, but for now, I think I'm fine.


  TODO: Need to wrap the various pointers in helper types that aren't pointers.
  Start with buffers and iters, some of the other stuff maybe not. I also have
  to make sure memory gets freed for some of the ones the create structures.

  TODO: Need to handle 'signals' as events. How are these handled currently?

  TODO: I *will* have to handle my own undo stuff. I guess I have to listen for
  events so that I can record them and put them on a stack to undo.
  Here's something done in Python, but I'm not sure if this handles style changes:
  https://bitbucket.org/tiax/gtk-textbuffer-with-undo/

  TODO: If this works, move it into a separate component, handling it via the
  usual widgetset system (where the widget is backed by a singleton class which
  handles the widget). Basically, it would descend from TCustomMemo, so that
  I don't have the extra TRichMemo stuff.

  https://developer.gnome.org/gtk2/stable/TextWidget.html
  }

  TTextJustification = (tjLeft, tjRight, tjCenter, tjFill);
  TWrapMode = (wmNone, wmChar, wmWord, wmWordChar);

  { TGTKTextWidget }

  TGTKTextWidget = class(TRichMemo)
  private
    function GetAcceptsTab: Boolean;
    // TODO: Wrap...
    function GetBuffer: PGtkTextBuffer;
    function GetCursorVisible: Boolean;
    function GetEditable: Boolean;
    function GetIndent: Longint;
    function GetJustification: TTextJustification;
    function GetLeftMargin: Longint;
    function GetOverwrite: Boolean;
    function GetPixelsAboveLines: Longint;
    function GetPixelsBelowLines: Longint;
    function GetPixelsInsideWrap: Longint;
    function GetRightMargin: Longint;
    // TODO: Wrap
    function GetTabs: TPangoTabArray;
    function GetTextView: PGtkTextView;
    function GetWrapMode: TWrapMode;
    procedure SetAcceptsTab(AValue: Boolean);
    procedure SetCursorVisible(AValue: Boolean);
    procedure SetEditable(AValue: Boolean);
    procedure SetIndent(AValue: Longint);
    procedure SetJustification(AValue: TTextJustification);
    procedure SetLeftMargin(AValue: Longint);
    procedure SetOverwrite(AValue: Boolean);
    procedure SetPixelsAboveLines(AValue: Longint);
    procedure SetPixelsBelowLines(AValue: Longint);
    procedure SetPixelsInsideWrap(AValue: Longint);
    procedure SetRightMargin(AValue: Longint);
    // TODO: Wrap
    procedure SetTabs(AValue: TPangoTabArray);
    procedure SetWrapMode(AValue: TWrapMode);
  protected
    property TextView: PGtkTextView read GetTextView;
  public
    // TODO: Set Buffer? Probably, but I have to make sure the old one gets
    // freed when I set it, and even then only if it's owned by me.
    // TODO: Wrap
    property Buffer: PGtkTextBuffer read GetBuffer;
    // TODO: Wrap
    procedure ScrollToMark(aMark: PGtkTextMark; aWithinMargin: Double;
      aUseAlign: Boolean; aXAlign: Double; aYAlign: Double);
    // TODO: Wrap
    function ScrollToIter(aIter: PGtkTextIter; aWithinMargin: Double;
      aUseAlign: Boolean; aXAlign: Double; aYAlign: Double): Boolean;
    // TODO: Wrap
    procedure ScrollMarkOnscreen(aMark: PGtkTextMark);
    // TODO: Wrap
    function MoveMarkOnscreen(aMark: PGtkTextMark): Boolean;
    function PlaceCursorOnscreen: Boolean;
    //void 	gtk_text_view_get_visible_rect ()
    // TODO: Wrap
    procedure GetIterLocation(aIter: PGtkTextIter; aLocation: PGdkRectangle);
    // TODO: Wrap
    procedure GetLineAtY(aIter: PGtkTextIter; aY: Longint; aLineTop: Pgint);
    // TODO: Wrap
    procedure GetLineYRange(aIter: PGtkTextIter; y: Pgint; aheight: Pgint);
    // TODO: Wrap
    procedure GetIterAtLocation(aIter: PGtkTextIter; aLocation: PGdkRectangle);
    // TODO: Wrap
    procedure GetIterAtPosition(aIter: PGtkTextIter; aTrailing: Pgint; aX: LongInt;
      aY: LongInt);
    //void 	gtk_text_view_buffer_to_window_coords ()
    //void 	gtk_text_view_window_to_buffer_coords ()
    //GdkWindow * 	gtk_text_view_get_window ()
    //GtkTextWindowType 	gtk_text_view_get_window_type ()
    //void 	gtk_text_view_set_border_window_size ()
    //gint 	gtk_text_view_get_border_window_size ()
    // TODO: Wrap
    function ForwardDisplayLine(aIter: PGtkTextIter): Boolean;
    // TODO: Wrap
    function BackwardDisplayLine(aIter: PGtkTextIter): Boolean;
    // TODO: Wrap
    function ForwardDisplayLineEnd(aIter: PGtkTextIter): Boolean;
    function BackwardDisplayLineStart(aIter: PGtkTextIter): Boolean;
    // TODO: Wrap
    function StartsDisplayLine(aIter: PGtkTextIter): Boolean;
    // TODO: Wrap
    function MoveVisually(aIter: PGtkTextIter; aCount: Longint): Boolean;
    //void 	gtk_text_view_add_child_at_anchor ()
    //GtkTextChildAnchor * 	gtk_text_child_anchor_new ()
    //GList * 	gtk_text_child_anchor_get_widgets ()
    //gboolean 	gtk_text_child_anchor_get_deleted ()
    //void 	gtk_text_view_add_child_in_window ()
    //void 	gtk_text_view_move_child ()
    property WrapMode: TWrapMode read GetWrapMode write SetWrapMode;
    property Editable: Boolean read GetEditable write SetEditable;
    property Cursorvisible: Boolean read GetCursorVisible write SetCursorVisible;
    property Overwrite: Boolean read GetOverwrite write SetOverwrite;
    property PixelsAboveLines: Longint read GetPixelsAboveLines write SetPixelsAboveLines;
    property PixelsBelowLines: Longint read GetPixelsBelowLines write SetPixelsBelowLines;
    property PixelsInsideWrap: Longint read GetPixelsInsideWrap write SetPixelsInsideWrap;
    property Justification: TTextJustification read GetJustification write SetJustification;
    property LeftMargin: Longint read GetLeftMargin write SetLeftMargin;
    property RightMargin: Longint read GetRightMargin write SetRightMargin;
    property Indent: Longint read GetIndent write SetIndent;
    property Tabs: TPangoTabArray read GetTabs write SetTabs;
    property AcceptsTab: Boolean read GetAcceptsTab write SetAcceptsTab;
   //GtkTextAttributes* gtk_text_view_get_default_attributes (GtkTextView *text_view);
    // TODO: Wrap
    function ImContextFilterKeypress(aEvent: PGdkEventKey): Boolean;
    procedure ResetImContext;
    // TODO: Wrap
    function GetHAdjustment: PGtkAdjustment;
    // TODO: Wrap
    function GetVAdjustment: PGtkAdjustment;
  end;

{$ENDIF}
implementation

{$IFDEF LCLGTK2}

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

function TGTKTextWidget.GetEditable: Boolean;
begin
  result := gtk_text_view_get_editable(TextView);
end;

function TGTKTextWidget.GetIndent: Longint;
begin
  result := gtk_text_view_get_indent(TextView);
end;

function TGTKTextWidget.GetJustification: TTextJustification;
begin
  case gtk_text_view_get_justification(TextView) of
    GTK_JUSTIFY_LEFT:
      result := tjLeft;
    GTK_JUSTIFY_RIGHT:
      result := tjRight;
    GTK_JUSTIFY_CENTER:
      result := tjCenter;
    GTK_JUSTIFY_FILL:
      result := tjFill;
  end;
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

function TGTKTextWidget.GetTabs: TPangoTabArray;
begin
  result := gtk_text_view_get_tabs(TextView);
end;

function TGTKTextWidget.GetTextView: PGtkTextView;
var
  Widget     : PGtkWidget;
  list       : PGList;
begin
  result:=nil;
  Widget := {%H-}PGtkWidget(PtrUInt(Handle));

  list := gtk_container_get_children(PGtkContainer(Widget));
  if not Assigned(list) then Exit;

  result := PGtkTextView(list^.data);
end;

function TGTKTextWidget.GetWrapMode: TWrapMode;
begin
  case gtk_text_view_get_wrap_mode(TextView) of
    GTK_WRAP_NONE:
      result := wmNone;
    GTK_WRAP_CHAR:
      result := TWrapMode.wmChar;
    GTK_WRAP_WORD:
      result := wmWord;
  end;
end;

procedure TGTKTextWidget.SetAcceptsTab(AValue: Boolean);
begin
  gtk_text_view_set_accepts_tab(TextView,AValue);
end;

procedure TGTKTextWidget.SetCursorVisible(AValue: Boolean);
begin
  gtk_text_view_set_cursor_visible(TextView,AValue);
end;

procedure TGTKTextWidget.SetEditable(AValue: Boolean);
begin
  gtk_text_view_set_editable(TextView,AValue);
end;

procedure TGTKTextWidget.SetIndent(AValue: Longint);
begin
  gtk_text_view_set_indent(TextView,AValue);
end;

procedure TGTKTextWidget.SetJustification(AValue: TTextJustification);
var
  lValue: TGtkJustification;
begin
  case AValue of
    tjLeft:
      lValue := GTK_JUSTIFY_LEFT;
    tjRight:
      lValue := GTK_JUSTIFY_RIGHT;
    tjCenter:
      lValue := GTK_JUSTIFY_CENTER;
    tjFill:
      lValue := GTK_JUSTIFY_FILL;
  end;
  gtk_text_view_set_justification(TextView,lValue);
end;

procedure TGTKTextWidget.SetLeftMargin(AValue: Longint);
begin
  gtk_text_view_set_left_margin(TextView,AValue);
end;

procedure TGTKTextWidget.SetOverwrite(AValue: Boolean);
begin
  gtk_text_view_set_overwrite(TextView,AValue);
end;

procedure TGTKTextWidget.SetPixelsAboveLines(AValue: Longint);
begin
  gtk_text_view_set_pixels_above_lines(TextView,AValue);
end;

procedure TGTKTextWidget.SetPixelsBelowLines(AValue: Longint);
begin
  gtk_text_view_set_pixels_below_lines(TextView,AValue);
end;

procedure TGTKTextWidget.SetPixelsInsideWrap(AValue: Longint);
begin
  gtk_text_view_set_pixels_inside_wrap(TextView,AValue);
end;

procedure TGTKTextWidget.SetRightMargin(AValue: Longint);
begin
  gtk_text_view_set_right_margin(TextView,AValue);
end;

procedure TGTKTextWidget.SetTabs(AValue: TPangoTabArray);
begin
  gtk_text_view_set_tabs(TextView,AValue);
end;

procedure TGTKTextWidget.SetWrapMode(AValue: TWrapMode);
var
  lValue: TGtkWrapMode;
begin
  case AValue of
    wmNone:
      lValue := GTK_WRAP_NONE;
    TWrapMode.wmChar:
      lValue := GTK_WRAP_CHAR;
    wmWord:
      lValue := GTK_WRAP_WORD;
  end;
  gtk_text_view_set_wrap_mode(TextView,lValue);
end;

procedure TGTKTextWidget.ScrollToMark(aMark: PGtkTextMark; aWithinMargin: Double; aUseAlign: Boolean; aXAlign: Double; aYAlign: Double);
begin
  gtk_text_view_scroll_to_mark(TextView,aMark,aWithinMargin,aUseAlign,aXAlign,aYAlign);
end;

function TGTKTextWidget.ScrollToIter(aIter: PGtkTextIter; aWithinMargin: Double; aUseAlign: Boolean; aXAlign: Double; aYAlign: Double): Boolean;
begin
  result := gtk_text_view_scroll_to_iter(TextView,aIter,aWithinMargin,aUseAlign,aXAlign,aYAlign);
end;

procedure TGTKTextWidget.ScrollMarkOnscreen(aMark: PGtkTextMark);
begin
  gtk_text_view_scroll_mark_onscreen(TextView,aMark);
end;

function TGTKTextWidget.MoveMarkOnscreen(aMark: PGtkTextMark): Boolean;
begin
  result := gtk_text_view_move_mark_onscreen(TextView,aMark);
end;

function TGTKTextWidget.PlaceCursorOnscreen: Boolean;
begin
  result := gtk_text_view_place_cursor_onscreen(TextView);
end;

procedure TGTKTextWidget.GetIterLocation(aIter: PGtkTextIter; aLocation: PGdkRectangle);
begin
  gtk_text_view_get_iter_location(TextView,aIter,aLocation);

end;

procedure TGTKTextWidget.GetLineAtY(aIter: PGtkTextIter; aY: Longint; aLineTop: Pgint);
begin
  gtk_text_view_get_line_at_y(TextView,aIter,aY,aLineTop);
end;

procedure TGTKTextWidget.GetLineYRange(aIter: PGtkTextIter; y: Pgint;
  aheight: Pgint);
begin
  gtk_text_view_get_line_yrange(TextView,aIter,y,aheight);
end;

procedure TGTKTextWidget.GetIterAtLocation(aIter: PGtkTextIter; aLocation: PGdkRectangle);
begin
  gtk_text_view_get_iter_location(TextView,aIter,aLocation);

end;

procedure TGTKTextWidget.GetIterAtPosition(aIter: PGtkTextIter; aTrailing: Pgint; aX: LongInt; aY: LongInt);
begin
  gtk_text_view_get_iter_at_position(TextView,aIter,aTrailing,aX,aY);
end;

function TGTKTextWidget.ForwardDisplayLine(aIter: PGtkTextIter): Boolean;
begin
  result := gtk_text_view_forward_display_line(TextView,aIter);
end;

function TGTKTextWidget.BackwardDisplayLine(aIter: PGtkTextIter): Boolean;
begin
  result := gtk_text_view_backward_display_line(TextView,aIter);
end;

function TGTKTextWidget.ForwardDisplayLineEnd(aIter: PGtkTextIter): Boolean;
begin
  result := gtk_text_view_forward_display_line_end(TextView,aIter);
end;

function TGTKTextWidget.BackwardDisplayLineStart(aIter: PGtkTextIter): Boolean;
begin
  result := gtk_text_view_backward_display_line_start(TextView,aIter);
end;

function TGTKTextWidget.StartsDisplayLine(aIter: PGtkTextIter): Boolean;
begin
  result := gtk_text_view_starts_display_line(TextView,aIter);
end;

function TGTKTextWidget.MoveVisually(aIter: PGtkTextIter; aCount: Longint): Boolean;
begin
  result := gtk_text_view_move_visually(TextView,aIter,aCount);
end;

// TODO: This wasn't declared in gtktextview.inc, why?
function gtk_text_view_im_context_filter_keypress(text_view:PGtkTextView; event:PGdkEventKey):gboolean; cdecl; external gtklib;

function TGTKTextWidget.ImContextFilterKeypress(aEvent: PGdkEventKey): Boolean;
begin
  result := gtk_text_view_im_context_filter_keypress(TextView,aEvent);
end;

// TODO: This wasn't declared in gtktextview.inc, why?
procedure gtk_text_view_reset_im_context (text_view:PGtkTextView); cdecl; external gtklib;

procedure TGTKTextWidget.ResetImContext;
begin
  gtk_text_view_reset_im_context(TextView);
end;

// TODO: This wasn't declared in gtktextview.inc, why?
function gtk_text_view_get_hadjustment (text_view:PGtkTextView): PGtkAdjustment; cdecl; external gtklib;

function TGTKTextWidget.GetHAdjustment: PGtkAdjustment;
begin
  result := gtk_text_view_get_hadjustment(TextView);
end;

// TODO: This wasn't declared in gtktextview.inc, why?
function gtk_text_view_get_vadjustment (text_view:PGtkTextView): PGtkAdjustment; cdecl; external gtklib;


function TGTKTextWidget.GetVAdjustment: PGtkAdjustment;
begin
  result := gtk_text_view_get_vadjustment(TextView);
end;
{$ENDIF}
end.

