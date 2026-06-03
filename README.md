# moving_average_filter

Overview

This project implements a real-time Moving Average Filter (MAF) on a ZedBoard FPGA.

A noisy analog signal is acquired using the PMOD AD2 (AD7991 ADC), filtered digitally inside the FPGA using an 8-point Moving Average Filter, and reconstructed through the PMOD DA2 DAC.

The objective is to demonstrate real-time digital signal processing using FPGA hardware.
