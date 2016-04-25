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



  TWYSIWYMNodeKind = (nkParagraph, nkSpan, nkText);
  TWYSIWYMSpanKind = (ncEmphasis, ncStrong, ncCode, ncSubscript,
                               ncSuperscript, ncLink, ncLinebreak, ncCustomSpan);
  TWYSIWYMParagraphKind = (ncNormalParagraph, ncHeading, ncVerse, ncHorizontalRule, ncBlockQuote, ncOrderedListItem,
                               ncUnorderedListItem, ncCustomParagraph);
  TWYSIWYMHeadingLevel = (hl1, hl2, hl3, hl4, hl5, hl6);


  { TWYSIWYMStyleManager }

  TWYSIWYMStyleManager = class(TLCLReferenceComponent)
  private
    function GetBlockQuoteStyle: TParagraphStyle;
    function GetBlockQuoteStyle(const aIndent: Word): TParagraphStyle;
    function GetBodyStyle: TBodyStyle;
    function GetCodeStyle: TSpanStyle;
    function GetEmphasisStyle: TSpanStyle;
    function GetHeadingStyle(const aLevel: TWYSIWYMHeadingLevel): TParagraphStyle;
    function GetHeadingStyle: TParagraphStyle;
    function GetLinkStyle: TSpanStyle;
    function GetOrderedListStyles(const aIndent: Word): TParagraphStyle;
    function GetUnorderedListStyles(const aIndent: Word): TParagraphStyle;
    function GetOrderedListItemStyle: TParagraphStyle;
    function GetParagraphStyles(const aName: String): TParagraphStyle;
    function GetSpanStyles(const aName: String): TSpanStyle;
    function GetStrongStyle: TSpanStyle;
    function GetStyleCount: Longint;
    function GetStyleKind(const aIndex: Longint): TStyleKind;
    function GetStyleKind(const aName: String): TStyleKind;
    function GetStyleName(const aIndex: Longint): String;
    function GetSubscriptStyle: TSpanStyle;
    function GetSuperscriptStyle: TSpanStyle;
    function GetUnorderedListItemStyle: TParagraphStyle;
    function GetVerseStyle: TParagraphStyle;
    procedure SetBlockQuoteStyle(AValue: TParagraphStyle);
    procedure SetBlockQuoteStyle(const aIndent: Word; AValue: TParagraphStyle);
    procedure SetBodyStyle(AValue: TBodyStyle);
    procedure SetCodeStyle(AValue: TSpanStyle);
    procedure SetEmphasisStyle(AValue: TSpanStyle);
    procedure SetHeadingStyle(const aLevel: TWYSIWYMHeadingLevel; AValue: TParagraphStyle);
    procedure SetHeadingStyle(AValue: TParagraphStyle);
    procedure SetLinkStyle(AValue: TSpanStyle);
    procedure SetOrderedListStyles(const aIndent: Word; AValue: TParagraphStyle);
    procedure SetUnorderedListStyles(const aIndent: Word;
      AValue: TParagraphStyle);
    procedure SetOrderedListItemStyle(AValue: TParagraphStyle);
    procedure SetParagraphStyles(const aName: String; AValue: TParagraphStyle);
    procedure SetSpanStyles(const aName: String; AValue: TSpanStyle);
    procedure SetStrongStyle(AValue: TSpanStyle);
    procedure SetSubscriptStyle(AValue: TSpanStyle);
    procedure SetSuperscriptStyle(AValue: TSpanStyle);
    procedure SetUnorderedListItemStyle(AValue: TParagraphStyle);
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
    property BodyStyle: TBodyStyle read GetBodyStyle write SetBodyStyle;

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
    property DefaultBlockQuoteStyle: TParagraphStyle read GetBlockQuoteStyle write SetBlockQuoteStyle;
    property BlockQuoteStyle[const aIndent: Word]: TParagraphStyle read GetBlockQuoteStyle write SetBlockQuoteStyle;
    property DefaultOrderedListItemStyle: TParagraphStyle read GetOrderedListItemStyle write SetOrderedListItemStyle;
    property OrderedListItemStyle[const aIndent: Word]: TParagraphStyle read GetOrderedListStyles write SetOrderedListStyles;
    property DefaultUnorderedListItemStyle: TParagraphStyle read GetUnorderedListItemStyle write SetUnorderedListItemStyle;
    property UnorderedListItemStyle[const aIndent: Word]: TParagraphStyle read GetUnorderedListStyles write SetUnorderedListStyles;
    // specify styles for custom paragraph classes.
    property ParagraphStyles[const aName: String]: TParagraphStyle read GetParagraphStyles write SetParagraphStyles;

    // these allow manipulation of the contained styles.
    property StyleCount: Longint read GetStyleCount;
    property StyleName[const aIndex: Longint]: String read GetStyleName;
    property StyleKind[const aIndex: Longint]: TStyleKind read GetStyleKind;
    property StyleKindByName[const aName: String]: TStyleKind read GetStyleKind;
    procedure DeleteStyle(const aName: String);
  end;

  TWYSIWYMReceiver = class;

  TWYSIWYMProviderNodeKind = (pnkParagraphStart, pnkSpanStart, pnkText, pnkSpanEnd, pnkParagraphEnd);

  { TWYSIWYMProvider }

  TWYSIWYMProvider = class
  public
    function NodeKind: TWYSIWYMProviderNodeKind; virtual; abstract;
    function SpanKind: TWYSIWYMSpanKind; virtual; abstract;
    function ParagraphKind: TWYSIWYMParagraphKind; virtual; abstract;
    function CustomClass: String; virtual; abstract;
    function LinkReference: String; virtual; abstract;
    function HeadingLevel: TWYSIWYMHeadingLevel; virtual; abstract;
    function IndentLevel: Word; virtual; abstract;
    function TextContent: String; virtual; abstract;
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
    procedure BlockQuoteStarted(aIndent: Word); virtual; abstract;
    procedure BlockQuoteFinished(aIndent: Word); virtual; abstract;
    procedure OrderedListItemStarted(aIndent: Word); virtual; abstract;
    procedure OrderedListItemFinished(aIndent: Word); virtual; abstract;
    procedure UnorderedListItemStarted(aIndent: Word); virtual; abstract;
    procedure UnorderedListItemFinished(aIndent: Word); virtual; abstract;
    procedure CustomParagraphStarted(const aClass: String); virtual; abstract;
    procedure CustomParagraphFinished(const aClass: String); virtual; abstract;
  end;

  TWYSIWYMProcessorClass = class of TWYSIWYMReceiver;

  TWYSIWYMSerializer = class(TWYSIWYMReceiver)
  public
    constructor Create(aStream: TStream); virtual; abstract;

  end;

  TWYSIWYMSerializerClass = class of TWYSIWYMSerializer;

  TSearchDirection = (sdSelectionToEnd, sdStartToSelection, sdSelectionToBeginning, sdEndToSelection);
  TNodeSelectionState = (nssUnselected, nssSelected, nssContainsSelection, nssContainsSelectionStartOnly, nssContainsSelectionEndOnly);
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

  The structure of a document in WYSIWYMEditor is a 'tree' structure, with nodes
  that contain other nodes. There are has four kinds of nodes: body,
  paragraphs, spans and text. Text represents actual text content. A span
  is a wrapper around inline text and other spans, which indicates a
  structure that won't effect the layout. A paragraph is a single block
  of text and spans, with spacing around it, separating it from other paragraphs
  and forcing it to flow down the page instead of across. The body represents
  the content of the entire document. At some point in the future I may add other
  kind embedding images, figures and object content, but these may be limited to
  a paragraph kind.

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

  In addition, certain paragraph types have additional properties. A Heading has
  a level, there are up to 6 of them. Block quotes and list items have an indent
  level, anywhere from 0 and up. To simulate nesting of these constructs, "child"
  objects can be given higher indent levels (see comments below on nesting these
  things).

  spans:
  - emphasis
  - strong
  - code
  - subscript
  - superscript
  - custom-span (contains a 'class' attribute in invisible text or something)
  - link: text which represents a link to another document (specified in some
  invisible text).
  - line-break: represents a break between lines that doesn't cause a new paragraph.

  paragraphs:
  - normal
  - heading (with importance level)
  - verse
  - horizontal-rule
  - block-quote (with indent level)
  - ordered-list-item (with indent level)
  - unordered-list-item (with indent level)
  - custom-paragraph


    On Nesting Blocks:

    You'll note that other structured documents allow nesting of certain block
    content inside of other block content. Here, I've factored that possibility
    out for the needs of simplicity. By keeping the style with the paragraph, it
    is easier to support this in the widgetset, whereas allowing arbitrary nesting
    of higher-level containers would require more complex algorithms to figure out
    exactly what level a given piece of text is when said searches become necessary.

    The only functionaliy this removes from a user-interface perspective is the
    ability to have one bullet point for multiple paragraphs at the same indent
    level. This is a common limitation in editors, however, and I don't think it's
    led to major complaints. If an author's bullet items are getting so big that you need
    more than one paragraph, then the author should probably consider shifting to
    a heading/body structure for these things instead.

    In fact, removing this requirement probably removes most reasons for a user
    to need to review the actual tags being used, since the paragraphs separations
    are always obvious.

    Apart from this, the only thing the user sees is the bullet, or the indentation
    of the block quote. The separation between the items is going to be the same
    whether it contains a paragraph or not. So, for all the user cares, they are
    separate paragraphs anyway. The visibility of this difference may be more
    obvious if borders are used in styling these items, however, those aren't
    available in this component right now, and if they ever are, certain actions
    can be taken to "merge" them together when they're right next to each other.

    The other thing to worry about is serialization and deserialization into
    formats which do support nesting. This is simply a matter of maintaining
    a 'nesting' state during these processes.

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
    // TODO: What other events do we need? I don't need to do to many details.

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
    procedure SetParagraphOrderedListItem(aIndent: Word);
    procedure SetParagraphUnorderedListItem(aIndent: Word);
    procedure SetBlockQuote(aIndent: Word);
    procedure SetParagraphCustom(const aClass: String);
    procedure InsertHorizontalRule; // inserts after current paragraph.
    procedure StartNewParagraph; // starts a new paragraph at the current selection,
                                 // if the current paragraph was a heading, the
                                 // new paragraph becomes a normal paragraph, otherwise
                                 // it remains the same type of paragraph as
                                 // the current.

    // querying... you can also use the Node struct below to make things a little
    // simpler...
    function GetBodyNode: TWYSIWYMNode;
    // navigating through the document (forward only). The value will be 0 if
    // there is no node there.
    function GetNodeFirstChild(aNode: TWYSIWYMNode): TWYSIWYMNode;
    function GetNodeNextSibling(aNode: TWYSIWYMNode): TWYSIWYMNode;
    function GetNodeParent(aNode: TWYSIWYMNode): TWYSIWYMNode;
    // node properties...
    // The kind determines if it is a paragraph, span or text.
    function GetNodeKind(aNode: TWYSIWYMNode): TWYSIWYMNodeKind;
    function GetNodeParagraphKind(aNode: TWYSIWYMNode): TWYSIWYMParagraphKind;
    function GetNodeSpanKind(aNode: TWYSIWYMNode): TWYSIWYMSpanKind;
    // If an attempt is made to set a paragraph kind on a span, and vice versa
    // an error will be raised..
    procedure SetNodeParagraphKind(aNode: TWYSIWYMNode; aValue: TWYSIWYMParagraphKind);
    procedure SetNodeSpanKind(aNode: TWYSIWYMNode; aValue: TWYSIWYMSpanKind);
    // returns the name of a custom class.
    function GetNodeCustomClass(aNode: TWYSIWYMNode): String; // returns the 'tag name', or 'class' if a custom...
    procedure SetNodeCustomClass(aNode: TWYSIWYMNode; const aValue: String); // yes, we can change this...
    // returns the reference for a link. If the node is not a link, an error is raised.
    function GetNodeLinkReference(aNode: TWYSIWYMNode): String;
    procedure SetNodeLinkReference(aNode: TWYSIWYMNode; const aValue: String);
    // returns the text of a node, if the node is not text, an error is raised.
    function GetNodeTextContent(aNode: TWYSIWYMNode): String; // only works with text.
    procedure SetNodeTextContent(aNode: TWYSIWYMNode; const aValue: String);
    // returns the level of a heading, if the node is not a heading, an error is raised.
    function GetNodeHeadingLevel(aNode: TWYSIWYMNode): TWYSIWYMHeadingLevel;
    procedure SetNodeHeadingLevel(aNode: TWYSIWYMNode; aValue: TWYSIWYMHeadingLevel);
    // returns the indent level of list items and block quotes. an error is raised if the paragraph doesn't support this.
    function GetNodeIndentLevel(aNode: TWYSIWYMNode): Word;
    procedure SetNodeIndentLevel(aNode: TWYSIWYMNode; aValue: Word);

    function GetNodeSelectionState(aNode: TWYSIWYMNode): TNodeSelectionState;
    // if node is a text node, and state is returns the actual
    // text within the node that is selected. If node is unselected, then
    // returns blank. Otherwise, raises an error.
    function GetNodeSelectedText(aNode: TWYSIWYMNode): String;

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
    // TODO: Might need a serializer here...
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
    function GetHeadingLevel: TWYSIWYMHeadingLevel;
    function GetIndentLevel: Word;
    function GetParagraphKind: TWYSIWYMParagraphKind;
    function GetSpanKind: TWYSIWYMSpanKind;
    function GetTextContent: String;
    function GetIsNull: Boolean;
    function GetKind: TWYSIWYMNodeKind;
    function GetLinkReference: String;
    function GetCustomClass: String;
    procedure SetHeadingLevel(AValue: TWYSIWYMHeadingLevel);
    procedure SetIndentLevel(AValue: Word);
    procedure SetCustomClass(AValue: String);
    procedure SetLinkReference(AValue: String);
    procedure SetParagraphKind(AValue: TWYSIWYMParagraphKind);
    procedure SetSpanKind(AValue: TWYSIWYMSpanKind);
    procedure SetTextContent(AValue: String);
  public
    class function New(aEditor: TWYSIWYMEditor; aNode: TWYSIWYMNode): TWYSIWYMDOM; static;
    class function Body(aEditor: TWYSIWYMEditor): TWYSIWYMDOM; static;
    property IsNull: Boolean read GetIsNull;
    property Kind: TWYSIWYMNodeKind read GetKind;
    property ParagraphKind: TWYSIWYMParagraphKind read GetParagraphKind write SetParagraphKind;
    property SpanKind: TWYSIWYMSpanKind read GetSpanKind write SetSpanKind;
    property Name: String read GetCustomClass write SetCustomClass;
    function FirstChild: TWYSIWYMDOM;
    function NextSibling: TWYSIWYMDOM;
    function Parent: TWYSIWYMDOM;
    property LinkReference: String read GetLinkReference write SetLinkReference;
    property TextContent: String read GetTextContent write SetTextContent;
    property HeadingLevel: TWYSIWYMHeadingLevel read GetHeadingLevel write SetHeadingLevel;
    property IndentLevel: Word read GetIndentLevel write SetIndentLevel;
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
      pnkParagraphStart:
      case ParagraphKind of
        ncNormalParagraph:
          aReceiver.NormalParagraphStarted;
        ncHeading:
          aReceiver.HeadingStarted(HeadingLevel);
        ncVerse:
          aReceiver.VerseStarted;
        ncHorizontalRule:
          aReceiver.HorizontalRuleFound;
        ncCustomParagraph:
          aReceiver.CustomParagraphStarted(CustomClass);
        ncBlockQuote:
          aReceiver.BlockQuoteStarted(IndentLevel);
        ncOrderedListItem:
          aReceiver.OrderedListItemStarted(IndentLevel);
        ncUnorderedListItem:
          aReceiver.UnorderedListItemStarted(IndentLevel);
      end;
      pnkSpanStart:
      case SpanKind of
        ncEmphasis:
          aReceiver.EmphasisStarted;
        ncStrong:
          aReceiver.StrongStarted;
        ncCode:
          aReceiver.CodeStarted;
        ncSubscript:
          aReceiver.SubscriptStarted;
        ncSuperscript:
          aReceiver.SuperscriptStarted;
        ncCustomSpan:
          aReceiver.CustomSpanStarted(CustomClass);
        ncLink:
          aReceiver.LinkStarted(LinkReference);
        ncLinebreak:
          aReceiver.LineBreakFound;
      end;
      pnkText:
        aReceiver.TextFound(TextContent);
      pnkSpanEnd:
      case SpanKind of
        ncEmphasis:
          aReceiver.EmphasisFinished;
        ncStrong:
          aReceiver.StrongFinished;
        ncCode:
          aReceiver.CodeFinished;
        ncSubscript:
          aReceiver.SubscriptFinished;
        ncSuperscript:
          aReceiver.SuperscriptFinished;
        ncCustomSpan:
          aReceiver.CustomSpanFinished(CustomClass);
        ncLink:
          aReceiver.LinkFinished;
      end;
      pnkParagraphEnd:
      case ParagraphKind of
        ncNormalParagraph:
          aReceiver.NormalParagraphFinished;
        ncHeading:
          aReceiver.HeadingFinished(HeadingLevel);
        ncVerse:
          aReceiver.VerseFinished;
        ncCustomParagraph:
          aReceiver.CustomParagraphFinished(CustomClass);
        ncBlockQuote:
          aReceiver.BlockQuoteFinished(IndentLevel);
        ncOrderedListItem:
          aReceiver.OrderedListItemFinished(IndentLevel);
        ncUnorderedListItem:
          aReceiver.UnorderedListItemFinished(IndentLevel);
      end;
    end;
  end;
