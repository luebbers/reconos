#
#  LogWindowController.py
#  rsimgui
#

from objc import YES, NO, IBAction, IBOutlet
from Foundation import *
from AppKit import *

class LogWindowController(NSWindowController):
    logView = IBOutlet()
    
    # handle log messages from simulator
    def write_(self, text):
        self.logView.textStorage().mutableString().appendString_(text)
        # scroll to end of textview
        range = NSMakeRange(self.logView.string().length(), 0)
        self.logView.scrollRangeToVisible_(range)
        self.logView.setFont_(NSFont.fontWithName_size_("Monaco", 10))

    def write(self, text):
        self.write_(text)


        
    def clearLog_(self, sender):
        self.logView.setString_("")
