package ActivePerl::Config;

use strict;
my %OVERRIDE;

# Make sure all the symbols overridden in this module are excluded
# from the tied cache in Config.pm (configpm in the Perl sources).

my %COMPILER_ENV = map { $_ => 1 } qw(
    cc
    ccflags
    cccdlflags
    ccname
    ccversion
    gccversion
    ar
    cpp
    cppminus
    cpprun
    cppstdin
    ld
    lddlflags
    ldflags
    lib_ext
    libc
    libs
    optimize
    perllibs
    _a
    _o
    obj_ext
    i64type
    u64type
    quadtype
    uquadtype
    d_casti32
);
my $compiler_env_initialized;

use Config ();
my $CONFIG_OBJ = tied %Config::Config;

sub override {
    return 0 if $ENV{ACTIVEPERL_CONFIG_DISABLE};

    require ActiveState::Path;

    my $key = shift;

    if (exists $ENV{"ACTIVEPERL_CONFIG_\U$key"}) {
	$_[0] = $ENV{"ACTIVEPERL_CONFIG_\U$key"};
	return 1;
    }

    if (exists $OVERRIDE{$key}) {
	$_[0] = $OVERRIDE{$key};
	return 1;
    }

    if ($key eq "make" && $^O eq "MSWin32") {
	for (qw(nmake dmake)) {
	    if (my $prog = _find_prog($_)) {
		$_[0] = $OVERRIDE{$key} = $prog;
		return 1;
	    }
	}
	if (_install_mingw($key)) {
	    if (my $prog = _find_prog("dmake")) {
		$_[0] = $OVERRIDE{$key} = $prog;
		return 1;
	    }
	}
	return 0;
    }
    if ($key eq "make" && ($^O eq "solaris" || $^O eq "hpux")) {
	if (!ActiveState::Path::find_prog(_orig_conf("make")) && -x "/usr/ccs/bin/make") {
	    $_[0] = $OVERRIDE{$key} = "/usr/ccs/bin/make";
	    return 1;
	}
    }

    if ($COMPILER_ENV{$key} && !$compiler_env_initialized++) {
	if ($^O eq "MSWin32" && !_gcc_requested() &&
	    _orig_conf("cc") eq "cl" && (my $cl = ActiveState::Path::find_prog("cl")))
	{
	    require Win32;
	    my @version = Win32::GetFileVersion($cl);
	    _override("ccversion", join('.', @version[0..2])) if @version;
	}
	elsif ($^O eq "MSWin32" && (_gcc_requested() || !ActiveState::Path::find_prog(_orig_conf("cc")))) {
	    my $gcc = _find_prog("gcc");
	    if (!$gcc && _install_mingw($key)) {
		$gcc = _find_prog("gcc");
	    }
	    if ($gcc) {
		# assume MinGW or similar is available
		$gcc = _get_short_path_name($gcc);
		$gcc =~ s,\\,/,g;
		my($mingw) = $gcc =~ m,^(.*)/bin/gcc\.exe$,;
		if (defined $mingw) {
		    $mingw .= "/lib";
		    my $sitelib = _get_short_path_name($Config::Config{sitelibexp});
		    $sitelib =~ s,\\,/,g;
		    $mingw .= "/auto/MinGW/lib" if lc($mingw) eq lc($sitelib);
		    if (defined $ENV{LIBRARY_PATH}) {
			$ENV{LIBRARY_PATH} .= ";$mingw";
		    }
		    else {
			$ENV{LIBRARY_PATH} = $mingw;
		    }
		}

		_override("cc", $gcc);
		_override("ccname", "gcc");
		my($gccversion) = qx($gcc --version);
		$gccversion =~ s/^gcc(\.exe)? \(GCC\) //;
		chomp($gccversion);
		warn "Set up gcc environment - $gccversion\n"
		    unless $ENV{ACTIVEPERL_CONFIG_SILENT} || $ENV{HARNESS_ACTIVE};
		_override("gccversion", $gccversion);
		_override("ccversion", "");

		foreach my $key (qw(libs perllibs)) {
		    # Old: "  foo.lib oldnames.lib bar.lib"
		    # New: "-lfoo -lbar"
		    my @libs = split / +/, _orig_conf($key);
		    # Filter out empty prefix and oldnames.lib
		    @libs = grep {$_ && $_ ne "oldnames.lib"} @libs;
		    # Remove '.lib' extension and add '-l' prefix
		    s/(.*)\.lib$/-l$1/ for @libs;
		    _override($key, join(' ', @libs));
		}

		# Copy all symbol definitions from the CCFLAGS
		my @ccflags = grep /^-D/, split / +/, _orig_conf("ccflags");
		# Add GCC specific flags
		push(@ccflags, qw(-DHASATTRIBUTE -fno-strict-aliasing -mms-bitfields));
		_override("ccflags", join(" ", @ccflags));

		# more overrides assuming MinGW
		_override("cpp",       "$gcc -E");
		_override("cpprun",    "$gcc -E");
		_override("cppminus",  "-");
		_override("ar",        _find_prog("ar"));
		_override("ld",        _find_prog("g++"));
		_override("_a",        ".a");
		_override("_o",        ".o");
		_override("obj_ext",   ".o");
		_override("lib_ext",   ".a");
		_override("optimize",  "-O2");
		_override("i64type",   "long long");
		_override("u64type",   "unsigned long long");
		_override("quadtype",  "long long");
		_override("uquadtype", "unsigned long long");
		_override("d_casti32", "define");

		# Extract all library paths from lddlflags
		my @libpaths = map "-L$_", map /^-libpath:(.+)/,
		    _orig_conf("lddlflags") =~ /(?=\S)(?>[^"\s]+|"[^"]*")+/g;
		_override("lddlflags", join(" ", "-mdll", @libpaths));
		_override("ldflags", join(" ", @libpaths));
	    }
	    elsif (_gcc_requested()) {
		warn "Cannot find gcc on PATH\n"
		    unless $ENV{ACTIVEPERL_CONFIG_SILENT};
	    }
	}
	elsif ($^O eq 'darwin') {
	    my($gccversion) = qx(gcc --version);
	    $gccversion =~ s/^gcc \(GCC\) //;
	    chomp($gccversion);
	    _override("gccversion", $gccversion);

	    my %flags = map { ($_ => _orig_conf($_)) } qw(ccflags ldflags lddlflags);

	    # gcc < 4 doesn't support -Wdeclaration-after-statement
	    $flags{ccflags} =~ s/-Wdeclaration-after-statement\s*//g
		if $gccversion =~ /^3\./;

	    # Try and find the SDK we built against
	    my $sdk;
	    my $sdkv;
	    if ($flags{ccflags} =~ m[(/Developer/SDKs/(MacOSX10\.[0-9a-z]+)\.sdk)]i) {
		$sdk = $1;
		$sdkv = $2;
	    }

	    # If the SDK is missing, we can't produce FAT binaries, so we have
	    # to fallback to regular native binaries
	    if ($sdk && !-d $sdk) {
		warn "Set up build environment without $sdkv SDK (will build native binaries)\n"
		    unless $ENV{ACTIVEPERL_CONFIG_SILENT};
		my $sdk_re = qr/$sdk|-nostdinc|-no-cpp-precomp|-mmacosx-version-min/;

		foreach my $flag (keys %flags) {
		    $flags{$flag} =~ s/-arch\s+(ppc|i386)\s*//g;
		    $flags{$flag} = join ' ', grep { !/$sdk_re/ } split /\s+/, $flags{$flag};
		}
	    }

	    _override($_, $flags{$_}) for keys %flags;
	}
	elsif (($^O eq "solaris" || $^O eq "hpux") && (_gcc_requested() || !_orig_conf("gccversion"))) {
	    my $cc = _gcc_requested() ? undef : ActiveState::Path::find_prog(_orig_conf("cc"));
	    if ($cc && $^O eq "hpux" && _is_bundled_hpux_compiler($cc)) {
		undef($cc);
	    }
	    if (!$cc && ($cc = ActiveState::Path::find_prog("gcc"))) {
		_override("cc", "gcc");
		my($gccversion) = qx(gcc --version);
		$gccversion =~ s/^gcc(\.exe)? \(GCC\) //;
		chomp($gccversion);
		warn "Set up gcc environment - $gccversion\n"
		    unless $ENV{ACTIVEPERL_CONFIG_SILENT};
		_override("gccversion", $gccversion);
		_override("ccversion", "");

		my $opt_mlp64 = "";
		$opt_mlp64 = "-mlp64 " if _orig_conf("archname") =~ /IA64/;

		for (qw(ccflags cppflags)) {
	            my $v = _orig_conf($_);
		    if ($^O eq "hpux") {
		        $v =~ s/(?:-Ae|-Wl,\+\w+)(?:\s+|$)//g;
			$v =~ s/\+Z/-fPIC/;
			$v =~ s/\+DD64\s*/$opt_mlp64/;
		    }
		    $v .= " -fno-strict-aliasing -pipe"; 
		    _override($_, $v);
		}
		my $cccdlflags = _orig_conf("cccdlflags");
		if (($^O eq "solaris" && $cccdlflags =~ s/-KPIC/-fPIC/) ||
		    ($^O eq "hpux" && $cccdlflags =~ s/\+Z/-fPIC/)
		   )
		{
		    _override("cccdlflags", $cccdlflags);
		}

		_override("ld", "gcc");
		_override("ccname", "gcc");
		_override("cpprun", "gcc -E");
		_override("cppstdin", "gcc -E");

		if ($^O eq "hpux") {
		    _override("optimize", "");
		    my $lddlflags = _orig_conf("lddlflags");
		    $lddlflags =~ s/\+vnocompatwarnings(?:\s+|$)//;
		    $lddlflags =~ s/-b(\s+|$)/-shared -static-libgcc -fPIC$1/;
		    $lddlflags =~ s,(-L/usr/lib/hpux64),$opt_mlp64$1,;
		    _override("lddlflags", $lddlflags);

		    my $ldflags = _orig_conf("ldflags");
		    if ($ldflags =~ s/\+DD64\s*/$opt_mlp64/ ||
			($opt_mlp64 && $ldflags =~ s,(-L/usr/lib/hpux64),$opt_mlp64$1,))
		    {
			_override("ldflags", $ldflags);
		    }
		}
	    }
	    if (!$cc && _gcc_requested()) {
		warn "Cannot find gcc on PATH\n"
		    unless $ENV{ACTIVEPERL_CONFIG_SILENT};
	    }
	}

	if (exists $OVERRIDE{$key}) {
	    $_[0] = $OVERRIDE{$key};
	    return 1;
	}
    }

    return 0;
}

sub _orig_conf {
    $CONFIG_OBJ->_fetch_string($_[0]);
}

sub _override {
    my($key, $val) = @_;
    $OVERRIDE{$key} = $val unless exists $OVERRIDE{$key};
}

sub _is_bundled_hpux_compiler {
    require ActiveState::Path;
    my $cc = shift;
    $cc = ActiveState::Path::realpath($cc);
    return $cc =~ /\bcc_bundled$/;
}

sub _gcc_requested {
    return defined($ENV{ACTIVEPERL_CONFIG_CC}) && $ENV{ACTIVEPERL_CONFIG_CC} eq "gcc";
}

# Prevent calling Win32::Console::DESTROY on a STDOUT handle
my $console;
sub _warn {
    my($msg) = @_;
    unless (-t STDOUT) {
	print "\n$msg\n";
	return;
    }
    require Win32::Console;
    unless ($console) {
	$console = Win32::Console->new(Win32::Console::STD_OUTPUT_HANDLE());
    }
    my($col,undef) = $console->Size;
    print "\n";
    $console->Attr($Win32::Console::FG_RED | $Win32::Console::BG_WHITE);
    for (split(/\n/, "$msg")) {
	$_ .= " " while length() < $col-1;
	print "$_\n";
    }
    $console->Attr($Win32::Console::ATTR_NORMAL);
    print "\n";
}

sub _inside_cpan_shell {
    return defined($INC{"CPAN.pm"}) || defined($INC{"CPANPLUS.pm"}) ||
	   $ENV{PERL5_CPAN_IS_RUNNING} || $ENV{PERL5_CPANPLUS_IS_RUNNING};
}

sub _get_short_path_name {
    my($path) = @_;
    $path = Win32::GetShortPathName($path) || $path;
    return $path;
}

my $dmake_not_on_path;
sub _find_prog {
    my($prog) = @_;
    if (my $progpath = ActiveState::Path::find_prog($prog)) {
	if ($^O eq "MSWin32") {
	    my($dir,$file) = $progpath =~ m,(.*)[\\/](.+)$,;
	    $progpath = _get_short_path_name($dir) . "\\$file" if defined $dir;
	}
	return $progpath;
    }
    if ($^O eq "MSWin32") {
	# dmake/MinGW install into Perl\site\bin; maybe the user forgot to add it to the PATH.
	# Don't call Win32::GetShortPathName() on $prog; it could break the forwarder program.
	my $fullname = _get_short_path_name($Config::Config{sitebinexp}) . "\\$prog.exe";
	if (-f $fullname) {
	    if ($prog eq "dmake" && !_inside_cpan_shell() && !$dmake_not_on_path++) {
		_warn <<EOT;
dmake could not be found on the PATH. Please invoke it using the full pathname:

    $fullname

or put the Perl\\site\\bin directory on the PATH with:

    path $Config::Config{sitebinexp};\%PATH\%
EOT
	    }
	    return $fullname;
	}
    }
    return;
}

my $already_tried_to_install_mingw;
my @module_builders = qw(
    CPAN.pm
    CPANPLUS.pm
    ExtUtils/MakeMaker.pm
    Module/Build.pm
    Module/Install.pm
);
sub _install_mingw {
    my($key) = @_;
    return if $already_tried_to_install_mingw++;
    return if ActivePerl::PRODUCT() =~ /Enterprise/i;

    # Don't warn or auto-install unless we are called from inside a build module
    return unless grep $INC{$_}, @module_builders;

    # Don't auto-install MinGW unless we are inside the CPAN/CPANPLUS shell
    unless (_inside_cpan_shell()) {
	if ($key eq "make") {
	    unless ($INC{"Module/Build.pm"}) {
		_warn <<'EOT';
It looks like you don't have either nmake.exe or dmake.exe on your PATH,
so you will not be able to execute the commands from a Makefile.  You can
install dmake.exe with the Perl Package Manager by running:

    ppm install dmake
EOT
	    }
	}
	else {
	    _warn <<'EOT';
It looks like you don't have a C compiler on your PATH, so you will not be
able to compile C or XS extension modules.  You can install GCC from the
MinGW package using the Perl Package Manager by running:

    ppm install MinGW
EOT
	}
	return;
    }
    return unless -f "$Config::Config{binexp}/ppm.bat";
    _warn <<'EOT';
It looks like you don't have a C compiler and make utility installed.  Trying
to install dmake and the MinGW gcc compiler using the Perl Package Manager.
This may take a a few minutes...
EOT
    system($^X, "-x", "$Config::Config{binexp}/ppm.bat", "install", "MinGW");

    unless (-f "$Config::Config{sitebinexp}/dmake.exe" && -f "$Config::Config{sitebinexp}/gcc.exe") {
	_warn <<'EOT';
It looks like the installation of dmake and MinGW has failed.  You will not be
able to run Makefile commands or compile C extension code.  Please check your
internet connection and your proxy settings!
EOT
	return;
    }

    _warn <<'EOT';
Please use the `dmake` program to run commands from a Makefile!
EOT
    return 1;
}

1;

__END__

=head1 NAME

ActivePerl::Config - Override the ActivePerl configuration

=head1 SYNOPSIS

  use Config qw(%Config);

=head1 DESCRIPTION

The standard C<Config> module provides the %Config hash containing
information about how this perl was built.  These configuration values
are used by modules and programs with the assumption that they still
apply for the system where perl is deployed.  This assumption does not
always hold.  The C<ExtUtils::MakeMaker> module will for instance
assume that it can use the compiler $Config{cc} for building new
extensions, but another compiler might be the only one available.

The C<ActivePerl::Config> module provides a solution for this.  It
overrides the values of %Config to better match the system where perl
currently runs.  For example, on Windows allows you to build extensions
with the free compiler L<gcc|gcc> (see L<http://www.mingw.org/>) even
though ActivePerl for Windows itself is built with the commercial
Microsoft Visual Studio 6 compiler.

The C<ActivePerl::Config> module is not used directly.  It is
automatically loaded by C<Config> if available and works behind the
scenes, overriding the values that are found in the %Config hash.  The
overriden values from C<ActivePerl::Config> will also show when C<perl
-V:foo> is invoked from the command line.

=head2 Windows overrides

For ActivePerl on Windows the following %Config overrides are provided:

=over

=item $Config{make}

This will be C<nmake> by default, but if no F<nmake> program can be
found and other compatible make programs are found, then this value
will reflect that.  Currently F<dmake> is the only other make
implementation that is compatible enough to build perl extensions.

=item $Config{cc}, $Config{ccflags},...

The value of $Config{cc} will be C<cl> by default, but if no C<cl>
program can be found and F<gcc> is found, then this value is C<gcc>
and other values related to the compiler environment is adjusted
accordingly.

The ACTIVEPERL_CONFIG_CC environment variable can be set to C<gcc>
to use C<gcc> even when C<cl> is found.

=back

=head2 Mac OS X overrides

For ActivePerl on Mac OS X the compilation flags (like
C<$Config{ccflags}>) are adjusted to make it possible to compile
extentions even on 10.3 systems and systems that don't have the SDK
for generating Universal binaries installed.

=head2 HP-UX and Solaris overrides

For ActivePerl on HP-UX and Solaris the following %Config overrides
are provided:

=over

=item $Config{make}

This will be C<make> by default, but if F<make> can't be found via the
PATH, then it's set to F</usr/ccs/bin/make> if that one is available.

=item $Config{cc}, $Config{ccflags},...

The value of $Config{cc} will be C<cc> by default and the other
compiler environment values are set up for compilation with the HP-UX
ANSI C compiler or the Sun Forte/WorkShop compiler respectively.  If
F<cc> can't be found via the PATH and F<gcc> is found, then
$Config{cc} is set to C<gcc> and other values related to the compiler
environment is adjusted accordingly.

The ACTIVEPERL_CONFIG_CC environment variable can be set to C<gcc>
to use C<gcc> even when C<cc> is found.

=back

=head1 ENVIRONMENT

The following environment variables can influence the operation of the
C<ActivePerl::Config> module:

=over

=item ACTIVEPERL_CONFIG_DISABLE

If set to a TRUE value (e.g. "1"), prevent C<ActivePerl::Config> from
overriding any %Config value; the only values seen in %Config would be
those determined at perl build time.  Another way to disable
C<ActivePerl::Config> permanently is to remove it using L<ppm|ppm>
(C<ppm remove ActivePerl-Config>)

=item ACTIVEPERL_CONFIG_SILENT

If set to a TRUE value (e.g. "1"), suppress warnings on STDERR when
new compilation environments are set up.  This happens when a
supported compiler is detected that is different from the one that
perl was originally built with.

=item ACTIVEPERL_CONFIG_I<FOO>

Override the $Config{I<foo>} value.  For example if the
ACTIVEPERL_CONFIG_MAKE environment variable has the value C<dmake>,
then so would $Config{make}.

If the ACTIVEPERL_CONFIG_DISABLE variable is set, all other
ACTIVEPERL_CONFIG_I<FOO> variables are ignored.

=back

=head1 SEE ALSO

L<Config>
