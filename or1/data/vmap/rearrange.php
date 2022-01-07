#!/usr/bin/php
<?php

if($argc < 2)
	die("Usage: rearrange.php die1.csv\n");
$fname = $argv[1];

/*
Two words per physical row, interleaved (so bit0A bit0B bit1A bit1B ...)
Addresses go from bottom to top
*/

//Read the input data
$f = file($fname);
$data = array();
for($row = 0; $row < 256; $row ++)
{
	$line = $f[$row+1];
	$fields = explode(',', $line);

	$crow = array();
	for($col = 0; $col < 8; $col ++)
		$crow[$col] = intval($fields[$col+1]);
	$data[$row] = $crow;
}

//Reformat it
for($addr=254; $addr>=0; $addr -= 2)
{
	$a = $data[$addr];
	$b = $data[$addr + 1];

	for($i=0; $i<8; $i++)
		printf('%5d, %5d, ', $a[$i], $b[$i]);
	echo "\n";
}

?>
