unit gtk_textwidget;

{$mode objfpc}{$H+}
{$modeswitch advancedrecords}

interface

{$IFDEF LCLGTK2}
uses
  Classes, SysUtils, RichMemo, gtk2, gdk2, glib2, Gtk2RichMemo, graphics;

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
  I don't have the extra TRichMemo stuff. Heck, I might even descend from something
  even higher up, such as TWinControl, so I can stick to just properties which
  are necessary. This would also make the sharing of buffers and tag tables
  easier, since I could add these before the widget handle is created.

  https://developer.gnome.org/gtk2/stable/TextWidget.html
  }

  {
  NOTE: I've implemented the various associated non-widget objects as advanced records
  with references to the pointers that they are associated with. This is for two
  reasons:
  1) I don't want to keep creating objects whenever this data is retrieved, so
  I'd have to cache the object when it's created, and that starts to get messy when
  you're passing around buffers between widgets.
  2) I want to keep the memory management of those things in GTK itself, so the
  programmer doesn't have to worry about that. This means that, if the user wants,
  they don't even have to create their own objects, they can just access them through
  TextWidgets themselves (even sharing buffers and tag tables). Therefore, the
  pointer references themselves can be allocated on the stack.
  }

  TTextJustification = (tjLeft, tjRight, tjCenter, tjFill);
  TWrapMode = (wmNone, wmChar, wmWord, wmWordChar);
  TSearchFlag = (sfVisibleOnly, sfTextOnly);
  TSearchFlags = set of TSearchFlag;

  { TTextMark }

  TTextMark = record
  private
    fMark: PGtkTextMark;
    function GetDeleted: Boolean;
    function GetLeftGravity: Boolean;
    function GetName: String;
    function GetVisible: Boolean;
    procedure SetVisible(AValue: Boolean);
  protected
    class function New(aMark: PGtkTextMark): TTextMark; static;
  public
    property LeftGravity: Boolean read GetLeftGravity;
    property Name: String read GetName;
    property Visible: Boolean read GetVisible write SetVisible;
    property Deleted: Boolean read GetDeleted;
  end;

  { TTextIter }

  TTextIter = record
  private
    fIter: TGtkTextIter;
    function GetLine: Longint;
    function GetLineIndex: Longint;
    function GetLineOffset: Longint;
    function GetOffset: Longint;
    function GetVisibleLineIndex: Longint;
    function GetVisibleLineOffset: LongInt;
    procedure SetLine(AValue: Longint);
    procedure SetLineIndex(AValue: Longint);
    procedure SetLineOffset(AValue: Longint);
    procedure SetOffset(AValue: Longint);
    procedure SetVisibleLineIndex(AValue: Longint);
    procedure SetVisibleLineOffset(AValue: LongInt);
  protected
    class function New(aIter: TGtkTextIter): TTextIter; static;
  public
    property Offset: Longint read GetOffset write SetOffset;
    property Line: Longint read GetLine write SetLine;
    property LineOffset: Longint read GetLineOffset write SetLineOffset;
    property LineIndex: Longint read GetLineIndex write SetLineIndex;
    property VisibleLineIndex: Longint read GetVisibleLineIndex write SetVisibleLineIndex;
    property VisibleLineOffset: LongInt read GetVisibleLineOffset write SetVisibleLineOffset;
    // TODO: What else?
    function ForwardSearch(aNeedle: UTF8String; aFlags: TSearchFlags; out oMatchStart: TTextIter; out oMatchEnd: TTextIter; aLimit: TTextIter): Boolean;
    function BackwardSearch(aNeedle: UTF8String; aFlags: TSearchFlags; out oMatchStart: TTextIter; out oMatchEnd: TTextIter; aLimit: TTextIter): Boolean;
  end;


  { TTagTable }

  TTagTable = record
  private
    fTable: PGtkTextTagTable;
  protected
    class function New(aTable: PGtkTextTagTable): TTagTable; static;
  public
    class function New: TTagTable; static;
  end;

  { TTextBuffer }

  TTextBuffer = record
  private
    fBuffer: PGtkTextBuffer;
    function GetCharCount: Longint;
    function GetEndIter: TTextIter;
    function GetInsertMark: TTextMark;
    function GetLineCount: Longint;
    function GetStartIter: TTextIter;
    function GetTagTable: TTagTable;
  protected
     class function New(aBuffer: PGtkTextBuffer): TTextBuffer; static;
  public
     class function New(aTagTable: TTagTable): TTextBuffer; static;
     property LineCount: Longint read GetLineCount;
     property CharCount: Longint read GetCharCount;
     property TagTable: TTagTable read GetTagTable;
     // TODO: What else?
     property InsertMark: TTextMark read GetInsertMark;
     function IterAtMark(aMark: TTextMark): TTextIter;
     property EndIter: TTextIter read GetEndIter;
     property StartIter: TTextIter read GetStartIter;
     procedure SelectRange(aInsertMark: TTextIter; aBoundMark: TTextIter);
  end;

  { TTextMarkHelper }

  TTextMarkHelper = record helper for TTextMark
  private
    function GetBuffer: TTextBuffer;
  public
    property Buffer: TTextBuffer read GetBuffer;
  end;


  { TTextWidget }

  TTextWidget = class(TRichMemo)
  private
    function GetAcceptsTab: Boolean;
    // TODO: Wrap...
    function GetBuffer: TTextBuffer;
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
    function GetTextView: PGtkTextView;
    function GetWrapMode: TWrapMode;
    procedure SetAcceptsTab(AValue: Boolean);
    procedure SetBuffer(AValue: TTextBuffer);
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
    procedure SetWrapMode(AValue: TWrapMode);
  protected
    property TextView: PGtkTextView read GetTextView;
  public
    // TODO: Set Buffer? Probably, but I have to make sure the old one gets
    // freed when I set it, and even then only if it's owned by me.
    // TODO: Wrap
    property Buffer: TTextBuffer read GetBuffer write SetBuffer;
    {
    Creates a new buffer for this widget (clearing all data) with the
    given tag table backing.

    This one gets around a problem with our architecture, and can hopefully
    disappear if I descend directly from TWinControl. Basically, I want to
    be able to share tag tables between buffers. However, the buffer is
    already created in CreateWnd. I can 'set' the buffer above, but that
    only allows me to share a buffer between two widgets, not the tag table
    between two buffers.

    What I *should* be able to do is provide a tag table or a buffer before
    the TextView is actually created, and have it assign those.
    }
    procedure NewBufferWithTagTable(aTable: TTagTable);
    procedure ScrollToMark(aMark: TTextMark; aWithinMargin: Double;
      aUseAlign: Boolean; aXAlign: Double; aYAlign: Double);
    function ScrollToIter(aIter: TTextIter; aWithinMargin: Double;
      aUseAlign: Boolean; aXAlign: Double; aYAlign: Double): Boolean;
    procedure ScrollMarkOnscreen(aMark: TTextMark);
    function MoveMarkOnscreen(aMark: TTextMark): Boolean;
    function PlaceCursorOnscreen: Boolean;
    //void 	gtk_text_view_get_visible_rect ()
    function GetIterLocation(aIter: TTextIter): TGdkRectangle;
    function GetLineAtY(aY: Longint; out oLineTop: LongInt): TTextIter;
    procedure GetLineYRange(aIter: TTextIter; out oY: Longint; out oHeight: Longint
      );
    function GetIterAtLocation(aX: Longint; aY: Longint): TTextIter;
    function GetIterAtPosition(var vTrailing: Longint; aX: LongInt; aY: LongInt
      ): TTextIter;
    function GetIterAtPosition(aX: LongInt; aY: LongInt
      ): TTextIter;
    //void 	gtk_text_view_buffer_to_window_coords ()
    //void 	gtk_text_view_window_to_buffer_coords ()
    //GdkWindow * 	gtk_text_view_get_window ()
    //GtkTextWindowType 	gtk_text_view_get_window_type ()
    //void 	gtk_text_view_set_border_window_size ()
    //gint 	gtk_text_view_get_border_window_size ()
    function ForwardDisplayLine(aIter: TTextIter): Boolean;
    function BackwardDisplayLine(aIter: TTextIter): Boolean;
    function ForwardDisplayLineEnd(aIter: TTextIter): Boolean;
    function BackwardDisplayLineStart(aIter: TTextIter): Boolean;
    function StartsDisplayLine(aIter: TTextIter): Boolean;
    function MoveVisually(aIter: TTextIter; aCount: Longint): Boolean;
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
    property AcceptsTab: Boolean read GetAcceptsTab write SetAcceptsTab;
    //void 	gtk_text_view_set_tabs ()
    //PangoTabArray* 	gtk_text_view_get_tabs ()
    //GtkTextAttributes* gtk_text_view_get_default_attributes (GtkTextView *text_view);
    // TODO: Wrap
    function ImContextFilterKeypress(aEvent: PGdkEventKey): Boolean;
    procedure ResetImContext;
    //GtkAdjustment * 	gtk_text_view_get_hadjustment ()
    //GtkAdjustment * 	gtk_text_view_get_vadjustment ()
  end;

