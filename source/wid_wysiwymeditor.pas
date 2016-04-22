unit wid_wysiwymeditor;

{$mode objfpc}{$H+}
{$modeswitch advancedrecords}

interface

uses
  Classes, SysUtils, Controls, LCLClasses, wid_wysiwymeditor_styles;

{
TODO: Next things next: I need to start hooking things up. But, in order
to do that, I want to first make sure the basics work. So, try to add this
to a form in Simplepad, and see if we can type around in it.

TODO: Then, while we're at it, finally determine whether it's absolutely necessary
to have the control be contained inside a scrolling window. If it's not, make sure
we can add it to a scrolling window. That will make some of the stuff in here
much easier to do.

TODO: Once we're done with that, we need to start working with tags. This means
both editing them and styling them. Make sure they all work correctly. Although,
we can save the list item bullets for later, since those are going to require
special tags to be inserted.

TODO: Make sure we have at least one event that occurs when the contents have
changed.

TODO: Then, serializing and deserializing. Just do a dumb binary format which
makes use of WriteAnsiString and WriteByte.

TODO: Then, undo/redo

TODO: Then, clipboard stuff.

TODO: From there, I think we'll leave a bunch of the other stuff (querying,
for example) for later, as I need it done. Although, the infrastructure for
saving may actually handle the querying. Selection manipulation, however,
beyond the find/replace, can wait.

TODO: I don't want a full-fledged editor, I just want a
WYSIWYM editor. More specifically, I need a WYSIWYM editor that supports
some rather specific structure tags. For that, I need the following:
- A shared 'TagTable' which is class global for all instances of the editor.
- A way of specifying the styles for these tags. I only need to specify
certain style properties, I don't need everything.
- Sharing a buffer is cool, and easy to do, but not necessary.
- A number of methods which are used for manipulating and retrieving the
data without knowing anything about tagtables and the like: A method called
SetBulletStyle sets the current paragraph to an unordered list item. A method
called SetBold sets the currently selected item to bold (or turns on bold for
further typing). And so on...
- The ability to save to a number of formats using serializers that know how
to handle the tags as they are iterated through.

Basically creates a WYSIWYM editor, which manipulates text based on structure,
not appearance. The styles for the structure can be manipulated, but only globally.
Right now, it extends TRichMemo because it contains a little bit of infrastructure
that I can use. However, I eventually want it to be a separate component, whether
it's even a descendant of TCustomMemo or TWinControl, I'm not sure.

units with useful information in richmemopackage:
- RichMemo
- Gtk2RichMemo


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
TODO: My policy on development: I'm only going to add features as they become
necessary. If other developers want features not here, they can request them
and give me a good use case, or add them themselves.
}

