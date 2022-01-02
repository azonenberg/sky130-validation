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
for($row = 0; $row < 46; $row ++)
{
	$crow = array();
	for($col = 0; $col < 36; $col ++)
		$crow[$col] = 0;
	$summary[$row] = $crow;
}

foreach($subdirs as $dir)
{
	$fname = $dir . '/' . $base;
	$lines = file($fname);
	for($row=1; $row<46; $row++)	//skip header row
	{
		$line = $lines[$row];
		$fields = explode(',', $line);

		for($col = 0; $col < 36; $col ++)
		{
			if(intval($fields[$col+1]) != 0)
				$summary[$row][$col] ++;
		}
	}
}

//print header
echo " ,";
for($i=10; $i<=45; $i++)
	echo "$i, ";
echo "\n";

//print data
for($row = 0; $row < 45; $row ++)
{
	$phase = 11000 - (100*$row);
	echo "$phase,";
	for($col = 0; $col < 36; $col ++)
		echo $summary[$row+1][$col] . ',';
	echo "\n";
}

?>
