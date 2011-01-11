services = {
  "mldonkey": {
    "name": "MLDonkey",
    "method": "GET",
    "path": "/submit",
    "url_regexp": "\\.(torrent|e2dk)$",
    "params": "q=dllink+%url",
  },
  
  "qbittorrent": {
    "name": "QBitTorrent",
    "method": "POST",
    "path": "/command/download",
    "url_regexp": "\\.(torrent|e2dk)$",
    "params": "urls=%url",
  },
}