end;

{ TWYSIWYMDOM }

function TWYSIWYMDOM.GetTextContent: String;
begin
  result := fEditor.GetNodeTextContent(fNode);
end;

function TWYSIWYMDOM.GetHeadingLevel: TWYSIWYMHeadingLevel;
begin
  result := fEditor.GetNodeHeadingLevel(fNode);
end;

function TWYSIWYMDOM.GetIndentLevel: Word;
begin
  result := fEditor.GetNodeIndentLevel(fNode);
end;

function TWYSIWYMDOM.GetParagraphKind: TWYSIWYMParagraphKind;
begin
  result := fEditor.GetNodeParagraphKind(fNode);
end;

function TWYSIWYMDOM.GetSpanKind: TWYSIWYMSpanKind;
begin
  result := fEditor.GetNodeSpanKind(fNode);
end;

function TWYSIWYMDOM.GetIsNull: Boolean;
begin
  result := (fNode = 0);
end;

function TWYSIWYMDOM.GetKind: TWYSIWYMNodeKind;
begin
  result := fEditor.GetNodeKind(fNode);
end;

function TWYSIWYMDOM.GetCustomClass: String;
begin
  result := fEditor.GetNodeCustomClass(fNode);
end;

procedure TWYSIWYMDOM.SetHeadingLevel(AValue: TWYSIWYMHeadingLevel);
begin
  fEditor.SetNodeHeadingLevel(fNode,AValue);
