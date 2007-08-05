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
    __PACKAGE__->_created_time_col,
    last_login_time => { type => 'datetime' },
    verified_time   => { type => 'datetime' },
  ],
  pk_columns   => [ 'id' ],
  unique_keys  => [ 'username' ],
  foreign_keys => [
    tz => {
      class       => 'Xenial::TimeZone',
      key_columns => { timezone_id => 'id' },
      rel_type    => 'many to one',
    },
  ],
  relationships => [
    groups => {
      type => 'many to many',
      map_class => 'Xenial::GroupMembership',
    },
  ],
);

__PACKAGE__->meta->make_manager_class('users');

sub password {
  my ($self, $password) = @_;
  Carp::croak("password method requires an argument") unless defined $password;
  require Digest::MD5;
  $self->pw_digest(Digest::MD5::md5_hex($password));
}

sub tz_name { $_[0]->tz->tz_name }

1;