{$ENDIF}
implementation

{ TTextMarkHelper }

function TTextMarkHelper.GetBuffer: TTextBuffer;
begin
  result := TTextBuffer.New(gtk_text_mark_get_buffer(fMark));
end;

{ TTagTable }

class function TTagTable.New(aTable: PGtkTextTagTable): TTagTable;
begin
  result.fTable := aTable;
end;

class function TTagTable.New: TTagTable;
begin
  result.fTable := gtk_text_tag_table_new;
end;

{ TTextBuffer }

function TTextBuffer.GetCharCount: Longint;
begin
  result := gtk_text_buffer_get_char_count(fBuffer);
end;

function TTextBuffer.GetEndIter: TTextIter;
var
  lIter: TGtkTextIter;
begin
  gtk_text_buffer_get_end_iter(fBuffer,@lIter);
  result := TTextIter.New(lIter);

end;

function TTextBuffer.GetInsertMark: TTextMark;
begin
  result := TTextMark.New(gtk_text_buffer_get_insert(fBuffer));
end;

function TTextBuffer.GetLineCount: Longint;
begin
  result := gtk_text_buffer_get_line_count(fBuffer);
end;

function TTextBuffer.GetStartIter: TTextIter;
var
  lIter: TGtkTextIter;
begin
  gtk_text_buffer_get_start_iter(fBuffer,@lIter);
  result := TTextIter.New(lIter);

