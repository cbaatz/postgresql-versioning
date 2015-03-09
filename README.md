PostgreSQL migrator
===================

*NOTE*: This is to be considered an experimental tool and has not been well
tested. Do not use for production. In all cases, you should ensure that you
understand what this tool does.

This is a script to implement a PostgreSQL schema versioning method, intended
to be simple and reliable. It is structured as follows:

A schema version is defined by the SQL file that migrates the DB from the
previous version. For example:

    .
    |-- 000-meta.sql
    |-- 001-basic-customer-tables.sql
    |-- 002-add-dob-column.sql
    |-- 003-create-tags-table.sql

The special `meta.version` table tracks the current and historic schema
versions of a database. For example:

     id |         name          |         valid_time
    ----+-----------------------+----------------------------
      0 | meta                  | 2015-03-08 23:01:20.626437
      1 | basic-customer-tables | 2015-03-08 23:01:20.626437
      2 | add-dob-column        | 2015-03-08 23:01:20.626437
      3 | create-tags-table     | 2015-03-09 00:31:21.146069

Schema versions increase strictly monotonically and can never be reverted once
commited (see comment on rollbacks below). Version 0 should set up the
`meta.version` table if it does not already exists since the `migrate` script
will assume it exists thereafter.

The `migrate` script wraps each migration in a transaction. A single migration
can cover several schema versions.

Installation
------------

1. Copy `migrate` and `000-meta.sql` to a folder under source control (for
   example `db/`) in your project.

2. Adjust the config parameters `ROLE`, `DB`, `HOSTNAME`, and `PORT`.

3. *OPTIONAL* For developer convenience, add an `init.sql` script that sets up
   the application database and corresponding role if run as the database
   cluster superuser.

4. *OPTIONAL* Copy this README into the same folder and remove this
   installation section and make any other edits you think appropriate to make
   it fit your project.

Usage
-----

    migrate show      # show the computed migration script
    migrate dry       # run migration but rollback
    migrate commit    # run migration and commit

To add a migration script, create a file starting with the zero-padded version
following the latest existing one. For example, if the highest versioned script
that exist is `011-move-tags-from-column-to-table.sql`, then your script should
start with `012-`, for example `012-add-hidden-column-to-user-table.sql`.

You can see what script the migrator would run using:

    migrate show

You can check if the migration script that would be run is valid without
committing:

    migrate dry

Finally, when you want to actually run the migration:

    migrate commit

Data vs schema
--------------

First of all, "schema" is used here in the conventional sense, *not in the
sense of a PostgreSQL namespace schema*. The naming of PostgreSQL namespaces to
schemas is unfortunate.

One thing to note is that the scripts that deal with schema migration should
not add alter essential data. They may, and often need to, alter the shape or
form of data to ensure that existing data are valid in a new schema. They
should not, however, add or delete rows or change data selectively based on
what data are expected to be in the database. Basically, any valid migration
should work just as well on an empty database as on one with data.

Rollbacks
---------

Rolling back a database change to a production system is dangerous becuase they
risk losing data. For example, if your migration added a column that has now
started to be populated by the application, a indiscriminate rollback would
drop the column and lose the data.

Rollbacks can still be important of course. If after a database migration
commits, the production application starts throwing critical errors, you want
to roll back to the previous schema even if it means losing some new data. To
allow for this, you prepare a roll-back script ahead of your migration and keep
this is a separate folder. If you decide you want to roll back, you move this
script to the main migration script folder as the next version (e.g.
012-rollback-to-10.sql) and run another migration. This will increase the
version number to 12, but (if you have written your rollback script correctly)
roll back the database to the same schema as version 10.

The advantage of this appraoch is that it is simple and predictable, tracks the
provenance of the database explicitly (including time information alawys saved
in `meta.version`), and leaves the choice of whether to write rollback scripts
or not to the database developer.
