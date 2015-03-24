use strict;
use warnings;
use v5.10;
use Test::More;
use File::Temp qw(tempdir);
use Time::HiRes qw(usleep);

use File::Hotfolder;

unless ($ENV{RELEASE_TESTING}) {
    plan skip_all => 'skipped unless RELEASE_TESTING is set';
    exit;
}

#unless (eval { require 'AnyEvent.pm'; 1 }) {
#    plan skip_all => 'skipped unless AnyEvent is installed';
#    exit;
#}

my $dir = tempdir( CLEANUP => 1 );
mkdir "$dir/foo";

my @queue;
my $hf = File::Hotfolder->new(
    watch    => $dir,
    delete   => 1,
    callback => sub { push @queue, @_; 1; }
);
$hf->inotify->blocking(0);

sub touch($) {
    my $f = new IO::File(shift, "w") || die "open: $!";
    $f->print('1');
    $f->close;
}

touch "$dir/a";
touch "$dir/foo/b";

$hf->inotify->poll for 1..10;

is_deeply \@queue, ["$dir/a","$dir/foo/b"];

done_testing;
