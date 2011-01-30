var current_element = null;

function parse_hotkey_string(string) {
  var re = /<(\w+)>/g;
  var modifiers = {control: false, shift: false, alt: false};    
  while (match = re.exec(string)) {
    var key = match[1].toLowerCase();
    modifiers[key] = true;
  }  
  return {ascii: string.match(/>(\w)/)[1], modifiers: modifiers};
}

function up(element, tagName) {
  var upTagName = tagName.toUpperCase();
  while (element && (!element.tagName || element.tagName.toUpperCase() != upTagName)) {
    element = element.parentNode;
  }
  return element;
}

function on_document_keydown(options_key, hotkey, ev) {
  var ascii = String.fromCharCode(ev.keyCode);
  if (hotkey.modifiers.control == ev.ctrlKey &&
        hotkey.modifiers.shift == ev.shiftKey &&
        hotkey.modifiers.alt == ev.altKey && 
        hotkey.ascii.toUpperCase() == ascii) {
    if (current_element) {
      var link = up(current_element, "a");
      if (link && link.href) {
        var request = {action: "submitLink", options_key: options_key, href: link.href};
        chrome.extension.sendRequest(request, function(response) {
        });
      }
    }    
  }
}

document.addEventListener("mouseover", function(ev) {
  current_element = ev.target;
});

chrome.extension.sendRequest({action: "getServices"}, function(services) {
  for(options_key in services) {
    var config_hotkey = services[options_key].hotkey;
    if (config_hotkey) {
      var hotkey = parse_hotkey_string(config_hotkey);
      document.addEventListener("keydown", function(ev) {      
        return on_document_keydown(options_key, hotkey, ev);
      });
    }
  }
});

chrome.extension.onRequest.addListener(function(request, sender, sendResponse) {
  if (request.action == "getLinks") {
    var anchors = document.getElementsByTagName("a");
    var urls = {};
    var selection = window.getSelection();
    var regexp = new RegExp(request.regexp);
    for(var i = 0; i < anchors.length; i++) {
      if (request.only_selection && !selection.containsNode(anchors[i], true)) {
        continue;
      }
      if (anchors[i].href && anchors[i].href.match(regexp)) {
        var href = anchors[i].href;
        if (!urls[href]) {
          urls[href] = null;
        }
      }
    }
    sendResponse({urls: urls});   
  }
});
