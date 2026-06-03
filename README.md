# moving_average_filter

Overview

This project implements a real-time Moving Average Filter (MAF) on a ZedBoard FPGA.

A noisy analog signal is acquired using the PMOD AD2 (AD7991 ADC), filtered digitally inside the FPGA using an 8-point Moving Average Filter, and reconstructed through the PMOD DA2 DAC.

The objective is to demonstrate real-time digital signal processing using FPGA hardware.

# Project Objective

Acquire noisy analog signal

Convert analog to digital

Reduce noise using Moving Average Filter

Reconstruct filtered signal

Observe improvement on oscilloscope

# System Architecture

Wavegen
   ↓
PMOD AD2
(AD7991 ADC)
   ↓
I²C Reader
   ↓
Moving Average Filter
   ↓
SPI DAC Driver
   ↓
PMOD DA2
   ↓
Oscilloscope


# Theory Section

Explain:

Sampling

Sampling Rate = 1 kHz

ADC

12-bit Conversion

Moving Average Filter


Explain:

Removes high-frequency noise

Smoothens waveform

Simple FIR Filter
