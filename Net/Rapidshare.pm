package Net::Rapidshare;

use strict;
use warnings;
use Carp;
use LWP::UserAgent;

use version; our $VERSION = qv("0.01");

### Interface
sub new{
	my $class = shift;
	my %h = ();
	if(@_){
		my %valid = ("type" => 1, "login" => 1, "password"=> 1);
		(%h) = @_;
		foreach (keys %h){croak "Invalid Option : $_" unless $valid{$_};}
		croak "Invalid Type $h{type}" unless _valid_type($h{type});
	}
	$h{"_url"} = "http://api.rapidshare.com/cgi-bin/rsapi.cgi?";
	return bless {%h}, $class;
}

sub type{
	my $self = shift;
	my $type = shift;
	if($type){croak "Invalid Type $type" unless _valid_type($type); $self->{type} = $type;}
	return $self->{type};
}

sub login{
	my $self = shift;
	my $login = shift;
	if($login){$self->{login} = $login;}
	return $self->{login};
}

sub password{
	my $self = shift;
	my $password = shift;
	if($password){$self->{password} = $password;}
	return $self->{password};
}

sub secure{
	my $self = shift;
	$self->{_url} = "https://api.rapidshare.com/cgi-bin/rsapi.cgi?";
	return 1;
}

sub proxy{
	my $self = shift;
	my $proxy = shift;
	if($proxy){croak "Invalid Proxy : $proxy" unless ($proxy =~ /^http/); $self->{proxy} = $proxy;}
	return $self->{proxy};
}

sub errstr{
	my $self = shift;
	return $self->{errstr};
}

sub cookie{
	my $self = shift;
	my $cookie = shift;
	if ($cookie){$self->{cookie} = $cookie;}
	return $self->{cookie};
}

### API Calls
sub nextuploadserver{
	my $self = shift;
	my $sub  = "nextuploadserver_v1";
	my $call = $self->{_url}."sub=${sub}";
	my $node =  $self->_get_resp($call) or return;
	return "http://rs${node}.rapidshare.com";
}

sub getapicpu{
	my $self = shift;
	my $sub = "getapicpu_v1";
	my $call = $self->{_url}."sub=${sub}";
	my $response = return $self->_get_resp($call) or return;
	my @curr_max = split(/,/, $response);
	return @curr_max;
}

sub checkincomplete{
	my $self = shift;
	my $fileid = shift or croak "fileid is required";
	my $killcode = shift or croak "killcode is required";
	
	my $sub = "checkincomplete_v1";
	my $call = $self->{_url}."sub=${sub}";
	$call .= "&fileid=${fileid}";
	$call .= "&killcode=${killcode}";
	
	return $self->_get_resp($call);
}

sub renamefile{
	my $self = shift;
	my $fileid = shift or croak "fileid is required";
	my $killcode = shift or croak "killcode is required";
	my $newname = shift or croak "new name is required";
	
	my $sub = "renamefile_v1";
	my $call = $self->_default_url($sub) or return;
	$call .= "&fileid=${fileid}";
	$call .= "&killcode=${killcode}";
	$call .= "&newname=${newname}";
	
	return $self->_get_resp($call);
}

sub movefilestorealfolder {
	my $self = shift;
	my $realfolderid = shift or croak "realfolderid is required";
	croak "fileids are required" unless @_;
	
	my $fileids;
	my @fileids_arr;
	if (ref @_ eq 'ARRAY'){
		@fileids_arr = @{@_};
		$fileids = join(',', @fileids_arr);
	}
	else{
		$fileids = join(',',@_);
	}
	if (length($fileids) > 10000){
		$self->{errstr} = "Length of fileids is more than 10,000 bytes";
		return;
	}
	
	my $sub = "movefilestorealfolder_v1";
	my $call = $self->_default_call($sub) or return;
	$call .= "&files=${fileids}";
	$call .= "&realfolder=${realfolderid}";
	
	return $self->_get_resp($call);
}

sub renamerealfolder{
	my $self = shift;
	my $realfolderid = shift or croak "realfolderid is required";
	my $newname = shift or croak "newname is required";
	
	if (length($newname) > 100){
		$self->{errstr} = "Length of newname is more than 100 Chars";
		return;
	}
	
	my $sub = "renamerealfolder_v1";
	my $call = $self->_default_call($sub) or return;
	$call .= "realfolder=${realfolderid}";
	$call .= "&newname=${newname}";
	
	return $self->_get_resp($call);
}

