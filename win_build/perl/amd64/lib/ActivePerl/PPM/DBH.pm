package ActivePerl::PPM::DBH;

sub dbh {
    my $self = shift;
    return $self->{dbh} ||= do {
	die $self->{dbh_err} if $self->{dbh_err};
	eval { $self->_init_db };  # will set $self->{dbh}
	if ($@) {
	    delete $self->{dbh};
	    $self->{dbh_err} = $@;
	    die;
	}
	$self->{dbh};
    };
}

sub DESTROY {
    my $self = shift;
    if (my $dbh = delete $self->{dbh}) {
	$dbh->disconnect;
    }
}

1;
