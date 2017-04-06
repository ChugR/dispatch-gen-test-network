#
# Program to emit configs and scripts to effect:
# - Create a test network of routers
# - Launch a sender
#   - You can run several of these
# - Launch a receiver
#   - You can run several of these
#
# The routers are chained in a line with the sender sending
# into the chain at one end and the receivers receiving at the other end.
#
# There may be N routers in the chain
#
import errno
import os
import sys
from datetime import datetime
import traceback
#import pdb

#
#
class ExitStatus(Exception):
    """Raised if a command wants a non-0 exit status from the script"""
    def __init__(self, status): self.status = status

#
#
def main_except(argv):
    #pdb.set_trace()
    """Given a pdml file name, send the javascript web page to stdout"""
    if len(sys.argv) < 1:
        sys.exit('Usage: %s n-routers' % sys.argv[0])


def main(argv):
    try:
        main_except(argv)
        return 0
    except ExitStatus, e:
        return e.status
    except Exception, e:
        type, value, tb = sys.exc_info()
        traceback.print_exc()
        return 1

if __name__ == "__main__":
    sys.exit(main(sys.argv))
