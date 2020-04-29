sub c2f() {
  my ($nick, $msg, $settings) = @_;
  my ($c2f)  = $msg =~ /([-\d]+)/; # Strips off non-numeric characters except minus sign
  if ($c2f < -273.15) {
    return { public => "I'm your absolute hero as long as your temp's above absolute zero" };
  }
  my $f_temp = ($c2f * 1.8) + 32;
  $f_temp = sprintf("%.1f", $f_temp);
  return { public => "$c2f C = $f_temp F" };
}

1;
