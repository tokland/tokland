#!/usr/bin/python
import os, sys, time
import threading
import popen2
import applet
import gtk.gdk
import optparse

#############################################
class ClockApplet(applet.GnomeApplet):
	_clock_image = "/usr/local/share/pixmaps/clock.png"
	_name = "Clock"
	_description = "Clock Applet"
	
	def __init__(self):
		applet.GnomeApplet.__init__(self, self._name, self._description)
		items = [("about", "_About...", "gtk-about", self.on_about)]
		self.set_menu(items)
		self.clock = self.add_image(self._clock_image)
		self.add_timeout(1.0, self.on_timeout)
		self.clock.connect_signal("button_press_event", self.on_button)
				
	def on_button(self, widget, event):
		if event.type == gtk.gdk._2BUTTON_PRESS and event.button == 1:
			thread = threading.Thread(target=self.count)
			# So, in case the applet ends, stop also any running thread
			thread.setDaemon(True)
			thread.start()
	
	def count(self):
		for x in range(10):
			print "Just counting to 10...", x
			time.sleep(1)
		self.set_sensitive("about", False)
		
	def on_about(self):
		self.show_about(logo=self._clock_image, version="0.1", \
			license="Here comes the license (consider the GPL!)", \
			authors=["Arnau Sanchez (arnau@ehas.org)"])
		
	def on_timeout(self):
		now = ":".join(["%02d"%x for x in time.localtime()[3:6]])
		self.clock.set_tip(now)
		return True

##############################################
def main():
	usage = """usage: %s [applet-options] 

Just an example to show the use of the GnomeApplet class"""
	parser = optparse.OptionParser(usage)
	parser.add_option('', '--oaf-activate-iid', dest='iid', default='', metavar='FILE', type='string', help='Applet identifier')
	parser.add_option('', '--oaf-ior-fd', dest='fd', default='', metavar='FILE', type='string', help='Input/Output descriptor')
	options, args = parser.parse_args()
	applet = ClockApplet()
	if len(sys.argv) > 1:
		applet.run(options.iid)
	else: applet.run_window()
	
##############################################
if __name__ == '__main__':
	main()
