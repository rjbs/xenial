use strict;
use warnings;

package Xenial::Gift;

use Xenial::DB;
use Xenial::DB::Object;

BEGIN { our @ISA = 'Xenial::DB::Object'; }

__PACKAGE__->meta->setup(
  table      => 'gifts',
  columns    => [
    id      => { primary_key => 1, type => 'serial' },
    wish_id => { type => 'int', not_null => 1 },
    user_id => { type => 'int', not_null => 1 },
    quantity => { type => 'int', not_null => 1, default => 1 },
    comments => { type => 'text' },
    __PACKAGE__->_created_time_col,
  ],
  pk_columns => 'id',
  unique_key => 'brief',
  relationships => [
    memberships => {
      type => 'one to many',
      class => 'Xenial::GroupMembership',
      key_columns => { id => 'group_id' },
    },
    users => {
      type => 'many to many',
      map_class => 'Xenial::GroupMembership',
    },
  ],
);

__PACKAGE__->meta->make_manager_class('groups');

1;