end;

function TTextBuffer.GetTagTable: TTagTable;
begin
  result := TTagTable.New(gtk_text_buffer_get_tag_table(fBuffer));
end;

class function TTextBuffer.New(aBuffer: PGtkTextBuffer): TTextBuffer;
begin
  result.fBuffer := aBuffer;
end;

class function TTextBuffer.New(aTagTable: TTagTable): TTextBuffer;
begin
  result.fBuffer := gtk_text_buffer_new(aTagTable.fTable);
end;

function TTextBuffer.IterAtMark(aMark: TTextMark): TTextIter;
var
  lIter: TGtkTextIter;
begin
  gtk_text_buffer_get_iter_at_mark(fBuffer,@lIter,aMark.fMark);
  result := TTextIter.New(lIter);
end;

procedure TTextBuffer.SelectRange(aInsertMark: TTextIter; aBoundMark: TTextIter
  );
begin
  gtk_text_buffer_select_range(fBuffer,@aInsertMark.fIter,@aBoundMark.fIter);
end;

{ TTextIter }

function TTextIter.GetLine: Longint;
begin
  result := gtk_text_iter_get_line(@fIter);
end;

function TTextIter.GetLineIndex: Longint;
begin
  result := gtk_text_iter_get_line_index(@fIter);
end;

function TTextIter.GetLineOffset: Longint;
begin
  result := gtk_text_iter_get_line_offset(@fIter);

end;

function TTextIter.GetOffset: Longint;
begin
  result := gtk_text_iter_get_offset(@fIter);

end;

function TTextIter.GetVisibleLineIndex: Longint;
begin
  result := gtk_text_iter_get_visible_line_index(@fIter);

end;

function TTextIter.GetVisibleLineOffset: LongInt;
begin
  result := gtk_text_iter_get_visible_line_offset(@fIter);

end;

