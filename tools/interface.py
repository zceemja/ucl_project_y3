import curses
import math
from quartus_tcl import INSYS_SPI_ERROR, INSYS_MEM_ERROR, QuartusTCL, QUATUS_TCL_TIMEOUT
from . import oisc8asm

def render_list(w, items, offset=3):
    selected = 0
    while True:
        w.refresh()
        curses.doupdate()
        index = 0
        for item in items:
            mode = curses.A_REVERSE if index == selected else curses.A_NORMAL
            w.addstr(offset + index, 2, item, mode)
            index += 1
        key = w.getch()
        if key in [curses.KEY_ENTER, ord('\n')]:
            break
        elif key == curses.KEY_UP:
            selected -= 1
            if selected < 0:
                selected = len(items) - 1
        elif key == curses.KEY_DOWN:
            selected += 1
            if selected >= len(items):
                selected = 0
        elif key == curses.KEY_BACKSPACE or key == 27 or key == ord('q'):  # esc | alt | q
            selected = -1
            break
    return selected


def reprint_header(w, q=None, hw=None, dev=None):
    w.addstr(0, 0, "Processor debugging interface", curses.color_pair(1))
    if q is not None:
        w.addstr(1, 0, "Connected: ", curses.A_BOLD)
        w.addstr(q.version)
        w.addstr(2, 0, "")
        if hw is not None:
            w.addstr("Hardware: ", curses.A_BOLD)
            w.addstr(hw)
        if dev is not None:
            w.addstr(" Device: ", curses.A_BOLD)
            w.addstr(dev)
    w.clrtobot()


def read_probes(ps, q, pren):
    res = []
    for i, src_width, prb_width, name in ps:
        value = []
        if pren and src_width > 0:
            try:
                value.append(q.read_source_data(i, True))
            except INSYS_SPI_ERROR:
                value.append('ERR')
        if pren and prb_width > 0:
            try:
                value.append(q.read_probe_data(i, True))
            except INSYS_SPI_ERROR:
                value.append('ERR')
        if len(value) == 0:
            value.append('??')
        res.append(value)
    return res


def memeditor(w, q, hw, dev, mem):
    error = None
    try:
        memedit_window(w, q, hw, dev, mem)
    except INSYS_MEM_ERROR as e:
        error = e.args[0]
    except curses.error:
        error = 'Terminal window is too small'
    finally:
        try:
            q.end_memory_edit()
        except INSYS_MEM_ERROR:
            pass
        if error is not None:
            w.addstr(4, 0, "ERROR: ", curses.color_pair(4) | curses.A_BOLD)
            w.addstr(error, curses.color_pair(4))
            w.clrtobot()
            w.refresh()
            w.getch()


def input_window(w, mode, x, y, length):
    curses.curs_set(1)
    index = 0
    new_val = [''] * length
    escape = False
    try:
        while True:
            w.refresh()
            curses.doupdate()
            for i, val in enumerate(new_val):
                if val == '':
                    val = '_'
                w.addch(y, x + i, val, curses.A_BOLD)
            w.move(y, x + index)
            key = w.getch()
            if key == curses.KEY_LEFT:
                if index > 0:
                    index -= 1
            elif key == curses.KEY_RIGHT:
                if index + 1 < length:
                    index += 1
            elif key == curses.KEY_BACKSPACE:
                new_val[index] = ''
                if index > 0:
                    index -= 1
            elif key == curses.KEY_ENTER or key == ord('\n'):
                break
            elif key == 27:
                escape = True
                break
            else:
                if (mode == 'd' and ord('0') <= key <= ord('9')) or \
                        (mode == 'b' and ord('0') <= key <= ord('1')) or \
                        (mode == 'h' and (ord('0') <= key <= ord('9') or ord('a') <= key <= ord('f'))) or \
                        (mode == 'a' and 32 <= key <= 126):
                    new_val[index] = chr(key)
                    if index + 1 < length:
                        index += 1
    except curses.error:
        pass
    curses.curs_set(0)
    if escape:
        return None
    return new_val


