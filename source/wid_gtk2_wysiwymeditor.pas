unit wid_gtk2_wysiwymeditor;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, Controls, LCLType,
  gtk2, Gtk2Def, Gtk2Proc, Gtk2Globals, glib2,
  wid_wysiwymeditor,
  wid_ws_wysiwymeditor;

{
TODO: Can I move the textview so that it becomes the actual handle, instead of
a scrolling window? If Lazarus expects WinControl to be scrollable, then that's
okay, otherwise it would be easier if I didn't have to do that.

TODO: Look at all of the signal handlers I brought over from Gtk2RichMemo, and
see whether we actually need them.
}

type
  TGtk2WSWYSIWYMStyleManager = class(TWSWYSIWYMStyleManager)
    {
    TODO: In our case, this would hold a reference to a 'TagTable' to
    be applied to an editor.
    }
  end;

  { TGtk2WSWYSIWYMEditor }

  TGtk2WSWYSIWYMEditor = class(TWSWYSIWYMEditor)
  protected
    class procedure SetCallbacks(const AGtkWidget: PGtkWidget; const AWidgetInfo: PWidgetInfo);
    class procedure GetWidgetBuffer(const AWinControl: TWinControl; var TextWidget: PGtkWidget; var Buffer: PGtkTextBuffer);
  published
    class function CreateHandle(const AWinControl: TWinControl; const AParams: TCreateParams): TLCLIntfHandle; override;
    class procedure DestroyHandle(const AWinControl: TWinControl); override;


  end;

implementation

uses
  gdk2;

procedure Gtk2WS_MemoSelChanged_Before(Textbuffer: PGtkTextBuffer;
   StartIter: PGtkTextIter; mark: PGtkTextMark; WidgetInfo: PWidgetInfo); cdecl;
var
  tag : PGtkTextTag;
begin
  tag := gtk_text_tag_table_lookup( gtk_text_buffer_get_tag_table(TextBuffer)
    , 'numeric');

  // navigate "through" numbering characters
  if gtk_text_iter_has_tag( StartIter, tag) then begin
    // if tried to move at the "endo
    if gtk_text_iter_begins_tag(StartIter, tag) then begin
      gtk_text_iter_forward_to_tag_toggle(StartIter, nil);
      gtk_text_buffer_move_mark(TextBuffer, mark, StartIter);
    end else begin
      gtk_text_iter_forward_char(StartIter);
      if gtk_text_iter_ends_tag(StartIter, tag) then begin
        gtk_text_iter_backward_to_tag_toggle(StartIter, nil);
        gtk_text_iter_backward_char(StartIter);
        gtk_text_buffer_move_mark(TextBuffer, mark, StartIter);
      end;
    end;
  end;
end;

procedure Gtk2WS_MemoSelChanged (Textbuffer: PGtkTextBuffer;
   StartIter: PGtkTextIter; mark: PGtkTextMark; WidgetInfo: PWidgetInfo); cdecl;
begin
  if TControl(WidgetInfo^.LCLObject) is TWYSIWYMEditor then
  begin
    TWYSIWYMEditor(WidgetInfo^.LCLObject).DoSelectionChange;
  end;
end;

procedure Gtk2WS_Backspace(view: PGtkTextView; WidgetInfo: PWidgetInfo); cdecl;
var
  buf    : PGtkTextBuffer;
  mark   : PGtkTextMark;
  iend   : TGtkTextIter;
  istart : TGtkTextIter;
  tag    : PGtkTextTag;
begin
  // this handler checks, if the "numbering" should be erarsed
  buf:=gtk_text_view_get_buffer(view);
  if not Assigned(buf) then Exit;
  mark := gtk_text_buffer_get_mark(buf, 'insert');
  if not Assigned(mark) then Exit;
  tag := gtk_text_tag_table_lookup( gtk_text_buffer_get_tag_table(buf)
    , 'numeric');
  if not Assigned(tag) then Exit;

  // first, check if cursor is right "after" the "numbering characters"
  gtk_text_buffer_get_iter_at_mark(buf, @iend, mark);

  if gtk_text_iter_ends_tag(@iend, tag) then begin
    // cursor position is at the beginning of the line - erase all
    // characters that belong to the numbering.
    istart:=iend;
    gtk_text_iter_backward_to_tag_toggle(@istart, tag);
    gtk_text_buffer_delete(buf, @istart, @iend);
    // prevent default backspace
    g_signal_stop_emission_by_name(view, 'backspace');
  end;
