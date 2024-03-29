#!/usr/bin/python3

import re
import math
import traceback
from typing import Dict, List

label_re = re.compile(r"^[\w$#@~.?]+$", re.IGNORECASE)
hex_re = re.compile(r"^[0-9a-f]+$", re.IGNORECASE)
bin_re = re.compile(r"^[0-1_]+$", re.IGNORECASE)
oct_re = re.compile(r"^[0-8]+$", re.IGNORECASE)
args_re = re.compile("(?:^|,)(?=[^\"]|(\")?)\"?((?(1)[^\"]*|[^,\"]*))\"?(?=,|$)", re.IGNORECASE)
func_re = re.compile("^([\w$#@~.?]+)\s*([|^<>+\-*/%@]{1,2})\s*([\w$#@~.?]+)$", re.IGNORECASE)
func2_re = re.compile("^([\w$#@~.?]+)\s*\(\s*([\w$#@~.?]+)*\)$", re.IGNORECASE)
brackets_re = re.compile(r"(\((?:\(??[^\(]*?\)))", re.IGNORECASE)
secs_re = re.compile("^([\d]+)x([\d]+)x([\d]+)$", re.IGNORECASE)
funcc_re = re.compile("^([\w$#@~.?]+)\(([\w,]+)\)(.*)", re.IGNORECASE)

MAX_INT_BYTES = 12


def args2operands(args):
    operands = ['"' + a[1] + '"' if a[0] == '"' else a[1] for a in args_re.findall(args or '') if a[1]]
    return operands


def match(regex, s):
    return regex.match(s) is not None


class CompilingError(Exception):
    def __init__(self, message):
        self.message = message


class InstructionError(Exception):
    def __init__(self, message):
        self.message = message


class Instruction:
    def __init__(self, name: str, opcode: str, operands=0, alias=None):
        name = name.strip().lower()
        if not name or not name.isalnum():
            raise InstructionError(f"Invalid instruction name '{name}'")
        self.name = name.strip()
        self.alias = alias or []

        self.reg_operands = 0
        opcode = opcode.replace('_', '')
        if len(opcode) == 8:
            if opcode[4:6] == '??':
                self.reg_operands += 1
            if opcode[6:8] == '??':
                self.reg_operands += 1
        else:
            raise CompilingError("Invalid opcode: " + opcode)

        self.opcode = int(opcode.replace('?', '0'), 2)
        self.imm_operands = operands
        self.compiler = None

    @property
    def length(self):
        return self.imm_operands + 1

    def __len__(self):
        return self.length

    def _gen_instr(self, regs):
        instr = self.opcode
        if len(regs) != self.reg_operands:
            raise CompilingError(f"Invalid number of registers: set {len(regs)}, required: {self.reg_operands}")
        if len(regs) == 2:
            if regs[1] is None:
                raise CompilingError(f"Unable to decode register name {regs[1]}")
            if regs[0] is None:
                raise CompilingError(f"Unable to decode register name {regs[0]}")
            instr |= regs[0] << 2 | regs[1]
        elif len(regs) == 1:
            if regs[0] is None:
                raise CompilingError(f"Unable to decode register name {regs[0]}")
            instr |= regs[0] << 2
        return instr.to_bytes(1, 'little')  # Order does not matter with 1 byte

    def compile(self, operands, scope):
        regs = []
        for reg in operands[:self.reg_operands]:
            regs.append(self.compiler.decode_reg(reg))

        imm = self.compiler.decode_with_labels(operands[self.reg_operands:], scope)
        if len(imm) != self.imm_operands:
            raise CompilingError(f"Instruction {self.name} has invalid argument size {len(imm)} != {self.imm_operands},"
                                 f" supplied args: 0x{imm.hex()}")
        instr = self._gen_instr(regs)

        return instr + imm


