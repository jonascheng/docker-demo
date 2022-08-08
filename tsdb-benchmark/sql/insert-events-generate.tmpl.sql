-- insert 30 days of sample data with 1-second intervals, ending now()
-- about 30(d) * 24(h) * 60(m) * 60(s) = 2,592,000 rows
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
    INTERVAL '1 seconds'
  ) as event_time;