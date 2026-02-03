# UART Protocol Implementation in Verilog

This repository contains a complete **UART (Universal Asynchronous Receiver Transmitter)**
implementation written in **Verilog HDL**, developed as part of the  
**Digital System Design Applications – Project 2** course at Istanbul Technical University.

## 📌 Features
- Standard UART frame format: **8N1**
- Parameterized baud rate (9600 / 115200)
- **Single shared baud generator**
- 8x oversampling on receiver side
- Modular design:
  - `baud_gen`
  - `uart_tx`
  - `uart_rx`
  - `uart_top`
- Behavioral & post-implementation timing verified

## 🧩 Module Overview
- **baud_gen**  
  Generates baud-rate and 8× oversampling tick signals from a 100 MHz system clock.

- **uart_tx**  
  FSM-based UART transmitter (IDLE, START, DATA, STOP).

- **uart_rx**  
  FSM-based UART receiver with start-bit validation and oversampling.

- **uart_top**  
  Top-level integration of TX, RX, and shared baud generator.

## 🧪 Verification
- File-based testbenches
- Loopback testing in `uart_top_tb`
- Behavioral & post-implementation simulations performed in Vivado

## 🛠 Tools
- Verilog HDL
- Xilinx Vivado
- 100 MHz system clock

## 📄 Report
The full project report, including block diagrams, timing analysis, and waveforms,
is available in the `docs/` folder.

## Verification
The design is verified using file-based and loopback testbenches.
Both behavioral and post-implementation timing simulations were performed.

## 👤 Author
**Mehmet Emin Delibaş**  
Electronics and Communication Engineering  
Istanbul Technical University
