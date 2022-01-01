#!/usr/bin/php
<?php

if($argc < 2)
	die("Usage: summarize.php die1.csv\n");
$base = $argv[1];

//list of all corners we measured data from
$subdirs = array(
	'dualport/heated',
	'dualport/ambient',
	'dualport/chilled',
	'singleport/heated',
	'singleport/ambient',
	'singleport/chilled');

$summary = array();
for($row = 0; $row < 42; $row ++)
{
	$crow = array();
	for($col = 0; $col < 20; $col ++)
		$crow[$col] = 0;
	$summary[$row] = $crow;
}

foreach($subdirs as $dir)
{
	$fname = $dir . '/' . $base;
	$lines = file($fname);
	for($row=1; $row<42; $row++)	//skip header row
	{
		$line = $lines[$row];
		$fields = explode(',', $line);

		for($col = 0; $col < 20; $col ++)
		{
			if(intval($fields[$col+1]) != 0)
				$summary[$row][$col] ++;
		}
	}
}

//print header
echo " ,";
for($i=10; $i<30; $i++)
	echo "$i, ";
echo "\n";

//print data
for($row = 0; $row < 41; $row ++)
{
	$voltage = 1800 - (10*$row);
	echo "$voltage,";
	for($col = 0; $col < 20; $col ++)
		echo $summary[$row+1][$col] . ',';
	echo "\n";
}

?>
