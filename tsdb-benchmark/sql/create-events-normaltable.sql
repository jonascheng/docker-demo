-- create user defined function
CREATE OR REPLACE FUNCTION random_between(low INT ,high INT)
   RETURNS INT AS
$$
BEGIN
   RETURN floor(random()* (high-low + 1) + low);
END;
$$ language 'plpgsql' STRICT;

-- create sample_events table
DROP TABLE IF EXISTS sample_events;
CREATE TABLE sample_events(
  agent_id bigint NOT NULL,
  event_type integer NOT NULL,
  event_uuid uuid NOT NULL,
  event_time timestamp NOT NULL
);
