# UART with AXI4-Lite Interface

A UART (Universal Asynchronous Receiver/Transmitter) peripheral with an AXI4-Lite slave interface, implemented in VHDL for FPGA/ASIC integration. This project provides a synthesizable UART core wrapped with a memory-mapped AXI4-Lite register interface, allowing a processor (or any AXI4-Lite master) to configure and communicate over a serial link.

---

## 📋 Table of Contents

- [Overview](#overview)
- [Features](#features)
- [Project Structure](#project-structure)
- [Architecture](#architecture)
- [Register Map](#register-map)
- [Getting Started](#getting-started)
- [Simulation](#simulation)
- [Synthesis](#synthesis)
- [Waveforms & RTL Capture](#waveforms--rtl-capture)
- [Tools & Requirements](#tools--requirements)
- [Author](#author)

---

## Overview

This project implements a UART communication interface accessible through an **AXI4-Lite** bus. It is designed to be instantiated in a system-on-chip (SoC) where a CPU or DMA controller needs to send and receive serial data using memory-mapped I/O.

The design is split into two main parts:

1. **`uart_core.vhd`** — The UART engine: baud rate generation, serialization/deserialization, start/stop bit handling, and parity.
2. **`uart_axi4lite.vhd`** — The AXI4-Lite slave wrapper that exposes the UART's control and data registers to the bus.

---

## Features

- ✅ AXI4-Lite slave interface (compliant with the AXI4-Lite protocol)
- ✅ Configurable baud rate (via baud divisor register)
- ✅ 8-bit data width, 1 start bit, 1 stop bit
- ✅ Optional parity support
- ✅ Transmit and receive buffers
- ✅ Status flags for TX ready, RX valid, overrun, and framing errors
- ✅ Fully synthesizable VHDL (RTL)
- ✅ Self-checking testbench (`uart_axi4lite_tb.vhd`)

---

## Project Structure
