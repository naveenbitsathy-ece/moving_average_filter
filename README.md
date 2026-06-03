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
