function get_selected_anchor() {
  if (document.activeElement.tagName == "A")
    return(document.activeElement);
}

// Refactor of http://james.padolsey.com/javascript/find-and-replace-text-with-javascript/
function find_text_recursive(searchNode, searchText) {
  var regex = typeof searchText === 'string' ?
              new RegExp(searchText, 'i') : searchText;
  var childNodes = (searchNode || document.body).childNodes;
  var cnLength = childNodes.length;
  var excludes = 'html,head,style,title,link,meta,script,object,iframe';
  
  while (cnLength--) {
    var currentNode = childNodes[cnLength];
    if (currentNode.nodeType === 1 &&
      (excludes + ',').indexOf(currentNode.nodeName.toLowerCase() + ',') === -1) {
      result = arguments.callee(currentNode, searchText);
      if (result)
        return result;
    }
    if (currentNode.nodeType !== 3 || !regex.test(currentNode.data) )
      continue;
    return {node: currentNode, index: currentNode.data.search(regex)}
  }
}

function up(element, tagName) {
  var upTagName = tagName.toUpperCase();
  while (element && (!element.tagName || element.tagName.toUpperCase() != upTagName)) {
    element = element.parentNode;
  }
  return element;
}

function process_search(search, search_index) {
  console.log("search: " + search);
  var selected = false;    
  var selected_anchor = get_selected_anchor();
  
  if (search.length > 0) {
    var matched_anchors = [], index;
    anchors = document.getElementsByTagName('a');
    
    for(index = 0; index < anchors.length; index++) {
      anchor = anchors[index];
      result = find_text_recursive(anchor, search);
      if (result) {
        matched_anchors.push(result);
      } 
    }
    if (matched_anchors.length > 0) {
      index = search_index % matched_anchors.length;
      if (index < 0)
        index += matched_anchors.length; 
      anchor = matched_anchors[index].node;
      up(anchor, 'a').focus();
      var selection = window.getSelection();
      selection.removeAllRanges();
      var range = document.createRange();
      var start = matched_anchors[index].index;
      range.setStart(anchor, start);
      range.setEnd(anchor, start + search.length);
      selection.addRange(range);
      selected = true;
    } 
  }
  if (selected_anchor && !selected)
    selected_anchor.blur();
}

function add_keyboard_listeners() {
  console.log("ta2");
  var search = "";
  var search_index = 0;
  var chars = "abcdefghijklmnopqrstuvwxyz0123456789";  
  var keycodes = {
    "backspace": 8,
    "tab": 9,
    "enter": 13,
    "escape": 27
  }
  
  window.addEventListener('keydown', function(ev) {
    var code = ev.keyCode;
    var selected_anchor = get_selected_anchor();    
    
    if (code == keycodes.backspace) {
      if (search) {
        search = search.substr(0, search.length-1)
        process_search(search, search_index);
      }
    } else if (code == keycodes.escape && search) {
      selection = window.getSelection();
      selection.removeAllRanges();
      search = "";
      search_index = 0;
    } else if (code == keycodes.enter && selected_anchor) {
      search = "";
      search_index = 0;
      selection = window.getSelection();
      selection.removeAllRanges();
      return;
    } else if (code == keycodes.tab && selected_anchor && search) {
      search_index += ev.shiftKey ? -1 : +1;
      process_search(search, search_index);
    } else {
      return;
    }
    
    ev.preventDefault();
    ev.stopPropagation();
  }, false);
  
  window.addEventListener('keypress', function(ev) {
    var code = ev.keyCode;
    var ascii = String.fromCharCode(code);
    
    if (!ev.altKey && !ev.metaKey && !ev.controlKey && ascii) {
      search += ascii;
      process_search(search, search_index);
    }
  }, false);
}

console.log("ta1");
//window.addEventListener('load', add_keyboard_listeners, false);
add_keyboard_listeners();
