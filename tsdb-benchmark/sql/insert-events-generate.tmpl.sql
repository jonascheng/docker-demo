-- insert __INSERT_INTERVAL_DAYS__ days of sample data with 1-second intervals, ending now()
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
    INTERVAL '10 seconds'
  ) as event_time;