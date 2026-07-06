# XADC-UART-Data-Acquisition
VHDL implementation of a real-time 4-channel XADC data acquisition system on the Nexys A7 FPGA. Each 12-bit XADC sample is stored in a 1024-depth FIFO and transmitted over UART by splitting the sample into two 8-bit frames (upper 4 bits + lower 8 bits), allowing complete 12-bit data reconstruction at the receiver.
