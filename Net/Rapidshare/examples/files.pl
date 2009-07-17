#!/usr/bin/perl

use strict;
use warnings;
use Net::Rapidshare;

## Initialize
my $rs = Net::Rapidshare->new( cookie => 'ASJHDASJHDGASJHDASD.....' )
    ;    # Use your cookie

## List all files sorted by size
my @rows = $rs->listfiles(
    fields => "killcode,name,size",
    order  => 'size'
) or die $rs->errstr;
foreach (@rows) {
    my ( $fileid, $killcode, $name, $size ) = split( /,/, $_ );
    print "Found $name ($size) with ID $fileid and KillCode $killcode\n";
}

## Check if a file is partially uploaded
my $size_on_server = $rs->checkincomplete(
    '1234323423',          # File ID
    '25298475092437502'    # Kill Code
) or die $rs->errstr;

## Get next upload server
my $upload_server = $rs->nextuploadserver or die $rs->errstr;

## Rename a file
$rs->renamefile(
    '23424342',            # file ID
    '817269847623843',     # Kill code
    'newname'              # New name
) or die $rs->errtsr;

## Delete file(s)
$rs->deletefiles(
    "476535874,34959483,94354533"    # File IDs, can also use an ARRAY REF
) or die $rs->errstr;

## Move Files to a folder
$rs->movefilestorealfolder(
    "876453453",                     # Target Folder ID
    "476535874,34959483,94354533"    # File IDs, can also use an ARRAY REF
) or die $rs->errstr;

## Migrate files from one account to another
my $response = $rs->filemigrator(
    fromtype     => 'col',           # Source accnt type
    fromlogin    => 'collector',     # Source accnt login
    frompassword => 'password',      # source accnt password

    totype     => 'prem',            # Target account type
    tologin    => 'premium',         # Target account login
    topassword => 'passwd',          # Target accnt password

    fileids => [ '32524354', '423452345' ],    # File IDs.
) or die $rs->errstr;
my ($number_of_files_moved,     $files_in_src_accnt_before,
    $space_in_src_accnt_before, $files_in_tgt_accnt_before,
    $space_in_tgt_accnt_before, $files_in_src_accnt_after,
    $space_in_src_accnt_after,  $files_in_tgt_accnt_after,
    $space_in_tgt_accnt_after,
) = split( /,/, $response );

## Check if a file exists on server
## Usefull before trying to download them
my $response = $rs->checkfiles(
    [ '87463528345', '982736452345' ],         # File IDs
    ['name1, name2'],                          # Corresponding names
) or die $rs->errstr;
foreach ( keys %{$response} ) {
    my $id     = $_;
    my $status = $response->{$_}->{status};
    my $name   = $response->{$_}->{name};
    my $server = $response->{$_}->{server};
    my $mirror = $response->{$_}->{mirror};

    next if $status;                           # 0 means file exists

    my $file_to_load =
        "http://rs${server}${mirror}.rapidshare.com/${id}/${name}";
}

## Set TrafficShare types for files
$rs->trafficsharetype(
    '101',                                     # On with logging
    [ '87346543', '945934534' ]                # File IDs
) or die $rs->errstr;
