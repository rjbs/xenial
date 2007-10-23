
use strict;
use warnings;

use lib 't/lib';

package Xenial::Test::User;

use Digest::MD5 qw(md5_hex);
use Test::More;
use Xenial::Test::Base;

BEGIN { our @ISA = 'Xenial::Test::Base'; }

sub load_modules :Test(startup => 9) {
  use_ok 'Xenial::DB';
  use_ok 'Xenial::DB::Object';

  use_ok 'Xenial::Group';
  use_ok 'Xenial::Group';
  use_ok 'Xenial::GroupMembership';
  use_ok 'Xenial::User';
  use_ok 'Xenial::Wish';
  use_ok 'Xenial::Wishlist';
  use_ok 'Xenial::TimeZone';
}

sub load_test_data :Test(startup) {
  my ($self) = @_;
  $self->init_db;
  $self->load_data('data.yaml');
}

sub create_user :Test(7) {
  my ($self) = @_;

  {
    my $user = Xenial::User->new(
      username => 'rjbs',
      password => 'secret',

      birthday => '1978-07-20',
    );

    $user->save;

    ok($user->id, "the user got an id value assigned");
  }

  {
    my $user = Xenial::User->new(username => 'rjbs')->load;

    isa_ok($user, 'Xenial::User');
    is($user->pw_digest, md5_hex('secret'), "password digest is as expected");

    isa_ok($user->created_time, 'DateTime', 'created_time');

    isa_ok($user->birthday, 'DateTime', 'birthday');

    isa_ok($user->tz, 'Xenial::TimeZone');
    is($user->tz_name, 'UTC');
  }
}

sub new_user_id {
  my ($self, %arg) = @_;

  my %param = (
    username => $self->_random_uname,
    password => $self->_random_string,
    birthday => DateTime->from_epoch(
      epoch     => time - int(rand 365 * 70 * 86400),
      time_zone => 'UTC',
    ),

    %arg,
  );

  my $user = Xenial::User->new(%param)->save;
  return $user->id;
}

sub _random_string {
  return join q{}, map { chr(33 + int rand 89) } 0 .. 11;
}

my %_seen_uname;
sub _random_uname {
  my $uname;
  until ($uname and not $_seen_uname{$uname}) {
    $uname = join q{}, map { chr(97 + int rand 26) } 0 .. 7;
  }
  return $uname;
}

sub create_wishlist :Test(3) {
  my ($self) = @_;

  my $wishlist = Xenial::Wishlist->new(
    brief => 'a few things that I want',
    owner => { id => 1 },
  );

  $wishlist->add_wishes(
    { brief => 'flock of seagulls', unit_cost => 15 },
    { brief => 'playing card', unit_cost => 0.05, quantity => 52,
      summary => 'cheap bicycle playing cards are fine; no jokers!', }
  );

  $wishlist->save;

  {
    my $user = Xenial::User->new(id => 1)->load;
    isa_ok($user, 'Xenial::User');

    my @wishlists = $user->wishlists;
    is(@wishlists, 1, 'user 1 now has 1 wishlist');

    my @wishes = map { $_->wishes } @wishlists;
    is(@wishes, 2, "two total wishes for user");
  }
}

sub user_groups :Test(7) {
  my ($self) = @_;

  my $user_id = $self->new_user_id;
  my $user = Xenial::User->new(id => $user_id)->load;

  {
    my @groups = $user->groups;
    is(@groups, 0, "the user is not in any groups yet");
  }

  my $group = Xenial::Group->new(
    brief => q{The Drone's Club},
  );

  $group->save;

  {
    my @users = $group->users;
    is(@users, 0, "the new group has no users");
  }

  $user->add_groups({ brief => q{The Drone's Club} });

  {
    my @groups = $user->groups;
    is(@groups, 1, "the user is now in a group");
  }

  $user->save;

  # Strangely enough, the rhs of => below can be "1" or any true value, from
  # what I can tell.  I emailed the list and asked ftw.  Still, I'm sticking
  # what what *should* work. -- rjbs, 2007-08-05
  $group->load(with => [ 'users' ]);

  {
    my @users = $group->users;
    is(@users, 1, "the group now has a member");
  }

  my $new_user_id = $self->new_user_id;

  eval { map { $_->load } $group->memberships({ user_id => $new_user_id }); };
  like($@, qr/no such/i, "we can't load a group membership for non-member");

  my ($membership) = map { $_->load } $group->memberships({ user => $user });

  isa_ok($membership, 'Xenial::GroupMembership', 'loaded membership');

  isa_ok($membership->created_time, 'DateTime', "its created_time");
}

1;