type

  TWYSIWYMHeadingLevel = (hl1, hl2, hl3, hl4, hl5, hl6);

  { TWYSIWYMStyleManager }

  TWYSIWYMStyleManager = class(TLCLReferenceComponent)
  private
    function GetBlockQuoteStyle: TContainerStyle;
    function GetBodyStyle: TContainerStyle;
    function GetCodeStyle: TSpanStyle;
    function GetContainerStyles(const aName: String): TContainerStyle;
    function GetEmphasisStyle: TSpanStyle;
    function GetHeadingStyle(const aLevel: TWYSIWYMHeadingLevel): TParagraphStyle;
    function GetHeadingStyle: TParagraphStyle;
    function GetLinkStyle: TSpanStyle;
    function GetNestedOrderedListStyles(const aLevel: Longint): TContainerStyle;
    function GetNestedUnorderedListStyles(const aLevel: Longint
      ): TContainerStyle;
    function GetOrderedListItemStyle: TContainerStyle;
    function GetParagraphStyles(const aName: String): TParagraphStyle;
    function GetSpanStyles(const aName: String): TSpanStyle;
    function GetStrongStyle: TSpanStyle;
    function GetStyleCount: Longint;
    function GetStyleKind(const aIndex: Longint): TStyleKind;
    function GetStyleKind(const aName: String): TStyleKind;
    function GetStyleName(const aIndex: Longint): String;
    function GetSubscriptStyle: TSpanStyle;
    function GetSuperscriptStyle: TSpanStyle;
    function GetUnorderedListItemStyle: TContainerStyle;
    function GetVerseStyle: TParagraphStyle;
    procedure SetBlockQuoteStyle(AValue: TContainerStyle);
    procedure SetBodyStyle(AValue: TContainerStyle);
    procedure SetCodeStyle(AValue: TSpanStyle);
    procedure SetContainerStyles(const aName: String; AValue: TContainerStyle);
    procedure SetEmphasisStyle(AValue: TSpanStyle);
    procedure SetHeadingStyle(const aLevel: TWYSIWYMHeadingLevel; AValue: TParagraphStyle);
    procedure SetHeadingStyle(AValue: TParagraphStyle);
    procedure SetLinkStyle(AValue: TSpanStyle);
    procedure SetNestedOrderedListStyles(const aLevel: Longint;
      AValue: TContainerStyle);
    procedure SetNestedUnorderedListStyles(const aLevel: Longint;
      AValue: TContainerStyle);
    procedure SetOrderedListItemStyle(AValue: TContainerStyle);
    procedure SetParagraphStyles(const aName: String; AValue: TParagraphStyle);
    procedure SetSpanStyles(const aName: String; AValue: TSpanStyle);
    procedure SetStrongStyle(AValue: TSpanStyle);
    procedure SetSubscriptStyle(AValue: TSpanStyle);
    procedure SetSuperscriptStyle(AValue: TSpanStyle);
    procedure SetUnorderedListItemStyle(AValue: TContainerStyle);
    procedure SetVerseStyle(AValue: TParagraphStyle);
  protected
    class procedure WSRegisterClass; override;
  public
    // all styles are stored as strings internally, I hope.
    // the '$' is used to specify the built-in classes.
    const BlockQuoteStyleName = '$block-quote';
    const CodeStyleName = '$code';
    const EmphasisStyleName = '$emphasis';
    const HeadingStyleName = '$heading';
    const LinkStyleName = '$link';
    const OrderedListItemStyleName = '$ordered-list-item';
    const UnorderedListItemStyleName = '$unordered-list-item';
    const StrongStyleName = '$strong';
    const SubscriptStyleName = '$subscript';
    const SuperscriptStyleName = '$superscript';
    const VerseStyleName = '$verse';
    const BodyStyleName = '$body';


    // style applied to all content, unless overridden by contained elements.
    property BodyStyle: TContainerStyle read GetBodyStyle write SetBodyStyle;

    property EmphasisStyle: TSpanStyle read GetEmphasisStyle write SetEmphasisStyle;
    property StrongStyle: TSpanStyle read GetStrongStyle write SetStrongStyle;
    property CodeStyle: TSpanStyle read GetCodeStyle write SetCodeStyle;
    property SubscriptStyle: TSpanStyle read GetSubscriptStyle write SetSubscriptStyle;
    property SuperscriptStyle: TSpanStyle read GetSuperscriptStyle write SetSuperscriptStyle;
    property LinkStyle: TSpanStyle read GetLinkStyle write SetLinkStyle;
    // specify styles for custom span classes.
    property SpanStyles[const aName: String]: TSpanStyle read GetSpanStyles write SetSpanStyles;

    // paragraph styles are applied to all contained text, unless overridden by
    // a contained span.
    // default heading style applied to all heading styles, unless overridden by the
    // specific heading.
    property DefaultHeadingStyle: TParagraphStyle read GetHeadingStyle write SetHeadingStyle;
    property HeadingStyle[const aLevel: TWYSIWYMHeadingLevel]: TParagraphStyle read GetHeadingStyle write SetHeadingStyle;
    property VerseStyle: TParagraphStyle read GetVerseStyle write SetVerseStyle;
    // specify styles for custom paragraph classes.
    property ParagraphStyles[const aName: String]: TParagraphStyle read GetParagraphStyles write SetParagraphStyles;

    // container styles are applied to all contained paragraphs, unless overridden
    // by a contained container or paragraph.
    property BlockQuoteStyle: TContainerStyle read GetBlockQuoteStyle write SetBlockQuoteStyle;
    property OrderedListItemStyle: TContainerStyle read GetOrderedListItemStyle write SetOrderedListItemStyle;
    property UnorderedListItemStyle: TContainerStyle read GetUnorderedListItemStyle write SetUnorderedListItemStyle;
    property ContainerStyles[const aName: String]: TContainerStyle read GetContainerStyles write SetContainerStyles;

    // the nested styles allow overriding the list styles for list items inside of
    // other lists.
    property NestedOrderedListStyles[const aLevel: Longint]: TContainerStyle read GetNestedOrderedListStyles write SetNestedOrderedListStyles;
    property NestedUnorderedListStyles[const aLevel: Longint]: TContainerStyle read GetNestedUnorderedListStyles write SetNestedUnorderedListStyles;

    // these allow manipulation of the contained styles.
    property StyleCount: Longint read GetStyleCount;
    property StyleName[const aIndex: Longint]: String read GetStyleName;
    property StyleKind[const aIndex: Longint]: TStyleKind read GetStyleKind;
    property StyleKindByName[const aName: String]: TStyleKind read GetStyleKind;
    procedure DeleteStyle(const aName: String);
  end;

  TWYSIWYMReceiver = class;

  TWYSIWYMProviderNodeKind = (pnkContainerStart, pnkParagraphStart, pnkSpanStart, pnkText, pnkSpanEnd, pnkParagraphEnd, pnkContainerEnd);
  TWYSIWYMNodeClass = (pncText, pncEmphasis, pncStrong, pncCode, pncSubscript,
                               pncSuperscript, pncCustomSpan, pncLink, pncLinebreak,
                               pncNormalParagraph, pncHeading, pncVerse, pncHorizontalRule,
                               pncCustomParagraph, pncBlockQuote, pncOrderedListItem,
                               pncUnorderedListItem, pncCustomContainer);

  { TWYSIWYMProvider }

  TWYSIWYMProvider = class
  public
    function NodeKind: TWYSIWYMProviderNodeKind; virtual; abstract;
    function NodeClass: TWYSIWYMNodeClass; virtual; abstract;
    function NodeName: String; virtual; abstract;
    function NodeLinkReference: String; virtual; abstract;
    function NodeHeadingLevel: TWYSIWYMHeadingLevel; virtual; abstract;
    function NodeTextContent: String; virtual; abstract;
    function ReadNext: Boolean; virtual; abstract;
    procedure Pipe(aReceiver: TWYSIWYMReceiver);

  end;

  TWYSIWYMProviderClass = class of TWYSIWYMProvider;

  TWYSIWYMDeserializer = class(TWYSIWYMProvider)
  public
    constructor Create(aStream: TStream); virtual; abstract;
  end;

  TWYSIWYMDeserializerClass = class of TWYSIWYMDeserializer;

  TWYSIWYMReceiver = class
  public
    procedure TextFound(const aContent: String); virtual; abstract;
    procedure EmphasisStarted; virtual; abstract;
    procedure EmphasisFinished; virtual; abstract;
    procedure StrongStarted; virtual; abstract;
    procedure StrongFinished; virtual; abstract;
    procedure CodeStarted; virtual; abstract;
    procedure CodeFinished; virtual; abstract;
    procedure SubscriptStarted; virtual; abstract;
    procedure SubscriptFinished; virtual; abstract;
    procedure SuperscriptStarted; virtual; abstract;
    procedure SuperscriptFinished; virtual; abstract;
    procedure CustomSpanStarted(const aName: String); virtual; abstract;
    procedure CustomSpanFinished(const aName: String); virtual; abstract;
    procedure LinkStarted(const aReference: String); virtual; abstract;
    procedure LinkFinished; virtual; abstract;
    procedure LineBreakFound; virtual; abstract;
    procedure NormalParagraphStarted; virtual; abstract;
    procedure NormalParagraphFinished; virtual; abstract;
    procedure HeadingStarted(aLevel: TWYSIWYMHeadingLevel); virtual; abstract;
    procedure HeadingFinished(aLevel: TWYSIWYMHeadingLevel); virtual; abstract;
    procedure VerseStarted; virtual; abstract;
    procedure VerseFinished; virtual; abstract;
    procedure HorizontalRuleFound; virtual; abstract;
    procedure CustomParagraphStarted(const aClass: String); virtual; abstract;
    procedure CustomParagraphFinished(const aClass: String); virtual; abstract;
    procedure BlockQuoteStarted; virtual; abstract;
    procedure BlockQuoteFinished; virtual; abstract;
    procedure OrderedListItemStarted; virtual; abstract;
    procedure OrderedListItemFinished; virtual; abstract;
    procedure UnorderedListItemStarted; virtual; abstract;
    procedure UnorderedListItemFinished; virtual; abstract;
    procedure CustomContainerStarted(const aClass: STring); virtual; abstract;
    procedure CustomContainerFinished(const aClass: String); virtual; abstract;
  end;

  TWYSIWYMProcessorClass = class of TWYSIWYMReceiver;

  TWYSIWYMSerializer = class(TWYSIWYMReceiver)
  public
    constructor Create(aStream: TStream); virtual; abstract;

  end;

  TWYSIWYMSerializerClass = class of TWYSIWYMSerializer;

  TSearchDirection = (sdSelectionToEnd, sdStartToSelection, sdSelectionToBeginning, sdEndToSelection);
  TWYSIWYMNodeKind = (dnkContainer, dnkParagraph, dnkSpan, dnkText);
  TWYSIWYMNode = type Longint; // TODO: Not sure what to make this...

  { TWYSIWYMEditor }

  {WYSIWYMEditor is a control for editing structured text content. Although it
  can be used like a rich text editor, and may have that in the background
  depending on your widgetset, it does not behave exactly the same.

  Instead of telling the editor what style parts of the text should be displayed
  in, you tell the editor about the structure of the text, and the editor styles
  it based on that structure. In order to do this, you provide the editor a
  TWYSIWYMStyleManager, which you can use to control the styles.

  TWYSIWYMEditor does not descend from TCustomMemo, or anything like it, because
  it's contents are not easily accessible as straight text, and it's selection
  is not available by character position. Or rather, depending on the widgetset
  being used, it may not be easy to create an abstraction that works with those.
  Both of these concepts contain ambiguity when dealing with structured text.
  At most, I may support events which indicate whether the selection has changed.

  In order to retrieve or pass text to a TWYSIWYMEditor, you need to pass it
  a TWYSIWYMSerializer class, in order to write to a stream or a string. It
  is also possible to process the content yourself using a TWYSIWYMReader or
  TWYSIWYMWriter. Some standard serializers should be made available in a
  helper unit.

  It should also possible to 'query' the TWYSIWYMEditor to get data out of it
  according to the structure. As well as make changes based on this query, but
  I haven't figured out exactly how to do that, yet.

  The structure of a document in WYSIWYMEditor has four kinds: containers,
  paragraphs, spans and text. Text represents actual text content. A span
  is a wrapper around inline text and other spans, which indicates a
  structure that won't effect the layout. A paragraph is a single block
  of text and spans, with spacing around it, separating it from other paragraphs
  and forcing it to flow down the page instead of across. A container is a
  wrapper around a group of paragraphs which cause them to behave in a similar
  manner. At some point in the future I may add an inset structure type, for
  embedding images, figures and other content.

  The actual defined structural types are below. Their names are given, but the
  meaning isn't always provided. In general, it is actually up to the developer
  to determine the actual semantics.

  A span can contain other spans or text. To manipulate a span, you either "Enable",
  "Disable", or "Toggle" it. Enabling a span causes the current selection to
  become part of that span type, or if nothing is selected to cause further typing
  to be part of that span. Disabling removes that span from all text contained
  in the selection, and causes further typing to move beyond that span. Toggling
  it causes Enabling if the span is currently disabled, or disabling if it is
  currently enabled. (If the content of the selection is mixed, it will be enabled
  first). (This is in general, there are a few cases, such as links, where this is
  done slightly differently).

  A paragraph can contain spans or text. Every bit of text is contained inside
  one, and only one, paragraph. You can change the semantics of a paragraph structure
  by using a "SetParagraph*" function to indicate the type. (This is in general,
  there are a few cases, such as horizontal-rules, where this is done slightly
  differently).

  A container can only contain other containers and a paragraph. There are a few
  ways to manipulate containers: You can wrap the current paragraph in a new container,
  you can move the current paragraph into the container just before or after it in the
  flow, and you can move a paragraph out of a container (and into the container's
  parent, if there is one). Empty containers should get cleared away, so the only
  way to delete a container is to remove all of its contents. The body of a document
  is basically a container, but nothing can be moved out of it.

  spans:
  - emphasis
  - strong
  - code
  - subscript
  - superscript
  - custom (contains a 'class' attribute in invisible text or something)
  - link: text which represents a link to another document (specified in some
  invisible text).
  - line-break: represents a break between lines that doesn't cause a new paragraph.

  paragraphs:
  - normal
  - heading1
  - heading2
  - heading3
  - heading4
  - heading5
  - heading6
  - verse
  - horizontal-rule
  - custom

  container:
  - block-quote
  - ordered-list-item
  - unordered-list-item
  - custom
  }

  TWYSIWYMEditor = class(TWinControl)
  private
    fStyleManager: TWYSIWYMStyleManager;
    procedure SetStyleManager(AValue: TWYSIWYMStyleManager);
  protected
    class procedure WSRegisterClass; override;
  public
    // This is here as an example of a signal handler in the gtk2. I'm
    // not doing anything with it at the moment, as I don't completely
    // understand how all of those things work yet.
    procedure DoSelectionChange;

    // selection manipulation
    procedure FindAndSelect(const aText: String; aDirection: TSearchDirection);
    // expand and collapse the selection by a specified number of characters.
    // should behave as if the user is moving the arrow key on that part of
    // the selection.
    procedure ExpandSelectionAtEnd(aCount: Longint);
    procedure ExpandSelectionAtStart(aCount: Longint);
    procedure CollapseSelectionAtEnd(aCount: Longint);
    procedure CollapseSelectionAtStart(aCount: Longint);
    procedure MoveSelectionForward(aCount: Longint);
    procedure MoveSelectionBackward(aCount: Longint);
    // collapses the selection down to a single line
    procedure CollapseSelection;
    // additional selection manipulation can be done using 'nodes', see below.

    // text manipulation: this acts on the current selection only.
    procedure EnterText(const aText: String);
    procedure DeleteText; // deletes current selection
    function SelectedText: String;

    // manipulate spans
    procedure EnableEmphasis;
    procedure DisableEmphasis;
    procedure ToggleEmphasis;
    procedure EnableStrong;
    procedure DisableStrong;
    procedure ToggleStrong;
    procedure EnableCode;
    procedure DisableCode;
    procedure ToggleCode;
    procedure EnableSubscript;
    procedure DisableSubscript;
    procedure ToggleSubscript;
    procedure EnableSuperscript;
    procedure DisableSuperscript;
    procedure ToggleSuperscript;
    procedure EnableCustomSpan(const aClass: String);
    procedure DisableCustomSpan(const aClass: String);
    procedure ToggleCustomSpan(const aClass: String);
    procedure EnableLink(const aReference: String);
    procedure DisableLink;
    procedure InsertLineBreak;

    // paragraph manipulation
    procedure SetParagraphNormal;
    procedure SetParagraphHeading(aLevel: TWYSIWYMHeadingLevel);
    procedure SetParagraphVerse;
    procedure SetParagraphCustom(const aClass: String);
    procedure InsertHorizontalRule; // inserts after current paragraph.
    procedure StartNewParagraph; // starts a new paragraph at the current selection,
                                 // the new paragraph is a normal paragraph, and
                                 // remains inside the same container.

    // container manipulation
    procedure WrapParagraphInBlockQuote;
    procedure WrapParagraphInUnorderedListItem;
    procedure WrapParagraphInOrderedListItem;
    procedure WrapParagraphInVerse;
    procedure WrapParagraphInCustom(const aClass: String);
    procedure MoveParagraphIntoPreviousContainer;
    procedure MoveParagraphIntoNextContainer;
    procedure MoveParagraphOutOfContainer; // NOTE: If it's a paragraph in the middle,
                                            // this splits the container into two of
                                            // the same type.

    // querying... you can also use the Node struct below to make things a little
    // simpler...
    function GetBodyNode: TWYSIWYMNode;
    // navigating through the document (forward only). The value will be 0 if
    // there is no node there.
    function GetNodeFirstChild(aNode: TWYSIWYMNode): TWYSIWYMNode;
    function GetNodeNextSibling(aNode: TWYSIWYMNode): TWYSIWYMNode;
    function GetNodeParent(aNode: TWYSIWYMNode): TWYSIWYMNode;
    // node properties...
    // The kind determines if it is a container, paragraph, span or text.
    function GetNodeKind(aNode: TWYSIWYMNode): TWYSIWYMNodeKind;
    // the class determines what built-in class it is.
    function GetNodeClass(aNode: TWYSIWYMNode): TWYSIWYMNodeClass;
    // If an attempt is made to set a class to a class that's not of the same
    // kind, then an error will be raised.
    procedure SetNodeClass(aNode: TWYSIWYMNode; aValue: TWYSIWYMNodeClass);
    // returns the name of a custom class.
    function GetNodeName(aNode: TWYSIWYMNode): String; // returns the 'tag name', or 'class' if a custom...
    procedure SetNodeName(aNode: TWYSIWYMNode; const aValue: String); // yes, we can change this...
    // returns the reference for a link. If the node is not a link, an error is raised.
    function GetLinkNodeReference(aNode: TWYSIWYMNode): String;
    procedure SetLinkNodeReference(aNode: TWYSIWYMNode; const aValue: String);
    // returns the text of a node, if the node is not text, an error is raised.
    function GetTextNodeContent(aNode: TWYSIWYMNode): String; // only works with text.
    procedure SetTextNodeContent(aNode: TWYSIWYMNode; const aValue: String);
    // returns the level of a heading, if the node is not a heading, an error is raised.
    function GetHeadingNodeLevel(aNode: TWYSIWYMNode): TWYSIWYMHeadingLevel;
    procedure SetHeadingNodeLevel(aNode: TWYSIWYMNode; aValue: TWYSIWYMHeadingLevel);
    // moving things around:
    // if the parent is null, moves node to the body. if the sibling is null,
    // moves the node to be the last child.
    // If the node can't be placed in the specified spot, then an error will be raised.
    // If the node is a text node, and is inserted directly before or after another
    // text node, it will be collapsed into the other.
    procedure InsertNodeBefore(aNode: TWYSIWYMNode; aNewParent: TWYSIWYMNode; aNewSibling: TWYSIWYMNode);
    // in certain cases, the deletion of a node will cause other nodes to be deleted
    // (ex: child nodes of the node, or parent nodes that can't be empty). Keep
    // that in mind.
    procedure DeleteNode(aNode: TWYSIWYMNode);

    // and bring it back to selection
    // this should select the entire contents of the node, inclusive indicates
    // whether the tags for the node are included in the selection, if that's
    // possible.
    procedure SelectNode(aNode: TWYSIWYMNode; aInclusive: Boolean);
    // this creates a collapsed selection just before the beginning of this node.
    procedure SelectBeforeNode(aNode: TWYSIWYMNode);
    procedure SelectAfterNode(aNode: TWYSIWYMNode);
    // this creates a collapsed selection just inside the beginning of the node.
    // for text nodes, this is the same as selectbeforenode.
    procedure SelectNodeStart(aNode: TWYSIWYMNode);
    procedure SelectNodeEnd(aNode: TWYSIWYMNode);

    // undo/redo
    procedure Undo;
    procedure Redo;

    // clipboard
    procedure PasteFromClipboard;
    procedure CutToClipboard;
    procedure CopyToClipboard;






    // serialization and other content processing
    function Serialize(aSerializerClass: TWYSIWYMSerializerClass): String;
    procedure Deserialize(aDeserializerClass: TWYSIWYMDeserializerClass; const aText: String);
    procedure Serialize(aSerializerClass: TWYSIWYMSerializerClass; aStream: TStream);
    procedure Deserialize(aDeserializerClass: TWYSIWYMDeserializerClass; aStream: TStream);
    procedure WriteContentsTo(aReceiver: TWYSIWYMReceiver);
    // NOTE: This *will* overwrite the contents completely...
    procedure LoadContentsFrom(aProvider: TWYSIWYMProvider);

  published

    property StyleManager: TWYSIWYMStyleManager read fStyleManager write SetStyleManager;



  end;

  { TWYSIWYMDOM }

  TWYSIWYMDOM = record
  private
    fEditor: TWYSIWYMEditor;
    fNode: TWYSIWYMNode;
    function GetClass: TWYSIWYMNodeClass;
    function GetHeadingLevel: TWYSIWYMHeadingLevel;
    function GetTextContent: String;
    function GetIsNull: Boolean;
    function GetKind: TWYSIWYMNodeKind;
    function GetLinkReference: String;
    function GetName: String;
    procedure SetClass(AValue: TWYSIWYMNodeClass);
    procedure SetHeadingLevel(AValue: TWYSIWYMHeadingLevel);
    procedure SetName(AValue: String);
    procedure SetLinkReference(AValue: String);
    procedure SetTextContent(AValue: String);
  public
    class function New(aEditor: TWYSIWYMEditor; aNode: TWYSIWYMNode): TWYSIWYMDOM; static;
    class function Body(aEditor: TWYSIWYMEditor): TWYSIWYMDOM; static;
    property IsNull: Boolean read GetIsNull;
    property Kind: TWYSIWYMNodeKind read GetKind;
    property Name: String read GetName write SetName;
    property &Class: TWYSIWYMNodeClass read GetClass write SetClass;
    function FirstChild: TWYSIWYMDOM;
    function NextSibling: TWYSIWYMDOM;
    function Parent: TWYSIWYMDOM;
    property LinkReference: String read GetLinkReference write SetLinkReference;
    property TextContent: String read GetTextContent write SetTextContent;
    property HeadingLevel: TWYSIWYMHeadingLevel read GetHeadingLevel write SetHeadingLevel;
    procedure Select(aInclusive: Boolean = false);
    procedure SelectBefore;
    procedure SelectAfter;
    procedure SelectStart;
    procedure SelectEnd;
    procedure AddChild(aChild: TWYSIWYMDOM);
    procedure AddChildAfter(aChild: TWYSIWYMDOM; aSibling: TWYSIWYMDOM);
    procedure AddChildBefore(aChild: TWYSIWYMDOM; aSibling: TWYSIWYMDOM);
    procedure AddChildFirst(aChild: TWYSIWYMDOM);
    procedure Delete;
  end;

