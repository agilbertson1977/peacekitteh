sub grab_title {
    my $url_re = '((http://|https://|www\.\S{5}).*?)[\].,!\)>"]?($|\s)';

    my ($url) = $_[1] =~ $url_re;

    my $req = HTTP::Request->new(HEAD => $url);
    my $res = $ua->request($req);

    if ($res->code == 405) {
      # Method Not Allowed -- IMDb doesn't like HEAD, but accepts GET,
      # so we trudge along.
    } else {
      return {error => "HEAD: " . $res->status_line} unless $res->is_success;
      if ($res->content_type !~ m~(application|text)/(html|xml|html\+xml)~) {
        return {error => "Unsupported content: ".$res->content_type};
      }
      if ($res->content_length && $res->content_length > 1_000_000) {
        return {error => "Too large: " .$res->content_length};
      }
    }
    $req = HTTP::Request->new(GET => $url);
    $res = $ua->request($req);
    return {private => $res->status_line} unless $res->is_success;

    if ($res->content_type !~ m~(application|text)/(html|xml|html\+xml)~) {
      return {private => "Unsupported content: ".$res->content_type};
    }
    my $html = $res->decoded_content || $res->content;
    my $charset = "iso-8859-1";
    my $ct = $res->header("Content-Type");
    if ($ct && $ct =~ /charset=(\S+)/i) {
      $charset = lc($1);
      $charset =~ s/,$//;
    }
    # open(LOG, ">/tmp/lt.log");
    # print LOG "[", $html, "]", "\n=== enough ===\n";
    # close(LOG);
    $html =~ s~</head>.*~~is;
    # The below replacement is to avoid getting "title" tags in SVG data embedded in <head> tags
    $html =~ s~<title>.*<\\/title>~~is;
    if ($html =~ m~<meta http-equiv="content-type"[^>]*charset='?([^ "]+)~is) {
      $charset = lc($1);
    }
    if ($html =~ m~<title[^>]*>(.*?)</title>~is) {
      my $title = decode_entities($1);
      $title =~ s/\s+/ /g;
      my $orig = $title;
      if (utf8::is_utf8($title) && $charset =~ /^utf-?8$/) {
        # Do nothing
      } elsif ($charset =~ /^iso-?8859-?1$/) {
        # Don't trust it.  Use UTF-8 if it is valid.
        eval { $title = decode("utf8", $title, 1) };
        if ($@ =~ /^utf8/) {
          $title = decode("iso-8859-1", $orig);
        }
      } else {
        eval { $title = decode($charset, $title, 1) };
        if ($@ =~ /^utf8/) {
          print "Error decoding to $charset: '$orig'";
          $title = $orig;
        }
      }
    # max 250 characters long -- arbitrary limit.
    if (length $title > 250) {
        $title = substr($title, 0, 250) . "...";
    }
    $title = "Title => " . $title;
    return {public => $title};
    }
  return {private => "No title"};
};

1;
