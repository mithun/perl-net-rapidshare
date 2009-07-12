package Net::Rapidshare;

use strict;
use warnings;
use diagnostics;
use LWP::UserAgent;
use Carp;

use version; our $VERSION = qv("0.1");

### Interface
sub new{
	my $class = shift;
	if(@_){
		my %valid = ("type" => 1, "login" => 1, "password"=> 1);
		my (%h) = @_;
		foreach (keys %h){croak "Invalid Option : $_" unless $valid{$_};}
		croak "Invalid Type $h{type}" unless _valid_type($h{type});
		return bless {%h, "_url" => "http://api.rapidshare.com/cgi-bin/rsapi.cgi?"}, $class;
	}
	return bless {"_url" => "http://api.rapidshare.com/cgi-bin/rsapi.cgi?"}, $class;
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
	return $self->_get_resp($call);
}

sub checkincomplete{
	my $self = shift;
	my $fileid = shift;
	my $killcode = shift;
	
	my $sub = "checkincomplete_v1";
	my $call = $self->{_url}."sub=${sub}&fileid=${fileid}&killcode=${killcode}";
	return $self->_get_resp($call);
}

sub renamefile{
	my $self = shift;
	my $fileid = shift;
	my $killcode = shift;
	
	my $sub = "renamefile_v1";
	my $call = $self->{_url}."sub=${sub}&fileid=${fileid}&killcode=${killcode}";
	return $self->_get_resp($call);
}

sub movefilestorealfolder {
	my $self = shift;
	my $realfolderid = shift;
	
	return unless $self->_is_init;
	my $fileids;
	my @fileids_arr;
	if (ref{@_} eq 'ARRAY'){
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
	my $call = $self->{_url}."sub=${sub}&type=".$self->{type}."&login=".$self->{login}."&password=".$self->{password}."&files=${fileids}&realfolder=${realfolderid}";
	return $self->_get_resp($call);
}

sub renamerealfolder{
	my $self = shift;
	my $realfolderid = shift;
	my $newname = shift;
	
	return unless $self->_is_init;
	if (length($newname) > 100){
		$self->{errstr} = "Length of newname is more than 100 Chars";
		return;
	}
	
	my $sub = "renamerealfolder_v1";
	my $call = $self->{_url}."sub=${sub}&type=".$self->{type}."&login=".$self->{login}."&password=".$self->{password}."realfolder=${realfolderid}&newname=${newname}";
	return $self->_get_resp($call);
}

sub deletefiles {
	my $self = shift;
	
	my $fileids;
	my @fileids_arr;
	if (ref{@_} eq 'ARRAY'){
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
	
	return unless $self->_is_init;
	
	my $sub = "deletefiles_v1";
	my $call = $self->{_url}."sub=${sub}&type=".$self->{type}."&login=".$self->{login}."&password=".$self->{password}."&files=${fileids}";
	return $self->_get_resp($call);
}

sub addrealfolder{
	my $self = shift;
	my $name = shift;
	my $parent = shift or 0;
	
	return unless $self->_is_init;
	if (length($name) > 100){
		$self->{errstr} = "Length of name is greater than 100 bytes";
		return;
	}
	
	my $sub  = "addrealfolder_v1";
	my $call = $self->{_url}."sub=${sub}&type=".$self->{type}."&login=".$self->{login}."&password=".$self->{password}."&name=${name}&parent=${parent}";
	return $self->_get_resp($call);
}

sub delrealfolder{
	my $self = shift;
	my $realfolder = shift;
	
	return unless $self->_is_init;
	
	my $sub = "delrealfolder_v1";
	my $call = $self->{_url}."sub=${sub}&type=".$self->{type}."&login=".$self->{login}."&password=".$self->{password}."&realfolder=${realfolder}";
	return $self->_get_resp($call);
}

sub moverealfolder{
	my $self = shift;
	my $realfolder = shift;
	my $newparent = shift;
	
	return unless $self->_is_init;
	
	my $sub = "moverealfolder_v1";
	my $call = $self->{_url}."sub=${sub}&type=".$self->{type}."&login=".$self->{login}."&password=".$self->{password}."&realfolder=${realfolder}&newparent=${newparent}";
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
	
	return unless $self->_is_init;
	
	my $sub = "listfiles_v1";
	my $call = $self->{_url}."sub=${sub}&type=".$self->{type}."&login=".$self->{login}."&password=".$self->{password}."&realfolder=${realfolder}";
	$call .= "&filename=${filename}" if $filename;
	$call .= "&fields=${fields}" if $fields;
	$call .= "&order=${order}" if $order;
	$call .= "&desc=${desc}" if exists $options{'desc'};
	
	return $self->_get_resp($call) unless $returnds;
	
	my $response = $self->_get_resp($call) or return;
	return $response if (uc($response) eq 'NONE');
	my @lines = split(/\n/, $response);
	if ($fields){
		my $list;
		my @req = split(/,/, $fields);
		foreach my $line (@lines){
			my ($index, $id, @resp) = split(/,/, $line);
			my $len = @req; my $i = 0;
			while($i < $len){$list->{"$id"}->{"$req[$i]"} = $resp[$i]; $i++;}
			$list->{"$id"}->{"index"}=$index;
		}
		return $list;
	}
	my @fileids;
	foreach my $line (@lines){
		my (undef, $id) = split(/,/, $line);
		push(@fileids, $id);
	}
	return @fileids;
}

sub listrealfolders{
	my $self = shift;

	my %options; %options = %{_read_opts(@_)} if @_;
	my $returnds; $returnds = $options{'returnds'} if exists $options{'returnds'};
	
	return unless $self->_is_init;
	
	my $sub = "listrealfolders_v1";
	my $call = $self->{_url}."sub=${sub}&type=".$self->{type}."&login=".$self->{login}."&password=".$self->{password};
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
	
	return unless $self->_is_init;
	
	my $sub = "getaccountdetails_v1";
	my $call = $self->{_url}."sub=${sub}&type=".$self->{type}."&login=".$self->{login}."&password=".$self->{password};
	$call .= "&withrefstring=1" if $withrefstring;
	$call .= "&withcookie=1" if $withcookie;
	return $self->_get_resp($call) unless $returnds;
}

### Internal Utilities
sub _get_resp{
	my $self = shift;
	my $call = shift;
	
	my $ua = LWP::UserAgent->new;
	$ua->agent("Rapidshare::API");
	$ua->proxy('http', $self->{proxy}) if $self->{proxy};
	
	my $response = $ua->get($call);
	$self->{errstr} = $response->status_line and return unless $response->is_success;
	my $resp_str = ${$response->content_ref};
	return $resp_str if $self->_response_is_good($resp_str);
	return;
}

sub _response_is_good{
	my $self = shift;
	my $str = shift;
	$self->{errstr} = $str and return if ($str =~ m/^ERROR/g);
	return 1;
}

sub _valid_type{
	my $type = shift or return;
	my %valid = ("col" => 1, "perm"=>1);
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
	if(ref{@_} eq 'HASH'){%options = %{@_};}else{(%options) = @_;}
	return \%options;
}
1;