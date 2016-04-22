unit wid_wysiwymeditor_styles;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, Graphics;

{ NOTE: I am not using the same things from Graphics, because 1) Most of these
things aren't actually using OS resources, except internally. 2) A lot of things
are simply not nullable.}

type
  TStyleKind = (skSpan, skParagraph, skContainer);
  TFontStyle = (fsInherited, fsBold, fsItalic, fsUnderline);
  TFontPosition = (fpInherited, fpSubscript, fpSuperscript);
  TJustification = (jInherited, jLeft, jCenter, jRight, jFull);
  TListNumberStyle = (lnsInherited, lnsBullet, lnsNumeric, lnsUpperAlpha, lnsLowerAlpha, lnsUpperRoman, lnsLowerRoman);

  TSpanStyle = record
    FontName: String;
    FontSize: Longint; // 0 means inherited
    FontStyle: TFontStyle;
    FontPosition: TFontPosition;
    FontColor: TColor; // clNone or clDefault means inherited
    BackgroundColor: TColor;
  end;

  TParagraphStyle = record
    FontName: String; // blank means inherited.
    FontSize: Longint; // 0 means inherited
    FontStyle: TFontStyle;
    FontPosition: TFontPosition;
    FontColor: TColor; // clNone or clDefault means inherited
    BackgroundColor: TColor;
    LineSpacing: Longint; // negative means inherited
    LeftIndent: Longint; // negative means inherited
    RightIndent: Longint; // negative means inherited
    FirstLineIndent: Longint; // negative means inherited
    SpaceAboveParagraph: Longint; // negative means inherited
    SpaceBelowParagraph: Longint; // negative means inherited
    Justification: TJustification;
  end;

  TContainerStyle = record
    FontName: String; // blank means inherited.
    FontSize: Longint; // 0 means inherited
    FontStyle: TFontStyle;
    FontPosition: TFontPosition;
    FontColor: TColor; // clNone or clDefault means inherited
    BackgroundColor: TColor;
    LineSpacing: Longint; // negative means inherited
    LeftIndent: Longint; // negative means inherited
    RightIndent: Longint; // negative means inherited
    FirstLineIndent: Longint; // negative means inherited
    SpaceAboveParagraph: Longint; // negative means inherited
    SpaceBelowParagraph: Longint; // negative means inherited
    Justification: TJustification;
    ListNumberStyle: TListNumberStyle;
    ListNumberSuffix: String; // blank means inherited.
  end;


implementation

end.

