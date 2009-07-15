package Net::Rapidshare;

use strict;
use warnings;
use Carp;
use LWP::UserAgent;

use version; our $VERSION = qv("0.01");

### Interface
my $rs_url       = "http://api.rapidshare.com/cgi-bin/rsapi.cgi?";
my $rs_secureurl = "https://api.rapidshare.com/cgi-bin/rsapi.cgi?";

sub new {
    my $class = shift;
    my %h     = ();
    if (@_) {
        my %valid = ( "type" => 1, "login" => 1, "password" => 1 );
        (%h) = @_;
        foreach ( keys %h ) { croak "Invalid Option : $_" unless $valid{$_}; }
        croak "Invalid Type $h{type}" unless _valid_type( $h{type} );
    }
    $h{"_url"} = $rs_url;
    return bless {%h}, $class;
}

sub type {
    my $self = shift;
    my $type = shift;
    if ($type) {
        croak "Invalid Type $type" unless _valid_type($type);
        $self->{type} = $type;
    }
    return $self->{type};
}

sub login {
    my $self  = shift;
    my $login = shift;
    if ($login) { $self->{login} = $login; }
    return $self->{login};
}

sub password {
    my $self     = shift;
    my $password = shift;
    if ($password) { $self->{password} = $password; }
    return $self->{password};
}

sub secure {
    my $self = shift;
    $self->{_url} = $rs_secureurl;
    return 1;
}

sub unsecure {
    my $self = shift;
    $self->{_url} = $rs_url;
    return 1;
}

sub proxy {
    my $self  = shift;
    my $proxy = shift;
    if ($proxy) {
        croak "Invalid Proxy : $proxy" unless ( $proxy =~ /^http/ );
        $self->{proxy} = $proxy;
    }
    return $self->{proxy};
}

sub errstr {
    my $self = shift;
    return $self->{errstr};
}

sub cookie {
    my $self   = shift;
    my $cookie = shift;
    if ($cookie) { $self->{cookie} = $cookie; }
    return $self->{cookie};
}

### API Calls
sub nextuploadserver {
    my $self = shift;

    my $sub  = "nextuploadserver_v1";
    my $call = $self->{_url} . "sub=${sub}";
    my $node = $self->_get_resp($call) or return;

    return "http://rs${node}.rapidshare.com";
}

sub getapicpu {
    my $self = shift;

    my $sub      = "getapicpu_v1";
    my $call     = $self->{_url} . "sub=${sub}";
    my $response = $self->_get_resp($call) or return;

    return split( /,/, $response );
}

sub checkincomplete {
    my $self     = shift;
    my $fileid   = shift or croak "fileid is required, but missing";
    my $killcode = shift or croak "killcode is required, but missing";

    my $sub  = "checkincomplete_v1";
    my $call = $self->{_url} . "sub=${sub}";
    $call .= "&fileid=${fileid}";
    $call .= "&killcode=${killcode}";

    return $self->_get_resp($call);
}

sub renamefile {
    my $self     = shift;
    my $fileid   = shift or croak "fileid is required, but missing";
    my $killcode = shift or croak "killcode is required, but missing";
    my $newname  = shift or croak "new name is required, but missing";

    my $sub = "renamefile_v1";
    my $call = $self->_default_url($sub) or return;
    $call .= "&fileid=${fileid}";
    $call .= "&killcode=${killcode}";
    $call .= "&newname=${newname}";

    return $self->_get_resp($call);
}

sub movefilestorealfolder {
    my $self = shift;
    my $realfolderid = shift or croak "realfolderid is required, but missing";
    croak "fileids are required, but missing" unless @_;

    my $fileids;
    my @fileids_arr;
    if ( ref @_ eq 'ARRAY' ) {
        @fileids_arr = @{@_};
        $fileids = join( ',', @fileids_arr );
    }
    else {
        $fileids = join( ',', @_ );
    }
    if ( length($fileids) > 10000 ) {
        $self->{errstr} = "Length of fileids is more than 10,000 bytes";
        return;
    }

    my $sub = "movefilestorealfolder_v1";
    my $call = $self->_default_call($sub) or return;
    $call .= "&files=${fileids}";
    $call .= "&realfolder=${realfolderid}";

    return $self->_get_resp($call);
}

