import argparse
import sys
import math
from os import path, mkdir

import asm_compiler as compiler
from asm_compiler import InstructionError, CompilingError


class Compiler(compiler.Compiler):
    def compile(self, file, code):
        sections = super(Compiler, self).compile(file, code)
        return sections
        # if '.text' in sections:
        #     width, length, size, data = sections['.text']

    def decompile(self, binary):
        pass


asmc = Compiler(byte_order='big')

instrSrc = {
    "NULL": 0,
    "ALUACC0R": 1,
    "ALU0": 1,
    "ALUACC1R": 2,
    "ALU1": 2,
    "ADD": 3,
    "ADDC": 4,
    "SUB": 5,
    "SUBC": 6,
    "AND": 7,
    "OR": 8,
    "XOR": 9,
    "SLL": 11,
    "SRL": 12,
    "EQ": 13,
    "GT": 14,
    "GE": 15,
    "MULLO": 16,
    "MULHI": 17,
    "DIV": 18,
    "MOD": 19,
    "BRPT0R": 20,
    "BR0": 20,
    "BRPT1R": 21,
    "BR1": 21,
    "MEMPT0R": 22,
    "MEM0": 22,
    "MEMPT1R": 23,
    "MEM1": 23,
    "MEMPT2R": 24,
    "MEM2": 24,
    "MEMLWHI": 25,
    "LWHI": 25,
    "MEMLWLO": 26,
    "LWLO": 26,
    "STACKR": 27,
    "STACK": 27,
    "STACKPT0": 28,
    "STACKPT1": 29,
    "COMAR": 30,
    "COMA": 30,
    "COMDR": 31,
    "COMD": 31
}


class InstructionDest:
    def __init__(self, name: str, opcode: int, alias=None):
        name = name.strip().lower()
        if not name or not name.isalnum():
            raise InstructionError(f"Invalid instruction name '{name}'")
        self.name = name.strip()
        self.alias = alias or []
        self.opcode = opcode
        self.imm_operands = 1
        self.reg_operands = 0
        self.compiler = None

    @property
    def length(self):
        return 2

    def __len__(self):
        return 2

    def compile(self, operands, scope):
        if len(operands) != 1:
            raise CompilingError(f"Instruction has invalid amount of operands")

        if operands[0] in instrSrc:
            src = instrSrc[operands[0]]
            immediate = 0
        else:
            imm = self.compiler.decode_with_labels(operands, scope)
            if len(imm) != 1:
                raise CompilingError(f"Instruction immediate is {len(imm)} in length. It must be 1.")
            immediate = 1
            src = imm[0]

        return (immediate << 12 | self.opcode << 8 | src).to_bytes(2, self.compiler.order)


asmc.add_instr(InstructionDest("ALU0", 0, alias=["ALUACC0"]))
asmc.add_instr(InstructionDest("ALU1", 1, alias=["ALUACC1"]))
asmc.add_instr(InstructionDest("BR0", 2, alias=["BRPT0"]))
asmc.add_instr(InstructionDest("BR1", 3, alias=["BRPT1"]))
asmc.add_instr(InstructionDest("BRZ", 4))
asmc.add_instr(InstructionDest("STACK", 5))
asmc.add_instr(InstructionDest("MEM0", 6, alias=["MEMPT0"]))
asmc.add_instr(InstructionDest("MEM1", 7, alias=["MEMPT1"]))
asmc.add_instr(InstructionDest("MEM2", 8, alias=["MEMPT2"]))
asmc.add_instr(InstructionDest("SWHI", 9, alias=["MEMSWHI"]))
asmc.add_instr(InstructionDest("SWLO", 10, alias=["MEMSWLO"]))
asmc.add_instr(InstructionDest("COMA", 11))
asmc.add_instr(InstructionDest("COMD", 12))


if __name__ == '__main__':
    parser = argparse.ArgumentParser(description='Assembly compiler', add_help=True)
    parser.add_argument('file', help='Files to compile')
    parser.add_argument('-t', '--output_type', choices=['bin', 'mem', 'binary', 'mif', 'uhex'], default='mem',
                        help='Output type')
    parser.add_argument('-S', '--slice', default=-1, type=int, help='Slice output for section')
    parser.add_argument('-o', '--output', help='Output directory')
    parser.add_argument('-f', '--force', action='store_true', help='Force override output file')
    parser.add_argument('-s', '--stdout', action='store_true', help='Print to stdout')
    parser.add_argument('-D', '--decompile', action='store_true', help='Print decompiled')
    parser.add_argument('section', help='Section')
    args = parser.parse_args(sys.argv[1:])
    if not path.isfile(args.file):
        print(f'No file {args.file}!')
        sys.exit(1)

    output_dir = args.output or path.dirname(args.file)
    if not path.exists(output_dir):
        mkdir(output_dir)

    if args.output_type == 'mem':
        ext = '.mem'
    elif args.output_type == 'bin':
        ext = '.bin'
    elif args.output_type == 'mif':
        ext = '.mif'
    elif args.output_type == 'uhex':
        ext = '.uhex'
    else:
        ext = '.out'
    bname = path.basename(args.file).rsplit('.', 1)[0]

    sformat = f'01d'
    outputs = []
    if args.slice > 0:
        sformat = f'0{int(math.log10(args.slice)) + 1}d'
        for i in range(0, args.slice):
            outputs.append(path.join(output_dir,f'{bname}{args.section}_{format(i, sformat)}{ext}'))
    else:
        outputs = [path.join(output_dir, bname + args.section + ext)]
    if not args.stdout and not args.force:
        for output in outputs:
            if path.isfile(output):
                print(f'Output file already exists {output}!')
                sys.exit(1)

    with open(args.file, 'r') as f:
        data = asmc.compile(args.file, f.readlines())
    if data is not None:
        section = args.section
        if section in data:
            width, length, size, bdata = data[section]
            asize = len(bdata)
            if size > 0:
                bdataf = bdata + (size - len(bdata)) * bytearray(b'\x00')
            else:
                bdataf = bdata

            for i, output in enumerate(outputs):

                y = bdataf[i::len(outputs)]
                if args.output_type == 'binary':
                    x = compiler.convert_to_binary(y)
                elif args.output_type == 'mem':
                    x = compiler.convert_to_mem(y, width=width)
                elif args.output_type == 'mif':
                    x = compiler.convert_to_mif(y, width=width, depth=len(y)/width)
                elif args.output_type == 'uhex':
                    x = compiler.convert_to_mem(y, width=width, uhex=True)
                else:
                    x = bytes(y)

                op = 'Printing' if args.stdout else 'Saving'
                print(f"{op} {args.output_type} {section} data '{output}' [Size: {len(y)}B Slice: {format(i + 1, sformat)}/{len(outputs)}]")
                if args.stdout:
                    if args.decompile:
                        print(asmc.decompile(bdata))
                    else:
                        print(x.decode())
                else:
                    with open(output, 'wb') as of:
                        of.write(x)

            print(f"Total {section} size: {len(bdata)/len(bdataf)*100:.1f}% [{len(bdata)}B/{len(bdataf)}B]")
        else:
            print(f'No such section {section}!')
    else:
        print(f'Failed to compile {args.file}!')
        sys.exit(1)
    sys.exit(0)
