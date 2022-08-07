-- insert 12 months of sample data with 1-min intervals, ending now()
-- about 360(d) * 24(h) * 60(m) = 518400 rows
INSERT INTO sample_events(
  agent_id,
  event_type,
  event_uuid,
  event_time)
SELECT
  random_between(1, 1000) as agent_id,
  random_between(1, 10) as event_type,
  uuid_generate_v4() as uuid,
  event_time
FROM
  generate_series(
 	  now() - INTERVAL '__INSERT_INTERVAL_DAYS__ days',
    now(),
    INTERVAL '1 min'
  ) as event_time;