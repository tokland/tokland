services = {
  "mldonkey": {
    "method": "GET",
    "path": "/submit",
    "params": "q=dllink+%url",
  },
  "qbittorrent": {
    "method": "POST",
    "path": "/command/download",
    "params": "urls=%url",
  },
}
