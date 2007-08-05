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
    id    => { primary_key => 1, type => 'serial' },
    brief => { type => 'varchar', length => '128', not_null => 1 },
    cost  => { type => 'decimal', precision => 8, scale => 2 },
    wishlist_id  => { type => 'integer', not_null => 1 },
    created_time => { type => 'datetime', default => q{now} },
  ],
  pk_columns => 'id',
);

__PACKAGE__->meta->make_manager_class('wishes');

1;
