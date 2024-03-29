@rem = '--*-Perl-*--
@echo off
if "%OS%" == "Windows_NT" goto WinNT
perl -x -S "%0" %1 %2 %3 %4 %5 %6 %7 %8 %9
goto endofperl
:WinNT
perl -x -S %0 %*
if NOT "%COMSPEC%" == "%SystemRoot%\system32\cmd.exe" goto endofperl
if %errorlevel% == 9009 echo You do not have Perl in your PATH.
if errorlevel 1 goto script_failed_so_exit_with_non_zero_val 2>nul
goto endofperl
@rem ';
#!/usr/bin/perl -w
#line 15

=head1 NAME

mech-dump - Dumps information about a web page

=cut

use warnings;
use strict;
use WWW::Mechanize;
use Getopt::Long;
use Pod::Usage;

my @actions;
my $absolute;

my $user;
my $pass;
my $agent;
my $agent_alias;

GetOptions(
    'user=s'        => \$user,
    'password=s'    => \$pass,
    forms           => sub { push( @actions, \&dump_forms ); },
    links           => sub { push( @actions, \&dump_links ); },
    images          => sub { push( @actions, \&dump_images ); },
    all             => sub { push( @actions, \&dump_forms, \&dump_links, \&dump_images ); },
    absolute        => \$absolute,
    'agent=s'       => \$agent,
    'agent-alias=s' => \$agent_alias,
    help            => sub { pod2usage(1); },
) or pod2usage(2);

=head1 SYNOPSIS

mech-dump [options] [file|url]

Options:

    --forms         Dump table of forms (default action)
    --links         Dump table of links
    --images        Dump table of images
    --all           Dump all three of the above, in that order

    --user=user     Set the username
    --password=pass Set the password

    --agent=agent   Specify the UserAgent to pass
    --agent-alias=alias
                    Specify the alias for the UserAgent to pass.
                    Pick one of:
                        * Windows IE 6
                        * Windows Mozilla
                        * Mac Safari
                        * Mac Mozilla
                        * Linux Mozilla
                        * Linux Konqueror

    --absolute      Show URLs as absolute, even if relative in the page
    --help          Show this message

The order of the options specified is relevant.  Repeated options
get repeated dumps.

=cut

my $uri = shift or die "Must specify a URL or file to check.  See --help for details.\n";
if ( -e $uri ) {
    require URI::file;
    $uri = URI::file->new_abs( $uri )->as_string;
}

@actions = (\&dump_forms) unless @actions;

my $mech = WWW::Mechanize->new( cookie_jar => undef );
if ( defined $agent ) {
    $mech->agent( $agent );
}
elsif ( defined $agent_alias ) {
    $mech->agent_alias( $agent_alias );
}
$mech->env_proxy();
my $response = $mech->get( $uri );
if (!$response->is_success and defined ($response->www_authenticate)) {
    if (!defined $user or !defined $pass) {
        die("Page requires username and password, but none specified.\n");
    }
    $mech->credentials($user,$pass);
    $response = $mech->get( $uri );
    $response->is_success or die "Can't fetch $uri with username and password\n", $response->status_line, "\n";
}
$mech->is_html or die qq{$uri returns type "}, $mech->ct, qq{", not "text/html"\n};

for my $action ( @actions ) {
    $action->( $mech );
}

sub dump_links {
    my $mech = shift;
    $mech->dump_links( undef, $absolute );
    return;
}

sub dump_images {
    my $mech = shift;
    $mech->dump_images( undef, $absolute );
    return;
}

sub dump_forms {
    my $mech = shift;
    $mech->dump_forms( undef, $absolute );
    return;
}

__END__
:endofperl
