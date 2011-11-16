package Pinto::DependencyExtractor;

# ABSTRACT: Extract dependency names and versions from a distribution archive

use Moose;
use Archive::Extract;
use Pinto::Exceptions qw(throw_fatal);
use Cwd::Guard qw(cwd_guard);
use Path::Class;
use File::Temp;

use namespace::autoclean;

#-----------------------------------------------------------------------------

use constant WIN32 => $^O eq 'MSWin32';
my $quote = WIN32 ? q/"/ : q/'/;

#-----------------------------------------------------------------------------

# VERSION

#-----------------------------------------------------------------------------
# Roles

with qw( Pinto::Role::Loggable );

#-----------------------------------------------------------------------------

sub extract_dependencies {
    my ( $self, %args ) = @_;

    my $archive = $args{archive};
    throw_fatal "$archive does not exist" if not -e $archive;

    $self->info("Extracting dependencies from $archive");
    my $ae = Archive::Extract->new( archive => $archive );

    my $temp = dir( File::Temp::tempdir(CLEANUP => 1) );
    $ae->extract( to => $temp ) or throw_fatal $ae->error();

    my $root = $temp->subdir( ( @{$ae->files()} )[0] );
    throw_fatal "$archive did not extract cleanly into a directory" if not -d $root;

    my $guard = cwd_guard($root) or throw_fatal "failed to chdir: $Cwd::Guard::Error";
    my $dist = {dist => $archive, dir => $root};
    $self->configure_this($dist);

    return $self->find_prereqs($dist);
}

#-----------------------------------------------------------------------------

sub configure_this {
    my ( $self, $dist ) = @_;

    #       if ($self->{skip_configure}) {
    #           my $eumm = -e 'Makefile';
    #           my $mb   = -e 'Build' && -f _;
    #           return {
    #               configured => 1,
    #               configured_ok => $eumm || $mb,
    #               use_module_build => $mb,
    #           };
    #       }

           my @mb_switches;
    #       unless ($self->{pod2man}) {
    #           # it has to be push, so Module::Build is loaded from the adjusted path when -L is in use
    #           push @mb_switches, ("-I$self->{base}", "-MModuleBuildSkipMan");
    #       }

    my $state = {};

    my $try_eumm = sub {
        if ( -e 'Makefile.PL' ) {
            $self->debug("Running Makefile.PL in $dist->{dir}");

            # NOTE: according to Devel::CheckLib, most XS modules exit
            # with 0 even if header files are missing, to avoid receiving
            # tons of FAIL reports in such cases. So exit code can't be
            # trusted if it went well.
            if ( $self->configure( [ $^X, "Makefile.PL" ] ) ) {
                $state->{configured_ok} = -e 'Makefile';
            }
            $state->{configured}++;
        }
    };

    my $try_mb = sub {
        if ( -e 'Build.PL' ) {
            $self->debug("Running Build.PL in $dist->{dir}");
            if ( $self->configure( [ $^X, @mb_switches, "Build.PL" ] ) ) {
                $state->{configured_ok} = -e 'Build' && -f _;
            }
            $state->{use_module_build}++;
            $state->{configured}++;
        }
    };

    # Module::Build deps should use MakeMaker because that causes circular deps and fail
    # Otherwise we should prefer Build.PL
    my %should_use_mm = map { $_ => 1 } qw( version ExtUtils-ParseXS ExtUtils-Install ExtUtils-Manifest );

    my @try;
    if ( $dist->{dist} && $should_use_mm{ $dist->{dist} } ) {
        @try = ( $try_eumm, $try_mb );
    }
    else {
        @try = ( $try_mb, $try_eumm );
    }

    for my $try (@try) {
        $try->();
        last if $state->{configured_ok};
    }

 #       unless ($state->{configured_ok}) {
 #           while (1) {
 #               my $ans = lc $self->prompt("Configuring $dist->{dist} failed.\nYou can s)kip, r)etry or l)ook ?", "s");
 #               last                                if $ans eq 's';
 #               return $self->configure_this($dist) if $ans eq 'r';
 #               $self->look                         if $ans eq 'l';
 #           }
 #       }

    return $state;
}

#-----------------------------------------------------------------------------

sub find_prereqs {
    my ( $self, $dist ) = @_;

    my @deps = $self->extract_meta_prereqs($dist);

    return @deps;
}

#-----------------------------------------------------------------------------

