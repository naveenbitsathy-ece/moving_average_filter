# Moving average filter 

## 📌 Overview

This project implements an 8-Point Moving Average Filter using Verilog HDL on a ZedBoard FPGA. The filter processes sampled input data and generates a smoother output signal by reducing noise. The design demonstrates basic digital signal processing concepts and real-time FPGA implementation.

## 📜 Problem Statement

Design and implement an 8-Point Moving Average Filter (MAF) on an FPGA to reduce noise from a sampled input signal.

* Acquire input samples from an ADC.
* Store the current and previous seven samples.
* Compute the average of the latest eight samples.
* Generate a smoother output signal with reduced noise.
* Transmit the filtered data to a DAC for analog signal reconstruction.
* Demonstrate real-time digital signal processing using FPGA hardware.
****

## ✨ Features

### Signal Acquisition

* Acquires analog signals using the PMOD AD2 (AD7991 ADC).
* Converts analog input into 12-bit digital samples.
* Supports real-time data acquisition at a sampling rate of 1 kHz.

### Noise Reduction

* Implements an 8-Point Moving Average Filter.
* Reduces random noise present in the input signal.
* Produces a smoother and more stable output waveform.

### Real-Time Processing

* Processes incoming samples continuously inside the FPGA.
* Generates filtered output without noticeable delay.
* Demonstrates real-time digital signal processing (DSP).

### Signal Reconstruction

* Sends filtered digital data to the PMOD DA2 DAC.
* Converts filtered digital samples back into an analog signal.
* Allows direct observation of the filtered waveform on an oscilloscope.

### FPGA Implementation

* Designed entirely using Verilog HDL.
* Implemented and tested on a ZedBoard FPGA.
* Uses modular design for easy debugging and future upgrades.

---

## 🛠 Tools & Hardware
- Software: Vivado ML Edition (Standard) 2024.2
- Hardware: ZedBoard Zynq-7000 ARM / FPGA SoC Development Board,Pmod AD2,Pmod DA2 convertors 
---

