#!/usr/bin/perl -CS
# FIXME: extract "MENU:" and "SALAT:", because they are located in heading
#   tags and not in table cells

use strict;
use warnings;
use utf8;
use LWP::UserAgent;

my $vflag = 0; # verbose
my $lflag = 0; # lowercase menu?
my $tflag = 0; # print restaurant name?

sub handle_cli_args {
  while ($#ARGV >= 0) {
    if ($ARGV[0] eq "-h" || $ARGV[0] eq "--help") {
      print STDERR
      "Displays Pod Loubim's daily menu.\n",
      "Usage: pod-loubim.pl [-h|--help]\n",
      "       pod-loubim.pl [-v|--verbose] [-r|--print-restaurant-name]\n\n",
      "  -h|--help                     prints help message\n",
      "  -v|--verbose                  enables verbose mode\n",
      "  -t|--print-restaurant-name    whether or not to display 'Restaurace",
      " Pod Loubim' header when printing the menu\n";
      exit 0;
    } elsif ($ARGV[0] eq "-v" || $ARGV[0] eq "--verbose") {
      $vflag = 1;
      print STDERR "Verbose mode on.\n";
    } elsif ($ARGV[0] eq "-t" || $ARGV[0] eq "--print-restaurant-name") {
      $tflag = 1;
      print STDERR "Will print restaurant name at the beginning of the menu.\n"
        if $vflag;
    } elsif ($ARGV[0] eq "-l" || $ARGV[0] eq "--lower-case") {
      $lflag = 1;
      print STDERR "Result will be converted to lower case before being",
      " printed.\n" if $vflag;
    } else {
      print STDERR "Unknown command line argument '$ARGV[0]'.\n" if $vflag;
    }
    shift @ARGV;
  }
}

sub isweekend {
  my $day = (split(' ', localtime))[0];
  my @weekend = ("sat", "sun");
  my $result = grep{$_ eq lc($day)} @weekend;
  print STDERR $result ? "It's weekend :(" : "It isn't weekend :)", ".\n"
    if $vflag;
  return $result;
}

sub fetch_site {
  my %links = (
    weekday => 'http://www.podloubim.com/menu/',
    weekend => 'http://www.podloubim.com/vikendove-menu/'
  );

  my $link = isweekend() ? $links{"weekend"} : $links{"weekday"};

  print STDERR "Fetching '$link'.\n" if $vflag;
  my $ua = LWP::UserAgent->new;
  $ua->timeout(10);
  $ua->env_proxy;

  my $response = $ua->get($link);
  $response->is_success or die "Couldn't fetch menu.\n";
  print STDERR "Successfully fetched menu.\n" if $vflag;
  return $response->decoded_content;
}

sub obtain_menu {
  my $i = 0;
  my $html = fetch_site();
  my $text = "";

  foreach $a (split('\n', $html)) {
    $a =~ s/^\s+|\s+$//g; # trim leading and ending whitespace
    $a =~ s/&nbsp;|&gt;//g; # remove all `&nbsp;`, `&gt`;
    if ($a =~ /^\S*$/) { # skip all empty lines
      next;
    }
    $a =~ s/<td[^>]*><\/td>//g; # remove all empty tags
    unless ($a =~ /<\/td\>$/g || $a =~ /MENU/ || $a =~ /SALÁT/) { # menu is contained inside a table, so if 
      next;                      # table cell tag isn't found, then skip
    }
    $a =~ s|<.+?>||g; # remove all html tags
    $a =~ s/^\s+|\s+$//g; # trim leading and ending whitespace
    $text .= $a . "\n";
  }

  $tflag && print "Restaurace Pod Loubím\n";

  my @by_nl = split('\n', $text);
  my $result = "";
  foreach $a (@by_nl[1..($#by_nl - 1)]) { # remove misc info
    # join price with next line (=meal name)
    if ($a =~ /^\d+/) {
      $result .= "$a ";
    } else {
      if ($lflag) {
        $result .= lc($a) . "\n";
      } else {
        $result .= "$a\n";
      }
    }
  }
  print STDERR "Menu building is done.\n" if $vflag;
  return $result;
}

sub print_menu {
  print obtain_menu();
}

handle_cli_args();
print_menu();

