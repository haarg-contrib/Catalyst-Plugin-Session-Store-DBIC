package TestApp::Model::DBICSchema;

use base 'Catalyst::Model::DBIC::Schema';

use strict;
use warnings;

our $db_file = $TestApp::DB_FILE;

__PACKAGE__->config(
    schema_class => 'TestApp::Schema',
    connect_info => [
        "dbi:SQLite:$db_file",
        '',
        '',
        { AutoCommit => 1 },
    ],
);

1;
