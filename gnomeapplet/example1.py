#!/usr/bin/python
import os, sys, time
import threading
import applet
import optparse

#############################################
class ClockApplet(applet.GnomeApplet):
	_clock_image = "/usr/local/share/pixmaps/clock.png"
	_name = "Clock"
	_description = "Clock Applet"
	
	def __init__(self):
		applet.GnomeApplet.__init__(self, self._name, self._description)
		self.clock = self.add_image(self._clock_image)
		self.add_timeout(1.0, self.on_timeout)
					
	def on_timeout(self):
		now = ":".join(["%02d"%x for x in time.localtime()[3:6]])
		self.clock.set_tip(now)
		return True

##############################################
def main():
	name = os.path.basename(sys.argv[0])
	usage = """usage: %s [applet-options] 

Just an example to show the use of the GnomeApplet class"""%name
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
