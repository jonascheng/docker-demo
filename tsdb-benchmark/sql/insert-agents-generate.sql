-- install extension for uuid_generate_v4
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

-- create sample_agents table
CREATE TABLE sample_agents(
  agent_id bigint,
  agent_uuid uuid
);

-- insert sample data with 1000 agents
INSERT INTO sample_agents(agent_id, agent_uuid)
SELECT id, uuid_generate_v4() as uuid
FROM
  generate_series(1,1000) as id;
