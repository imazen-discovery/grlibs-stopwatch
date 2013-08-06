
# Timer module

import time

Timings = []

class TimerContext:
    def __init__(self, filename, desc):
        self.filename = filename
        self.desc = desc

    def __enter__(self):
        self.start = time.time()
        return self

    def __exit__(self, extype, value, traceback):
        global Timings

        end = time.time()
        Timings += [ [end - self.start, self.filename, self.desc] ]

        if traceback != None:
            print "Exception caught:", extype, "\n", value, "\n", traceback
            exit(1)


def printResults():
    global Timings
    f = "%s\t%s\t%.3f"
    total = 0

    for t in Timings:
        (elapsed, filename, desc) = t
        print f % (filename, desc, elapsed*1000)
        total += elapsed

    print f % ("", "Total:", total*1000)


