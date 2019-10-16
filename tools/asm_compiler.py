#!/usr/bin/python3
import sys
import argparse

from os import path


def decode_byte(val: str):
    try:
        if val.endswith('h'):
            return int(val[:-1], 16)
        if val.startswith('0x'):
            return int(val[2:], 16)
        if val.startswith('b'):
            return int(val.replace('_', '')[1:], 2)
    except ValueError:
        raise ValueError(f"Invalid binary '{val}'")
    if val.isdigit():
        i = int(val)
        if i > 255 or i < 0:
            raise ValueError(f"Invalid binary '{val}', unsigned int out of bounds")
        return i
    if (val.startswith('+') or val.startswith('-')) and val[1:].isdigit():
        i = int(val)
        if i > 127 or i < -128:
            raise ValueError(f"Invalid binary '{val}', signed int out of bounds")
        if i < 0:  # convert to unsigned
            i += 2**8
        return i
    if len(val) == 3 and ((val[0] == "'" and val[2] == "'") or (val[0] == '"' and val[2] == '"')):
        return ord(val[1])
    raise ValueError(f"Invalid binary '{val}'")


def is_reg(r):
    if r.startswith('$'):
        r = r[1:]
    return len(r) == 2 and (r == 'ra' or r == 'rb' or r == 'rc' or r == 're')


def decode_reg(r):
    rl = r.lower()
    if rl.startswith('$'):
        rl = rl[1:]
    if rl == 'ra':
        return 0
    if rl == 'rb':
        return 1
    if rl == 'rc':
        return 2
    if rl == 're':
        return 3
    raise ValueError(f"Invalid register name '{r}'")


def assemble(file):
    odata = []
    afile = open(file, 'r')
    failed = False
    refs = dict()
    for lnum, line in enumerate(afile.readlines()):
        lnum += 1  # Line numbers start from 1, not 0
        if '//' in line:
            line = line[:line.index('//')]
        if ':' in line:
            rsplit = line.split(':', 1)
            ref = rsplit[0]
            if not ref.isalnum():
                print(f"{file}:{lnum}: Invalid pointer reference '{ref}'")
                failed = True
                continue
            if ref in refs:
                print(f"{file}:{lnum}: Pointer reference '{ref}' is duplicated with {file}:{refs[ref][0]}")
                failed = True
                continue
            refs[ref] = [lnum, len(odata)]
            line = rsplit[1]
        line = line.replace('\n', '').replace('\r', '').replace('\t', '')
        line = line.strip(' ')
        if line == '':
            continue
        ops = line.split()
        instr = ops[0].upper()
        rops = 3
        if instr == 'CPY' or instr == 'COPY':
            iname = 'COPY'
            inibb = 0
        elif instr == 'ADD':
            iname = 'ADD'
            inibb = 1
        elif instr == 'SUB':
            iname = 'SUB'
            inibb = 2
        elif instr == 'AND':
            iname = 'AND'
            inibb = 3
        elif instr == 'OR':
            iname = 'OR'
            inibb = 4
        elif instr == 'XOR':
            iname = 'XOR'
            inibb = 5
        elif instr == 'GT' or instr == 'GRT':
            iname = 'GT'
            inibb = 6
        elif instr == 'EX' or instr == 'EXT':
            iname = 'EXT'
            inibb = 7
        elif instr == 'LW':
            iname = 'LW'
            inibb = 8
        elif instr == 'SW':
            iname = 'SW'
            inibb = 9
        elif instr == 'JEQ':
            iname = 'JEQ'
            rops = 4
            inibb = 10
        elif instr == 'JMP' or instr == 'JUMP':
            iname = 'JUMP'
            rops = 2
            inibb = 11
        else:
            if len(ops) == 1:
                try:
                    odata.append(decode_byte(ops[0]))
                    continue
                except ValueError:
                    pass
            print(f"{file}:{lnum}: Instruction '{ops[0]}' not recognised")
            failed = True
            continue
        if len(ops) != rops:
            print(f"{file}:{lnum}: {iname} instruction requires {rops - 1} arguments")
            failed = True
            continue
        try:
            if iname == 'JUMP':
                odata.append(inibb << 4)
                try:
                    odata.append(decode_byte(ops[1]))
                except ValueError:
                    if not ops[1].isalnum():
                        print(f"{file}:{lnum}: Invalid pointer reference '{ops[1]}'")
                        failed = True
                        continue
                    if ops[1] in refs:
                        odata.append(refs[ops[1]][1])
                    else:
                        refs[ops[1]] = [lnum, None]
                        odata.append(ops[1])
                continue

            rd = decode_reg(ops[1])
            if iname == 'COPY' and not is_reg(ops[2]):
                imm = decode_byte(ops[2])
                odata.append((inibb << 4) | (rd << 2) | rd)
                odata.append(int(imm))
                continue

            rs = decode_reg(ops[2])
            if iname == 'COPY' and rd == rs:
                print(f"{file}:{lnum}: {iname} cannot copy register to itself")
                failed = True
                continue

            odata.append((inibb << 4) | (rd << 2) | rs)
            if iname == 'JEQ':
                try:
                    odata.append(decode_byte(ops[3]))
                except ValueError:
                    if not ops[3].isalnum():
                        print(f"{file}:{lnum}: Invalid pointer reference '{ops[3]}'")
                        failed = True
                        continue
                    if ops[3] in refs:
                        odata.append(refs[ops[3]][1])
                    else:
                        refs[ops[3]] = [lnum, None]
                        odata.append(ops[3])
                continue
        except ValueError as e:
            print(f"{file}:{lnum}: {e}")
            failed = True
            continue

    afile.close()
    # Convert jumps
    for i, l in enumerate(odata):
        if isinstance(l, str):
            if refs[l][1] is None:
                print(f"{file}:{refs[l][0]}: Pointer reference '{l}' does not exist!")
                failed = True
                continue
            odata[i] = refs[l][1]

    return not failed, odata


if __name__ == '__main__':
    parser = argparse.ArgumentParser(description='Assembly compiler', add_help=True)
    parser.add_argument('file', help='Files to compile')
    parser.add_argument('-t', '--output_type', choices=['bin', 'mem', 'binary'], default='mem', help='Output type')
    parser.add_argument('-o', '--output', help='Output file')
    parser.add_argument('-f', '--force', action='store_true', help='Force override output file')
    args = parser.parse_args(sys.argv[1:])
    if not path.isfile(args.file):
        print(f'No file {args.file}!')
        sys.exit(1)

    output = args.output
    if not output:
        opath = path.dirname(args.file)
        bname = path.basename(args.file).rsplit('.', 1)[0]
        ext = '.out'
        if args.output_type == 'mem':
            ext = '.mem'
        elif args.output_type == 'bin':
            ext = '.bin'
        output = path.join(opath, bname + ext)
    if not args.force and path.isfile(output):
        print(f'Output file already exists {output}!')
        sys.exit(1)

    success, data = assemble(args.file)
    if success:
        print(f"Saving {args.output_type} data to {output}")
        with open(output, 'wb') as of:
            if args.output_type == 'binary':
                a = '\n'.join([format(i, '08b') for i in data])
                of.write(a.encode())
            elif args.output_type == 'mem':
                a = [format(i, '02x') for i in data]
                for i in range(int(len(a)/8)+1):
                    of.write((' '.join(a[i*8:(i+1)*8]) + '\n').encode())
            elif args.output_type == 'bin':
                of.write(bytes(data))
    else:
        print(f'Failed to compile {args.file}!')
        sys.exit(1)
    sys.exit(0)


