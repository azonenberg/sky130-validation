EESchema Schematic File Version 4
EELAYER 30 0
EELAYER END
$Descr A4 11693 8268
encoding utf-8
Sheet 1 1
Title "OR1 Test Chip Breakout"
Date "2021-08-15"
Rev "0.1"
Comp "Antikernel Labs"
Comment1 "Andrew D. Zonenberg"
Comment2 ""
Comment3 ""
Comment4 ""
$EndDescr
$Comp
L special-azonenberg:CONN_SKY130_TEST_DEVICE J1
U 1 1 611051F5
P 2700 5000
F 0 "J1" H 3225 9175 50  0000 C CNN
F 1 "CONN_SKY130_TEST_DEVICE" H 3225 9084 50  0000 C CNN
F 2 "azonenberg_pcb:CONN_SAMTEC_QTH-030-01-L-D-A" H 2700 5100 50  0001 C CNN
F 3 "" H 2700 5100 50  0001 C CNN
	1    2700 5000
	1    0    0    -1  
$EndComp
$Comp
L special-azonenberg:SKY130_TEST_OR1 U1
U 2 1 6119B757
P 5950 5000
F 0 "U1" H 6475 6275 50  0000 C CNN
F 1 "SKY130_TEST_OR1" H 6475 6184 50  0000 C CNN
F 2 "azonenberg_pcb:QFN_64_0.5MM_9x9MM" H 5950 5000 50  0001 C CNN
F 3 "" H 5950 5000 50  0001 C CNN
	2    5950 5000
	1    0    0    -1  
$EndComp
$Comp
L special-azonenberg:SKY130_TEST_OR1 U1
U 3 1 6119C4AF
P 5200 7550
F 0 "U1" H 5200 7500 50  0000 L CNN
F 1 "SKY130_TEST_OR1" H 5200 7400 50  0000 L CNN
F 2 "azonenberg_pcb:QFN_64_0.5MM_9x9MM" H 5200 7550 50  0001 C CNN
F 3 "" H 5200 7550 50  0001 C CNN
	3    5200 7550
	1    0    0    -1  
$EndComp
$Comp
L device:C C1
U 1 1 6119E166
P 850 7100
F 0 "C1" H 965 7146 50  0000 L CNN
F 1 "4.7 uF" H 965 7055 50  0000 L CNN
F 2 "azonenberg_pcb:EIA_0603_CAP_NOSILK" H 888 6950 50  0001 C CNN
F 3 "" H 850 7100 50  0001 C CNN
	1    850  7100
	1    0    0    -1  
$EndComp
Text Label 850  6950 2    50   ~ 0
VCCIO
Text Label 850  7250 2    50   ~ 0
GND
$Comp
L device:C C3
U 1 1 6119EE97
P 1350 7100
F 0 "C3" H 1465 7146 50  0000 L CNN
F 1 "0.47 uF" H 1465 7055 50  0000 L CNN
F 2 "azonenberg_pcb:EIA_0402_CAP_NOSILK" H 1388 6950 50  0001 C CNN
F 3 "" H 1350 7100 50  0001 C CNN
	1    1350 7100
	1    0    0    -1  
$EndComp
$Comp
L device:C C5
U 1 1 6119F20F
P 1900 7100
F 0 "C5" H 2015 7146 50  0000 L CNN
F 1 "0.47 uF" H 2015 7055 50  0000 L CNN
F 2 "azonenberg_pcb:EIA_0402_CAP_NOSILK" H 1938 6950 50  0001 C CNN
F 3 "" H 1900 7100 50  0001 C CNN
	1    1900 7100
	1    0    0    -1  
$EndComp
$Comp
L device:C C7
U 1 1 6119F6BB
P 2450 7100
F 0 "C7" H 2565 7146 50  0000 L CNN
F 1 "0.47 uF" H 2565 7055 50  0000 L CNN
F 2 "azonenberg_pcb:EIA_0402_CAP_NOSILK" H 2488 6950 50  0001 C CNN
F 3 "" H 2450 7100 50  0001 C CNN
	1    2450 7100
	1    0    0    -1  