end;

procedure Gtk2WS_RichMemoInsert(Textbuffer: PGtkTextBuffer;
   StartIter: PGtkTextIter; text: PChar; len: gint; WidgetInfo: PWidgetInfo); cdecl;
var
  rm : TWYSIWYMEditor;
  iter : PGtkTextIter;
  tag  : PGtkTextTag;
  w    : PGtkWidget;
  b    : PGtkTextBuffer;
  attr : PGtkTextAttributes;
begin
  if TControl(WidgetInfo^.LCLObject) is TWYSIWYMEditor then
  begin
    rm := TWYSIWYMEditor(WidgetInfo^.LCLObject);
    // re-zooming any newly entered (pasted, manually inserted text)
    { TODO:
    if (rm.ZoomFactor<>1) then begin
      TGtk2WSCustomRichMemo.GetWidgetBuffer(rm, w, b);
      iter:=gtk_text_iter_copy(StartIter);
      gtk_text_iter_backward_chars(iter, len);
      attr := gtk_text_view_get_default_attributes(PGtkTextView(w));
      gtk_text_iter_get_attributes(iter, attr);

      if attr^.font_scale<>rm.ZoomFactor then begin
        tag := gtk_text_buffer_create_tag(b, nil,
            'scale', [   gdouble(rm.ZoomFactor),
            'scale-set', gboolean(gTRUE),
            nil]);
        gtk_text_buffer_apply_tag(b, tag, iter, StartIter);
      end;
      gtk_text_attributes_unref(attr);
    end;}
  end;
end;

function Gtk2_RichMemoKeyPress(view: PGtkTextView; Event: PGdkEventKey;
  WidgetInfo: PWidgetInfo): gboolean; cdecl;
var
  buf    : PGtkTextBuffer;
  mark   : PGtkTextMark;
  iend   : TGtkTextIter;
  istart : TGtkTextIter;
  tag    : PGtkTextTag;
begin
  if Event^.keyval= GDK_KEY_Return then begin
    //writeln('return !');
    buf:=gtk_text_view_get_buffer(view);
    if not Assigned(buf) then Exit;
    mark := gtk_text_buffer_get_mark(buf, 'insert');
    if not Assigned(mark) then Exit;
    tag := gtk_text_tag_table_lookup( gtk_text_buffer_get_tag_table(buf)
      , 'numeric');
    if not Assigned(tag) then Exit;
    gtk_text_buffer_get_iter_at_mark(buf, @istart, mark);

    gtk_text_iter_set_line_offset(@istart, 0);
    if gtk_text_iter_begins_tag(@istart, tag) then begin
      //writeln('apply!');
      //writeln( 'ofs: ', gtk_text_iter_get_offset(@istart));
    end;
  end;
  Result:=false;
end;



{ TGtk2WSWYSIWYMEditor }

class procedure TGtk2WSWYSIWYMEditor.SetCallbacks(const AGtkWidget: PGtkWidget;
  const AWidgetInfo: PWidgetInfo);
var
  TextBuf: PGtkTextBuffer;
  view   : PGtkTextView;
begin
  // TODO: This was done in Gtk2RichMemo. Not sure yet what it does:
  // TGtk2WSCustomMemoInt.SetCallbacks(AGtkWidget, AWidgetInfo);

  view:=PGtkTextView(AWidgetInfo^.CoreWidget);
  TextBuf := gtk_text_view_get_buffer(view);
  SignalConnect(PGtkWidget(view), 'backspace', @Gtk2WS_Backspace, AWidgetInfo);
  SignalConnect(PGtkWidget(TextBuf), 'mark-set', @Gtk2WS_MemoSelChanged_Before, AWidgetInfo);
  SignalConnectAfter(PGtkWidget(TextBuf), 'mark-set', @Gtk2WS_MemoSelChanged, AWidgetInfo);
  SignalConnectAfter(PGtkWidget(TextBuf), 'insert-text', @Gtk2WS_RichMemoInsert, AWidgetInfo);
  SignalConnect(PGtkWidget(view), 'key-press-event',  @Gtk2_RichMemoKeyPress, AWidgetInfo);
