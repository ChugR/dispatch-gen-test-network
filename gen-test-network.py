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
import stat
import sys
from datetime import datetime
import traceback
#import pdb

#
#
class ExitStatus(Exception):
    """Raised if a command wants a non-0 exit status from the script"""
    def __init__(self, status): self.status = status

def chmodExec(path):
    st = os.stat(path)
    os.chmod(path, st.st_mode | stat.S_IXUSR | stat.S_IXGRP | stat.S_IXOTH)

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
    #               opens connector to 21000 to next (B)
    # The second, B, opens port 21000 for A's interrouter connection
    #                opens connector to 21002
    # The third, C, opens port 21001 for B's interrouter connection
    # ...
    # The last, N, opens port 2100x for the interrouter connection and 55672 for the receivers to drain
    #
    #       0 A            1 B
    #       +------+       +-------+
    #    L: 5672         L: 21000
    #           C: 21000        C: 21001
    #         addrs
    # It's really convenient if all these ports are available when the scripts are started up, for sure.
    #
    inListenPort = 5672
    outListenPort = 55672
    firstInterrouter = 21000
    targetQueue = "q1"

    # Q: Where to put the generated files? A: odir
    od = "%s_%d" % (datetime.now().strftime('%Y-%m-%d_%H-%M-%S'), nRouters)
    odir = os.path.join(os.getcwd(), od)
    try:
        os.makedirs(odir)
    except OSError as e:
        raise  # exit on any error

    # Loop to generate router configs
    for ri in range(0, nRouters):
        rid = chr(ord('A') + ri)
        filename = "%c.conf" % rid
        with open(os.path.join(odir, filename), 'w') as d:
            d.write("# Generated file\n")
            d.write("router {\n")
            d.write("    mode: interior\n")
            d.write("    id: Router.%s\n" % rid)
            d.write("}\n")
            d.write("\n")
            if ri == 0:
                # First router gets native listener and addresses
                d.write("listener {\n")
                d.write("    host: 127.0.0.1\n")
                d.write("    port: %s\n" % str(inListenPort))
                d.write("    authenticatePeer: no\n")
                d.write("}\n")
                d.write("\n")
                d.write("address {\n")
                d.write("    prefix: %s\n" % targetQueue)
                d.write("    distribution: closest\n")
                d.write("}\n")
                d.write("\n")
            if ri > 0:
                # IR Listener looks left
                d.write("listener {\n")
                d.write("    host: 127.0.0.1\n")
                d.write("    port: %s\n" % str(firstInterrouter + ri - 1))
                d.write("    authenticatePeer: no\n")
                d.write("    role: inter-router\n")
                d.write("}\n")
                d.write("\n")
            if ri < nRouters - 1:
                # IR Connector looks right
                d.write("connector {\n")
                d.write("    name: INTER_ROUTER\n")
                d.write("    host: 127.0.0.1\n")
                d.write("    port: %s\n" % (firstInterrouter + ri))
                d.write("    role: inter-router\n")
                d.write("}\n")
                d.write("\n")
            if ri == nRouters - 1:
                # Last router gets native listener
                d.write("listener {\n")
                d.write("    host: 127.0.0.1\n")
                d.write("    port: %s\n" % str(outListenPort))
                d.write("    authenticatePeer: no\n")
                d.write("}\n")
            # all routers get logging
            lfn = "%s.log" % rid
            d.write("log {\n")
            d.write("    module: DEFAULT\n")
            d.write("    enable: info+\n")
            d.write("    output: %s\n" % os.path.join(odir, lfn))
            d.write("}\n")

    # Emit the qdr runner script
    pathqdr = os.path.join(odir, "run-qdrs.sh")
    with open(pathqdr, 'w') as d:
        d.write("#!/bin/bash\n")
        d.write("\n")
        d.write("# Environment for python/proton/n/stuff\n")
        d.write("source ~/bin/dispatch-setup.sh\n")
        d.write("\n")
        d.write("DEVROOT=/home/chug/git/qpid-dispatch\n")
        d.write("\n")
        d.write("# launch\n")
        # loop to launch
        pids = []
        for ri in range(0, nRouters):
            rid = chr(ord('A') + ri)
            pidname = "pid%c" % rid
            pids.append("$%s" % pidname)
            d.write("${DEVROOT}/build/router/qdrouterd -c `pwd`/%c.conf -I ${DEVROOT}/python &\n" % rid)
            d.write("%s=$!\n" % pidname)
        d.write("\n")

        # shutdown hint
        d.write("echo  to shut down routers execute: kill %s\n" % " ".join(pids))

    # Emit a sender script
    pathsndr = os.path.join(odir, "sender.sh")
    with open(pathsndr, 'w') as d:
        d.write("#!/bin/bash\n")
        d.write("\n")
        d.write("# Environment for python/proton/n/stuff\n")
        d.write("source ~/bin/dispatch-setup.sh\n")
        d.write("\n")
        d.write("/home/chug/git/qpid-proton/build/examples/cpp/simple_send -a amqp://127.0.0.1:%s/%s $1\n" % (str(inListenPort), targetQueue))


    # Emit a receiver script
    pathrcvr = os.path.join(odir, "receiver.sh")
    with open(pathrcvr, 'w') as d:
        d.write("#!/bin/bash\n")
        d.write("\n")
        d.write("# Environment for python/proton/n/stuff\n")
        d.write("source ~/bin/dispatch-setup.sh\n")
        d.write("\n")
        d.write("/home/chug/git/qpid-proton/build/examples/cpp/simple_recv -a amqp://127.0.0.1:%s/%s $1\n" % (str(outListenPort), targetQueue))

    # Make the scripts executable
    chmodExec(pathqdr)
    chmodExec(pathsndr)
    chmodExec(pathrcvr)

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
