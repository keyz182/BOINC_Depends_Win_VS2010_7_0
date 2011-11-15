###############################################################################
#
# File:         IISScriptMap.pl
# Description:  Creates script mappings in the IIS metabase.
#
# Copyright (c) 2000-2007 ActiveState Software Inc.  All rights reserved.
#
###############################################################################
BEGIN {
    $tmp = $ENV{'TEMP'} || $ENV{'tmp'} ||
	($Config{'osname'} eq 'MSWin32' ? 'c:/temp' : '/tmp');
    open(STDERR, ">> $tmp/ActivePerlInstall.log");
}

use strict;
use Win32 ();
use Win32::OLE;

my $iis = Win32::GetFolderPath(Win32::CSIDL_SYSTEM)."\\inetsrv\\inetinfo.exe";
exit 0 unless -f $iis;

my($server_id,$virt_dir,$file_ext,$exec_path,$flags,$verbs) = @ARGV;
exit 0 unless $file_ext && $exec_path;

my @dirs = split /;/, $virt_dir, -1;
push @dirs, "" unless @dirs;

my $iis_version = int(Win32::GetFileVersion($iis));

unless (defined $flags) {
    # 1 The script is allowed to run in directories given Script
    #   permission. If this value is not set, then the script can only be
    #   executed in directories that are flagged for Execute permission.
    # 4 The server attempts to access the PATH_INFO portion of the URL, as a
    #   file, before starting the scripting engine. If the file can't be
    #   opened, or doesn't exist, an error is returned to the client.
    $flags = 5;
}
unless (defined $verbs) {
    # In IIS version 4.0 and earlier, the syntax was to list excluded verbs
    # rather than included verbs. In version 5.0, if no verbs are listed, a
    # value of "all verbs" is assumed.
    $verbs = $iis_version < 5 ? "PUT,DELETE" : "GET,HEAD,POST";
}

# Add script mappings
foreach my $id (split /;/, $server_id) {
    foreach my $dir (@dirs) {
	my $node = "IIS://localhost/W3SVC";
	# NOTE: A serverID of "0" is treated as the W3SVC root; any supplied
	# virtual directory for this case is ignored.
	$node .= "/$id/ROOT" if $id;
	$node .= "/$dir"     if $id and length($dir);

	my $server = Win32::OLE->GetObject($node) or next;
	my @list = grep { !/^\Q$file_ext,\E/ } @{$server->{ScriptMaps}};
	$server->{ScriptMaps} = [@list, "$file_ext,$exec_path,$flags,$verbs"];
	$server->SetInfo(); # save!
    }
}

# Check for Windows 2003 Server
exit 0 unless $iis_version >= 6;

# Add Web Server Extension entry
my %types = (".pl"   => "Perl CGI",
	     ".plx"  => "Perl ISAPI",
	     ".plex" => "PerlEx ISAPI");
my $type = $types{$file_ext} || "Perl $file_ext";

my $server = Win32::OLE->GetObject("IIS://localhost/W3SVC") or exit;
my @list = @{$server->{WebSvcExtRestrictionList}};
$server->{WebSvcExtRestrictionList} = [@list, "0,$exec_path,1,,$type Extension"];
$server->SetInfo();