procedure TTextIter.SetLine(AValue: Longint);
begin
  gtk_text_iter_set_line(@fIter,aValue);
end;

procedure TTextIter.SetLineIndex(AValue: Longint);
begin
  gtk_text_iter_set_line_index(@fIter,aValue);

end;

procedure TTextIter.SetLineOffset(AValue: Longint);
begin
  gtk_text_iter_set_line_offset(@fIter,aValue);

end;

procedure TTextIter.SetOffset(AValue: Longint);
begin
  gtk_text_iter_set_offset(@fIter,aValue);

end;

procedure TTextIter.SetVisibleLineIndex(AValue: Longint);
begin
  gtk_text_iter_set_visible_line_index(@fIter,aValue);

end;

procedure TTextIter.SetVisibleLineOffset(AValue: LongInt);
begin
  gtk_text_iter_set_visible_line_offset(@fIter,aValue);

end;

class function TTextIter.New(aIter: TGtkTextIter): TTextIter;
begin
  result.fIter := aIter;
end;

function TTextIter.ForwardSearch(aNeedle: UTF8String; aFlags: TSearchFlags; out
  oMatchStart: TTextIter; out oMatchEnd: TTextIter; aLimit: TTextIter): Boolean;
var
  lSearchFlags: TGtkTextSearchFlags;
  lMatchStart: TGtkTextIter;
  lMatchEnd: TGtkTextIter;
begin
  lSearchFlags := 0;
  if sfTextOnly in aFlags then
     lSearchFlags := GTK_TEXT_SEARCH_TEXT_ONLY;
  if sfVisibleOnly in aFlags then
     lSearchFlags := lSearchFlags and GTK_TEXT_SEARCH_VISIBLE_ONLY;
  result := gtk_text_iter_forward_search(@fIter,PChar(aNeedle),lSearchFlags,@lMatchStart,@lMatchEnd,@aLimit.fIter);
  oMatchStart := TTextIter.New(lMatchStart);
  oMatchEnd := TTextIter.New(lMatchEnd);
end;

function TTextIter.BackwardSearch(aNeedle: UTF8String; aFlags: TSearchFlags;
  out oMatchStart: TTextIter; out oMatchEnd: TTextIter; aLimit: TTextIter
  ): Boolean;
var
  lSearchFlags: TGtkTextSearchFlags;
  lMatchStart: TGtkTextIter;
  lMatchEnd: TGtkTextIter;
begin
  lSearchFlags := 0;
  if sfTextOnly in aFlags then
     lSearchFlags := GTK_TEXT_SEARCH_TEXT_ONLY;
  if sfVisibleOnly in aFlags then
     lSearchFlags := lSearchFlags and GTK_TEXT_SEARCH_VISIBLE_ONLY;
  result := gtk_text_iter_backward_search(@fIter,PChar(aNeedle),lSearchFlags,@lMatchStart,@lMatchEnd,@aLimit.fIter);
  oMatchStart := TTextIter.New(lMatchStart);
  oMatchEnd := TTextIter.New(lMatchEnd);
end;

{$IFDEF LCLGTK2}

{ TTextMark }

function TTextMark.GetDeleted: Boolean;
begin
  result := gtk_text_mark_get_deleted(fMark);
end;

function TTextMark.GetLeftGravity: Boolean;
begin
  result := gtk_text_mark_get_left_gravity(fMark);
end;

function TTextMark.GetName: String;
begin
  result := gtk_text_mark_get_name(fMark);
end;

function TTextMark.GetVisible: Boolean;
begin
  result := gtk_text_mark_get_visible(fMark);
end;

procedure TTextMark.SetVisible(AValue: Boolean);
begin
  gtk_text_mark_set_visible(fMark,AValue);
end;

class function TTextMark.New(aMark: PGtkTextMark): TTextMark;
begin
  result.fMark := aMark;
end;

{ TTextWidget }

function TTextWidget.GetAcceptsTab: Boolean;
begin
  result := gtk_text_view_get_accepts_tab(TextView);
end;

function TTextWidget.GetBuffer: TTextBuffer;
begin
  result := TTextBuffer.New(gtk_text_view_get_buffer(TextView));
end;

