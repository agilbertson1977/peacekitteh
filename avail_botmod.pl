sub avail() {
  my $settings = $_[0];
  opendir(DIR, ".");
  my @files = grep(/_botmod\.pl$/,readdir(DIR));
  closedir(DIR);
  my $list = "";
  foreach my $c (@files) {
    $c =~ s/_botmod.pl//;
    $list .= $c . " ";
  }
  return { public=>"Use caution! These may incompletely or incorrectly implemented, which could cause the bot to crash! Commands available: " . $list };
}

1;
