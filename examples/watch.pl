use strict;
use File::Hotfolder;
use File::Spec;

my $root = @ARGV[0];

my $hf = File::Hotfolder->new( 
    watch => $root,
    callback => sub {
        my $path = shift;
        print File::Spec->abs2rel( $path, $root ) . "\n";
    }
);

1 while $hf->poll;
