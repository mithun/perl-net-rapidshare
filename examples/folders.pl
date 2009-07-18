#!/usr/bin/perl

use strict;
use warnings;
use Net::Rapidshare;

## Initialize
my $rs = Net::Rapidshare->new( cookie => 'ASJHDASJHDGASJHDASD.....' )
    ;    # Use your cookie

## Add new folder
$rs->addrealfolder(
    'newfolder',    # Folder Name
    '1'             # Parent ID, defaults to 0
) or die $rs->errstr;

## Move folder
$rs->moverealfolder(
    '657634345',    # Folder ID
    '2',            # New Parent, defaults to 0
) or die $rs->errstr;

## Rename Folder
$rs->renamerealfolder(
    '87365345',     # Folder ID
    'new name'      # New folder name
) or die $rs->errstr;

## Delete Folder
$rs->delrealfolder(
    '87652'         # Folder ID
) or die $rs->errstr;
