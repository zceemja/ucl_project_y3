import csv
import sys
from os import path


def remove(datal, skipl):
    for skip in skipl:
        del datal[skip]
    return datal


if __name__ == '__main__':
    if len(sys.argv) != 3:
        print(f"Invalid arguments, usage: {sys.argv[0]} [input csv] [output verilog]")
        sys.exit(1)

    if not path.exists(sys.argv[1]):
        print(f"Input csv does not exist: {sys.argv[1]}")
        sys.exit(1)

    if not path.exists(sys.argv[2]):
        print(f"Output verilog does not exist: {sys.argv[1]}")
        sys.exit(1)

    header = []
    casename = ''
    cases = dict()
    skip = set()

    with open(sys.argv[1]) as csv_file:
        csv_reader = csv.reader(csv_file, delimiter=',')
        line_count = 0

        for row in csv_reader:
            line_count += 1
            if line_count == 1:
                casename = row[0].strip() or 'case_name'
                header = row[1:]
                for i, head in enumerate(header):
                    head = head.strip()
                    if not head:
                        skip.add(i)
                    header[i] = head
                header = remove(header, skip)
                continue
            if row[0].strip():
                cases[row[0].strip()] = list(map(lambda x: x.strip(), remove(row[1:], skip)))

    for arr in cases.values():
        for i, v in enumerate(arr):
            if set(v) == {'x'}:
                arr[i] = f"{len(v)}'b{'_'.join([v[i:i+4] for i in range(0, len(v), 4)])}"

    max_header = max(map(lambda x: len(x), header))
    max_case = max(map(lambda x: len(x), cases.keys()))

    sv_data = []
    start_line = 0
    end_line = 0

    with open(sys.argv[2], 'r') as v_file:
        line_no = 0
        for line in v_file.readlines():
            sv_data.append(line)
            line_no += 1
            if line.strip().lower() == '// generated table':
                start_line = line_no
            elif line.strip().lower() == '// generated table end':
                end_line = line_no

    if start_line == 0 or end_line <= start_line:
        print(f"Failed to find 'generated table' comment in {sys.argv[2]}")
        sys.exit(1)

    idata = ['\talways_comb begin', f'\tcasez({casename})']
    for case, value in cases.items():
        idata.append(f'\t\t{case.ljust(max_case, " ")}: begin')
        for i, head in enumerate(header):
            idata.append(f'\t\t\t{head.ljust(max_header, " ")} = {value[i]};')
        if case != 'default':
            idata.append(f'\t\t\t`ifdef ADDOP\n\t\t\top = {case};\n\t\t\t`endif')
        idata.append('\t\tend')
    idata.append('\tendcase')
    idata.append('\tend')

    with open(sys.argv[2], 'w') as v_file:
        v_file.writelines(sv_data[:start_line])
        v_file.write("\n".join(idata).replace('\t', '    ')+"\n")
        v_file.writelines(sv_data[end_line-1:])
