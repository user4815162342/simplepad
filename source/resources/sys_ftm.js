
var simplepadFTMValidate = (function() {
    
    // TODO: I need to space the output nicely... I wonder if I were to produce HTML instead if it would work.
    
    var nodePath = function(node) {
        var result = "";
        while ((node != null) && (!node.ftmroot)) {
           result = node.tagName + " > " + result;
           node = node.parentElement; 
        }
        return result;
    }
    
    var textAttr = function() {
        return function(node,name,value) {
            // almost anything is valid here...
        }
    }
    
    var choiceAttr = function(choices) {
        return function(node,name,value) {
            if (choices.indexOf(value) < 0) {
                throw new Error("Attribute '" + name + "' has an invalid value '" + value + "'; context: " + nodePath(node));
            }
        }
    }
    
    var styleAttr = function(attributes) {
        return function(node,name,value) {
            var result = "";
            var styles = value.split(';');
            for (var i = 0; i < styles.length - 1; i += 1) {
                var style = styles[i].split(':');
                var styleVal = style[1].trim();
                var style = style[0].trim();
                if (attributes.hasOwnProperty(style)) {
                    attributes[style](node,style,styleVal);
                } else {
                    throw new Error("Style property '" + style + "' not allowed here: " + nodePath(node));
                }
            }
            return result;
        }
    };
    
    var pixelAttr = function() {
        return function(node,name,value) {
            if (isNaN(parseInt(value))) {
                throw new Error("Style property '" + name + "' has an invalid value '" + value + "'; context: " + nodePath(node));
            }
        }
    }
    
    var integerAttr = function() {
        return function(node,name,value) {
            if (isNaN(parseInt(value))) {
                throw new Error("Attribute '" + name + "' has an invalid value '" + value + "'; context: " + nodePath(node));
            }
        }
    }
    
    
    var defaultAttributes = {
        id: textAttr(),
        class: textAttr(),
        "data-ftm-version": choiceAttr(["1.0"])
    }
    
    var tag = function(attributes,childContext) {
        attributes = attributes || {};
        return function(node) {
            Array.prototype.forEach.call(node.attributes,function(attr) {
                if (attributes.hasOwnProperty(attr.name)) {
                    attributes[attr.name](node,attr.name,attr.value);
                } else if (defaultAttributes.hasOwnProperty(attr.name)) {
                    defaultAttributes[attr.name](node,attr.name,attr.value);
                } else {
                    throw new Error("Attribute '" + attr.name + "' not allowed here: " + nodePath(node));
                }
            });
            var child;
            if (child = node.firstChild) {
                if (childContext) {
                    for (;!!child; child = child.nextSibling) {
                        childContext(child);
                    }
                } else {
                    throw new Error("Node must be empty: " + nodePath(node));
                }
            }
        }
    }

    var context = function(allowText) {
        var tags = {};
        var result = function(node) {
            switch (node.nodeType) {
                case Node.TEXT_NODE:
                    if ((!allowText) && (text.trim() !== "")) {
                        throw new Error("Text not allowed here: " + nodePath(node.parentElement));
                    } 
                    break;
                case Node.ELEMENT_NODE:
                    var tagName = node.tagName.toLowerCase();
                    if (tags.hasOwnProperty(tagName)) {
                        tags[tagName](node);
                    } else {
                        throw new Error("Tag '" + tagName + "' not allowed here: " + nodePath(node.parentElement));
                    }
                    break;
                default:
                    // I'm going to just ignore anything else.
                    throw new Error("Invalid node type: " + node.nodeType);
            }
        };
        
        result.tag = function(name,attributes,childContext) {
            if (name instanceof Array) {
                name.forEach(function(name) {
                    this.tag(name,attributes,childContext);
                }.bind(this))
            } else if (typeof attributes === "function") {
                if (attributes.tag) {
                    tags[name] = attributes.getTag(name);
                } else {
                    tags[name] = attributes;
                }
            } else {
                tags[name] = tag(attributes,childContext);
            }
        };
        
        result.getTag = function(name) {
            if (tags.hasOwnProperty(name)) {
                return tags[name];
            }
        }
        
        return result;
    }
    
    var textContext = context(true);
    textContext.tag("a",{
            href: textAttr()
        },textContext);
    var text = tag();
    textContext.tag(["em","strong","code","sub","sup","i","b","span"],{},textContext);
    textContext.tag("br");
    textContext.tag("img",{
           src: textAttr(),
           alt: textAttr(),
           style: styleAttr({
               width: pixelAttr(),
               height: pixelAttr()
           })
        })
        
    var flowContext = context(true);
    flowContext.tag(["a","em","strong","code","sub","sup","i","b","span"],textContext);
    
    var oListContext = context(true);
    oListContext.tag("li",{ value: integerAttr()},flowContext);
    
    var uListContext = context(true);
    uListContext.tag("li",{ },flowContext);
    
    var tableRowContext = context(true);
    tableRowContext.tag(["th","td"],{
        rowSpan: integerAttr(),
        colSpan: integerAttr()
    },flowContext);
    
    var tableBodyContext = context(true);
    tableBodyContext.tag("tr",{},tableRowContext);
    
    var tableContext = context(true);
    tableContext.tag("tr",{},tableRowContext);
    tableContext.tag("tbody",{},tableBodyContext);
    
    flowContext.tag(["h1","h2","h3","h4","h5","h6","p","pre","blockquote"],{},textContext);
    flowContext.tag("ol",{ start: integerAttr() },oListContext);
    flowContext.tag("ul",{},uListContext);
    // NOTE: This is non-standard. However, the editor appears to do this
    // by default for sublists, and I don't feel like trying to fix that.
    oListContext.tag(["ol","ul"],flowContext);
    uListContext.tag(["ol","ul"],flowContext);
    flowContext.tag("hr");
    flowContext.tag("img",{
           src: textAttr(),
           alt: textAttr(),
           style: styleAttr({
               width: pixelAttr(),
               height: pixelAttr(),
               float: choiceAttr(["left","right"]),
               clear: choiceAttr(["left","right","none"])
           })
        });
        
    flowContext.tag("table",{},tableContext);
    
    
    return function(html) {
        
        var output = "";
        var input = document.createElement('div');
        // add a flag to avoid getting out of the document for some reason.
        input.ftmroot = true;
        input.innerHTML = html;
        
        for (var child = input.firstChild; child; child = child.nextSibling) {
            output += flowContext(child);
        }
        
        return output;
        
    }
})();
