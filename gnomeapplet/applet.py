#!/usr/bin/python

# Copyright (C) 2006 Arnau Sanchez
#
# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License
# as published by the Free Software Foundation; either version 2
# of the License or any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program; if not, write to the Free Software Foundation,
# Inc., 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301, USA.

import gnomeapplet, gnome.ui
import egg.trayicon
import gtk, gobject
import os, sys

# hacer una clase NotificationApplet
# usando las AppletImage
# dar acceso al menu
# y directamente al eventbox, sin hbox

##############################################
class AppletImage:
	"""A high-level image object for the applet.
	
	It contains a event_box (to be able to respond to mouse 
	click and give hints when the mouse is on it) and the 
	gtk-image itself."""
	def __init__(self, box, tip, image_path):
		self.box = box
		self.tip = tip
		self.image = gtk.Image()
		self.event_box = gtk.EventBox()
		self.event_box.add(self.image)
		box.pack_start(self.event_box)
		if image_path: 
			self.set_image(image_path)

	def set_image(self, path):
		self.image.set_from_file(path)

	def set_tip(self, s):
		self.tip.set_tip(self.event_box, s)

	def show(self):
		self.event_box.show_all()

	def hide(self):
		self.event_box.hide()

	def connect_signal(self, *args, **kwargs):
		self.event_box.connect(*args, **kwargs)

##############################################
class GnomeApplet:
	"""A high-level wrapper for gnomeapplet.
	
	This classe provides:
	
	- Run in window (test mode) or applet mode.
	- Several fields (images) with separated hints
	- Time-callbacks
	- Right-button mouse menu
	- A simple function to show the About window"""
	
	def __init__(self, name, description):
		self.__name = name
		self.__description = description
		self.__gapplet = None
		self.__box = gtk.HBox()
		self.__packed = {}
		self.__tips = gtk.Tooltips()
		self.__tips.enable()
		self.__menu_callbacks = {}
		self.__menu_verbs = []
		self.__menu_xml = []
		self.__images = []
	
	def __factory_callback(self, applet, iid):
		self.__applet_init(applet)
		return True

	def __applet_init(self, applet):
		self.__gapplet = applet
		applet.add(self.__box)
		applet.connect("change-background",self.__panel_bg)
		self.__setup_menu()
		applet.show_all()

	def __menu_callback(self, uiobject, verb):
		data = self.__menu_callbacks[verb]
		data[0](*data[1:])

	def __panel_bg(self, applet, bg_type, color, pixmap):
		rc_style = gtk.RcStyle()
		applet.set_style(None)
		applet.modify_style(rc_style)
		event_boxes = [x.event_box for x in self.__images]
		for eb in event_boxes:
			eb.set_style(None)
			eb.modify_style(rc_style)
		if bg_type == gnomeapplet.PIXMAP_BACKGROUND:
			style = applet.get_style()
			style.bg_pixmap[gtk.STATE_NORMAL] = pixmap
			applet.set_style(style)
			for eb in event_boxes:
				eb.set_style(style)
		if bg_type == gnomeapplet.COLOR_BACKGROUND:
			applet.modify_bg(gtk.STATE_NORMAL, color)
			for eb in event_boxes:
				eb.modify_bg(gtk.STATE_NORMAL, color)

	def __setup_menu(self):
		if self.__gapplet:
			self.__gapplet.setup_menu("\n".join(self.__menu_xml), \
				self.__menu_verbs, None)

	# Public interface
	
	def run(self, factory):
		gnomeapplet.bonobo_factory(factory, \
			gnomeapplet.Applet.__gtype__, self.__description, "0", \
			self.__factory_callback)

	def run_window(self):
		window = gtk.Window(gtk.WINDOW_TOPLEVEL)
		window.connect("destroy", gtk.main_quit)
		self.__applet_init(gnomeapplet.Applet())
		self.__gapplet.reparent(window)
		window.show_all()
		gtk.main()

	def add_timeout(self, tseconds, callback, *args):
		gobject.timeout_add(int(1000*tseconds), callback, *args)
				
	def set_menu(self, items):
		self.__menu_xml = ['<popup name="button3">']
		for item in items:
			verb, label, pixname = item[:3]
			callback = item[3:]
			if pixname.find("gtk-") == 0 or pixname.find("gnome-") == 0:
				pixtype = "stock"
			else: pixtype = "filename"
			self.__menu_xml.append('<menuitem name="%s" verb="%s" \
				label="%s" pixtype="%s" pixname="%s"/>'
				%(verb, verb, label, pixtype, pixname))
			self.__menu_callbacks[verb] = callback
			self.__menu_verbs.append((verb, self.__menu_callback))
		self.__menu_xml.append('</popup>')	
		self.__setup_menu()
			
	def set_sensitive(self, menu_verb, value):
		popup = self.__gapplet.get_popup_component()
		s = {False: "0", True: "1"}[value]
		popup.set_prop("/commands/"+menu_verb, "sensitive", s)
	
	def add_image(self, image_path=None, show=True):
		image = AppletImage(self.__box, self.__tips, image_path)
		self.__images.append(image)
		if show: 
			image.show()
		return image
					
	def show_about(self, logo, version, license, authors):
		about = gnome.ui.About(self.__name, version, license, \
			self.__description, authors, [""], "", \
			gtk.gdk.pixbuf_new_from_file(logo))
		about.show()

#############################################
class ClockApplet(GnomeApplet):
	_clock_image = "clock.png"
	
	def __init__(self):
		GnomeApplet.__init__(self, "Clock", "Clock applet")
		items = [("about", "_About...", "gtk-about", self.on_about)]
		self.set_menu(items)
		self.clock = self.add_image(self._clock_image)
		self.add_timeout(1.0, self.on_timeout)
		
	def on_about(self):
		self.show_about(logo=self._clock_image, version="0.1", \
			license="Here comes the license (consider the GPL!)", \
			authors=["Arnau Sanchez (arnau@ehas.org)"])
		
	def on_timeout(self):
		import time
		now = ":".join(["%02d"%x for x in time.localtime()[3:6]])
		self.clock.set_tip(now)
		return True

##############################################
def main():
	import optparse
	name = os.path.basename(sys.argv[0])
	usage = """usage: %s [applet-options] 

Just an example to show the use of the GnomeApplet class"""%name
	parser = optparse.OptionParser(usage)
	parser.add_option('', '--oaf-activate-iid', dest='iid', default='', \
		metavar='IDENTIFIER', type='string', help='Applet identifier')
	parser.add_option('', '--oaf-ior-fd', dest='fd', default='', \
		metavar='FD', type='string', help='Input/Output file descriptor')
	options, args = parser.parse_args()
	applet = ClockApplet()
	if len(sys.argv) > 1:
		applet.run(options.iid)
	else: applet.run_window()
	
##############################################
if __name__ == '__main__':
	main()