sub renamerealfolder {
    my $self         = shift;
    my $realfolderid = shift or croak "realfolderid is required, but missing";
    my $newname      = shift or croak "newname is required, but missing";

    if ( length($newname) > 100 ) {
        $self->{errstr} = "Length of newname is more than 100 Chars";
        return;
    }

    my $sub = "renamerealfolder_v1";
    my $call = $self->_default_call($sub) or return;
    $call .= "&realfolder=${realfolderid}";
    $call .= "&newname=${newname}";

    return $self->_get_resp($call);
}

sub deletefiles {
    my $self = shift;
    croak "fileids are required, but missing" unless @_;

    my $fileids;
    my @fileids_arr;
    if ( ref @_ eq 'ARRAY' ) {
        @fileids_arr = @{@_};
        $fileids = join( ',', @fileids_arr );
    }
    else {
        $fileids = join( ',', @_ );
    }
    if ( length($fileids) > 10000 ) {
        $self->{errstr} = "Length of fileids is more than 10,000 bytes";
        return;
    }

    my $sub = "deletefiles_v1";
    my $call = $self->_default_call($sub) or return;
    $call .= "&files=${fileids}";

    return $self->_get_resp($call);
}

sub addrealfolder {
    my $self   = shift;
    my $name   = shift;
    my $parent = shift or 0;

    if ( length($name) > 100 ) {
        $self->{errstr} = "Length of name is greater than 100 bytes";
        return;
    }

    my $sub = "addrealfolder_v1";
    my $call = $self->_default_call($sub) or return;
    $call .= "&name=${name}";
    $call .= "&parent=${parent}";

    my $response = $self->_get_resp($call);
    if ( $response eq '-1' ) {
        $self->{errstr} = "No space available";
        return;
    }
    return $response;
}

sub delrealfolder {
    my $self = shift;
    my $realfolder = shift or croak "realfolderid is required, but missing";

    my $sub = "delrealfolder_v1";
    my $call = $self->_default_call($sub) or return;
    $call .= "&realfolder=${realfolder}";

    return $self->_get_resp($call);
}

sub moverealfolder {
    my $self       = shift;
    my $realfolder = shift or croak "realfolderid is required, but missing";
    my $newparent  = shift or 0;

    my $sub = "moverealfolder_v1";
    my $call = $self->_default_call($sub) or return;
    $call .= "&realfolder=${realfolder}";
    $call .= "&newparent=${newparent}";

    return $self->_get_resp($call);
}

sub listfiles {
    my $self = shift;

    my %options;
    %options = %{ _read_opts(@_) } if @_;
    my ( $realfolder, $filename, $fields, $order, $desc ) = '0';
    $realfolder = $options{'realfolder'} if exists $options{'realfolder'};
    $filename   = $options{'filename'}   if exists $options{'filename'};
    $fields     = $options{'fields'}     if exists $options{'fields'};
    $order      = $options{'order'}      if exists $options{'order'};
    $desc       = $options{'desc'}       if exists $options{'desc'};

    my $sub = "listfiles_v1";
    my $call = $self->_default_call($sub) or return;
    $call .= "&realfolder=${realfolder}";
    $call .= "&filename=${filename}" if $filename;
    $call .= "&fields=${fields}" if $fields;
    $call .= "&order=${order}" if $order;
    $call .= "&desc=${desc}";

    my $response = $self->_get_resp($call) or return;
    my @list = split( /\n/, $response );
    return @list if wantarray;
    return \@list;
}

sub listrealfolders {
    my $self = shift;

    my $sub = "listrealfolders_v1";
    my $call = $self->_default_call($sub) or return;

    my $response = $self->_get_resp($call) or return;
    return ($response) if ( uc($response) eq 'NONE' );
    my @list = split( /\n/, $response );
    return @list if wantarray;
    return \@list;
}

