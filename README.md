# NAME

File::Hotfolder - recursive watch directory for new or modified files

# STATUS

[![Build Status](https://travis-ci.org/nichtich/File-Hotfolder.png)](https://travis-ci.org/nichtich/File-Hotfolder)
[![Coverage Status](https://coveralls.io/repos/nichtich/File-Hotfolder/badge.png?branch=master)](https://coveralls.io/r/nichtich/File-Hotfolder?branch=master)
[![Kwalitee Score](http://cpants.cpanauthors.org/dist/File-Hotfolder.png)](http://cpants.cpanauthors.org/dist/File-Hotfolder)

# SYNOPSIS

    use File::Hotfolder;

    # object interface
    File::Hotfolder->new(
        watch    => '/some/directory',  # which directory to watch
        callback => sub {               # what to do with each new/modified file
            my $path = shift;
            ...
        },
        delete   => 1,                  # delete each file if callback returns true
        filter   => qr/\.json$/,        # only watch selected files
        print    => WATCH_DIR,          # show which directories are watched
    )->loop;

    # function interface
    watch( '/some/directory', callback => sub { say shift } )->loop;

    # watch a given directory and delete all new or modified files
    watch( $ARGV[0] // '.', delete  => 1, print => DELETE_FILE )->loop;

# DESCRIPTION

This module uses [Linux::Inotify2](https://metacpan.org/pod/Linux::Inotify2) to recursively watch a directory for new or
modified files. A callback is called on each file with its path.

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

- fullname

    Return absolute path names (disabled by default).

- filter

    Filter filenames with regular expression before passing to callback.

- print

    Print to STDOUT each new directory (`WATCH_DIR`), each file path before
    callback execution (`FOUND_FILE`), and/or each deletion (`DELETE_FILE`).

- scan

    First call the callback for all existing files. This does not guarantee that
    found files have been closed.

# METHODS

## loop

Watch with a manual event loop. This method never returns.

## anyevent

Watch with [AnyEvent](https://metacpan.org/pod/AnyEvent). Returns a new AnyEvent watch.

## inotify

Returns the internal [Linux::Inotify2](https://metacpan.org/pod/Linux::Inotify2) object.

# SEE ALSO

[File::ChangeNotify](https://metacpan.org/pod/File::ChangeNotify), [Filesys::Notify::Simple](https://metacpan.org/pod/Filesys::Notify::Simple), [AnyEvent::Inotify::Simple](https://metacpan.org/pod/AnyEvent::Inotify::Simple)

[AnyEvent](https://metacpan.org/pod/AnyEvent)

[rrr-server](https://metacpan.org/pod/rrr-server) from [File::Rsync::Mirror::Recent](https://metacpan.org/pod/File::Rsync::Mirror::Recent)

# COPYRIGHT AND LICENSE

Copyright Jakob Voss, 2015-

This library is free software; you can redistribute it and/or modify it under
the same terms as Perl itself.
