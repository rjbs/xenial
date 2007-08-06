
use strict;
use warnings;

use lib 't/lib';

package Xenial::Test::User;

use Digest::MD5 qw(md5_hex);
use Test::More;
use Xenial::Test::Base;

BEGIN { our @ISA = 'Xenial::Test::Base'; }

sub load_modules :Test(startup => 8) {
  use_ok 'Xenial::DB';
  use_ok 'Xenial::DB::Object';

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

sub user_groups :Test(7) {
  my ($self) = @_;

  my $user = Xenial::User->new(
    username => 'bwooster',
    password => 'whatho',

    birthday => '1903-05-13',
  );

  $user->save;

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

  eval { map { $_->load } $group->memberships({ user_id => 0 }); };
  like($@, qr/no such/i, "we can't load a group membership for user 0");

  my ($membership) = map { $_->load } $group->memberships({ user => $user });

  isa_ok($membership, 'Xenial::GroupMembership', 'loaded membership');

  isa_ok($membership->created_time, 'DateTime', "its created_time");
}

1;
