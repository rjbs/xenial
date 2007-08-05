use strict;
use warnings;

package Xenial::DB;

use Rose::DB;
BEGIN { our @ISA = 'Rose::DB' }

__PACKAGE__->use_private_registry;

__PACKAGE__->register_db(
  driver   => 'sqlite',
  database => 'xenial.db',
  server_time_zone => 'UTC',
);

1;
