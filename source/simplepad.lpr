program simplepad;

{$mode objfpc}{$H+}

uses
  {$IFDEF UNIX}{$IFDEF UseCThreads}
  cthreads,
  {$ENDIF}{$ENDIF}
  Interfaces, // this includes the LCL widgetset
  Forms, richmemopackage, gui_main, gui_documentframe, gui_htmlframe, sys_types,
  gui_config, gui_gtktextwidgetframe, gtk_textwidget, widget_wysiwymeditor,
  gtk2_wysiwymeditor;

{$R *.res}

begin
  RequireDerivedFormResource := True;
  Application.Initialize;
  Application.CreateForm(TMainForm, MainForm);
  Application.Run;
end.

