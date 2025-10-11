VERILOG=iverilog

#------------------------------------------------------------------------------#
# Directories Declarations                                                     #
#------------------------------------------------------------------------------#
CUR_DIR=$(PWD)
TESTBENCH=TESTBENCH
RTL_DIR=RTL
SIM=vvp


verif1: clean
	python3 data_generator.py --mode 0 --target_dir verif1 --ncases 10
	cp verif1/input.txt verif1/input.bk
	mv verif1/input.txt $(TESTBENCH)/
	$(VERILOG) -g2005-sv -o verif1/simulation $(TESTBENCH)/TESTBENCH.v -I $(TESTBENCH) -I $(RTL_DIR) -D RTL
	$(SIM) verif1/simulation +access+r

verif2: clean
	python3 data_generator.py --mode 1 --target_dir verif2 --ncases 10
	cp verif2/input.txt verif2/input.bk
	mv verif2/input.txt $(TESTBENCH)/
	$(VERILOG) -g2005-sv -o verif2/simulation $(TESTBENCH)/TESTBENCH.v -I $(TESTBENCH) -I $(RTL_DIR) -D RTL
	$(SIM) verif2/simulation +access+r

verif3: clean
	python3 data_generator.py --mode 2 --target_dir verif3 --ncases 10
	cp verif3/input.txt verif3/input.bk
	cp verif3/input.txt $(TESTBENCH)/
	$(VERILOG) -g2005-sv -o verif3/simulation $(TESTBENCH)/TESTBENCH.v -I $(TESTBENCH) -I $(RTL_DIR) -D RTL
	$(SIM) verif3/simulation +access+r

verif4: clean
	python3 data_generator.py --mode 3 --target_dir verif4 --ncases 50
	cp verif4/input.txt verif4/input.bk
	mv verif4/input.txt $(TESTBENCH)/
	$(VERILOG) -g2005-sv -o verif4/simulation $(TESTBENCH)/TESTBENCH.v -I $(TESTBENCH) -I $(RTL_DIR) -D RTL
	$(SIM) verif4/simulation +access+r

# verif_signed is not a part of lab 3
verif_signed: clean
	python3 data_generator.py --mode 4 --target_dir verif5 --ncases 50
	cp verif5/input.txt verif5/input.bk
	mv verif5/input.txt $(TESTBENCH)/
	$(VERILOG) -g2005-sv -o verif5/simulation $(TESTBENCH)/TESTBENCH.v -I $(TESTBENCH) -I $(RTL_DIR) -D RTL
	$(SIM) verif5/simulation +access+r

systolic_test: clean_systolic
	mkdir -p systolic_verif
	$(VERILOG) -g2005-sv -o systolic_verif/simulation RTL/buffer.v RTL/PE.v RTL/systolic_array.v RTL/systolic_array_tb_with_buffer.v RTL/global_buffer.v -I $(RTL_DIR) -D RTL
	$(SIM) systolic_verif/simulation +access+r

buffer_test: clean_buffer
	mkdir -p buffer_verif
	$(VERILOG) -g2005-sv -o buffer_verif/simulation RTL/buffer.v RTL/buffer_tb.v -I $(RTL_DIR)
	$(SIM) buffer_verif/simulation +access+r

# Add this to your clean target or create a separate one
clean_systolic:
	rm -rf systolic_verif

clean_buffer:
	rm -rf buffer_verif

# Update your main clean target to include systolic cleanup
clean: clean_systolic clean_buffer
	rm -rf verif*

# clean:
# #------------------------------------------------------------------------------#
# 	rm -rf verif*
