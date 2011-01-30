chrome.extension.onRequest.addListener(function(request, sender, sendResponse) {
  if (request.action == "getLinks") {
    var anchors = document.getElementsByTagName("a");
    var urls = [];
    var selection = window.getSelection();
    for(var i = 0; i < anchors.length; i++) {
      var anchor = anchors[i];
      if (request.only_selection && !selection.containsNode(anchor, true)) {
        continue;
      }
      if (anchor.href && urls.indexOf(anchor.href) < 0) {
        urls.push(anchor.href)
      }
    }
    sendResponse({urls: urls});   
  }
});