$EndComp
$Comp
L device:C C9
U 1 1 6119F98F
P 3000 7100
F 0 "C9" H 3115 7146 50  0000 L CNN
F 1 "0.47 uF" H 3115 7055 50  0000 L CNN
F 2 "azonenberg_pcb:EIA_0402_CAP_NOSILK" H 3038 6950 50  0001 C CNN
F 3 "" H 3000 7100 50  0001 C CNN
	1    3000 7100
	1    0    0    -1  
$EndComp
$Comp
L device:C C11
U 1 1 6119FD86
P 3550 7100
F 0 "C11" H 3665 7146 50  0000 L CNN
F 1 "0.47 uF" H 3665 7055 50  0000 L CNN
F 2 "azonenberg_pcb:EIA_0402_CAP_NOSILK" H 3588 6950 50  0001 C CNN
F 3 "" H 3550 7100 50  0001 C CNN
	1    3550 7100
	1    0    0    -1  
$EndComp
Wire Wire Line
	850  6950 1350 6950
Connection ~ 1350 6950
Wire Wire Line
	1350 6950 1900 6950
Connection ~ 1900 6950
Wire Wire Line
	1900 6950 2450 6950
Connection ~ 2450 6950
Wire Wire Line
	2450 6950 3000 6950
Connection ~ 3000 6950
Wire Wire Line
	3000 6950 3550 6950
Wire Wire Line
	3550 7250 3000 7250
Connection ~ 1350 7250
Wire Wire Line
	1350 7250 850  7250
Connection ~ 1900 7250
Wire Wire Line
	1900 7250 1350 7250
Connection ~ 2450 7250
Wire Wire Line
	2450 7250 1900 7250
Connection ~ 3000 7250
Wire Wire Line
	3000 7250 2450 7250
$Comp
L device:C C2
U 1 1 611A0C8D
P 850 7550
F 0 "C2" H 965 7596 50  0000 L CNN
F 1 "4.7 uF" H 965 7505 50  0000 L CNN
F 2 "azonenberg_pcb:EIA_0603_CAP_NOSILK" H 888 7400 50  0001 C CNN
F 3 "" H 850 7550 50  0001 C CNN
	1    850  7550
	1    0    0    -1  
$EndComp
Text Label 850  7400 2    50   ~ 0
VCCINT
Text Label 850  7700 2    50   ~ 0
GND
$Comp
L device:C C4
U 1 1 611A0C99
P 1350 7550
F 0 "C4" H 1465 7596 50  0000 L CNN
F 1 "0.47 uF" H 1465 7505 50  0000 L CNN
F 2 "azonenberg_pcb:EIA_0402_CAP_NOSILK" H 1388 7400 50  0001 C CNN
F 3 "" H 1350 7550 50  0001 C CNN
	1    1350 7550
	1    0    0    -1  
$EndComp
$Comp
L device:C C6
U 1 1 611A0CA3
P 1900 7550
F 0 "C6" H 2015 7596 50  0000 L CNN
F 1 "0.47 uF" H 2015 7505 50  0000 L CNN
F 2 "azonenberg_pcb:EIA_0402_CAP_NOSILK" H 1938 7400 50  0001 C CNN
F 3 "" H 1900 7550 50  0001 C CNN
	1    1900 7550
	1    0    0    -1  
$EndComp
$Comp
L device:C C8
U 1 1 611A0CAD
P 2450 7550
F 0 "C8" H 2565 7596 50  0000 L CNN
F 1 "0.47 uF" H 2565 7505 50  0000 L CNN
F 2 "azonenberg_pcb:EIA_0402_CAP_NOSILK" H 2488 7400 50  0001 C CNN
F 3 "" H 2450 7550 50  0001 C CNN
	1    2450 7550
	1    0    0    -1  
$EndComp
$Comp
L device:C C10
U 1 1 611A0CB7
P 3000 7550
F 0 "C10" H 3115 7596 50  0000 L CNN
F 1 "0.47 uF" H 3115 7505 50  0000 L CNN
F 2 "azonenberg_pcb:EIA_0402_CAP_NOSILK" H 3038 7400 50  0001 C CNN
F 3 "" H 3000 7550 50  0001 C CNN
	1    3000 7550
	1    0    0    -1  
