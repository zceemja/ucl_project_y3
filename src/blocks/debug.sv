// (C) 2001-2018 Intel Corporation. All rights reserved.
// Your use of Intel Corporation's design tools, logic functions and other 
// software and tools, and its AMPP partner logic functions, and any output 
// files from any of the foregoing (including device programming or simulation 
// files), and any associated documentation or information are expressly subject 
// to the terms and conditions of the Intel Program License Subscription 
// Agreement, Intel FPGA IP License Agreement, or other applicable 
// license agreement, including, without limitation, that your use is for the 
// sole purpose of programming logic devices manufactured by Intel and sold by 
// Intel or its authorized distributors.  Please refer to the applicable 
// agreement for further details.

module altsource_probe_top
#(
    parameter lpm_type = "altsource_probe",     // required by the coding standard
    parameter lpm_hint = "UNUSED",              // required by the coding standard 

    parameter sld_auto_instance_index = "YES",  // Yes, if the instance index should be automatically assigned.
    parameter sld_instance_index = 0,           // unique identifier for the altsource_probe instance.
    parameter sld_node_info_parameter = 4746752 + sld_instance_index,   // The NODE ID to uniquely identify this node on the hub.  Type ID: 9 Version: 0 Inst: 0 MFG ID 110 -- ***NOTE*** this parameter cannot be called SLD_NODE_INFO or Quartus Standard will think it's an ISSP impl.
    parameter sld_ir_width = 4,                 
                                        
    parameter instance_id = "UNUSED",           // optional name for the instance.
    parameter probe_width = 1,                  // probe port width
    parameter source_width= 1,                  // source port width
    parameter source_initial_value = "0",       // initial source port value
    parameter enable_metastability = "NO"       // yes to add two register
)
(
    input [probe_width - 1 : 0] probe,       // probe inputs
    output [source_width - 1 : 0] source,    // source outputs
    input source_clk,                        // clock of the registers used to metastabilize the source output
    input tri1 source_ena                    // enable of the registers used to metastabilize the source output
);

    altsource_probe #(
        .lpm_type(lpm_type),
        .lpm_hint(lpm_hint),   
        .sld_auto_instance_index(sld_auto_instance_index),
        .sld_instance_index(sld_instance_index),
        .SLD_NODE_INFO(sld_node_info_parameter),
        .sld_ir_width(sld_ir_width),                          
        .instance_id(instance_id),
        .probe_width(probe_width),
        .source_width(source_width),
        .source_initial_value(source_initial_value),
        .enable_metastability(enable_metastability)
    )issp_impl
    (
        .probe(probe),
        .source(source),
        .source_clk(source_clk),
        .source_ena(source_ena)
    );
    
endmodule


module sys_comb(source, probe);
	parameter NAME = "";
	parameter WIDTH = 1;
	input wire[WIDTH-1:0] probe;
	output wire[WIDTH-1:0] source;

	altsource_probe_top #(
		.sld_auto_instance_index ("YES"),
		.sld_instance_index      (0),
		.instance_id             (NAME),
		.probe_width             (WIDTH),
		.source_width            (WIDTH),
		.enable_metastability    ("NO")
	) in_system_sources_probes_0 (
		.probe (probe),       // probes.probe
		.source(source),      // sources.source
		.source_ena ('d0)    // (terminated)
	);
endmodule


module sys_ss (source);
	parameter NAME = "";
	parameter WIDTH = 1;
	output wire[WIDTH-1:0] source;

	altsource_probe_top #(
		.sld_auto_instance_index ("YES"),
		.sld_instance_index      (0),
		.instance_id             (NAME),
		.probe_width             (0),
		.source_width            (WIDTH),
		.source_initial_value    ("0"),
		.enable_metastability    ("NO")
	) in_system_sources_probes_0 (
		.source     (source), // sources.source
		.source_ena (1'b1)    // (terminated)
	);

endmodule

module sys_sp (probe);
	parameter NAME = "";
	parameter WIDTH = 1;
	input wire[WIDTH-1:0] probe;

	altsource_probe_top #(
		.sld_auto_instance_index ("YES"),
		.sld_instance_index      (0),
		.instance_id             (NAME),
		.probe_width             (WIDTH),
		.source_width            (0),
		.enable_metastability    ("NO")
	) in_system_sources_probes_0 (
		.probe (probe)  // probes.probe
	);

endmodule
