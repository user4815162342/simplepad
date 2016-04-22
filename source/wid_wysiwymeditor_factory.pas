unit wid_wysiwymeditor_factory;

{$mode objfpc}{$H+}

interface

// Kind of loosely based off of RichMemoFactory, except I don't think I need
// the 'external' definition of the register proc, since I'm using defines anyway.
// I think it's done just to get around circular unit references, but I'm sure there's
// a better way if that's the case.
// Please, if I'm wrong, explain why.

{$define NoWYSIWYM}
// TODO: As I create WidgetSets to report this...
//{$ifdef LCLWin32}{$undef NoWYSIWYM}{$endif}
//{$ifdef LCLCarbon}{$undef NoWYSIWYM}{$endif}
{$ifdef LCLGtk2}{$undef NoWYSIWYM}{$endif}
//{$ifdef LCLCocoa}{$undef NoWYSIWYM}{$endif}
//{$ifdef LCLQt}{$undef NoWYSIWYM}{$endif}

uses
  WSLCLClasses,
  wid_wysiwymeditor
  {$ifdef LCLWin32},wid_win32_wysiwymeditor{$endif}
  {$ifdef LCLCarbon},wid_carbon_wysiwymeditor{$endif}
  {$ifdef LCLGtk2},wid_gtk2_wysiwymeditor{$endif}
  {$ifdef LCLCocoa},wid_cocoa_wysiwymeditor{$endif}
  {$ifdef LCLQt},wid_cocoa_wysiwymeditor{$endif}
  {$ifdef NoWYSIWYM},wid_ws_wysiwymeditor{$endif}
  ;

function RegisterWYSIWYMEditor: Boolean;
function RegisterWYSIWYMStyleManager: Boolean;

implementation

function RegisterWYSIWYMEditor: Boolean;
begin
  Result := True;
  {$ifdef LCLWin32}RegisterWSComponent(TWYSIWYMEditor, TWin32WSWYSIWYMEditor);{$endif}
  {$ifdef LCLCarbon}RegisterWSComponent(TWYSIWYMEditor, TCarbon2WSWYSIWYMEditor);{$endif}
  {$ifdef LCLGtk2}RegisterWSComponent(TWYSIWYMEditor, TGtk2WSWYSIWYMEditor);{$endif}
  {$ifdef LCLCocoa}RegisterWSComponent(TWYSIWYMEditor, TCocoa2WSWYSIWYMEditor);{$endif}
  {$ifdef LCLQt}RegisterWSComponent(TWYSIWYMEditor, TQtWSWYSIWYMEditor);{$endif}
  {$ifdef NoWYSIWYM}
     {$WARNING TWYSIWYMEditor is not usable in this widget set}
     RegisterWSComponent(TWYSIWYMEditor, TWSWYSIWYMEditor);
  {$endif}
end;

function RegisterWYSIWYMStyleManager: Boolean;
begin
  Result := True;
  {$ifdef LCLWin32}RegisterWSComponent(TWYSIWYMEditor, TWin32WSWYSIWYMEditor);{$endif}
  {$ifdef LCLCarbon}RegisterWSComponent(TWYSIWYMEditor, TCarbon2WSWYSIWYMEditor);{$endif}
  {$ifdef LCLGtk2}RegisterWSComponent(TWYSIWYMStyleManager, TGtk2WSWYSIWYMStyleManager);{$endif}
  {$ifdef LCLCocoa}RegisterWSComponent(TWYSIWYMEditor, TCocoa2WSWYSIWYMEditor);{$endif}
  {$ifdef LCLQt}RegisterWSComponent(TWYSIWYMEditor, TQtWSWYSIWYMEditor);{$endif}
  {$ifdef NoWYSIWYM}
     RegisterWSComponent(TWYSIWYMStyleManager, TWSWYSIWYMStyleManager);
  {$endif}
end;



end.

