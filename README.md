# FPGA XADC FIFO UART Data Acquisition

## Overview

This project is implemented in **VHDL** on the **Digilent Nexys A7 FPGA**.

The system reads analog signals using the **Xilinx XADC**, stores the data in **four FIFOs**, and sends the data to a PC through **UART**.

Each FIFO stores **12-bit XADC samples** with a depth of **1024 samples**.

Since UART can transmit only **8 bits at a time**, each 12-bit sample is divided into two parts:
- First byte: `0000 + upper 4 bits`
- Second byte: `lower 8 bits`

For example:

```
12-bit Data : AE3

UART Transmits:

0A
E3
```

The receiver can combine these two bytes to recover the original **12-bit value**.

---

## Features

- VHDL implementation
- Digilent Nexys A7 FPGA
- Xilinx XADC
- 4 independent FIFOs
- FIFO depth: **2048**
- FIFO width: **12 bits**
- UART transmission
- Continuous data transfer
- Round-robin FIFO reading

---

## Data Flow

```
Analog Input
      │
      ▼
    XADC
      │
      ▼
  4 FIFOs
      │
      ▼
12-bit Splitter
      │
      ▼
 UART TX
      │
      ▼
     PC
```

---

## UART Data Format

Example:

```
ADC Sample = AE3

UART Byte 1 = 0A
UART Byte 2 = E3
```

UART Output:

```
0A E3 09 67 08 99 02 55 ...
```

---

## Hardware

- Digilent Nexys A7 FPGA
- Xilinx Artix-7
- XADC Wizard
- FIFO Generator IP
- UART Transmitter

---

## Software

- Vivado Design Suite
- VHDL

## Future Work

- UART Receiver
- 12-bit data reconstruction
- Ethernet/UDP communication
- PC application for real-time data display