sub getaccountdetails {
    my $self = shift;

    my %options;
    %options = %{ _read_opts(@_) } if @_;
    my ( $withrefstring, $withcookie ) = '0';
    $withrefstring = $options{'withrefstring'}
        if exists $options{'withrefstring'};
    $withcookie = $options{'withcookie'} if exists $options{'withrefstring'};

    my $sub = "getaccountdetails_v1";
    my $call = $self->_default_call($sub) or return;
    $call .= "&withrefstring=1" if $withrefstring;
    $call .= "&withcookie=1"    if $withcookie;

    my $response = $self->_get_resp($call) or return;
    my @lines = split( /\n/, $response );
    my %accnt = ();
    foreach my $line (@lines) {
        my ( $key, $value ) = split( /=/, $line );
        $accnt{"$key"} = $value;
    }
    return %accnt if wantarray;
    return \%accnt;
}

sub setaccountdetails {
    my $self = shift;

    my %options;
    %options = %{ _read_opts(@_) } if @_;
    my ($newpassword, $email,    $username,
        $mirror,      $mirror2,  $mirror3,
        $directstart, $jsconfig, $plustrafficmode
    ) = 0;
    croak "email is required, but missing" unless exists $options{'email'};
    $email       = $options{'email'};
    $newpassword = $options{'newpassword'} if exists $options{'newpassword'};
    $username    = $options{'username'} if exists $options{'username'};
    $mirror      = $options{'mirror'} if exists $options{'mirror'};
    $mirror2     = $options{'mirror2'} if exists $options{'mirror2'};
    $mirror3     = $options{'mirror3'} if exists $options{'mirror3'};
    $directstart = $options{'directstart'} if exists $options{'directstart'};
    $jsconfig    = $options{'jsconfig'} if exists $options{'jsconfig'};
    $plustrafficmode = $options{'plustrafficmode'}
        if exists $options{'plustrafficmode'};

    my $sub = "setaccountdetails_v1";
    my $call = $self->_default_call($sub) or return;
    $call .= "&email=${email}";
    $call .= "&newpassword=${newpassword}" if $newpassword;
    $call .= "&username=${username}" if $username;
    $call .= "&mirror=${mirror}" if $mirror;
    $call .= "&mirror2=${mirror2}" if $mirror2;
    $call .= "&mirror3=${mirror3}" if $mirror3;
    $call .= "&directstart=${directstart}" if $directstart;
    $call .= "&jsconfig=${jsconfig}" if $jsconfig;
    $call .= "&plustrafficmode=${plustrafficmode}"
        if exists $options{'plustrafficmode'};

    return $self->_get_resp($call);
}

sub enablersantihack {
    my $self = shift;

    my $sub = "enablersantihack_v1";
    my $call = $self->_default_call($sub) or return;
    return $self->_get_resp($call);
}

sub disablersantihack {
    my $self = shift;
    my $unlockcode = shift or croak "unlock code is required, but missing";

    my $sub = "disablersantihack_v1";
    my $call = $self->_default_call($sub) or return;
    $call .= "&unlockcode=${unlockcode}";

    return $self->_get_resp($call);
}

sub sendrsantihackmail {
    my $self = shift;

    my $sub = "sendrsantihackmail_v1";
    my $call = $self->_default_call($sub) or return;
    return $self->_get_resp($call);
}

