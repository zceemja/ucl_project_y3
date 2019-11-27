import argparse
import sys
import math
from os import path

import asm_compiler as compiler

asmc = compiler.Compiler(byte_order='big')
asmc.add_reg('r0', 0)
asmc.add_reg('r1', 1)
asmc.add_reg('r2', 2)
asmc.add_reg('r3', 3)


class MoveInstr(compiler.Instruction):
    def compile(self, operands):
        regs = [0, 0]
        imm = []
        regs[0] = self.compiler.decode_reg(operands[0])
        try:
            regs[1] = self.compiler.decode_reg(operands[1])
            self.imm_operands = 0
        except compiler.CompilingError:
            regs[1] = regs[0]
            self.imm_operands = 1
            imm = [self.compiler.decode_bytes(operands[1])]
        instr = self._gen_instr(regs, imm)
        return [instr] + imm


asmc.add_instr(MoveInstr('MOVE ', 'b0000_????'))
asmc.add_instr(compiler.Instruction('ADD  ', 'b0001_????'))
asmc.add_instr(compiler.Instruction('SUB  ', 'b0010_????'))
asmc.add_instr(compiler.Instruction('AND  ', 'b0011_????'))
asmc.add_instr(compiler.Instruction('OR   ', 'b0100_????'))
asmc.add_instr(compiler.Instruction('XOR  ', 'b0101_????'))
asmc.add_instr(compiler.Instruction('MUL  ', 'b0110_????'))
asmc.add_instr(compiler.Instruction('DIV  ', 'b0111_????'))
asmc.add_instr(compiler.Instruction('BR   ', 'b1000_????', 2))
asmc.add_instr(compiler.Instruction('SLL  ', 'b1001_??00'))
asmc.add_instr(compiler.Instruction('SRL  ', 'b1001_??01'))
asmc.add_instr(compiler.Instruction('SRA  ', 'b1001_??10'))
asmc.add_instr(compiler.Instruction('SRAS ', 'b1001_??11'))
asmc.add_instr(compiler.Instruction('LWHI ', 'b1010_??00', 3))
asmc.add_instr(compiler.Instruction('SWHI ', 'b1010_??01'))
asmc.add_instr(compiler.Instruction('LWLO ', 'b1010_??10', 3))
asmc.add_instr(compiler.Instruction('SWLO ', 'b1010_??11', 3))
asmc.add_instr(compiler.Instruction('INC  ', 'b1011_??00'))
asmc.add_instr(compiler.Instruction('DEC  ', 'b1011_??01'))
asmc.add_instr(compiler.Instruction('GETAH', 'b1011_??10'))
asmc.add_instr(compiler.Instruction('GETIF', 'b1011_??11'))
asmc.add_instr(compiler.Instruction('PUSH ', 'b1100_??00'))
asmc.add_instr(compiler.Instruction('POP  ', 'b1100_??01'))
asmc.add_instr(compiler.Instruction('COM  ', 'b1100_??10', 1))
asmc.add_instr(compiler.Instruction('SETI ', 'b1100_??11'))
asmc.add_instr(compiler.Instruction('BEQ  ', 'b1101_??00', 3))
asmc.add_instr(compiler.Instruction('BGT  ', 'b1101_??01', 3))
asmc.add_instr(compiler.Instruction('BGE  ', 'b1101_??10', 3))
asmc.add_instr(compiler.Instruction('BZ   ', 'b1101_0011'))
asmc.add_instr(compiler.Instruction('CALL ', 'b1111_0000', 2))
asmc.add_instr(compiler.Instruction('RET  ', 'b1111_0001'))
asmc.add_instr(compiler.Instruction('JUMP ', 'b1111_0010', 2))
asmc.add_instr(compiler.Instruction('RETI ', 'b1111_0011'))
asmc.add_instr(compiler.Instruction('CLC  ', 'b1111_0100'))
asmc.add_instr(compiler.Instruction('SETC ', 'b1111_0101'))
asmc.add_instr(compiler.Instruction('CLS  ', 'b1111_0110'))
asmc.add_instr(compiler.Instruction('SETS ', 'b1111_0111'))
asmc.add_instr(compiler.Instruction('SSETS', 'b1111_1000'))
asmc.add_instr(compiler.Instruction('CLN  ', 'b1111_1001'))
asmc.add_instr(compiler.Instruction('SETN ', 'b1111_1010'))
asmc.add_instr(compiler.Instruction('SSETN', 'b1111_1011'))
asmc.add_instr(compiler.Instruction('RJUMP', 'b1111_1100', 2))
asmc.add_instr(compiler.Instruction('RBWI ', 'b1111_1101'))


if __name__ == '__main__':
    parser = argparse.ArgumentParser(description='Assembly compiler', add_help=True)
    parser.add_argument('file', help='Files to compile')
    parser.add_argument('-t', '--output_type', choices=['bin', 'mem', 'binary', 'mif'], default='mem', help='Output type')
    parser.add_argument('-S', '--slice', type=int, default=0, help='if defined, output to multiple sliced files')
    parser.add_argument('-o', '--output', help='Output file')
    parser.add_argument('-f', '--force', action='store_true', help='Force override output file')
    parser.add_argument('-s', '--stdout', action='store_true', help='Print to stdout')
    parser.add_argument('-l', '--size', type=int, default=0, help='if defined, fill rest of memory with 0x00')
    args = parser.parse_args(sys.argv[1:])
    if not path.isfile(args.file):
        print(f'No file {args.file}!')
        sys.exit(1)


    output = args.output
    if not output:
        bname = args.file.rsplit('.', 1)
        if args.output_type == 'mem':
            ext = '.mem'
        elif args.output_type == 'bin':
            ext = '.bin'
        elif args.output_type == 'mif':
            ext = '.mif'
        else:
            ext = '.out'
        output = bname[0] + ext
    outputs = []

    sformat = f'01d'
    if args.slice > 0:
        sformat = f'0{int(math.log10(args.slice)) + 1}d'
        for i in range(0, args.slice):
            bname = output.rsplit('.', 1)
            outputs.append(f'{bname[0]}_{format(i, sformat)}.{bname[1]}')
    else:
        outputs = [output]
    if not args.stdout and not args.force:
        for output in outputs:
            if path.isfile(output):
                print(f'Output file already exists {output}!')
                sys.exit(1)

    with open(args.file, 'r') as f:
        data = asmc.compile(args.file, f.readlines())
    if data is not None:
        if args.size > 0:
            data = data + (args.size - len(data)) * bytearray(b'\x00')

        for i, output in enumerate(outputs):

            y = data[i::len(outputs)]
            if args.output_type == 'binary':
                x = compiler.convert_to_binary(y)
            elif args.output_type == 'mem':
                x = compiler.convert_to_mem(y)
            elif args.output_type == 'mif':
                x = compiler.convert_to_mif(y, depth=len(y))
            else:
                x = bytes(y)

            op = 'Printing' if args.stdout else 'Saving'
            print(f"{op} {args.output_type} data '{output}' [Size: {len(y)}B Slice: {format(i + 1, sformat)}/{len(outputs)}]")
            if args.stdout:
                print(x.decode())
            else:
                with open(output, 'wb') as of:
                    of.write(x)

        print(f"Total program size: {len(data)}B")
    else:
        print(f'Failed to compile {args.file}!')
        sys.exit(1)
    sys.exit(0)