$EndComp
$Comp
L device:C C12
U 1 1 611A0CC1
P 3550 7550
F 0 "C12" H 3665 7596 50  0000 L CNN
F 1 "0.47 uF" H 3665 7505 50  0000 L CNN
F 2 "azonenberg_pcb:EIA_0402_CAP_NOSILK" H 3588 7400 50  0001 C CNN
F 3 "" H 3550 7550 50  0001 C CNN
	1    3550 7550
	1    0    0    -1  
$EndComp
Wire Wire Line
	850  7400 1350 7400
Connection ~ 1350 7400
Wire Wire Line
	1350 7400 1900 7400
Connection ~ 1900 7400
Wire Wire Line
	1900 7400 2450 7400
Connection ~ 2450 7400
Wire Wire Line
	2450 7400 3000 7400
Connection ~ 3000 7400
Wire Wire Line
	3000 7400 3550 7400
Wire Wire Line
	3550 7700 3000 7700
Connection ~ 1350 7700
Wire Wire Line
	1350 7700 850  7700
Connection ~ 1900 7700
Wire Wire Line
	1900 7700 1350 7700
Connection ~ 2450 7700
Wire Wire Line
	2450 7700 1900 7700
Connection ~ 3000 7700
Wire Wire Line
	3000 7700 2450 7700
Text Label 5000 7000 2    50   ~ 0
GND
Wire Wire Line
	5000 7000 5000 7100
Connection ~ 5000 7100
Wire Wire Line
	5000 7100 5000 7200
Connection ~ 5000 7200
Wire Wire Line
	5000 7200 5000 7300
Connection ~ 5000 7300
Wire Wire Line
	5000 7300 5000 7400
Connection ~ 5000 7400
Wire Wire Line
	5000 7400 5000 7500
Text Label 5000 6400 2    50   ~ 0
VCCINT
Wire Wire Line
	5000 6400 5000 6500
Connection ~ 5000 6500
Wire Wire Line
	5000 6500 5000 6600
Connection ~ 5000 6600
Wire Wire Line
	5000 6600 5000 6700
Connection ~ 5000 6700
Wire Wire Line
	5000 6700 5000 6800
Text Label 5000 5800 2    50   ~ 0
VCCIO
Wire Wire Line
	5000 5800 5000 5900
Connection ~ 5000 5900
Wire Wire Line
	5000 5900 5000 6000
Connection ~ 5000 6000
Wire Wire Line
	5000 6000 5000 6100
Connection ~ 5000 6100
Wire Wire Line
	5000 6100 5000 6200
Text Label 2500 1050 2    50   ~ 0
VCCIO
Wire Wire Line
	2500 1050 2500 1150
Connection ~ 2500 1150
Wire Wire Line
	2500 1150 2500 1250
Connection ~ 2500 1250
Wire Wire Line
	2500 1250 2500 1350
Text Label 2500 1550 2    50   ~ 0
VCCINT
Wire Wire Line
	2500 1550 2500 1650
Connection ~ 2500 1650
Wire Wire Line
	2500 1650 2500 1750
Connection ~ 2500 1750
Wire Wire Line
	2500 1750 2500 1850
Text Label 2500 2050 2    50   ~ 0
GND
Text Label 3950 1050 0    50   ~ 0
CLK0
Text Label 3950 1150 0    50   ~ 0
CS0_N
Text Label 3950 1250 0    50   ~ 0
WE0_N
Text Label 3950 1650 0    50   ~ 0
WMASK0[0]
Text Label 3950 1450 0    50   ~ 0
WMASK0[1]
Text Label 3950 1350 0    50   ~ 0
WMASK0[2]
Text Label 3950 3950 0    50   ~ 0
ADDR0[0]
Text Label 3950 3750 0    50   ~ 0
ADDR0[1]
Text Label 3950 3550 0    50   ~ 0
ADDR0[2]
Text Label 3950 3350 0    50   ~ 0
ADDR0[3]
Text Label 2500 3950 2    50   ~ 0
ADDR0[4]
$Comp
L special-azonenberg:SKY130_TEST_OR1 U1
U 1 1 61199410
P 5950 3600
F 0 "U1" H 6450 6375 50  0000 C CNN
F 1 "SKY130_TEST_OR1" H 6450 6284 50  0000 C CNN
F 2 "azonenberg_pcb:QFN_64_0.5MM_9x9MM" H 5950 3600 50  0001 C CNN
F 3 "" H 5950 3600 50  0001 C CNN
	1    5950 3600
	1    0    0    -1  