implementation

uses
  wid_wysiwymeditor_factory;

{ TWYSIWYMProvider }

procedure TWYSIWYMProvider.Pipe(aReceiver: TWYSIWYMReceiver);
begin
  while ReadNext do
  begin
    case NodeKind of
      pnkContainerStart,pnkParagraphStart,pnkSpanStart:
      case NodeClass of
        pncEmphasis:
          aReceiver.EmphasisStarted;
        pncStrong:
          aReceiver.StrongStarted;
        pncCode:
          aReceiver.CodeStarted;
        pncSubscript:
          aReceiver.SubscriptStarted;
        pncSuperscript:
          aReceiver.SuperscriptStarted;
        pncCustomSpan:
          aReceiver.CustomSpanStarted(NodeName);
        pncLink:
          aReceiver.LinkStarted(NodeLinkReference);
        pncLinebreak:
          aReceiver.LineBreakFound;
        pncNormalParagraph:
          aReceiver.NormalParagraphStarted;
        pncHeading:
          aReceiver.HeadingStarted(NodeHeadingLevel);
        pncVerse:
          aReceiver.VerseStarted;
        pncHorizontalRule:
          aReceiver.HorizontalRuleFound;
        pncCustomParagraph:
          aReceiver.CustomParagraphStarted(NodeName);
        pncBlockQuote:
          aReceiver.BlockQuoteStarted;
        pncOrderedListItem:
          aReceiver.OrderedListItemStarted;
        pncUnorderedListItem:
          aReceiver.UnorderedListItemStarted;
        pncCustomContainer:
          aReceiver.CustomContainerStarted(NodeName);
      end;
      pnkText:
        aReceiver.TextFound(NodeTextContent);
      pnkSpanEnd,pnkParagraphEnd,pnkContainerEnd:
      case NodeClass of
        pncEmphasis:
          aReceiver.EmphasisFinished;
        pncStrong:
          aReceiver.StrongFinished;
        pncCode:
          aReceiver.CodeFinished;
        pncSubscript:
          aReceiver.SubscriptFinished;
        pncSuperscript:
          aReceiver.SuperscriptFinished;
        pncCustomSpan:
          aReceiver.CustomSpanFinished(NodeName);
        pncLink:
          aReceiver.LinkFinished;
        pncNormalParagraph:
          aReceiver.NormalParagraphFinished;
        pncHeading:
          aReceiver.HeadingFinished(NodeHeadingLevel);
        pncVerse:
          aReceiver.VerseFinished;
        pncCustomParagraph:
          aReceiver.CustomParagraphFinished(NodeName);
        pncBlockQuote:
          aReceiver.BlockQuoteFinished;
        pncOrderedListItem:
          aReceiver.OrderedListItemFinished;
        pncUnorderedListItem:
          aReceiver.UnorderedListItemFinished;
        pncCustomContainer:
          aReceiver.CustomContainerFinished(NodeName);
      end;
    end;
  end;
