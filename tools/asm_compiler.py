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
secs_re = re.compile("^([\d]+)x([\d]+)x([\d]+)$", re.IGNORECASE)

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
        self.length = 1
        self.size = 2**8


class Compiler:
    def __init__(self, address_size=2, byte_order='little'):
        self.instr_db: Dict[str, Instruction] = {}
        self.data = []
        self.labels = {}
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
        if s.isnumeric():
            typ = 'int'
        elif s.endswith('d') and s[:-1].isnumeric():
            s = s[:-1]
            typ = 'int'
        elif s.startswith('0d') and s[2:].isnumeric():
            s = s[2:]
            typ = 'int'

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
        if typ == 'int':
            numb = int(s)
            for i in range(1, 9):
                if -2 ** (i * 7) < i < 2 ** (i * 8):
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
        if op == '|':
            return left | right
        if op == '^':
            return left ^ right
        if op == '&':
            return left & right
        if op == '<<':
            return left << right
        if op == '>>':
            return left >> right
        if op == '+':
            return left + right
        if op == '-':
            return left - right
        if op == '*':
            return left * right
        if op == '/' or op == '//':
            return left / right
        if op == '%' or op == '%%':
            return left % right
        if op == '@':
            return bytes([left[len(left)-int.from_bytes(right, byteorder=self.order)-1]])
        raise CompilingError(f"Invalid function operation {op}")

    def compile(self, file, code):
        failure = False

        sections: Dict[str, Section] = {}
        csect = None
        scope = None

        for lnum, line in enumerate(code):
            lnum += 1
            line = line.split(';', 1)[0].strip()

            try:
                line_args = [l.strip() for l in line.split(' ', 2)]
                # line_args = list(filter(lambda x: len(x) > 0, line_args))
                if len(line_args) == 0 or line_args[0] == '':
                    continue

                # Section
                if line_args[0].lower() == 'section':
                    if len(line_args) < 2:
                        raise CompilingError(f"Invalid section arguments!")
                    section_name = line_args[1].lower()
                    if section_name not in sections:
                        s = Section()
                        if len(line_args) == 3:
                            m = secs_re.match(line_args[2])
                            if m is not None:
                                g = m.groups()
                                s.width = int(g[0])
                                s.length = int(g[1])
                                s.size = int(g[2])
                            else:
                                raise CompilingError(f"Invalid section argument: {line_args[2]}")
                        sections[section_name] = s
                    csect = sections[section_name]
                    continue

                # Macros
                elif line_args[0].lower() == '%define':
                    if len(line_args) != 3:
                        raise CompilingError(f"Invalid %define arguments!")
                    self.labels[line_args[1]] = self.decode_bytes(line_args[2])
                    continue

                elif line_args[0].lower() == '%include':
                    if len(line_args) != 2:
                        raise CompilingError(f"Invalid %include arguments!")
                    raise CompilingError(f"%include is not implemented yet")  # TODO: Complete
                    continue

                if csect is None:
                    raise CompilingError(f"No section defined!")

                builtin_cmds = {'db', 'dbe'}

                if line_args[0].lower() not in self.instr_db and\
                        line_args[0].lower() not in builtin_cmds:  # Must be label
                    label = line_args[0]
                    line_args = line_args[1:]
                    if label.startswith('.'):
                        if scope is None:
                            raise CompilingError(f"No local scope for {label}!")
                        label = scope + label
                    else:
                        scope = label
                    if label in self.labels:
                        raise CompilingError(f"Label {label} duplicate")
                    self.labels[label] = csect.count.to_bytes(csect.length, self.order)

                if len(line_args) == 0:
                    continue
                elif len(line_args) == 1:
                    instr_name, args = line_args[0].lower(), None
                else:
                    instr_name, args = line_args[0].lower(), line_args[1]

                # Builtin instructions
                if instr_name == 'db':
                    data = self.decode_with_labels(args2operands(args), scope)
                    if len(data) % csect.width != 0:
                        fill = csect.width - (len(data) % csect.width)
                        data += b'\x00' * fill
                    csect.instr.append(data)
                    csect.count += int(len(data)/csect.width)
                    continue

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
                    csect.count += int(len(data)/csect.width)
                    continue

                if instr_name not in self.instr_db:
                    raise CompilingError(f"Instruction '{instr_name}' not recognised!")

                instr_obj = self.instr_db[instr_name.lower()]
                csect.instr.append((instr_obj, args, lnum, scope))
                csect.count += instr_obj.length

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
        return {k: (v.width, v.length, v.size, v.data) for k, v in sections.items()}

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


def convert_to_binary(data):
    a = '\n'.join([format(i, '08b') for i in data])
    return a.encode()


def convert_to_mem(data, width=1, uhex=False):
    x = b''

    if uhex:
        if width == 2:
            for i in range(int(len(data)/2)):
                x += format(data[-(i*2) - 2], f'02x').upper().encode()
                x += format(data[-(i*2) - 1], f'02x').upper().encode()
        else:
            for i in range(len(data)):
                x += format(data[-i-1], f'02x').upper().encode()
        return x

    if width == 2:
        datax = [(x << 8) | y for x, y in zip(data[0::2], data[1::2])]
        if len(data) % 2 == 1:
            datax.append(data[-1] << 8)
    else:
        datax = data

    fa = f'0{math.ceil(math.ceil(math.log2(len(datax))) / 4)}x'
    a = [format(d, f'0{width*2}x') for d in datax]
    for i in range(int(len(a) / 8) + 1):
        y = a[i * 8:(i + 1) * 8]
        if len(y) > 0:
            x += (' '.join(y) + ' ' * ((8 - len(y)) * 3) + '  // ' + format((i * 8 - 1) + len(y), fa) + '\n').encode()
    return x


def convert_to_mif(data, depth=32, width=1):
    x = f'''-- auto-generated memory initialisation file
DEPTH = {math.ceil(depth)};
WIDTH = {width*8};
ADDRESS_RADIX = HEX;
DATA_RADIX = HEX;
CONTENT
BEGIN
'''.encode()

    addr_format = f'0{math.ceil(int(math.log2(len(data))) / 4)}x'
    if width == 2:
        datax = [(x << 8) | y for x, y in zip(data[0::2], data[1::2])]
        if len(data) % 2 == 1:
            datax.append(data[-1] << 8)
    else:
        datax = data
    a = [format(i, f'0{width*2}x') for i in datax]
    for i in range(int(len(a*width) / 8) + 1):
        y = a[i * 8:(i + 1) * 8]
        if len(y) > 0:
            x += (format(i * 8, addr_format) + ' : ' + ' '.join(y) + ';\n').encode()
    x += b"END;"
    return x
