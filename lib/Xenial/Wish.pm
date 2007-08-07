use strict;
use warnings;

package Xenial::Wish;

use Carp ();
use Xenial::DB;
use Xenial::DB::Object;

BEGIN { our @ISA = 'Xenial::DB::Object'; }

__PACKAGE__->meta->setup(
  table      => 'wishes',
  columns    => [
    id          => { primary_key => 1, type => 'serial' },
    wishlist_id => { type => 'int', not_null => 1 },
    brief       => { type => 'varchar', length => '128', not_null => 1 },
    unit_cost   => { type => 'decimal', precision => 8, scale => 2 },
    quantity    => { type => 'int', not_null => 1, default => 1 },
    __PACKAGE__->_created_time_col,
  ],
  pk_columns => 'id',
  foreign_keys => [
    wishlist => {
      class       => 'Xenial::Wishlist',
      key_columns => { wishlist_id => 'id' },
      rel_type    => 'many to one',
    },
  ],
);

__PACKAGE__->meta->make_manager_class('wishes');

1;