end;

{ TWYSIWYMDOM }

function TWYSIWYMDOM.GetTextContent: String;
begin
  result := fEditor.GetTextNodeContent(fNode);
end;

function TWYSIWYMDOM.GetClass: TWYSIWYMNodeClass;
begin
  result := fEditor.GetNodeClass(fNode);
end;

function TWYSIWYMDOM.GetHeadingLevel: TWYSIWYMHeadingLevel;
begin
  result := fEditor.GetHeadingNodeLevel(fNode);
end;

function TWYSIWYMDOM.GetIsNull: Boolean;
begin
  result := (fNode = 0);
end;

function TWYSIWYMDOM.GetKind: TWYSIWYMNodeKind;
begin
  result := fEditor.GetNodeKind(fNode);
end;

function TWYSIWYMDOM.GetName: String;
begin
  result := fEditor.GetNodeName(fNode);
end;

procedure TWYSIWYMDOM.SetClass(AValue: TWYSIWYMNodeClass);
begin
  fEditor.SetNodeClass(fNode,AValue);
end;

procedure TWYSIWYMDOM.SetHeadingLevel(AValue: TWYSIWYMHeadingLevel);
begin
  fEditor.SetHeadingNodeLevel(fNode,AValue);
end;

function TWYSIWYMDOM.GetLinkReference: String;
begin
  result := fEditor.GetLinkNodeReference(fNode);
