# NAME

File::Hotfolder - recursive watch directory for new or modified files

# STATUS

[![Build Status](https://travis-ci.org/nichtich/File-Hotfolder.png)](https://travis-ci.org/nichtich/File-Hotfolder)
[![Coverage Status](https://coveralls.io/repos/nichtich/File-Hotfolder/badge.png?branch=master)](https://coveralls.io/r/nichtich/File-Hotfolder?branch=master)
[![Kwalitee Score](http://cpants.cpanauthors.org/dist/File-Hotfolder.png)](http://cpants.cpanauthors.org/dist/File-Hotfolder)

# SYNOPSIS

    my $hf = File::Hotfolder->new(
        watch    => '/my/input/path',
        delete   => 1
        callback => sub { 
            my $path = shift; # absolute path
            ...
            return should_delete($path) ? 1 : 0;
        },
    );

# DESCRIPTION

This module uses [Linux::Inotify2](https://metacpan.org/pod/Linux::Inotify2) to recursively watch a directory for new or
modified files. A callback is called on each file with its absolute path.

Deletions and new subdirectories are not reported but new subdirectories will
be watched as well.

# CONFIGURATION

- watch

    Base directory to watch

- callback

    Callback for each new or modified file. The callback is not called during a
    write but after a file has been closed.

- delete

    Delete the modified file if a callback returned a true value (disabled by
    default).

# EXAMPLE

    use File::Hotfolder;
    use File::Spec;

    my $root = @ARGV[0];

    my $hf = File::Hotfolder->new( 
        watch => $root,
        delete => 0,
        callback => sub {
            my $path = shift;
            print File::Spec->abs2rel( $path, $root ) . "\n";
        }
    );

    1 while $hf->poll;

# SEE ALSO

[File::ChangeNotify](https://metacpan.org/pod/File::ChangeNotify), [Filesys::Notify::Simple](https://metacpan.org/pod/Filesys::Notify::Simple), [AnyEvent::Inotify::Simple](https://metacpan.org/pod/AnyEvent::Inotify::Simple)

# COPYRIGHT AND LICENSE

Copyright Jakob Voss, 2015-

This library is free software; you can redistribute it and/or modify it under
the same terms as Perl itself.
