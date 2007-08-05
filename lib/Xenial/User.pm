use strict;
use warnings;

package Xenial::User;

use Carp ();
use Xenial::DB;
use Xenial::DB::Object;

BEGIN { our @ISA = 'Xenial::DB::Object'; }

__PACKAGE__->meta->setup(
  table      => 'users',
  columns    => [
    id    => { primary_key => 1, type => 'serial' },
    username  => { type => 'varchar', length => 32, not_null => 1 },
    realname  => { type => 'varchar', length => 64 },
    pw_digest => { type => 'varchar', length => 32, not_null => 1 },
    birthday  => { type => 'date', not_null => 1 },
    timezone_id     => { type => 'integer', not_null => 1, default => 1 },
    created_time    => { type => 'datetime', not_null => 1, default => q{now} },
    last_login_time => { type => 'datetime' },
    verified_time   => { type => 'datetime' },
  ],
  pk_columns => 'id',
  unique_key => 'username',
);

__PACKAGE__->meta->make_manager_class('users');

sub password {
  my ($self, $password) = @_;
  Carp::croak("password method requires an argument") unless defined $password;
  require Digest::MD5;
  $self->pw_digest(Digest::MD5::md5_hex($password));
}

1;
