#!/usr/bin/python
import spynner
import os

browser = spynner.Browser(debug_level=spynner.INFO)
browser.set_url_filter(lambda op, s: os.path.splitext(s)[1] not in 
  ('.gif', '.jpg', '.png', '.css'))
#browser.show()
browser.load("http://www.lavanguardia.es/premium/login/epaper.html")
browser.fill("input[name=email]", "lapidario@gmail.com")
browser.fill("input[name=password]", "nurianuria")
browser.click("input[name=imageField]", True)
print browser.get_cookies()
browser.close()
