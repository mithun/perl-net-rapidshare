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
my ( $timestamp, $kbps ) =
    $rs->trafficsharebandwidth( 'start_time', 'end_time' )
    or die $rs->errstr;

## Point logs
my ( $date, $free_points, $prem_points ) = $rs->getpointlogs
    or die $rs->errstr;

## Referrer Logs
my ( $timestamp, $refpoints, $fileid ) = $rs->getreferrerlogs
    or die $rs->errstr;
