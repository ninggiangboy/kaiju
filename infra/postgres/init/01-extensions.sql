-- Runs once when the database cluster is initialised at tiers 1 and 2.
--
-- Extensions only. Do NOT define table structure here - structure belongs to
-- the migrations under backend/, and the data model is still pending analysis.
--
-- No identifier-generating extension is needed: identifiers come from the
-- client (CON-61).

-- Case-insensitive string comparison, for email and slugs. Needed from phase 1.
CREATE EXTENSION IF NOT EXISTS citext;

-- Fuzzy string matching, for search suggestions. Needed from phase 7; enabled
-- up front because it costs nothing while unused.
CREATE EXTENSION IF NOT EXISTS pg_trgm;