end;

procedure TWYSIWYMDOM.SetTextContent(AValue: String);
begin
  fEditor.SetTextNodeContent(fNode,AValue);
end;

procedure TWYSIWYMDOM.SetName(AValue: String);
begin
  fEditor.SetNodeName(fNode,AValue);

end;

procedure TWYSIWYMDOM.SetLinkReference(AValue: String);
begin
  fEditor.SetLinkNodeReference(fNode,AValue);
end;

class function TWYSIWYMDOM.New(aEditor: TWYSIWYMEditor; aNode: TWYSIWYMNode
  ): TWYSIWYMDOM;
begin
  result.fEditor := aEditor;
  result.fNode := aNode;
end;

class function TWYSIWYMDOM.Body(aEditor: TWYSIWYMEditor): TWYSIWYMDOM;
begin
  result.fEditor := aEditor;
  result.fNode:= aEditor.GetBodyNode;
end;

function TWYSIWYMDOM.FirstChild: TWYSIWYMDOM;
begin
  result.fEditor := fEditor;
  result.fNode := fEditor.GetNodeFirstChild(fNode);

end;

function TWYSIWYMDOM.NextSibling: TWYSIWYMDOM;
begin
  result.fEditor := fEditor;
  result.fNode := fEditor.GetNodeNextSibling(fNode);
