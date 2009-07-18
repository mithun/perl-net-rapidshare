#!/usr/bin/perl

use strict;
use warnings;
use Net::Rapidshare;

## Initialize a new object
my $rs = Net::Rapidshare->new(
    type     => 'prem',     # Account type
    login    => 'hello',    # Account login
    password => 'world',    # Account Password
);

## Get your current API usage
my ( $curr, $max ) = $rs->getapicpu or die $rs->errstr;

## Use an 'https' connection
$rs->secure;

## Get your account details
my %account = $rs->getaccountdetails( withcookie => 1 ) or die $rs->errstr;

## Use a cookie string to authenticate
## When you set a cookie, all methods use a
## dummy login/password
## This way you do not transmit on a non secure connection
$rs->cookie( $account{cookie} );

## Use an 'http' connection after setting a cookie
$rs->unsecure;

## Update your account details
$rs->setaccountdetails(
    email => 'john@smith.com',
    newpassword =>
        'secret',    # you might want to use secure if setting password
    directstart => 1,
    mirror      => 'l3',
) or die $rs->errstr;

## Enable RS AntiHack
$rs->enablersantihack or die $rs->errstr;

## Send RS AntiHack email
$rs->sendrsantihackmail or die $rs->errstr;

## Disable RS AntiHack
$rs->disablersantihack('unlock code') or die $rs->errstr;

## Buy Lots
my $num_of_lots = $rs->buylots('how many') or die $rs->errstr;

## Vote
$rs->masspoll(
    '34534535342',    # Poll ID
    '10'             # Vote
) or die $rs->errstr;
