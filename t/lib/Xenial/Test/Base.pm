use strict;
use warnings;

package Xenial::Base;

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

  unlink 'xenial.db';
  close STDIN;
  system qw(sqlite3 -init schema.sql xenial.db);
}

1;
