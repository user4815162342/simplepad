
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
            return true;
        }
    }
    
    var choiceAttr = function(choices) {
        return function(node,name,value,error) {
            if (choices.indexOf(value) < 0) {
                error("Attribute '" + name + "' has an invalid value '" + value + "'; context: " + nodePath(node));
            } else {
                return true;
            }
        }
    }
    
    var styleAttr = function(attributes) {
        return function(node,name,value,error) {
            var result = '';
            var styles = value.split(';');
            for (var i = 0; i < styles.length - 1; i += 1) {
                var style = styles[i].split(':');
                var styleVal = style[1].trim();
                var style = style[0].trim();
                if (attributes.hasOwnProperty(style)) {
                    if (attributes[style](node,style,styleVal,error)) {
                        result = result + style + ':' + styleVal + ';';
                    }
                } else {
                    error("Style property '" + style + "' not allowed here: " + nodePath(node));
                }
            }
            return result;
        }
    };
    
    var pixelAttr = function() {
        return function(node,name,value,error) {
            if (isNaN(parseInt(value))) {
                error("Style property '" + name + "' has an invalid value '" + value + "'; context: " + nodePath(node));
            } else {
                return true;
            }
        }
    }
    
    var integerAttr = function() {
        return function(node,name,value,error) {
            if (isNaN(parseInt(value))) {
                error("Attribute '" + name + "' has an invalid value '" + value + "'; context: " + nodePath(node));
            } else {
                return true;
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
        return function(node,error) {
            Array.prototype.slice.call(node.attributes, 0).forEach(function(attr) {
                var value;
                if (attributes.hasOwnProperty(attr.name)) {
                    value = attributes[attr.name](node,attr.name,attr.value,error);
                } else if (defaultAttributes.hasOwnProperty(attr.name)) {
                    value = defaultAttributes[attr.name](node,attr.name,attr.value,error);
                } else {
                    error("Attribute '" + attr.name + "' not allowed here: " + nodePath(node));
                }
                if (value) {
                    node.setAttribute(attr.name,value);
                } else {
                    node.removeAttribute(attr.name);
                }
            });
            var child;
            if (node.hasChildNodes()) {
                if (childContext) {
                    var childNodes = Array.prototype.slice.call(node.childNodes, 0);
                    for (var i = 0; i < childNodes.length; i += 1) {
                        childContext(childNodes[i],error);
                    }
                } else {
                    error("Node must be empty: " + nodePath(node));
                    while (node.firstChild) {
                        node.removeChild(node.firstChild);
                    }
                }
            }
        }
    }

    var context = function(allowText) {
        var tags = {};
        var result = function(node,error) {
            switch (node.nodeType) {
                case Node.TEXT_NODE:
                    if ((!allowText) && (text.trim() !== "")) {
                        error("Text not allowed here: " + nodePath(node.parentElement));
                        node.remove();
                    } 
                    break;
                case Node.ELEMENT_NODE:
                    var tagName = node.tagName.toLowerCase();
                    if (tags.hasOwnProperty(tagName)) {
                        tags[tagName](node,error);
                    } else {
                        error("Tag '" + tagName + "' not allowed here: " + nodePath(node.parentElement));
                        node.remove();
                    }
                    break;
                default:
                    // I'm going to just ignore anything else.
                    error("Invalid node: " + node.nodeName);
                    node.parentNode.removeChild(node);
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
    flowContext.tag(["a","em","strong","code","sub","sup","i","b","span","br"],textContext);
    
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
    
    
    return function(html,err) {
        
        if (typeof err !== "function") {
            err = function(message) {
               throw new Error(message);
            }
        }
        
        var input = document.createElement('div');
        // add a flag to avoid getting out of the document for some reason.
        input.ftmroot = true;
        input.innerHTML = html;

        var childNodes = Array.prototype.slice.call(input.childNodes, 0);
        for (var i = 0; i < childNodes.length; i += 1) {
            flowContext(childNodes[i],err);
        }
        
        return input.innerHTML;
        
        
    }
})();
