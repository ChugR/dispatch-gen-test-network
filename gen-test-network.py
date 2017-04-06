#!/usr/bin/env python
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
    if len(argv) < 2:
        es = ExitStatus('Usage: %s n-routers' % sys.argv[0])
        raise es

    # How many routers to configure?
    nRouters = int(argv[1])

    # Routers listeners all "look left" for incoming connections.
    # The first, A, opens port 5672 for senders to fill
    # The second, B, opens port 21000 for A's interrouter connection
    # The third, C, opens port 21001 for B's interrouter connection
    # ...
    # The last, N, opens port 2100x for the interrouter connection and 55672 for the receivers to drain
    #
    # It's really convenient if all these ports are available when the scripts are started up, for sure.
    #
    inListenPort = 5672
    outListenPort = 55672
    firstInterrouter = 21000

    # Where to put the generated files?
    odir = os.path.join(
        os.getcwd(),
        datetime.now().strftime('%Y-%m-%d_%H-%M-%S'))
    try:
        os.makedirs(odir)
    except OSError as e:
        raise  # exit on any error
    with open(os.path.join(mydir, filename), 'w') as d:
        d.writelines(list)


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
