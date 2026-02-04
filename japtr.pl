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
      $opt->{apath}      //= "/nu/conf/jojessapt/archive";
      $opt->{tmp}        //= "japtrtmp";
      $opt->{Packages}   //= "dists/stable/main/binary-amd64/Packages";
      $opt->{ReleaseDir} //= "dists/stable";
      $opt->{Release}      //= "Release";
      $opt->{inRelease}    //= "InRelease";
      $opt->{arch}       //= "amd64";
      $opt->{gpgkeyname} //= "jojess";
      $opt->{retaincopyq} //= 3;

   my $self  = {opt=>$opt, urls=>$urls};
   
   bless ($self, $class);
   
   $self->archiveold if $opt->{retaincopyq};
   $self->doit if $opt->{doit};
   
   return $self;
}

sub archiveold {
   # lazy lil archive routine
   my $self = shift;
   chdir($opt->{rpath}) or die;
   my @files = split("\n", `find -type f -name "*deb"`);
   my $sort = {};
   foreach my $file (@files) {
      if ( $file =~ /^(.*\/)(.*?)$/ ) {
         my $pat = $1;
         my $fil = $2;
         next if $pat !~ /^..pool/; # these are the files that slow down the inrelease gen , we don't need to host a bajillion different versions of discord lmao
         push (@{$sort->{$pat}}, $fil);
      }
   }
   foreach my $key (keys %{$sort}) {
      my @keyfiles = ();
      foreach my $fil (sort @{$sort->{$key}}) {
         push(@keyfiles,$fil);
      }
      for (my $i=1;  $i<=  $self->{opt}->{retaincopyq}; $i++) {
         pop(@keyfiles);
      }
      mkdir($self->{opt}->{apath});

      my $odi = $self->{opt}->{apath} .  "/" . $key;
      &{File::Path::make_path}( $odi )  if ! -d $odi;
      foreach my $fil (@keyfiles) {
         my $ifi = $key . $fil;
         my $ofi = $odi . $fil;
         &{File::Copy::move}($ifi,$ofi) if (( -e $ifi )and (! -e $ofi ));
      }
   }
   return;
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

   push(@{$urls}, "https://discord.com/api/download?platform=linux&format=deb") if $opt->{discord};
   push(@{$urls}, "https://downloads.slack-edge.com/desktop-releases/linux/x64/4.46.101/slack-desktop-4.46.101-amd64.deb") if $opt->{slack};
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
      &{File::Path::make_path}($odi) if ! -d $odi;
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

