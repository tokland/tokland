chrome.extension.onRequest.addListener(function(request, sender, sendResponse) {
  if (request.action == "getLinks") {
    var anchors = document.getElementsByTagName("a");
    var urls = {};
    var regexp = new RegExp(request.regexp);
    for(var i = 0; i < anchors.length; i++) {
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