$EndComp
Text Label 3950 2150 0    50   ~ 0
CLK1
Text Label 3950 2250 0    50   ~ 0
CS1_N
Text Label 2500 3550 2    50   ~ 0
ADDR0[6]
Text Label 2500 3350 2    50   ~ 0
ADDR0[7]
Text Label 2500 4850 2    50   ~ 0
DIN0[7]
Text Label 2500 4550 2    50   ~ 0
DIN0[15]
Text Label 3950 3650 0    50   ~ 0
DIN0[23]
Text Label 2500 3650 2    50   ~ 0
DIN0[31]
Text Label 5750 1050 2    50   ~ 0
CLK0
Text Label 5750 1150 2    50   ~ 0
CS0_N
Text Label 5750 1250 2    50   ~ 0
WE0_N
Text Label 5750 1450 2    50   ~ 0
WMASK0[0]
Text Label 5750 1550 2    50   ~ 0
WMASK0[1]
Text Label 5750 1650 2    50   ~ 0
WMASK0[2]
Text Label 5750 1750 2    50   ~ 0
WMASK0[3]
Text Label 5750 1950 2    50   ~ 0
ADDR0[0]
Text Label 5750 2050 2    50   ~ 0
ADDR0[1]
Text Label 5750 2150 2    50   ~ 0
ADDR0[2]
Text Label 5750 2250 2    50   ~ 0
ADDR0[3]
Text Label 5750 2350 2    50   ~ 0
ADDR0[4]
Text Label 5750 2450 2    50   ~ 0
ADDR0[5]
Text Label 5750 2550 2    50   ~ 0
ADDR0[6]
Text Label 5750 2650 2    50   ~ 0
ADDR0[7]
Text Label 5750 2850 2    50   ~ 0
DIN0[0]
Text Label 5750 2950 2    50   ~ 0
DIN0[7]
Text Label 5750 3050 2    50   ~ 0
DIN0[8]
Text Label 5750 3150 2    50   ~ 0
DIN0[15]
Text Label 5750 3250 2    50   ~ 0
DIN0[16]
Text Label 5750 3350 2    50   ~ 0
DIN0[23]
Text Label 5750 3450 2    50   ~ 0
DIN0[24]
Text Label 5750 3550 2    50   ~ 0
DIN0[31]
Text Label 2500 4450 2    50   ~ 0
DOUT0[0]
Text Label 2500 4650 2    50   ~ 0
DOUT0[7]
Text Label 2500 4950 2    50   ~ 0
DOUT0[8]
Text Label 3950 3850 0    50   ~ 0
DOUT0[16]
Text Label 3950 3450 0    50   ~ 0
DOUT0[23]
Text Label 2500 3450 2    50   ~ 0
DOUT0[31]
Text Label 7150 2850 0    50   ~ 0
DOUT0[0]
Text Label 7150 2950 0    50   ~ 0
DOUT0[7]
Text Label 7150 3050 0    50   ~ 0
DOUT0[8]
Text Label 7150 3150 0    50   ~ 0
DOUT0[15]
Text Label 7150 3250 0    50   ~ 0
DOUT0[16]
Text Label 7150 3350 0    50   ~ 0
DOUT0[23]
Text Label 7150 3450 0    50   ~ 0
DOUT0[24]
Text Label 7150 3550 0    50   ~ 0
DOUT0[31]
Text Label 5750 3950 2    50   ~ 0
CLK1
Text Label 5750 4050 2    50   ~ 0
CS1_N
NoConn ~ 3950 1750
NoConn ~ 3950 1850
NoConn ~ 3950 1950
Text Label 3950 2850 0    50   ~ 0
ADDR1[1]
Text Label 3950 2650 0    50   ~ 0
ADDR1[2]
Text Label 3950 2450 0    50   ~ 0
ADDR1[3]
Text Label 2500 2650 2    50   ~ 0
ADDR1[6]
Text Label 2500 2450 2    50   ~ 0
ADDR1[7]
Text Label 3950 3150 0    50   ~ 0
DOUT1[0]
Text Label 2500 2750 2    50   ~ 0
DOUT1[7]
Text Label 2500 2550 2    50   ~ 0
DOUT1[8]
Text Label 3950 2950 0    50   ~ 0
DOUT1[15]
Text Label 3950 2750 0    50   ~ 0
DOUT1[16]
Text Label 3950 2550 0    50   ~ 0
DOUT1[23]
Text Label 2500 3150 2    50   ~ 0
DOUT1[24]
Text Label 2500 2950 2    50   ~ 0
DOUT1[31]
Text Label 7200 4250 0    50   ~ 0
DOUT1[0]
Text Label 7200 4350 0    50   ~ 0
DOUT1[7]
Text Label 7200 4450 0    50   ~ 0
DOUT1[8]
Text Label 7200 4550 0    50   ~ 0
DOUT1[15]
Text Label 7200 4650 0    50   ~ 0
DOUT1[16]
Text Label 7200 4750 0    50   ~ 0
DOUT1[23]
Text Label 7200 4850 0    50   ~ 0
DOUT1[24]
Text Label 7200 4950 0    50   ~ 0
DOUT1[31]
Text Label 5750 4250 2    50   ~ 0
ADDR1[0]
Text Label 5750 4350 2    50   ~ 0
ADDR1[1]
Text Label 5750 4450 2    50   ~ 0
ADDR1[2]
Text Label 5750 4550 2    50   ~ 0
ADDR1[3]
Text Label 5750 4650 2    50   ~ 0
ADDR1[4]
Text Label 5750 4750 2    50   ~ 0
ADDR1[5]
Text Label 5750 4850 2    50   ~ 0
ADDR1[6]
Text Label 5750 4950 2    50   ~ 0
ADDR1[7]
$Comp
L Connector:Conn_Coaxial TP1
U 1 1 611E37F7
P 850 5750
F 0 "TP1" H 803 5988 50  0000 C CNN
F 1 "U.FL" H 803 5897 50  0000 C CNN
F 2 "azonenberg_pcb:CONN_U.FL_TE_1909763-1" H 850 5750 50  0001 C CNN
F 3 "" H 850 5750 50  0001 C CNN
	1    850  5750
	-1   0    0    -1  
