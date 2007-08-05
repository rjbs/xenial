use strict;
use warnings;

package Xenial::DB::Object;

use Rose::DB::Object;
use Xenial::DB;

BEGIN { our @ISA = 'Rose::DB::Object'; }

sub init_db { Xenial::DB->new }

sub _created_time_col {
  created_time => { type => 'datetime', not_null => 1, default => q{now} },
}

1;
