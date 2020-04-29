sub rot13() {
  my $phrase = $_[1];
  $phrase =~ tr[a-zA-Z][n-za-mN-ZA-M];
  my $result = $phrase;
  
  return {public=>$result};
}


1;
