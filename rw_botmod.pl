sub rw () {
  my $src = $_[0];
  if ($src eq "xles") { return {public=>"boobs"}; }
  my $settings = $_[1];
  my $ua;
  my $url = "https://random-word-api.herokuapp.com/word?number=1";
  unless (defined $ua) {
    $ua = LWP::UserAgent->new;
    $ua->agent("PeaceKitteh IRC title fetch bot");
    $ua->timeout(5);
  }
  my $req = HTTP::Request->new(GET => $url);
  my $res = $ua->request($req);
  my $content = $res->content;
  #print $content . "\n";
  $content =~ s/\[\"//;
  $content =~ s/\"\]//;
  return { public=>$content };
}

1;