$EndComp
Text Label 1000 5750 0    50   ~ 0
VCCIO
Text Label 1000 5950 0    50   ~ 0
GND
Wire Wire Line
	1000 5950 850  5950
$Comp
L Connector:Conn_Coaxial TP2
U 1 1 611E527E
P 850 6300
F 0 "TP2" H 803 6538 50  0000 C CNN
F 1 "U.FL" H 803 6447 50  0000 C CNN
F 2 "azonenberg_pcb:CONN_U.FL_TE_1909763-1" H 850 6300 50  0001 C CNN
F 3 "" H 850 6300 50  0001 C CNN
	1    850  6300
	-1   0    0    -1  
$EndComp
Text Label 1000 6300 0    50   ~ 0
VCCINT
Text Label 1000 6500 0    50   ~ 0
GND
Wire Wire Line
	1000 6500 850  6500
Text Notes 2700 5100 0    50   ~ 0
Bits swapped for layout
Text Label 2500 2850 2    50   ~ 0
ADDR1[5]
Text Label 3950 4050 0    50   ~ 0
DIN0[16]
Text Label 2500 3050 2    50   ~ 0
ADDR1[4]
Text Label 2500 4750 2    50   ~ 0
DIN0[8]
Text Label 3950 3050 0    50   ~ 0
ADDR1[0]
Text Label 3950 1550 0    50   ~ 0
WMASK0[3]
Text Label 2500 3750 2    50   ~ 0
ADDR0[5]
Text Label 2500 3850 2    50   ~ 0
DOUT0[24]
Text Label 2500 4050 2    50   ~ 0
DIN0[24]
Text Label 2500 4250 2    50   ~ 0
DIN0[0]
Text Label 2500 4350 2    50   ~ 0
DOUT0[15]
$EndSCHEMATC