end;

function TWYSIWYMDOM.Parent: TWYSIWYMDOM;
begin
  result.fEditor := fEditor;
  result.fNode := fEditor.GetNodeParent(fNode);

end;

procedure TWYSIWYMDOM.Select(aInclusive: Boolean);
begin
  fEditor.SelectNode(fNode,aInclusive);
end;

procedure TWYSIWYMDOM.SelectBefore;
begin
  fEditor.SelectBeforeNode(fNode);
end;

procedure TWYSIWYMDOM.SelectAfter;
begin

  fEditor.SelectAfterNode(fNode);
end;

procedure TWYSIWYMDOM.SelectStart;
begin
  fEditor.SelectNodeStart(fNode);
end;

procedure TWYSIWYMDOM.SelectEnd;
begin
  fEditor.SelectNodeEnd(fNode);
end;

procedure TWYSIWYMDOM.AddChild(aChild: TWYSIWYMDOM);
begin
  fEditor.InsertNodeBefore(aChild.fNode,fNode,0);
end;

procedure TWYSIWYMDOM.AddChildAfter(aChild: TWYSIWYMDOM; aSibling: TWYSIWYMDOM);
begin
  fEditor.InsertNodeBefore(aChild.fNode,fNode,aSibling.NextSibling.fNode);

end;

procedure TWYSIWYMDOM.AddChildBefore(aChild: TWYSIWYMDOM; aSibling: TWYSIWYMDOM
  );
begin
  fEditor.InsertNodeBefore(aChild.fNode,fNode,aSibling.fNode);

end;

procedure TWYSIWYMDOM.AddChildFirst(aChild: TWYSIWYMDOM);
begin
  fEditor.InsertNodeBefore(aChild.fNode,fNode,FirstChild.fNode);

end;

procedure TWYSIWYMDOM.Delete;
begin

end;

{ TWYSIWYMStyleManager }

function TWYSIWYMStyleManager.GetBlockQuoteStyle: TContainerStyle;
begin
  result := ContainerStyles[BlockQuoteStyleName];
end;

function TWYSIWYMStyleManager.GetBodyStyle: TContainerStyle;
begin
  result := ContainerStyles[BodyStyleName];

end;

function TWYSIWYMStyleManager.GetCodeStyle: TSpanStyle;
begin
  result := SpanStyles[CodeStyleName];
end;

function TWYSIWYMStyleManager.GetContainerStyles(const aName: String
  ): TContainerStyle;
begin
  // TODO:

end;

function TWYSIWYMStyleManager.GetEmphasisStyle: TSpanStyle;
begin
  result := SpanStyles[EmphasisStyleName];

end;

function TWYSIWYMStyleManager.GetHeadingStyle(const aLevel: TWYSIWYMHeadingLevel
  ): TParagraphStyle;
begin
  result := ParagraphStyles[HeadingStyleName + '-' + IntToStr(Ord(aLevel))];
end;

function TWYSIWYMStyleManager.GetHeadingStyle: TParagraphStyle;
begin
  result := ParagraphStyles[HeadingStyleName];
end;

function TWYSIWYMStyleManager.GetLinkStyle: TSpanStyle;
begin
  result := SpanStyles[LinkStyleName];

end;

function TWYSIWYMStyleManager.GetNestedOrderedListStyles(const aLevel: Longint
  ): TContainerStyle;
begin
  if aLevel < 0 then
     result := GetOrderedListItemStyle
  else
    result := ContainerStyles[OrderedListItemStyleName + '-' + IntToStr(aLevel)];

end;

function TWYSIWYMStyleManager.GetNestedUnorderedListStyles(const aLevel: Longint
  ): TContainerStyle;
begin
  if aLevel < 1 then
     result := GetUnorderedListItemStyle
  else
    result := ContainerStyles[UnorderedListItemStyleName + '-' + IntToStr(aLevel)];

end;

function TWYSIWYMStyleManager.GetOrderedListItemStyle: TContainerStyle;
begin
  result := ContainerStyles[OrderedListItemStyleName];
end;

function TWYSIWYMStyleManager.GetParagraphStyles(const aName: String
  ): TParagraphStyle;
begin
  // TODO:

end;

function TWYSIWYMStyleManager.GetSpanStyles(const aName: String): TSpanStyle;
begin
  // TODO:
end;

function TWYSIWYMStyleManager.GetStrongStyle: TSpanStyle;
begin
  result := SpanStyles[StrongStyleName];
end;

function TWYSIWYMStyleManager.GetStyleCount: Longint;
begin
  // TODO:
end;

function TWYSIWYMStyleManager.GetStyleKind(const aIndex: Longint): TStyleKind;
begin
  // TODO:
end;

function TWYSIWYMStyleManager.GetStyleKind(const aName: String): TStyleKind;
begin
  // TODO:
end;

function TWYSIWYMStyleManager.GetStyleName(const aIndex: Longint): String;
begin
  // TODO:

end;

function TWYSIWYMStyleManager.GetSubscriptStyle: TSpanStyle;
begin
  result := SpanStyles[SubscriptStyleName];

end;

function TWYSIWYMStyleManager.GetSuperscriptStyle: TSpanStyle;
begin
  result := SpanStyles[SuperscriptStyleName];

end;

function TWYSIWYMStyleManager.GetUnorderedListItemStyle: TContainerStyle;
begin
  result := ContainerStyles[UnorderedListItemStyleName];

end;

function TWYSIWYMStyleManager.GetVerseStyle: TParagraphStyle;
begin
  result := ParagraphStyles[VerseStyleName];
end;

procedure TWYSIWYMStyleManager.SetBlockQuoteStyle(AValue: TContainerStyle);
begin
  ContainerStyles[BlockQuoteStyleName] := AValue;
end;

procedure TWYSIWYMStyleManager.SetBodyStyle(AValue: TContainerStyle);
begin
  ContainerStyles[BodyStyleName] := AValue;
end;

procedure TWYSIWYMStyleManager.SetCodeStyle(AValue: TSpanStyle);
begin
  SpanStyles[CodeStyleName] := AValue;
end;

procedure TWYSIWYMStyleManager.SetContainerStyles(const aName: String;
  AValue: TContainerStyle);
