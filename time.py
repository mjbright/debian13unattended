#!/usr/bin/env python3

import os, sys
import time

USE_COLOUR=True
#COLOUR='\x1b[6;30;42m'
#COLOUR='\x1b[1;32;40m'
#COLOUR='\x1b[0;32;40m'
#COLOUR='\x1b[91m'
COLOUR='\x1b[92m'
ENDC='\x1b[0m'
#print('\x1b[6;30;42m' + 'Success!' + '\x1b[0m')

# Usage:
#   with just a command (normal usage):
#         ./time.py command ...
#     e.g.
#         ./time.py ls -altrR
#
#   OR with a start time provided, and a "command-label"
#         SAVED_EPOCHREALTIME=$EPOCHREALTIME
#         ... do something ...
#         ./time.py -s $SAVED_EPOCHREALTIME command-label ...
#     e.g.
#         SAVED_EPOCHREALTIME=$EPOCHREALTIME
#         ... do something ...
#         ./time.py -s $SAVED_EPOCHREALTIME ls -altrR
#     e.g.
#         SAVED_EPOCHREALTIME=$EPOCHREALTIME ; sleep 3; ./time.py -s $SAVED_EPOCHREALTIME sleeping
#
#   OR with a start & end times provided, and a "command-label"
#     e.g.
#         START_EPOCHREALTIME=$EPOCHREALTIME ; sleep 3; END_EPOCHREALTIME=$EPOCHREALTIME 
#         ./time.py -s $START_EPOCHREALTIME -e $END_EPOCHREALTIME sleeping

## -- Functions: --------------------------------------------------------------------------------

def die(msg):
    sys.stderr.write(f'{sys.argv[0]}: die - {msg}\n')
    sys.exit(1)

def took(label, end_ts, start_ts):
    # Difference between two timestamps
    delta = end_ts - start_ts

    days      = int(delta / (60 * 60 * 24))
    rem_secs  = delta - ( days * 60 * 60 * 24 )
    hours     = int(rem_secs / (60 * 60))
    rem_secs -= hours * 60 * 60
    mins      = int(rem_secs / 60)
    rem_secs -= mins * 60

    if USE_COLOUR:
        sys.stdout.write(COLOUR)
    if days > 0:
        print(f'Took [{delta:.2f}s]  {days}d {hours}h {mins}m {rem_secs:.2f}s: [{label}]')
    elif hours > 0:
        print(f'Took [{delta:.2f}s]  {hours}h {mins}m {rem_secs:.2f}s: [{label}]')
    elif mins > 0:
        print(f'Took [{delta:.2f}s]  {mins}m {rem_secs:.2f}s: [{label}]')
    else:
        print(f'Took  {rem_secs:.2f}s: [{label}]')
    if USE_COLOUR:
        sys.stdout.write(ENDC)

## -- Args: -------------------------------------------------------------------------------------

print(f'== { " ".join(sys.argv) }')
if len(sys.argv) < 2:
    die("Missing arguments")

exit_code = 0
if sys.argv[1] == '-s':
    if len(sys.argv) < 4:
        die("Missing arguments - '-s' option specified, expecting timestamp and command (or -e timestamp command) to follow")
    start_ts=sys.argv[2]

    if sys.argv[3] == '-e':
        if len(sys.argv) < 6:
            die("Missing arguments - '-s' & '-e' options specified, expecting timestamp and command")
        end_ts=sys.argv[4]
        end_ts=float(end_ts)
        command=" ".join(sys.argv[5:])
    else:
        end_ts=time.time()
        command=" ".join(sys.argv[3:])

    # print(f'Provided start time as {start_ts}')
    start_ts=float(start_ts)
    # print(f'End            time is {end_ts}')
else:
    command=" ".join(sys.argv[1:])

    # Run command:
    start_ts=time.time()
    #os.system( command )
    #exit_code = os.WEXITSTATUS(os.system(command))
    exit_value = os.system(command)
    exit_code = os.WEXITSTATUS(exit_value)
    #print(f'EXIT VALUE={exit_value} EXIT CODE={exit_code}')
    end_ts=time.time()

## -- Main: -------------------------------------------------------------------------------------


took(command, end_ts, start_ts)
#sys.exit(1)
sys.exit(exit_code)

# test: 5d, 7h, 23m, 46s
#delta = (60 * 60 * 24 * 5) + (60 * 60 * 7) + (60 * 23) + 46.4
#delta = (60 * 60 * 7) + (60 * 23) + 46.4
#delta = (60 * 23) + 46.4
#delta = 46.4
# f'{value:{width}.{precision}}'
#print('Difference is:', delta)

