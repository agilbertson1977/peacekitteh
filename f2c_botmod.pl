sub f2c() {
  my ($nick, $msg, $settings) = @_;
  my ($f2c)  = $msg =~ /([-\d]+)/; # Strips off non-numeric characters except minus sign
  if ($f2c < -459.67) {
    return { public => "Hey, that's below absolute zero!" };
  }
  my $c_temp = ($f2c - 32) / 1.8;
  $c_temp = sprintf("%.1f", $c_temp);
  return { public => "$f2c F = $c_temp C" };
}

1;
