use strict;
use warnings;

use Test::Needs qw(
    DBD::SQLite
    Catalyst::Model::DBIC::Schema
    Catalyst::Plugin::Session::State::Cookie
    Test::WWW::Mechanize::Catalyst
);

use FindBin;
use Test::More;
use Test::Warnings qw(:all :no_end_test);

use lib "$FindBin::Bin/lib";

BEGIN {
    $TestApp::DB_FILE = "$FindBin::Bin/session.db";

    $TestApp::CONFIG = {
        name    => 'TestApp',
        session => {
            dbic_class => 'DBICSchema::Session',
            data_field => 'data',
        },
    };

    $TestApp::PLUGINS = [qw/
        Session
        Session::State::Cookie
        Session::Store::DBIC
    /];
}

use SetupDB;
use Test::WWW::Mechanize::Catalyst 'TestApp';

my $mech = Test::WWW::Mechanize::Catalyst->new;

my $key   = 'schema';
my $value = scalar localtime;

# Setup session
$mech->get_ok("http://localhost/session/setup?key=$key&value=$value", 'request to set session value');
$mech->content_is('ok', 'set session value');

# Setup flash
$mech->get_ok("http://localhost/flash/setup?key=$key&value=$value", 'request to set flash value');
$mech->content_is('ok', 'set session value');

# Check flash
$mech->get_ok("http://localhost/flash/output?key=$key", 'request to get flash value');
$mech->content_is($value, 'got session value back');

# Check session
$mech->get_ok("http://localhost/session/output?key=$key", 'request to get session value');
$mech->content_is($value, 'got session value back');

# Check change_session_id
$mech->get_ok("http://localhost/session/sessionid", 'request current session ID');
my $sid = $mech->content;
$mech->get_ok("http://localhost/session/change", 'request to change session ID');
$mech->content_is('ok', 'successful');
$mech->get_ok("http://localhost/session/sessionid", 'request current session ID');
ok($mech->content ne $sid, 'session ID changed');
$mech->get_ok("http://localhost/session/output?key=$key", 'request to get session value');
$mech->content_is($value, 'got session value back');

# Exceed our session storage capactity
$value = "blah" x 200;
like warning {
    $mech->get_ok("http://localhost/session/setup?key=$key&value=$value", 'exceeding storage capacity');
}, qr/This session requires \d+ bytes of storage, but your database column 'data' can only store 200 bytes. Storing this session may not be reliable; increase the size of your data field/, 'warning thrown as expected';

# Delete session
$mech->get_ok('http://localhost/session/delete', 'request to delete session');
$mech->content_is('ok', 'deleted session');

# Delete expired sessions
$mech->get_ok('http://localhost/session/delete_expired', 'request to delete expired sessions');
$mech->content_is('ok', 'deleted expired sessions');

# Clean up
unlink $TestApp::DB_FILE;

done_testing;
