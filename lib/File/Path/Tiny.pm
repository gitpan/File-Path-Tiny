package File::Path::Tiny;

$File::Path::Tiny::VERSION = 0.4;

sub mk {
    my ( $path, $mask ) = @_;
    return 2 if -d $path;
    if ( -e $path ) { $! = 20; return; }
    $mask ||= '0777';    # Perl::Critic == Integer with leading zeros at ...
    $mask = oct($mask) if substr( $mask, 0, 1 ) eq '0';
    require File::Spec;
    my ( $progressive, @parts ) = File::Spec->splitdir($path);
    if ( !defined $progressive ) {    # no "|| $progressive eq ''" because, per File::Spec->splitdir POD: empty directory names ('') can be returned, because these are significant on some OSes.
        $progressive = File::Spec->catdir( $progressive, shift(@parts) );
    }
    if ( !-d $progressive ) {
        mkdir( $progressive, $mask ) or return;
    }
    for my $part (@parts) {
        $progressive = File::Spec->catdir( $progressive, $part );
        if ( !-d $progressive ) {
            mkdir( $progressive, $mask ) or return;
        }
    }
    return 1 if -d $path;
    return;
}

sub rm {
    my ($path) = @_;
    if ( -e $path && !-d $path ) { $! = 20; return; }
    return 2 if !-d $path;
    empty_dir($path) or return;
    rmdir($path) or return;
    return 1;
}

sub empty_dir {
    my ($path) = @_;
    if ( -e $path && !-d $path ) { $! = 20; return; }
    opendir( DIR, $path ) or return;
    my @contents = grep { $_ ne '.' && $_ ne '..' } readdir(DIR);
    closedir DIR;
    require File::Spec if @contents;
    for my $thing (@contents) {
        my $long = File::Spec->catdir( $path, $thing );
        if ( !-l $long && -d $long ) {
            rm($long) or return;
        }
        else {
            unlink $long or return;
        }
    }
    return 1;
}

1;
