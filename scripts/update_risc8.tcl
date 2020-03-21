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
start_insystem_source_probe -hardware_name $hardware_name -device_name $device_name
write_source_data -instance_index 0 -value 1 -value_in_hex

puts "Flashing ram0...";
set content [exec python ./tools/format_utils.py -w 16 -t uhex -s ./memory/build/risc8.data.o]
#set content [exec cat ./memory/risc8.data.uhex]
write_content_to_memory -instance_index 0 -content $content -content_in_hex -start_address 0 -word_count 4096

puts "Flashing rom0...";
set content [exec python ./tools/format_utils.py -w 8 -S 4 -n 0 -t uhex -s ./memory/build/risc8.text.o]
#set content [exec cat ./memory/risc8.text_0.uhex]
write_content_to_memory -instance_index 1 -content $content -content_in_hex -start_address 0 -word_count 1024

puts "Flashing rom1...";
set content [exec python ./tools/format_utils.py -w 8 -S 4 -n 1 -t uhex -s ./memory/build/risc8.text.o]
#set content [exec cat ./memory/risc8.text_1.uhex]
write_content_to_memory -instance_index 2 -content $content -content_in_hex -start_address 0 -word_count 1024

puts "Flashing rom2...";
set content [exec python ./tools/format_utils.py -w 8 -S 4 -n 2 -t uhex -s ./memory/build/risc8.text.o]
#set content [exec cat ./memory/risc8.text_2.uhex]
write_content_to_memory -instance_index 3 -content $content -content_in_hex -start_address 0 -word_count 1024

puts "Flashing rom3...";
set content [exec python ./tools/format_utils.py -w 8 -S 4 -n 3 -t uhex -s ./memory/build/risc8.text.o]
#set content [exec cat ./memory/risc8.text_3.uhex]
write_content_to_memory -instance_index 4 -content $content -content_in_hex -start_address 0 -word_count 1024


write_source_data -instance_index 0 -value 0 -value_in_hex
end_insystem_source_probe
end_memory_edit
puts "Done!";



