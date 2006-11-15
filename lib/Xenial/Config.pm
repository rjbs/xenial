package Xenial::Config;

=head1 NAME

Xenial::Config - the configuration data for Xenial

=head1 VERSION

 $Id$

=head1 DESCRIPTION

Xenial::Config provides access to the configuration data for Xenial.  The basic
implementation stores its configuration in YAML in a text file found using
Config::Auto's C<find_file> function.  By default, Xenial::Config looks
for C<rubric.yml>, but an alternate filename may be passed when using the
module:

 use Xenial:Config ".xenial_yml";

If this filename contains any slashes, it will be used without consulting
Config::Auto.

=cut

use strict;
use warnings;

use base qw(Class::Accessor);
use Config::Auto;
use YAML;

my $config_filename = 'xenial.yml';

sub import {
	my ($class) = shift;
	$config_filename = shift if @_;
}

=head1 SETTINGS

These configuration settings can all be retrieved by methods of the same name.

=over 4

=item * dsn

the DSN to be used by Xenial::DBI to connect to the Xenial's database

=back

=head1 METHODS

These methods are used by the setting accessors, internally:

=head2 _read_config

This method returns the config data, if loaded.  If it hasn't already been
loaded, it finds and parses the configuration file, then returns the data.

=cut

my $config;
sub _read_config {
	return $config if $config;

	my $config_file = ($config_filename =~ m!/|\\!)
		? Config::Auto::find_file($config_filename)
		: $config_filename;
	$config = YAML::LoadFile($config_file);
}

=head2 _default

This method returns the default configuration has a hashref.

=cut

my $default = {
	dsn         => undef,
};
sub _default { $default }

=head2 make_ro_accessor

Xenial::Config isa Class::Accessor, and uses this sub to build its setting
accessors.  For a given field, it returns the value of that field in the
configuration, if it exists.  Otherwise, it returns the default for that field.

=cut

sub make_ro_accessor {
	my ($class, $field) = @_;
	sub {
		exists $class->_read_config->{$field}
			? $class->_read_config->{$field}
			: $class->_default->{$field}
	}
}

__PACKAGE__->mk_ro_accessors(keys %$default);

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