end;

procedure TWYSIWYMDOM.SetIndentLevel(AValue: Word);
begin
  fEditor.SetNodeIndentLevel(fNode,AValue);

end;

function TWYSIWYMDOM.GetLinkReference: String;
begin
  result := fEditor.GetNodeLinkReference(fNode);
end;

procedure TWYSIWYMDOM.SetTextContent(AValue: String);
begin
  fEditor.SetNodeTextContent(fNode,AValue);
end;

procedure TWYSIWYMDOM.SetCustomClass(AValue: String);
begin
  fEditor.SetNodeCustomClass(fNode,AValue);

end;

procedure TWYSIWYMDOM.SetLinkReference(AValue: String);
begin
  fEditor.SetNodeLinkReference(fNode,AValue);
end;

procedure TWYSIWYMDOM.SetParagraphKind(AValue: TWYSIWYMParagraphKind);
begin
  fEditor.SetNodeParagraphKind(fNode,AValue);

end;

procedure TWYSIWYMDOM.SetSpanKind(AValue: TWYSIWYMSpanKind);
begin
  fEditor.SetNodeSpanKind(fNode,AValue);

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
   raise ENotImplemented.Create('TWYSIWYMDOM.Delete');
end;

{ TWYSIWYMStyleManager }

function TWYSIWYMStyleManager.GetBlockQuoteStyle: TParagraphStyle;
begin
  result := ParagraphStyles[BlockQuoteStyleName];
