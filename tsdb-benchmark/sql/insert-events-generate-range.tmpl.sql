INSERT INTO sample_events(
  agent_id,
  event_type,
  event_uuid,
  event_time)
SELECT
  random_between(1, 100) as agent_id,
  random_between(1, 5) as event_type,
  uuid_generate_v4() as uuid,
  event_time
FROM
  generate_series(
 	  now() - INTERVAL '__INSERT_RANGE_BEGIN_INTERVAL_DAYS__ days',
    now() - INTERVAL '__INSERT_RANGE_END_INTERVAL_DAYS__ days',
    INTERVAL '10 seconds'
  ) as event_time;