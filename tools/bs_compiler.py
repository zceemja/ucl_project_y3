#!/usr/bin/python3

import argparse
import sys
from os import path


ch_add      = {'+'}
ch_sub      = {'-'}
ch_left     = {'<'}
ch_right    = {'>'}
ch_print    = {'.'}
ch_start    = {'['}
ch_stop     = {']'}

def compileBF(filename):
    program = []
    # Init program
    # $ra: Current value
    # $rb: ??
    # $rc: Memory pointer
    # $re: The +/- 1 value

    program.append("CPY $rc 0xFF")
    program.append("CPY $re 1")
    program.append("memInitStart:")
    program.append("JEQ $ra $rc memInitFinish")
    program.append("SW $rb $ra")
    program.append("ADD $ra $re")
    program.append("JMP memInitStart")
    program.append("memInitFinish:")
    program.append("CPY $rb 0")
    program.append("CPY $ra $rb")
    program.append("CPY $rc $rb")

    f = open(filename, 'r')
    pc = 0
    nc = 0
    lc = 0
    rc = 0
    nodePrev = []
    nodeCount = 0
    while 1:
        c = f.read(1)
        if c == '':
            break
        if c in ch_add:
            pc += 1
        elif pc > 0:
            program.append(f"CPY $re {pc}")
            pc = 0
            program.append("ADD $ra $re")

        if c in ch_sub:
            nc += 1
        elif nc > 0:
            program.append(f"CPY $re {nc}")
            nc = 0
            program.append("SUB $ra $re")

        if c in ch_right:
            rc += 1
        elif rc > 0:
            program.append("SW $ra $rc")
            program.append(f"CPY $re {rc}")
            program.append("ADD $rc $re")
            program.append("LW $ra $rc")
            rc = 0

        if c in ch_left:
            lc += 1
        elif lc > 0:
            program.append("SW $ra $rc")
            program.append(f"CPY $re {lc}")
            program.append("SUB $rc $re")
            program.append("LW $ra $rc")
            lc = 0

        if c in ch_print:
            program.append("CPY $re 0xFF")
            program.append("SW $ra $re")

        if c in ch_start:
            nodePrev.append(nodeCount)
            program.append(f"node{nodeCount:04d}s:")
            program.append(f"JEQ $ra $rb node{nodeCount:04d}e")
            nodeCount += 1

        if c in ch_stop:
            node = nodePrev.pop(-1)
            program.append(f"JMP node{node:04d}s")
            program.append(f"node{node:04d}e:")

    f.close()
    return program


if __name__ == '__main__':
    parser = argparse.ArgumentParser(description='Assembly compiler', add_help=True)
    parser.add_argument('file', help='Files to compile')
    # parser.add_argument('-t', '--output_type', choices=['asm', 'mem', 'binary'], default='mem', help='Output type')
    parser.add_argument('-o', '--output', help='Output file')
    parser.add_argument('-f', '--force', action='store_true', help='Force override output file')
    args = parser.parse_args(sys.argv[1:])
    if not path.isfile(args.file):
        print(f'No file {args.file}!')
        sys.exit(1)
    asm = compileBF(args.file)
    data = '\n'.join(asm)
    if args.output and (not path.isfile(args.output) or args.force):
        with open(args.output, 'w') as o:
            o.write(data)
    elif args.output is None:
        print(data)