end;

function TWYSIWYMStyleManager.GetBlockQuoteStyle(const aIndent: Word
  ): TParagraphStyle;
begin
     result := ParagraphStyles[BlockQuoteStyleName + '-' + IntToStr(aIndent)]
end;

function TWYSIWYMStyleManager.GetBodyStyle: TBodyStyle;
begin
  // TODO: Not sure where to store this...
  raise ENotImplemented.Create('TWYSIWYMStyleManager.GetBodyStyle');

end;

function TWYSIWYMStyleManager.GetCodeStyle: TSpanStyle;
begin
  result := SpanStyles[CodeStyleName];
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

function TWYSIWYMStyleManager.GetOrderedListStyles(const aIndent: Word
  ): TParagraphStyle;
begin
    result := ParagraphStyles[OrderedListItemStyleName + '-' + IntToStr(aIndent)];

end;

function TWYSIWYMStyleManager.GetUnorderedListStyles(const aIndent: Word
  ): TParagraphStyle;
begin
    result := ParagraphStyles[UnorderedListItemStyleName + '-' + IntToStr(aIndent)];

end;

function TWYSIWYMStyleManager.GetOrderedListItemStyle: TParagraphStyle;
begin
  result := ParagraphStyles[OrderedListItemStyleName];
end;

function TWYSIWYMStyleManager.GetParagraphStyles(const aName: String
  ): TParagraphStyle;
