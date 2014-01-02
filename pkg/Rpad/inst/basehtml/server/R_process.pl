#!/usr/bin/perl -w
#!c:/apps/perl/bin/perl.exe 

# The following line is a test script to see if it works.
# http://localhost/Rpad/server/R_process.pl?&ID=/tmp/ddNTlmHSvWZF&command=R_commands&R_commands=print('hello')

use strict;
use warnings;

use Statistics::R;
use Linux::Inotify2;
use File::Path qw(remove_tree);
use Time::Out qw(timeout);
use CGI qw/:standard send_http_header/;

# chdir to temporary directory
#my $Rpad_ID = '/home/jedick/tmp/rtmp';  ## testing
my $Rpad_ID = param('ID');
chomp($Rpad_ID);
chdir $Rpad_ID;

#my $p_command = 'login';  ## testing
#my $p_command = 'R_commands';  ## testing
my $p_command = param('command');
chomp $p_command ;

my @output_value = "";

if ($p_command eq 'login') {
  
  # fork this process
  my $pid = fork();
  die "Fork failed: $!" if !defined $pid;

  if ($pid == 0) {

    # do this in the child
    open STDOUT, ">/dev/null";
    open STDERR, ">/dev/null";

    # start R and load Rpad
    my $R = "";
    sub startR{
      $R = Statistics::R->new( shared => 1 );
      $R->start();
      $R->run(q`require(Rpad)`); 
      # from ?stop: "don't stop on stop(.)"
      # this way the R process behaves more like the interactive session - it isn't halted when an error occurs
      # but errors still hang up the perl so we can't use it...
      #$R->run(q`options(error = expression(NULL))`); 
    }
    &startR();

    # subroutine to clean up temporary directory
    sub cleanup{
      chdir ".." or die "Failed to go to parent directory: $!";
      remove_tree($Rpad_ID);
    }

    # set up inotify watch on temporary directory
    my $inotify = new Linux::Inotify2
      or die "Unable to create new inotify object: $!";
    $inotify->watch("$Rpad_ID", IN_CLOSE_WRITE, sub {
      my $event = shift;
      my $name = $event->name;
      # run the input.R when it appears
      if ( $name eq "input.R" ) {
        # read R command from the input file
        # $R->run_from_file would be cleaner, but it's a source(), so doesn't echo like the interactive session
        #my $output_value = eval { $R->run_from_file($name); };
        open(my $fh, '<', $name) or die "Could not open file '$name' $!";
        # Slurp into a scalar
        my $R_commands; 
          { local $/ = undef; $R_commands = <$fh>; }
        close $fh;
        my $output_value = eval { $R->run($R_commands); };
        
        # convert any errors from R into the output text
        if ( $@ ) {
          $output_value = "$@";
          # remove first 3 lines for a cleaner error message
          $output_value =~ s/^(?:.*\n){1,3}//;
          # restart R (probably should test if really did stop)
          &startR();
        }
        # save output to file
        my $filename = "output";
        open($fh, '>', $filename) or die "Could not open file '$filename' $!";
        print $fh "$output_value\n";
        close $fh;
      }
      elsif ( $name eq "theend" ) {
        &cleanup();
        die "watch process terminated by request";
      }
    }) or die "watch creation failed: $!";

    # put a limit of 10 minutes on our process
    timeout 600 => sub {
      1 while $inotify->poll;
    } ;
    if ($@){
      &cleanup();
      # operation timed-out
      die "watch process reached timeout limit";
    }
  }

  # wait a second for R to start and to begin watch of
  # input file before any R commands are sent
  sleep 1;

}

elsif ($p_command eq 'logout') {

  # this creates a file signalling the end of Perl child process
  my $filename = "theend";
  open(my $fh, '>', $filename) or die "Could not open file '$filename' $!";
  print $fh "\n";
  close $fh;

}

elsif ($p_command eq 'R_commands') {

  # process R commands
  #my $R_commands = "print('abcxyz') \n\ndate()\n\n  \n    Sys.sleep(10)";  ## testing
  my $R_commands = param('R_commands');
  # replace non-breaking spaces with regular spaces
  $R_commands =~ s/\xA0/ /g;
  
  # save commands to the input file that is being watched by the child process
  my $filename = "input.R";
  open(my $fh, '>', $filename) or die "Could not open file '$filename' $!";
  # split the string of commands on newlines
  my @lines = split /\n/, $R_commands;
  foreach my $line (@lines) {
    # remove the trailing space(s), which seem to cause problems
    $line =~ s/\ *$//g;
    # blank lines also cause problems; remove them too
    if ( $line ne "" ) {
      print $fh "$line\n";
    }
  }
  close $fh;

  # set up inotify watch to grab output file
  my $inotify = new Linux::Inotify2
    or die "Unable to create new inotify object: $!";
  $inotify->watch("$Rpad_ID", IN_CLOSE_WRITE, sub {
    my $event = shift;
    my $name = $event->name;
    if ( $name eq "output" ) {
      # read contents of output file into output_value
      my $filename = "output";
      open(my $fh, '<', $filename) or die "Could not open file '$filename' $!";
      @output_value=<$fh>;
      close $fh;
    }
  }) or die "watch creation failed: $!";

  # interrupt the watch if it runs for more than 10 seconds.
  timeout 10 => sub {
    $inotify->poll;
  } ;
  if ($@){
    # operation timed-out
    @output_value = "10 seconds passed with no output from R ... back to you!\n";
  }

}

CGI::initialize_globals();
print header;
print @output_value;
