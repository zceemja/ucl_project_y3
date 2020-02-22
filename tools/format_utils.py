import math
from bitstring import BitArray


def chunks(lst, n):
    """Yield successive n-sized chunks from lst."""
    for i in range(0, len(lst), n):
        yield lst[i:i + n]


def convert_to_mem(data, width, binary=False, reverse=False, packed=False):
    """
    Converts to general memory format
    :param data: array of BinArray
    :param width: width in bits
    :param binary: output in binary values
    :param reverse: reverse data order
    :param packed: do not print any commens or spaces between values
    :return: mem formatted text file
    """
    x = b''
    if width % 8 != 0 and not binary:
        raise ValueError("Cannot convert non integer byte width to hex")

    if reverse:
        data = reversed(data)
    if packed:
        arr = [(c.bin if binary else c.hex).encode() for c in data]
        return b''.join(arr)

    line_items = (8 if binary else 32)//(width//8)
    fa = f'0{math.ceil(math.ceil(math.log2(len(data))) / 4)}x'
    for i, chunk in enumerate(chunks(data, line_items)):
        arr = [(c.bin if binary else c.hex).encode() for c in chunk]
        x += b' '.join(arr) + f'  // {format(line_items*i, fa)}\n'.encode()
    return x


def convert_to_mif(data, width):
    """
    :param data: array of BinArray
    :param width: width in bits
    :return: mif formatted text file
    """
    radix = 'HEX' if width % 8 == 0 else 'BIN'
    x = f'''-- auto-generated memory initialisation file
-- total size: {sizeof_fmt(len(data) * width, 'bits', addi=False)}
DEPTH = {len(data)};
WIDTH = {width};
ADDRESS_RADIX = HEX;
DATA_RADIX = {radix};
CONTENT
BEGIN
'''.encode()
    line_items = (8 if radix == 'BIN' else 32)//(width//8)
    depth = math.ceil(math.log2(len(data)))
    addr_format = f'0{math.ceil(depth / 4)}x'
    for i, comp in enumerate(chunks(data, line_items)):
        a = ' '.join([c.bin if radix == 'BIN' else c.hex for c in comp])
        x += f'{format(i*line_items, addr_format)} : {a};\n'.encode()
    x += b"END;"
    return x


def sizeof_fmt(num, suffix='B', addi=True):
    l = ['', 'Ki', 'Mi', 'Gi', 'Ti', 'Pi', 'Ei', 'Zi'] if addi else ['', 'K', 'M', 'G', 'T', 'P', 'E', 'Z']
    for unit in l:
        if abs(num) < 1024.0:
            return "%3.1f%s%s" % (num, unit, suffix)
        num /= 1024.0
    return "%.1f%s%s" % (num, 'Yi' if addi else 'Y', suffix)


# format function map. Function input: [array of BinArray, width in bits]
FORMAT_MAP = {
    'mif':  ('mif',  convert_to_mif, {}),
    'ubin': ('ubin', convert_to_mem, {'binary': True, 'reverse': True, 'packed': True}),
    'uhex': ('uhex', convert_to_mem, {'binary': False, 'reverse': True, 'packed': True}),
    'memh': ('mem',  convert_to_mem, {'binary': False}),
    'memb': ('mem',  convert_to_mem, {'binary': True}),
}

if __name__ == '__main__':
    import argparse
    import sys
    from os import path, mkdir

    parser = argparse.ArgumentParser(description='Program formatter', add_help=True)
    parser.add_argument('file', help='Files to compile')
    parser.add_argument('-o', '--output', help='Output directory')
    parser.add_argument('-f', '--force', action='store_true', help='Force override output file')
    parser.add_argument('-s', '--stdout', action='store_true', help='Print to stdout')
    parser.add_argument('-S', '--slice', type=int, default=0, help='Slice output')
    parser.add_argument('-n', '--slice_no', type=int, default=-1, help='Output only nth slice')
    parser.add_argument('-w', '--width', type=int, default=8, help='Data width in bits')
    parser.add_argument('-t', '--output_type', choices=list(FORMAT_MAP.keys()), default='mem', help='Output type')

    args = parser.parse_args(sys.argv[1:])
    bname = path.basename(args.file).rsplit('.', 1)[0]

    if args.width < 1:
        print(f'Width must be more than 0', file=sys.stderr)
        sys.exit(1)

    if args.slice < 1:
        args.slice = 1

    if not path.isfile(args.file):
        print(f'No file {args.file}!', file=sys.stderr)
        sys.exit(1)

    output_dir = args.output or path.dirname(args.file)
    if not path.exists(output_dir):
        mkdir(output_dir)

    ifile = open(args.file, 'rb')
    binary = BitArray(ifile.read())
    ifile.close()

    if args.slice > 1 and len(binary) % (args.slice*args.width) != 0:
        print(f'File {args.file} (size {len(binary)}B) cannot be sliced into {args.slice} equal parts', file=sys.stderr)
        sys.exit(1)

    slices_bin = [binary[i * args.width:(i + 1) * args.width] for i in range(len(binary) // args.width)]
    ext, func, kwargs = FORMAT_MAP[args.output_type]

    for sno in range(args.slice):
        if args.slice_no >= 0 and args.slice_no != sno:
            continue
        if args.slice == 1:
            output = path.join(output_dir, f'{bname}.{ext}')
        else:
            output = path.join(output_dir, f'{bname}.{sno}.{ext}')

        if not args.force and not args.stdout:
            if path.isfile(output):
                print(f'Output file already exists {output}!', file=sys.stderr)
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

        slice_bin = slices_bin[sno::args.slice]
        try:
            data = func(slice_bin, args.width, **kwargs)
        except ValueError as e:
            print(e.args[0])
            continue

        if args.stdout:
            sys.stdout.write(data.decode())
        else:
            with open(output, 'wb') as f:
                f.write(data)
            print(f'Written {sizeof_fmt(len(slice_bin)*args.width, "bits", addi=False)} to {output}')
