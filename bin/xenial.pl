#!/usr/bin/perl 

use strict;
use DBI;
use CGI qw/:all/;

use vars qw($dbh $current_unum $current_realname $rev);

$rev = '$Revision: 1.7 $';
$rev =~ s/(\$| +$|^ +)//g;

$dbh=DBI->connect('dbi:Pg:dbname=xmas', 'samael', undef) or print 'oops!';

($current_unum, $current_realname) =
	$dbh->selectrow_array("SELECT unum, realname FROM people WHERE uname='$ENV{REMOTE_USER}'");

sub user_updated {
	my $unum = shift;
	$dbh->do("UPDATE people SET lastupdate=current_date WHERE unum=?", undef, $unum);
}

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
			div#footer { text-align: center }
			h3 { margin-bottom: 0; }
			h4 { margin-top: .1em; margin-left: .5em }
			table { width: 95% }
			th { width: 25% }
			caption { font-weight: bold; text-align: left; }
		</style>
	</head>
	<body>
	<div id='header'>
		<h1>Christmas Wishlists</h1>
		<h2>$title</h2>
		<div id='userid'>you're logged in as $current_realname</div>
	</div>
EOH
}

sub end_html {
	print "<div id='footer'><a href='?op=about'>Xenial D1</a> $rev</div>\n";
	print "</body>\n</html>\n";
}

## Database Operations

