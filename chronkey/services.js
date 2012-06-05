services = {
  "mldonkey": {
    "name": "MLDonkey",
    "method": "GET",
    "path": "/submit",
    "url_regexp": "\\.(torrent|ed2k)$",
    "params": "q=dllink+%url"
  },
  
  "qbittorrent": {
    "name": "QBitTorrent",
    "method": "POST",
    "path": "/command/download",
    "url_regexp": "\\.(torrent|ed2k)$",
    "params": "urls=%url"
  },

  "ktorrent": {
    "name": "KTorrent",
    "method": "GET",
    "path": "/action",
    "url_regexp": "\\.(torrent|ed2k)$",
    "params": "load_torrent=%url"
  }
}
