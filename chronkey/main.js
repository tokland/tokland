function get_keys(obj) { 
  var ks = []
  for (k in obj) {
    if (obj.hasOwnProperty(k)) {
      ks.push(k);
    }
  }
  return ks;
};

function on_submit(info, tab, options) {
  var template_url = options.url;
  if (!template_url) {
    alert("No template URL configured");
    return;
  }

  var service = services[options.service];
  var urls = {} // {(url, http_code)}
  if (info.linkUrl) {
    urls[info.linkUrl] = null;
    send_url(service, template_url, urls, info.linkUrl);    
  } else if (info.pageUrl) {
    var request = {action: "getLinks", regexp: options.url_regexp, only_selection: !!info.selectionText};
    chrome.tabs.sendRequest(tab.id, request, function(response) {
      var urls = response.urls;
      if (get_keys(urls).length > 0) {
        for(url in urls) {
          send_url(service, template_url, urls, url);
        }
      } else {
        alert("No URLs found matching regular expression: " + options.url_regexp);
      }
    });  
  }
}

function send_url(service, template_url, urls, url) {
  var service_url = template_url.replace(new RegExp("/*$"), "") + 
                    service.path.replace("%url", escape(url));  

  var xhr = new XMLHttpRequest();    
  xhr.onreadystatechange = function() {
    if (xhr.readyState == 4) {
      urls[url] = xhr.status;
      for(url in urls) {
        if (!urls[url]) {
          return
        }
      }
      
      var successful = 0, error = 0, urls_keys = [];
      for (url in urls) {
        urls_keys.push(url);
        if ((urls[url] + "").match(/2../)) {
          successful++;
        } else {
          error++;
        }
      }
      message = urls_keys.length + " URL(s) submitted " + 
        "(ok: " + successful + ", error: " + error + ")" + "\n\n" + 
        urls_keys.join("\n")
      alert(message);        
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

var config = JSON.parse(localStorage["services"]);

function add_menus() {
  var main = chrome.contextMenus.create({
    title: "Chronkey" + (get_keys(config).length == 0 ? " (go to options page to add services)" : ""),
    contexts: ["page", "link"],
  });
  for (index in config) {
    var options = config[index];
    chrome.contextMenus.create({
      title: options.name,
      contexts: ["page", "link", "selection"],
      parentId: main,
      onclick: function(info, tab) {
        on_submit(info, tab, options); 
      }
    });
  }
}

chrome.extension.onRequest.addListener(
  function(request, sender, sendResponse) {
    if (request.action == "updateMenus") {
      chrome.contextMenus.removeAll()
      add_menus();
    } else if (request.action == "getServices") {
      sendResponse(JSON.parse(localStorage["services"]));
    } else if (request.action == "submitLink") {
      var options = config[request.options_key];
      var service = services[options.service];
      var template_url = options.url;
      var urls = {};
      urls[request.href] = null;      
      send_url(service, template_url, urls, request.href);
    }
  }
);

add_menus();