def convert_to_ascii(value):
    """ converts binary string to ascii """
    r = ''
    for b in range(len(value) // 8):
        dec = int(value[b * 8:b * 8 + 8], 2)
        if 32 <= dec <= 126:
            r += chr(dec)
        else:
            r += '.'
    return r


def read_mem(raw_mem, width, depth):
    data = list(reversed([raw_mem[i * width:i * width + width] for i in range(depth)]))
    data_hex = list(map(lambda x: format(int(x, 2), f'0{math.ceil(width / 4)}x'), data))
    data_ascii = data
    dec_format_len = len(str(2 ** width))
    dec_format = f'0{dec_format_len}d'
    if width % 8 == 0:
        data_ascii = list(map(lambda x: convert_to_ascii(x), data))
    data_dec = list(map(lambda x: format(int(x, 2), dec_format), data))
    return data, data_hex, data_ascii, data_dec, dec_format_len, dec_format


def memedit_window(w, q, hw, dev, mem):
    mem_index, depth, width, mode, itype, name = mem

    w.addstr(3, 0, "Memory editor: ", curses.color_pair(2) | curses.A_BOLD)
    w.addstr(name, curses.A_BOLD)
    w.addstr(f" {mode} {itype} {depth}bit x {width}")
    iy, ix = w.getyx()  # save to it can be edited later
    w.clrtobot()
    w.addstr(4, 0, "String the memory editing sequence..", curses.color_pair(1))
    w.refresh()
    q.begin_memory_edit(dev, hw)
    w.addstr(4, 0, "Reading memory..", curses.color_pair(1))
    w.clrtoeol()
    w.refresh()
    raw_mem = q.read_content_from_memory(mem_index, 0, depth)
    data, data_hex, data_ascii, data_dec, dec_format_len, dec_format = read_mem(raw_mem, width, depth)
    selected = 0
    offset = 0
    draw_mode = 'h'
    addr_len = math.ceil(math.log2(depth) / 4) + 2
    addr_format = f'0{addr_len - 2}x'
    moded = {}
    while True:
        w.refresh()
        curses.doupdate()

        if draw_mode == 'h':
            sdata = data_hex
        elif draw_mode == 'a':
            sdata = data_ascii
        elif draw_mode == 'd':
            sdata = data_dec
        else:
            sdata = data

        xmax, ymax = w.getmaxyx()
        dwidth = width
        if draw_mode == 'h':
            dwidth = math.ceil(width / 4)
        elif draw_mode == 'a':
            dwidth = width // 8
        elif draw_mode == 'd':
            dwidth = dec_format_len
        cols = (ymax - addr_len) // (dwidth + 1) - 1
        rows = xmax - 4
        # rows = 1
        info = [
            f'ADDR: {format(selected, addr_format)}',
            f'OFFSET: {offset}',
            f'BIN: {data[selected]}',
            f'HEX: {data_hex[selected]}',
            f'DEC: {data_dec[selected]}'
        ]
        if width % 8 == 0:
            info.append(f'ASCII: {convert_to_ascii(data[selected])}')
        w.addstr(iy, ix + 10, f"[{' '.join(info)}]", curses.color_pair(1))
        w.clrtoeol()
        for row in range(0, rows):
            row_off = row + offset
            w.addstr(4 + row, 0, format(row_off * cols, addr_format) + ": ", curses.A_BOLD)
            done = False
            for col in range(cols):
                index = row_off * cols + col
                if index + 1 > depth:
                    w.clrtobot()
                    done = True
                    break
                smode = curses.A_REVERSE if index == selected else curses.A_NORMAL
                if index in moded:
                    if draw_mode == 'h':
                        val = format(moded[index], f'0{dwidth}x')
                    elif draw_mode == 'a':
                        val = convert_to_ascii(format(moded[index], f'0{width}b'))
                    elif draw_mode == 'd':
                        val = format(moded[index], f'0{dwidth}d')
                    else:
                        val = format(moded[index], f'0{width}b')
                    w.addstr(val, curses.color_pair(3) | smode | curses.A_BOLD)
                else:
                    w.addstr(sdata[index], smode)
                if col + 1 == cols:
                    w.clrtoeol()
                else:
                    w.addstr(' ')
            if done:
                break

        selected_row = selected // cols - offset
        if selected > cols and selected_row == 0:
            offset -= 1
        elif selected_row == rows - 2:
            offset += 1

        key = w.getch()
        if key == ord(' '):
            raw_mem = q.read_content_from_memory(mem_index, 0, depth)
            data, data_hex, data_ascii, data_dec, dec_format_len, dec_format = read_mem(raw_mem, width, depth)
        elif key == ord('h'):
            draw_mode = 'h'
        elif key == ord('b'):
            draw_mode = 'b'
        elif key == ord('d'):
            draw_mode = 'd'
        elif key == ord('a') and width % 8 == 0:
            draw_mode = 'a'
        elif key == ord('r'):
            if selected in moded:
                del moded[selected]
        elif key == ord('s'):
            for i, val in moded.items():
                data[i] = val
            content = ''.join(list(reversed(data)))
            q.write_content_to_memory(mem_index, 0, depth, content)
        elif key in {curses.KEY_ENTER, ord('\n')}:
            row = selected//cols
            col = selected - cols*row
            current_val = sdata[selected]
            res = input_window(w, draw_mode, col * (dwidth+1) + addr_len, row+4, dwidth)
            new_val = ''.join([res[i] if res[i] != '' else current_val[i] for i in range(len(current_val))])
            try:
                if draw_mode == 'h':
                    moded[selected] = int(new_val, 16)
                elif draw_mode == 'a':
                    moded[selected] = 0
                    for i in range(len(new_val)):
                        moded[selected] |= ord(new_val[i]) << ((len(new_val)-1-i)*8)
                elif draw_mode == 'd':
                    moded[selected] = int(new_val)
                else:
                    moded[selected] = int(new_val, 2)
            except ValueError:
                pass
        elif key == curses.KEY_LEFT:
            if selected > 0:
                selected -= 1
        elif key == curses.KEY_RIGHT:
            if selected + 1 < len(data):
                selected += 1
        elif key == curses.KEY_UP:
            if selected - cols >= 0:
                selected -= cols
        elif key == curses.KEY_DOWN:
            if selected + cols < len(data):
                selected += cols
        elif key == curses.KEY_BACKSPACE or key == 27 or key == ord('q'):
            return


def oisc_comments(probe, value):
    try:
        data = int(value[0], 16)
    except ValueError:
        return None
    except IndexError:
        return None

    if probe == "INST":
        val = oisc8asm.asmc.decompile([data]).split('\n')[0]
        return val
    return None


def debugging_window(w, q, hw, dev, ps, mem, pren):
    w.addstr(3, 0, "      Probes:", curses.color_pair(2) | curses.A_BOLD)
    w.clrtoeol()
    w.addstr(3, 30, "Memory:", curses.color_pair(2) | curses.A_BOLD)
    w.clrtobot()
    selected = 0
    srow = 0
    profile = False
    ps_map = {name: (i, src_width, prb_width) for i, src_width, prb_width, name in ps}
    if pren and 'RST' in ps_map and 'CLKD' in ps_map and 'MCLK' in ps_map:
        ## This is oisc
        profile = True
        q.write_source_data(ps_map['RST'][0], '1')
        q.write_source_data(ps_map['CLKD'][0], '1')
        q.write_source_data(ps_map['MCLK'][0], '1')
        q.write_source_data(ps_map['MCLK'][0], '0')
        q.write_source_data(ps_map['RST'][0], '0')
    values = read_probes(ps, q, pren)
    while True:
        try:
            w.refresh()
            curses.doupdate()
            index = 0
            # <index> <source width> <probe width> <instance name>
            for i, src_width, prb_width, name in ps:
                mode = curses.A_REVERSE if index == selected and srow == 0 else curses.A_NORMAL
                w.addstr(4 + index, 0, f" {name:>4} [{src_width:>2}|{prb_width:>2}]: ", curses.A_BOLD)
                data = values[i]
                for di, d in enumerate(data):
                    if d == 'ERR':
                        w.addstr(d, curses.color_pair(4) | mode)
                    else:
                        w.addstr(d, mode)
                    if di < len(data) - 1:
                        w.addstr('|', mode)
                if profile:
                    comment = oisc_comments(name, data)
                    if comment is not None:
                        w.addstr(' ' + comment, curses.color_pair(1))
                w.clrtoeol()
                index += 1
            # <index> <depth> <width> <read/write mode> <instance type> <instance name>
            index = 0
            for i, depth, width, mode, itype, name in mem:
                smode = curses.A_REVERSE if index == selected and srow == 1 else curses.A_NORMAL
                w.addstr(4 + index, 31, f"{name:>5}: ", curses.A_BOLD)
                w.addstr(f"[{width}bit x {depth} {mode} {itype}]", smode)
                w.clrtoeol()
                index += 1

            key = w.getch()
            if key == ord(' '):
                if profile:
                    q.write_source_data(ps_map['MCLK'][0], '0')
                    q.write_source_data(ps_map['MCLK'][0], '1')
                values = read_probes(ps, q, pren)
            elif key in {curses.KEY_ENTER, ord('\n')}:
                if srow == 0 and pren:
                    i, src_width, prb_width, name = ps[selected]
                    # Flip single bit
                    if src_width == 1 and values[selected][0].isdigit():
                        new_val = 1 if values[selected][0] == '0' else 0
                        q.write_source_data(i, new_val)
                    values = read_probes(ps, q, pren)
                elif srow == 1:
                    memeditor(w, q, hw, dev, mem[selected])
                    w.addstr(3, 0, "      Probes:", curses.color_pair(2) | curses.A_BOLD)
                    w.clrtoeol()
                    w.addstr(3, 30, "Memory:", curses.color_pair(2) | curses.A_BOLD)
                    w.clrtobot()

            elif key == curses.KEY_LEFT or key == curses.KEY_RIGHT:
                srow = 0 if srow == 1 else 1
                if srow == 0 and selected >= len(ps):
                    selected = len(ps) - 1
                elif srow == 1 and selected >= len(mem):
                    selected = len(mem) - 1
            elif key == curses.KEY_UP:
                selected -= 1
                if selected < 0:
                    selected = len(ps) - 1 if srow == 0 else len(mem) - 1
            elif key == curses.KEY_DOWN:
                selected += 1
                if srow == 0 and selected >= len(ps):
                    selected = 0
                if srow == 1 and selected >= len(mem):
                    selected = 0
            elif key == curses.KEY_BACKSPACE or key == 27 or key == ord('q'):  # esc | alt | q
                break
        except curses.error:
            w.addstr(4, 2, "ERROR: ", curses.color_pair(4) | curses.A_BOLD)
            w.addstr("Terminal window is too small", curses.color_pair(4))
            key = w.getch()
            if key == curses.KEY_BACKSPACE or key == 27 or key == ord('q'):  # esc | alt | q
                break


def main(w):
    """ INIT """
    w.keypad(1)
    # screen.nodelay(1)
    curses.curs_set(0)
    curses.start_color()
    curses.use_default_colors()

    # panel = curses.panel.new_panel(w)
    # panel.hide()
    # curses.panel.update_panels()

    curses.init_pair(1, curses.COLOR_WHITE, -1)
    curses.init_pair(2, curses.COLOR_CYAN, -1)
    curses.init_pair(3, curses.COLOR_MAGENTA, -1)
    curses.init_pair(4, curses.COLOR_RED, -1)
    reprint_header(w)

    """ START """
    w.addstr(1, 0, "Connecting to Quartus Prime Signal Tap shell..")
    w.refresh()

    q = QuartusTCL()

    """ LIST Devices """
    # panel.top()
    # panel.show()
    while True:
        reprint_header(w, q, None, None)
        w.addstr(2, 1, "Loading list..")
        w.refresh()
        try:
            devices = {h: q.get_device_names(h) for h in q.get_hardware_names()}
            menu_map = [(h, d) for h, ds in devices.items() for d in ds]
            menu_list = list(map(lambda x: x[0] + ': ' + x[1], menu_map))
            w.addstr(2, 0, "")
            w.clrtoeol()
        except QUATUS_TCL_TIMEOUT:
            w.addstr(2, 1, "Timeout!", curses.color_pair(4) | curses.A_BOLD)
            w.clrtoeol()
            menu_list = []
        menu_list.append('Update list')
        selected = render_list(w, menu_list)
        if selected == len(menu_list) - 1:
            continue  # update list
        if selected >= 0:
            w.clear()
            hw, dev = menu_map[selected]
            reprint_header(w, q, hw, dev)
            w.addstr(3, 2, "Checking device in-system sources and probes..")
            w.refresh()
            try:
                spis = q.get_insystem_source_probe_instance_info(dev, hw)
                w.addstr(3, 2, f"Found {len(spis)} source/probe instances..")
                w.clrtoeol()
            except INSYS_SPI_ERROR as e:
                w.addstr(3, 2, "ERROR: ", curses.color_pair(4) | curses.A_BOLD)
                w.addstr(e.message, curses.color_pair(4))
                spis = []
            w.refresh()
            w.addstr(4, 2, "Checking device in-system memory..")
            try:
                mems = q.get_editable_mem_instances(dev, hw)
                w.addstr(4, 2, f"Found {len(mems)} memory instances..")
                w.clrtoeol()
            except INSYS_MEM_ERROR as e:
                w.addstr(4, 2, "ERROR: ", curses.color_pair(4) | curses.A_BOLD)
                w.addstr(e.message, curses.color_pair(4))
                mems = []
            w.refresh()
            try:
                q.start_insystem_source_probe(dev, hw)
                w.addstr(5, 2, f"In-system transactions started..")
                pren = True
            except INSYS_SPI_ERROR as e:
                w.addstr(5, 2, "ERROR: ", curses.color_pair(4) | curses.A_BOLD)
                w.addstr("Transaction setup failed: " + e.message, curses.color_pair(4))
                pren = False
            w.refresh()
            w.addstr(6, 4, "Press any key to start..", curses.color_pair(1))
            w.getch()
            debugging_window(w, q, hw, dev, spis, mems, pren)
            try:
                if pren:
                    q.end_insystem_source_probe()
            except INSYS_SPI_ERROR as e:
                w.addstr(3, 2, "ERROR: ", curses.color_pair(4) | curses.A_BOLD)
                w.addstr(e.message, curses.color_pair(4))
                w.clrtobot()
                w.refresh()
                w.getch()
            continue
        break
    q.disconnect()

    # except Exception as e:
    #     print("Unexpected error:" + e.args[0])
