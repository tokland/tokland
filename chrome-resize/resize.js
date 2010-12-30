NodeList.prototype.toArray = function(fun) {
  return Array.prototype.slice.call(this, 0);
}

function getElementIdx(elt) {
  var count = 1;
  for (var sib = elt.previousSibling; sib; sib = sib.previousSibling) {
    if (sib.nodeType == 1 && sib.tagName == elt.tagName)
      count++;
  }  
  return count;
}

function getElementXPath(elt) {
  var path = "";
  for (; elt && elt.nodeType == 1; elt = elt.parentNode) {
    idx = getElementIdx(elt);
    xname = elt.tagName;
    if (idx > 1) 
      xname += "[" + idx + "]";
    path = "/" + xname + path;
  }
  return path;	
}

function evaluateXPath(aNode, aExpr) {
  var xpe = new XPathEvaluator();
  var nsResolver = xpe.createNSResolver(aNode.ownerDocument == null ?
    aNode.documentElement : aNode.ownerDocument.documentElement);
  var result = xpe.evaluate(aExpr, aNode, nsResolver, 0, null);
  var found = [];
  var res;
  while (res = result.iterateNext())
    found.push(res);
  return found;
}

$ = function(id) {  
  return document.getElementById(id);
}

HTMLElement.prototype.remove = function() {
  this.parentNode.removeChild(this);
}

Array.prototype.map = function(fun) {
  var res = new Array(this.length);
  var thisp = arguments[1];
  for (var i = 0; i < this.length; i++) {
    res[i] = fun.call(thisp, this[i], i, this);
  }
  return res;
};

function get_style(element, styles) {
  output = {}
  for (key in styles) {
    output[key] = element.style[key];
  }
  return output;
}

function set_style(element, styles) {
  for (key in styles) {
    element.style[key] = styles[key];
  }
}

