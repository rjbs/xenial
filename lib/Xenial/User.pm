package Xenial::User;

=head1 NAME

Xenial::User - a Xenial user

=head1 VERSION

 $Id$

=head1 DESCRIPTION

This class provides an interface to Xenial users.  It inherits from
Xenial::DBI, which is a Class::DBI class.

=cut

use strict;
use warnings;
use base qw(Xenial::DBI);

__PACKAGE__->table('users');

=head1 COLUMNS

 username - the user's login name
 password - the hex md5sum of the user's password
 email    - the user's email address
 created  - the user's date of registration

 verification_code - the code sent to the user for verification
                     NULL if verified

=cut

__PACKAGE__->columns(
	All => qw(username password email created verification_code)
);

=head1 RELATIONSHIPS

=head2 wishes

Every user has_many wishes, which are Xenial::Wish objects.  They can be
retrieved with the C<wishes> accessor, as usual.

=cut

__PACKAGE__->has_many(wishes => 'Xenial::Wish' );

=head1 INFLATIONS

=head2 created

The created column is stored as seconds since epoch, but inflated to
Time::Piece objects.

=cut

__PACKAGE__->has_a(created => 'Time::Piece', deflate => 'epoch');

__PACKAGE__->add_trigger(before_create => \&create_times);

sub create_times {
	my $self = shift;
	$self->created(scalar gmtime) unless $self->{created};
}

=head1 METHODS

=head2 verify($code)

If the given code matches this user's C<verification_code>, the user will be
verified; that is, his C<verification_code> will be undefined.

=cut

sub verify {
	my ($self, $code) = @_;

	return unless $self->verification_code;

	if ($code and $code eq $self->verification_code) {
		$self->verification_code(undef);
		$self->update;
		return 1;
	}
	return;
}

=head1 TODO

=head1 AUTHOR

Ricardo SIGNES, C<< <rjbs@cpan.org> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-xenial@rt.cpan.org>, or
through the web interface at L<http://rt.cpan.org>. I will be notified, and
then you'll automatically be notified of progress on your bug as I make
changes.

=head1 COPYRIGHT

Copyright 2004 Ricardo SIGNES.  This program is free software;  you can
redistribute it and/or modify it under the same terms as Perl itself.

=cut

1;
