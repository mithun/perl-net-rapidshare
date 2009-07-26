#!/usr/bin/perl

use strict;
use warnings;
use Net::Rapidshare;

## Initialize
my $rs = Net::Rapidshare->new( cookie => 'ASJHDASJHDGASJHDASD.....' )
    ;    # Use your cookie

## Create a new link list
my $new_ll_id = $rs->newlinklist(
    name     => 'newlist',             # Name
    headline => 'my new link list',    # Headline
    nickname => 'll1',                 # Nickname
    password => 'secret',              # Password
) or die $rs->errstr;

## Create a new sub folder (or sub link list)
my $new_sub_id = $rs->newlinklistsubfolder(
    folderid    => 'MJHG67',           # Parent link list ID
    name        => 'newsublist',       # Name
    description => 'new links',        # Description
    password    => 'secret',           # Password
) or die $rs->errstr;

## Add files to a link list
$rs->copyfilestolinklist(
    folderid => 'MJHG67',                       # Parent link list ID
    fileids => [ '73876221', '7876523523' ],    # File IDs
) or die $rs->errstr;

## Edit a link list
$rs->editlinklist(
    folderid => 'HDKS778',                      # Link list ID
    name     => 'newlist',                      # Name
    headline => 'my new link list',             # Headline
    nickname => 'll1',                          # Nickname
    password => 'secret',                       # Password
) or die $rs->errstr;

## Edit a link list entry (sub link list OR file)
$rs->editlinklistentry(
    folderid    => 'HFGSK87',                   # Link list ID
    fileid      => '876872345',                 # File ID
    description => 'hey, get this file',        # Description
) or die $rs->errstr;

## Get link lists
my $lists = $rs->getlinklist or die $rs->errstr;
my @ids = keys %{$lists};
foreach my $id (@ids) {
    my $name     = $list->{$id}->{name};
    my $headline = $list->{$id}->{headline};
}

## Delete Link list entries
$rs->deletelinklistentries(
    folderid => 'HHSKL76',                      # Link list ID
    fileids => [ '73876221', '7876523523' ],    # File IDs to delete
) or die $rs->errstr;

## Delete a link list
$rs->deletelinklist('JHSDS7') or die $rs->errstr;