/******************/
var ResizeExtension = {
  arrow_size: {width: 16, height: 16},
  hover_style: {border: "1px solid red"},
  selected_style: {border: "1px solid blue"},
  hotkey: "<Control><Shift>Z",
  
  /* State variables */
  mode: "disabled", // disabled | hover-select | selected | arrow
  mods: {},
  selected: null,
  selected_old_style: null,
  hover_element: null,
  arrow: null,
  arrow_info: null,

  set_arrow_position: function(arrow, selected) {
    arrow.style.top = (selected.offsetTop + selected.offsetHeight - this.arrow_size.height) + "px";
    arrow.style.left = (selected.offsetLeft + selected.offsetWidth - this.arrow_size.width) + "px";
    arrow.title = getElementXPath(selected) + (selected.id ? ("#" + selected.id) : "");
  },
  
  select_hover_element: function(element) {
    if (element) {
      this.selected_old_style = get_style(element, this.hover_style);
      set_style(element, this.hover_style);
    }  
  },
    
  on_document_mouseover: function(ev) {
    this.hover_element = ev.target;
    if (this.mode == "hover-select") {
      var element = ev.target;
      this.select_hover_element(element);
      this.selected = element;
    }  
  },
  
  on_document_mouseout: function(ev) {
    if (this.mode == "hover-select") {
      set_style(ev.target, this.selected_old_style)
      this.selected = null;
    }  
  },
  
  on_document_click: function(ev) {
    var element = ev.target;
    
    if (this.mode == "hover-select") {
      var arrow = $("resize-arrow-br") || this.create_arrow();
      set_style(element, this.selected_style)    
      this.mode = "selected";
      this.set_arrow_position(arrow, element);
      set_style(arrow, {display: "inline", cursor:  "se-resize"});
      this.selected = element;      
    } else if (this.mode == "selected") {
      var arrow = $("resize-arrow-br") || this.create_arrow();
      if (element != arrow) {
        var el = element;
        while (el != null && el != this.selected) {
          el = el.parentNode;
        }
        if (el == this.selected) {
          set_style(this.selected, this.selected_old_style)
          this.selected = (el.tagName == "BODY") ? element : el.parentNode;
          set_style(this.selected, this.selected_style)
          this.set_arrow_position(arrow, this.selected);
        } else {
          arrow.remove();
          set_style(this.selected, this.selected_old_style)
          //this.select_hover_element(this.hover_element);
          this.mode = "hover-select";
        }
      }
    }
  },

  on_document_mousemove: function(ev) {
    if (this.mode == "arrow") {
      var arrow = $("resize-arrow-br");
      var dx = ev.pageX - this.arrow_info.x; 
      var dy = ev.pageY - this.arrow_info.y;              
      set_style(this.selected, {
        width: (this.arrow_info.width + dx) + "px",
        height: (this.arrow_info.height + dy) + "px"
      });
      this.set_arrow_position(arrow, this.selected);
    }
  },
  
  on_document_mouseup: function(ev) {
    if (this.mode == "arrow") {
      var url = window.location.href;
      var xpath = getElementXPath(this.selected);
      var value = {width: this.selected.offsetWidth, height: this.selected.offsetHeight}
      if (this.options.mod_callback) {
        this.options.mod_callback(url, xpath, value);
      }  
      this.mode = "selected";
    }
  },

  on_arrow_mousedown: function(ev) {
    this.mode = "arrow";
    this.arrow_info = {
      x: ev.pageX, 
      y: ev.pageY,
      top: this.selected.offsetTop,
      left: this.selected.offsetLeft,
      width: this.selected.offsetWidth,
      height: this.selected.offsetHeight,              
    };
    ev.preventDefault();
  },                          

  create_arrow: function() {
    arrow = document.createElement("img");
    arrow.id = "resize-arrow-br";
    arrow.src = this.options.arrow_url;
    arrow.style.position = "absolute";
    document.body.appendChild(arrow);
    arrow.addEventListener("mousedown", this.on_arrow_mousedown.bind(this));
    return arrow;
  },
  
  on_document_keydown: function(ev) {
    var ascii = String.fromCharCode(ev.keyCode);
    var hotkey_ascii = this.hotkey.match(/>(\w)/)[1];    
    var re = /<(\w+)>/g;
    var modifiers = {control: false, shift: false, alt: false};    
    while (match = re.exec(this.hotkey)) {
      var key = match[1].toLowerCase();
      modifiers[key] = true;
    }
    if (modifiers.control == ev.ctrlKey &&
        modifiers.shift == ev.shiftKey &&
        modifiers.alt == ev.altKey && 
        hotkey_ascii.toUpperCase()) {
      if (this.mode == "disabled") {
        this.mode = "hover-select";
        this.select_hover_element(this.hover_element);
      } else {        
        set_style(this.selected, this.selected_old_style);        
        var arrow = $("resize-arrow-br");
        if (arrow) {
          arrow.remove();
        }
        this.mode = "disabled";        
      }
    }
  },
  
  update_mods: function(mods) {
    for (xpath in mods) {
      var opts = mods[xpath];
      var element = evaluateXPath(document.body, xpath)[0];
      if (element) {
        set_style(element, {width: opts.width + "px", height: opts.height + "px"});
      }
    }  
  },

  initialize: function(options) {
    this.options = options || {};
    this.hotkey = options.hotkey || this.hotkey;
    ["mouseover", "mouseout", "click", "mouseup", "mousemove", "keydown"].forEach(function(event_name) {
      document.addEventListener(event_name, this["on_document_" + event_name].bind(this));
    }.bind(this));
  }
};

function mod_callback(url, xpath, value) {
  chrome.extension.sendRequest({'update_mod': {url: url, xpath: xpath, value: value}});
}

if (chrome.extension) {
  chrome.extension.sendRequest({'get_options': true}, function(response) {
    var url = window.location.href;
    var options = {
      hotkey: response.hotkey, 
      mod_callback: mod_callback, 
      arrow_url: chrome.extension.getURL("arrow-br.png")
    };
    ResizeExtension.initialize(options);
    ResizeExtension.update_mods(JSON.parse(response.mods || '{}')[url]);
  });
} else {
  ResizeExtension.initialize({hotkey: "<Control><Shift>A", arrow_url: "arrow-br.png"});
  //document.addEventListener("DOMContentLoaded", ResizeExtension.update_mods.bind(ResizeExtension));
}
