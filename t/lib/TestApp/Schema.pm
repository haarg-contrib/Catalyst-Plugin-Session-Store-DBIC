package TestApp::Schema;

use base qw/DBIx::Class::Schema/;
use strict;
use warnings;

__PACKAGE__->load_classes('Session');

1;
