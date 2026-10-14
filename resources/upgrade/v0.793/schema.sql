--
-- Additive schema for the Voice AI Agents and Numbers modules (v0.793)
-- Safe to re-run: tables are created only when missing and existing rows are never dropped.
-- Column definitions mirror gui/modules/agents/db/dsip_agent.py and gui/modules/numbers/db/dsip_number.py.
-- Python-side model defaults are not emitted as DDL defaults, except server_default values.
--

CREATE TABLE IF NOT EXISTS `dsip_agent` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `name` varchar(255) NOT NULL,
  `type` varchar(128) NOT NULL,
  `project_id` varchar(255) NOT NULL,
  `greeting_message` varchar(512) NOT NULL,
  `instructions` varchar(1024) NOT NULL,
  `instructions_id` int(11) NOT NULL,
  `guardrails` varchar(255) NOT NULL,
  `training_website` varchar(255) NOT NULL,
  `tools` varchar(255) NOT NULL,
  `callback_email` varchar(255) NOT NULL,
  `did_mapping` varchar(255) NOT NULL,
  `deployment_type` varchar(255) NOT NULL,
  `deployment_profile_id` int(11) NOT NULL,
  `container_name` varchar(255) NOT NULL,
  `container_port` varchar(64) NOT NULL,
  `container_port_mapped` varchar(64) NOT NULL,
  `image_name` varchar(255) NOT NULL,
  `created_at` datetime DEFAULT CURRENT_TIMESTAMP,
  `modified_at` datetime DEFAULT CURRENT_TIMESTAMP,
  `status` int(11) NOT NULL,
  `error` varchar(200) NOT NULL,
  `webhook_secret` varchar(255) NOT NULL,
  `agent_services_api_key` varchar(255) NOT NULL,
  PRIMARY KEY (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE TABLE IF NOT EXISTS `dsip_agent_instruction` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `name` varchar(255) NOT NULL,
  `project_type` varchar(255) NOT NULL,
  `instructions` varchar(4096) NOT NULL,
  PRIMARY KEY (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE TABLE IF NOT EXISTS `dsip_number` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `did` varchar(64) NOT NULL,
  `status` varchar(64) NULL,
  `carrier` varchar(128) NULL,
  `pool` varchar(128) NULL,
  `assigned_length` varchar(256) NULL,
  `assigned_reference_id` varchar(256) NULL,
  `assigned_date` datetime NULL,
  `date_created` datetime NULL,
  PRIMARY KEY (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;
