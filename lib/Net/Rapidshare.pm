package Net::Rapidshare;

use strict;
use warnings;
use Carp;
use LWP::UserAgent;
use HTML::Entities;

our $VERSION = 0.05;

### Interface
my $rs_url       = "http://api.rapidshare.com/cgi-bin/rsapi.cgi?";
my $rs_secureurl = "https://api.rapidshare.com/cgi-bin/rsapi.cgi?";

sub new {
    my $class = shift;
    my %h     = ();
    if (@_) {
        my %valid = (
            "type"     => 1,
            "login"    => 1,
            "password" => 1,
            "cookie"   => 1,
        );
        croak "Uneven number of options passed" if ( @_ % 2 );
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
    my $self    = shift;
    my $fileid  = shift or croak "fileid is required, but missing";
    my $newname = shift or croak "new name is required, but missing";

    my $sub = "renamefile_v1";
    my $call = $self->_default_call($sub) or return;
    $call .= "&fileid=${fileid}";
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
    my $name   = shift or croak "folder name is required, but missing";
    my $parent = shift;

    if ( length($name) > 100 ) {
        $self->{errstr} = "Length of name is greater than 100 bytes";
        return;
    }

    my $sub = "addrealfolder_v1";
    my $call = $self->_default_call($sub) or return;
    $call .= "&name=${name}";
    if   ($parent) { $call .= "&parent=${parent}"; }
    else           { $call .= "&parent=0"; }

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
    my $newparent  = shift;

    my $sub = "moverealfolder_v1";
    my $call = $self->_default_call($sub) or return;
    $call .= "&realfolder=${realfolder}";
    if   ($newparent) { $call .= "&newparent=${newparent}"; }
    else              { $call .= "&newparent=0"; }

    return $self->_get_resp($call);
}

sub listfiles {
    my $self = shift;

    my %options;
    %options = %{ _read_opts(@_) } if @_;
    my ( $realfolder, $filename, $fileids, $fields, $order, $desc );
    $realfolder = "all";
    $realfolder = $options{'realfolder'} if exists $options{'realfolder'};
    $filename   = $options{'filename'} if exists $options{'filename'};
    $fields     = $options{'fields'} if exists $options{'fields'};
    $fileids    = $options{'fileids'} if exists $options{'fileids'};
    $order      = $options{'order'} if exists $options{'order'};
    $desc       = $options{'desc'} if exists $options{'desc'};

    my $sub = "listfiles_v1";
    my $call = $self->_default_call($sub) or return;
    $call .= "&realfolder=${realfolder}";
    $call .= "&filename=${filename}" if $filename;
    $call .= "&fields=${fields}" if $fields;
    $call .= "&fileids=${fileids}" if $fileids;
    $call .= "&order=${order}" if $order;
    $call .= "&desc=1" if $desc;

    my $response = $self->_get_resp($call) or return;
    return ($response) if ( uc($response) eq 'NONE' );
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
    my ( $withrefstring, $withcookie );
    $withrefstring = $options{'withrefstring'}
      if exists $options{'withrefstring'};
    $withcookie = $options{'withcookie'} if exists $options{'withcookie'};

    my $sub = "getaccountdetails_v1";
    my $call = $self->_default_call($sub) or return;
    $call .= "&withrefstring=1" if $withrefstring;
    $call .= "&withcookie=1"    if $withcookie;

    my $response = $self->_get_resp($call) or return;
    my @lines = split( /\n/, $response );
    my %accnt = ();
    foreach my $line (@lines) {
        my ( $key, $value ) = split( /=/, $line );
        $accnt{$key} = $value;
    }
    return %accnt if wantarray;
    return \%accnt;
}

sub setaccountdetails {
    my $self = shift;

    my %options;
    %options = %{ _read_opts(@_) } if @_;
    my (
        $newpassword, $email,    $username,
        $mirror,      $mirror2,  $mirror3,
        $directstart, $jsconfig, $plustrafficmode
    );
    $email = $options{'email'} or croak "email is required, but missing";
    $newpassword = $options{'newpassword'} if exists $options{'newpassword'};
    $username    = $options{'username'}    if exists $options{'username'};
    $mirror      = $options{'mirror'}      if exists $options{'mirror'};
    $mirror  .= "," . $options{'mirror2'} if exists $options{'mirror2'};
    $mirror3 .= "," . $options{'mirror3'} if exists $options{'mirror3'};
    $directstart = $options{'directstart'} if exists $options{'directstart'};
    $jsconfig    = $options{'jsconfig'}    if exists $options{'jsconfig'};
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
    my $from;
    $from = "free" if ( lc($fromtype) eq 'free' );
    $from = "prem" if ( lc($fromtype) eq 'prem' );
    $from = "col"  if ( lc($fromtype) eq 'col' );
    croak "Unsupported fromtype $fromtype" unless $from;

    my ( $fromlogin, $frompassword );
    $fromlogin = $options{fromlogin}
      or croak "fromlogin is required, but missing"
      unless ( $from eq 'free' );
    $frompassword = $options{frompassword}
      or croak "frompassword is required, but missing"
      unless ( $from eq 'free' );

    my $totype = $options{totype} or croak "totype is required, but missing";
    my $to;
    $to = "prem" if ( lc($totype) eq 'prem' );
    $to = "col"  if ( lc($totype) eq 'col' );
    croak "Unsupported totype $totype" unless $to;

    my $tologin = $options{tologin}
      or croak "tologin is required, but missing";
    my $topassword = $options{topassword}
      or croak "topassword is required, but missing";

    my $fileids_ref = $options{fileids}
      or croak "fileids are required, but missing";
    my $acceptfee = $options{acceptfee}
      or croak "acceptfee is required, but missing";
    my $linkedlists = $options{linkedlists} or undef;

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
    $call .= "&srcaccount=${fromlogin}"      if $fromlogin;
    $call .= "&srcpassword=${frompassword}"  if $frompassword;
    $call .= "&srcrealfolder=${fromfolder}"  if $fromfolder;
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
    my $md5           = shift;

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
    my $self        = shift;
    my $type        = shift;
    my $fileids_ref = shift or croak "File ids are required, but missing";

    my $fileids;
    if ( ref $fileids_ref eq 'ARRAY' ) {
        $fileids = join( ',', @{$fileids_ref} );
    }
    else { $fileids = $fileids_ref; }

    my $sub = "trafficsharetype_v1";
    my $call = $self->_default_call($sub) or return;
    $call .= "&files=${fileids}";
    if   ($type) { $call .= "&trafficsharetype=${type}"; }
    else         { $call .= "&trafficsharetype=0"; }

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
    return split( /\n/, $response );
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

sub premiumzonelogs {
    my $self = shift;

    my $sub      = "premiumzonelogs_v1";
    my $call     = $self->_default_call($sub) or return;
    my $response = $self->_get_resp($call) or return;
    my @rows     = split( /\n/, $response );

    return @rows if wantarray;
    return \@rows;
}

sub newlinklist {
    my $self = shift;

    my %options = %{ _read_opts(@_) } if @_;
    my ( $name, $headline, $nickname, $llpwd );
    $name     = $options{name}     if exists $options{name};
    $headline = $options{headline} if exists $options{headline};
    $nickname = $options{nickname} if exists $options{nickname};
    $llpwd    = $options{password} if exists $options{password};

    my $sub = "newlinklist_v1";
    my $call = $self->_default_call($sub) or return;
    $call .= "&foldername=${name}"         if $name;
    $call .= "&folderheadline=${headline}" if $headline;
    $call .= "&nickname=${nickname}"       if $nickname;
    $call .= "&folderpassword=${llpwd}"    if $llpwd;

    return $self->_get_resp($call);
}

sub editlinklist {
    my $self = shift;
    croak "No options passed" unless @_;

    my %options = %{ _read_opts(@_) };
    my ( $id, $name, $headline, $nickname, $llpwd );
    $id = $options{id} or croak "Linked List ID is required, but missing";
    $name     = $options{name}     if exists $options{name};
    $headline = $options{headline} if exists $options{headline};
    $nickname = $options{nickname} if exists $options{nickname};
    $llpwd    = $options{password} if exists $options{password};

    my $sub = "editlinklist_v1";
    my $call = $self->_default_call($sub) or return;
    $call .= "&folderid=${id}";
    $call .= "&foldername=${name}" if $name;
    $call .= "&folderheadline=${headline}" if $headline;
    $call .= "&nickname=${nickname}" if $nickname;
    $call .= "&folderpassword=${llpwd}" if $llpwd;

    return $self->_get_resp($call);
}

sub getlinklist {
    my $self = shift;

    my %options;
    %options = %{ _read_opts(@_) } if @_;
    my ( $id, $showsubs );
    $id       = $options{id}       if exists $options{id};
    $showsubs = $options{showsubs} if exists $options{showsubs};

    my $sub = "getlinklist_v1";
    my $call = $self->_default_call($sub) or return;
    $call .= "&folderid=${id}"   if $id;
    $call .= "&withsubfolders=1" if $showsubs;

    my $response = $self->_get_resp($call) or return;
    my @rows = split( /\n/, $response );

    my $list;
    if ($id) {
        foreach (@rows) {
            my ( $subid, $fileid, $name, $size, $description, $addtime ) =
              split( /,/, $_ );
            foreach ( $subid, $fileid, $name, $size, $description, $addtime ) {
                $_ = decode_entities($_);
            }
            $list->{$id}->{subfolderid} = $subid;
            $list->{$id}->{fileid}      = $fileid;
            $list->{$id}->{name}        = $name;
            $list->{$id}->{size}        = $size;
            $list->{$id}->{description} = $description;
            $list->{$id}->{addtime}     = $addtime;
        }
    }
    else {
        foreach (@rows) {
            my ( $id, $subid, $name, $headline, $views, $lastview, $pwd, $nick )
              = split( /,/, $_ );
            foreach ( $id, $subid, $name, $headline, $views, $lastview, $pwd,
                $nick )
            {
                $_ = decode_entities($_);
            }
            $list->{$id}->{subfolderid} = $subid;
            $list->{$id}->{name}        = $name;
            $list->{$id}->{headline}    = $headline;
            $list->{$id}->{views}       = $views;
            $list->{$id}->{lastview}    = $lastview;
            $list->{$id}->{password}    = $pwd;
            $list->{$id}->{nickname}    = $nick;
        }
    }
    return $list;
}

sub newlinklistsubfolder {
    my $self = shift;
    croak "No options passed" unless @_;

    my %options = %{ _read_opts(@_) };
    my ( $folderid, $subfolderid, $name, $password, $description );
    $folderid = $options{folderid}
      or croak "Folder ID is required, but missing";
    $name = $options{name} or croak "Name is required, but missing";
    $subfolderid = $options{subfolderid} if exists $options{subfolderid};
    $password    = $options{password}    if exists $options{password};
    $description = $options{description} if exists $options{description};

    my $sub = "newlinklistsubfolder_v1";
    my $call = $self->_default_call($sub) or return;
    $call .= "&folderid=${folderid}";
    $call .= "&newsubfoldername=${name}";
    $call .= "&subfolderid=${subfolderid}" if $subfolderid;
    $call .= "&newsubfolderpassword=${password}" if $password;
    $call .= "&newsubfolderdescription=${description}" if $description;

    return $self->_get_resp($call);
}

sub copyfilestolinklist {
    my $self = shift;
    croak "No options passed" unless @_;

    my %options = %{ _read_opts(@_) };
    my ( $folderid, $subfolderid, $fileids );
    $folderid = $options{folderid}
      or croak "Folder ID is required, but missing";
    $subfolderid = $options{subfolderid} if exists $options{subfolderid};
    croak "File IDs are required, but missing"
      unless exists $options{fileids};
    if ( ref $options{fileids} eq 'ARRAY' ) {
        $fileids = join( ',', @{ $options{fileids} } );
    }
    else { $fileids = $options{fileids}; }

    my $sub = "copyfilestolinklist_v1";
    my $call = $self->_default_call($sub) or return;
    $call .= "&folderid=${folderid}";
    $call .= "&subfolderid=${subfolderid}" if $subfolderid;
    $call .= "&files=${fileids}";

    return $self->_get_resp($call);
}

sub deletelinklist {
    my $self = shift;
    my $folderid = shift or croak "Folder ID is required, but missing";

    my $sub = "deletelinklist_v1";
    my $call = $self->_default_call($sub) or return;
    $call .= "&folderid=${folderid}";

    return $self->_get_resp($call);
}

sub deletelinklistentries {
    my $self = shift;
    croak "No options passed" unless @_;

    my %options = %{ _read_opts(@_) };
    my ( $folderid, $subfolderid, $fileids );
    $folderid = $options{folderid}
      or croak "Folder ID is required, but missing";
    $subfolderid = $options{subfolderid} if exists $options{subfolderid};
    croak "File IDs are required, but missing"
      unless exists $options{fileids};
    if ( ref $options{fileids} eq 'ARRAY' ) {
        $fileids = join( ',', @{ $options{fileids} } );
    }
    else { $fileids = $options{fileids}; }

    my $sub = "deletelinklistentries_v1";
    my $call = $self->_default_call($sub) or return;
    $call .= "&folderid=${folderid}";
    $call .= "&subfolderid=${subfolderid}" if $subfolderid;
    $call .= "&files=${fileids}";

    return $self->_get_resp($call);
}

sub editlinklistentry {
    my $self = shift;
    croak "No options passed" unless @_;

    my %options = %{ _read_opts(@_) };
    my ( $folderid, $subfolderid, $fileid, $desc, $pwd );
    $folderid = $options{folderid}
      or croak "Folder ID is required, but missing";
    $subfolderid = $options{subfolderid} if exists $options{subfolderid};
    $fileid = $options{fileid} or croak "File ID is required, but missing";
    $desc = $options{description} if exists $options{description};
    $pwd  = $options{password}    if exists $options{password};

    if ( ( length($fileid) <= 4 ) and $pwd ) {
        $self->{errstr} =
          "Cannot change the password for a file, only a sub-linklist";
        return;
    }

    my $sub = "editlinklistentry_v1";
    my $call = $self->_default_call($sub) or return;
    $call .= "&folderid=${folderid}";
    $call .= "&subfolderid=${subfolderid}" if $subfolderid;
    $call .= "&fileid=${fileid}";
    $call .= "&newdescription=${desc}" if $desc;
    $call .= "&newpassword=${pwd}" if $pwd;

    return $self->_get_resp($call);
}

sub getreward {
    my $self = shift;

    my $sub      = "getreward_v1";
    my $call     = $self->_default_call($sub) or return;
    my $response = $self->_get_resp($call) or return;
    my @rows     = split( /\n/, $response, 2 );
    return split( /,/, $rows[0] ), $rows[1];
}

sub setreward {
    my $self = shift;
    my ( $rewardid, $data ) = @_;

    croak "Reward ID missing"   unless $rewardid;
    croak "Reward data missing" unless $data;

    my $sub = "setreward_v1";
    my $call = $self->_default_call($sub) or return;
    $call .= "&reward=$rewardid";
    $call .= "&parameters=$data";

    return $self->_get_resp($call);
}

### Internal Utilities
sub _get_resp {
    my $self = shift;
    my $call = shift;

    my $ua = LWP::UserAgent->new;
    $ua->agent("Net::Rapidshare/$VERSION");
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
    if ( $self->{cookie} ) {
        $self->type("prem");
        $self->login("login");
        $self->password("password");
        return 1;
    }
    return 1 if ( $self->{type} and $self->{login} and $self->{password} );
    $self->{errstr} = "Not initialized with type/login/password or cookie";
    return;
}

sub _read_opts {
    my %options;
    if ( ref @_ eq 'HASH' ) { %options = %{@_}; }
    else {
        croak "Incorect number of options passed. Must be even"
          if ( scalar @_ % 2 );
        (%options) = @_;
    }
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
__END__

=pod

=head1 NAME

Net::Rapidshare - Perl interface to the Rapidshare API

=head1 VERSION

This document describes Net::Rapidshare version 0.05

=head1 SYNOPSIS

	use Net::Rapidshare;

	## Initialize with account info
	my $rs = Net::Rapidshare->new(
		type => 'prem',
		login => 'mylogin',
		password => 'mypassword'
	);

	## Initialize and then add account info
	my $rs = Net::Rapidshare->new();
	$rs->type('col');
	$rs->login('mylogin');
	$rs->password('mypassword');

	## Initialize with a cookie
	my $rs = Net::Rapidshare->new(
		cookie => 'ASJHDGSASJDHAKSD6543.....',
	);
	# OR
	my $rs = Net::Rapidshare->new();
	$rs->cookie('JHASGDASAAKSJHD65465.....');

=head1 DESCRIPTION

This module provides a Perl interface to the Rapidshare API. You can view the
full API Documentation at L<http://images.rapidshare.com/apidoc.txt>.

B<Note:> Always make sure you do not make more API calls than necessary.
Rapidshare servers use a IP-based credit system, which will ban a IP making
very many small requests or just a few unnecessary big requests. Everything you
do will add POINTS to your IP address. If you exceed a certain point limit, API
calls are denied for 30 minutes. If you exceed this limit multiple times, your
account is banned as well.

B<Note:> v0.05 includes changes to various methods to reflect Rapidshares API
updates. The changes can potentially break existing code. Please read the
'Changes' file for more details.

=head1 METHODS

=over

=item new

=item new(\%options)

Construct a new Net::Rapidshare object

	my $rs = my $rs = Net::Rapidshare->new();
	my $rs = my $rs = Net::Rapidshare->new(\%options);

Options allowed:

L</"type"> - Account Type

L</"login"> - Account Login

L</"password"> - Account Password

L</"cookie"> - Rapidshare Cookie string

=item type

=item type($type)

Get or set the type of account. Use I<col> for Collector and I<prem> for
Premium accounts. Free accounts are not supported.

=item login

=item login($user)

Get or set account login

=item password

=item password($mypwd)

Get or set account password

=item cookie

=item cookie($cookie_string)

Get or set authentication cookie. Setting a cookie causes it to override
account type/login/password.

=item unsecure

Use I<http> instead of I<https> for all API calls. This is the default

	$rs->unsecure;

=item secure

Use I<https> instead of I<http> for all API calls. Using this will B<double>
your points for all API calls.

	$rs->secure

=item proxy

=item proxy($proxy_server)

Get or set a proxy server

=back

=head1 API METHODS

=head2 Account

=over

=item getapicpu

Returns the current and maximum allowed Rapidshare API CPU usage. Your account
maybe banned if you go over. It is a good idea to check it before/after
intensive operations.

	my ($curr, $max) = $rs->getapicpu or die $rs->errstr;

=item getaccountdetails

=item getaccountdetails(\%options)

Returns a hash (or reference) containing your account details.

	my %account = $rs->getaccountdetails(
		withrefstring => 1,
		withcookie => 1,
	) or die $rs->errstr;

Options:

I<withrefstring> Returned hash includes a key 'refstring' with your referrer
string as its value

I<withcookie> Returned hash includes a key 'cookie' with your Rapidshare cookie
as its value

Returned Hash contains following keys -

Premium Account: accountid, type, servertime, addtime, validuntil, username,
directstart, protectfiles, rsantihack, plustrafficmode, mirrors, jsconfig,
email, lots, fpoints, ppoints, curfiles, curspace, bodkb, premkbleft,
ppointrate, refstring, cookie

Collectors Account: accountid, type, servertime, addtime, username, email,
jsconfig, rsantihack, lots, fpoints, ppoints, curfiles, curspace, ppointrate,
refstring, cookie

=item setaccountdetails(\%options)

Update your Rapidshare account information.

	$rs->setaccountdetails(
	    email => 'john@smith.com',
	    newpassword =>
	        'secret',    # you might want to use secure if setting password
	    directstart => 1,
	    mirror      => 'l3',
	) or die $rs->errstr;

=over

=item email

Required. Your email ID

=item newpassword

Optional. New account password

=item username

Optional. New username/alias

=item mirror

Optional. Choose what mirrors you want to use. Comma seperated list

=item directstart

Optional. Direct downloads, requested files are saved without redirection via
RapidShare. '0' to disable, '1' to enable. Skipping disables it.

=item jsconfig

Optional. A custom value, which can be set as you like. Max. 64 alphanumeric
characters.

=item plustrafficmode

Optional. Modes valid are 0=No auto conversion. 1=Only TrafficShare conversion.
2=Only RapidPoints conversion. 3=Both conversions available.

=back

=item enablersantihack

Enabled the RS AntiHack mode. This mode is highly recommended for every
account, as it makes account manipulations impossible without unlocking it
first.

	$rs->enablersantihack or die $rs->errstr;

=item sendrsantihackmail

Sends an email to the email ID on your account containing unlock code.

	$rs->sendrsantihackmail or die $rs->errstr;

=item disablersantihack($unlock_code)

Disables the RS AntiHack mode, allowing account changes

	$rs->disablersantihack('unlock code') or die $rs->errstr;

=item buylots

Exchanges RapidPoints to lots. You will get one lot for 50 RapidPoints. You
cannot own more than 50.000 lots.

Return total number of lots after buying.

	my $num_of_lots = $rs->buylots('how many') or die $rs->errstr;

=item masspoll($pollid, $vote)

Cast your vote in a (running) mass poll.

	$rs->masspoll(
	    '34534535342',    # Poll ID
	    '10'             # Vote
	) or die $rs->errstr;

=back

=head2 Files

=over

=item nextuploadserver

Get the next upload server. Returns a full Rapidshare URL

	my $upload_server = $rs->nextuploadserver or die $rs->errstr;

=item checkincomplete($fileid, $killcode)

Check if a file has been uploaded successfully. Returns size on server

	my $size_on_server = $rs->checkincomplete(
	    '1234323423',          # File ID
	    '25298475092437502'    # Kill Code
	) or die $rs->errstr;

=item listfiles(\%options)

List all the files in your account. This is API Points intensive. Use
sparingly.

	my @rows = $rs->listfiles(
	    fields => "killcode,name,size",
	    order  => 'size'
	) or die $rs->errstr;
	foreach (@rows) {
	    my ( $fileid, $killcode, $name, $size ) = split( /,/, $_ );
	    print "Found $name ($size) with ID $fileid and KillCode $killcode\n";
	}

Returns 'NONE' or an array (or reference) of results. Each element will contain
a comma separated list of file ID and requested fields

=over

=item realfolder

Realfolder ID to list files from. Defaults to all

=item filename

List all files who's file names are that specified. Helps in finding dupes

=item fileids

A comma seperated list of I<fileids> to list

=item fields

Fields to include in the result list. I<fileid> is always included. This should
be a comma separated string.

You can use any of the following =>
downloads,lastdownload,filename,size,killcode,serverid,type,x,y,realfolder,
bodtype,killdeadline,uploadtime,ip,md5hex.

=item order

Order your results by any of the fields queried

=item desc

Result is in descending order when '1'. Defaults to '0'

=back

=item renamefile($fileid, $killcode, $newname)

Rename a file

	$rs->renamefile(
	    '23424342',            # file ID
	    'newname'              # New name
	) or die $rs->errtsr;

=item deletefiles($file1,$file2,...)

=item delefiles(\@files)

Delete files

	$rs->deletefiles(
	    "476535874,34959483,94354533"    # File IDs, can also use an ARRAY REF
	) or die $rs->errstr;

=item movefilestorealfolder($folderid, $file1, $file2, ....)

=item movefilestorealfolder($folderid, \@files)

Move files to a specified folder

	$rs->movefilestorealfolder(
	    "876453453",                     # Target Folder ID
	    "476535874,34959483,94354533"    # File IDs, can also use an ARRAY REF
	) or die $rs->errstr;

=item filemigrator(\%options)

Transfer files between accounts

	my $response = $rs->filemigrator(
	    fromtype     => 'col',           # Source accnt type
	    fromlogin    => 'collector',     # Source accnt login
	    frompassword => 'password',      # Source accnt password

	    totype     => 'prem',            # Target account type
	    tologin    => 'premium',         # Target account login
	    topassword => 'passwd',          # Target account password

	    fileids => [ '32524354', '423452345' ],    # File IDs.
	) or die $rs->errstr;
	my ($number_of_files_moved,     $files_in_src_accnt_before,
	    $space_in_src_accnt_before, $files_in_tgt_accnt_before,
	    $space_in_tgt_accnt_before, $files_in_src_accnt_after,
	    $space_in_src_accnt_after,  $files_in_tgt_accnt_after,
	    $space_in_tgt_accnt_after,
	) = split( /,/, $response );

Returns a comma separated string with -

	1:Number of moved files
	2:Files in source account before action
	3:Space in source account before action
	4:Files in target account before action
	5:Space in target account before action
	6:Files in source account after action
	7:Space in source account after action
	8:Files in target account after action
	9:Space in target account after action

Moving a linked list returns only #1 above.

Options:

=over

=item fromtype

Source account type. free/col/prem

=item fromlogin, frompassword

Source account credentials. Not required if fromtype is free.

=item totype

Target account type. prem/col

=item tologin,topassword

Target account credentials

=item fileids

Array REF of file ids to move or '*' for all. Linked list ID if moving linked
lists

=item linkedlists

set to '1' if moving a linked list

=item acceptfee

Set to '1' indicating that you have accepted the fee of 300 points which will
be deducted from the target account. This call will fail unless accepted.

=back

=item trafficsharetype($tstype, \@fileids)

Set the Traffic Share type (0=off 1=on 2=on with encryption 101=on with logging
102=on with logging and encryption)

	$rs->trafficsharetype(
	    '101',                                     # On with logging
	    [ '87346543', '945934534' ]                # File IDs
	) or die $rs->errstr;

=item checkfiles(\@fileids, \@filenames)

=item checkfiles(\@fileids, \@filenames, $md5)

Check if file exists on server and is downloadable. Returns a data structure
containing each file's information. Also includes file MD5sums if $md5 is true.

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

	    next if ($status eq '0' or $status eq '4');

	    my $file_to_load =
	        "http://rs${server}${mirror}.rapidshare.com/${id}/${name}";
	}

The Status value can be -

	0=File not found
	1=File OK (Downloading possible without any logging)
	2=File OK (TrafficShare direct download without any logging)
	3=Server down
	4=File marked as illegal
	5=Anonymous file locked, because it has more than 10 downloads already
	6=File OK (TrafficShare direct download with enabled logging. Read our privacy policy to see what is logged.)

=back

=head2 Folders

=over

=item addrealfolder($name)

=item addrealfolder($name, $parent)

Add a new Folder

	$rs->addrealfolder(
	    'newfolder',    # Folder Name
	    '1'             # Parent ID, defaults to 0
	) or die $rs->errstr;

=item moverealfolder($folderid, $parent)

Move a folder.

	$rs->moverealfolder(
	    '657634345',    # Folder ID
	    '2',            # New Parent, defaults to 0
	) or die $rs->errstr;

=item renamerealfolder($folderid, $newname)

Rename a Folder

	$rs->renamerealfolder(
	    '87365345',     # Folder ID
	    'new name'      # New folder name
	) or die $rs->errstr;

=item delrealfolder($folderid)

Delete a folder

	$rs->delrealfolder(
	    '87652'         # Folder ID
	) or die $rs->errstr;

=back

=head2 Logs

=over

=item trafficsharelogs($fileid)

Get the traffic share logs for a file

	my ( $start_time, $stop_time, $size, $starting_position, $bytes_downloaded,
	    $range, $custom )
	    = $rs->trafficsharelogs('fileid')
	    or die $rs->errstr;

=item trafficsharebandwidth($start_time, $end_time)

Get the traffic share logs for you account

	my (@rows) = $rs->trafficsharebandwidth( 'start_time', 'end_time' )
	    or die $rs->errstr;
	foreach (@rows) { my ( $timestamp, $kbps ) = split( /,/, $_ ); }

=item getpointlogs

Gets details about your earned RapidPoints

	my @rows = $rs->getpointlogs or die $rs->errstr;
	foreach (@rows) {
	    my ( $date, $free_points, $prem_points ) = split( /,/, $_ );
	}

=item getreferrerlogs

Gets details about your earned Referrer Points

	my @rows = $rs->getreferrerlogs or die $rs->errstr;
	foreach (@rows) { my ( $timestamp, $refpoints, $fileid, $confirmed ) = split( /,/, $_ ); }

=back

=head2 Link Lists

=over

=item newlinklist(\%options)

Create a new Link List. Returns the link list ID

	my $new_ll_id = $rs->newlinklist(
	    name     => 'newlist',             # Name
	    headline => 'my new link list',    # Headline
	    nickname => 'll1',                 # Nickname
	    password => 'secret',              # Password
	) or die $rs->errstr;

=item newlinklistsubfolder(\%options)

Create a sub link list (sub folder). Returns the sub folder ID

	my $new_sub_id = $rs->newlinklistsubfolder(
	    folderid    => 'MJHG67',           # Parent link list ID
	    name        => 'newsublist',       # Name
	    description => 'new links',        # Description
	    password    => 'secret',           # Password
	) or die $rs->errstr;

=item copyfilestolinklist(\%options)

Add files to a link list

	$rs->copyfilestolinklist(
	    folderid => 'MJHG67',                       # Parent link list ID
	    fileids => [ '73876221', '7876523523' ],    # File IDs
	) or die $rs->errstr;

=item editlinklist(\%options)

Edit a link list

	$rs->editlinklist(
	    folderid => 'HDKS778',                      # Link list ID
	    name     => 'newlist',                      # Name
	    headline => 'my new link list',             # Headline
	    nickname => 'll1',                          # Nickname
	    password => 'secret',                       # Password
	) or die $rs->errstr;

=item editlinklistentry(\%options)

Edit either a file or a sub folder in a link list

	## Edit a file entry
	$rs->editlinklistentry(
	    folderid    => 'HFGSK87',                   # Link list ID
	    fileid      => '876872345',                 # File ID
	    description => 'hey, get this file',        # Description
	) or die $rs->errstr;

Options -

I<folderid> : The Link list ID that contains the entries

I<fileid> : This can either be a file ID or a sub folder ID

I<description> : Optional. Description will be applied to the C<fileid>

I<password> : Optional. Secure a sub folder with the password. This option is
invalid when C<fileid> is a file and not a sub folder

=item getlinklist

=item getlinklist(\%options)

Get a listing of all of your link lists and (optionally) all link list entries.
Returns a Data structure with each entry's details

	my $lists = $rs->getlinklist or die $rs->errstr;
	my @ids = keys %{$lists};
	foreach my $id (@ids) {
	    my $name     = $list->{$id}->{name};
	    my $headline = $list->{$id}->{headline};
	}

Options -

I<folderid> : When provided with a folder ID, the returned list will contain
the following details all entries in that link list.

	'subfolderid'   The sub folder ID. '0' means root
	'fileid'        File ID or Sub folder ID
	'name'          Name
	'size'          Size
	'description'   Description
	'addtime'       Time entry was added (UNIX)

I<showsubs> : When set to true, the returned data structure will return all of
the link lists as well as all entries within those lists. This cannot be used
with C<folderid>. The following details are returned for each link list

	'subfolderid'   The sub folder ID. '0' means root
	'name'          File or Sub folder Name
	'headline'      Headline
	'views'         Number of views
	'lastview'      Last viewed time (UNIX)
	'password'      Password
	'nickname'      Nickname

=item deletelinklistentries(\%options)

Delete file or sub folder entries

	$rs->deletelinklistentries(
	    folderid => 'HHSKL76',                      # Link list ID
	    fileids => [ '73876221', '7876523523' ],    # File IDs to delete
	) or die $rs->errstr;

C<fileids> can be sub folder IDs as well.

=item deletelinklist($linklistid)

Delete a link list

	$rs->deletelinklist('JHSDS7') or die $rs->errstr;

=back

=head2 Rewards

=over

=item getreward

Get details of your active reward. Only one reward can be active at a time on
your account.

	my (
	$reward_id,		# Reward ID
	$time,			# Unix timestamp when ordered
	$email,			# Email used at time of ordering
	$active_ppr,	# Active PPointRate
	$data			# Data needed to deliver reward. Used by setreward
	) = $rs->getreward() or die $rs->errstr;

=item setreward($reward_id, $reward_data)

Saves details about your ordered RapidShare reward

	$rs->setreward($reward_id, $reward_data) or die $rs->errstr;

=back

=head1 ERROR HANDLING

All methods return 'undef' and set $obj->errstr on errors. The $obj->errstr
will also contain any errors reported by Rapidshare.

=head1 DEPENDENCIES

L<LWP::UserAgent>

L<HTML::Entities>

=head1 SUPPORT

Please report any bugs or feature requests at
L<http://github.com/mithun/perl-net-rapidshare/issues>

=head1 AUTHOR

Mithun Ayachit  C<< <mithun at cpan dot org> >>

=head1 LICENCE AND COPYRIGHT

Copyright (c) 2009, Mithun Ayachit C<< <mithun at cpan dot org> >>. All rights
reserved.

This module is free software; you can redistribute it and/or modify it under
the same terms as Perl itself.

=head1 DISCLAIMER OF WARRANTY

BECAUSE THIS SOFTWARE IS LICENSED FREE OF CHARGE, THERE IS NO WARRANTY FOR THE
SOFTWARE, TO THE EXTENT PERMITTED BY APPLICABLE LAW. EXCEPT WHEN OTHERWISE
STATED IN WRITING THE COPYRIGHT HOLDERS AND/OR OTHER PARTIES PROVIDE THE
SOFTWARE "AS IS" WITHOUT WARRANTY OF ANY KIND, EITHER EXPRESSED OR IMPLIED,
INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND
FITNESS FOR A PARTICULAR PURPOSE. THE ENTIRE RISK AS TO THE QUALITY AND
PERFORMANCE OF THE SOFTWARE IS WITH YOU. SHOULD THE SOFTWARE PROVE DEFECTIVE,
YOU ASSUME THE COST OF ALL NECESSARY SERVICING, REPAIR, OR CORRECTION.

IN NO EVENT UNLESS REQUIRED BY APPLICABLE LAW OR AGREED TO IN WRITING WILL ANY
COPYRIGHT HOLDER, OR ANY OTHER PARTY WHO MAY MODIFY AND/OR REDISTRIBUTE THE
SOFTWARE AS PERMITTED BY THE ABOVE LICENCE, BE LIABLE TO YOU FOR DAMAGES,
INCLUDING ANY GENERAL, SPECIAL, INCIDENTAL, OR CONSEQUENTIAL DAMAGES ARISING
OUT OF THE USE OR INABILITY TO USE THE SOFTWARE (INCLUDING BUT NOT LIMITED TO
LOSS OF DATA OR DATA BEING RENDERED INACCURATE OR LOSSES SUSTAINED BY YOU OR
THIRD PARTIES OR A FAILURE OF THE SOFTWARE TO OPERATE WITH ANY OTHER SOFTWARE),
EVEN IF SUCH HOLDER OR OTHER PARTY HAS BEEN ADVISED OF THE POSSIBILITY OF SUCH
DAMAGES.
