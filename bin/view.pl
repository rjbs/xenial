#!/usr/bin/perl 

use strict;
use DBI;
use CGI qw/:all/;

use vars qw[$dbh $current_unum $current_realname];

$dbh=DBI->connect('dbi:Pg:dbname=xmas', 'samael', undef) or print 'oops!';

($current_unum, $current_realname) =
	$dbh->selectrow_array("SELECT unum, realname FROM people WHERE uname='$ENV{REMOTE_USER}'");

## HTML Generating Routines

sub begin_html {
	my ($title) = @_;

	print "Content-type: text/html\n\n";
	print <<EOH;
<html>
	<head>
		<title>Signes Wishlists</title>
		<link rel='stylesheet' href='http://www.manxome.org/style/manxome.css' type='text/css' />
		<style type='text/css'>
			div#header div#userid { font-size: smaller; background-color:#d0d0d0; text-align:right; }
			table { width: 95% }
			th { width: 25% }
		</style>
	</head>
	<body>
	<div id='header'>
		<h1>Ricardo Signes</h1>
		<h2>$title</h2>
	</div>
EOH
}

sub end_html {
	print "<div id='footer'>end</div>\n";
	print "</body>\n</html>\n";
}

## Database Operations

sub sql_meta {
	$_[0] =~ s/'/''/g;
	return $_[0];
}

sub wishlist {
	my $unum = shift;
	my $table;
	my $tts = $dbh->selectall_arrayref("
		SELECT DISTINCT brief, thingtypeid
		FROM thingtypes
		WHERE thingtypeid IN
			(SELECT thingtypeid FROM wishes WHERE unum=$unum)
		ORDER BY brief
	");

	foreach my $tt (@$tts) {
		$table .= "<h3>$tt->[0]</h3>\n";

	my $sth = $dbh->prepare("
		SELECT * 
		FROM wishes
		WHERE unum=$unum AND thingtypeid=$tt->[1]
		ORDER BY thingtypeid, brief
	");
	
	$table .= "<table>\n";
	$table .= "<tr><th style='width:80%'>Item</th><th>Approx Cost</th></tr>\n";
	$sth->execute;
	while (my $row = $sth->fetchrow_hashref) {
		$table .= "\t<tr>" .
			"<td><a href='?op=item&amp;wnum=$row->{wnum}'>$row->{brief}</a></td><td>" .
			($row->{cost} ? sprintf('$%.2f',$row->{cost}) : 'unknown') .
			"</td></tr>\n";
	}
	$table .= "</table>\n";
	}

	return $table;
}

sub item {
	my $wnum = shift;
	my $item = $dbh->selectrow_hashref("
		SELECT w.*, tt.brief AS thingtype
		FROM wishes w
		JOIN thingtypes tt ON w.thingtypeid=tt.thingtypeid
		WHERE wnum=$wnum
	");
	
	my $table;
	$table .= "<table>\n";
	$table .= "<tr><th colspan='2'>$item->{brief}</th></tr>\n";
	$table .= "<tr><th>Type:</th><td>$item->{thingtype}</td></tr>\n";
	$table .= "<th>Approx Cost</th><td>" 
			. ($item->{cost} ? sprintf('$%.2f',$item->{cost}) : 'unknown')
			. "</td></tr>\n";
	$table .= "<tr><td colspan='2'>$item->{summary}</td></tr>\n";
	$table .= "</table>\n";

	return $table;
}

## Main Switch

MAINMENU:
for (param('op') || 'list') {
	$_ eq 'list' and do {
		begin_html("Things I Want");
		print wishlist(1);
		last MAINMENU;
	};
	$_ eq 'item' and do {
		my $wnum=param('wnum');
		begin_html("A Thing I Want");
		print item($wnum);
		last MAINMENU;
	};
	begin_html("Things I Want");
	print wishlist(1);
}

end_html();
$dbh->disconnect();
