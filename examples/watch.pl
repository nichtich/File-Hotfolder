use strict;
use warnings;
use v5.10;
use File::Hotfolder;

# watch a given directory and print all new or modified files 
File::Hotfolder->new( 
    watch    => ($ARGV[0] // '.'),
    callback => sub {
        my $path = shift;
        say $path;
    }
)->loop;
