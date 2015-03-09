-- This is an example init script. You might want to define this for your
-- project to make it easy for developers to set up new databases from scratch.
-- It is expected that this script is run as the database cluster superuser.
-- For example:
-- 
-- sudo -u postgres psql -f 'init.sql'

CREATE USER migrator_example;
CREATE DATABASE migrator_example OWNER migrator_example;
