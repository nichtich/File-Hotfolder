package File::Hotfolder;
use strict;
use warnings;
use v5.10;

our $VERSION = '0.01';

use Carp;
use File::Find;
use File::Spec;
use Linux::Inotify2;

sub new {
    my ($class, %args) = @_;

    my $self = bless { 
        inotify  => (Linux::Inotify2->new()
                    or croak "Unable to create new inotify object: $!"),
        source   => ($args{watch} && -d $args{watch} ? $args{watch}
                    : croak "Missing watch directory: ".($args{watch} // '')),
        callback => ($args{callback} || sub { }),
        delete   => !!$args{delete},
    }, $class;

    $self->watch_recursive( $self->{source} );

    $self;
}

sub watch_recursive {
    my ($self, $path) = @_;

    $path = File::Spec->rel2abs($path);
    find( sub {
        return unless -d $_;
        $self->watch($File::Find::name);
    }, $path );
}

sub watch {
    my ($self, $path) = @_;

    unless (-d $path) {
        warn "missing watch directory: $path\n";
        return;
    }

    $self->{inotify}->watch( 
        $path, 
        IN_CREATE | IN_CLOSE_WRITE | IN_MOVE | IN_DELETE, 
        sub {
            my $e = shift;
            my $path  = $e->fullname;
            
            if (-d $path && ($e->IN_CREATE || $e->IN_MOVED_TO)) {
                $path = File::Spec->rel2abs($path);
            } elsif (-f $path && ($e->IN_CLOSE_WRITE || $e->IN_MOVED_TO)) {
                if ( $self->{callback}->( $path ) ) {
                    unlink $path if $self->{delete};
                }
            }
        }
    );
}

sub process_recursive {
    my ($self, $path) = @_;

    find( sub {
        return unless -f $_;
        # TODO: check if not open or modified (lsof or fuser)
        if ( $self->{callback}->($File::Find::name) ) {
            unlink $path;
        }
    }, $path );
}

sub poll {
    $_[0]->{inotify}->poll;
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

    my $hf = File::Hotfolder->new(
        watch    => '/my/input/path',
        delete   => 1
        callback => sub { 
            my $path = shift; # absolute path
            ...
            return should_delete($path) ? 1 : 0;
        },
    );

=head1 DESCRIPTION

This module uses L<Linux::Inotify2> to recursively watch a directory for new or
modified files. A callback is called on each file with its absolute path.

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

=back

=head1 EXAMPLE

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

=head1 SEE ALSO

L<File::ChangeNotify>, L<Filesys::Notify::Simple>, L<AnyEvent::Inotify::Simple>

=head1 COPYRIGHT AND LICENSE

Copyright Jakob Voss, 2015-

This library is free software; you can redistribute it and/or modify it under
the same terms as Perl itself.

=cut
