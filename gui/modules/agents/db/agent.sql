--
-- Table structure for the Voice AI Agents module
--
-- Source of truth for this schema is the SQLAlchemy model in
-- gui/modules/agents/db/dsip_agent.py. The tables are created at runtime by
-- Base.metadata.create_all() in gui/modules/agents/__init__.py, so this file is
-- a reference copy and is not sourced by the installer. Keep it in sync with the
-- model when columns change.
--
-- Column defaults declared on the model (default='') are applied by SQLAlchemy
-- on insert, not emitted as DDL defaults, which is why the NOT NULL columns
-- below carry no DEFAULT clause.
--

/*!40101 SET @OLD_CHARACTER_SET_CLIENT=@@CHARACTER_SET_CLIENT */;
/*!40101 SET @OLD_CHARACTER_SET_RESULTS=@@CHARACTER_SET_RESULTS */;
/*!40101 SET @OLD_COLLATION_CONNECTION=@@COLLATION_CONNECTION */;
/*!40101 SET NAMES utf8mb4 */;
/*!40103 SET @OLD_TIME_ZONE=@@TIME_ZONE */;
/*!40103 SET TIME_ZONE='+00:00' */;
/*!40014 SET @OLD_UNIQUE_CHECKS=@@UNIQUE_CHECKS, UNIQUE_CHECKS=0 */;
/*!40014 SET @OLD_FOREIGN_KEY_CHECKS=@@FOREIGN_KEY_CHECKS, FOREIGN_KEY_CHECKS=0 */;
/*!40101 SET @OLD_SQL_MODE=@@SQL_MODE, SQL_MODE='NO_AUTO_VALUE_ON_ZERO' */;
/*!40111 SET @OLD_SQL_NOTES=@@SQL_NOTES, SQL_NOTES=0 */;

--
-- Table structure for table `dsip_agent`
--

DROP TABLE IF EXISTS `dsip_agent`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `dsip_agent` (
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
  PRIMARY KEY (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `dsip_agent_instruction`
--

DROP TABLE IF EXISTS `dsip_agent_instruction`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `dsip_agent_instruction` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `name` varchar(255) NOT NULL,
  `project_type` varchar(255) NOT NULL,
  `instructions` varchar(4096) NOT NULL,
  PRIMARY KEY (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;
/*!40101 SET character_set_client = @saved_cs_client */;
