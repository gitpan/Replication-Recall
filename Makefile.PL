# -*-cperl-*-
#
# Replication::Recall - Perl Interface to Recall.
# Copyright (c) 2000 Ashish Gulhati <hash@netropolis.org>
#
# All rights reserved. This code is free software; you can
# redistribute it and/or modify it under the same terms as Perl
# itself.
#
# $Id: Makefile.PL,v 1.6 2001/05/27 09:00:50 cvs Exp $

( $VERSION ) = '$Revision: 1.6 $' =~ /\s+([\d\.]+)/;

use ExtUtils::MakeMaker;

# Uncomment and change this line if I fail to find recall
# $recalldir = '/root/Work/recall';

unless (defined $recalldir) {
  for $dir ('..', '../..') {
    $recalldir = $dir, last if -e "$dir/recall/recall.h";
  }
}

$recalldir = get_recall() unless $recalldir;  

if ($recalldir) {
  $recall_version = `cd $recalldir; pwd`;
  $recall_version =~ /.*recall-([\d\.]+).*/; $recall_version = $1;
  die "Could not find recall build directory, please edit Makefile.PL.\n"
    unless -e "$recalldir/Precall/precall.h";
  print "Found recall ($recall_version) build directory in $recalldir\n";
} 
else {
  die "Could not find recall build directory, please edit Makefile.PL.\n";
}

my $installdir = `pwd`; chomp $installdir;

system ("cd $recalldir; ./configure --enable-pth; make");
system ("cd $recalldir/Precall; patch < $installdir/patch; rm -f *_wrap.c; make clean; make")
  and die "Make failed.\n";
system ("cd $recalldir/Precall; sed -e 's/ Server/ Replication::Recall::Server/g' < Server.pm > Server.fix;");
system ("cd $recalldir/Precall; sed -e 's/ Client/ Replication::Recall::Client/g' < Client.pm > Client.fix;");
system ("cd $recalldir/Precall; mv Server.fix Server.pm; mv Client.fix Client.pm");
system ("cd $recalldir/Precall; install -m 644 -o root -g root .libs/*.so Server.pm Client.pm $installdir/.libs");
system ("cd $recalldir; install -m 644 -o root -g root recall/.libs/* Simple/.libs/* Containers/.libs/* /usr/lib");

&WriteMakefile(
	       NAME	     => 'Replication::Recall',
	       ABSTRACT      => 'Perl Interface to Recall.',
	       AUTHOR        => 'Ashish Gulhati <hash@netropolis.org>',
	       VERSION_FROM  => 'Makefile.PL',
	       PM            => { '.libs/Server.pm' => '$(INST_LIBDIR)/Recall/Server.pm',
				  '.libs/Client.pm' => '$(INST_LIBDIR)/Recall/Client.pm',
				  '.libs/Server.so' => '$(INST_ARCHAUTODIR)/Server/Server.so',
				  '.libs/Client.so' => '$(INST_ARCHAUTODIR)/Client/Client.so',
				}
	      );

sub get_recall {
  my $url = 'http://download.sourceforge.net/recall/';
  print "\nDid not find Recall build directory around.\n\n";

  print "I can download and install Recall for you automatically.
There are several other pieces of software that are needed
for Recall to compile properly. You'll have to install these
youself:

  libtcl -  http://sourceforge.net/projects/tcl
  libtk  -  http://sourceforge.net/projects/tktoolkit
  Pth    -  http://www.gnu.org/software/pth
  SWIG   -  http://www.swig.org/

Please make sure you have these packages installed before saying 'y'
to the next question, or your Recall build will probably fail. 

If your build fails because of missing packages not listed here,
please email dbd-recall\@netropolis.org so that I can add them above.\n\n";

  if (-t STDIN and (-t STDOUT or -p STDOUT)) { # Interactive
    $| = 1;
    print "Do you want me to fetch Recall automatically? ";
    $ans = <>;
    if ($ans !~ /^y/i) {
      print "Well, as you wish... I give up...\n";
      return;
    }
  } 
  else {
    print "Non-interactive session, autofetching Recall...\n"
  }

  print "Getting Recall from $url\n";
  eval { require LWP::UserAgent }
    or die "You do not have LWP installed, cannot download, exiting...";

  my $ua = new LWP::UserAgent;
  my $request = new HTTP::Request('GET', $url);
  my $response = $ua->request($request);
  $response->is_success
    or die "Error accessing $url, exiting...";
  
  my $ls = $response->content();
  $ls =~ s/\"recall-([\d\.]+)(\.[^\"]+)\"/{ $version{$1} = "recall-$1$2" }/eg;
  foreach (sort { $a <=> $b } keys %version) {
    $download = "$version{$_}";
  }

  print "Downloading $url/$download\n";
  $request = new HTTP::Request('GET', "$url/$download");
  $response = $ua->request($request, "$download");
  $response->is_success
    or die "Error downloading $download, exiting...";

  $dir = `tar tzvf $download | head -1`; $dir =~ /.*?(\S+)\/\s*$/; 
  $dir = `pwd`; chomp $dir; $dir .= "/$1";
  system ("tar xzf $download");
  return $dir;
} 
