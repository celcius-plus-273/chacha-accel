
all:
	iverilog -o test/round_test test/round_test.sv
	vvp test/round_test