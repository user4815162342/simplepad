program simplepad;

{$mode objfpc}{$H+}

uses
  {$IFDEF UNIX}{$IFDEF UseCThreads}
  cthreads,
  {$ENDIF}{$ENDIF}
  Interfaces, // this includes the LCL widgetset
  Forms, richmemopackage, gui_main, gui_documentframe, gui_htmlframe, sys_types,
  gui_config, gui_gtktextwidgetframe, gtk_textwidget, wid_wysiwymeditor,
  wid_gtk2_wysiwymeditor, wid_ws_wysiwymeditor, wid_wysiwymeditor_factory;

{$R *.res}

begin
  RequireDerivedFormResource := True;
  Application.Initialize;
  Application.CreateForm(TMainForm, MainForm);
  Application.Run;
end.