function TTextWidget.GetCursorVisible: Boolean;
begin
  result := gtk_text_view_get_cursor_visible(TextView);
end;

function TTextWidget.GetEditable: Boolean;
begin
  result := gtk_text_view_get_editable(TextView);
end;

function TTextWidget.GetIndent: Longint;
begin
  result := gtk_text_view_get_indent(TextView);
end;

function TTextWidget.GetJustification: TTextJustification;
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

function TTextWidget.GetLeftMargin: Longint;
begin
  result := gtk_text_view_get_left_margin(TextView);
end;

function TTextWidget.GetOverwrite: Boolean;
begin
  result := gtk_text_view_get_overwrite(TextView);
end;

function TTextWidget.GetPixelsAboveLines: Longint;
begin
  result := gtk_text_view_get_pixels_above_lines(TextView);
end;

function TTextWidget.GetPixelsBelowLines: Longint;
begin
  result := gtk_text_view_get_pixels_below_lines(TextView);
end;

function TTextWidget.GetPixelsInsideWrap: Longint;
begin
  result := gtk_text_view_get_pixels_inside_wrap(TextView);
end;

function TTextWidget.GetRightMargin: Longint;
begin
  result := gtk_text_view_get_right_margin(TextView);
end;

function TTextWidget.GetTextView: PGtkTextView;
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

function TTextWidget.GetWrapMode: TWrapMode;
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

procedure TTextWidget.SetAcceptsTab(AValue: Boolean);
begin
  gtk_text_view_set_accepts_tab(TextView,AValue);
end;

procedure TTextWidget.SetBuffer(AValue: TTextBuffer);
begin
  // In theory, the only way a new buffer would be created is if it came
  // from another TTextWidget. So, I'll let GTK manage the memory.
  gtk_text_view_set_buffer(TextView,AValue.fBuffer);
end;

procedure TTextWidget.SetCursorVisible(AValue: Boolean);
begin
  gtk_text_view_set_cursor_visible(TextView,AValue);
end;

procedure TTextWidget.SetEditable(AValue: Boolean);
begin
  gtk_text_view_set_editable(TextView,AValue);
end;

procedure TTextWidget.SetIndent(AValue: Longint);
begin
  gtk_text_view_set_indent(TextView,AValue);
end;

procedure TTextWidget.SetJustification(AValue: TTextJustification);
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

procedure TTextWidget.SetLeftMargin(AValue: Longint);
begin
  gtk_text_view_set_left_margin(TextView,AValue);
end;

procedure TTextWidget.SetOverwrite(AValue: Boolean);
begin
  gtk_text_view_set_overwrite(TextView,AValue);
end;

procedure TTextWidget.SetPixelsAboveLines(AValue: Longint);
begin
  gtk_text_view_set_pixels_above_lines(TextView,AValue);
end;

procedure TTextWidget.SetPixelsBelowLines(AValue: Longint);
begin
  gtk_text_view_set_pixels_below_lines(TextView,AValue);
end;

procedure TTextWidget.SetPixelsInsideWrap(AValue: Longint);
begin
  gtk_text_view_set_pixels_inside_wrap(TextView,AValue);
end;

procedure TTextWidget.SetRightMargin(AValue: Longint);
begin
  gtk_text_view_set_right_margin(TextView,AValue);
end;

procedure TTextWidget.SetWrapMode(AValue: TWrapMode);
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

procedure TTextWidget.NewBufferWithTagTable(aTable: TTagTable);
var
  lBuffer: PGtkTextBuffer;
begin
  lBuffer := gtk_text_buffer_new(aTable.fTable);
  gtk_text_view_set_buffer(TextView,lBuffer);
end;

procedure TTextWidget.ScrollToMark(aMark: TTextMark; aWithinMargin: Double;
  aUseAlign: Boolean; aXAlign: Double; aYAlign: Double);
begin
  gtk_text_view_scroll_to_mark(TextView,aMark.fMark,aWithinMargin,aUseAlign,aXAlign,aYAlign);
end;

function TTextWidget.ScrollToIter(aIter: TTextIter; aWithinMargin: Double;
  aUseAlign: Boolean; aXAlign: Double; aYAlign: Double): Boolean;
