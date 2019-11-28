#!/usr/bin/python3

import re
import math
import traceback

label_re = re.compile(r"^[\w\$\#\@\~\.\?]+$", re.IGNORECASE)
hex_re = re.compile(r"^[0-9a-f]+$", re.IGNORECASE)
bin_re = re.compile(r"^[0-1_]+$", re.IGNORECASE)
oct_re = re.compile(r"^[0-8]+$", re.IGNORECASE)


def match(regex, s):
    return regex.match(s) is not None


def decode_bytes(val: str):
    try:
        if val.endswith('h'):
            return [int(val[i:i + 2], 16) for i in range(0, len(val) - 1, 2)]
        if val.startswith('0x'):
            return [int(val[i:i + 2], 16) for i in range(2, len(val), 2)]
        if val.startswith('b'):
            val = val.replace('_', '')[1:]
            return [int(val[i:i + 8], 2) for i in range(0, len(val), 8)]
    except ValueError:
        raise ValueError(f"Invalid binary '{val}'")
    if val.isdigit():
        i = int(val)
        if i > 255 or i < 0:
            raise ValueError(f"Invalid binary '{val}', unsigned int out of bounds")
        return [i]
    if (val.startswith('+') or val.startswith('-')) and val[1:].isdigit():
        i = int(val)
        if i > 127 or i < -128:
            raise ValueError(f"Invalid binary '{val}', signed int out of bounds")
        if i < 0:  # convert to unsigned
            i += 2 ** 8
        return [i]
    if len(val) == 3 and ((val[0] == "'" and val[2] == "'") or (val[0] == '"' and val[2] == '"')):
        return [ord(val[1])]
    raise ValueError(f"Invalid binary '{val}'")


def is_reg(r):
    if r.startswith('$'):
        r = r[1:]
        if r.isnumeric() and 0 <= int(r) <= 3:
            return True
    elif len(r) == 2 and r[0] == 'r' and r[1] in {'0', '1', '2', '3', 'a', 'b', 'c', 'e'}:
        return True
    return False


def decode_reg(r):
    if r.startswith('$') and r[1:].isnumeric():
        r = int(r[1:])
    if isinstance(r, int):
        if 0 <= r <= 3:
            return r
        raise ValueError(f"Invalid register value {r}")
    rl = r.lower()
    if rl.startswith('$'):
        rl = rl[1:]
    if rl == 'ra' or rl == 'r0':
        return 0
    if rl == 'rb' or rl == 'r1':
        return 1
    if rl == 'rc' or rl == 'r2':
        return 2
    if rl == 're' or rl == 'r3':
        return 3
    raise ValueError(f"Invalid register name '{r}'")


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
        self.opcode = decode_bytes(opcode.replace('?', '0'))[0]
        self.reg_operands = 0
        if len(opcode) == 10:
            if opcode[6:8] == '??':
                self.reg_operands += 1
            if opcode[8:10] == '??':
                self.reg_operands += 1
        self.imm_operands = operands
        self.compiler = None

    @property
    def length(self):
        return self.imm_operands + 1

    def __len__(self):
        return self.length

    def _gen_instr(self, regs, imm):
        instr = self.opcode
        if len(regs) != self.reg_operands:
            raise CompilingError(f"Invalid number of registers: set {len(regs)}, required: {self.reg_operands}")
        limm = 0
        for i in imm:
            if isinstance(i, str):
                if i in self.compiler.labels:
                    d = self.compiler.labels[i]
                    limm += len(d)
                else:
                    limm += self.compiler.address_size
            else:
                limm += len(i)
        if limm != self.imm_operands:
            raise CompilingError(f"Invalid number of immediate: set {limm}, required: {self.reg_operands}")
        if len(regs) == 2:
            if regs[1] is None:
                raise CompilingError(f"Unable to decode register name {regs[1]}")
            if regs[0] is None:
                raise CompilingError(f"Unable to decode register name {regs[0]}")
            instr |= regs[1] << 2 | regs[0]
        elif len(regs) == 1:
            if regs[0] is None:
                raise CompilingError(f"Unable to decode register name {regs[0]}")
            instr |= int(regs[0]) << 2
        return instr

    def compile(self, operands):
        regs = []
        imm = []
        for i, arg in enumerate(operands):
            if self.reg_operands > i:
                regs.append(self.compiler.decode_reg(arg))
            else:
                imm.append(self.compiler.decode_bytes(arg))

        instr = self._gen_instr(regs, imm)
        return [instr] + imm


class CompObject:
    def __init__(self, instr, operands, line_num):
        self.instr = instr
        self.operands = operands
        self.line_num = line_num
        self.code = []
        self.code_ref = 0
        self.code = self.instr.compile(self.operands)

    def instr_len(self):
        if hasattr(self.instr, 'get_imm_operands'):
            o = getattr(self.instr, 'get_imm_operands')
            return o(self.operands)
        else:
            return self.instr.length


