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








                +----------------+
                | 8-Point Moving |
                | Average Filter |
                +-------+--------+
                        |
                        v
                +----------------+
                | DAC Driver     |
                | (SPI Interface)|
                +-------+--------+
                        |
                        v
                +----------------+
                | PMOD DA2       |
                | DAC            |
                +-------+--------+
                        |
                        v
                +----------------+
                | Oscilloscope   |
                +----------------+
```

---

## 🧠 Theory

### Sampling

The noisy analog signal is sampled using the AD7991 Analog-to-Digital Converter.

**Sampling Rate:**

```text
1 kHz
```

This means:

```text
1000 samples per second
```

Each sample is represented as a:

```text
12-bit digital value
```

---

### Moving Average Filter

The Moving Average Filter is one of the simplest and most widely used digital filters.

It works by averaging the current sample and the previous seven samples.

**Filter Equation**

```text
y[n] = (x[n] + x[n-1] + x[n-2] + x[n-3]
      + x[n-4] + x[n-5] + x[n-6] + x[n-7]) / 8
```

Where:

```text
x[n] = Current ADC sample

y[n] = Filtered output sample
```

### Advantages

- Simple FPGA implementation
- Low hardware resource utilization
- Effective noise reduction
- Real-time operation

---

## ✨ Features

- Real-time analog signal acquisition
- AD7991 ADC interfacing using I²C
- 12-bit signal processing
- 8-point Moving Average Filter
- Real-time DAC reconstruction
- Noise reduction and waveform smoothing
- Modular Verilog design
- FPGA implementation on ZedBoard

---

## 🛠 Hardware Used

| Component | Description |
|------------|------------|
| FPGA Board | ZedBoard (Zynq-7000 XC7Z020) |
| ADC | Digilent PMOD AD2 (AD7991) |
| DAC | Digilent PMOD DA2 |
| Oscilloscope | Agilent DSO-X 2002A |
| Signal Source | Waveform Generator |
| Communication | I²C and SPI |

---

## 💻 Software Used

| Software | Purpose |
|-----------|----------|
| Vivado 2023 | Design & Implementation |
| Verilog HDL | Hardware Description Language |
| GitHub | Version Control & Documentation |

---

## 🔌 Hardware Connections

### PMOD AD2 Connections

| PMOD AD2 | ZedBoard |
|-----------|-----------|
| VCC | VCC |
| GND | GND |
| SDA | JE4 |
| SCL | JE3 |
| VIN0 (V1) | Wavegen Output |

---

### PMOD DA2 Connections

| PMOD DA2 | ZedBoard |
|-----------|-----------|
| SYNC | Lower JA |
| DIN | Lower JA |
| SCLK | Lower JA |
| GND | GND |

---

### Oscilloscope Connections

| Oscilloscope | PMOD DA2 |
|--------------|-----------|
| Probe Tip | Analog Output |
| Ground Clip | GND |

---

## 📂 Repository Structure

```text
FPGA-Moving-Average-Filter
│
├── README.md
│
├── src
│   ├── top.v
│   ├── i2c_clock.v
│   ├── ad7991_reader.v
│   ├── moving_average_8.v
│   └── dac_driver.v
│
├── constraints
│   └── constraints.xdc
│
├── simulation
│   ├── testbench.v
│   └── waveform.png
│
├── docs
│   ├── block_diagram.png
│   ├── hardware_setup.jpg
│   ├── input_waveform.png
│   ├── output_waveform.png
│   ├── schematic.png
│   ├── technology_view.png
│   ├── utilization_report.png
│   └── timing_summary.png
│
└── report
    └── Project_Report.pdf
```

---

## 📁 Verilog Modules

### 1. top.v

Top-level module that integrates all project blocks.

Responsibilities:

- Connects ADC reader
- Connects Moving Average Filter
- Connects DAC driver
- Controls data flow

---

### 2. i2c_clock.v

Generates timing signals required for:

- ADC sampling
- I²C communication

Outputs:

```text
sample_tick = 1 kHz

i2c_clk_en = 100 kHz
```

---

### 3. ad7991_reader.v

Handles communication with the AD7991 ADC.

Functions:

- Generate I²C transactions
- Read ADC samples
- Store 12-bit conversion results

Output:

```text
adc_data[11:0]
```

---

### 4. moving_average_8.v

Implements the 8-point Moving Average Filter.

Functions:

- Stores 8 previous samples
- Calculates running average
- Produces filtered output

Output:

```text
filtered_data[11:0]
```

---

### 5. dac_driver.v

Interfaces with PMOD DA2.

Functions:

- Converts filtered samples into DAC commands
- Generates SPI control signals
- Reconstructs analog waveform

Outputs:

```text
dac_sync
dac_sclk
dac_din
```

---

## 📊 Results

### Input Signal

Noisy analog waveform generated using the waveform generator.

**Insert oscilloscope screenshot here**

---

### Filtered Output Signal

Filtered waveform after FPGA processing.

**Insert oscilloscope screenshot here**

---

### Performance Comparison

| Parameter | Before Filtering | After Filtering |
|------------|----------------|----------------|
| Noise Level | High | Reduced |
| Waveform Stability | Poor | Improved |
| Signal Quality | Moderate | Better |
| Smoothness | Low | High |

---

## 📈 FPGA Resource Utilization

Include screenshots of:

- Synthesis Report
- Utilization Summary
- Timing Analysis
- Power Analysis
- Technology Schematic

---

## 🚀 Future Improvements

- FIR Filter Implementation
- IIR Filter Implementation
- FFT Spectrum Analyzer
- Real-Time Audio Processing
- FPGA-Based Digital Oscilloscope
- VGA Signal Visualization
- SDR (Software Defined Radio) Applications

---

## 👥 Contributors

**Naveenraj S**  
Bannari Amman Institute of Technology

**Mohanapriyan P**  
Bannari Amman Institute of Technology

---

## 🙏 Acknowledgement

We sincerely thank our faculty members and mentors for their valuable guidance and support throughout the development of this project. The project provided practical exposure to FPGA-based digital signal processing, hardware interfacing, debugging, and real-time system implementation.

---

## 📜 License

This project is intended for educational and research purposes.

Smoothens waveform

Simple FIR Filter