sub sql_meta { $_[0] =~ s/'/''/g; return $_[0]; }

sub can_see_bought {
	my ($unum, $item) = @_;
	
	if (param('cheat')) { return 1; }
	if (($item->{unum} == $unum) and ($item->{buyer_unum} != $unum)) { return 0; }
	return 1;
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

	return "<h3>this wishlist is empty!</h3>\n" unless @$tts;

	foreach my $tt (@$tts) {
		$table .= "<h3>$tt->[0]</h3>\n";

		my $sth = $dbh->prepare("
			SELECT * 
			FROM wishes
			WHERE unum=$unum AND thingtypeid=$tt->[1]
			ORDER BY thingtypeid, brief
		");

		$sth->execute;

		$table .= "<table>\n";
		$table .= "<tr><th style='width:10%'>Bought?</th><th style='width:80%'>Item</th><th>Approx Cost</th></tr>\n";
		while (my $row = $sth->fetchrow_hashref) {
			$table .= 
				"\t<tr><td style='text-align:center'>" .
				#((($unum == $current_unum) and not ($row->{buyer_unum} == $current_unum))
				(can_see_bought($current_unum,$row)
					? ($row->{bought} ? 'yes' : 'no') : '??' ) .
				"<td><a href='?op=item&amp;wnum=$row->{wnum}'>$row->{brief}</a></td><td>" .
				($row->{cost} ? sprintf('$%.2f',$row->{cost}) : 'unknown') .
				"</td></tr>\n";
		}
		$table .= "</table>\n";
	}

	return $table;
}

sub boughtlist {
	my $table;

	my $fors = $dbh->selectall_arrayref("
		SELECT unum, realname
		FROM people
		WHERE unum IN
			(SELECT unum FROM wishes WHERE buyer_unum=$current_unum)
		ORDER BY realname
	");

	return "<h3>you haven't bought anything</h3>\n" unless @$fors;

	foreach my $for (@$fors) {
		my $sth = $dbh->prepare("
			SELECT w.*
			FROM wishes w
			WHERE buyer_unum=$current_unum AND unum=$for->[0]
			ORDER BY w.brief
		");

		$sth->execute;

		$table .= "<table>\n";
		$table .= "<caption>$for->[1]</caption>\n";
		$table .= "<tr><th style='width:80%'>Item</th><th>Approx Cost</th></tr>\n";
		while (my $row = $sth->fetchrow_hashref) {
			$table .= 
				"\t<tr>" .
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
	$table .= "<tr><th>Bought?</th><td>"
		#. ((($item->{unum} == $current_unum) and not ($item->{buyer_unum} == $current_unum))
		. (can_see_bought($current_unum,$item)
			? ($item->{bought} ? un2rn($item->{buyer_unum}) : 'no') : '??' )
		. "</td></tr>\n";
	$table .= "<th>Approx Cost</th><td>" 
			. ($item->{cost} ? sprintf('$%.2f',$item->{cost}) : 'unknown')
			. "</td></tr>\n";
	$table .= "<tr><td colspan='2'>$item->{summary}</td></tr>\n";
	unless ($item->{bought} or ($item->{unum} == $current_unum)) {
		$table .= "<tr><td colspan='2' style='background-color:white;border:none;text-align:center'>\n";
		$table .= "<form method='post'>\n";
		$table .= "<input type='hidden' name='wnum' value='$item->{wnum}' />\n";
		$table .= "<input type='hidden' name='op' value='buy' />\n";
		$table .= "<input type='submit' value='Mark as Purchased' />\n</form>\n";
		$table .= "</td></tr>\n";
	}
	if ($item->{buyer_unum} == $current_unum) {
		$table .= "<tr><td colspan='2' style='background-color:white;border:none;text-align:center'>\n";
		$table .= "<form method='post'>\n";
		$table .= "<input type='hidden' name='wnum' value='$item->{wnum}' />\n";
		$table .= "<input type='hidden' name='op' value='unbuy' />\n";
		$table .= "<input type='submit' value='Mark as NOT Purchased' />\n</form>\n";
		$table .= "</td></tr>\n";
	}
	$table .= "</table>\n";

	$table .= "<ul>";
	if ($item->{unum} == $current_unum) { 
		$table .= "<li><a href='?op=delete&amp;wnum=$wnum'>delete item</a></li>\n";
		$table .= "<li><a href='?op=edit&amp;wnum=$wnum'>edit item</a></li>\n";
	}
	$table .= "<li><a href='?op=list&amp;unum=$item->{unum}'>back to the wishlist</a></li>\n";
	$table .= "</ul>";

	return $table;
}

sub itemform {
	my ($brief, $summ, $cost, $wnum) = map { escapeHTML $_ } @_;
	
	my $wtt;
	if (defined $wnum) {
		$wtt = $dbh->selectrow_array("
			SELECT thingtypeid FROM wishes WHERE wnum=$wnum
		");
	}
	my $tt = $dbh->selectall_arrayref("
		SELECT thingtypeid, brief FROM thingtypes ORDER BY brief
	");
	my $ttselect  = "<select name='thingtypeid'>";
	foreach my $type (@$tt) {
	   $ttselect .= "\n\t<option value='$type->[0]' ";
	   $ttselect .= "selected='selected'" if ($type->[0] eq $wtt);
	   $ttselect .= ">$type->[1]</option>\n";
	}
	$ttselect .= "</select>";

	my $form;
	$form = <<EOH;
<form method='post'>
	<blockquote><strong>NOTE:</strong>
		Cost must be a whole number less than about 32,000.  Let's stick to
		American dollars, ok?  Leave it blank for an unknown or undefined cost.
		Oh, and make sure you put in both a short <em>and</em> long description!
	</blockquote>
	<table>
		<tr><th>Item Type</th><td>$ttselect</td></tr>
		<tr><th>Short Description</th><td><input size='75' maxlength='75' name='brief' value="$brief"/></td></tr>
		<tr><th>Long Description</th><td><textarea rows='5' style='width:100%' name='summary'>$summ</textarea></td></tr>
		<tr><th>Approx Cost</th><td><input size='75' maxlength='10' name='cost' value="$cost"/></td></tr>
		<tr><td colspan='2' style='background-color:white;border:none;text-align:center'>
			<input type='hidden' value='$wnum' name='wnum' />
			<input type='hidden' value='additemnow' name='op' />
			<input type='submit' value='Update Item' />
		</td></tr>
	</table>
</form>
EOH
}


sub userlist {
	my $unum = shift;
	my $sth = $dbh->prepare("
		SELECT p.*, (SELECT COUNT(*) FROM wishes w WHERE p.unum=w.unum) AS numw
		FROM people p
		WHERE lastupdate IS NOT NULL
		ORDER BY realname
	");
	
	my $table;
	$table .= "<table>\n";
	$table .= "<caption>users without updates since 2003 not listed</caption>\n";
	$table .= "<tr><th style='width:85%'>Person</th><th>Updated</th><th># Items</th></tr>\n";
	$sth->execute;
	while (my $row = $sth->fetchrow_hashref) {
		$table .= "\t<tr><td>";
		$table .= "<a href='?op=list&amp;unum=$row->{unum}'>" if $row->{numw};
		$table .= "$row->{realname}";
		$table .= "</a>" if $row->{numw};
		$table .= "</td><td style='text-align:center'>"
		       . ($row->{lastupdate} ? $row->{lastupdate} : '(unknown)')
		       . "</td>\n";
		$table .= "<td style='text-align:right'>$row->{numw}</td></tr>\n";
	}
	$table .= "</table>\n";

	return $table;
}

sub un2rn {
	my $unum = shift;
	my ($rn) = $dbh->selectrow_array("SELECT realname FROM people WHERE unum=$unum");
	return $rn;
}

## Main Switch

sub mainmenu {
	print "<ul>\n\t",
		"<li><a href='?op=list&amp;unum=$current_unum'>Your List</a></li>\n",
		"<li><a href='?op=people'>Other People's Lists</a></li>\n",
		"<li><a href='?op=bought'>Things You've Bought</a></li>\n",
		"<li><a href='/'>Main Menu</a></li>\n",
		"</ul>\n";
}

MAINMENU:
for (param('op') || '') {
	$_ eq 'additem' and do {
		begin_html("Add an Item");
		print itemform(param('brief'),param('summary'),param('cost'));
		mainmenu;
		last MAINMENU;
	};
	$_ eq 'additemnow' and do {
		param('op','list');
		param('unum',$current_unum);

		my $wnum  = param('wnum');

		my $tt    = param('thingtypeid');
		my $brief = param('brief');
		my $summ  = param('summary');
		my $cost  = param('cost');
		   $cost  =~ s/^\$//;
 		   undef $cost unless $cost =~ /^\d+$/;

		#unless ($brief and $summ and ($cost =~ /^\d+(?:\.\d+)?$/)) {
		unless ($brief and $summ) {
			param('op','additem');
		} elsif ($wnum) {
			$tt    = $dbh->quote($tt);
			$brief = $dbh->quote($brief);
			$summ  = $dbh->quote($summ);
			$cost  = $dbh->quote($cost);
			$dbh->do("
				UPDATE wishes
				SET brief=$brief, summary=$summ, cost=$cost, thingtypeid=$tt
				WHERE wnum=$wnum
			");
			user_updated($current_unum);
		} else {
			$tt    = $dbh->quote($tt);
			$brief = $dbh->quote($brief);
			$summ  = $dbh->quote($summ);
			$cost  = $dbh->quote($cost);
			$dbh->do("
				INSERT INTO wishes
				(thingtypeid, unum, brief, summary, cost)
				VALUES
				($tt, $current_unum, $brief, $summ, $cost)
			");
			user_updated($current_unum);
		}
		
		goto MAINMENU;
	};
	$_ eq 'buy' and do {
		my $wnum=param('wnum');
		$dbh->do("UPDATE wishes SET bought=now(), buyer_unum=$current_unum WHERE wnum=$wnum");
		param('op','item');
		goto MAINMENU;
	};
	$_ eq 'unbuy' and do {
		my $wnum=param('wnum');
		$dbh->do("UPDATE wishes SET bought=NULL, buyer_unum=NULL WHERE wnum=$wnum");
		param('op','item');
		goto MAINMENU;
	};
	$_ eq 'delete' and do {
		my $wnum=param('wnum');
		$dbh->do("DELETE FROM wishes WHERE wnum=$wnum AND unum=$current_unum");
		param('op','list');
		param('unum',$current_unum);
		user_updated($current_unum);
		goto MAINMENU;
	};
	$_ eq 'edit' and do {
		begin_html("Edit an Item");
		my $wnum = param('wnum');
		my $item = $dbh->selectrow_hashref("
			SELECT * 
			FROM wishes
			WHERE wnum=$wnum
		");
		print itemform($item->{brief},$item->{summary},$item->{cost},$item->{wnum});
		mainmenu;
		last MAINMENU;
	};
	$_ eq 'list' and do {
		my $unum=param('unum');
		begin_html("Stuff Wanted");
		print "<ul><li><a href='?op=additem'>add an item</a></li></ul>\n" if ($unum == $current_unum);
		print wishlist($unum);
		mainmenu;
		last MAINMENU;
	};
	$_ eq 'bought' and do {
		begin_html("Stuff You Bought");
		print boughtlist;
		mainmenu;
		last MAINMENU;
	};
	$_ eq 'item' and do {
		my $wnum=param('wnum');
		begin_html("Item Detail");
		print item($wnum);
		mainmenu;
		last MAINMENU;
	};
	$_ eq 'people' and do {
		begin_html("People Who Want Stuff");
		print userlist();
		mainmenu;
		last MAINMENU;
	};
	$_ eq 'about' and do {
		begin_html("About this Software");
		print <<EOH;
	<h3>Xenial D1</h3>
	<h4>$rev</h4>
	<p>
		This is Xenial, cupidity management software written by <a
		href='http://rjbs.manxome.org/'>rjbs</a>.  It was begun in 2003-09 and
		received an hour of work here and there.  It will be released under the
		GPL when it has reached a reasonable level of security, stability, and
		general usefulness.
	</p>
EOH
		mainmenu;
		last MAINMENU;
	};
	begin_html("Merry Christmas");
	mainmenu;
}

end_html();
$dbh->disconnect();