begin
  // TODO:
  raise ENotImplemented.Create('TWYSIWYMStyleManager.GetParagraphStyles');

end;

function TWYSIWYMStyleManager.GetSpanStyles(const aName: String): TSpanStyle;
begin
  // TODO:
  raise ENotImplemented.Create('TWYSIWYMStyleManager.GetSpanStyles');
end;

function TWYSIWYMStyleManager.GetStrongStyle: TSpanStyle;
begin
  result := SpanStyles[StrongStyleName];
end;

function TWYSIWYMStyleManager.GetStyleCount: Longint;
begin
  // TODO:
  raise ENotImplemented.Create('TWYSIWYMStyleManager.GetStyleCount');
end;

function TWYSIWYMStyleManager.GetStyleKind(const aIndex: Longint): TStyleKind;
begin
  // TODO:
  raise ENotImplemented.Create('TWYSIWYMStyleManager.GetStyleKind');
end;

function TWYSIWYMStyleManager.GetStyleKind(const aName: String): TStyleKind;
begin
   // TODO:
   raise ENotImplemented.Create(' TWYSIWYMStyleManager.GetStyleKind');
end;

function TWYSIWYMStyleManager.GetStyleName(const aIndex: Longint): String;
begin
   // TODO:
   raise ENotImplemented.Create(' TWYSIWYMStyleManager.GetStyleName');
end;

function TWYSIWYMStyleManager.GetSubscriptStyle: TSpanStyle;
begin
  result := SpanStyles[SubscriptStyleName];

end;

function TWYSIWYMStyleManager.GetSuperscriptStyle: TSpanStyle;
begin
  result := SpanStyles[SuperscriptStyleName];

end;

function TWYSIWYMStyleManager.GetUnorderedListItemStyle: TParagraphStyle;
begin
  result := ParagraphStyles[UnorderedListItemStyleName];

end;

function TWYSIWYMStyleManager.GetVerseStyle: TParagraphStyle;
begin
  result := ParagraphStyles[VerseStyleName];
end;

procedure TWYSIWYMStyleManager.SetBlockQuoteStyle(AValue: TParagraphStyle);
begin
  ParagraphStyles[BlockQuoteStyleName] := AValue;
end;

procedure TWYSIWYMStyleManager.SetBlockQuoteStyle(const aIndent: Word;
  AValue: TParagraphStyle);
begin
  ParagraphStyles[BlockQuoteStyleName + '-' + IntToStr(aIndent)] := AValue;
end;

procedure TWYSIWYMStyleManager.SetBodyStyle(AValue: TBodyStyle);
begin
   // TODO: Not sure where to put this...
   raise ENotImplemented.Create('TWYSIWYMStyleManager.SetBodyStyle');
end;

procedure TWYSIWYMStyleManager.SetCodeStyle(AValue: TSpanStyle);
begin
  SpanStyles[CodeStyleName] := AValue;
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

procedure TWYSIWYMStyleManager.SetOrderedListStyles(const aIndent: Word;
  AValue: TParagraphStyle);
begin
  ParagraphStyles[OrderedListItemStyleName + '-' + IntToStr(aIndent)] := AValue;

end;

procedure TWYSIWYMStyleManager.SetUnorderedListStyles(const aIndent: Word;
  AValue: TParagraphStyle);
begin
  ParagraphStyles[UnorderedListItemStyleName + '-' + IntToStr(aIndent)] := AValue;

end;

procedure TWYSIWYMStyleManager.SetOrderedListItemStyle(AValue: TParagraphStyle);
begin
  ParagraphStyles[OrderedListItemStyleName] := AValue;

end;

procedure TWYSIWYMStyleManager.SetParagraphStyles(const aName: String;
  AValue: TParagraphStyle);
begin
   // TODO:
   raise ENotImplemented.Create('TWYSIWYMStyleManager.SetParagraphStyles');
