
use strict;
use warnings;

use lib 't/lib';

package Xenial::Test::Objects;

use Digest::MD5 qw(md5_hex);
use Test::More;
use Xenial::Test::Base;

BEGIN { our @ISA = 'Xenial::Test::Base'; }

sub init_test_db :Test(startup) {
  my ($self) = @_;
  $self->init_db;
}

sub use_modules :Test(startup) {
  use_ok 'Xenial::User';
  use_ok 'Xenial::Wishlist';
  use_ok 'Xenial::Group';
  use_ok 'Xenial::Wish';
}

sub create_test_user :Test(3) {
  my ($self) = @_;

  {
    my $user = Xenial::User->new(
      username => 'rjbs',
      password => 'secret',

      birthday => '1978-07-20',
    );

    $user->save;

    is($user->id, 1, "since we've re-initialized the db, first id must be 1");
  }

  {
    my $user = Xenial::User->new(id => 1)->load;

    isa_ok($user, 'Xenial::User');
    is(
      $user->pw_digest,
      md5_hex('secret'),
      "password digest is as expected",
    );
  }
}

1;
