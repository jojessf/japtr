#!/usr/bin/perl
# 20250807 jojessf
use strict;
use Getopt::Lazier;
use File::Copy qw(move);
use File::Path qw(make_path);
my ($opt, @DARG) = Getopt::Lazier->new(@ARGV);
$opt->{doit} //= 1;
my $Japtr = Jojess::Japtr->new($opt, \@DARG);
   
exit; 

package Jojess::Japtr;

sub new {
   my $class = shift;
   my $opt   = shift;
   my $urls  = shift;
      $opt->{rpath}      //= "/nu/conf/jojessapt";
      $opt->{tmp}        //= "japtrtmp";
      $opt->{Packages}   //= "dists/stable/main/binary-amd64/Packages";
      $opt->{ReleaseDir} //= "dists/stable";
      $opt->{Release}      //= "Release";
      $opt->{inRelease}    //= "InRelease";
      $opt->{arch}       //= "amd64";
      $opt->{gpgkeyname} //= "jojess";

   my $self  = {opt=>$opt, urls=>$urls};
   
   bless ($self, $class);
   
   $self->doit if $opt->{doit};
   
   return $self;
}

sub doit {
   my $self = shift;
   $self->get_stuff;
   $self->tmp_to_deb;
   $self->scan_packages;
   $self->release_gen;
   $self->release_sign;
   return;
}
 
sub release_gen {
   my $self = shift;
   my $opt = $self->{opt};
   chdir($opt->{rpath});
   chdir($opt->{ReleaseDir});
   my $testrgen = `$opt->{rpath}/releasegen.sh > $opt->{Release}`;
   return;
}

sub release_sign {
   my $self = shift;
   chdir($opt->{rpath});
   chdir($opt->{ReleaseDir});
   
   my $signcom  = "cat ".$opt->{Release};
      $signcom .= " | gpg --default-key ".$opt->{gpgkeyname}." -abs";
      $signcom .= " > ".$opt->{Release}.".gpg";
   my $testsign = `$signcom`;

      $signcom = "cat ".$opt->{Release};
      $signcom .= " | gpg --default-key ".$opt->{gpgkeyname}." -abs --clearsign";
      $signcom .= " > " . $opt->{inRelease};
      $testsign = `$signcom`;

   return;
}


sub get_stuff {
   my $self = shift;
   my $opt  = $self->{opt};
   my $urls = $self->{urls};

   push(@{$urls}, "https://discord.com/api/download?platform=linux&format=deb");

   chdir($opt->{rpath});
   chdir($opt->{tmp});
   foreach my $url (@{$urls}) {
      print "[GET]". $url . "\n";
      my $wget = `wget -nv "$url"`;
   }
   return;
}

sub tmp_to_deb {
   my $self = shift;
   my $opt  = $self->{opt};

   chdir($opt->{rpath});
   chdir($opt->{tmp});
   my @fils;
   while (<*>) {
      push(@fils, $_);
   }
   foreach my $fil (@fils) {
      my $dnfo;
      my $dnfostr = `dpkg --info "$fil"`;
      my @dnfoz = split("\n", $dnfostr);
      foreach my $lin (@dnfoz) {
         $lin =~ m/ (.+?): (.*)/;
         my ($key, $val) = ($1, $2);
         $dnfo->{$key} = $val;
      }
      if ( (! $dnfo->{Package}) || (! $dnfo->{Version}) || (! $dnfo->{Architecture}) ) {
         die;
      }
      $dnfo->{Revision} //= 1;
      my $ofi;
      $ofi .= $dnfo->{Package}.'-';
      $ofi .= $dnfo->{Version} .'-';
      $ofi .= $dnfo->{Revision}.'_';
      $ofi .= $dnfo->{Architecture};
      $ofi .= ".deb";
   
      $dnfo->{Package} =~ /^(.)/;
      $dnfo->{firstletter} = $1;

      # TODO mktree
      my $odi = "../pool/main/".$dnfo->{firstletter}."/".$dnfo->{Package}."/";
      print $fil . "\t" . $odi . $ofi . "\n";
      File::Copy::move($fil, $odi.$ofi) or die "$odi???";
   }
   return;
}


sub scan_packages {
   chdir($opt->{rpath});
   system("dpkg-scanpackages --arch $opt->{arch} pool > $opt->{Packages}");

   system("cat dists/stable/main/binary-".$opt->{arch}."/Packages | gzip -9 > dists/stable/main/binary-".$opt->{arch}."/Packages.gz");
}

