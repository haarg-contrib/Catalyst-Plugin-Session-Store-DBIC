# NAME

Catalyst::Plugin::Session::Store::DBIC - Store your sessions via DBIx::Class

# SYNOPSIS

```perl
# Create a table in your database for sessions
CREATE TABLE sessions (
    id           CHAR(72) PRIMARY KEY,
    session_data TEXT,
    expires      INTEGER
);

# Create the corresponding table class
package MyApp::Schema::Session;

use base qw/DBIx::Class/;

__PACKAGE__->load_components(qw/Core/);
__PACKAGE__->table('sessions');
__PACKAGE__->add_columns(qw/id session_data expires/);
__PACKAGE__->set_primary_key('id');

1;

# In your application
use Catalyst qw/Session Session::Store::DBIC Session::State::Cookie/;

__PACKAGE__->config(
    # ... other items ...
    'Plugin::Session' => {
        dbic_class => 'DBIC::Session',  # Assuming MyApp::Model::DBIC
        expires    => 3600,
    },
);

# Later, in a controller action
$c->session->{foo} = 'bar';
```

# DESCRIPTION

This [Catalyst::Plugin::Session](https://metacpan.org/pod/Catalyst%3A%3APlugin%3A%3ASession) storage module saves session data in
your database via [DBIx::Class](https://metacpan.org/pod/DBIx%3A%3AClass).  It's actually just a wrapper around
[Catalyst::Plugin::Session::Store::Delegate](https://metacpan.org/pod/Catalyst%3A%3APlugin%3A%3ASession%3A%3AStore%3A%3ADelegate); if you need complete
control over how your sessions are stored, you probably want to use
that instead.

# METHODS

## setup\_finished

Hook into the configured session class.

## session\_store\_dbic\_class

Return the [DBIx::Class](https://metacpan.org/pod/DBIx%3A%3AClass) class name to be passed to `$c->model`.
Defaults to `DBIC::Session`.

## session\_store\_dbic\_id\_field

Return the configured ID field name.  Defaults to `id`.

## session\_store\_dbic\_data\_field

Return the configured data field name.  Defaults to `session_data`.

## session\_store\_dbic\_expires\_field

Return the configured expires field name.  Defaults to `expires`.

## session\_store\_model

Return the model used to find a session.

## get\_session\_store\_delegate

Load the row corresponding to the specified session ID.  If none is
found, one is automatically created.

## session\_store\_delegate\_key\_to\_accessor

Match the specified key and operation to the session ID and field
name.

## delete\_session\_data

Delete the specified session from the backend store.

## delete\_expired\_sessions

Delete all expired sessions.

# CONFIGURATION

The following parameters should be placed in your application
configuration under the `Plugin::Session` key.

## dbic\_class

(Required) The name of the [DBIx::Class](https://metacpan.org/pod/DBIx%3A%3AClass) that represents a session in
the database.  It is recommended that you provide only the part after
`MyApp::Model`, e.g. `DBIC::Session`.

If you are using [Catalyst::Model::DBIC::Schema](https://metacpan.org/pod/Catalyst%3A%3AModel%3A%3ADBIC%3A%3ASchema), the following
layout is recommended:

- `MyApp::Schema` - your [DBIx::Class::Schema](https://metacpan.org/pod/DBIx%3A%3AClass%3A%3ASchema) class
- `MyApp::Schema::Session` - your session table class
- `MyApp::Model::DBIC` - your [Catalyst::Model::DBIC::Schema](https://metacpan.org/pod/Catalyst%3A%3AModel%3A%3ADBIC%3A%3ASchema) class

This module will then use `$c->model` to access the appropriate
result source from the composed schema matching the `dbic_class`
name.

For more information, please see [Catalyst::Model::DBIC::Schema](https://metacpan.org/pod/Catalyst%3A%3AModel%3A%3ADBIC%3A%3ASchema).

## expires

Number of seconds for which sessions are active.

Note that no automatic cleanup is done on your session data.  To
delete expired sessions, you can use the ["delete\_expired\_sessions"](#delete_expired_sessions)
method with [Catalyst::Plugin::Scheduler](https://metacpan.org/pod/Catalyst%3A%3APlugin%3A%3AScheduler).

## id\_field

The name of the field on your sessions table which stores the session
ID.  Defaults to `id`.

## data\_field

The name of the field on your sessions table which stores session
data.  Defaults to `session_data` for compatibility with
[Catalyst::Plugin::Session::Store::DBI](https://metacpan.org/pod/Catalyst%3A%3APlugin%3A%3ASession%3A%3AStore%3A%3ADBI).

## expires\_field

The name of the field on your sessions table which stores the
expiration time of the session.  Defaults to `expires`.

# SCHEMA

Your sessions table should contain the following columns:

```
id           CHAR(72) PRIMARY KEY
session_data TEXT
expires      INTEGER
```

The `id` column should probably be 72 characters.  It needs to handle
the longest string that can be returned by
["generate\_session\_id" in Catalyst::Plugin::Session](https://metacpan.org/pod/Catalyst%3A%3APlugin%3A%3ASession#generate_session_id), plus another eight
characters for internal use.  This is less than 72 characters when
SHA-1 or MD5 is used, but SHA-256 will need all 72 characters.

The `session_data` column should be a long text field.  Session data
is encoded using [MIME::Base64](https://metacpan.org/pod/MIME%3A%3ABase64) before being stored in the database.

Note that MySQL `TEXT` fields only store 64 KB, so if your session
data will exceed that size you'll want to use `MEDIUMTEXT`,
`MEDIUMBLOB`, or larger. If you configure your
[DBIx::Class::ResultSource](https://metacpan.org/pod/DBIx%3A%3AClass%3A%3AResultSource) to include the size of the column, you
will receive warnings for this problem:

```
This session requires 1180 bytes of storage, but your database
column 'session_data' can only store 200 bytes. Storing this
session may not be reliable; increase the size of your data field
```

See ["add\_columns" in DBIx::Class::ResultSource](https://metacpan.org/pod/DBIx%3A%3AClass%3A%3AResultSource#add_columns) for more information.

The `expires` column stores the future expiration time of the
session.  This may be null for per-user and flash sessions.

Note that you can change the column names using the ["id\_field"](#id_field),
["data\_field"](#data_field), and ["expires\_field"](#expires_field) configuration parameters.
However, the column types must match the above.

# ACKNOWLEDGMENTS

- Andy Grundman, for [Catalyst::Plugin::Session::Store::DBI](https://metacpan.org/pod/Catalyst%3A%3APlugin%3A%3ASession%3A%3AStore%3A%3ADBI)
- David Kamholz, for most of the testing code (from
        [Catalyst::Plugin::Authentication::Store::DBIC](https://metacpan.org/pod/Catalyst%3A%3APlugin%3A%3AAuthentication%3A%3AStore%3A%3ADBIC))
- Yuval Kogman, for assistance in converting to
        [Catalyst::Plugin::Session::Store::Delegate](https://metacpan.org/pod/Catalyst%3A%3APlugin%3A%3ASession%3A%3AStore%3A%3ADelegate)
- Jay Hannah, for tests and warning when session size
        exceeds DBIx::Class storage size.

# BUGS

Please report any bugs or feature requests on the bugtracker website
[https://rt.cpan.org/Public/Dist/Display.html?Name=Catalyst-Plugin-Session-Store-DBIC](https://rt.cpan.org/Public/Dist/Display.html?Name=Catalyst-Plugin-Session-Store-DBIC)
or by email to
[bug-Catalyst-Plugin-Session-Store-DBIC@rt.cpan.org](mailto:bug-Catalyst-Plugin-Session-Store-DBIC@rt.cpan.org).

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

# AUTHORS

- Daniel Westermann-Clark <danieltwc@cpan.org>
- Andrew Rodland <andrew@cleverdomain.org>

# CONTRIBUTORS

- Florian Ragwitz <rafl@debian.org>
- Graham Knop <haarg@haarg.org>
- Jay Hannah <jay@jays.net>
- John Napiorkowski <jjn1056@yahoo.com>
- Jonathan Yu <frequency@cpan.org>
- Tomas Doran <bobtfish@bobtfish.net>

# COPYRIGHT AND LICENSE

This software is copyright (c) 2006 - 2026 by Daniel Westermann-Clark.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.
