use strict;
use warnings;
use Win32::OLE;

my($ServerNumber, $Name, $Path, $Browse, $Read, $Write, $Execute,
   $Script, $AuthAnon, $AuthNTLM, $NoDelete) = @ARGV;

$Browse   = 0 unless defined $Browse;
$Read     = 1 unless defined $Read;
$Write    = 0 unless defined $Write;
$Execute  = 1 unless defined $Execute;
$Script   = 0 unless defined $Script;
# if unspecified, enable anonymous access (this is the IIS default)
$AuthAnon = 1 unless defined $AuthAnon;
# if unspecified, enable NTLM access (this is the IIS default)
$AuthNTLM = 1 unless defined $AuthNTLM;

my $ADsPath = "IIS://localhost/W3SVC/$ServerNumber/ROOT";
my $website = Win32::OLE->GetObject($ADsPath) or exit;
$website->Delete('IISWebVirtualDir', $Name) unless $NoDelete;
my $virdir = $website->Create('IISWebVirtualDir', $Name) or exit;

$virdir->{Path}                  = $Path;
$virdir->{AppFriendlyName}       = $Name;

$virdir->{EnableDirBrowsing}     = $Browse;
$virdir->{AccessRead}            = $Read;
$virdir->{AccessWrite}           = $Write;
$virdir->{AccessExecute}         = $Execute;
$virdir->{AccessScript}          = $Script;

$virdir->{AccessNoRemoteRead}    = 0;
$virdir->{AccessNoRemoteScript}  = 0;
$virdir->{AccessNoRemoteWrite}   = 0;
$virdir->{AccessNoRemoteExecute} = 0;

$virdir->{AuthAnonymous}         = $AuthAnon;
$virdir->{AuthNTLM}              = $AuthNTLM;

$virdir->AppCreate(1);
$virdir->SetInfo();
