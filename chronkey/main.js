function on_submit(info, tab, options) {
  var url = info.linkUrl;
  var template_url = options.url;
  if (!template_url) {
    alert("No template URL configured");
    return;
  }
  
  var service = services[options.service];
  var service_url = template_url.replace(new RegExp("/*$"), "") + 
                    service.path.replace("%url", escape(url));
  
  var xhr = new XMLHttpRequest();  
  xhr.onreadystatechange = function() {
    if (xhr.readyState == 4) {
      if (xhr.status == 200) {
        alert("URL submitted to " + options.service + ": " + url);
      } else {
        alert('Error HTTP response: ' + xhr.status);
      }
    }
  };
  
  var params = service.params.replace("%url", escape(url));
  if (service.method == "GET") {
    xhr.open("GET", service_url + (params ? ("?" + params) : ""), true);
    xhr.send();
  } else {
    xhr.open("POST", service_url, true);
    xhr.setRequestHeader('Content-Type', 'application/x-www-form-urlencoded');
    xhr.send(params);
  }
}

function add_menus() {
  var main = chrome.contextMenus.create({
    title: "Submit to service",
    contexts: ["link"],
  });
  var config = JSON.parse(localStorage["services"]);
  for (index in config) {
    var options = config[index];
    chrome.contextMenus.create({
      title: options.name,
      contexts: ["link"],
      parentId: main,
      onclick: function(info, tab) { on_submit(info, tab, options); }
    });
  }
}

chrome.extension.onRequest.addListener(
  function(request, sender, sendResponse) {
    if (request.update_menus) {
      chrome.contextMenus.removeAll()
      add_menus();
    }
  }
);

add_menus();
