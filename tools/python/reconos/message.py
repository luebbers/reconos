
import sys, os

beVerbose = False

def setVerbose(x):
    if x in (None, False, 0):
        beVerbose = False
    else:
        beVerbose = True

def error(msg):
    print >> sys.stderr, os.path.basename(sys.argv[0]) + ": " + msg
    sys.exit(1)

def info(msg):
    if beVerbose:
        print >> sys.stderr, os.path.basename(sys.argv[0]) + ": " + msg

def warning(msg):
    print >> sys.stderr, os.path.basename(sys.argv[0]) + ": " + msg

