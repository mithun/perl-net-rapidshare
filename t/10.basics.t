use Test::More tests => 7;
use Net::Rapidshare;

my $rs = new_ok('Net::Rapidshare');

my $type   = 'prem';
my $login  = 'hello';
my $pwd    = 'world';
my $cookie = 'ASDFGHJLQWERYIUOASDJFKHAFALDF';

is( $rs->type($type),         $type );
is( $rs->password($password), $password );
is( $rs->login($login),       $login );
is( $rs->cookie($cookie),     $cookie );
ok( $rs->secure );
ok( $rs->unsecure );
