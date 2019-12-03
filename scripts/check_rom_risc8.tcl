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

set content [read_content_from_memory -instance_index 1 -start_address 0 -word_count 1024 -content_in_hex]
puts "Checking rom0...[exec ./check_mem.sh ./memory/risc8.text_0.uhex $content]"
set content [read_content_from_memory -instance_index 2 -start_address 0 -word_count 1024 -content_in_hex]
puts "Checking rom1...[exec ./check_mem.sh ./memory/risc8.text_1.uhex $content]"
set content [read_content_from_memory -instance_index 3 -start_address 0 -word_count 1024 -content_in_hex]
puts "Checking rom2...[exec ./check_mem.sh ./memory/risc8.text_2.uhex $content]"
set content [read_content_from_memory -instance_index 4 -start_address 0 -word_count 1024 -content_in_hex]
puts "Checking rom3...[exec ./check_mem.sh ./memory/risc8.text_3.uhex $content]"

puts "Done!";
end_memory_edit

