sub unload {
  my ($nick, $params, $settings) = @_;
  my $resp = unload_this($params);
  return {public=>$resp};
}

sub unload_this {
  my ($sub) = @_;
  if (eval "defined &$sub") {
    # Undefine the subroutine itself
    undef &$sub;
    #remove it from the list of loaded commands
    my $index = 0;
    $index++ until $commands_list[$index] eq $sub;
    splice (@commands_list, $index, 1);
    # return success!
    return "Unloaded $sub";
  } else {
    return "$sub not defined";
  }
}


1;