class Section:
    def __init__(self):
        self.instr = []
        self.data = b''
        self.count = 0
        self.width = 1
        self.length = 3
        self.options = {}
        self.depth = 2 ** 8

    @property
    def bin_width(self):
        if 'bin_width' in self.options and self.options['bin_width'].isdecimal():
            return int(self.options['bin_width'])
        return self.width * 8

    @property
    def fill_bits(self):
        if 'fill_bits' in self.options and self.options['fill_bits'].isdecimal():
            return int(self.options['fill_bits'])
        return self.depth * self.width * 8


class Compiler:
    def __init__(self, address_size=2, byte_order='little'):
        self.instr_db: Dict[str, Instruction] = {}
        self.data = []
        self.labels = {}
        self.macros = {}
        self.order = byte_order
        self.regnames = {}
        self.address_size = address_size

    def decode_reg(self, s: str):
        s = s.strip()
        if s in self.regnames:
            return self.regnames[s]
        raise CompilingError(f"Unrecognised register name: {s}")

    def decode_bytes(self, s: str):
        s = s.strip()
        typ = ""
        # Decimal numbers
        if (s.startswith('+') or s.startswith('-')) and s[1:].isnumeric():
            typ = 'int'
        elif s.isnumeric():
            typ = 'uint'
        elif s.endswith('d') and s[:-1].isnumeric():
            s = s[:-1]
            typ = 'uint'
        elif s.startswith('0d') and s[2:].isnumeric():
            s = s[2:]
            typ = 'uint'

        # Hexadecimal numbers
        elif s.startswith('0') and s.endswith('h') and match(hex_re, s[1:-1]):
            s = s[1:-1]
            typ = 'hex'
        elif (s.startswith('$0') or s.startswith('0x') or s.startswith('$0')) and match(hex_re, s[2:]):
            s = s[2:]
            typ = 'hex'

        # Octal numbers
        elif (s.endswith('q') or s.endswith('o')) and match(oct_re, s[:-1]):
            s = s[:-1]
            typ = 'oct'
        elif (s.startswith('0q') or s.startswith('0o')) and match(oct_re, s[2:]):
            s = s[2:]
            typ = 'oct'

        # Binary number
        elif (s.endswith('b') or s.endswith('y')) and match(bin_re, s[:-1]):
            s = s[:-1].replace('_', '')
            typ = 'bin'

        elif (s.startswith('0b') or s.startswith('0y')) and match(bin_re, s[2:]):
            s = s[2:].replace('_', '')
            typ = 'bin'

        # ASCII
        elif s.startswith("'") and s.endswith("'") and len(s) == 3:
            s = ord(s[1:-1]).to_bytes(1, self.order)
            typ = 'ascii'

        elif (s.startswith("'") and s.endswith("'")) or (s.startswith('"') and s.endswith('"')):
            s = s[1:-1].encode('utf-8').decode("unicode_escape").encode('utf-8')
            typ = 'string'

        # Convert with limits
        if typ == 'uint':
            numb = int(s)
            for i in range(1, MAX_INT_BYTES + 1):
                if numb < 2 ** (i * 8):
                    return numb.to_bytes(i, self.order)
        elif typ == 'int':
            numb = int(s)
            for i in range(1, MAX_INT_BYTES + 1):
                if -2 ** (i * 7) < numb < 2 ** (i * 7):
                    return numb.to_bytes(i, self.order)
        elif typ == 'hex':
            numb = int(s, 16)
            return numb.to_bytes(int(len(s) / 2) + len(s) % 2, self.order)

        elif typ == 'oct':
            numb = int(s, 8)
            for i in range(1, 9):
                if -2 ** (i * 7) < i < 2 ** (i * 8):
                    return numb.to_bytes(i, self.order)

        elif typ == 'bin':
            numb = int(s, 2)
            return numb.to_bytes(int(len(s) / 8) + len(s) % 8, self.order)

        else:
            return s

    def _decode_labels(self, arg, scope):
        immx = self.decode_bytes(arg)
        if isinstance(immx, str):
            if immx.startswith('.'):
                immx = scope + immx
            if immx in self.labels:
                return self.labels[immx]
            else:
                raise CompilingError(f"Unknown label: {immx}")
        elif isinstance(immx, bytes):
            return immx

    def decode_with_labels(self, args, scope):
        data = b''
        for arg in args:
            if isinstance(arg, str):
                funcm = func_re.match(arg)
                if funcm is not None:
                    g = funcm.groups()
                    left = self._decode_labels(g[0], scope)
                    right = self._decode_labels(g[2], scope)
                    data += self.proc_func(left, right, g[1])
                    continue
            data += self._decode_labels(arg, scope)
        return data

    def add_reg(self, name, val):
        self.regnames[name] = val
        self.regnames['$' + name] = val

    def add_instr(self, instr: Instruction):
        instr.compiler = self
        operands = instr.reg_operands + instr.imm_operands

        if instr.name in self.instr_db:
            raise InstructionError(f"Instruction {instr.name} operands={operands} duplicate!")
        self.instr_db[instr.name] = instr
        for alias in instr.alias:
            if alias.lower() in self.instr_db:
                raise InstructionError(f"Instruction alias {alias} operands={operands} duplicate!")
            self.instr_db[alias.lower()] = instr

    def proc_func(self, left, right, op):
        leftInt = int.from_bytes(left, self.order)
        rightInt = int.from_bytes(right, self.order)
        if op == '|':
            result = leftInt | rightInt
        elif op == '^':
            result = leftInt ^ rightInt
        elif op == '&':
            result = leftInt & rightInt
        elif op == '<<':
            result = leftInt << rightInt
        elif op == '>>':
            result = leftInt >> rightInt
        elif op == '+':
            result = leftInt + rightInt
        elif op == '-':
            result = leftInt - rightInt
        elif op == '*':
            result = leftInt * rightInt
        elif op == '/' or op == '//':
            result = leftInt // rightInt
        elif op == '%' or op == '%%':
            result = leftInt % rightInt
        elif op == '@':
            return bytes([left[len(left) - rightInt - 1]])
        else:
            raise CompilingError(f"Invalid function operation {op}")
        return result.to_bytes(len(left), self.order)

    def __code_compiler(self, file, lnum, line_args, csect, scope, macro):
        builtin_cmds = {'db', 'dbe'}

        if line_args[0].endswith(':') and label_re.match(line_args[0][:-1]) is not None:
            # Must be label
            label = line_args[0][:-1]
            line_args = line_args[1:]
            if label.startswith('.'):
                if scope is None:
                    raise CompilingError(f"No local scope for {label}!")
                label = scope + label
            elif not macro:
                scope = label
            if label in self.labels:
                raise CompilingError(f"Label {label} duplicate")
            self.labels[label] = csect.count.to_bytes(csect.length, self.order)

        if len(line_args) == 0:
            return scope
        elif len(line_args) == 1:
            args = None
        else:
            args = line_args[1]
        instr_name = line_args[0].lower()
        instr_nameCS = line_args[0]

        # Builtin instructions
        if instr_name == 'db':
            data = self.decode_with_labels(args2operands(args), scope)
            if len(data) % csect.width != 0:
                fill = csect.width - (len(data) % csect.width)
                data += b'\x00' * fill
            csect.instr.append(data)
            csect.count += len(data) // csect.width
            return scope

        if instr_name == 'dbe':
            try:
                fill = int(args[0])
            except ValueError:
                raise CompilingError(f"Instruction 'dbe' invalid argument, must be a number")
            except IndexError:
                raise CompilingError(f"Instruction 'dbe' invalid argument count! Must be 1")

            if fill % csect.width != 0:
                fill += csect.width - (fill % csect.width)
            data = b'\x00' * fill
            csect.instr.append(data)
            csect.count += len(data) // csect.width
            return scope

        if instr_name == '%def':
            ops = args2operands(args)
            if len(ops) != 2:
                raise CompilingError(f"Command '%def' hsa invalid argument count! Must be 2, found {len(ops)}")
            self.labels[scope + '.' + ops[0]] = ops[1].lower()
            return scope

        if instr_name in self.macros:
            argsp = args2operands(args)
            if len(argsp) != self.macros[instr_name][0]:
                raise CompilingError(f"Invalid macro argument count!")
            self.macros[instr_name][3] += 1  # How many time macro been used (used for macro labels)
            mlabel = f'{instr_name}.{self.macros[instr_name][3]}'
            for slnum, sline in enumerate(self.macros[instr_name][1]):
                slnum += 1
                mline = sline.copy()
                for i, mline0 in enumerate(mline):
                    for j in range(len(argsp)):
                        mline0 = mline0.replace(f'%{j + 1}', argsp[j])
                    mline[i] = re.sub(r'(%{2})([\w$#~.?]+)', mlabel + r'.\2', mline0)
                try:
                    scope = self.__code_compiler(file, lnum, mline, csect, scope, True)
                except CompilingError as e:
                    print(f"ERROR {file}:{self.macros[instr_name][2] + slnum}: {e.message}")
                    raise CompilingError(f"Previous error")
            return scope

        dscope = scope + '.' if scope else ''
        if dscope + instr_name in self.labels:
            instr_name = self.labels[dscope + instr_name]  # replace with definition

        if dscope + instr_nameCS in self.labels:
            instr_name = self.labels[dscope + instr_nameCS]  # replace with definition

        if instr_name not in self.instr_db:
            raise CompilingError(f"Instruction '{instr_name}' not recognised!")

        # replace args with %def
        ops = args2operands(args)
        for i, arg in enumerate(ops):
            if dscope + arg in self.labels:
                val = self.labels[dscope + arg]
                if isinstance(val, bytes):
                    val = '0x' + val.hex()
                ops[i] = val
        args = ','.join(ops)

        instr_obj = self.instr_db[instr_name.lower()]
        csect.instr.append((instr_obj, args, lnum, scope))
        csect.count += instr_obj.length
        return scope

    @staticmethod
    def __line_generator(code):
        for lnum, line in enumerate(code):
            lnum += 1
            line = line.split(';', 1)[0]
            line = re.sub(' +', ' ', line)  # replace multiple spaces
            line = line.strip()
            line_args = [l.strip() for l in line.split(' ', 2)]
            # line_args = list(filter(lambda x: len(x) > 0, line_args))
            if len(line_args) == 0 or line_args[0] == '':
                continue
            yield lnum, line_args

    def compile_file(self, file):
        try:
            with open(file, 'r') as f:
                data = self.compile(file, f.readlines())
            return data
        except IOError:
            return None

    def compile(self, file, code):
        failure = False

        sections: Dict[str, Section] = {}
        csect = None
        scope = None
        macro = None

        for lnum, line_args in self.__line_generator(code):
            try:
                # Inside macro
                if macro is not None:
                    if line_args[0].lower() == '%endmacro':
                        macro = None
                        continue
                    self.macros[macro][1].append(line_args)
                    continue

                # Section
                if line_args[0].lower() == 'section':
                    if len(line_args) < 2:
                        raise CompilingError(f"Invalid section arguments!")
                    section_name = line_args[1].lower()
                    if section_name not in sections:
                        s = Section()
                        options = {}
                        if len(line_args) == 3:
                            for sp in line_args[2].split(','):
                                if '=' not in sp:
                                    continue
                                sp2 = sp.split('=', 1)
                                key = sp2[0].lower()
                                val = sp2[1]
                                s.options[key] = val
                                if not val.isdecimal():
                                    continue
                                if key == 'depth':
                                    s.depth = int(val)
                                if key == 'width':
                                    s.width = int(val)
                                if key == 'length':
                                    s.length = int(val)
                            # m = secs_re.match(line_args[2])
                            # if m is not None:
                            #     g = m.groups()
                            #     s.width = int(g[0])
                            #     s.length = int(g[1])
                            #     s.size = int(g[2])
                            # else:
                            #     raise CompilingError(f"Invalid section argument: {line_args[2]}")
                        sections[section_name] = s
                    csect = sections[section_name]
                    continue

                # Macros
                elif line_args[0].lower() == '%define':
                    if len(line_args) != 3:
                        raise CompilingError(f"Invalid %define arguments!")
                    self.labels[line_args[1]] = self.decode_bytes(line_args[2])
                    continue
                elif line_args[0].lower() == '%macro':
                    if len(line_args) != 3:
                        raise CompilingError(f"Invalid %macro arguments!")
                    if line_args[1] in self.macros:
                        raise CompilingError(f"Macro '{line_args[1]}' already in use")
                    if not line_args[2].isdigit():
                        raise CompilingError(f"%macro argument 2 must be a number")
                    macro = line_args[1].lower()
                    self.macros[macro] = [int(line_args[2]), [], lnum, 0]
                    continue

                elif line_args[0].lower() == '%include':
                    if len(line_args) != 2:
                        raise CompilingError(f"Invalid %include arguments!")
                    raise CompilingError(f"%include is not implemented yet")  # TODO: Complete
                    continue

                elif line_args[0].lower() == '%ifdef':
                    if len(line_args) != 1:
                        raise CompilingError(f"Invalid %ifdef arguments!")
                    raise CompilingError(f"%ifdef is not implemented yet")  # TODO: Complete
                    continue

                elif line_args[0].lower() == '%ifndef':
                    if len(line_args) != 1:
                        raise CompilingError(f"Invalid %ifndef arguments!")
                    raise CompilingError(f"%ifndef is not implemented yet")  # TODO: Complete
                    continue

                elif line_args[0].lower() == '%else':
                    if len(line_args) != 0:
                        raise CompilingError(f"Invalid %else arguments!")
                    raise CompilingError(f"%else is not implemented yet")  # TODO: Complete
                    continue

                elif line_args[0].lower() == '%endif':
                    if len(line_args) != 0:
                        raise CompilingError(f"Invalid %endif arguments!")
                    raise CompilingError(f"%endif is not implemented yet")  # TODO: Complete
                    continue

                if csect is None:
                    raise CompilingError(f"No section defined!")

                scope = self.__code_compiler(file, lnum, line_args, csect, scope, False)

            except CompilingError as e:
                failure = True
                print(f"ERROR {file}:{lnum}: {e.message}")

        for section in sections.values():
            for instr_tuple in section.instr:
                if isinstance(instr_tuple, bytes):
                    section.data += instr_tuple
                    continue
                instr, args, lnum, scope = instr_tuple
                try:
                    operands = args2operands(args)
                    section.data += instr.compile(operands, scope)
                except CompilingError as e:
                    failure = True
                    print(f"ERROR {file}:{lnum}: {e.message}")
        if failure:
            return None
        # return {k: (v.width, v.length, v.size, v.data) for k, v in sections.items()}
        return sections

    def decompile(self, binary):
        addr = 0
        res = []
        ibin = iter(binary)
        for data in ibin:
            norm0 = int(data)
            norm1 = norm0 & int('11110011', 2)
            norm2 = norm0 & int('11110000', 2)

            for instr in self.instr_db.values():
                if not ((instr.reg_operands == 0 and norm0 == instr.opcode) or
                        (instr.reg_operands == 1 and norm1 == instr.opcode) or
                        (instr.reg_operands == 2 and norm2 == instr.opcode)):
                    continue
                asm = f'{addr:04x}: {instr.name.upper().ljust(6)}'
                args = []
                raw = format(norm0, '02x')
                if instr.reg_operands > 0:
                    args.append(f'r{(norm0 & 12) >> 2}')
                if instr.reg_operands > 1:
                    args.append(f'r{(norm0 & 3)}')
                if instr.imm_operands > 0:
                    b = '0x'
                    for i in range(instr.imm_operands):
                        try:
                            bi = format(int(next(ibin)), '02x')
                        except StopIteration:
                            break
                        b += bi
                        raw += bi
                        addr += 1
                    args.append(b)
                line = asm + ', '.join(args)
                tabs = ' ' * (27 - int(len(line)))
                res.append(f'{line}{tabs}[{raw}]')
                break
            addr += 1
        return '\n'.join(res)


