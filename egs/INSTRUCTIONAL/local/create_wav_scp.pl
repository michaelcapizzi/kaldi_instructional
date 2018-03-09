#!/usr/bin/env perl

$waves_dir = $ARGV[0];      #directory of all wave files
$in_list = $ARGV[1];        #list to be used

open IL, $in_list;

while ($l = <IL>)
{
	chomp($l);
	$full_path = $waves_dir . "\/" . $l;
	$l =~ s/\.wav//;
	print "$l $full_path\n";
}