end;

procedure TWYSIWYMStyleManager.SetSpanStyles(const aName: String;
  AValue: TSpanStyle);
begin
   // TODO:
   raise ENotImplemented.Create('TWYSIWYMStyleManager.SetSpanStyles');
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

procedure TWYSIWYMStyleManager.SetUnorderedListItemStyle(AValue: TParagraphStyle);
begin
  ParagraphStyles[UnorderedListItemStyleName] := AValue;

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
   raise ENotImplemented.Create('TWYSIWYMStyleManager.DeleteStyle');
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
   raise ENotImplemented.Create('TWYSIWYMEditor.DoSelectionChange');
end;

procedure TWYSIWYMEditor.FindAndSelect(const aText: String;
  aDirection: TSearchDirection);
begin
   raise ENotImplemented.Create('TWYSIWYMEditor.FindAndSelect');
end;

procedure TWYSIWYMEditor.ExpandSelectionAtEnd(aCount: Longint);
begin
   raise ENotImplemented.Create('TWYSIWYMEditor.ExpandSelectionAtEnd');
end;

procedure TWYSIWYMEditor.ExpandSelectionAtStart(aCount: Longint);
begin
   raise ENotImplemented.Create('TWYSIWYMEditor.ExpandSelectionAtStart');
end;

procedure TWYSIWYMEditor.CollapseSelectionAtEnd(aCount: Longint);
begin
   raise ENotImplemented.Create('TWYSIWYMEditor.CollapseSelectionAtEnd');
end;

procedure TWYSIWYMEditor.CollapseSelectionAtStart(aCount: Longint);
begin
   raise ENotImplemented.Create('TWYSIWYMEditor.CollapseSelectionAtStart');
end;

procedure TWYSIWYMEditor.MoveSelectionForward(aCount: Longint);
begin
   raise ENotImplemented.Create('TWYSIWYMEditor.MoveSelectionForward');
end;

procedure TWYSIWYMEditor.MoveSelectionBackward(aCount: Longint);
begin
   raise ENotImplemented.Create('TWYSIWYMEditor.MoveSelectionBackward');
end;

procedure TWYSIWYMEditor.CollapseSelection;
begin
   raise ENotImplemented.Create('TWYSIWYMEditor.CollapseSelection');
end;

procedure TWYSIWYMEditor.EnterText(const aText: String);
begin
   raise ENotImplemented.Create('TWYSIWYMEditor.EnterText');
end;

procedure TWYSIWYMEditor.DeleteText;
begin
   raise ENotImplemented.Create('TWYSIWYMEditor.DeleteText');
end;

function TWYSIWYMEditor.SelectedText: String;
begin
   raise ENotImplemented.Create('TWYSIWYMEditor.SelectedText');
end;

procedure TWYSIWYMEditor.EnableEmphasis;
begin
   raise ENotImplemented.Create('TWYSIWYMEditor.EnableEmphasis');
end;

procedure TWYSIWYMEditor.DisableEmphasis;
begin
   raise ENotImplemented.Create('TWYSIWYMEditor.DisableEmphasis');
end;

procedure TWYSIWYMEditor.ToggleEmphasis;
begin
   raise ENotImplemented.Create('TWYSIWYMEditor.ToggleEmphasis');
end;

procedure TWYSIWYMEditor.EnableStrong;
begin
   raise ENotImplemented.Create('TWYSIWYMEditor.EnableStrong');
end;

procedure TWYSIWYMEditor.DisableStrong;
begin
   raise ENotImplemented.Create('TWYSIWYMEditor.DisableStrong');
end;

procedure TWYSIWYMEditor.ToggleStrong;
begin
   raise ENotImplemented.Create('TWYSIWYMEditor.ToggleStrong');
end;

procedure TWYSIWYMEditor.EnableCode;
begin
   raise ENotImplemented.Create('TWYSIWYMEditor.EnableCode');
end;

procedure TWYSIWYMEditor.DisableCode;
begin
   raise ENotImplemented.Create('TWYSIWYMEditor.DisableCode');
end;

procedure TWYSIWYMEditor.ToggleCode;
begin
   raise ENotImplemented.Create('TWYSIWYMEditor.ToggleCode');
end;

procedure TWYSIWYMEditor.EnableSubscript;
begin
   raise ENotImplemented.Create('TWYSIWYMEditor.EnableSubscript');
end;

procedure TWYSIWYMEditor.DisableSubscript;
begin
   raise ENotImplemented.Create('TWYSIWYMEditor.DisableSubscript');
end;

procedure TWYSIWYMEditor.ToggleSubscript;
begin
   raise ENotImplemented.Create('TWYSIWYMEditor.ToggleSubscript');
end;

procedure TWYSIWYMEditor.EnableSuperscript;
begin
   raise ENotImplemented.Create('TWYSIWYMEditor.EnableSuperscript');
end;

procedure TWYSIWYMEditor.DisableSuperscript;
begin
   raise ENotImplemented.Create('TWYSIWYMEditor.DisableSuperscript');
end;

procedure TWYSIWYMEditor.ToggleSuperscript;
begin
   raise ENotImplemented.Create('TWYSIWYMEditor.ToggleSuperscript');
end;

