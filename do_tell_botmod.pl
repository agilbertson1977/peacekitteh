use DBI;

my $driver = "SQLite";
my $database = "tell.db";
my $dsn = "DBI:$driver:dbname:$database";
my $userid = "";
my $password = "";

my $dbh = DBI->connect($dsn, $userid, $password, {RaiseError => 1 })
   or die $DBI::errstr;

sub do_tell {
  my ($nick, $msg, $settings) = @_;
  #my $nick = "amg";
  #my $msg = "this has to be here";
  my $pstmt = $dbh->prepare("SELECT _rowid_, SOURCE_NICK, DEST_NICK, MESSAGE, EXPIRES FROM TELLS WHERE DEST_NICK = ?;");
  my $dstmt = $dbh->prepare("DELETE FROM TELLS WHERE _rowid_ = ?;");
  my $rv = $pstmt->execute($nick);
  my $all_msgs = "";
  if (my @row = $pstmt->fetchrow_array() ) {
    my $id = $row[0];
    my $source = $row[1];
    my $this_msg = $row[3];
    $all_msgs .= "$source said \"$this_msg\"\n";
    $dstmt->execute($id);
  }
  
  if ( length ($all_msgs) > 0) {
    return {public=>"", private=>"$all_msgs"};
  } else { 
    return {};
  };
}

1;
