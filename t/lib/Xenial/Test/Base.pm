use strict;
use warnings;

package Xenial::Test::Base;

use Test::Class;
use Test::More;

BEGIN { our @ISA = qw(Test::Class); }

=head1 METHODS

=head2 init_db

  $class->init_db(\%arg);

This method initializes a new test database.  It is not a startup or setup
method so that subclasses can choose whether and when to call it.

=cut

sub init_db {
  my ($self, $arg) = @_;
  $arg ||= {};

  # XXX: Yes, yes, this is ridiculous. -- rjbs, 2007-08-05
  unlink 'xenial.db';
  close STDIN;
  system qw(sqlite3 -init schema.sql xenial.db);
}

=head2 load_data

=cut

sub load_data {
  my ($self, $filename) = @_;

  require YAML::Syck;

  my $data = YAML::Syck::LoadFile($filename);

  for my $i (0 .. $#$data) {
    my ($class, $attr, $other) = %{ $data->[$i] };
    Carp::croak "too many data for entry $i in $filename" if $other;
    $class = "Xenial::$class";
    eval "require $class; 1" or die;
    $class->new(%$attr)->save;
  }
}

1;