end;

class procedure TGtk2WSWYSIWYMEditor.GetWidgetBuffer(
  const AWinControl: TWinControl; var TextWidget: PGtkWidget;
  var Buffer: PGtkTextBuffer);
var
  Widget     : PGtkWidget;
  list       : PGList;
begin
  TextWidget:=nil;
  Buffer:=nil;
  // todo: cache values?
  Widget := PGtkWidget(PtrUInt(AWinControl.Handle));

  list := gtk_container_get_children(PGtkContainer(Widget));
  if not Assigned(list) then Exit;

  TextWidget := PGtkWidget(list^.data);
  if not Assigned(TextWidget) then Exit;

  buffer := gtk_text_view_get_buffer (PGtkTextView(TextWidget));
end;

class function TGtk2WSWYSIWYMEditor.CreateHandle(
  const AWinControl: TWinControl; const AParams: TCreateParams): TLCLIntfHandle;
var
  Widget,
  TempWidget: PGtkWidget;
  WidgetInfo: PWidgetInfo;
  buffer: PGtkTextBuffer;
begin
  Widget := gtk_scrolled_window_new(nil, nil);
  Result := TLCLIntfHandle(PtrUInt(Widget));
  if Result = 0 then Exit;
  {$IFDEF DebugLCLComponents}
  DebugGtkWidgets.MarkCreated(Widget,dbgsName(AWinControl));
  {$ENDIF}

  WidgetInfo := CreateWidgetInfo(Pointer(Result), AWinControl, AParams);

  TempWidget := gtk_text_view_new();
  gtk_container_add(PGtkContainer(Widget), TempWidget);

  GTK_WIDGET_UNSET_FLAGS(PGtkScrolledWindow(Widget)^.hscrollbar, GTK_CAN_FOCUS);
  GTK_WIDGET_UNSET_FLAGS(PGtkScrolledWindow(Widget)^.vscrollbar, GTK_CAN_FOCUS);
  gtk_scrolled_window_set_policy(PGtkScrolledWindow(Widget),
                                     GTK_POLICY_AUTOMATIC,
                                     GTK_POLICY_AUTOMATIC);
  // add border for memo
  gtk_scrolled_window_set_shadow_type(PGtkScrolledWindow(Widget),
    BorderStyleShadowMap[TCustomControl(AWinControl).BorderStyle]);

  SetMainWidget(Widget, TempWidget);
  GetWidgetInfo(Widget, True)^.CoreWidget := TempWidget;

  gtk_text_view_set_editable(PGtkTextView(TempWidget), True);
  gtk_text_view_set_wrap_mode(PGtkTextView(TempWidget), GTK_WRAP_WORD);

  gtk_text_view_set_accepts_tab(PGtkTextView(TempWidget), True);

  gtk_widget_show_all(Widget);

  buffer := gtk_text_view_get_buffer (PGtkTextView(TempWidget));
  //tag:=gtk_text_tag_new(TagNameNumeric);
  gtk_text_buffer_create_tag (buffer, 'numeric',
      'editable',   [ gboolean(gFALSE),
      'editable-set', gboolean(gTRUE),
      nil]);

  Set_RC_Name(AWinControl, Widget);
  SetCallbacks(Widget, WidgetInfo);
end;

class procedure TGtk2WSWYSIWYMEditor.DestroyHandle(
  const AWinControl: TWinControl);
var
  w : PGtkWidget;
  b : PGtkTextBuffer;
  handlerid: gulong;
begin
  GetWidgetBuffer(AWinControl, w, b);

  // uninstall hanlder, to prevent crashes
  handlerid := g_signal_handler_find(b
    , G_SIGNAL_MATCH_FUNC or G_SIGNAL_MATCH_DATA
    , 0, 0, nil
    , @Gtk2WS_MemoSelChanged, GetWidgetInfo(w));
  g_signal_handler_disconnect (b, handlerid);

  inherited DestroyHandle(AWinControl);
end;

end.