sub filemigrator {
    my $self = shift;
    croak "no options passed" unless @_;

    my %options  = %{ _read_opts(@_) };
    my $fromtype = $options{fromtype}
        or croak "fromtype is required, but missing";
    my $fromlogin = $options{fromlogin}
        or croak "fromlogin is required, but missing";
    my $frompassword = $options{frompassword}
        or croak "frompassword is required, but missing";
    my $totype = $options{totype} or croak "totype is required, but missing";
    my $tologin = $options{tologin}
        or croak "tologin is required, but missing";
    my $topassword = $options{topassword}
        or croak "topassword is required, but missing";
    my $fileids_ref = $options{fileids}
        or croak "fileids are required, but missing";
    my $acceptfee = $options{acceptfee}
        or croak "acceptfee is required, but missing";
    my $linkedlists = $options{linkedlists} or 0;

    my $from;
    $from = "free" if ( lc($fromtype) eq 'free' );
    $from = "prem" if ( lc($fromtype) eq 'prem' );
    $from = "col"  if ( lc($fromtype) eq 'col' );
    croak "Unsupported fromtype $fromtype" unless $from;

    my $to;
    $to = "prem" if ( lc($totype) eq 'prem' );
    $to = "col"  if ( lc($totype) eq 'col' );
    croak "Unsupported totype $totype" unless $to;

    if ($linkedlists) {
        croak "Cannot moved linked lists from $fromtype to $totype"
            unless ( ( $from eq 'prem' ) and ( $to eq 'prem' ) );
    }

    my $movetype = "${from}${to}";
    $movetype = "ll" . $movetype if $linkedlists;

    my $fileids;
    if ( ref $fileids_ref eq 'ARRAY' ) {
        $fileids = join( ',', @{$fileids_ref} );
    }
    $fileids = $fileids_ref;

    my ( $fromfolder, $tofolder ) = 0;
    $fromfolder = $options{fromfolder} if exists $options{fromfolder};
    $tofolder   = $options{tofolder}   if exists $options{tofolder};

    my $sub = "filemigrator_v1";
    my $call = $self->_default_call($sub) or return;
    $call .= "&srcaccount=${fromlogin}";
    $call .= "&srcpassword=${frompassword}";
    $call .= "&srcrealfolder=${fromfolder}" if $fromfolder;
    $call .= "&targetaccount=${tologin}";
    $call .= "&targetpassword=${topassword}";
    $call .= "&targetrealfolder=${tofolder}" if $tofolder;
    $call .= "&movetype=${movetype}";
    $call .= "&fileids=${fileids}";
    $call .= "&acceptfee=${acceptfee}";

    my $response = $self->_get_resp($call) or return;
    return split( /,/, $response );
}

sub checkfiles {
    my $self          = shift;
    my $fileids_ref   = shift or croak "fileids are required, but missing";
    my $filenames_ref = shift or croak "filenames are required, but missing";
    my $md5           = shift or 0;

    my $fileids;
    if ( ref $fileids_ref eq 'ARRAY' ) {
        $fileids = join( ',', @{$fileids_ref} );
    }
    else { $fileids = $fileids_ref; }

    my $filenames;
    if ( ref $filenames_ref eq 'ARRAY' ) {
        $filenames = join( ',', @{$filenames_ref} );
    }
    else { $filenames = $filenames_ref; }

    my $sub  = "checkfiles_v1";
    my $call = $self->{_url};
    $call .= "sub=${sub}";
    $call .= "&files=${fileids}";
    $call .= "&filenames=${filenames}";
    $call .= "&incmd5=${md5}" if $md5;
    my $response = $self->_get_resp($call) or return;
    my @lines = split( /\n/, $response );
    my $list;

    foreach my $line (@lines) {
        my ( $id, $name, $size, $server, $status, $mirror, $md5 ) =
            split( /,/, $line );
        $list->{$id}->{name}   = $name;
        $list->{$id}->{size}   = $size;
        $list->{$id}->{server} = $server;
        $list->{$id}->{status} = $status;
        $list->{$id}->{mirror} = $mirror;
        $list->{$id}->{md5}    = $md5;
    }
    return $list;
}

sub trafficsharetype {
    my $self = shift;
    my $type = shift or croak "traffic share type is required, but missing";
    my $fileids_ref = shift or croak "File ids are required, but missing";

    my $fileids;
    if ( ref $fileids_ref eq 'ARRAY' ) {
        $fileids = join( ',', @{$fileids_ref} );
    }
    else { $fileids = $fileids_ref; }

    my $sub = "trafficsharetype_v1";
    my $call = $self->_default_call($sub) or return;
    $call .= "&files=${fileids}";
    $call .= "&trafficsharetype=${type}";

    return $self->_get_resp($call);
}

