sub weather() {
  if (!exists($settings->{'openweatherapi'})) {
    return {private=>"OpenWeather API key not found"};
  }
  my $loc = $_[1];
  my $settings = $_[2];
  #print Dumper(@_);
  $loc =~ s/ //g;
  my $api_key = $settings->{'openweatherapi'};
  my $ua;
  my $url = "https://api.openweathermap.org/data/2.5/weather?APPID=$api_key&q=$loc";
  print "Fetching $url for weather data\n";
  unless (defined $ua) {
    $ua = LWP::UserAgent->new;
    $ua->agent("PeaceKitteh IRC title fetch bot");
    $ua->timeout(5);
  }
  my $req = HTTP::Request->new(GET => $url);
  my $res = $ua->request($req);
  my $content = $res->content;
  #print $content;
  my $weather = decode_json($content);
  if ($weather->{'cod'} == 200) {
    my $response = "Current conditions for " . $weather->{'name'} . ": ";
    $response .= $weather->{'weather'}[0]->{'description'} . ", ";
    my $country = $weather->{'sys'}->{'country'};
    my $curr_temp_k = $weather->{'main'}->{'temp'};
    my $high_temp_k = $weather->{'main'}->{'temp_max'};
    my $low_temp_k =  $weather->{'main'}->{'temp_min'};
    my $curr_temp_c = $curr_temp_k - 273;
    my $curr_temp_f = ($curr_temp_c * 1.8) + 32;
    if ($country eq "US") {
      $response .= sprintf("%d", $curr_temp_f) . "°F (" . sprintf("%d", $curr_temp_c) . "°C), ";
    } else {
      $response .= sprintf("%d", $curr_temp_c) . "°C (" . sprintf("%d", $curr_temp_f) . "°F), ";
    }
    return {public=>$response};
  } else {
    if (exists $weather->{'message'}) {
      return {public=>"Uh-oh. Bad response from open weather API: " . $weather->{'cod'} . "; " . $weather->{'message'}};
    }
  }
}


1;
