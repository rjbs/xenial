use strict;
use warnings;

package Xenial::Group;

use Xenial::DB;
use Xenial::DB::Object;

BEGIN { our @ISA = 'Xenial::DB::Object'; }

__PACKAGE__->meta->setup(
  table      => 'groups',
  columns    => [
    id    => { primary_key => 1, type => 'serial' },
    brief => { type => 'varchar', length => 32, not_null => 1 },
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
