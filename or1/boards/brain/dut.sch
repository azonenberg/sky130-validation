EESchema Schematic File Version 4
LIBS:brain-cache
EELAYER 30 0
EELAYER END
$Descr A3 16535 11693
encoding utf-8
Sheet 3 3
Title ""
Date "2021-11-06"
Rev ""
Comp ""
Comment1 ""
Comment2 ""
Comment3 ""
Comment4 ""
$EndDescr
$Comp
L special-azonenberg:CONN_SKY130_TEST_HOST J5
U 1 1 60D004CF
P 9600 7500
F 0 "J5" H 10125 11675 50  0000 C CNN
F 1 "CONN_SKY130_TEST_HOST" H 10125 11584 50  0000 C CNN
F 2 "azonenberg_pcb:CONN_SAMTEC_QSH-030-01-L-D-A" H 9600 7600 50  0001 C CNN
F 3 "" H 9600 7600 50  0001 C CNN
	1    9600 7500
	1    0    0    -1  
$EndComp
$Comp
L xilinx-azonenberg:XC7Sx-FTGB196 U?
U 4 1 60DB51EA
P 6750 8050
AR Path="/60CA3D46/60DB51EA" Ref="U?"  Part="2" 
AR Path="/60DB51EA" Ref="U?"  Part="4" 
AR Path="/60DAFE68/60DB51EA" Ref="U2"  Part="4" 
F 0 "U2" H 6750 8000 50  0000 L CNN
F 1 "XC7S15-1FTGB196C" H 6750 7900 50  0000 L CNN
F 2 "azonenberg_pcb:BGA_196_15x15_FULLARRAY_1MM_FTGB196" H 6750 8050 50  0001 C CNN
F 3 "" H 6750 8050 50  0001 C CNN
	4    6750 8050
	-1   0    0    -1  
$EndComp
Text HLabel 9400 3550 0    50   Input ~ 0
DUT_VCCIO
Text HLabel 9400 4050 0    50   Input ~ 0
DUT_VCORE
Text HLabel 9400 4550 0    50   Input ~ 0
GND
Wire Wire Line
	9400 4050 9400 4150
Connection ~ 9400 4150
Wire Wire Line
	9400 4150 9400 4250
Connection ~ 9400 4250
Wire Wire Line
	9400 4250 9400 4350
Wire Wire Line
	9400 3550 9400 3650
Connection ~ 9400 3650
Wire Wire Line
	9400 3650 9400 3750
Connection ~ 9400 3750
Wire Wire Line
	9400 3750 9400 3850
