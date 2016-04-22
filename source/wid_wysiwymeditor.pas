unit wid_wysiwymeditor;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, RichMemo;

{
TODO: First things first, I need to set this up so it's easy to create the
correct widget backend for the widget. Look at the richmemopackage for how
this is done. Keep in mind that I can't do it exactly the same, until I
create my own component, since right now I've got to descend from the gtk2
widget set library. Or... do I? Maybe I can just copy what I need over to this one.

TODO: Then, I need to come up with the infrastructure for this. It needs to
have a bunch of commands for setting the structure (of a selection or current
block), getting the structure, serializing and deserializing, and establishing
the style for the code.


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

type
  TWYSIWYMMemo = class(TRichMemo)

  end;

implementation

end.

