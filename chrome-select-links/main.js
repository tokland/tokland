function on_click(info, tab) {
  var request = {action: "getLinks", only_selection: !!info.selectionText};
  chrome.tabs.sendRequest(tab.id, request, function(response) {
    alert(response.urls.join("\n"));
  });
}
  
function add_menus() {
  chrome.contextMenus.create({
    title: "Get links",
    contexts: ["selection", "page"],
    onclick: function(info, tab) {
      on_click(info, tab); 
    }
  });
}

add_menus();