def main(asmc):
    import sys
    import argparse
    from os import path, mkdir
    from bitstring import BitArray

    parser = argparse.ArgumentParser(description='Assembly compiler', add_help=True)
    parser.add_argument('file', help='Files to compile')
    parser.add_argument('-o', '--output', help='Output directory')
    parser.add_argument('-f', '--force', action='store_true', help='Force override output file')
    parser.add_argument('-s', '--stdout', action='store_true', help='Print to stdout')
    parser.add_argument('-D', '--decompile', action='store_true', help='Print decompiled')
    args = parser.parse_args(sys.argv[1:])
    bname = path.basename(args.file).rsplit('.', 1)[0]

    if not path.isfile(args.file):
        print(f'No file {args.file}!')
        sys.exit(1)

    output_dir = args.output or path.dirname(args.file)
    if not path.exists(output_dir):
        mkdir(output_dir)

    data = asmc.compile_file(args.file)
    if data is not None:
        for sec_name in data:
            sec = data[sec_name]
            if sec_name == '.text' and args.decompile:
                print(asmc.decompile(sec.data))

            output = path.join(output_dir, f'{bname}.{sec_name.strip(".")}.o')
            if not args.stdout and not args.force:
                if path.isfile(output):
                    print(f'Output file already exists {output}!')
                    inval = ''
                    while True:
                        inval = input('Override? [y/n]: ')
                        inval = inval.lower().strip()
                        if inval != 'y' and inval != 'n':
                            print('Please type y or n')
                            continue
                        break
                    if inval == 'n':
                        continue

            parity = 0
            if 'parity' in sec.options and sec.options['parity'].isdigit():
                parity = int(sec.options['parity'])

            content = sec.data

            used = -1
            # if fill_bits == 0 and len(sec.data) < sec.depth:
            #     used = len(content)/sec.depth
            #     content += (sec.depth*sec.width - len(content)) * bytearray(b'\x00')

            # converting to BitArray
            binary = BitArray()
            for i in range(sec.depth):
                if len(binary) >= sec.fill_bits:  # FIXME: better solution
                    break
                cell = content[i*sec.width:(i+1)*sec.width]
                cell_bytes = BitArray(cell)
                if len(cell_bytes) < sec.width:  # we can assume content ends here
                    if used == -1:
                        used = len(binary)/sec.fill_bits
                    f = '0' * (sec.bin_width - len(cell_bytes))
                    cell_bytes.append(BitArray(bin=f))
                cell_bytes = cell_bytes[len(cell_bytes)-sec.bin_width:]
                binary.append(cell_bytes)
                if parity > 0 and i % parity == 1:
                    parity_bit = str(binary[-(i*parity*sec.bin_width):].bin.count('1') % 2)
                    binary.append(BitArray(bin=parity_bit))

            if used == -1:  # this is bad. Content is bigger than memory itself
                used = len(binary)/sec.fill_bits
            # if fill_bits > 0 and len(binary) < fill_bits:
            #     used = len(binary) / fill_bits
            #     fill = (fill_bits - len(binary)) * BitArray(bin='0')
            #     binary.append(fill)

            with open(output, 'wb') as f:
                f.write(binary.bytes)
            print(f'Saved {sec_name} to "{output}", used {used*100:.2f}% [{int(len(binary)/8 * used)}B of {len(binary)//8}B]')
    else:
        print(f'Failed to compile {args.file}!')
        sys.exit(1)
    sys.exit(0)

