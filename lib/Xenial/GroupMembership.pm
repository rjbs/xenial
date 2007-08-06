use strict;
use warnings;

package Xenial::GroupMembership;

use Carp ();
use Xenial::DB;
use Xenial::DB::Object;

BEGIN { our @ISA = 'Xenial::DB::Object'; }

__PACKAGE__->meta->setup(
  table      => 'group_memberships',
  columns    => [
    group_id => { type => 'integer' },
    user_id  => { type => 'integer' },
    __PACKAGE__->_created_time_col,
  ],
  pk_columns   => [ qw(group_id user_id) ],
  foreign_keys => [
    group => {
      class => 'Xenial::Group',
      key_columns => { group_id => 'id' },
    },
    user => {
      class       => 'Xenial::User',
      key_columns => { user_id => 'id' },
    },
  ]
);

__PACKAGE__->meta->make_manager_class('group_memberships');

1;