sub deletefiles {
	my $self = shift;
	croak "fileids are required" unless @_;
	
	my $fileids;
	my @fileids_arr;
	if (ref @_ eq 'ARRAY'){
		@fileids_arr = @{@_};
		$fileids = join(',', @fileids_arr);
	}
	else{
		$fileids = join(',',@_);
	}
	if (length($fileids) > 10000){
		$self->{errstr} = "Length of fileids is more than 10,000 bytes";
		return;
	}
	
	my $sub = "deletefiles_v1";
	my $call = $self->_default_call($sub) or return;
	$call .= "&files=${fileids}";
	
	return $self->_get_resp($call);
}

sub addrealfolder{
	my $self = shift;
	my $name = shift;
	my $parent = shift or 0;
	
	if (length($name) > 100){
		$self->{errstr} = "Length of name is greater than 100 bytes";
		return;
	}
	
	my $sub  = "addrealfolder_v1";
	my $call = $self->_default_call($sub) or return;
	$call .= "&name=${name}";
	$call .= "&parent=${parent}";
	
	return $self->_get_resp($call);
}

sub delrealfolder{
	my $self = shift;
	my $realfolder = shift;
	
	my $sub = "delrealfolder_v1";
	my $call = $self->_default_call($sub) or return;
	$call .= "&realfolder=${realfolder}";
	
	return $self->_get_resp($call);
}

sub moverealfolder{
	my $self = shift;
	my $realfolder = shift;
	my $newparent = shift;
	
	my $sub = "moverealfolder_v1";
	my $call = $self->_default_call($sub) or return;
	$call .= "&realfolder=${realfolder}";
	$call .= "&newparent=${newparent}";
	
	return $self->_get_resp($call);
}

sub listfiles{
	my $self = shift;
	
	my %options;%options = %{_read_opts(@_)} if @_;
	my ($realfolder,$filename,$fields,$order,$desc, $returnds) = '0';
	$realfolder = $options{'realfolder'} if exists $options{'realfolder'};
	$filename = $options{'filename'} if exists $options{'filename'};
	$fields = $options{'fields'} if exists $options{'fields'};
	$order = $options{'order'} if exists $options{'order'};
	$desc = $options{'desc'} if exists $options{'desc'};
	$returnds = $options{'returnds'} if exists $options{'returnds'};
	
	my $sub = "listfiles_v1";
	my $call = $self->_default_call($sub) or return;
	$call .= "&realfolder=${realfolder}";
	$call .= "&filename=${filename}" if $filename;
	$call .= "&fields=${fields}" if $fields;
	$call .= "&order=${order}" if $order;
	$call .= "&desc=${desc}" if exists $options{'desc'};
	
	return $self->_get_resp($call) unless $returnds;
	
	my $response = $self->_get_resp($call) or return;
	return $response if (uc($response) eq 'NONE');
	my @lines = split(/\n/, $response);
	my $list;
	if ($fields){
		my @req = split(/,/, $fields);
		foreach my $line (@lines){
			my ($index, $id, @resp) = split(/,/, $line);
			my $len = @req; my $i = 0;
			while($i < $len){$list->{"$index"}->{"$req[$i]"} = $resp[$i]; $i++;}
			$list->{"$index"}->{"fileid"}=$id;
		}
	}
	else{
		foreach my $line (@lines){my ($index,$id) = split(/,/, $line); $list->{"$index"}->{"fileid"}=$id;}
	}
	return $list;
}

sub listrealfolders{
	my $self = shift;

	my %options; %options = %{_read_opts(@_)} if @_;
	my $returnds; $returnds = $options{'returnds'} if exists $options{'returnds'};
	
	my $sub = "listrealfolders_v1";
	my $call = $self->_default_call($sub) or return;
	return $self->_get_resp($call) unless $returnds;
	
	my $response = $self->_get_resp($call) or return;
	return $response if (uc($response) eq 'NONE');
	my @lines = split(/\n/, $response);
	my $folders;
	foreach my $line (@lines){
		my ($id,$parent,$name) = split(/,/, $line);
		$folders->{"$id"}->{"parent"} = $parent;
		$folders->{"$id"}->{"name"} = $name;
	}
	return $folders;
}