Text Label 6950 6600 0    50   ~ 0
ADDR0_0
Text Label 6950 6800 0    50   ~ 0
ADDR0_1
Text Label 6950 6300 0    50   ~ 0
ADDR0_2
Text Label 6950 7400 0    50   ~ 0
ADDR0_3
Text Label 6950 6200 0    50   ~ 0
ADDR0_4
Text Label 6950 6500 0    50   ~ 0
ADDR0_5
Text Label 6950 5700 0    50   ~ 0
ADDR0_7
Text Label 9400 7450 2    50   ~ 0
ADDR0_0
Text Label 9400 7350 2    50   ~ 0
ADDR0_1
Text Label 9400 7150 2    50   ~ 0
ADDR0_2
Text Label 9400 6950 2    50   ~ 0
ADDR0_3
Text Label 9400 6750 2    50   ~ 0
ADDR0_4
Text Label 10850 6450 0    50   ~ 0
ADDR0_5
Text Label 10850 6050 0    50   ~ 0
ADDR0_7
Text Label 6950 4300 0    50   ~ 0
ADDR1_0
Text Label 6950 3300 0    50   ~ 0
ADDR1_1
Text Label 6950 4200 0    50   ~ 0
ADDR1_2
Text Label 6950 4500 0    50   ~ 0
ADDR1_3
Text Label 6950 3100 0    50   ~ 0
ADDR1_4
Text Label 6950 3800 0    50   ~ 0
ADDR1_5
Text Label 6950 3500 0    50   ~ 0
ADDR1_6
Text Label 6950 3700 0    50   ~ 0
ADDR1_7
Text Label 10850 4950 0    50   ~ 0
ADDR1_0
Text Label 9400 5350 2    50   ~ 0
ADDR1_2
Text Label 9400 5150 2    50   ~ 0
ADDR1_3
Text Label 9400 4950 2    50   ~ 0
ADDR1_4
Text Label 9400 5250 2    50   ~ 0
ADDR1_5
Text Label 9400 5650 2    50   ~ 0
ADDR1_6
Text Label 10850 5250 0    50   ~ 0
ADDR1_7
Text Label 6950 7600 0    50   ~ 0
WMASK0_0
Text Label 6950 8000 0    50   ~ 0
WMASK0_1
Text Label 6950 7700 0    50   ~ 0
WMASK0_2
Text Label 6950 7100 0    50   ~ 0
WMASK0_3
Text Label 10850 4150 0    50   ~ 0
WMASK0_0
Text Label 10850 3950 0    50   ~ 0
WMASK0_1
Text Label 10850 3750 0    50   ~ 0
WMASK0_2
Text Label 10850 3850 0    50   ~ 0
WMASK0_3
Text Label 6950 6900 0    50   ~ 0
CS0_N
Text Label 10850 3650 0    50   ~ 0
CS0_N
Text Label 10850 4750 0    50   ~ 0
CS1_N
Text Label 6950 7000 0    50   ~ 0
WE0_N
Text Label 10850 4050 0    50   ~ 0
WE0_N
Text Label 6950 7200 0    50   ~ 0
CLK0
Text Label 6950 7800 0    50   ~ 0
CLK1
Text Label 10850 3550 0    50   ~ 0
CLK0
Text Label 10850 4650 0    50   ~ 0
CLK1
Text Label 6950 6700 0    50   ~ 0
DIN0_0
Text Label 6950 6000 0    50   ~ 0
DIN0_1
Text Label 6950 5900 0    50   ~ 0
DIN0_2
Text Label 6950 4700 0    50   ~ 0
DIN0_4
Text Label 6950 5300 0    50   ~ 0
DIN0_5
Text Label 6950 4000 0    50   ~ 0
DIN0_6
Text Label 6950 3400 0    50   ~ 0
DIN0_7
Text Label 9400 7050 2    50   ~ 0
DIN0_0
Text Label 9400 6850 2    50   ~ 0
DIN0_1
Text Label 10850 6150 0    50   ~ 0
DIN0_2
Text Label 9400 6350 2    50   ~ 0
DIN0_4
Text Label 9400 5950 2    50   ~ 0
DIN0_5
Text Label 10850 5450 0    50   ~ 0
DIN0_6
Text Label 9400 5450 2    50   ~ 0
DIN0_7
Text Label 6950 6100 0    50   ~ 0
DOUT0_0
Text Label 6950 7500 0    50   ~ 0
DOUT0_1
Text Label 6950 4900 0    50   ~ 0
DOUT0_3
Text Label 6950 4100 0    50   ~ 0
DOUT0_4
Text Label 6950 5200 0    50   ~ 0
DOUT0_5
Text Label 6950 3600 0    50   ~ 0
DOUT0_6
Text Label 6950 3900 0    50   ~ 0
DOUT0_7
Text Label 10850 6550 0    50   ~ 0
DOUT0_0
Text Label 9400 7250 2    50   ~ 0
DOUT0_1
Text Label 9400 6550 2    50   ~ 0
DOUT0_3
Text Label 10850 5650 0    50   ~ 0
DOUT0_4
Text Label 9400 6150 2    50   ~ 0
DOUT0_5
Text Label 10850 5050 0    50   ~ 0
DOUT0_6
Text Label 9400 5050 2    50   ~ 0
DOUT0_7
Text Label 6950 5400 0    50   ~ 0
DOUT1_1
Text Label 6950 5600 0    50   ~ 0
DOUT1_2
Text Label 6950 5100 0    50   ~ 0
DOUT1_3
Text Label 6950 5000 0    50   ~ 0
DOUT1_4
Text Label 6950 4400 0    50   ~ 0
DOUT1_5
Text Label 6950 4600 0    50   ~ 0
DOUT1_6
Text Label 6950 5500 0    50   ~ 0
DOUT1_7
Text Label 6950 7300 0    50   ~ 0
GPIO0
Text Label 9400 6450 2    50   ~ 0
DOUT1_1
Text Label 10850 5850 0    50   ~ 0
DOUT1_2
Text Label 10850 5350 0    50   ~ 0
DOUT1_3
Text Label 10850 5550 0    50   ~ 0
DOUT1_4
Text Label 9400 5850 2    50   ~ 0
DOUT1_5
Text Label 9400 6050 2    50   ~ 0
DOUT1_6
Text Label 9400 6250 2    50   ~ 0
DOUT1_7
Text Label 10850 4250 0    50   ~ 0
GPIO0
NoConn ~ 10850 4350
NoConn ~ 10850 4450
Text Label 6950 7900 0    50   ~ 0
CS1_N
Text Label 9400 5550 2    50   ~ 0
ADDR1_1
Text Label 6950 3200 0    50   ~ 0
DOUT1_0
Text Label 10850 5150 0    50   ~ 0
DOUT1_0
Text Label 6950 6400 0    50   ~ 0
ADDR0_6
Text Label 10850 6250 0    50   ~ 0
ADDR0_6
Text Label 6950 4800 0    50   ~ 0
DIN0_3
Text Label 10850 5950 0    50   ~ 0
DIN0_3
Text Label 6950 5800 0    50   ~ 0
DOUT0_2
Text Label 10850 6350 0    50   ~ 0
DOUT0_2
$EndSCHEMATC
