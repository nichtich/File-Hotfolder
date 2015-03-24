package File::Hotfolder;
use strict;
use warnings;
use v5.10;

our $VERSION = '0.03';

use Carp;
use File::Find;
use File::Spec;
use Linux::Inotify2;

use parent 'Exporter';
our %EXPORT_TAGS = (print => [qw(WATCH_DIR FOUND_FILE DELETE_FILE)]);
our @EXPORT = ('watch', @{$EXPORT_TAGS{'print'}});
$EXPORT_TAGS{all} = \@EXPORT;

use constant {
    WATCH_DIR   => 1,
    FOUND_FILE  => 2,
    DELETE_FILE => 4
};

# function interface
sub watch {
    shift if $_[0] eq 'File::Hotfolder';
    File::Hotfolder->new( @_ % 2 ? (watch => @_) : @_ );
}

# object interface
sub new {
    my ($class, %args) = @_;

    my $path = $args{watch} // ''; 
    $path = File::Spec->rel2abs($path) if $args{fullname};
    croak "Missing watch directory: $path" unless -d $path,

    my $self = bless { 
        inotify  => (Linux::Inotify2->new
                    or croak "Unable to create new inotify object: $!"),
        callback => ($args{callback} || sub { 1 }),
        delete   => !!$args{delete},
        print    => 0+($args{print} || 0),
        filter   => $args{filter},
        scan     => $args{scan},
    }, $class;

    $self->watch_recursive( $path );

    $self;
}

sub watch_recursive {
    my ($self, $path) = @_;

    find({
        no_chdir => 1, 
        wanted => sub {
            if (-d $_) {
                $self->watch_directory($_);
            } elsif( $self->{scan} ) {
                # TODO: check if not open or modified (lsof or fuser)
                $self->_callback($_);
            }
        },
    }, $path );
}

sub watch_directory {
    my ($self, $path) = @_;

    unless (-d $path) {
        warn "missing watch directory: $path\n";
        return;
    }
    
    say "watching $path" if ($self->{print} & WATCH_DIR);

    unless ( $self->inotify->watch( 
        $path, 
        IN_CREATE | IN_CLOSE_WRITE | IN_MOVE | IN_DELETE | IN_DELETE_SELF | IN_MOVE_SELF, 
        sub {
            my $e = shift;
            my $path  = $e->fullname;
            
            warn "event queue overflowed\n" if $e->IN_Q_OVERFLOW;
            
            if ( $e->IN_ISDIR ) {
                if ( $e->IN_CREATE || $e->IN_MOVED_TO) {
                    $self->watch_recursive($path);
                } elsif ( $e->IN_DELETE_SELF || $e->IN_MOVE_SELF ) {
                    say "unwatching $path" if ($self->{print} & WATCH_DIR);
                    $e->w->cancel;
                }
            } elsif ( $e->IN_CLOSE_WRITE || $e->IN_MOVED_TO ) {
                $self->_callback($path);
            }

        }
    ) ) {
        warn "watching $path failed: $!\n";
    };
}

sub _callback {
    my ($self, $path) = @_;

    if ($self->{filter} && $path !~ $self->{filter}) {
        return;
    }

    say $path if ($self->{print} & FOUND_FILE);
    if ( $self->{callback}->( $path ) ) {
        if ( $self->{delete} ) {
            say $path if ($self->{print} & DELETE_FILE); 
            unlink $path;
        }
    }
}

sub inotify {
    $_[0]->{inotify};
}

sub loop {
    1 while $_[0]->inotify->poll;
}

sub anyevent {
    my $inotify = $_[0]->inotify;
    AnyEvent->io (
        fh => $inotify->fileno, poll => 'r', cb => sub { $inotify->poll }
    );
}

1;
__END__

=head1 NAME

File::Hotfolder - recursive watch directory for new or modified files

=begin markdown

# STATUS

[![Build Status](https://travis-ci.org/nichtich/File-Hotfolder.png)](https://travis-ci.org/nichtich/File-Hotfolder)
[![Coverage Status](https://coveralls.io/repos/nichtich/File-Hotfolder/badge.png?branch=master)](https://coveralls.io/r/nichtich/File-Hotfolder?branch=master)
[![Kwalitee Score](http://cpants.cpanauthors.org/dist/File-Hotfolder.png)](http://cpants.cpanauthors.org/dist/File-Hotfolder)

=end markdown

=head1 SYNOPSIS

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

=head1 DESCRIPTION

This module uses L<Linux::Inotify2> to recursively watch a directory for new or
modified files. A callback is called on each file with its path.

Deletions and new subdirectories are not reported but new subdirectories will
be watched as well.

=head1 CONFIGURATION

=over

=item watch

Base directory to watch

=item callback

Callback for each new or modified file. The callback is not called during a
write but after a file has been closed.

=item delete

Delete the modified file if a callback returned a true value (disabled by
default).

=item fullname

Return absolute path names (disabled by default).

=item filter

Filter filenames with regular expression before passing to callback.

=item print

Print to STDOUT each new directory (C<WATCH_DIR>), each file path before
callback execution (C<FOUND_FILE>), and/or each deletion (C<DELETE_FILE>).

=item scan

First call the callback for all existing files. This does not guarantee that
found files have been closed.

=cut

=back

=head1 METHODS

=head2 loop

Watch with a manual event loop. This method never returns.

=head2 anyevent

Watch with L<AnyEvent>. Returns a new AnyEvent watch.

=head2 inotify

Returns the internal L<Linux::Inotify2> object.

=head1 SEE ALSO

L<File::ChangeNotify>, L<Filesys::Notify::Simple>, L<AnyEvent::Inotify::Simple>

L<AnyEvent>

L<rrr-server> from L<File::Rsync::Mirror::Recent>

=head1 COPYRIGHT AND LICENSE

Copyright Jakob Voss, 2015-

This library is free software; you can redistribute it and/or modify it under
the same terms as Perl itself.

=cut
