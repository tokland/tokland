$ = function(id) {
  return document.getElementById(id);
}
      
function set_feedback(msg) {
  var feedback = document.getElementById("feedback");
  feedback.innerHTML = "<i>" + msg + "</i>";
  setTimeout(function() {
    feedback.innerHTML = "";
  }, 1000);
}
   
function toArray(object) {
  return([].slice.call(object, 0));
}

function save_options() {
  config = {}
  var services = document.getElementById("services").getElementsByClassName("service");
  var errors = false;
  toArray(services).forEach(function(form, index) {
    function check_field(input) {
      if (!input.value) {
        input.className = "error";
        return false;
      } else {
        input.className = "";
        return true;
      }   
    }
    if (!check_field(form.name))
      errors = true;
    if (!check_field(form.url))
      errors = true;
    config[index] = {
      service: form.service.value, 
      name: form.name.value, 
      url: form.url.value,
    };
  });
  if (!errors) {
    localStorage["services"] = JSON.stringify(config);
    set_feedback("Options saved");
    chrome.extension.sendRequest({'update_menus': true})
  } else {
    set_feedback("Errors found, cannot save");
  }
}

function onload() {
  for (key in services) {
    var option = document.createElement("option");
    option.text = services[key].human_name;
    option.value = key;        
    $('add').options.add(option);
  }
  restore_options();
}

function restore_options() {
  config = JSON.parse(localStorage["services"]);
  for (index in config) {
    add(config[index]);
  }
}

function add(options) {
  var namespace = {
    name: options.name || "",
    url: options.url || "http://user:password@server:port",
    service_name: services[options.service].human_name, 
    service: options.service,
  };
  
  var html = $('service_template').innerHTML;
  for (key in namespace) {
    html = html.replace(new RegExp("%"+key+"%", "g"), namespace[key]);
  }
  var div = document.createElement("div");
  div.innerHTML = html;
  $('services').appendChild(div); 
}

function remove(link) {
  parent = link.parentElement;
  parent.parentElement.removeChild(parent);
}
