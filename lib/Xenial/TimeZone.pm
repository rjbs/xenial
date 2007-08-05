use strict;
use warnings;

package Xenial::TimeZone;

use Xenial::DB;
use Xenial::DB::Object;

BEGIN { our @ISA = 'Xenial::DB::Object'; }

__PACKAGE__->meta->setup(
  table      => 'timezones',
  columns    => [
    id      => { primary_key => 1, type => 'serial' },
    tz_name => { type => 'varchar', length => 32, not_null => 1 },
  ],
  pk_columns => 'id',
  unique_key => 'tz_name',
);

__PACKAGE__->meta->make_manager_class('timezones');

1;