sub extract_meta_prereqs {
    my ( $self, $dist ) = @_;

    my $meta = $dist->{meta};

    my @deps;
    if ( -e "MYMETA.json" ) {
        require JSON::PP;
        $self->debug("Checking dependencies from MYMETA.json ...\n");
        my $json = do { open my $in, "<MYMETA.json"; local $/; <$in> };
        my $mymeta = JSON::PP::decode_json($json);
        if ($mymeta) {
            $meta->{$_} = $mymeta->{$_} for qw(name version);
            return $self->extract_requires($mymeta);
        }
    }

    if ( -e 'MYMETA.yml' ) {
        $self->debug("Checking dependencies from MYMETA.yml");
        my $mymeta = $self->parse_meta('MYMETA.yml');
        if ($mymeta) {
            $meta->{$_} = $mymeta->{$_} for qw(name version);
            return $self->extract_requires($mymeta);
        }
    }

    if ( -e '_build/prereqs' ) {
        $self->debug("Checking dependencies from _build/prereqs");
        my $mymeta = do { open my $in, "_build/prereqs"; $self->safe_eval( join "", <$in> ) };
        @deps = $self->extract_requires($mymeta);
    }
    elsif ( -e 'Makefile' ) {
        $self->debug("Finding PREREQ from Makefile");
        open my $mf, "Makefile";
        while (<$mf>) {
            if (/^\#\s+PREREQ_PM => {\s*(.*?)\s*}/) {
                my @all;
                my @pairs = split ', ', $1;
                for (@pairs) {
                    my ( $pkg, $v ) = split '=>', $_;
                    push @all, [ $pkg, $v ];
                }
                my $list = join ", ", map {"'$_->[0]' => $_->[1]"} @all;
                my $prereq = $self->safe_eval("no strict; +{ $list }");
                push @deps, %$prereq if $prereq;
                last;
            }
        }
    }

    return @deps;
}

#------------------------------------------------------------------------------

sub extract_requires {
    my ( $self, $meta ) = @_;

    if ( $meta->{'meta-spec'} && $meta->{'meta-spec'}{version} == 2 ) {
        my @phase = $self->{notest} ? qw( build runtime ) : qw( build test runtime );
        my @deps = map {
            my $p = $meta->{prereqs}{$_} || {};
            %{ $p->{requires} || {} };
        } @phase;
        return @deps;
    }

    my @deps;
    push @deps, %{ $meta->{build_requires} } if $meta->{build_requires};
    push @deps, %{ $meta->{requires} }       if $meta->{requires};

    return @deps;
}

#-----------------------------------------------------------------------------

sub configure {
    my ( $self, $cmd ) = @_;

    # trick AutoInstall
    local $ENV{PERL5_CPAN_IS_RUNNING} = local $ENV{PERL5_CPANPLUS_IS_RUNNING} = $$;

    # e.g. skip CPAN configuration on local::lib
    local $ENV{PERL5_CPANM_IS_RUNNING} = $$;

    my $use_default = !$self->{interactive};
    local $ENV{PERL_MM_USE_DEFAULT} = $use_default;

    # skip man page generation
    local $ENV{PERL_MM_OPT} = $ENV{PERL_MM_OPT};
    unless ( $self->{pod2man} ) {
        $ENV{PERL_MM_OPT} .= " INSTALLMAN1DIR=none INSTALLMAN3DIR=none";
    }

    local $self->{verbose} = $self->{verbose} || $self->{interactive};
    $self->run_timeout( $cmd, $self->{configure_timeout} );
}

#-----------------------------------------------------------------------------

sub run_timeout {
    my ( $self, $cmd, $timeout ) = @_;
    return $self->run($cmd) if WIN32 || $self->{verbose} || !$timeout;

    my $pid = fork;
    if ($pid) {
        eval {
            local $SIG{ALRM} = sub { die "alarm\n" };
            alarm $timeout;
            waitpid $pid, 0;
            alarm 0;
        };
        if ( $@ && $@ eq "alarm\n" ) {
            $self->diag_fail("Timed out (> ${timeout}s). Use --verbose to retry.");
            local $SIG{TERM} = 'IGNORE';
            kill TERM => 0;
            waitpid $pid, 0;
            return;
        }
        return !$?;
    }
    elsif ( $pid == 0 ) {
        $self->run_exec($cmd);
    }
    else {
        $self->debug("! fork failed: falling back to system()\n");
        $self->run($cmd);
    }
}

#-----------------------------------------------------------------------------

sub run {
      my($self, $cmd) = @_;

      if (WIN32 && ref $cmd eq 'ARRAY') {
          $cmd = join q{ }, map { $self->shell_quote($_) } @$cmd;
      }

      if (ref $cmd eq 'ARRAY') {
          my $pid = fork;
          if ($pid) {
              waitpid $pid, 0;
              return !$?;
          } else {
              $self->run_exec($cmd);
          }
      } else {
          unless ($self->{verbose}) {
              $cmd .= " >> " . $self->shell_quote($self->{log}) . " 2>&1";
          }
          !system $cmd;
      }
  }

#-----------------------------------------------------------------------------

  sub run_exec {
      my($self, $cmd) = @_;

      if (ref $cmd eq 'ARRAY') {
          unless ($self->{verbose}) {
              open my $logfh, ">>", $self->{log};
              open STDERR, '>&', $logfh;
              open STDOUT, '>&', $logfh;
              close $logfh;
          }
          exec @$cmd;
      } else {
          unless ($self->{verbose}) {
              $cmd .= " >> " . $self->shell_quote($self->{log}) . " 2>&1";
          }
          exec $cmd;
      }
  }


#-----------------------------------------------------------------------------

sub shell_quote {
      my($self, $stuff) = @_;
      $stuff =~ /^${quote}.+${quote}$/ ? $stuff : ($quote . $stuff . $quote);
  }

#-----------------------------------------------------------------------------

sub safe_eval {
      my($self, $code) = @_;
      eval $code;
  }

#-----------------------------------------------------------------------------

__PACKAGE__->meta->make_immutable();

#-----------------------------------------------------------------------------

1;