begin
  result := gtk_text_view_scroll_to_iter(TextView,@aIter.fIter,aWithinMargin,aUseAlign,aXAlign,aYAlign);
end;

procedure TTextWidget.ScrollMarkOnscreen(aMark: TTextMark);
begin
  gtk_text_view_scroll_mark_onscreen(TextView,aMark.fMark);
end;

function TTextWidget.MoveMarkOnscreen(aMark: TTextMark): Boolean;
begin
  result := gtk_text_view_move_mark_onscreen(TextView,aMark.fMark);
end;

function TTextWidget.PlaceCursorOnscreen: Boolean;
begin
  result := gtk_text_view_place_cursor_onscreen(TextView);
end;

function TTextWidget.GetIterLocation(aIter: TTextIter): TGdkRectangle;
begin
  gtk_text_view_get_iter_location(TextView,@aIter.fIter,@Result);

end;

function TTextWidget.GetLineAtY(aY: Longint; out oLineTop: LongInt): TTextIter;
var
  lIter: TGtkTextIter;
begin
  gtk_text_view_get_line_at_y(TextView,@lIter,aY,@oLineTop);
  result := TTextIter.New(lIter);
end;

procedure TTextWidget.GetLineYRange(aIter: TTextIter; out oY: Longint; out oHeight: Longint);
begin
  gtk_text_view_get_line_yrange(TextView,@aIter.fIter,@oY,@oHeight);
end;

function TTextWidget.GetIterAtLocation(aX: Longint; aY: Longint): TTextIter;
var
  lIter: TGtkTextIter;
begin
  gtk_text_view_get_iter_at_location(TextView,@lIter,aX,aY);
  result := TTextIter.New(lIter);

end;

function TTextWidget.GetIterAtPosition(var vTrailing: Longint;
  aX: LongInt; aY: LongInt): TTextIter;
var
  lIter: TGtkTextIter;
begin
  gtk_text_view_get_iter_at_position(TextView,@lIter,@vTrailing,aX,aY);
  result := TTextIter.New(lIter);
end;

function TTextWidget.GetIterAtPosition(aX: LongInt; aY: LongInt): TTextIter;
var
  lIter: TGtkTextIter;
begin
  gtk_text_view_get_iter_at_position(TextView,@lIter,nil,aX,aY);
  result := TTextIter.New(lIter);
end;

function TTextWidget.ForwardDisplayLine(aIter: TTextIter): Boolean;
begin
  result := gtk_text_view_forward_display_line(TextView,@aIter.fIter);
end;

function TTextWidget.BackwardDisplayLine(aIter: TTextIter): Boolean;
begin
  result := gtk_text_view_backward_display_line(TextView,@aIter.fIter);
end;

function TTextWidget.ForwardDisplayLineEnd(aIter: TTextIter): Boolean;
begin
  result := gtk_text_view_forward_display_line_end(TextView,@aIter.fIter);
end;

function TTextWidget.BackwardDisplayLineStart(aIter: TTextIter): Boolean;
begin
  result := gtk_text_view_backward_display_line_start(TextView,@aIter.fIter);
end;

function TTextWidget.StartsDisplayLine(aIter: TTextIter): Boolean;
begin
  result := gtk_text_view_starts_display_line(TextView,@aIter.fIter);
end;

function TTextWidget.MoveVisually(aIter: TTextIter; aCount: Longint): Boolean;
begin
  result := gtk_text_view_move_visually(TextView,@aIter.fIter,aCount);
end;

// TODO: This wasn't declared in gtktextview.inc, why?
function gtk_text_view_im_context_filter_keypress(text_view:PGtkTextView; event:PGdkEventKey):gboolean; cdecl; external gtklib;

function TTextWidget.ImContextFilterKeypress(aEvent: PGdkEventKey): Boolean;
begin
  result := gtk_text_view_im_context_filter_keypress(TextView,aEvent);
end;

// TODO: This wasn't declared in gtktextview.inc, why?
procedure gtk_text_view_reset_im_context (text_view:PGtkTextView); cdecl; external gtklib;

procedure TTextWidget.ResetImContext;
begin
  gtk_text_view_reset_im_context(TextView);
end;

{$ENDIF}
end.