procedure TWYSIWYMEditor.EnableCustomSpan(const aClass: String);
begin
   raise ENotImplemented.Create('TWYSIWYMEditor.EnableCustomSpan');
end;

procedure TWYSIWYMEditor.DisableCustomSpan(const aClass: String);
begin
   raise ENotImplemented.Create('TWYSIWYMEditor.DisableCustomSpan');
end;

procedure TWYSIWYMEditor.ToggleCustomSpan(const aClass: String);
begin
   raise ENotImplemented.Create('TWYSIWYMEditor.ToggleCustomSpan');
end;

procedure TWYSIWYMEditor.EnableLink(const aReference: String);
begin
   raise ENotImplemented.Create('TWYSIWYMEditor.EnableLink');
end;

procedure TWYSIWYMEditor.DisableLink;
begin
   raise ENotImplemented.Create('TWYSIWYMEditor.DisableLink');
end;

procedure TWYSIWYMEditor.InsertLineBreak;
begin
   raise ENotImplemented.Create('TWYSIWYMEditor.InsertLineBreak');
end;

procedure TWYSIWYMEditor.SetParagraphNormal;
begin
   raise ENotImplemented.Create('TWYSIWYMEditor.SetParagraphNormal');
end;

procedure TWYSIWYMEditor.SetParagraphHeading(aLevel: TWYSIWYMHeadingLevel);
begin
   raise ENotImplemented.Create('TWYSIWYMEditor.SetParagraphHeading');
end;

procedure TWYSIWYMEditor.SetParagraphVerse;
begin
   raise ENotImplemented.Create('TWYSIWYMEditor.SetParagraphVerse');
end;

procedure TWYSIWYMEditor.SetParagraphOrderedListItem(aIndent: Word);
begin
   raise ENotImplemented.Create('TWYSIWYMEditor.SetParagraphOrderedListItem');
end;

procedure TWYSIWYMEditor.SetParagraphUnorderedListItem(aIndent: Word);
begin
   raise ENotImplemented.Create('TWYSIWYMEditor.SetParagraphUnorderedListItem');
end;

procedure TWYSIWYMEditor.SetBlockQuote(aIndent: Word);
begin
   raise ENotImplemented.Create('TWYSIWYMEditor.SetBlockQuote');
end;

procedure TWYSIWYMEditor.SetParagraphCustom(const aClass: String);
begin
   raise ENotImplemented.Create('TWYSIWYMEditor.SetParagraphCustom');
end;

procedure TWYSIWYMEditor.InsertHorizontalRule;
begin
   raise ENotImplemented.Create('TWYSIWYMEditor.InsertHorizontalRule');
end;

procedure TWYSIWYMEditor.StartNewParagraph;
begin
   raise ENotImplemented.Create('TWYSIWYMEditor.StartNewParagraph');
end;

function TWYSIWYMEditor.GetBodyNode: TWYSIWYMNode;
begin
   raise ENotImplemented.Create('TWYSIWYMEditor.GetBodyNode');
end;

function TWYSIWYMEditor.GetNodeFirstChild(aNode: TWYSIWYMNode): TWYSIWYMNode;
begin
   raise ENotImplemented.Create('TWYSIWYMEditor.GetNodeFirstChild');
end;

function TWYSIWYMEditor.GetNodeNextSibling(aNode: TWYSIWYMNode): TWYSIWYMNode;
begin
   raise ENotImplemented.Create('TWYSIWYMEditor.GetNodeNextSibling');
end;

function TWYSIWYMEditor.GetNodeParent(aNode: TWYSIWYMNode): TWYSIWYMNode;
begin
   raise ENotImplemented.Create('TWYSIWYMEditor.GetNodeParent');
end;

function TWYSIWYMEditor.GetNodeKind(aNode: TWYSIWYMNode): TWYSIWYMNodeKind;
begin
   raise ENotImplemented.Create('TWYSIWYMEditor.GetNodeKind');
end;

function TWYSIWYMEditor.GetNodeParagraphKind(aNode: TWYSIWYMNode
  ): TWYSIWYMParagraphKind;
begin
   raise ENotImplemented.Create('TWYSIWYMEditor.GetNodeParagraphKind');
end;

function TWYSIWYMEditor.GetNodeSpanKind(aNode: TWYSIWYMNode): TWYSIWYMSpanKind;
begin
   raise ENotImplemented.Create('TWYSIWYMEditor.GetNodeSpanKind');
end;

procedure TWYSIWYMEditor.SetNodeParagraphKind(aNode: TWYSIWYMNode;
  aValue: TWYSIWYMParagraphKind);
begin
   raise ENotImplemented.Create('TWYSIWYMEditor.SetNodeParagraphKind');
end;

procedure TWYSIWYMEditor.SetNodeSpanKind(aNode: TWYSIWYMNode;
  aValue: TWYSIWYMSpanKind);
begin
   raise ENotImplemented.Create('TWYSIWYMEditor.SetNodeSpanKind');
end;

function TWYSIWYMEditor.GetNodeCustomClass(aNode: TWYSIWYMNode): String;
begin
   raise ENotImplemented.Create('TWYSIWYMEditor.GetNodeCustomClass');
end;

procedure TWYSIWYMEditor.SetNodeCustomClass(aNode: TWYSIWYMNode;
  const aValue: String);
