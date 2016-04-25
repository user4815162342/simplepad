unit wid_wysiwymeditor_styles;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, Graphics;

{ NOTE: I am not using the same things from Graphics, because 1) Most of these
things aren't actually using OS resources, except internally. 2) A lot of things
are simply not nullable.}

{
Inheritance:
- All content inherits the body/default style.
- All content inherits the styles provided nodes which contain them.
- Nested list items and block quotes inherit from the default list and blockquote style
- Levelled headings inherit from the default heading style.

These last two are probably managed by the widgetset code, by modifying the styles of
all known list, blockquote and heading styles.
}

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
    // These only apply to list item styles, inheritance comes from
    // lists with a higher nesting level.
    ListNumberStyle: TListNumberStyle;
    ListNumberSuffix: String; // blank means inherited.
  end;

  TBodyStyle = record // similar to TParagraph style, except doesn't have list items.
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


implementation

end.

