#!/usr/bin/php
<?php

if($argc < 3)
	die("Usage: makeimage.php rearranged.csv out.png\n");
$fname = $argv[1];
$fout = $argv[2];
$f = file($fname);

$img = imagecreatetruecolor(16, 128);

//First pass: find min and max voltages (0 means no data, ignore)
$vmin = 1800;
$vmax = 0;
for($y=0; $y<128; $y++)
{
	$line = $f[$y];
	$fields = explode(',', $line);
	foreach($fields as $num)
	{
		if( ($num < $vmin) && ($num != 0) )
			$vmin = $num;
		if($num > $vmax)
			$vmax = $num;
	}
}

//Read the gradient
$fp = fopen('viridis.rgba', 'rb');
$colors = array();
for($i=0; $i<256; $i++)
{
	$r = ord(fread($fp, 1));
	$g = ord(fread($fp, 1));
	$b = ord(fread($fp, 1));
	fread($fp, 1);
	$colors[$i] = imagecolorallocate($img, $r, $g, $b);
}
$transparent = imagecolorallocatealpha($img, 0, 0, 0, 0);

//Second pass: generate scaled plot
$vrange = $vmax - $vmin;

for($y=0; $y<128; $y++)
{
	$line = $f[$y];
	$fields = explode(',', $line);

	for($x=0; $x<16; $x++)
	{
		$v = $fields[$x];
		$frac = ($v - $vmin) / $vrange;
		if($v == 0)
			imagesetpixel($img, $x, $y, $transparent);

		else
			imagesetpixel($img, $x, $y, $colors[round($frac*255)]);
	}
}

imagepng($img, $fout);

?>