sub getaccountdetails{
	my $self = shift;
	
	my %options; %options = %{_read_opts(@_)} if @_;
	my ($withrefstring, $withcookie, $returnds) = '0';
	$withrefstring = $options{'withrefstring'} if exists $options{'withrefstring'};
	$withcookie = $options{'withcookie'} if exists $options{'withrefstring'};
	$returnds = $options{'returnds'} if exists $options{'returnds'};
	
	my $sub = "getaccountdetails_v1";
	my $call = $self->_default_call($sub) or return;
	$call .= "&withrefstring=1" if $withrefstring;
	$call .= "&withcookie=1" if $withcookie;
	return $self->_get_resp($call) unless $returnds;
	
	my $response = $self->_get_resp($call) or return;
	my @lines = split(/\n/, $response);
	my $accnt;
	foreach my $line (@lines){
		my ($key,$value) = split(/=/, $line);
		$accnt->{"$key"} = $value;
	}
	return $accnt;
}

sub setaccountdetails{
	my $self = shift;
	
	my %options; %options = %{_read_opts(@_)} if @_;
	my ($newpassword,$email,$username,$mirror, $mirror2, $mirror3, $directstart, $jsconfig, $plustrafficmode) = 0;
	croak "email not provided" unless exists $options{'email'};
	$email = $options{'email'};
	$newpassword = $options{'newpassword'} if exists $options{'newpassword'};
	$username = $options{'username'} if exists $options{'username'};
	$mirror = $options{'mirror'} if exists $options{'mirror'};
	$mirror2 = $options{'mirror2'} if exists $options{'mirror2'};
	$mirror3 = $options{'mirror3'} if exists $options{'mirror3'};
	$directstart = $options{'directstart'} if exists $options{'directstart'};
	$jsconfig = $options{'jsconfig'} if exists $options{'jsconfig'};
	$plustrafficmode = $options{'plustrafficmode'} if exists $options{'plustrafficmode'};	
	
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
	$call .= "&plustrafficmode=${plustrafficmode}" if exists $options{'plustrafficmode'};
	
	return $self->_get_resp($call);
}

sub enablersantihack{
	my $self = shift;
	
	my $sub = "enablersantihack_v1";
	my $call = $self->_default_call($sub) or return;
	return $self->_get_resp($call);
}

sub disablersantihack{
	my $self = shift;
	
	my %options; %options=%{_read_opts(@_)} if @_;
	my $unlockcode = $options{'unlockcode'} or croak "Unlock code not provided";
	
	my $sub = "disablersantihack_v1";
	my $call = $self->_default_call($sub) or return;
	$call .= "&unlockcode=${unlockcode}";
	
	return $self->_get_resp($call);
}

### Internal Utilities
sub _get_resp{
	my $self = shift;
	my $call = shift;
	
	my $ua = LWP::UserAgent->new;
	$ua->agent("Rapidshare::API");
	$ua->proxy('http', $self->{proxy}) if $self->{proxy};
	
	my $response = $ua->get($call);
	unless ($response->is_success){	$self->{errstr} = $response->status_line;return;}
	my $resp_str = ${$response->content_ref};
	return $resp_str if $self->_response_is_good($resp_str);
	return;
}

sub _response_is_good{
	my $self = shift;
	my $str = shift;
	if ($str =~ /^ERROR/){$self->{errstr} = $str;return;}
	return 1;
}

sub _valid_type{
	my $type = shift or return;
	my %valid = ("col" => 1, "prem"=>1);
	return $valid{$type} if $valid{$type};
	return;
}

sub _is_init{
	my $self = shift;
	return 1 if ($self->{type} and $self->{login} and $self->{password});
	$self->{errstr} = "Not initialized with type/login/password";
	return;
}

sub _read_opts{
	my %options;
	if(ref @_ eq 'HASH'){%options = %{@_};}else{(%options) = @_;}
	return \%options;
}

sub _default_call{
	my $self = shift;
	my $sub = shift;
	
	return unless $self->_is_init;
	my $call = $self->{_url};
	$call .= "sub=${sub}";
	$call .= "&type=".$self->{type};
	$call .= "&login=".$self->{login};
	$call .= "&password=".$self->{password};
	$call .= "&cookie=".$self->{cookie} if $self->{cookie};
	
	return $call;
}

1;