use strict;
use warnings;

package Xenial::Wishlist;

use Carp ();
use Xenial::DB;
use Xenial::DB::Object;

BEGIN { our @ISA = 'Xenial::DB::Object'; }

__PACKAGE__->meta->setup(
  table      => 'wishlists',
  columns    => [
    id       => { primary_key => 1, type => 'serial' },
    owner_id => { type => 'int', not_null => 1 },
    brief    => { type => 'varchar', length => 64, not_null => 1 },
    __PACKAGE__->_created_time_col,
    modified_time => { type => 'datetime', default => q{now} },
  ],
  pk_columns => 'id',
  unique_key => [ [ qw(owner_id brief) ] ],
  foreign_keys => [
    owner => {
      class       => 'Xenial::User',
      key_columns => { owner_id => 'id' },
      rel_type    => 'many to one',
    },
  ],
  relationships => [
    wishes => {
      type => 'one to many',
      class => 'Xenial::Wish',
      key_columns => { id => 'wishlist_id' },
    },
  ],
);

__PACKAGE__->meta->make_manager_class('wishlists');

1;
