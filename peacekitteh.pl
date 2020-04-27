#!/usr/bin/perl

use warnings;
use strict;
use POE;
use POE::Component::IRC;
use File::Slurper qw(read_text);
use File::Slurp;
use JSON::XS qw(decode_json encode_json);
use LWP;
use HTML::Entities;
use Data::Dumper;

my $settings_file = $ARGV[0];
if (! $settings_file ) { die "settings file not passed"; }

my $settings = decode_json(read_text($settings_file));

my $command_char;

#Check that all needed settings are present
if (!exists($settings->{'server'}))   { die "Required settings field 'server' not found"; }
if (!exists($settings->{'port'}))     { 
  print "Setting for port not found, using default of 6667\n"; 
  $settings->{'port'} = 6667; 
}
if (!exists($settings->{'nick'}))     { 
  print "Setting for nick not found, using default of 'PeacePuppy'\n"; 
  $settings->{'nick'} = "PeacePuppy"; 
}
if (!exists($settings->{'username'})) { 
  print "Setting for username not found, using default of 'PeacePuppy'\n";
  $settings->{'username'} = "PeacePuppy"; 
  }
if (!exists($settings->{'owner'}))    { die "Required settings field 'owner' not found"; }
if (!exists($settings->{'channel'}))  { die "Required settings field 'channel' not found"; }
if (!exists($settings->{'command_char'})) { 
  print "Setting for command_char not found, using default of '!'\n"; 
  $settings->{'command_char'} = "!"; 
}

$command_char = $settings->{'command_char'};

my @commands_list;

# load the list of default commands
foreach my $c (@{$settings->{'load_at_startup'}}) {
  print "Loading new module: $c\n";
  my $new_sub_value = read_text($c . "_botmod.pl");
  eval $new_sub_value;
  push (@commands_list, $c);
  
}
# User agent we can pass to other functions
my $ua = LWP::UserAgent->new;
$ua->agent("PeaceKitteh IRC title fetch bot");
$ua->timeout(5);

# Create the component that will represent an IRC network.
my ($irc) = POE::Component::IRC->spawn();

# Create the bot session.  The new() call specifies the events the bot
# knows about and the functions that will handle those events.
# Each of the items that start with \& must be followed by the name
# of a function defined in this program.
POE::Session->create(
  inline_states => {
    _start     => \&bot_start,
    irc_001    => \&on_connect,
    irc_public => \&on_public,
    irc_ctcp_action => \&on_ctcp_action,
    irc_msg => \&on_public,
    #irc_disconnected => \&on_disconnect,
    irc_all => \&show_all,
    irc_error => \&show_error,
    irc_notice => \&show_notice
  },
);

sub show_all {
  print "Hey something happened. This code in show_all.\n";
}

sub show_error {
  print "Hey an error happened. This code in show_error.\n";
  #print "$_\n";
  print Dumper(@_);
}

sub show_notice {
  my ($message) = @_[ARG2];
  print "Received notice: " . $message . "\n";
}

# The bot session has started.  Register this bot with the "magnet"
# IRC component.  Select a nickname.  Connect to a server.
sub bot_start {
  $irc->yield(register => "all");
  $irc->yield(
    connect => {
      Nick     => $settings->{'nick'},
      Username => $settings->{'username'},
      Ircname  => 'Andy\'s pet bot',
      Server   => $settings->{'server'},
      Port     => $settings->{'port'},
      UseSSL   => $settings->{'useSSL'},
      Password => $settings->{'password'}
    }
  );
}

# The bot has successfully connected to a server.  Join a channel.
sub on_connect {
  #my ($kernel, $heap) = @_[KERNEL, HEAP];
  $irc->yield(join => $settings->{'channel'});
  print "join attempted\n";
  #$kernel->post(poco_irc => connect => \%parameters);
}