begin
  // TODO:
end;

procedure TWYSIWYMStyleManager.SetEmphasisStyle(AValue: TSpanStyle);
begin
  SpanStyles[EmphasisStyleName] := AValue;

end;

procedure TWYSIWYMStyleManager.SetHeadingStyle(
  const aLevel: TWYSIWYMHeadingLevel; AValue: TParagraphStyle);
begin
  ParagraphStyles[HeadingStyleName + '-' + IntToStr(ord(aLevel))] := AValue;

end;

procedure TWYSIWYMStyleManager.SetHeadingStyle(AValue: TParagraphStyle);
begin
  ParagraphStyles[HeadingStyleName] := AValue;
end;

procedure TWYSIWYMStyleManager.SetLinkStyle(AValue: TSpanStyle);
begin
  SpanStyles[LinkStyleName] := AValue;
end;

procedure TWYSIWYMStyleManager.SetNestedOrderedListStyles(
  const aLevel: Longint; AValue: TContainerStyle);
begin
  if aLevel < 1 then
     SetOrderedListItemStyle(AValue)
  else
    ContainerStyles[OrderedListItemStyleName + '-' + IntToStr(aLevel)] := AValue;

end;

procedure TWYSIWYMStyleManager.SetNestedUnorderedListStyles(
  const aLevel: Longint; AValue: TContainerStyle);
begin
  if aLevel < 1 then
     SetUnorderedListItemStyle(AValue)
  else
    ContainerStyles[UnorderedListItemStyleName + '-' + IntToStr(aLevel)] := AValue;

end;

procedure TWYSIWYMStyleManager.SetOrderedListItemStyle(AValue: TContainerStyle);
begin
  ContainerStyles[OrderedListItemStyleName] := AValue;

end;

procedure TWYSIWYMStyleManager.SetParagraphStyles(const aName: String;
  AValue: TParagraphStyle);
begin
  // TODO:

end;

procedure TWYSIWYMStyleManager.SetSpanStyles(const aName: String;
  AValue: TSpanStyle);
begin
  // TODO:
end;

procedure TWYSIWYMStyleManager.SetStrongStyle(AValue: TSpanStyle);
begin
  SpanStyles[StrongStyleName] := AValue;

end;

procedure TWYSIWYMStyleManager.SetSubscriptStyle(AValue: TSpanStyle);
begin
  SpanStyles[SubscriptStyleName] := AValue;
end;

procedure TWYSIWYMStyleManager.SetSuperscriptStyle(AValue: TSpanStyle);
begin
  SpanStyles[SuperscriptStyleName] := AValue;

end;

procedure TWYSIWYMStyleManager.SetUnorderedListItemStyle(AValue: TContainerStyle
  );
begin
  ContainerStyles[UnorderedListItemStyleName] := AValue;

end;

procedure TWYSIWYMStyleManager.SetVerseStyle(AValue: TParagraphStyle);
begin
  ParagraphStyles[VerseStyleName] := AValue;
end;

class procedure TWYSIWYMStyleManager.WSRegisterClass;
begin
  inherited WSRegisterClass;
  RegisterWYSIWYMStyleManager;
end;

procedure TWYSIWYMStyleManager.DeleteStyle(const aName: String);
begin
  // TODO:
end;

{ TWYSIWYMEditor }

procedure TWYSIWYMEditor.SetStyleManager(AValue: TWYSIWYMStyleManager);
begin
  if fStyleManager=AValue then Exit;
  // TODO: Unregister any change notifications
  fStyleManager:=AValue;
  // TODO: Register for any change notifications.
end;

class procedure TWYSIWYMEditor.WSRegisterClass;
begin
  inherited WSRegisterClass;
  RegisterWYSIWYMEditor;
end;

procedure TWYSIWYMEditor.DoSelectionChange;
begin
  // TODO: This is here as an example of how to handle signals... leave it for now...
end;

procedure TWYSIWYMEditor.FindAndSelect(const aText: String;
  aDirection: TSearchDirection);
begin

end;

procedure TWYSIWYMEditor.ExpandSelectionAtEnd(aCount: Longint);
begin

end;

procedure TWYSIWYMEditor.ExpandSelectionAtStart(aCount: Longint);
begin

end;

procedure TWYSIWYMEditor.CollapseSelectionAtEnd(aCount: Longint);
begin

end;

procedure TWYSIWYMEditor.CollapseSelectionAtStart(aCount: Longint);
begin

end;

procedure TWYSIWYMEditor.MoveSelectionForward(aCount: Longint);
begin

end;

procedure TWYSIWYMEditor.MoveSelectionBackward(aCount: Longint);
begin

end;

procedure TWYSIWYMEditor.CollapseSelection;
begin

end;

procedure TWYSIWYMEditor.EnterText(const aText: String);
begin

end;

procedure TWYSIWYMEditor.DeleteText;
begin

end;

function TWYSIWYMEditor.SelectedText: String;
begin

end;

procedure TWYSIWYMEditor.EnableEmphasis;
begin

end;

procedure TWYSIWYMEditor.DisableEmphasis;
begin

end;

procedure TWYSIWYMEditor.ToggleEmphasis;
begin

end;

procedure TWYSIWYMEditor.EnableStrong;
begin

end;

procedure TWYSIWYMEditor.DisableStrong;
begin

end;

procedure TWYSIWYMEditor.ToggleStrong;
begin

end;

procedure TWYSIWYMEditor.EnableCode;
begin

end;

procedure TWYSIWYMEditor.DisableCode;
begin

end;

procedure TWYSIWYMEditor.ToggleCode;
begin

end;

procedure TWYSIWYMEditor.EnableSubscript;
begin

end;

procedure TWYSIWYMEditor.DisableSubscript;
begin

end;

procedure TWYSIWYMEditor.ToggleSubscript;
begin

end;

procedure TWYSIWYMEditor.EnableSuperscript;
begin

end;

procedure TWYSIWYMEditor.DisableSuperscript;
begin

end;

procedure TWYSIWYMEditor.ToggleSuperscript;
begin

end;

procedure TWYSIWYMEditor.EnableCustomSpan(const aClass: String);
begin

end;

procedure TWYSIWYMEditor.DisableCustomSpan(const aClass: String);
begin

end;

procedure TWYSIWYMEditor.ToggleCustomSpan(const aClass: String);
begin

end;

procedure TWYSIWYMEditor.EnableLink(const aReference: String);
begin

end;

procedure TWYSIWYMEditor.DisableLink;
begin

end;

