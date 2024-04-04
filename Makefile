
# all:
# 	iverilog -o $(source_dir)/$(source_name) $(source_dir)/$(source_name).sv
# 	vvp $(source_dir)/$(source_name)
# 	gtkwave $(source_dir)/$(source_name).vcd

all: 
	iverilog -o $(test_dir)/$(test_name) $(test_dir)/$(test_name).sv
	vvp $(test_dir)/$(test_name)
	gtkwave $(test_dir)/$(test_name).vcd

clean:
	rm -r $(test_dir)/$(test_name) $(test_dir)/$(test_name).vcd
