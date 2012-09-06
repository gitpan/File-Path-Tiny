use Test::More tests => 19;

use lib '../lib';

BEGIN {
    use_ok('File::Path::Tiny');
}

diag("Testing File::Path::Tiny $File::Path::Tiny::VERSION");

# cleanup from last time

for my $path (
    qw(
    foo/bar/mode       foo/bar/mode2       foo/bar/mode3
    foo/bar/mode_mkdir foo/bar/mode_mkdir2 foo/bar/dir
    foo/bar/file       foo/bar             foo
    )
  ) {
    if ( !-l $path && -d $path ) {
        rmdir $path;
    }
    else {
        unlink $path;
    }
}

SKIP: {
    skip 'Stale testing files exist', 5 if -d 'foo/bar';
    ok( File::Path::Tiny::mk("foo/bar"),  "make simple path - return true" );
    ok( -d "foo/bar",                     "make simple path - path recursively created" );
    ok( File::Path::Tiny::mk("foo") == 2, "make already existing dir" );
    if ( open my $fh, '>', 'foo/bar/file' ) {
        print {$fh} "test";
        close $fh;
    }
  SKIP: {
        skip 'test file not created', 2 if !-e 'foo/bar/file';
        ok( !File::Path::Tiny::mk("foo/bar/file"), "make already existing non dir - return false" );
        ok( $! == 20,                              "make already existing file - errno" );
    }
}

SKIP: {
    eval 'require File::Temp;';
    skip 'Absolute path test requires File::Temp', 3 if $@;
    my $dir = File::Temp->newdir();
    my $new = "$dir/foo/bar/baz";
    ok( File::Path::Tiny::mk($new),      "make absolute path - return true" );
    ok( -d $new,                         "make absolute path - path recursively created" );
    ok( File::Path::Tiny::mk($new) == 2, "make already existing absolute path dir" );
}

mkdir 'foo/bar/dir';

my $mk_mode = ( stat('foo/bar') )[2];

# $mk_mode       = sprintf('%04o', $mk_mode & 07777);
my $mkdir_mode = ( stat('foo/bar/dir') )[2];

# $mkdir_mode    = sprintf('%04o', $mkdir_mode & 07777);
# diag("mk: $mk_mode, mkdir: $mkdir_mode");
ok( $mk_mode == $mkdir_mode, 'MASK logic gets same results as mkdir()' );

File::Path::Tiny::mk( "foo/bar/mode", 0700 );
mkdir 'foo/bar/mode_mkdir', 0700;
ok( ( stat('foo/bar/mode') )[2] == ( stat('foo/bar/mode_mkdir') )[2], 'MASK arg OCT gets same results as mkdir()' );

File::Path::Tiny::mk( "foo/bar/mode2", oct('0700') );
mkdir 'foo/bar/mode_mkdir2', oct('0700');
ok( ( stat('foo/bar/mode2') )[2] == ( stat('foo/bar/mode_mkdir2') )[2], 'MASK arg oct(STR) gets same results as mkdir()' );

File::Path::Tiny::mk( "foo/bar/mode3", "0700" );

# mkdir 'foo/bar/mode_mkdir3', "0700"; # this breaks permissions so we compare with previous one
ok( ( stat('foo/bar/mode3') )[2] == ( stat('foo/bar/mode2') )[2], 'MASK arg STR gets detected and handled - different results as mkdir()' );

ok( !File::Path::Tiny::rm("foo/bar/file"), "remove existing non dir - return false" );
ok( $! == 20,                              "remove existing non dir - errno" );
undef $!;
ok( File::Path::Tiny::rm('foo/bar'),      "empty and remove simple path - return true" );
ok( !-d 'foo/bar',                        "remove simple path - path recursively removed" );
ok( File::Path::Tiny::rm('foo/bar') == 2, "remove already non-existing dir" );
ok( File::Path::Tiny::rm('foo'),          'remove empty dir' );
