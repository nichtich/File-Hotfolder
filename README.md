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
        fork     => 0,                  # fork callback
        delete   => 1,                  # delete each file if callback returns true
        filter   => qr/\.json$/,        # only watch selected files
        print    => WATCH_DIR           # show which directories are watched
                    | HOTFOLDER_ERROR,  # show all errors (CATCH_ERROR | WATCH_ERROR)
        catch    => sub {               # catch callback errors
            my ($path, $error) = @_;
            ...
        },
        event_mask => IN_CLOSE          # filter event only to those of interest
    )->loop;

    # function interface
    watch( '/some/directory', callback => sub { say shift } )->loop;

    # watch a given directory and delete all new or modified files
    watch( $ARGV[0] // '.', delete  => 1, print => DELETE_FILE )->loop;

    # watch directory, delete all new/modified non-txt files, print all files
    watch( '/some/directory',
        callback => sub { $_[0] !~ /\.txt$/ },
        delete  => 1,
        print   => DELETE_FILE | KEEP_FILE
    );
    
    # wait for events with AnyEvent
    File::HotFolder->new( ... )->anyevent;
    AnyEvent->condvar->recv;

# DESCRIPTION

This module uses [Linux::Inotify2](https://metacpan.org/pod/Linux::Inotify2) to recursively watch a directory for new or
modified files. A callback is called on each file with its path.

Deletions and new subdirectories are not reported but new subdirectories will
be watched as well.

# CONFIGURATION

- watch

    Base directory to watch. The `WATCH_DIR` event is logged for each watched
    (sub)directory and the `UNWATCH_DIR` event if directories are deleted. The
    `WATCH_ERROR` event is logged if watching a directory failed and if the watch
    queue overflowed.

- callback

    Callback for each new or modified file. The callback is not called during a
    write but after a file has been closed. The `FOUND_FILE` event is logged
    before executing the callback.

- delete

    Delete the modified file if a callback returned a true value (disabled by
    default). A `DELETE_FILE` will be logged after deletion or a `KEEP_FILE`
    event otherwise.

- event\_mask

    React only to those event satisfying the mask. Can be any mask built of the
    following Linux::Inotify2 event flags: `IN_CREATE`, `IN_CLOSE_WRITE`,
    `IN_MOVE`, `IN_DELETE`, `IN_DELETE_SELF`, `IN_MOVE_SELF`.

    Defaults to `IN_CLOSE_WRITE` | `IN_MOVED_TO`.

- fullname

    Return absolute path names. By default pathes are relative to the base
    directory given with option `watch`.

- filter

    Filter file pathes with regular expression or code reference before passing to
    callback. Set to ignore all hidden files (starting with a dot) by default.  Use
    `0` to disable.

- filter\_dir

    Filter directory names with regular expression before watching. Set to ignore
    hidden directories (starting with a dot) by default. Use `0` to disable.

- fork

    Execute callback in a child process by forking if possible.  Logging also takes
    place in the child process.

- print

    Log events to STDOUT and STDERR unless an explicit `logger` is specified.

    This parameter expects a value with event types.  Possible event types are
    exported as constants `WATCH_DIR`, `UNWATCH_DIR`, `FOUND_FILE`,
    `DELETE_FILE`, `KEEP_FILE`, `CATCH_ERROR`, and `WATCH_ERROR`. The constant
    `HOTFOLDER_ERROR` combines `CATCH_ERROR` and `WATCH_ERROR` and the constant
    `HOTFOLDER_ALL` combines all event types.

- logger

    Where to log events to. If given a code reference, the code is called with
    three named parameters:

        logger => sub { # event => $event, path => $path, message => $message
            my (%args) = @_;
            ...
        },

    If given an object instance a logging method is created and called at the
    object's `log` method with argument `level` and `message` as expected by
    [Log::Dispatch](https://metacpan.org/pod/Log::Dispatch):

        logger => Log::Dispatch->new( ... ),

    The `level` is set to `error` for `HOTFOLDER_ERROR` events and `info` for
    other events.

- catch

    Error callback for failing callbacks (event `CATCH_ERROR`). Disabled by
    default, so a dying callback will terminate the program. 

- scan

    First call the callback for all existing files. This does not guarantee that
    found files have been closed.

# METHODS

## loop

Watch with a manual event loop. This method never returns.

## anyevent

Watch with [AnyEvent](https://metacpan.org/pod/AnyEvent). Returns a new AnyEvent watch.

## inotify

Returns the internal [Linux::Inotify2](https://metacpan.org/pod/Linux::Inotify2) object. Future versions of this module
may use another notify module ([Win32::ChangeNotify](https://metacpan.org/pod/Win32::ChangeNotify), [Mac::FSEvents](https://metacpan.org/pod/Mac::FSEvents),
[Filesys::Notify::KQueue](https://metacpan.org/pod/Filesys::Notify::KQueue)...), so this method may return `undef`.

# SEE ALSO

- [File::ChangeNotify](https://metacpan.org/pod/File::ChangeNotify), [Filesys::Notify::Simple](https://metacpan.org/pod/Filesys::Notify::Simple)
- [AnyEvent](https://metacpan.org/pod/AnyEvent)

# COPYRIGHT AND LICENSE

Copyright Jakob Voss, 2015-

This library is free software; you can redistribute it and/or modify it under
the same terms as Perl itself.
