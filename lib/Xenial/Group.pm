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
  ],
  pk_columns => 'id',
  unique_key => 'brief',
);

__PACKAGE__->meta->make_manager_class('groups');

1;
