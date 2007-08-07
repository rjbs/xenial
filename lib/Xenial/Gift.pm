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
    wish_id => { type => 'integer', not_null => 1 },
    user_id => { type => 'integer', not_null => 1 },
    quantity => { type => 'integer', not_null => 1, default => 1 },
    comments => { type => 'text' },
    __PACKAGE__->_created_time_col,
  ],
  pk_columns => 'id',
  foreign_keys => [
    user => {
      class       => 'Xenial::User',
      key_columns => { user_id => 'id' },
      rel_type    => 'many to one',
    },
    wish => {
      class       => 'Xenial::Wish',
      key_columns => { wish_id => 'id' },
      rel_type    => 'many to one',
    },
  ],
);

__PACKAGE__->meta->make_manager_class('groups');

1;
