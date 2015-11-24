
var createSimplepadEditor = (function() {

    // NMS: Removed undo redo since we can control this from the main window.    
    /*
    var UndoButton = MediumEditor.Extension.extend({
        name: 'undo',

        init: function () {
            this.button = this.document.createElement('button');
            this.button.classList.add('medium-editor-action');
            this.button.innerHTML = '<i class="fa fa-undo"></i>';
            this.button.title = 'Undo';
            
            this.on(this.button, 'click', this.handleClick.bind(this));
        },
        
        getButton: function () {
            return this.button;
        },
        
        handleClick: function(event) {
            event.preventDefault();
            event.stopPropagation();
        
            this.execAction('undo');
        }
    });
    
    var RedoButton = MediumEditor.Extension.extend({
        name: 'redo',

        init: function () {
            this.button = this.document.createElement('button');
            this.button.classList.add('medium-editor-action');
            this.button.innerHTML = '<i class="fa fa-repeat"></i>';
            this.button.title = 'Redo';
            
            this.on(this.button, 'click', this.handleClick.bind(this));
        },
        
        getButton: function () {
            return this.button;
        },
        
        handleClick: function(event) {
            event.preventDefault();
            event.stopPropagation();
        
            this.execAction('redo');
        }
    });*/
    
    var editors = {}
    
    var result = function(id) {
        var editor = new MediumEditor('#' + id,{
            extensions: {
         /*       'undo': new UndoButton(),
                'redo': new RedoButton()*/
            },
            toolbar: {
                buttons: [/*'undo','redo',*/
                          'bold','italic','subscript','superscript','removeFormat','anchor',
                          'h1','h2','h3','h4','quote',{
                              name: 'pre',
                              contentDefault: '<b class="fa fa-code"></b>',
                              classList: []
                          },
                          'unorderedlist','orderedlist','indent','outdent'],
                static: true,
                updateOnEmptySelection: true,
                align: "left",
                relativeContainer: document.body
            },
            anchorPreview: {
                showWhenToolbarIsVisible: true
            },
            imageDragging: false,
            placeholder: false
        });
        editors[id] = editor;
        // make sure the toolbar gets shown, otherwise we have "blank" toolbars constantly.
        editor.getExtensionByName('toolbar').showToolbar();
        editor.getExtensionByName('toolbar').hideToolbar = (function(oldFn) {
            
            return function() {
                // only hide the toolbar if in fullscreen.
                if (simplepad && simplepad.fullscreen) {
                    oldFn();
                }
            }
        })(editor.getExtensionByName('toolbar').hideToolbar.bind(editor.getExtensionByName('toolbar')));
        return editor;
    }
    
    result.getEditorById = function(id) {
        if (editors.hasOwnProperty(id)) {
            return editors[id];
        }
    }
    
    return result;
    
})();



