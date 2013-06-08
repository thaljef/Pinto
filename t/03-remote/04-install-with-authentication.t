#!perl

use strict;
use warnings;

use Test::More;
use Test::File;
use Test::Exception;
use Plack::Test;
use Apache::Htpasswd;
use File::Temp;
use Path::Class;

use Pinto::Remote;

use lib 'tlib';
use Pinto::Server::Tester;
use Pinto::Tester::Util qw(make_dist_archive has_cpanm $MINIMUM_CPANM_VERSION);

#------------------------------------------------------------------------------

plan skip_all => "Need cpanm $MINIMUM_CPANM_VERSION or newer" 
  unless has_cpanm($MINIMUM_CPANM_VERSION);

#------------------------------------------------------------------------------

warn "You will see some messages from cpanm, don't be alarmed...\n";

#------------------------------------------------------------------------------
# Create a password file

my $temp_dir         = File::Temp->newdir;
my $htpasswd_file    = file($temp_dir, 'htpasswd');
my @credentials      = qw(my_login my_password);
my $auth_required_rx = qr/authorization required/i;

$htpasswd_file->touch; # Apache::Htpasswd requires the file to exist
Apache::Htpasswd->new( $htpasswd_file )->htpasswd(@credentials);

ok( -e $htpasswd_file, 'htpasswd file exists' );
ok( -s $htpasswd_file, 'htpasswd file is not empty' );

#------------------------------------------------------------------------------
# Setup the server

my @auth = (qw(--auth backend=Passwd --auth), "path=$htpasswd_file");
my $t = Pinto::Server::Tester->new(pintod_opts => \@auth)->start_server;
$t->populate('JOHN/DistA-1 = PkgA~1 & PkgB~1,PkgC~1');
$t->populate('PAUL/DistB-1 = PkgB~1 & PkgD~2');
$t->populate('MARK/DistC-1 = PkgC~1');
$t->populate('MARK/DistC-2 = PkgC~2,PkgD~2');

#------------------------------------------------------------------------------

subtest 'Install succeeds with valid credentials' => sub {

  my %creds  = (username => 'my_login', password => 'my_password');
  my $remote = Pinto::Remote->new(root => $t->server_url, %creds);

  my $sandbox    = File::Temp->newdir;
  my $p5_dir     = dir($sandbox, qw(lib perl5));
  my %cpanm_opts = (cpanm_options => {q => undef, L => $sandbox->dirname});

  lives_ok { $remote->run(Install => (targets => ['PkgA'], %cpanm_opts)) }
    'install command was successfull'

  file_exists_ok($p5_dir->file('PkgA.pm'));
  file_exists_ok($p5_dir->file('PkgB.pm'));
  file_exists_ok($p5_dir->file('PkgC.pm'));
  file_exists_ok($p5_dir->file('PkgD.pm'));
};

#------------------------------------------------------------------------------

subtest 'Install fails with invalid credentials' => sub {

  my %creds  = (username => 'my_login', password => 'bogus');
  my $remote = Pinto::Remote->new(root => $t->server_url, %creds);

  my $sandbox    = File::Temp->newdir;
  my $p5_dir     = dir($sandbox, qw(lib perl5));
  my %cpanm_opts = (cpanm_options => {q => undef, L => $sandbox->dirname});
  
  throws_ok { $remote->run(Install => (targets => ['PkgA'], %cpanm_opts)) }
    qr/Installation failed/;
};

#------------------------------------------------------------------------------

subtest 'Install fails with no credentials' => sub {

  my %creds  = ();
  my $remote = Pinto::Remote->new(root => $t->server_url, %creds);

  my $sandbox    = File::Temp->newdir;
  my $p5_dir     = dir($sandbox, qw(lib perl5));
  my %cpanm_opts = (cpanm_options => {q => undef, L => $sandbox->dirname});
  
  throws_ok { $remote->run(Install => (targets => ['PkgA'], %cpanm_opts)) }
    qr/Installation failed/;
};

#------------------------------------------------------------------------------

done_testing;
