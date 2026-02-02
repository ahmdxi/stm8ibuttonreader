
# STM8 1-Wire iButton Reader

This project implements a bit-banged 1-Wire communication protocol on an STM8S microcontroller to read and validate the 64-bit ROM ID of a DS1990A iButton or similar device.

### Hardware Configuration

The code is configured for the STM8S105C6 microcontroller.

### Functionality

The program follows the standard 1-Wire initialization and communication sequence to extract the unique hardware ID:

- **Bus Reset**: The master pulls the bus low for \(480μ s\) and listens for a presence pulse from the slave device.
- **Read ROM Command**: The master transmits the command \(0x33\) to request the 8-byte unique ID from the connected device.
- **Data Collection**: The code reads 8 bytes (64 bits) into a RAM buffer.
- **Validation**: It specifically checks the first byte (the Family Code). If the byte matches \(0x01\), the access is granted (Green LED); otherwise, access is denied (Red LED).

### Protocol Timing

Since the 1-Wire protocol is timing-dependent, this implementation uses calibrated delay loops based on the \(16MHz\) CPU frequency.

- **Write 1**: Pulls the bus low briefly and releases it quickly.
- **Write 0**: Holds the bus low for the majority of the time slot (\(60μ s\)).
- **Read Slot**: Initiates a short low pulse and samples the bus state after approximately \(15μ s\).

### Requirements

To assemble and flash this project, you will need:

- **ST Visual Develop (STVD)** or the standalone **ST Assembler (STM8AS)**.
- **ST-Link V2** programmer.
- **Standard Include Files**: `mapping.inc` and `stm8s105c_s.inc` must be present in the project directory.

***