begin
   raise ENotImplemented.Create('TWYSIWYMEditor.SetNodeCustomClass');
end;

function TWYSIWYMEditor.GetNodeLinkReference(aNode: TWYSIWYMNode): String;
begin
   raise ENotImplemented.Create('TWYSIWYMEditor.GetNodeLinkReference');
end;

procedure TWYSIWYMEditor.SetNodeLinkReference(aNode: TWYSIWYMNode;
  const aValue: String);
begin
   raise ENotImplemented.Create('TWYSIWYMEditor.SetNodeLinkReference');
end;

function TWYSIWYMEditor.GetNodeTextContent(aNode: TWYSIWYMNode): String;
begin
   raise ENotImplemented.Create('TWYSIWYMEditor.GetNodeTextContent');
end;

procedure TWYSIWYMEditor.SetNodeTextContent(aNode: TWYSIWYMNode;
  const aValue: String);
begin
   raise ENotImplemented.Create('TWYSIWYMEditor.SetNodeTextContent');
end;

function TWYSIWYMEditor.GetNodeHeadingLevel(aNode: TWYSIWYMNode
  ): TWYSIWYMHeadingLevel;
begin
   raise ENotImplemented.Create('TWYSIWYMEditor.GetNodeHeadingLevel');
end;

procedure TWYSIWYMEditor.SetNodeHeadingLevel(aNode: TWYSIWYMNode;
  aValue: TWYSIWYMHeadingLevel);
begin
   raise ENotImplemented.Create('TWYSIWYMEditor.SetNodeHeadingLevel');
end;

function TWYSIWYMEditor.GetNodeIndentLevel(aNode: TWYSIWYMNode): Word;
begin
   raise ENotImplemented.Create('TWYSIWYMEditor.GetNodeIndentLevel');
end;

procedure TWYSIWYMEditor.SetNodeIndentLevel(aNode: TWYSIWYMNode; aValue: Word);
begin
   raise ENotImplemented.Create('TWYSIWYMEditor.SetNodeIndentLevel');
end;

function TWYSIWYMEditor.GetNodeSelectionState(aNode: TWYSIWYMNode
  ): TNodeSelectionState;
begin
   raise ENotImplemented.Create('TWYSIWYMEditor.GetNodeSelectionState');
end;

function TWYSIWYMEditor.GetNodeSelectedText(aNode: TWYSIWYMNode): String;
begin
   raise ENotImplemented.Create('TWYSIWYMEditor.GetNodeSelectedText');
end;

procedure TWYSIWYMEditor.InsertNodeBefore(aNode: TWYSIWYMNode;
  aNewParent: TWYSIWYMNode; aNewSibling: TWYSIWYMNode);
begin
   raise ENotImplemented.Create('TWYSIWYMEditor.InsertNodeBefore');
end;

procedure TWYSIWYMEditor.DeleteNode(aNode: TWYSIWYMNode);
begin
   raise ENotImplemented.Create('TWYSIWYMEditor.DeleteNode');
end;

procedure TWYSIWYMEditor.SelectNode(aNode: TWYSIWYMNode; aInclusive: Boolean);
begin
   raise ENotImplemented.Create('TWYSIWYMEditor.SelectNode');
end;

procedure TWYSIWYMEditor.SelectBeforeNode(aNode: TWYSIWYMNode);
begin
   raise ENotImplemented.Create('TWYSIWYMEditor.SelectBeforeNode');
end;

procedure TWYSIWYMEditor.SelectAfterNode(aNode: TWYSIWYMNode);
begin
   raise ENotImplemented.Create('TWYSIWYMEditor.SelectAfterNode');
end;

procedure TWYSIWYMEditor.SelectNodeStart(aNode: TWYSIWYMNode);
begin
   raise ENotImplemented.Create('TWYSIWYMEditor.SelectNodeStart');
end;

procedure TWYSIWYMEditor.SelectNodeEnd(aNode: TWYSIWYMNode);
begin
   raise ENotImplemented.Create('TWYSIWYMEditor.SelectNodeEnd');
end;

procedure TWYSIWYMEditor.Undo;
begin
   raise ENotImplemented.Create('TWYSIWYMEditor.Undo');
end;

procedure TWYSIWYMEditor.Redo;
begin
   raise ENotImplemented.Create('TWYSIWYMEditor.Redo');
end;

procedure TWYSIWYMEditor.PasteFromClipboard;
begin
   raise ENotImplemented.Create('TWYSIWYMEditor.PasteFromClipboard');
end;

procedure TWYSIWYMEditor.CutToClipboard;
begin
   raise ENotImplemented.Create('TWYSIWYMEditor.CutToClipboard');
end;

procedure TWYSIWYMEditor.CopyToClipboard;
begin
   raise ENotImplemented.Create('TWYSIWYMEditor.CopyToClipboard');
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
   raise ENotImplemented.Create('TWYSIWYMEditor.WriteContentsTo');
end;

procedure TWYSIWYMEditor.LoadContentsFrom(aProvider: TWYSIWYMProvider);
begin
  // TODO: scan through the structure and put into the processor.
  raise ENotImplemented.Create('TWYSIWYMEditor.LoadContentsFrom');

end;

end.

