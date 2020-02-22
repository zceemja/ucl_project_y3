import argparse
import sys
from os import path, mkdir

import asm_compiler as compiler
from asm_compiler import InstructionError, CompilingError
import format_utils

class Compiler(compiler.Compiler):
    def compile(self, file, code):
        sections = super(Compiler, self).compile(file, code)
        return sections
        # if '.text' in sections:
        #     width, length, size, data = sections['.text']

    def decompile(self, binary):
        addr = 0
        res = []
        ibin = iter(binary)
        for data in ibin:
            src = int(next(ibin))
            imm = ((data & 16) >> 4) == 1
            dst = data & 15
            dst_name = None
            for instr in self.instr_db.values():
                if instr.opcode == dst:
                    dst_name = instr.name.upper()
            if dst_name is None:
                dst_name = "0x" + format(dst, '02x')
            asm = f'{addr:04x}: {dst_name.ljust(6)}'
            src_name = "0x" + format(src, '02x')
            if not imm and src in instrSrc:
                src_name = instrSrc[src][-1]

            line = asm + ' ' + src_name
            tabs = ' ' * (27 - int(len(line)))
            raw = format(data, '02x') + format(src, '02x')
            res.append(f'{line}{tabs}[{raw}]')
            addr += 1
        return '\n'.join(res)


asmc = Compiler(byte_order='big')

instrSrc = {
    0:  ["NULL"],
    1:  ["ALUACC0R", "ALU0"],
    2:  ["ALUACC1R", "ALU1"],
    3:  ["ADD"],
    4:  ["ADDC"],
    5:  ["SUB"],
    6:  ["SUBC"],
    7:  ["AND"],
    8:  ["OR"],
    9:  ["XOR"],
    10: ["SLL"],
    11: ["SRL"],
    12: ["EQ"],
    13: ["GT"],
    14: ["GE"],
    15: ["NE"],
    16: ["LT"],
    17: ["LE"],
    18: ["MULLO"],
    19: ["MULHI"],
    20: ["DIV"],
    21: ["MOD"],
    22: ["BRPT0R", "BR0"],
    23: ["BRPT1R", "BR1"],
    24: ["PC0"],
    25: ["PC1"],
    26: ["MEMPT0R", "MEM0"],
    27: ["MEMPT1R", "MEM1"],
    28: ["MEMPT2R", "MEM2"],
    29: ["MEMLWHI", "LWHI", "MEMHI"],
    30: ["MEMLWLO", "LWLO", "MEMLO"],
    31: ["STACKR", "STACK"],
    32: ["STACKPT0", "STPT0"],
    33: ["STACKPT1", "STPT1"],
    34: ["COMAR", "COMA"],
    35: ["COMDR", "COMD"],
    36: ["REG0R", "REG0"],
    37: ["REG1R", "REG1"],
    38: ["ADC"],
    39: ["SBC"],
    40: ["ROL"],
    41: ["ROR"],
}
instrMap = {}
for i, v in instrSrc.items():
    for n in v:
        instrMap[n.lower()] = i


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
        return 1

    def __len__(self):
        return 1

    def compile(self, operands, scope):
        if len(operands) != 1:
            raise CompilingError(f"Instruction has invalid amount of operands")

        if operands[0].lower() in instrMap:
            src = instrMap[operands[0].lower()]
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
asmc.add_instr(InstructionDest("SWHI", 9, alias=["MEMSWHI", "MEMHI"]))
asmc.add_instr(InstructionDest("SWLO", 10, alias=["MEMSWLO", "MEMLO"]))
asmc.add_instr(InstructionDest("COMA", 11))
asmc.add_instr(InstructionDest("COMD", 12))
asmc.add_instr(InstructionDest("REG0", 13))
asmc.add_instr(InstructionDest("REG1", 14))


