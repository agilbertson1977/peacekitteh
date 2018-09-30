use Cwd qw(cwd);
use DBI;
use strict;
use POSIX qw(strftime);

my $driver = "SQLite";
my $database = "tell.db";
my $dsn = "DBI:$driver:dbname:$database";
my $userid = "";
my $password = "";
my $new = -1;

if (-e "dbname:tell.db") {
  # In this case, we must create the database table, so set the $new flag to a true value.
  $new = 0; 
}
my $dbh = DBI->connect($dsn, $userid, $password, {RaiseError => 1 })
   or die $DBI::errstr;

if ($new) {
  my $create_statement = qq(
  CREATE TABLE TELLS (
    SOURCE_NICK TEXT NOT NULL,
    DEST_NICK TEXT NOT NULL,
    MESSAGE TEXT NOT NULL,
    EXPIRES TEXT NOT NULL);
  );
  my $rv = $dbh->do($create_statement);
  if ($rv < 0) {
    return { private => $DBI::errstr};
  } else {
    print "TELLS table created successfully\n";
  }
}

my $pstmt = $dbh->prepare("INSERT INTO TELLS(SOURCE_NICK, DEST_NICK, MESSAGE, EXPIRES) VALUES (?, ?, ?, ?)");

sub tell {
  my ($src, $msg, $settings) = @_;
#  my $src = "amg";
#  my $msg = "test message's";
  my $index = index($msg, " ");
  #print "\$index = $index";
  my $dst = substr($msg,0,$index);
  print "|$dst|\n";
  my $date = strftime "%m-%d-%Y %H:%M:%S.000", localtime;
  $msg =~ s/$dst //;
  $dst =~ s/'/''/g;
  $msg =~ s/'/''/g;
  my $rv = $pstmt->execute($src, $dst, $msg, $date) or die $DBI::errstr;
  print "\$rv = $rv\n";
  if ($rv < 1) {
    return { private => "Attempting to insert $dst:$msg failed " . $DBI::errstr };
  } else {
    return { public => "Okay, I'll tell $dst that if that person is active in the next week" }
  }
  return { public => "Success...maybe?" }; # We should never get here.
}
