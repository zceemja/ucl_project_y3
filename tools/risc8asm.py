import argparse
import sys
import math
from os import path, mkdir

import asm_compiler as compiler

asmc = compiler.Compiler(byte_order='big')
asmc.add_reg('r0', 0)
asmc.add_reg('r1', 1)
asmc.add_reg('r2', 2)
asmc.add_reg('r3', 3)

asmc.add_instr(compiler.Instruction('CPY0 ', '0000_0000', 1, alias=['COPY0']))
asmc.add_instr(compiler.Instruction('CPY1 ', '0000_0101', 1, alias=['COPY1']))
asmc.add_instr(compiler.Instruction('CPY2 ', '0000_1010', 1, alias=['COPY2']))
asmc.add_instr(compiler.Instruction('CPY3 ', '0000_1111', 1, alias=['COPY3']))

asmc.add_instr(compiler.Instruction('MOVE ', '0000_????', alias=['MOV']))
asmc.add_instr(compiler.Instruction('ADD  ', '0001_????'))
asmc.add_instr(compiler.Instruction('SUB  ', '0010_????'))
asmc.add_instr(compiler.Instruction('AND  ', '0011_????'))
asmc.add_instr(compiler.Instruction('OR   ', '0100_????'))
asmc.add_instr(compiler.Instruction('XOR  ', '0101_????'))
asmc.add_instr(compiler.Instruction('MUL  ', '0110_????'))
asmc.add_instr(compiler.Instruction('DIV  ', '0111_????'))

asmc.add_instr(compiler.Instruction('CI0  ', '1000_??00'))
asmc.add_instr(compiler.Instruction('CI1  ', '1000_??01'))
asmc.add_instr(compiler.Instruction('CI2  ', '1000_??10'))
asmc.add_instr(compiler.Instruction('ADDC ', '1000_??11'))

asmc.add_instr(compiler.Instruction('ADDI',  '1110_??00', 1))
asmc.add_instr(compiler.Instruction('SUBI ', '1110_??01', 1))
asmc.add_instr(compiler.Instruction('ANDI ', '1110_??10', 1))
asmc.add_instr(compiler.Instruction('ORI  ', '1110_??11', 1))
asmc.add_instr(compiler.Instruction('XORI ', '1100_??11', 1))

asmc.add_instr(compiler.Instruction('SLL  ', '1001_??00', 1))
asmc.add_instr(compiler.Instruction('SRL  ', '1001_??01', 1))
asmc.add_instr(compiler.Instruction('SRA  ', '1001_??10', 1))
asmc.add_instr(compiler.Instruction('SRAS ', '1001_??11'))
asmc.add_instr(compiler.Instruction('LWHI ', '1010_??00', 3))
asmc.add_instr(compiler.Instruction('SWHI ', '1010_??01'))
asmc.add_instr(compiler.Instruction('LWLO ', '1010_??10', 3))
asmc.add_instr(compiler.Instruction('SWLO ', '1010_??11', 3))
asmc.add_instr(compiler.Instruction('INC  ', '1011_??00'))
asmc.add_instr(compiler.Instruction('DEC  ', '1011_??01'))
asmc.add_instr(compiler.Instruction('GETAH', '1011_??10'))
asmc.add_instr(compiler.Instruction('GETIF', '1011_??11'))
asmc.add_instr(compiler.Instruction('PUSH ', '1100_??00'))
asmc.add_instr(compiler.Instruction('POP  ', '1100_??01'))
asmc.add_instr(compiler.Instruction('COM  ', '1100_??10', 1))
asmc.add_instr(compiler.Instruction('SETI ', '1100_??11'))
asmc.add_instr(compiler.Instruction('BEQ  ', '1101_??00', 3))
asmc.add_instr(compiler.Instruction('BGT  ', '1101_??01', 3))
asmc.add_instr(compiler.Instruction('BGE  ', '1101_??10', 3))
asmc.add_instr(compiler.Instruction('BZ   ', '1101_??11', 2))
asmc.add_instr(compiler.Instruction('CALL ', '1111_0000', 2))
asmc.add_instr(compiler.Instruction('RET  ', '1111_0001'))
asmc.add_instr(compiler.Instruction('JUMP ', '1111_0010', 2))
asmc.add_instr(compiler.Instruction('INTRE', '1111_1110', 2))
asmc.add_instr(compiler.Instruction('RETI ', '1111_0011'))
asmc.add_instr(compiler.Instruction('CLC  ', '1111_0100'))
asmc.add_instr(compiler.Instruction('SETC ', '1111_0101'))
asmc.add_instr(compiler.Instruction('CLS  ', '1111_0110'))
asmc.add_instr(compiler.Instruction('SETS ', '1111_0111'))
asmc.add_instr(compiler.Instruction('SSETS', '1111_1000'))
asmc.add_instr(compiler.Instruction('CLN  ', '1111_1001'))
asmc.add_instr(compiler.Instruction('SETN ', '1111_1010'))
asmc.add_instr(compiler.Instruction('SSETN', '1111_1011'))
asmc.add_instr(compiler.Instruction('RJUMP', '1111_1100', 2))
asmc.add_instr(compiler.Instruction('RBWI ', '1111_1101'))

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

            print(f"Total {section} size: {len(bdata)}B [{len(bdataf)}B]")
        else:
            print(f'No such section {section}!')
    else:
        print(f'Failed to compile {args.file}!')
        sys.exit(1)
    sys.exit(0)
