sub xkcd37 {
  my $msg = $_[1];
  $msg =~ s/-ass / ass-/g;
  return { public=>$msg };
}

1;