class Compiler:
    def __init__(self, address_size=2, byte_order='little'):
        self.instr_db = {}
        self.data = []
        self.caddress = 0
        self.labels = {}
        self.order = byte_order
        self.regnames = {}
        self.address_size = address_size

    def decode_reg(self, s: str):
        s = s.strip()
        # if s in self.labels:
        #     b = self.labels[s]
        if s in self.regnames:
            b = self.regnames[s]
        else:
            b = self.decode_bytes(s)
        if isinstance(b, bytes):
            i = int.from_bytes(b, byteorder=self.order)
        elif isinstance(b, int):
            i = b
        else:
            raise CompilingError(f"Unrecognised register name: {s}")
        if i not in self.regnames.values():
            raise CompilingError(f"Invalid register: {s}")
        return i

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

    @staticmethod
    def _hash_instr(name, operands):
        return hash(name) + hash(operands)

    def add_reg(self, name, val):
        self.regnames[name] = val
        self.regnames['$' + name] = val

    def add_instr(self, instr: Instruction):
        instr.compiler = self
        operands = instr.reg_operands + instr.imm_operands
        # ihash = self._hash_instr(instr.name, operands)

        if instr.name in self.instr_db:
            raise InstructionError(f"Instruction {instr.name} operands={operands} duplicate!")
        self.instr_db[instr.name] = instr
        for alias in instr.alias:
            # ahash = self._hash_instr(alias, operands)
            if alias.lower() in self.instr_db:
                raise InstructionError(f"Instruction alias {alias} operands={operands} duplicate!")
            self.instr_db[alias.lower()] = instr

    def __func(self, f, args):
        for arg in args:
            if arg == '|':
                pass
            if arg == '^':
                pass
            if arg == '&':
                pass
            if arg == '<<':
                pass
            if arg == '>>':
                pass
            if arg == '+':
                pass
            if arg == '-':
                pass
            if arg == '*':
                pass
            if arg == '/' or arg == '//':
                pass
            if arg == '%' or arg == '%%':
                pass

    def __precompile(self, line):
        line = line.split(';', 1)[0]
        if ':' in line:
            linespl = line.split(':', 1)
            line = linespl[1]
            label = linespl[0]
            if label in self.labels:
                raise CompilingError(f"Label {label} duplicate")
            self.labels[label] = self.caddress.to_bytes(self.address_size, self.order)
        if line.startswith('%define'):
            sp = list(filter(None, line.split(' ', 3)))
            if len(sp) != 3:
                raise CompilingError(f"Invalid %define")
            if '(' in sp[1] and ')' in sp[1]:  # Function
                raise CompilingError(f"%define functions not implemented")
            self.labels[sp[1]] = self.decode_bytes(sp[2])
            return
        instr0 = list(filter(None, line.strip().split(' ', 1)))
        if len(instr0) == 0:
            return
        instr = instr0[0]
        if len(instr0) == 1:
            instr0.append('')
        operands = list(filter(None, map(lambda x: x.strip(), instr0[1].split(','))))
        if instr.lower() not in self.instr_db:
            raise CompilingError(f"Instruction {instr} operands={operands} is not recognised!")
        co = CompObject(self.instr_db[instr.lower()], operands, 0)
        return co

    def compile(self, file, code):
        failure = False
        instr = []
        binary = []
        for lnum, line in enumerate(code):
            lnum += 1
            try:
                co = self.__precompile(line)
                if co is not None:
                    co.line_num = lnum
                    self.caddress += co.instr_len()
                    instr.append(co)
            except CompilingError as e:
                failure = True
                print(f"ERROR {file}:{lnum}: {e.message}")
        for co in instr:
            try:
                binary += co.code
            except CompilingError as e:
                failure = True
                print(f"ERROR {file}:{co.line_num}: {e.message}")
            except Exception:
                failure = True
                print(f"ERROR {file}:{co.line_num}: Unexpected error:")
                traceback.print_exc()

        nbin = bytearray()
        for b in binary:
            if isinstance(b, int):
                nbin += b.to_bytes(1, self.order)
            elif isinstance(b, bytes):
                nbin += b
            elif isinstance(b, str):
                if b in self.labels:
                    nbin += self.labels[b]
                else:
                    failure = True
                    print(f"ERROR {file}: Unable to find label '{b}'")
        if failure:
            return None
        return nbin


def convert_to_binary(data):
    a = '\n'.join([format(i, '08b') for i in data])
    return a.encode()


def convert_to_mem(data):
    x = b''
    fa = f'0{math.ceil(math.ceil(math.log2(len(data)))/4)}x'
    a = [format(d, '02x') for d in data]
    for i in range(int(len(a) / 8) + 1):
        y = a[i * 8:(i + 1) * 8]
        if len(y) > 0:
            x += (' '.join(y) + ' '*((8-len(y))*3) + '  // ' + format((i*8-1)+len(y), fa) + '\n').encode()
    return x


def convert_to_mif(data, depth=32, width=8):
    x = f'''-- auto-generated memory initialisation file
DEPTH = {depth};
WIDTH = {width};
ADDRESS_RADIX = HEX;
DATA_RADIX = HEX;
CONTENT
BEGIN
'''.encode()
    addr_format = f'0{math.ceil(int(math.log2(len(data)))/4)}x'
    a = [format(i, '02x') for i in data]
    for i in range(int(len(a) / 8) + 1):
        y = a[i * 8:(i + 1) * 8]
        if len(y) > 0:
            x += (format(i*8, addr_format) + ' : ' + ' '.join(y) + ';\n').encode()
    x += b"END;"
    return x
