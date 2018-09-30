sub list_commands {
  my $retval = "Commands loaded: ";
  foreach my $this_sub (@commands_list) {
    $retval = $retval . ", " .$this_sub ;
  }
  $retval =~ s/ , / /;
  return $retval;
}

1;
