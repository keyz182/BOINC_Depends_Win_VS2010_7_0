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

use strict;

use File::Which;
use Getopt::Std;

my %opts = ();

getopts('av', \%opts);

my @files = @ARGV;

if ($opts{v}) {
    print <<"END";
This is pwhich running File::Which version $File::Which::VERSION

Copyright 2002 Per Einar Ellefsen.
This program is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.
END

    exit;
}

unless(@files) {
    print <<"EOS";
Usage: $0 [-a] [-v] programname [programname ...]
      -a        Print all matches in PATH, not just the first.
      -v        Prints version and exits

EOS
          
    exit;
}

for my $file (@files) {
    my @result = $opts{a} ? which($file) : scalar which($file); # need to force scalar
    @result = () unless defined $result[0];   # we might end up with @result = (undef) -> 1 elem
    for my $result (@result) {
        print "$result\n" if $result;
    }
    print STDERR "pwhich: no $file in PATH\n" unless @result;
}

__END__

=head1 NAME

pwhich - Perl-only `which'

=head1 Synopsis

  $ pwhich perl
  $ pwhich -a perl          # print all matches
  $ pwhich perl perldoc ... # look for multiple programs
  $ pwhich -a perl perldoc ...

=head1 DESCRIPTION

`pwhich' is a command-line utility program for finding paths to other
programs based on the user's C<PATH>. It is similar to the usualy Unix
tool `which', and tries to emulate its functionality, but is written
purely in Perl (uses the module C<File::Which>), so is portable.


=head1 Calling syntax

  $ pwhich [-a] [-v] programname [programname ...]

=head2 Options

=over

=item -a

The option I<-a> will make C<pwhich> print all matches found in the
C<PATH> variable instead of just the first one. Each match is printed
on a separate line.

=item -v

Prints version (of C<File::Which>) and copyright notice and exits.

=back

=head1 License

This program is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=head1 See Also

L<perl>, L<File::Which>, L<which(1)>

=head1 Author

Per Einar Ellefsen, E<lt>per.einar (at) skynet.beE<gt>

=cut


__END__
:endofperl
