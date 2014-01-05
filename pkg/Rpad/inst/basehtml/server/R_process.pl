#!/usr/bin/perl
#!c:/apps/perl/bin/perl.exe 

# The following line is a test script to see if it works.
# http://localhost/Rpad/server/R_process.pl?&ID=/tmp/ddNTlmHSvWZF&command=R_commands&R_commands=print('hello')

use strict;
use warnings;

use Statistics::R;
use Linux::Inotify2;
use File::Path qw(remove_tree);
use CGI qw/:standard send_http_header/;
use Time::HiRes qw(time sleep);

CGI::initialize_globals();

# get name of temporary directory
#my $Rpad_ID = '/home/jedick/tmp/rtmp';  ## testing
my $Rpad_ID = param('ID');
chomp($Rpad_ID);

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
    
    # TODO: http://perl.apache.org/docs/1.0/guide/performance.html#toc_Freeing_the_Parent_Process
    # (and protect from zombies)
    # do this in the child
    open STDOUT, ">/dev/null";
    open STDERR, ">/dev/null";

    # start R and load Rpad
    my $R = "";
    sub startR{
      chdir $Rpad_ID;
      $R = Statistics::R->new( shared => 1 );
      $R->start();
      $R->run(q`require(Rpad)`); 
      # from ?stop: "don't stop on stop(.)"
      # this way the R process behaves more like the interactive session - it isn't halted when an error occurs
      # but errors still hang up the perl so we can't use it...
      #$R->run(q`options(error = expression(NULL))`); 
      chdir ".." or die "Failed to go to parent directory: $!";
    }
    &startR();

    # subroutine to clean up temporary directory
    # and exit child process
    sub all_done{
      remove_tree($Rpad_ID);
      # we do want the interpreter to quit (so the associated R process gets killed)
      # therefore we can't use exit() or die() because they get overriden in mod_perl
      # http://perl.apache.org/docs/1.0/guide/porting.html#toc_Terminating_requests_and_processes__the_exit___and_child_terminate___functions
      # http://perl.apache.org/docs/1.0/guide/performance.html#toc_Forking_and_Executing_Subprocesses_from_mod_perl
      CORE::exit(0);
    }

    # set up inotify watch on temporary directory
    my $inotify = new Linux::Inotify2
      or die "Unable to create new inotify object: $!";
    $inotify->watch($Rpad_ID, IN_CLOSE_WRITE, sub {
      my $event = shift;
      my $name = $event->name;
      my $fullname = $event->fullname;
      # run the input.R when it appears
      if ( $name eq "input.R" ) {
        # read R command from the input file
        # $R->run_from_file would be cleaner, but it's a source(), so doesn't echo like the interactive session
        #my $output_value = eval { $R->run_from_file($name); };
        # TODO: use IO::File to avoid file descriptor leakage
        # http://perl.apache.org/docs/1.0/guide/porting.html#toc_Filehandlers_and_locks_leakages
        open(my $fh, '<', $fullname) or die "Could not open file '$fullname' $!";
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
        my $filename = $Rpad_ID . "/output";
        open($fh, '>', $filename) or die "Could not open file '$filename' $!";
        print $fh "$output_value\n";
        close $fh;
      }
      elsif ( $name eq "theend" ) {
        &all_done();
      }
    }) or die "watch creation failed: $!";

    # time out after 5 minutes
    # Sys::SigAction or Time::Out work when script is run from commandline, but don't timeout under CGI
    # instead, turn off blocking on inotify and use Time::HiRes
    # http://www.perlmonks.org/?node_id=859287
    $inotify->blocking(0);
    my $timelimit = 300;
    my $end = time() + $timelimit;
    while( time() < $end ) {
      $inotify->poll;
      sleep 0.1;
    }

    &all_done();

  }

  # this is the parent
  # wait a second before returning so that R and the input file watch
  # can start before any R commands are sent
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
  my $filename = $Rpad_ID . "/input.R";
  sub not_writable{
    @output_value="Input file not writable; timeout may have occurred.\nTry starting a new session by reloading the page.\n";
    print header;
    print @output_value;
    exit 1;
  }
  open(my $fh, '>', $filename) or &not_writable();
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

  # set up inotify watch to grab output file or create message if tmpdir (Rpad_ID) was deleted while running R command
  my $inotify = new Linux::Inotify2
    or die "Unable to create new inotify object: $!";
  # set up a watcher on an output file
  $inotify->watch($Rpad_ID, IN_DELETE_SELF | IN_CLOSE_WRITE, sub {
    my $event = shift;
    my $name = $event->name;
    my $fullname = $event->fullname;
    if ( $event->IN_DELETE_SELF ) {
      # TODO: test this, do we ever get here?
      @output_value="Temporary directory was deleted while running R command; timeout may have occurred.\nTry starting a new session by reloading the page.\n";
    }
    elsif ( $name eq "output" ) {
      # read contents of output file into output_value
      open(my $fh, '<', $fullname) or die "Could not open file '$fullname' $!";
      @output_value=<$fh>;
      close $fh;
    }
  }) or die "watch creation failed: $!";

  $inotify->poll;

#  this slows down response time considerably, so for now running of R commands is blocking
#  # return a default message if the R process doesn't finish within 10 seconds
#  @output_value = "10 seconds passed with no output from R ... back to you!\n";
#  $inotify->blocking(0);
#  my $timelimit = 10;
#  my $end = time() + $timelimit;
#  while( time() < $end ) {
#    $inotify->poll;
#    sleep 0.01;
#  }

}

print header;
print @output_value;
