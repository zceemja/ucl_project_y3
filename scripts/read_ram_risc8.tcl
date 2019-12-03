foreach hardware_name [get_hardware_names] {
	if { [string match "USB-Blaster*" $hardware_name] } {
		set usbblaster_name $hardware_name
	}
}
puts "JTAG chain: $usbblaster_name";
foreach device_name [get_device_names -hardware_name $usbblaster_name] {
	if { [string match "@1*" $device_name] } {
		set test_device $device_name
	}
}
puts "Device: $test_device";
begin_memory_edit -hardware_name $hardware_name -device_name $device_name

set content [read_content_from_memory -instance_index 0 -start_address 0 -word_count 4096 -content_in_hex]
end_memory_edit

puts "\n[exec echo $content | fold -w64 ]\n"