if __name__ == '__main__':
    compiler.main(asmc)
    # parser = argparse.ArgumentParser(description='Assembly compiler', add_help=True)
    # parser.add_argument('file', help='Files to compile')
    # parser.add_argument('-t', '--output_type', choices=['bin', 'mem', 'binary', 'mif', 'uhex', 'ubin'], default='mem',
    #                     help='Output type')
    # parser.add_argument('-S', '--slice', default=0, type=int, help='Slice output for section')
    # parser.add_argument('-o', '--output', help='Output directory')
    # parser.add_argument('-f', '--force', action='store_true', help='Force override output file')
    # parser.add_argument('-s', '--stdout', action='store_true', help='Print to stdout')
    # parser.add_argument('-D', '--decompile', action='store_true', help='Print decompiled')
    # parser.add_argument('section', help='Section')
    # args = parser.parse_args(sys.argv[1:])
    # if not path.isfile(args.file):
    #     print(f'No file {args.file}!')
    #     sys.exit(1)
    #
    # output_dir = args.output or path.dirname(args.file)
    # if not path.exists(output_dir):
    #     mkdir(output_dir)
    #
    # if args.output_type == 'mem' or args.output_type == 'binary':
    #     ext = '.mem'
    # elif args.output_type == 'bin':
    #     ext = '.bin'
    # elif args.output_type == 'mif':
    #     ext = '.mif'
    # elif args.output_type == 'uhex':
    #     ext = '.uhex'
    # elif args.output_type == 'ubin':
    #     ext = '.ubin'
    # else:
    #     ext = '.out'
    # bname = path.basename(args.file).rsplit('.', 1)[0]
    #
    # outputs = []
    # if args.slice > 0:
    #     for i in range(0, args.slice):
    #         outputs.append(path.join(output_dir, f'{bname}{args.section}_{i}{ext}'))
    # else:
    #     outputs = [path.join(output_dir, bname + args.section + ext)]
    # if not args.stdout and not args.force:
    #     for output in outputs:
    #         if path.isfile(output):
    #             print(f'Output file already exists {output}!')
    #             sys.exit(1)
    #
    # data = asmc.compile_file(args.file)
    # if data is not None:
    #     section = args.section
    #     if section in data:
    #         width, length, size, bdata = data[section]
    #         asize = len(bdata)
    #
    #         if size > 0:
    #             bdataf = bdata + (size - len(bdata)) * bytearray(b'\x00')
    #         else:
    #             bdataf = bdata
    #
    #         bitwidth = width * 8
    #         if section == '.text':
    #             if len(bdata) % 4 != 0:
    #                 bdata += b'\x00\x00'
    #             bitblocks = [
    #                 format(int.from_bytes(bdataf[i * 4:i * 4 + 2], 'big'), f'013b') +
    #                 format(int.from_bytes(bdataf[i * 4 + 2:i * 4 + 4], 'big'), f'013b')
    #                 for i in range(0, len(bdataf) // 4)
    #             ]
    #             bitblocks += ['0'*26] * (size//3 - len(bitblocks))
    #             # calculate parity bit
    #             bitblocks = [b + str(b.count('1') % 2) for b in bitblocks]
    #             # divide into 3 for each memory chip
    #         else:
    #             bitblocks = [
    #                 format(int.from_bytes(bdataf[i * width:i * width + width], 'big'), f'0{bitwidth}b')
    #                 for i in range(len(bdataf) // width)
    #             ]
    #             # bitblocks = [bdataf]
    #             # bitstring = ''.join(bits)
    #             # bitstring += len(bitstring) % 8 * 27 * '0'  # fill to the integer byte
    #             # x = int(bitstring, 2).to_bytes(len(bitstring) // 8, 'big')
    #
    #         for i, output in enumerate(outputs):
    #             block_chunks = []
    #             chunk_width = 9 if section == '.text' else 16
    #             for block in bitblocks:
    #                 for j in range(len(outputs)):
    #                     block_chunks.append(block[chunk_width * j:chunk_width * (j+1)])
    #
    #             y = block_chunks[i::len(outputs)]
    #             if args.output_type == 'binary':
    #                 x = '\n'.join(y).encode()
    #             elif args.output_type == 'mif':
    #                 x = format_utils.convert_to_mif(y, width=bitwidth)
    #             else:
    #                 from bitstring import BitArray
    #                 # merge bits chunks info bytes
    #                 y = BitArray(bin='0b'+''.join(y)).bytes
    #                 if args.output_type == 'mem':
    #                     x = format_utils.convert_to_mem(y, width=1, uhex=True, reverse=True)
    #                 elif args.output_type == 'uhex':
    #                     x = format_utils.convert_to_mem(y, width=width, uhex=True)
    #                 elif args.output_type == 'ubin':
    #                     x = format_utils.convert_to_binary(reversed(y), width=width)
    #                 else:
    #                     x = bytes(y)
    #
    #             op = 'Printing' if args.stdout else 'Saving'
    #             print(f"{op} {args.output_type} {section} data '{output}' [Size: {len(y)}B Slice: {i+1}/{len(outputs)}]")
    #             if args.stdout:
    #                 if args.decompile:
    #                     print(asmc.decompile(bdata))
    #                 else:
    #                     print(x.decode())
    #             else:
    #                 with open(output, 'wb') as of:
    #                     of.write(x)
    #         if section == '.text':
    #             insUsed = int(asize)//2
    #             insTotal = size//2
    #             print(f"Total {section} size: {insUsed / insTotal * 100:.1f}% "
    #                   f"[ {insUsed} instr / {insTotal} instr ]")
    #         else:
    #             print(f"Total {section} size: {asize / len(bdataf) * 100:.1f}% [{int(asize)}B/{len(bdataf)}B]")
    #     else:
    #         print(f'No such section {section}!')
    # else:
    #     print(f'Failed to compile {args.file}!')
    #     sys.exit(1)
    # sys.exit(0)
