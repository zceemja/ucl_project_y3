import time
import re
import pexpect

class QuartusTCL:
    def __init__(self):
        self.tcl = pexpect.spawn('quartus_stp --shell')
        self.tcl.expect('tcl> ')
        out = self.tcl.before
        self.version = 'Version unknown'
        for line in out.split(b'\n'):
            line = line.replace(b'\x1b[0m', b'').replace(b'\x1b[0;32m', b'')
            line = line.decode().strip()
            if line.startswith('Info: Version'):
                self.version = line[6:]
                break

    def send_cmd(self, cmd, timeout=45):
        self.tcl.sendline(cmd)
        try:
            self.tcl.expect('tcl> ', timeout=timeout)
            lines = self.tcl.before.decode().split('\r\n')[1:-1]
            return list(filter(None, lines))
        except pexpect.exceptions.TIMEOUT:
            raise QUATUS_TCL_TIMEOUT()

    def get_hardware_names(self):
        out = self.send_cmd('get_hardware_names')
        return re.findall(r'{([^\{]*)}', out[0])

    def get_device_names(self, hardware):
        out = self.send_cmd(f'get_device_names -hardware_name {{{hardware}}}')
        return re.findall(r'{([^\{]*)}', out[0])

    def start_insystem_source_probe(self, device, hardware):
        out = self.send_cmd(f'start_insystem_source_probe -device_name {{{device}}} -hardware_name {{{hardware}}}')
        if len(out) > 0 and out[0].startswith('ERROR'):
            raise INSYS_SPI_ERROR(out[0][7:])

    def read_probe_data(self, index, value_in_hex=False):
        cmd = f'read_probe_data -instance_index {index}'
        if value_in_hex:
            cmd += ' -value_in_hex'
        out = self.send_cmd(cmd)
        if len(out) > 0 and out[0].startswith('ERROR'):
            raise INSYS_SPI_ERROR(out[0][7:])
        if len(out) == 0:
            return ''
        return out[0]

    def write_source_data(self, index, value, value_in_hex=False):
        cmd = f'write_source_data -instance_index {index} -value "{value}"'
        if value_in_hex:
            cmd += ' -value_in_hex'
        out = self.send_cmd(cmd)
        if len(out) > 0 and out[0].startswith('ERROR'):
            raise INSYS_SPI_ERROR(out[0][7:])

    def read_source_data(self, index, value_in_hex=False):
        cmd = f'read_source_data -instance_index {index}'
        if value_in_hex:
            cmd += ' -value_in_hex'
        out = self.send_cmd(cmd)
        if len(out) > 0 and out[0].startswith('ERROR'):
            raise INSYS_SPI_ERROR(out[0][7:])
        if len(out) == 0:
            return ''
        return out[0]

    def end_insystem_source_probe(self):
        out = self.send_cmd(f'end_insystem_source_probe')
        if len(out) > 0 and out[0].startswith('ERROR'):
            raise INSYS_SPI_ERROR(out[0][7:])

    def begin_memory_edit(self, device, hardware):
        out = self.send_cmd(f'begin_memory_edit -device_name {{{device}}} -hardware_name {{{hardware}}}')
        if len(out) > 0 and out[0].startswith('ERROR'):
            raise INSYS_MEM_ERROR(out[0][7:])

    def end_memory_edit(self):
        out = self.send_cmd(f'end_memory_edit')
        if len(out) > 0 and out[0].startswith('ERROR'):
            raise INSYS_MEM_ERROR(out[0][7:])

    def get_editable_mem_instances(self, device, hardware):
        """
        :param device:
        :param hardware:
        :return: list of tuple [<index> <depth> <width> <read/write mode> <instance type> <instance name>]
        """
        out = self.send_cmd(f'get_editable_mem_instances -device_name {{{device}}} -hardware_name {{{hardware}}}')
        res = []
        if len(out) == 0:
            return res
        if out[0].startswith('ERROR'):
            raise INSYS_MEM_ERROR(out[0][7:])
        for i in re.findall(r'{([^\{]*)}', out[0]):
            try:
                c = i.split(' ')
                res.append((int(c[0]), int(c[1]), int(c[2]), c[3], c[4], c[5]))
            except (IndexError, ValueError):
                continue
        return res

    def read_content_from_memory(self, index, start_address, word_count, content_in_hex=False):
        cmd = f'read_content_from_memory -instance_index {index} -start_address {start_address} ' \
              f'-word_count {word_count}'
        if content_in_hex:
            cmd += ' -content_in_hex'
        out = self.send_cmd(cmd)
        if len(out) == 0:
            return ''
        if out[0].startswith('ERROR'):
            raise INSYS_MEM_ERROR(out[0][7:])
        return out[0]

    def write_content_to_memory(self, index, start_address, word_count, content, content_in_hex=False):
        cmd = f'read_content_from_memory -content "{content}" -instance_index {index} ' \
              f'-start_address {start_address} -word_count {word_count}'
        if content_in_hex:
            cmd += ' -content_in_hex'
        out = self.send_cmd(cmd)
        if len(out) > 0 and out[0].startswith('ERROR'):
            raise INSYS_MEM_ERROR(out[0][7:])

    def get_insystem_source_probe_instance_info(self, device, hardware):
        """

        :param device:
        :param hardware:
        :return: list of tuple [<index> <source width> <probe width> <instance name>]
        """
        out = self.send_cmd(
            f'get_insystem_source_probe_instance_info -device_name {{{device}}} -hardware_name {{{hardware}}}')
        res = []
        if len(out) == 0:
            return res
        if out[0].startswith('ERROR'):
            raise INSYS_SPI_ERROR(out[0][7:])
        for i in re.findall(r'{([^\{]*)}', out[0]):
            try:
                c = i.split(' ')
                res.append((int(c[0]), int(c[1]), int(c[2]), c[3]))
            except (IndexError, ValueError):
                continue
        return res

    def disconnect(self):
        self.tcl.sendline('exit')
        time.sleep(0.1)
        if self.tcl.isalive():
            self.tcl.kill(1)


class QUARTUS_TCL_EXCEPTION(Exception):
    pass


class QUATUS_TCL_TIMEOUT(QUARTUS_TCL_EXCEPTION):
    pass


class INSYS_SPI_ERROR(QUARTUS_TCL_EXCEPTION):
    def __init__(self, message):
        self.message = message


class INSYS_MEM_ERROR(QUARTUS_TCL_EXCEPTION):
    def __init__(self, message):
        self.message = message