sub on_public {
  my $ts = scalar localtime;   # for logging
  my ($kernel, $who, $where, $msg) = @_[KERNEL, ARG0, ARG1, ARG2];
  my $nick    = (split /!/, $who)[0];
  my $channel = $where->[0];
  print "[$ts] <$channel:$nick> $msg\n";
  my $aliased = 0;
  foreach my $imply_command (@{$settings->{'implied_command'}}) {
    my $regex = $imply_command->{'regex'};
    my $command = $imply_command->{'command'};
    if (my (@result_data) = $msg =~ $regex) {
      if (test_for_sub($command)) {
        if (substr($msg,0,5) eq "!8ball") {
          print "Looks like an aliased command: $command\n";
          $aliased = 1;
        }
        my $sub = \&{$command};
        my $response = $sub->($nick, $msg, $settings);
        if(exists($response->{'public'})) {
          $irc->yield(privmsg=>$where, $response->{'public'});
        }
        if(exists($response->{'private'})) {
          print $response->{'private'};
          $irc->yield(privmsg=>$nick, $response->{'private'});
        }
        if (exists($response->{'action'})) {
          print "Action triggered: " . $response->{'action'};
          $irc->yield(ctcp => $where => "ACTION " . $response->{'action'});
        }
        if (exists($response->{'error'})) {
	  print "Error response: " . $response->{'error'};
        }
      } elsif (-e $command . "_botmod.pl") {
        print "Loading new module: $command\n";
        my $new_sub_value = read_text($command . "_botmod.pl");
        eval $new_sub_value;
        push (@commands_list, $command);
        my $sub = \&{$command};
        my $response = $sub->($nick, $msg, $settings);
        if(exists($response->{'public'})) {
          $irc->yield(privmsg=>$where, $response->{'public'});
        }
        if(exists($response->{'private'})) {
          print $response->{'private'};
          $irc->yield(privmsg=>$nick, $response->{'private'});
        }
        if(exists($response->{'error'})) {
          print "Error response: " . $response->{'error'};
        }
      } else {
        print "Matched on regex /" . $regex . "/ but no matching module file " . $command . "_botmod.pl\n";
      }
    }
  }
  my $cmd_regex = "^".$command_char."(.+)";
  if ((my ($is_command) = $msg =~ $cmd_regex) && ($aliased == 0)) {    #/^\!(.+)/) # deleted curly brace needs replacing!
    # This is our command prefix, so from here we check if the command exists
    my ($command, $params);
    if ($msg =~ / /) {
      ($command, $params) = $msg =~ /!(\w+) (.+)/;
    } else {
      $command = substr($msg,1);
      $params = "";
    }
    if (!defined($params)) { $params = ""; }
    # 1. If the command is already loaded, execute it.
    if (test_for_sub($command)) {
      eval {
        my $sub = \&{$command};
        my $response = $sub->($nick, $params, $settings);
        if(exists($response->{'public'})) {
          $irc->yield(privmsg=>$where, $response->{'public'});
        }
        if(exists($response->{'private'})) {
          print $response->['private'];
        }
        if (exists($response->{'action'})) {
          print "Action triggered: " . $response->{'action'};
          $irc->yield(ctcp => $where => "ACTION " . $response->{'action'});
        }
      }
    } else {
    # 2. Check if there is a file to load the command, load it, then execute it.
      if (-e $command . "_botmod.pl") {
        print "Loading new module: $command\n";
        my $new_sub_value = read_text($command . "_botmod.pl");
        eval $new_sub_value;
        push (@commands_list, $command);
        my $sub = \&{$command};
        my $response = $sub->($nick, $params, $settings);
        if(exists($response->{'public'})) {
          $irc->yield(privmsg=>$where, $response->{'public'});
        }
        if(exists($response->{'private'})) {
          print $response->['private'];
        }
        if (exists($response->{'action'})) {
          print "Action triggered: " . $response->{'action'};
          $irc->yield(ctcp => $where => "ACTION " . $response->{'action'});
        }

      } else {
    # 3. Complain about a non-command
        $irc->yield(privmsg=>$nick, "I don't know the trick \"$command\"");
      }
    }
  }
}

sub on_ctcp_action {
  my $ts = scalar localtime;   # for logging
  my ($kernel, $who, $where, $msg) = @_[KERNEL, ARG0, ARG1, ARG2];
  my $nick    = (split /!/, $who)[0];
  my $channel = $where->[0];

  print "[$ts] <$channel> $nick $msg\n";
}

$poe_kernel->run();

## Utility routines

# This tests if a subroutine exists. It is used by on_public
# and on_private
sub test_for_sub {
  my ($expr) = @_;
  return eval "defined &$expr";
}

exit 0;
