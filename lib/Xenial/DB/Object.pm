use strict;
use warnings;

package Xenial::DB::Object;

use Rose::DB::Object;
use Xenial::DB;

BEGIN { our @ISA = 'Rose::DB::Object'; }

sub init_db { Xenial::DB->new }

1;
