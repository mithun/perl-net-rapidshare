#!/usr/bin/perl

use strict;
use warnings;
use Net::Rapidshare;

## Initialize
my $rs = Net::Rapidshare->new( cookie => 'ASJHDASJHDGASJHDASD.....' )
    ;    # Use your cookie

## Tracfficshare Logs
my ( $start_time, $stop_time, $size, $starting_position, $bytes_downloaded,
    $range, $custom )
    = $rs->trafficsharelogs('fileid')
    or die $rs->errstr;

## Trafficshare bandwidth
my (@rows) = $rs->trafficsharebandwidth( 'start_time', 'end_time' )
    or die $rs->errstr;
foreach (@rows) { my ( $timestamp, $kbps ) = split( /,/, $_ ); }

## Point logs
my @rows = $rs->getpointlogs or die $rs->errstr;
foreach (@rows) {
    my ( $date, $free_points, $prem_points ) = split( /,/, $_ );
}

## Referrer Logs
my @rows = $rs->getreferrerlogs or die $rs->errstr;
foreach (@rows) { my ( $timestamp, $refpoints, $fileid ) = split( /,/, $_ ); }
