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

puts "Flashing rom0...";
set content [exec cat ./memory/risc8.text_0.uhex]
write_content_to_memory -instance_index 1 -content $content -content_in_hex -start_address 0 -word_count 1024

puts "Flashing rom1...";
set content [exec cat ./memory/risc8.text_1.uhex]
write_content_to_memory -instance_index 2 -content $content -content_in_hex -start_address 0 -word_count 1024

puts "Flashing rom2...";
set content [exec cat ./memory/risc8.text_2.uhex]
write_content_to_memory -instance_index 3 -content $content -content_in_hex -start_address 0 -word_count 1024

puts "Flashing rom3...";
set content [exec cat ./memory/risc8.text_3.uhex]
write_content_to_memory -instance_index 4 -content $content -content_in_hex -start_address 0 -word_count 1024

puts "Flashing ram0...";
set content [exec cat ./memory/risc8.data.uhex]
write_content_to_memory -instance_index 0 -content $content -content_in_hex -start_address 0 -word_count 4096

puts "Done!";
end_memory_edit



