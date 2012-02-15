#!/usr/bin/perl -w

# Script to pull the main Bugzilla repository, and all associated
# extensions.

use strict;
use Cwd;

my @extensions = ('BayotBase','Dashboard','EnhancedTreeView','InlineEditor','ChangeLog','EnhancedSeeAlso','MediaInfo','ListComponents','Scrums');

sub move_hook_to_extension($){
  my ($extension) = @_;
  
  # Put a Git pre-commit hook into place, to ensure perltidy is run.
  
  if (-d "./extensions/$extension/.git"){
    `cp pre-commit.extension ./extensions/$extension/.git/hooks/pre-commit`;
    `chmod +x ./extensions/$extension/.git/hooks/pre-commit`;
  }
}

if (-d "extensions"){
  print "Updating repositories:\n";

  print " * Pulling ./\n";
  `git pull`;
  
  # Put a Git pre-commit hook into place, to ensure perltidy is run.
  
  `cp pre-commit.nwp ./.git/hooks/pre-commit`;
  `chmod +x ./.git/hooks/pre-commit`;
  
  my $branch = `git name-rev --name-only HEAD`;
  chomp($branch);
  
  # Clone / pull each extension and checkout the current branch.

  foreach my $extension (sort @extensions){
    if (-d "./extensions/$extension"){
      print " * Pulling ./extensions/$extension\n";
      chdir("./extensions/$extension");
      `git pull`;
      chdir("../../");
      
      move_hook_to_extension($extension);
    }
    else {
      print "* Cloning ./extensions/$extension\n";
      my $path = "bayoteers/$extension".'.git';
      my $cmd = "git clone https://github.com/$path extensions/$extension";
      print $cmd."\n";
      `$cmd`;
      chdir("./extensions/$extension");
      
      my $g_branch;
      
      if ($branch eq 'sandbox'){
        $g_branch = 'devel'
      }
      else{
        $g_branch = 'master';
      }
      
      `git checkout $g_branch`;
      chdir("../../");
      
      move_hook_to_extension($extension);
    }
  }

  # Make sure we have all the latest schema updates
  # and any new parameters.
  
  `sudo rm data/templates -rf`;

  print "Running checksetup.pl\n";    

  `perl checksetup.pl`;
  
  # Run the basic unit tests that come with Bugzilla.
  
  print "Running runtests.pl\n";
  `perl runtests.pl`;
  
  # Put .perltidyrc into place to ensure consistent Perl code.
  print "Putting perltidyrc into place\n";

  if (-f "~/.perltidyrc"){
    my $result = `diff -q perltidyrc ~/.perltidyrc`;
    if ($result){
      print "Backing up existing ~/.perltidyrc to ~/.perltidyrc.bak\n";
      `cp ~/.perltidyrc ~/.perltidyrc.bak`;
    }
  }
  
  `cp ./perltidyrc ~/.perltidyrc`;
}
else {
  die("Can't find 'extensions' folder");
}