sub trafficsharelogs {
    my $self = shift;
    my $fileid = shift or croak "File id is required, but missing";

    my $sub  = "trafficsharelogs_v1";
    my $call = $self->_default_call($sub);
    $call .= "&fileid=${fileid}";

    my $response = $self->_get_resp($call) or return;
    return split( /"/, $response );
}

sub trafficsharebandwidth {
    my $self  = shift;
    my $start = shift or croak "Start time is required, but missing";
    my $end   = shift or croak "End time is required, but missing";

    croak "Invalid time format $start"
        unless ( $start =~ /^{[[:digit:]]}{10}$/ );
    croak "Invalid time format $end" unless ( $end =~ /^{[[:digit:]]}{10}$/ );

    my $sub = "trafficsharebandwidth_v1";
    my $call = $self->_default_call($sub) or return;
    $call .= "&starttime=${start}";
    $call .= "&endtime=${end}";

    my $response = $self->_get_resp($call) or return;
    return split( /,/, $response );
}

sub buylots {
    my $self = shift;
    my $new = shift or croak "Number of new lots is required, but missing";

    my $sub = "buylots_v1";
    my $call = $self->_default_call($sub) or return;
    $call .= "&newlots=${new}";

    return $self->_get_resp($call);
}

sub getpointlogs {
    my $self = shift;

    my $sub      = "getpointlogs_v1";
    my $call     = $self->_default_call($sub) or return;
    my $response = $self->_get_resp($call) or return;
    my @list     = split( /\n/, $response );
    return @list if wantarray;
    return \@list;
}

sub getreferrerlogs {
    my $self = shift;

    my $sub      = "getreferrerlogs_v1";
    my $call     = $self->_default_call($sub) or return;
    my $response = $self->_get_resp($call) or return;
    my @list     = split( /\n/, $response );
    return @list if wantarray;
    return \@list;
}

sub masspoll {
    my $self   = shift;
    my $pollid = shift or croak "Poll ID is required, but missing";
    my $vote   = shift or croak "Vote is required, but missing";

    my $sub = "masspoll_v1";
    my $call = $self->_default_call($sub) or return;
    $call .= "&pollid=${pollid}";
    $call .= "&vote=${vote}";

    return $self->_get_resp($call);
}

### Internal Utilities
sub _get_resp {
    my $self = shift;
    my $call = shift;

    my $ua = LWP::UserAgent->new;
    $ua->agent("Rapidshare::API/$VERSION");
    $ua->proxy( 'http', $self->{proxy} ) if $self->{proxy};

    my $response = $ua->get($call);
    unless ( $response->is_success ) {
        $self->{errstr} = $response->status_line;
        return;
    }
    my $resp_str = ${ $response->content_ref };
    return $resp_str if $self->_response_is_good($resp_str);
    return;
}

sub _response_is_good {
    my $self = shift;
    my $str  = shift;
    if ( $str =~ /^ERROR/ ) { $self->{errstr} = $str; return; }
    return 1;
}

sub _valid_type {
    my $type = shift or return;
    my %valid = ( "col" => 1, "prem" => 1 );
    return $valid{$type} if $valid{$type};
    return;
}

sub _is_init {
    my $self = shift;
    return 1 if ( $self->{type} and $self->{login} and $self->{password} );
    $self->{errstr} = "Not initialized with type/login/password";
    return;
}

sub _read_opts {
    my %options;
    if   ( ref @_ eq 'HASH' ) { %options   = %{@_}; }
    else                      { (%options) = @_; }
    return \%options;
}

sub _default_call {
    my $self = shift;
    my $sub  = shift;

    return unless $self->_is_init;
    my $call = $self->{_url};
    $call .= "sub=${sub}";
    $call .= "&type=" . $self->{type};
    $call .= "&login=" . $self->{login};
    $call .= "&password=" . $self->{password};
    $call .= "&cookie=" . $self->{cookie} if $self->{cookie};

    return $call;
}

1;