procedure TWYSIWYMEditor.InsertLineBreak;
begin

end;

procedure TWYSIWYMEditor.SetParagraphNormal;
begin

end;

procedure TWYSIWYMEditor.SetParagraphHeading(aLevel: TWYSIWYMHeadingLevel);
begin

end;

procedure TWYSIWYMEditor.SetParagraphVerse;
begin

end;

procedure TWYSIWYMEditor.SetParagraphCustom(const aClass: String);
begin

end;

procedure TWYSIWYMEditor.InsertHorizontalRule;
begin

end;

procedure TWYSIWYMEditor.StartNewParagraph;
begin

end;

procedure TWYSIWYMEditor.WrapParagraphInBlockQuote;
begin

end;

procedure TWYSIWYMEditor.WrapParagraphInUnorderedListItem;
begin

end;

procedure TWYSIWYMEditor.WrapParagraphInOrderedListItem;
begin

end;

procedure TWYSIWYMEditor.WrapParagraphInVerse;
begin

end;

procedure TWYSIWYMEditor.WrapParagraphInCustom(const aClass: String);
begin

end;

procedure TWYSIWYMEditor.MoveParagraphIntoPreviousContainer;
begin

end;

procedure TWYSIWYMEditor.MoveParagraphIntoNextContainer;
begin

end;

procedure TWYSIWYMEditor.MoveParagraphOutOfContainer;
begin

end;

function TWYSIWYMEditor.GetBodyNode: TWYSIWYMNode;
begin

end;

function TWYSIWYMEditor.GetNodeFirstChild(aNode: TWYSIWYMNode): TWYSIWYMNode;
begin

end;

function TWYSIWYMEditor.GetNodeNextSibling(aNode: TWYSIWYMNode): TWYSIWYMNode;
begin

end;

function TWYSIWYMEditor.GetNodeParent(aNode: TWYSIWYMNode): TWYSIWYMNode;
begin

end;

function TWYSIWYMEditor.GetNodeKind(aNode: TWYSIWYMNode): TWYSIWYMNodeKind;
begin

end;

function TWYSIWYMEditor.GetNodeClass(aNode: TWYSIWYMNode): TWYSIWYMNodeClass;
begin

end;

procedure TWYSIWYMEditor.SetNodeClass(aNode: TWYSIWYMNode;
  aValue: TWYSIWYMNodeClass);
begin

end;

function TWYSIWYMEditor.GetNodeName(aNode: TWYSIWYMNode): String;
begin

end;

procedure TWYSIWYMEditor.SetNodeName(aNode: TWYSIWYMNode; const aValue: String);
begin

end;

function TWYSIWYMEditor.GetLinkNodeReference(aNode: TWYSIWYMNode): String;
begin

end;

procedure TWYSIWYMEditor.SetLinkNodeReference(aNode: TWYSIWYMNode;
  const aValue: String);
begin

end;

function TWYSIWYMEditor.GetTextNodeContent(aNode: TWYSIWYMNode): String;
begin

end;

procedure TWYSIWYMEditor.SetTextNodeContent(aNode: TWYSIWYMNode;
  const aValue: String);
begin

end;

function TWYSIWYMEditor.GetHeadingNodeLevel(aNode: TWYSIWYMNode
  ): TWYSIWYMHeadingLevel;
begin

end;

procedure TWYSIWYMEditor.SetHeadingNodeLevel(aNode: TWYSIWYMNode;
  aValue: TWYSIWYMHeadingLevel);
begin

end;

procedure TWYSIWYMEditor.InsertNodeBefore(aNode: TWYSIWYMNode;
  aNewParent: TWYSIWYMNode; aNewSibling: TWYSIWYMNode);
begin

end;

procedure TWYSIWYMEditor.DeleteNode(aNode: TWYSIWYMNode);
begin

end;

procedure TWYSIWYMEditor.SelectNode(aNode: TWYSIWYMNode; aInclusive: Boolean);
begin

end;

procedure TWYSIWYMEditor.SelectBeforeNode(aNode: TWYSIWYMNode);
begin

end;

procedure TWYSIWYMEditor.SelectAfterNode(aNode: TWYSIWYMNode);
begin

end;

procedure TWYSIWYMEditor.SelectNodeStart(aNode: TWYSIWYMNode);
begin

end;

procedure TWYSIWYMEditor.SelectNodeEnd(aNode: TWYSIWYMNode);
begin

end;

procedure TWYSIWYMEditor.Undo;
begin

end;

procedure TWYSIWYMEditor.Redo;
begin

end;

procedure TWYSIWYMEditor.PasteFromClipboard;
begin

end;

procedure TWYSIWYMEditor.CutToClipboard;
begin

end;

procedure TWYSIWYMEditor.CopyToClipboard;
begin

end;

function TWYSIWYMEditor.Serialize(aSerializerClass: TWYSIWYMSerializerClass
  ): String;
var
  lStream: TStringStream;
begin
  lStream := TStringStream.Create('');
  try
    Serialize(aSerializerClass,lStream);
    result := lStream.DataString;
  finally
    lStream.Free;
  end;
end;

procedure TWYSIWYMEditor.Deserialize(
  aDeserializerClass: TWYSIWYMDeserializerClass; const aText: String);
var
  lStream: TStringStream;
begin
  lStream := TStringStream.Create(aText);
  try
    Deserialize(aDeserializerClass,lStream);
  finally
    lStream.Free;
  end;

end;

procedure TWYSIWYMEditor.Serialize(aSerializerClass: TWYSIWYMSerializerClass;
  aStream: TStream);
var
  lSerializer: TWYSIWYMSerializer;
begin
  lSerializer := aSerializerClass.Create(aStream);
  try
    WriteContentsTo(lSerializer);
  finally
    lSerializer.Free;
  end;

end;

procedure TWYSIWYMEditor.Deserialize(
  aDeserializerClass: TWYSIWYMDeserializerClass; aStream: TStream);
var
  lDeserializer: TWYSIWYMDeserializer;
begin
  lDeserializer := aDeserializerClass.Create(aStream);
  try
    LoadContentsFrom(lDeserializer);
  finally
    lDeserializer.Free;
  end;

end;

procedure TWYSIWYMEditor.WriteContentsTo(aReceiver: TWYSIWYMReceiver);
begin
  // TODO: scan through the structure and put into the processer.

end;

procedure TWYSIWYMEditor.LoadContentsFrom(aProvider: TWYSIWYMProvider);
begin
  // TODO: scan through the structure and put into the processor.

end;

end.

