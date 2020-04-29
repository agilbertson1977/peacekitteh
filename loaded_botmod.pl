sub loaded {
  my $list = "";
  my $c = "";
  foreach $c (@commands_list) {
    $list .= $c . " ";
  }
  return { public=>"Loaded commands: " . $list };
}

1;
