
use strict;
use Test::More 'no_plan';

use Digest::MD5 qw(md5_hex);
use Xenial::User;
use Xenial::Wishlist;
use Xenial::Group;
use Xenial::Wish;

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
