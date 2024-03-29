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
#!perl
#line 15
    eval 'exec C:\Progra~1\Perl64\bin\perl.exe -S $0 ${1+"$@"}'
	if $running_under_some_shell;
#!./perl
# $Id: piconv,v 2.3 2007/04/06 12:53:41 dankogai Exp $
#
use 5.8.0;
use strict;
use Encode ;
use Encode::Alias;
my %Scheme =  map {$_ => 1} qw(from_to decode_encode perlio);

use File::Basename;
my $name = basename($0);

use Getopt::Long qw(:config no_ignore_case);

my %Opt;

help()
    unless
      GetOptions(\%Opt,
         'from|f=s',
         'to|t=s',
         'list|l',
         'string|s=s',
         'check|C=i',
         'c',
         'perlqq|p',
         'htmlcref',
         'xmlcref',
         'debug|D',
         'scheme|S=s',
         'resolve|r=s',
         'help',
         );

$Opt{help} and help();
$Opt{list} and list_encodings();
my $locale = $ENV{LC_CTYPE} || $ENV{LC_ALL} || $ENV{LANG};
defined $Opt{resolve} and resolve_encoding($Opt{resolve});
$Opt{from} || $Opt{to} || help();
my $from = $Opt{from} || $locale or help("from_encoding unspecified");
my $to   = $Opt{to}   || $locale or help("to_encoding unspecified");
$Opt{string} and Encode::from_to($Opt{string}, $from, $to) and print $Opt{string} and exit;
my $scheme = exists $Scheme{$Opt{scheme}} ? $Opt{scheme} :  'from_to';
$Opt{check} ||= $Opt{c};
$Opt{perlqq}   and $Opt{check} = Encode::PERLQQ;
$Opt{htmlcref} and $Opt{check} = Encode::HTMLCREF;
$Opt{xmlcref}  and $Opt{check} = Encode::XMLCREF;

if ($Opt{debug}){
    my $cfrom = Encode->getEncoding($from)->name;
    my $cto   = Encode->getEncoding($to)->name;
    print <<"EOT";
Scheme: $scheme
From:   $from => $cfrom
To:     $to => $cto
EOT
}

# we do not use <> (or ARGV) for the sake of binmode()
@ARGV or push @ARGV, \*STDIN;

unless ( $scheme eq 'perlio' ) {
    binmode STDOUT;
    for my $argv (@ARGV) {
        my $ifh = ref $argv ? $argv : undef;
        $ifh or open $ifh, "<", $argv or next;
        binmode $ifh;
        if ( $scheme eq 'from_to' ) {    # default
            while (<$ifh>) {
                Encode::from_to( $_, $from, $to, $Opt{check} );
                print;
            }
        }
        elsif ( $scheme eq 'decode_encode' ) {    # step-by-step
            while (<$ifh>) {
                my $decoded = decode( $from, $_, $Opt{check} );
                my $encoded = encode( $to, $decoded );
                print $encoded;
            }
        }
        else {                                    # won't reach
            die "$name: unknown scheme: $scheme";
        }
    }
}
else {

    # NI-S favorite
    binmode STDOUT => "raw:encoding($to)";
    for my $argv (@ARGV) {
        my $ifh = ref $argv ? $argv : undef;
        $ifh or open $ifh, "<", $argv or next;
        binmode $ifh => "raw:encoding($from)";
        print while (<$ifh>);
    }
}

sub list_encodings {
    print join( "\n", Encode->encodings(":all") ), "\n";
    exit 0;
}

sub resolve_encoding {
    if ( my $alias = Encode::resolve_alias( $_[0] ) ) {
        print $alias, "\n";
        exit 0;
    }
    else {
        warn "$name: $_[0] is not known to Encode\n";
        exit 1;
    }
}

sub help {
    my $message = shift;
    $message and print STDERR "$name error: $message\n";
    print STDERR <<"EOT";
$name [-f from_encoding] [-t to_encoding] [-s string] [files...]
$name -l
$name -r encoding_alias
  -l,--list
     lists all available encodings
  -r,--resolve encoding_alias
    resolve encoding to its (Encode) canonical name
  -f,--from from_encoding  
     when omitted, the current locale will be used
  -t,--to to_encoding    
     when omitted, the current locale will be used
  -s,--string string         
     "string" will be the input instead of STDIN or files
The following are mainly of interest to Encode hackers:
  -D,--debug          show debug information
  -C N | -c           check the validity of the input
  -S,--scheme scheme  use the scheme for conversion
Those are handy when you can only see ascii characters:
  -p,--perlqq
  --htmlcref
  --xmlcref
EOT
    exit;
}

__END__

=head1 NAME

piconv -- iconv(1), reinvented in perl

=head1 SYNOPSIS

  piconv [-f from_encoding] [-t to_encoding] [-s string] [files...]
  piconv -l
  piconv [-C N|-c|-p]
  piconv -S scheme ...
  piconv -r encoding
  piconv -D ...
  piconv -h

=head1 DESCRIPTION

B<piconv> is perl version of B<iconv>, a character encoding converter
widely available for various Unixen today.  This script was primarily
a technology demonstrator for Perl 5.8.0, but you can use piconv in the
place of iconv for virtually any case.

piconv converts the character encoding of either STDIN or files
specified in the argument and prints out to STDOUT.

Here is the list of options.  Each option can be in short format (-f)
or long (--from).

=over 4

=item -f,--from from_encoding

Specifies the encoding you are converting from.  Unlike B<iconv>,
this option can be omitted.  In such cases, the current locale is used.

=item -t,--to to_encoding

Specifies the encoding you are converting to.  Unlike B<iconv>,
this option can be omitted.  In such cases, the current locale is used.

Therefore, when both -f and -t are omitted, B<piconv> just acts
like B<cat>.

=item -s,--string I<string>

uses I<string> instead of file for the source of text.

=item -l,--list

Lists all available encodings, one per line, in case-insensitive
order.  Note that only the canonical names are listed; many aliases
exist.  For example, the names are case-insensitive, and many standard
and common aliases work, such as "latin1" for "ISO-8859-1", or "ibm850"
instead of "cp850", or "winlatin1" for "cp1252".  See L<Encode::Supported>
for a full discussion.

=item -C,--check I<N>

Check the validity of the stream if I<N> = 1.  When I<N> = -1, something
interesting happens when it encounters an invalid character.

=item -c

Same as C<-C 1>.

=item -p,--perlqq

=item --htmlcref

=item --xmlcref

Applies PERLQQ, HTMLCREF, XMLCREF, respectively.  Try

  piconv -f utf8 -t ascii --perlqq

To see what it does.

=item -h,--help

Show usage.

=item -D,--debug

Invokes debugging mode.  Primarily for Encode hackers.

=item -S,--scheme scheme

Selects which scheme is to be used for conversion.  Available schemes
are as follows:

=over 4

=item from_to

Uses Encode::from_to for conversion.  This is the default.

=item decode_encode

Input strings are decode()d then encode()d.  A straight two-step
implementation.

=item perlio

The new perlIO layer is used.  NI-S' favorite.

You should use this option if you are using UTF-16 and others which
linefeed is not $/.

=back

Like the I<-D> option, this is also for Encode hackers.

=back

=head1 SEE ALSO

L<iconv/1>
L<locale/3>
L<Encode>
L<Encode::Supported>
L<Encode::Alias>
L<PerlIO>

=cut

__END__
:endofperl
