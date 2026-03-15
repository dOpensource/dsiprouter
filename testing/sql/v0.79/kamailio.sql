/*M!999999\- enable the sandbox mode */ 
-- MariaDB dump 10.19  Distrib 10.11.14-MariaDB, for debian-linux-gnu (x86_64)
--
-- Host: localhost    Database: kamailio
-- ------------------------------------------------------
-- Server version	10.11.14-MariaDB-0+deb12u2

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
-- Table structure for table `acc`
--

DROP TABLE IF EXISTS `acc`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8mb4 */;
CREATE TABLE `acc` (
  `id` int(10) unsigned NOT NULL AUTO_INCREMENT,
  `method` varchar(16) NOT NULL DEFAULT '',
  `from_tag` varchar(128) NOT NULL DEFAULT '',
  `to_tag` varchar(128) NOT NULL DEFAULT '',
  `callid` varchar(255) NOT NULL DEFAULT '',
  `sip_code` char(3) NOT NULL DEFAULT '',
  `sip_reason` varchar(255) NOT NULL DEFAULT '',
  `time` datetime NOT NULL DEFAULT current_timestamp(),
  `src_ip` varchar(64) NOT NULL DEFAULT '',
  `dst_ouser` varchar(128) NOT NULL DEFAULT '',
  `dst_user` varchar(128) NOT NULL DEFAULT '',
  `dst_domain` varchar(255) NOT NULL DEFAULT '',
  `src_user` varchar(128) NOT NULL DEFAULT '',
  `src_domain` varchar(255) NOT NULL DEFAULT '',
  `cdr_id` int(10) unsigned NOT NULL DEFAULT 0,
  `calltype` varchar(20) DEFAULT NULL,
  `src_gwgroupid` varchar(10) NOT NULL DEFAULT '',
  `dst_gwgroupid` varchar(10) NOT NULL DEFAULT '',
  PRIMARY KEY (`id`),
  KEY `acc_callid` (`callid`)
) ENGINE=InnoDB AUTO_INCREMENT=554 DEFAULT CHARSET=utf8mb3 COLLATE=utf8mb3_general_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `acc`
--

LOCK TABLES `acc` WRITE;
/*!40000 ALTER TABLE `acc` DISABLE KEYS */;
INSERT INTO `acc` VALUES
(1,'INVITE','gj5nvj520l','z9hG4bK9459.ab9a3880bcc37ff7b04a98641fe099de.0','6gctvgn638rp4ffo6hg3','401','Unauthorized','2025-07-18 00:36:35','50.192.97.226','2000','2000','test.dsiprouter.net','2000','test.dsiprouter.net',0,'','56','1'),
(2,'INVITE','gj5nvj520l','90292834-880a-4c93-b76e-de1221320166','6gctvgn638rp4ffo6hg3','487','Request Terminated','2025-07-18 00:36:39','50.192.97.226','2000','2000','test.dsiprouter.net','2000','test.dsiprouter.net',0,'','56','1'),
(3,'INVITE','b18afa15-342b-41db-8a42-ad58dff8a347','','4035471a-b8c8-4f5b-9079-d97a8ffd0b58','487','Request Terminated','2025-07-18 00:37:05','143.198.44.195','068e0tg1','068e0tg1','52.41.52.34','2000','52.41.52.34',0,'outbound','','2'),
(4,'INVITE','1ocgoffjjv','z9hG4bK1f31.02b1b39607c857626603aea42c091658.0','6gctvjqjpheg83133pb7','401','Unauthorized','2025-07-18 00:39:35','50.192.97.226','2001','2001','test.dsiprouter.net','2000','test.dsiprouter.net',0,'','56','1'),
(5,'INVITE','ab77c887-56a8-4ea4-9a64-da6192b1e50f','3ab2852c','12e9af0b-af86-4f06-8705-58709aec288c','200','OK','2025-07-18 00:39:39','143.198.44.195','2001','2001','50.192.97.226','2000','143.198.44.195',1,'','',''),
(6,'INVITE','1ocgoffjjv','bf7493ee-a140-4bb0-a3e8-635d0e904dd4','6gctvjqjpheg83133pb7','200','OK','2025-07-18 00:39:39','50.192.97.226','2001','2001','test.dsiprouter.net','2000','test.dsiprouter.net',2,'','56','1'),
(7,'BYE','1ocgoffjjv','bf7493ee-a140-4bb0-a3e8-635d0e904dd4','6gctvjqjpheg83133pb7','200','OK','2025-07-18 00:39:39','50.192.97.226','2001','2001','143.198.44.195','2000','test.dsiprouter.net',2,'','56','1'),
(8,'BYE','ab77c887-56a8-4ea4-9a64-da6192b1e50f','3ab2852c','12e9af0b-af86-4f06-8705-58709aec288c','200','OK','2025-07-18 00:39:39','143.198.44.195','2001','2001','50.192.97.226','2000','143.198.44.195',1,'','',''),
(9,'INVITE','5kapev0npa','z9hG4bK465a.8e3300bb9de55e2ba5eb14c6ba8feabc.0','6gctv6sbgs8obj4la82e','401','Unauthorized','2025-07-18 00:40:31','50.192.97.226','2001','2001','test.dsiprouter.net','2000','test.dsiprouter.net',0,'','56','1'),
(10,'INVITE','73677323-a132-4b9c-a7b1-bb538735c89f','d201f37c','23d3b164-ff5f-44cc-ab44-e9e977d8dd9c','200','OK','2025-07-18 00:40:36','143.198.44.195','2001','2001','50.192.97.226','2000','143.198.44.195',3,'','',''),
(11,'INVITE','5kapev0npa','d85a8fe3-c637-4355-967c-c78403cb34da','6gctv6sbgs8obj4la82e','200','OK','2025-07-18 00:40:36','50.192.97.226','2001','2001','test.dsiprouter.net','2000','test.dsiprouter.net',4,'','',''),
(12,'BYE','5kapev0npa','d85a8fe3-c637-4355-967c-c78403cb34da','6gctv6sbgs8obj4la82e','200','OK','2025-07-18 00:40:37','50.192.97.226','2001','2001','143.198.44.195','2000','test.dsiprouter.net',4,'','',''),
(13,'BYE','73677323-a132-4b9c-a7b1-bb538735c89f','d201f37c','23d3b164-ff5f-44cc-ab44-e9e977d8dd9c','200','OK','2025-07-18 00:40:37','143.198.44.195','2001','2001','50.192.97.226','2000','143.198.44.195',3,'','',''),
(14,'INVITE','t1fpqeaujq','z9hG4bK411.8f2557eb7ff260b464329db29aee2670.0','6gctv0g4u3k4oeidq3hu','401','Unauthorized','2025-07-18 00:47:52','50.192.97.226','2001','2001','test.dsiprouter.net','2000','test.dsiprouter.net',0,'','56','1'),
(15,'INVITE','0fbd9601-c77b-459b-89ef-0adb9a01d918','a175324b','f8a4c0df-85bf-486b-86c3-05413cbf1f17','200','OK','2025-07-18 00:48:05','143.198.44.195','2001','2001','50.192.97.226','2000','143.198.44.195',5,'','',''),
(16,'INVITE','t1fpqeaujq','ef1ecac6-ace4-4510-a039-7f9f572ad8aa','6gctv0g4u3k4oeidq3hu','200','OK','2025-07-18 00:48:05','50.192.97.226','2001','2001','test.dsiprouter.net','2000','test.dsiprouter.net',6,'','',''),
(17,'BYE','t1fpqeaujq','ef1ecac6-ace4-4510-a039-7f9f572ad8aa','6gctv0g4u3k4oeidq3hu','200','OK','2025-07-18 00:48:05','50.192.97.226','2001','2001','143.198.44.195','2000','test.dsiprouter.net',6,'','',''),
(18,'BYE','0fbd9601-c77b-459b-89ef-0adb9a01d918','a175324b','f8a4c0df-85bf-486b-86c3-05413cbf1f17','200','OK','2025-07-18 00:48:05','143.198.44.195','2001','2001','50.192.97.226','2000','143.198.44.195',5,'','',''),
(19,'INVITE','k52ebdo4n6','z9hG4bK0fb.8bcba9a5aed4d5dd896a7ae99ff8172c.0','6gctvc79iokc6a0f1s77','401','Unauthorized','2025-07-18 00:57:39','50.192.97.226','2001','2001','test.dsiprouter.net','2000','test.dsiprouter.net',0,'','56','1'),
(20,'INVITE','7b4c7bd9-0605-4836-b688-a64cbb5cc3e5','52783c55','f40698c8-749c-4325-b618-df6422882716','200','OK','2025-07-18 00:57:42','143.198.44.195','2001','2001','50.192.97.226','2000','143.198.44.195',7,'','',''),
(21,'INVITE','k52ebdo4n6','685abf69-1b8a-45d2-aadb-cfba82cb34b2','6gctvc79iokc6a0f1s77','200','OK','2025-07-18 00:57:42','50.192.97.226','2001','2001','test.dsiprouter.net','2000','test.dsiprouter.net',8,'','56','1'),
(22,'BYE','52783c55','7b4c7bd9-0605-4836-b688-a64cbb5cc3e5','f40698c8-749c-4325-b618-df6422882716','200','OK','2025-07-18 00:57:57','50.192.97.226','2000','asterisk','143.198.44.195','2001','146.190.253.188',0,'','',''),
(23,'BYE','685abf69-1b8a-45d2-aadb-cfba82cb34b2','k52ebdo4n6','6gctvc79iokc6a0f1s77','200','OK','2025-07-18 00:57:57','143.198.44.195','2000','068e0tg1','n0eciob64cns.invalid','2001','test.dsiprouter.net',0,'','',''),
(24,'INVITE','3d5a4a72','z9hG4bKfb1f.e1bbea973265ee046a2abcb64a520e5a.0','zL8AMSwXuacjD7Tnzy08Ag..','401','Unauthorized','2025-07-18 01:00:28','50.192.97.226','2000','2000','test.dsiprouter.net','2001','test.dsiprouter.net',0,'','56','1'),
(25,'INVITE','3d5a4a72','073bf9c0-5609-4cef-af4d-7f8858ce6884','zL8AMSwXuacjD7Tnzy08Ag..','487','Request Terminated','2025-07-18 01:00:43','50.192.97.226','2000','2000','test.dsiprouter.net','2001','test.dsiprouter.net',0,'','',''),
(26,'INVITE','3d4853f4-94a9-4824-9b3c-64a28248214f','','9558a4fe-b1f5-441e-a69b-b8aeaa00b714','487','Request Terminated','2025-07-18 01:00:59','143.198.44.195','068e0tg1','068e0tg1','52.41.52.34','2001','52.41.52.34',0,'outbound','','2'),
(27,'INVITE','01565d57','z9hG4bK7136.17a5c2f6d6e163c3ee465dc16f7a0f74.0','XVDo4NXTl_LO_p-bUNHpZw..','401','Unauthorized','2025-07-18 01:01:10','50.192.97.226','2000','2000','test.dsiprouter.net','2001','test.dsiprouter.net',0,'','56','1'),
(28,'INVITE','01565d57','ed967d5e-c9cf-44de-9297-436842a4245c','XVDo4NXTl_LO_p-bUNHpZw..','200','OK','2025-07-18 01:01:26','50.192.97.226','2000','2000','test.dsiprouter.net','2001','test.dsiprouter.net',9,'','',''),
(29,'BYE','01565d57','ed967d5e-c9cf-44de-9297-436842a4245c','XVDo4NXTl_LO_p-bUNHpZw..','200','OK','2025-07-18 01:01:27','50.192.97.226','2000','','143.198.44.195','2001','test.dsiprouter.net',9,'','',''),
(30,'INVITE','f090d2b2-0b51-401e-93a8-18c05e6ec3ed','','724bf92b-9752-4a67-b202-afd3d82f4006','487','Request Terminated','2025-07-18 01:01:40','143.198.44.195','068e0tg1','068e0tg1','52.41.52.34','2001','52.41.52.34',0,'outbound','','2'),
(31,'INVITE','f4e3f57a','z9hG4bKef2d.3a78cd50a2b8c972439bfb4776f6ffb2.0','BcMdGz1BSJuEOT2UIvMQqg..','401','Unauthorized','2025-07-18 01:08:18','50.192.97.226','2000','2000','test.dsiprouter.net','2001','test.dsiprouter.net',0,'','56','1'),
(32,'INVITE','f4e3f57a','f2dbb35d-615d-4ec5-a1ac-458c9c179ce4','BcMdGz1BSJuEOT2UIvMQqg..','200','OK','2025-07-18 01:08:33','50.192.97.226','2000','2000','test.dsiprouter.net','2001','test.dsiprouter.net',10,'','',''),
(33,'BYE','f4e3f57a','f2dbb35d-615d-4ec5-a1ac-458c9c179ce4','BcMdGz1BSJuEOT2UIvMQqg..','200','OK','2025-07-18 01:08:35','50.192.97.226','2000','','143.198.44.195','2001','test.dsiprouter.net',10,'','',''),
(34,'INVITE','e71f3c90-8200-4e01-968d-e6f5908bed5b','','78d318af-cd34-4c80-aab5-6486759f063d','487','Request Terminated','2025-07-18 01:08:48','143.198.44.195','068e0tg1','068e0tg1','52.41.52.34','2001','52.41.52.34',0,'outbound','','2'),
(35,'INVITE','becd3605','z9hG4bK5dd3.062de445459e7e7526a636149df66399.0','PTeIzkKSbYkUUxmSDVIFrA..','401','Unauthorized','2025-07-18 01:14:36','50.192.97.226','2000','2000','test.dsiprouter.net','2001','test.dsiprouter.net',0,'','56','1'),
(36,'INVITE','becd3605','c9faebc1-51c7-434d-bb65-5adbfbcd04ba','PTeIzkKSbYkUUxmSDVIFrA..','487','Request Terminated','2025-07-18 01:14:47','50.192.97.226','2000','2000','test.dsiprouter.net','2001','test.dsiprouter.net',0,'','',''),
(37,'INVITE','ac91dd24-15c6-4351-b970-f962a8471024','','c5b2c80a-b206-416c-a02a-c134c668feda','487','Request Terminated','2025-07-18 01:15:06','143.198.44.195','068e0tg1','068e0tg1','52.41.52.34','2001','52.41.52.34',0,'outbound','','2'),
(38,'INVITE','c18ab75a','z9hG4bK6983.edc0c634394c751b04d244416cd51ed9.0','0hBrIfAgMtLKLoppPDj24w..','401','Unauthorized','2025-07-18 01:47:41','50.192.97.226','2000','2000','test.dsiprouter.net','2001','test.dsiprouter.net',0,'','56','1'),
(39,'INVITE','c18ab75a','a6dceca2-2a90-47c6-831b-7b94e458f950','0hBrIfAgMtLKLoppPDj24w..','487','Request Terminated','2025-07-18 01:47:51','50.192.97.226','2000','2000','test.dsiprouter.net','2001','test.dsiprouter.net',0,'','',''),
(40,'INVITE','4c8c1db4-1ef8-4597-aca0-e3e846b99b5e','','10bb5bb4-9b6a-4d7d-a1d9-0176f0602513','487','Request Terminated','2025-07-18 01:48:11','143.198.44.195','068e0tg1','068e0tg1','52.41.52.34','2001','52.41.52.34',0,'outbound','','2'),
(41,'INVITE','9513d73b','z9hG4bK138f.faa99b54807115ebdfbd86a31898b45b.0','KzCeEt_5R-U3tdN5Bckadg..','401','Unauthorized','2025-07-18 01:51:27','50.192.97.226','2000','2000','test.dsiprouter.net','2001','test.dsiprouter.net',0,'','56','1'),
(42,'INVITE','9513d73b','17810ca9-4af2-4af2-a960-1be76f5da327','KzCeEt_5R-U3tdN5Bckadg..','200','OK','2025-07-18 01:51:43','50.192.97.226','2000','2000','test.dsiprouter.net','2001','test.dsiprouter.net',11,'','',''),
(43,'BYE','9513d73b','17810ca9-4af2-4af2-a960-1be76f5da327','KzCeEt_5R-U3tdN5Bckadg..','200','OK','2025-07-18 01:51:43','50.192.97.226','2000','','143.198.44.195','2001','test.dsiprouter.net',11,'','',''),
(44,'INVITE','7c85f09f-3c1c-4b55-8ca4-4fee8d5e5f37','','60ac07b3-4535-4e9f-9528-09392d304965','487','Request Terminated','2025-07-18 01:51:58','143.198.44.195','068e0tg1','068e0tg1','52.41.52.34','2001','52.41.52.34',0,'outbound','','2'),
(45,'INVITE','9ae3d27c','z9hG4bK8e05.23441b9e410a2f3223ac7a47cc5ae296.0','ILmOuFIsbxnVY0YQhyEsxw..','401','Unauthorized','2025-07-18 01:53:58','50.192.97.226','2000','2000','test.dsiprouter.net','2001','test.dsiprouter.net',0,'','56','1'),
(46,'INVITE','9ae3d27c','f78d4eb9-4dc8-4bc8-86bf-9fadb3447a8d','ILmOuFIsbxnVY0YQhyEsxw..','487','Request Terminated','2025-07-18 01:54:08','50.192.97.226','2000','2000','test.dsiprouter.net','2001','test.dsiprouter.net',0,'','',''),
(47,'INVITE','f2099619-f789-405f-8b2d-e94b5e5a8cc8','','40d57318-6f73-4848-924d-b5c47e87666a','487','Request Terminated','2025-07-18 01:54:29','143.198.44.195','068e0tg1','068e0tg1','52.41.52.34','2001','52.41.52.34',0,'outbound','','2'),
(48,'INVITE','661a163d','z9hG4bK8e9.e17f3efd4cad0a218698568122e74a4c.0','zGMogbVpyPPOVgYEnCqMfg..','401','Unauthorized','2025-07-18 01:56:33','50.192.97.226','2000','2000','test.dsiprouter.net','2001','test.dsiprouter.net',0,'','56','1'),
(49,'INVITE','661a163d','7184ad3c-59b2-4eb7-b6e8-0807a7aabb95','zGMogbVpyPPOVgYEnCqMfg..','200','OK','2025-07-18 01:56:48','50.192.97.226','2000','2000','test.dsiprouter.net','2001','test.dsiprouter.net',12,'','',''),
(50,'BYE','661a163d','7184ad3c-59b2-4eb7-b6e8-0807a7aabb95','zGMogbVpyPPOVgYEnCqMfg..','200','OK','2025-07-18 01:56:51','50.192.97.226','2000','','143.198.44.195','2001','test.dsiprouter.net',12,'','',''),
(51,'INVITE','a4ec7094-81fb-41f9-809b-f18df9c892e1','','09a003bc-2b05-4dc8-bf57-897df34a159c','487','Request Terminated','2025-07-18 01:57:03','143.198.44.195','068e0tg1','068e0tg1','52.41.52.34','2001','52.41.52.34',0,'outbound','','2'),
(52,'INVITE','328ea419','z9hG4bK98c9.7b34821195743081419e4e8a0abec518.0','zt8_y5dXtnmXVdCAEUUkkQ..','401','Unauthorized','2025-07-18 01:58:06','50.192.97.226','2000','2000','test.dsiprouter.net','2001','test.dsiprouter.net',0,'','56','1'),
(53,'INVITE','328ea419','7b64a262-296d-4e16-9f19-72bca321d671','zt8_y5dXtnmXVdCAEUUkkQ..','200','OK','2025-07-18 01:58:06','50.192.97.226','2000','2000','test.dsiprouter.net','2001','test.dsiprouter.net',13,'','56','1'),
(54,'BYE','328ea419','7b64a262-296d-4e16-9f19-72bca321d671','zt8_y5dXtnmXVdCAEUUkkQ..','200','OK','2025-07-18 01:58:13','50.192.97.226','2000','','143.198.44.195','2001','test.dsiprouter.net',13,'','',''),
(55,'INVITE','a8a0d275','z9hG4bKc41d.5fe8b43f58fe12c9ed1193f0eebe77ad.0','QftiU4nEv01MHa63HwRdhg..','401','Unauthorized','2025-07-18 01:58:27','50.192.97.226','2000','2000','test.dsiprouter.net','2001','test.dsiprouter.net',0,'','56','1'),
(56,'INVITE','a8a0d275','686cf599-550d-4c83-bebe-a0fc2b836919','QftiU4nEv01MHa63HwRdhg..','200','OK','2025-07-18 01:58:28','50.192.97.226','2000','2000','test.dsiprouter.net','2001','test.dsiprouter.net',14,'','56','1'),
(57,'BYE','a8a0d275','686cf599-550d-4c83-bebe-a0fc2b836919','QftiU4nEv01MHa63HwRdhg..','200','OK','2025-07-18 01:58:30','50.192.97.226','2000','','143.198.44.195','2001','test.dsiprouter.net',14,'','56','1'),
(58,'INVITE','bef8e15f','z9hG4bK0f04.a46debb83724bb70dfab18e3fa63057a.0','nrw-fHqZSUUoxgfvU5aMuQ..','401','Unauthorized','2025-07-18 01:58:43','50.192.97.226','2000','2000','test.dsiprouter.net','2001','test.dsiprouter.net',0,'','56','1'),
(59,'INVITE','bef8e15f','5e224e63-7583-43ce-9572-3fcffc00ff4a','nrw-fHqZSUUoxgfvU5aMuQ..','487','Request Terminated','2025-07-18 01:58:58','50.192.97.226','2000','2000','test.dsiprouter.net','2001','test.dsiprouter.net',0,'','',''),
(60,'INVITE','fb4a1e06-eae0-4923-8b71-be36afa20d8b','','fe3525aa-9bff-4fae-ac5b-32954ff49697','487','Request Terminated','2025-07-18 01:59:13','143.198.44.195','068e0tg1','068e0tg1','52.41.52.34','2001','52.41.52.34',0,'outbound','','2'),
(61,'INVITE','98735046','z9hG4bK7f31.e6eae1fd8d392680d9e98130f94de9ec.0','Mf-lZQ_zZzkA_qXx7hRLWQ..','401','Unauthorized','2025-07-18 02:02:21','50.192.97.226','2000','2000','test.dsiprouter.net','2001','test.dsiprouter.net',0,'','56','1'),
(62,'INVITE','98735046','46b6d1ad-e19e-4722-b5a1-37acdb17e498','Mf-lZQ_zZzkA_qXx7hRLWQ..','487','Request Terminated','2025-07-18 02:02:29','50.192.97.226','2000','2000','test.dsiprouter.net','2001','test.dsiprouter.net',0,'','',''),
(63,'INVITE','11792e6d-b48d-49d9-81da-9733532c98d2','','6d1f947a-809a-416e-a5c6-62a64b418f6f','487','Request Terminated','2025-07-18 02:02:51','143.198.44.195','068e0tg1','068e0tg1','52.41.52.34','2001','52.41.52.34',0,'outbound','','2'),
(64,'INVITE','683fbd3c','z9hG4bK284f.39433986aee5d00f71bd435447e40d37.0','n1NX0C6Cvr63ZMrhn22UGw..','401','Unauthorized','2025-07-18 03:40:46','50.192.97.226','2000','2000','test.dsiprouter.net','2001','test.dsiprouter.net',0,'','56','1'),
(65,'INVITE','683fbd3c','d4f815cd-46f0-42f2-a425-319e76a41341','n1NX0C6Cvr63ZMrhn22UGw..','487','Request Terminated','2025-07-18 03:40:57','50.192.97.226','2000','2000','test.dsiprouter.net','2001','test.dsiprouter.net',0,'','',''),
(66,'INVITE','17f2278f-fb7b-4c4c-91dd-94e75383a2a5','','e9e2c741-f8a5-40a9-9719-071f6d883727','487','Request Terminated','2025-07-18 03:41:17','143.198.44.195','068e0tg1','068e0tg1','52.41.52.34','2001','52.41.52.34',0,'outbound','','2'),
(67,'INVITE','43f2330c','z9hG4bKbc8e.6844e4b20b98cc730aac4bd2ca96e7a2.0','C8zQBka1EpNy7u-wBPH2xw..','401','Unauthorized','2025-07-18 03:42:55','50.192.97.226','2000','2000','test.dsiprouter.net','2001','test.dsiprouter.net',0,'','56','1'),
(68,'INVITE','43f2330c','93b73463-e07f-439c-acc0-ee4953e08b90','C8zQBka1EpNy7u-wBPH2xw..','487','Request Terminated','2025-07-18 03:43:10','50.192.97.226','2000','2000','test.dsiprouter.net','2001','test.dsiprouter.net',0,'','',''),
(69,'INVITE','bd942e76-04b5-4f82-b38b-31f84602393e','','30f0e8a5-0e12-44dc-81a2-11d5fd912fee','487','Request Terminated','2025-07-18 03:43:25','143.198.44.195','068e0tg1','068e0tg1','52.41.52.34','2001','52.41.52.34',0,'outbound','','2'),
(70,'INVITE','c8cbe924','z9hG4bKa9a2.e6c1e8f6fbcd6b4b80bb1b03598a30a4.0','jHEjw2tsEusNKRMXNY1IXg..','401','Unauthorized','2025-07-18 03:50:46','50.192.97.226','2000','2000','test.dsiprouter.net','2001','test.dsiprouter.net',0,'','56','1'),
(71,'INVITE','c8cbe924','f5c8d214-3a4d-4784-90a6-e6868de9e365','jHEjw2tsEusNKRMXNY1IXg..','200','OK','2025-07-18 03:50:46','50.192.97.226','2000','2000','test.dsiprouter.net','2001','test.dsiprouter.net',15,'','56','1'),
(72,'BYE','c8cbe924','f5c8d214-3a4d-4784-90a6-e6868de9e365','jHEjw2tsEusNKRMXNY1IXg..','200','OK','2025-07-18 03:50:50','50.192.97.226','2000','','143.198.44.195','2001','test.dsiprouter.net',15,'','56','1'),
(73,'INVITE','bfbe5b6a','z9hG4bK9cb.1817e8efdfcf7ac72eb96f8cbffc9a18.0','Bi1g9sxNBmuNH3ZxPk4HHQ..','401','Unauthorized','2025-07-18 03:51:05','50.192.97.226','2000','2000','test.dsiprouter.net','2001','test.dsiprouter.net',0,'','56','1'),
(74,'INVITE','bfbe5b6a','f8a6b7d3-286c-4236-8efc-79c264fd41d0','Bi1g9sxNBmuNH3ZxPk4HHQ..','200','OK','2025-07-18 03:51:20','50.192.97.226','2000','2000','test.dsiprouter.net','2001','test.dsiprouter.net',16,'','',''),
(75,'BYE','bfbe5b6a','f8a6b7d3-286c-4236-8efc-79c264fd41d0','Bi1g9sxNBmuNH3ZxPk4HHQ..','200','OK','2025-07-18 03:51:24','50.192.97.226','2000','','143.198.44.195','2001','test.dsiprouter.net',16,'','',''),
(76,'INVITE','b088f561-9b77-476d-98e5-303347d0b3da','','f796a4f9-6e4e-4b1d-b244-a8bac09f7381','487','Request Terminated','2025-07-18 03:51:35','143.198.44.195','068e0tg1','068e0tg1','52.41.52.34','2001','52.41.52.34',0,'outbound','','2'),
(77,'INVITE','af07f529','z9hG4bKae3f.cf2f9aeaa51b05adcd76c5fe6cefa1d3.0','XVLeVWP7PpEpGVw_GNYnpw..','401','Unauthorized','2025-07-18 03:55:44','50.192.97.226','2000','2000','test.dsiprouter.net','2001','test.dsiprouter.net',0,'','56','1'),
(78,'INVITE','af07f529','7b182ab5-ac5b-4957-b133-d5a43b811fc6','XVLeVWP7PpEpGVw_GNYnpw..','200','OK','2025-07-18 03:56:00','50.192.97.226','2000','2000','test.dsiprouter.net','2001','test.dsiprouter.net',17,'','',''),
(79,'BYE','af07f529','7b182ab5-ac5b-4957-b133-d5a43b811fc6','XVLeVWP7PpEpGVw_GNYnpw..','200','OK','2025-07-18 03:56:03','50.192.97.226','2000','','143.198.44.195','2001','test.dsiprouter.net',17,'','',''),
(80,'INVITE','841fb661','z9hG4bK536d.a51cac9ba35a9b7d5b19c762e83ab794.0','28hBY-UOvyCEtHZZkePzZQ..','401','Unauthorized','2025-07-18 03:56:14','50.192.97.226','2000','2000','test.dsiprouter.net','2001','test.dsiprouter.net',0,'','56','1'),
(81,'INVITE','ff9c3af9-e463-4460-89b2-9e3a93bf7ce0','','0a94dbf9-e5cc-4c65-a40f-ec36c1c9ea71','487','Request Terminated','2025-07-18 03:56:15','143.198.44.195','068e0tg1','068e0tg1','52.41.52.34','2001','52.41.52.34',0,'outbound','','2'),
(82,'INVITE','841fb661','dddf4e6c-7d47-4217-8797-0f33ce53f2de','28hBY-UOvyCEtHZZkePzZQ..','487','Request Terminated','2025-07-18 03:56:20','50.192.97.226','2000','2000','test.dsiprouter.net','2001','test.dsiprouter.net',0,'','',''),
(83,'INVITE','1ebc0087-05ff-44b8-99f2-73aea0b09b98','','b2811ccb-0f55-461d-91a6-c488dcac96d4','487','Request Terminated','2025-07-18 03:56:44','143.198.44.195','068e0tg1','068e0tg1','52.41.52.34','2001','52.41.52.34',0,'outbound','','2'),
(84,'INVITE','c30a6a56','z9hG4bKfac2.4caab0e5571eacde6b0a8388ededf2f1.0','NrsB5lqXBtYCLVuwN5K7rQ..','401','Unauthorized','2025-07-18 03:58:06','50.192.97.226','2000','2000','test.dsiprouter.net','2001','test.dsiprouter.net',0,'','56','1'),
(85,'INVITE','c30a6a56','b5dc7c43-0728-41f3-a561-870ff99bda51','NrsB5lqXBtYCLVuwN5K7rQ..','487','Request Terminated','2025-07-18 03:58:15','50.192.97.226','2000','2000','test.dsiprouter.net','2001','test.dsiprouter.net',0,'','',''),
(86,'INVITE','48d6b893-82b2-4111-a7f6-17b12ecf17d3','','1e50f7f6-1ab6-41a0-8e63-472d090d851a','487','Request Terminated','2025-07-18 03:58:36','143.198.44.195','068e0tg1','068e0tg1','52.41.52.34','2001','52.41.52.34',0,'outbound','','2'),
(87,'INVITE','0d780c3f','z9hG4bKc001.0411b7e8d63db23eb0c5bee6937e3299.0','jvokpPZB_xPxPucq9_AKJw..','401','Unauthorized','2025-07-18 04:00:38','50.192.97.226','2000','2000','test.dsiprouter.net','2001','test.dsiprouter.net',0,'','56','1'),
(88,'INVITE','0d780c3f','0ab7027d-af4d-41b9-aaf5-0d0e3c6678e2','jvokpPZB_xPxPucq9_AKJw..','200','OK','2025-07-18 04:00:53','50.192.97.226','2000','2000','test.dsiprouter.net','2001','test.dsiprouter.net',18,'','',''),
(89,'BYE','0d780c3f','0ab7027d-af4d-41b9-aaf5-0d0e3c6678e2','jvokpPZB_xPxPucq9_AKJw..','200','OK','2025-07-18 04:00:54','50.192.97.226','2000','','143.198.44.195','2001','test.dsiprouter.net',18,'','',''),
(90,'INVITE','43e7e0f0-7fb0-4e27-8d8c-3937af29e9f3','','e333b214-8d75-4da7-8f4d-b9b69c326aed','487','Request Terminated','2025-07-18 04:01:08','143.198.44.195','068e0tg1','068e0tg1','52.41.52.34','2001','52.41.52.34',0,'outbound','','2'),
(91,'INVITE','51ac6130','z9hG4bK1795.c419e2a8f202d2b6caf9343b5c47d34d.0','VBxJq1IXREt5lArdzPKuTg..','401','Unauthorized','2025-07-18 04:05:18','50.192.97.226','2000','2000','test.dsiprouter.net','2001','test.dsiprouter.net',0,'','56','1'),
(92,'INVITE','51ac6130','051aa48f-5186-45b6-ada0-4fb515537891','VBxJq1IXREt5lArdzPKuTg..','200','OK','2025-07-18 04:05:34','50.192.97.226','2000','2000','test.dsiprouter.net','2001','test.dsiprouter.net',19,'','',''),
(93,'BYE','51ac6130','051aa48f-5186-45b6-ada0-4fb515537891','VBxJq1IXREt5lArdzPKuTg..','200','OK','2025-07-18 04:05:43','50.192.97.226','2000','','143.198.44.195','2001','test.dsiprouter.net',19,'','',''),
(94,'INVITE','f0e98997-d700-495c-8022-9b01b4420821','','6f388bbd-ad0e-4f56-9049-e1d38fc344db','487','Request Terminated','2025-07-18 04:05:48','143.198.44.195','068e0tg1','068e0tg1','52.41.52.34','2001','52.41.52.34',0,'outbound','','2'),
(95,'INVITE','b4a10119','z9hG4bK83c5.64be3b2eb601e939fbf9fc4b80da0c17.0','PR_AT48gVvGtamUqblL3AA..','401','Unauthorized','2025-07-18 04:14:39','50.192.97.226','2000','2000','test.dsiprouter.net','2001','test.dsiprouter.net',0,'','56','1'),
(96,'INVITE','9fd44f9e-95e6-4c53-a0d9-a1541f6c21fb','jmgbl11p92','36b77a58-9942-440c-bcbf-e81537472b3c','488','Not Acceptable Here','2025-07-18 04:14:44','143.198.44.195','068e0tg1','068e0tg1','n0eciob64cns.invalid','2001','143.198.44.195',0,'','',''),
(97,'INVITE','b4a10119','0378dfc1-0bee-40bf-bd98-52e69ea3ce0f','PR_AT48gVvGtamUqblL3AA..','200','OK','2025-07-18 04:14:44','50.192.97.226','2000','2000','test.dsiprouter.net','2001','test.dsiprouter.net',20,'','',''),
(98,'BYE','b4a10119','0378dfc1-0bee-40bf-bd98-52e69ea3ce0f','PR_AT48gVvGtamUqblL3AA..','200','OK','2025-07-18 04:14:56','50.192.97.226','2000','','143.198.44.195','2001','test.dsiprouter.net',20,'','',''),
(99,'INVITE','dad2dd70','z9hG4bKcb27.a4831556db763c9f9bdfe9031eaab91a.0','3YE80Cx4X9dWtQPVDRd2Ng..','401','Unauthorized','2025-07-18 04:17:51','50.192.97.226','2000','2000','test.dsiprouter.net','2001','test.dsiprouter.net',0,'','56','1'),
(100,'INVITE','de74f092-3c4c-40c0-9c05-a67206607609','74r9k37gar','2f36b0bf-cc7b-41f7-8bf7-68d670cbf5d5','488','Not Acceptable Here','2025-07-18 04:17:59','143.198.44.195','068e0tg1','068e0tg1','n0eciob64cns.invalid','2001','143.198.44.195',0,'','',''),
(101,'INVITE','dad2dd70','9b30f7f1-d591-4c1d-9a31-2955c349b3c3','3YE80Cx4X9dWtQPVDRd2Ng..','200','OK','2025-07-18 04:17:59','50.192.97.226','2000','2000','test.dsiprouter.net','2001','test.dsiprouter.net',21,'','',''),
(102,'BYE','dad2dd70','9b30f7f1-d591-4c1d-9a31-2955c349b3c3','3YE80Cx4X9dWtQPVDRd2Ng..','200','OK','2025-07-18 04:18:08','50.192.97.226','2000','','143.198.44.195','2001','test.dsiprouter.net',21,'','',''),
(103,'INVITE','8f93cc1b','z9hG4bK699b.95261a8d98eda1942ea1aee526795e32.0','cq2BVTuBA1nG5aT4g4fkwg..','401','Unauthorized','2025-07-18 04:22:53','50.192.97.226','2000','2000','test.dsiprouter.net','2001','test.dsiprouter.net',0,'','56','1'),
(104,'INVITE','b8b7b75d-9a37-4e7e-a7bb-3b36740508ae','stdi2jmcde','2291a552-b53f-4eb3-af49-7da08bc3fee6','200','OK','2025-07-18 04:22:56','143.198.44.195','068e0tg1','068e0tg1','n0eciob64cns.invalid','2001','143.198.44.195',22,'','',''),
(105,'INVITE','8f93cc1b','33a373f4-498f-49b2-8c5a-dc3fd2c9ffba','cq2BVTuBA1nG5aT4g4fkwg..','200','OK','2025-07-18 04:22:56','50.192.97.226','2000','2000','test.dsiprouter.net','2001','test.dsiprouter.net',23,'','56','1'),
(106,'BYE','stdi2jmcde','b8b7b75d-9a37-4e7e-a7bb-3b36740508ae','2291a552-b53f-4eb3-af49-7da08bc3fee6','200','OK','2025-07-18 04:23:28','50.192.97.226','2001','asterisk','143.198.44.195','068e0tg1','146.190.253.188',0,'','',''),
(107,'BYE','33a373f4-498f-49b2-8c5a-dc3fd2c9ffba','8f93cc1b','cq2BVTuBA1nG5aT4g4fkwg..','200','OK','2025-07-18 04:23:28','143.198.44.195','2001','2001','50.192.97.226','2000','test.dsiprouter.net',0,'','',''),
(108,'INVITE','06fc655b','z9hG4bK6b3a.6f7df247c198f80a975b152bb52e1cec.0','b0QInEIov2xdN8N3tcEzMw..','401','Unauthorized','2025-07-18 10:50:01','50.192.97.226','2000','2000','test.dsiprouter.net','2001','test.dsiprouter.net',0,'','56','1'),
(109,'INVITE','b3eba65f-f92f-4321-be23-bd69dfac06e3','qjoj3rnmu4','34d370a9-b53f-441d-9597-996f194853c1','200','OK','2025-07-18 10:50:06','143.198.44.195','068e0tg1','068e0tg1','n0eciob64cns.invalid','2001','143.198.44.195',24,'','',''),
(110,'INVITE','06fc655b','fef763d6-2cd2-4a0c-a37e-d1173cf7ceef','b0QInEIov2xdN8N3tcEzMw..','200','OK','2025-07-18 10:50:06','50.192.97.226','2000','2000','test.dsiprouter.net','2001','test.dsiprouter.net',25,'','56','1'),
(111,'BYE','06fc655b','fef763d6-2cd2-4a0c-a37e-d1173cf7ceef','b0QInEIov2xdN8N3tcEzMw..','200','OK','2025-07-18 10:50:32','50.192.97.226','2000','','143.198.44.195','2001','test.dsiprouter.net',25,'','',''),
(112,'BYE','b3eba65f-f92f-4321-be23-bd69dfac06e3','qjoj3rnmu4','34d370a9-b53f-441d-9597-996f194853c1','478','Request Failure','2025-07-18 10:50:32','143.198.44.195','068e0tg1','068e0tg1','n0eciob64cns.invalid','2001','143.198.44.195',24,'','',''),
(113,'BYE','qjoj3rnmu4','b3eba65f-f92f-4321-be23-bd69dfac06e3','34d370a9-b53f-441d-9597-996f194853c1','481','Call/Transaction Does Not Exist','2025-07-18 10:50:38','50.192.97.226','2001','asterisk','143.198.44.195','068e0tg1','146.190.253.188',0,'','',''),
(114,'INVITE','faf5ee12','z9hG4bK347a.0afc6a67e6ff652aa154df54e3eaa108.0','FPoviMRD9FL8swsNDhZWpw..','401','Unauthorized','2025-07-18 10:54:06','50.192.97.226','2000','2000','test.dsiprouter.net','2001','test.dsiprouter.net',0,'','56','1'),
(115,'INVITE','a98ac50a-e843-4d3b-a0a0-b0ba5f58034a','t6om3877nd','15a8e07b-4432-4fdc-934b-7301f930c1ea','200','OK','2025-07-18 10:54:08','143.198.44.195','068e0tg1','068e0tg1','n0eciob64cns.invalid','2001','143.198.44.195',26,'','',''),
(116,'INVITE','faf5ee12','e0a968d5-7c74-47f9-99b1-ca313994331e','FPoviMRD9FL8swsNDhZWpw..','200','OK','2025-07-18 10:54:08','50.192.97.226','2000','2000','test.dsiprouter.net','2001','test.dsiprouter.net',27,'','56','1'),
(117,'BYE','t6om3877nd','a98ac50a-e843-4d3b-a0a0-b0ba5f58034a','15a8e07b-4432-4fdc-934b-7301f930c1ea','200','OK','2025-07-18 10:54:40','50.192.97.226','2001','asterisk','143.198.44.195','068e0tg1','146.190.253.188',0,'','',''),
(118,'BYE','e0a968d5-7c74-47f9-99b1-ca313994331e','faf5ee12','FPoviMRD9FL8swsNDhZWpw..','200','OK','2025-07-18 10:54:41','143.198.44.195','2001','2001','50.192.97.226','2000','test.dsiprouter.net',0,'','',''),
(119,'INVITE','b018ef15','z9hG4bK3e82.016a787178d2937e6630b0978cfb5612.0','7ZsTIHVqwEB4gG7oufk75Q..','401','Unauthorized','2025-07-18 10:55:51','50.192.97.226','2000','2000','test.dsiprouter.net','2001','test.dsiprouter.net',0,'','56','1'),
(120,'INVITE','8cec5052-73ca-4ec6-832e-cd6c7a137198','uquejo141c','150862a5-e519-4d6f-b625-380665f32c21','200','OK','2025-07-18 10:55:57','143.198.44.195','068e0tg1','068e0tg1','n0eciob64cns.invalid','2001','143.198.44.195',28,'','',''),
(121,'INVITE','b018ef15','43311e64-dd9d-4f89-99b7-5018e4a363e8','7ZsTIHVqwEB4gG7oufk75Q..','200','OK','2025-07-18 10:55:57','50.192.97.226','2000','2000','test.dsiprouter.net','2001','test.dsiprouter.net',29,'','',''),
(122,'BYE','b018ef15','43311e64-dd9d-4f89-99b7-5018e4a363e8','7ZsTIHVqwEB4gG7oufk75Q..','200','OK','2025-07-18 10:56:12','50.192.97.226','2000','','143.198.44.195','2001','test.dsiprouter.net',29,'','',''),
(123,'BYE','8cec5052-73ca-4ec6-832e-cd6c7a137198','uquejo141c','150862a5-e519-4d6f-b625-380665f32c21','478','Request Failure','2025-07-18 10:56:12','143.198.44.195','068e0tg1','068e0tg1','n0eciob64cns.invalid','2001','143.198.44.195',28,'','',''),
(124,'BYE','uquejo141c','8cec5052-73ca-4ec6-832e-cd6c7a137198','150862a5-e519-4d6f-b625-380665f32c21','481','Call/Transaction Does Not Exist','2025-07-18 10:56:29','50.192.97.226','2001','asterisk','143.198.44.195','068e0tg1','146.190.253.188',0,'','',''),
(125,'INVITE','95567500','z9hG4bK1466.8a77a30e1b4893b4efa6c46f59345cd4.0','EnSE3ON6FBiJcZg7nAW3xA..','401','Unauthorized','2025-07-18 11:04:09','50.192.97.226','2000','2000','test.dsiprouter.net','2001','test.dsiprouter.net',0,'','56','1'),
(126,'INVITE','c05dce07-ddc3-412a-9576-b486b9ab16cc','179qrnve80','74969bc5-cddc-4e7b-9712-7a0a4ddc7221','200','OK','2025-07-18 11:04:13','143.198.44.195','068e0tg1','068e0tg1','n0eciob64cns.invalid','2001','143.198.44.195',30,'','',''),
(127,'INVITE','95567500','941ba565-a574-4e50-9779-bb5f9dd87ee9','EnSE3ON6FBiJcZg7nAW3xA..','200','OK','2025-07-18 11:04:13','50.192.97.226','2000','2000','test.dsiprouter.net','2001','test.dsiprouter.net',31,'','56','1'),
(128,'BYE','179qrnve80','c05dce07-ddc3-412a-9576-b486b9ab16cc','74969bc5-cddc-4e7b-9712-7a0a4ddc7221','200','OK','2025-07-18 11:11:18','50.192.97.226','2001','asterisk','143.198.44.195','068e0tg1','146.190.253.188',0,'','',''),
(129,'BYE','941ba565-a574-4e50-9779-bb5f9dd87ee9','95567500','EnSE3ON6FBiJcZg7nAW3xA..','200','OK','2025-07-18 11:11:18','143.198.44.195','2001','2001','50.192.97.226','2000','test.dsiprouter.net',0,'','',''),
(130,'INVITE','5d1dv7dj4i','z9hG4bK3d84.2b17e5fdb619603f5da9c1949fbf65f9.0','6gctvih7dv7fpogqm85k','401','Unauthorized','2025-07-18 11:42:08','50.192.97.226','2001','2001','test.dsiprouter.net','2000','test.dsiprouter.net',0,'','56','1'),
(131,'INVITE','5d1dv7dj4i','739cfd1d-886d-419a-afd8-b2a06990ef51','6gctvih7dv7fpogqm85k','200','OK','2025-07-18 11:42:08','50.192.97.226','2001','2001','test.dsiprouter.net','2000','test.dsiprouter.net',32,'','56','1'),
(132,'BYE','5d1dv7dj4i','739cfd1d-886d-419a-afd8-b2a06990ef51','6gctvih7dv7fpogqm85k','200','OK','2025-07-18 11:42:17','50.192.97.226','2001','2001','143.198.44.195','2000','test.dsiprouter.net',32,'','',''),
(133,'INVITE','i5tfdlhmmc','z9hG4bKc4ba.3a5e9d892d6801f500856c3534c12012.0','6gctvlnpsi7e65nl8ifk','401','Unauthorized','2025-07-18 11:42:30','50.192.97.226','2001','2001','test.dsiprouter.net','2000','test.dsiprouter.net',0,'','56','1'),
(134,'INVITE','3ed1ef93-5adb-4b62-b0a7-d09c77b6da73','9be84269','51dc9473-7ec4-438e-80e1-2bd6910a1c9a','200','OK','2025-07-18 11:42:35','143.198.44.195','2001','2001','50.192.97.226','2000','143.198.44.195',33,'','',''),
(135,'INVITE','i5tfdlhmmc','e2063827-4ec7-42c8-a0bf-6884f82ed63b','6gctvlnpsi7e65nl8ifk','200','OK','2025-07-18 11:42:35','50.192.97.226','2001','2001','test.dsiprouter.net','2000','test.dsiprouter.net',34,'','',''),
(136,'BYE','9be84269','3ed1ef93-5adb-4b62-b0a7-d09c77b6da73','51dc9473-7ec4-438e-80e1-2bd6910a1c9a','200','OK','2025-07-18 11:42:46','50.192.97.226','2000','asterisk','143.198.44.195','2001','146.190.253.188',0,'','',''),
(137,'BYE','e2063827-4ec7-42c8-a0bf-6884f82ed63b','i5tfdlhmmc','6gctvlnpsi7e65nl8ifk','200','OK','2025-07-18 11:42:46','143.198.44.195','2000','068e0tg1','n0eciob64cns.invalid','2001','test.dsiprouter.net',0,'','',''),
(138,'INVITE','07c19qmf0k','z9hG4bK2d04.c55b611f24356f95c9770b66fc916464.0','6gctvl2h5m677tedl73v','401','Unauthorized','2025-07-18 11:50:18','50.192.97.226','2001','2001','test.dsiprouter.net','2000','test.dsiprouter.net',0,'','56','1'),
(139,'INVITE','203e250f-d01b-4ee1-8b33-c79bd4a2ddba','27ec7c73','9ae7000d-206b-471d-9f4f-6884e8cbcc36','200','OK','2025-07-18 11:50:21','143.198.44.195','2001','2001','50.192.97.226','2000','143.198.44.195',35,'','',''),
(140,'INVITE','07c19qmf0k','3af809e9-a547-4300-9870-99f12a0ba94b','6gctvl2h5m677tedl73v','200','OK','2025-07-18 11:50:21','50.192.97.226','2001','2001','test.dsiprouter.net','2000','test.dsiprouter.net',36,'','56','1'),
(141,'BYE','27ec7c73','203e250f-d01b-4ee1-8b33-c79bd4a2ddba','9ae7000d-206b-471d-9f4f-6884e8cbcc36','200','OK','2025-07-18 11:50:36','50.192.97.226','2000','asterisk','143.198.44.195','2001','146.190.253.188',0,'','',''),
(142,'BYE','3af809e9-a547-4300-9870-99f12a0ba94b','07c19qmf0k','6gctvl2h5m677tedl73v','200','OK','2025-07-18 11:50:36','143.198.44.195','2000','068e0tg1','n0eciob64cns.invalid','2001','test.dsiprouter.net',0,'','',''),
(143,'INVITE','6d451e13','z9hG4bK4267.94d59d0af0df0a4f24c86a08202b6bf1.0','LsqdSOuhvgBlSgu6mD02qQ..','401','Unauthorized','2025-07-18 11:50:47','50.192.97.226','2000','2000','test.dsiprouter.net','2001','test.dsiprouter.net',0,'','56','1'),
(144,'INVITE','d85315fb-cde1-40a9-b5da-b186c8c12683','s6bkcjuer4','60cf7ba7-f299-41a3-adf7-e4076938c26e','200','OK','2025-07-18 11:50:49','143.198.44.195','068e0tg1','068e0tg1','n0eciob64cns.invalid','2001','143.198.44.195',37,'','',''),
(145,'INVITE','6d451e13','ea34f396-2b32-48a5-9b49-66f387dd1eec','LsqdSOuhvgBlSgu6mD02qQ..','200','OK','2025-07-18 11:50:49','50.192.97.226','2000','2000','test.dsiprouter.net','2001','test.dsiprouter.net',38,'','56','1'),
(146,'BYE','s6bkcjuer4','d85315fb-cde1-40a9-b5da-b186c8c12683','60cf7ba7-f299-41a3-adf7-e4076938c26e','200','OK','2025-07-18 11:50:54','50.192.97.226','2001','asterisk','143.198.44.195','068e0tg1','146.190.253.188',0,'','',''),
(147,'BYE','ea34f396-2b32-48a5-9b49-66f387dd1eec','6d451e13','LsqdSOuhvgBlSgu6mD02qQ..','200','OK','2025-07-18 11:50:54','143.198.44.195','2001','2001','50.192.97.226','2000','test.dsiprouter.net',0,'','',''),
(148,'INVITE','gK0c1bc4f8','43d5a9ef-fdbc-4753-86d0-ad786e95b3de','208428479_133162762@206.147.88.72','200','OK','2025-10-24 03:04:54','34.226.36.33','proj_MrxkZ5BlbAFrpJXiyZBrs6mq','proj_MrxkZ5BlbAFrpJXiyZBrs6mq','sip.api.openai.com','+19475176566','fl.gg',39,'inbound','','14'),
(149,'BYE','gK0c1bc4f8','43d5a9ef-fdbc-4753-86d0-ad786e95b3de','208428479_133162762@206.147.88.72','408','Request Timeout','2025-10-24 03:06:19','34.226.36.33','proj_MrxkZ5BlbAFrpJXiyZBrs6mq','OAI','sip.api.openai.com','+19475176566','fl.gg',39,'','','14'),
(150,'INVITE','gK040c0fc7','b2850e68-1dc2-42df-b64a-961410be08ce','438587087_132045321@74.120.93.30','200','OK','2025-10-24 03:20:14','34.226.36.33','proj_MrxkZ5BlbAFrpJXiyZBrs6mq','proj_MrxkZ5BlbAFrpJXiyZBrs6mq','sip.api.openai.com','+19475176566','fl.gg',40,'inbound','','14'),
(151,'BYE','gK040c0fc7','b2850e68-1dc2-42df-b64a-961410be08ce','438587087_132045321@74.120.93.30','200','OK','2025-10-24 03:20:23','34.226.36.33','proj_MrxkZ5BlbAFrpJXiyZBrs6mq','OAI','sip.api.openai.com','+19475176566','fl.gg',40,'','','14'),
(152,'INVITE','gK00419423','aec90603-fd85-4517-ad7b-b1cc7f609d51','438357385_133953516@74.120.93.30','200','OK','2025-10-24 04:19:37','34.226.36.35','proj_MrxkZ5BlbAFrpJXiyZBrs6mq','proj_MrxkZ5BlbAFrpJXiyZBrs6mq','sip.api.openai.com','+19475176566','fl.gg',41,'inbound','','14'),
(153,'BYE','gK00419423','aec90603-fd85-4517-ad7b-b1cc7f609d51','438357385_133953516@74.120.93.30','200','OK','2025-10-24 04:20:52','34.226.36.35','proj_MrxkZ5BlbAFrpJXiyZBrs6mq','OAI','sip.api.openai.com','+19475176566','fl.gg',41,'','','14'),
(154,'INVITE','gK087514f6','7eba831b-ca32-4d6d-84c2-7dcf5becb300','256420411_16749185@74.120.93.200','200','OK','2025-10-24 04:42:54','34.226.36.33','proj_MrxkZ5BlbAFrpJXiyZBrs6mq','proj_MrxkZ5BlbAFrpJXiyZBrs6mq','sip.api.openai.com','+19475176566','fl.gg',42,'inbound','','14'),
(155,'BYE','gK087514f6','7eba831b-ca32-4d6d-84c2-7dcf5becb300','256420411_16749185@74.120.93.200','200','OK','2025-10-24 04:45:26','34.226.36.33','proj_MrxkZ5BlbAFrpJXiyZBrs6mq','OAI','sip.api.openai.com','+19475176566','fl.gg',42,'','','14'),
(156,'INVITE','gK045630cd','3e693041-ebb2-4b8d-84b6-f7af3744c6a4','509878254_133211243@74.120.93.30','200','OK','2025-10-24 20:51:03','34.226.36.33','proj_MrxkZ5BlbAFrpJXiyZBrs6mq','proj_MrxkZ5BlbAFrpJXiyZBrs6mq','sip.api.openai.com','+19475176566','fl.gg',43,'inbound','','14'),
(157,'BYE','gK045630cd','3e693041-ebb2-4b8d-84b6-f7af3744c6a4','509878254_133211243@74.120.93.30','200','OK','2025-10-24 20:51:11','34.226.36.33','proj_MrxkZ5BlbAFrpJXiyZBrs6mq','OAI','sip.api.openai.com','+19475176566','fl.gg',43,'','','14'),
(158,'INVITE','gK006770e9','9cbadbd2-05b6-4b90-9620-1b3d1e7a9e25','524295333_133912318@74.120.93.200','200','OK','2025-10-24 20:51:24','34.226.36.35','proj_MrxkZ5BlbAFrpJXiyZBrs6mq','proj_MrxkZ5BlbAFrpJXiyZBrs6mq','sip.api.openai.com','+19475176566','fl.gg',44,'inbound','','14'),
(159,'BYE','gK006770e9','9cbadbd2-05b6-4b90-9620-1b3d1e7a9e25','524295333_133912318@74.120.93.200','200','OK','2025-10-24 20:51:38','34.226.36.35','proj_MrxkZ5BlbAFrpJXiyZBrs6mq','OAI','sip.api.openai.com','+19475176566','fl.gg',44,'','','14'),
(160,'INVITE','gK083999b1','b06475cf-1a24-4b54-afe2-49aeaa6b0617','503842597_134080436@74.120.93.30','200','OK','2025-10-24 21:20:37','34.226.36.34','proj_MrxkZ5BlbAFrpJXiyZBrs6mq','proj_MrxkZ5BlbAFrpJXiyZBrs6mq','sip.api.openai.com','+19475176566','fl.gg',45,'inbound','','14'),
(161,'BYE','gK083999b1','b06475cf-1a24-4b54-afe2-49aeaa6b0617','503842597_134080436@74.120.93.30','200','OK','2025-10-24 21:20:45','34.226.36.34','proj_MrxkZ5BlbAFrpJXiyZBrs6mq','OAI','sip.api.openai.com','+19475176566','fl.gg',45,'','','14'),
(162,'INVITE','gK0474a877','0570103f-175d-4469-8154-ac8c77e4f591','507820268_121572229@206.147.88.72','200','OK','2025-10-24 21:20:49','34.226.36.33','proj_MrxkZ5BlbAFrpJXiyZBrs6mq','proj_MrxkZ5BlbAFrpJXiyZBrs6mq','sip.api.openai.com','+19475176566','fl.gg',46,'inbound','','14'),
(163,'BYE','gK0474a877','0570103f-175d-4469-8154-ac8c77e4f591','507820268_121572229@206.147.88.72','200','OK','2025-10-24 21:22:30','34.226.36.33','proj_MrxkZ5BlbAFrpJXiyZBrs6mq','OAI','sip.api.openai.com','+19475176566','fl.gg',46,'','','14'),
(164,'INVITE','gK04463251','096cb1be-9f71-4beb-9bc5-ab160dfca408','295641_133329785@74.120.93.30','200','OK','2025-10-27 10:41:59','34.226.36.33','proj_MrxkZ5BlbAFrpJXiyZBrs6mq','proj_MrxkZ5BlbAFrpJXiyZBrs6mq','sip.api.openai.com','+19475176566','fl.gg',47,'inbound','','14'),
(165,'BYE','gK04463251','096cb1be-9f71-4beb-9bc5-ab160dfca408','295641_133329785@74.120.93.30','200','OK','2025-10-27 10:42:20','34.226.36.33','proj_MrxkZ5BlbAFrpJXiyZBrs6mq','OAI','sip.api.openai.com','+19475176566','fl.gg',47,'','','14'),
(166,'INVITE','39bb100c','bf8638324618dc61059d4c604476fea1.f648d587','eYr6AC402jfx7JwR5wrSpw..','403','Tech Prefix and IP not in ACL - support@flowroute.com','2025-10-27 20:58:40','50.192.97.226','16723617*19475176566','16723617*19475176566','34.226.36.32','3137891313','34.210.91.112',0,'outbound','13','3'),
(167,'INVITE','gK007143a2','253662be-5ee2-4476-9f53-9ed3576f527e','39864624_125792962@74.120.93.30','200','OK','2025-10-27 20:59:52','34.226.36.33','proj_MrxkZ5BlbAFrpJXiyZBrs6mq','proj_MrxkZ5BlbAFrpJXiyZBrs6mq','sip.api.openai.com','+19475176566','fl.gg',48,'inbound','','14'),
(168,'BYE','gK007143a2','253662be-5ee2-4476-9f53-9ed3576f527e','39864624_125792962@74.120.93.30','200','OK','2025-10-27 20:59:56','34.226.36.33','proj_MrxkZ5BlbAFrpJXiyZBrs6mq','OAI','sip.api.openai.com','+19475176566','fl.gg',48,'','','14'),
(169,'INVITE','19cd9b51','gK08ffbd62','bTsOkw-B-JooRs4tWio6xA..','200','OK','2025-10-27 21:03:14','50.192.97.226','16723617*19475176566','16723617*19475176566','34.210.91.112','3137891313','34.210.91.112',49,'outbound','13','3'),
(170,'BYE','19cd9b51','gK08ffbd62','bTsOkw-B-JooRs4tWio6xA..','200','OK','2025-10-27 21:03:25','50.192.97.226','19475176566','+19475176566','208.69.83.20','3137891313','34.210.91.112',49,'','13','3'),
(171,'INVITE','64aabd74','bf8638324618dc61059d4c604476fea1.8d9c33a3','uvjdaSc7ViOjE4c-la8vHQ..','403','International Calling Disabled - support@flowroute.com','2025-10-27 22:17:31','50.192.97.226','16723617*9475176566','16723617*9475176566','34.226.36.32','3137891313','34.210.91.112',0,'outbound','13','3'),
(172,'INVITE','2759780b','gK04e633c1','SaKuRgvQ2neucUy8u2053g..','200','OK','2025-10-27 22:17:45','50.192.97.226','16723617*19475176566','16723617*19475176566','34.210.91.112','3137891313','34.210.91.112',50,'outbound','13','3'),
(173,'BYE','gK04e633c1','2759780b','SaKuRgvQ2neucUy8u2053g..','200','OK','2025-10-27 22:18:00','34.210.91.112','3137891313','3137891313','146.190.253.188','19475176566','34.210.91.112',0,'','13','3'),
(174,'INVITE','c42e607b','gK04aa805a','Rg79zJQdr1qmQCcPVX7vOQ..','200','OK','2025-10-27 22:21:39','50.192.97.226','16723617*19475176566','16723617*19475176566','34.210.91.112','3137891313','34.210.91.112',51,'outbound','13','3'),
(175,'BYE','c42e607b','gK04aa805a','Rg79zJQdr1qmQCcPVX7vOQ..','200','OK','2025-10-27 22:23:07','50.192.97.226','19475176566','+19475176566','208.69.83.20','3137891313','34.210.91.112',51,'','13','3'),
(176,'INVITE','ee4d0234','gK0c91fc24','mgtIA_pD29Mr2oKFzr6WSQ..','200','OK','2025-10-27 22:23:42','50.192.97.226','16723617*19475176566','16723617*19475176566','34.210.91.112','3137891313','34.210.91.112',52,'outbound','13','3'),
(177,'BYE','gK0c91fc24','ee4d0234','mgtIA_pD29Mr2oKFzr6WSQ..','200','OK','2025-10-27 22:23:49','34.210.91.112','3137891313','3137891313','146.190.253.188','19475176566','34.210.91.112',0,'','13','3'),
(178,'INVITE','e5eac314','gK04e20e89','s6_dKv0LY6HKj5DQxegRnA..','200','OK','2025-10-27 22:25:32','50.192.97.226','16723617*19475176566','16723617*19475176566','34.210.91.112','3137891313','34.210.91.112',53,'outbound','13','3'),
(179,'BYE','gK04e20e89','e5eac314','s6_dKv0LY6HKj5DQxegRnA..','200','OK','2025-10-27 22:25:34','34.210.91.112','3137891313','3137891313','146.190.253.188','19475176566','34.210.91.112',0,'','13','3'),
(180,'INVITE','0489c025','gK0cf7e856','-vPMVYz2yaOjZNOrrnLL5g..','200','OK','2025-10-28 03:05:18','50.192.97.226','16723617*19475176566','16723617*19475176566','34.210.91.112','3137891313','34.210.91.112',54,'outbound','13','3'),
(181,'BYE','0489c025','gK0cf7e856','-vPMVYz2yaOjZNOrrnLL5g..','200','OK','2025-10-28 03:06:01','50.192.97.226','19475176566','+19475176566','208.69.83.20','3137891313','34.210.91.112',54,'','13','3'),
(182,'INVITE','fec04d65','gK049dc82e','JxQtQ4TdtvgTl9a5ckUAhQ..','200','OK','2025-10-28 03:07:45','50.192.97.226','16723617*19475176566','16723617*19475176566','34.210.91.112','3137891313','34.210.91.112',55,'outbound','13','3'),
(183,'BYE','fec04d65','gK049dc82e','JxQtQ4TdtvgTl9a5ckUAhQ..','200','OK','2025-10-28 03:07:51','50.192.97.226','19475176566','+19475176566','208.69.82.20','3137891313','34.210.91.112',55,'','13','3'),
(184,'INVITE','ec593724','gK0cb80944','SeJsM9umYiYBpwMrP75YYQ..','200','OK','2025-10-28 03:08:13','50.192.97.226','16723617*19475176566','16723617*19475176566','34.210.91.112','3137891313','34.210.91.112',56,'outbound','13','3'),
(185,'BYE','ec593724','gK0cb80944','SeJsM9umYiYBpwMrP75YYQ..','200','OK','2025-10-28 03:08:43','50.192.97.226','19475176566','+19475176566','208.69.82.20','3137891313','34.210.91.112',56,'','13','3'),
(186,'INVITE','fb825b6e','gK08ef5a1d','xaCz-lMXL5eCgvAhunmuhw..','200','OK','2025-10-28 03:10:20','50.192.97.226','16723617*19475176566','16723617*19475176566','34.210.91.112','3137891313','34.210.91.112',57,'outbound','13','3'),
(187,'BYE','fb825b6e','gK08ef5a1d','xaCz-lMXL5eCgvAhunmuhw..','200','OK','2025-10-28 03:12:25','50.192.97.226','19475176566','+19475176566','208.69.81.117','3137891313','34.210.91.112',57,'','13','3'),
(188,'INVITE','b76fa61c','gK0c863b20','hBTOVGKIUTZMLnV6AHlAjg..','200','OK','2025-10-28 03:28:17','50.192.97.226','16723617*19475176566','16723617*19475176566','34.210.91.112','3137891313','34.210.91.112',58,'outbound','13','3'),
(189,'BYE','gK0c863b20','b76fa61c','hBTOVGKIUTZMLnV6AHlAjg..','200','OK','2025-10-28 03:28:40','34.210.91.112','3137891313','3137891313','146.190.253.188','19475176566','34.210.91.112',0,'','13','3'),
(190,'INVITE','dd1e5d79','gK089c9017','HYskrUUBNmULhsjyAiEQaQ..','200','OK','2025-10-28 04:06:15','50.192.97.226','16723617*19475176566','16723617*19475176566','34.210.91.112','3137891313','34.210.91.112',59,'outbound','13','3'),
(191,'BYE','gK089c9017','dd1e5d79','HYskrUUBNmULhsjyAiEQaQ..','200','OK','2025-10-28 04:06:23','34.210.91.112','3137891313','3137891313','146.190.253.188','19475176566','34.210.91.112',0,'','13','3'),
(192,'INVITE','67ae4719','gK009d4f67','u3iHWYs-L6GSAk0sv5rlCw..','200','OK','2025-10-28 04:32:23','50.192.97.226','16723617*19475176566','16723617*19475176566','34.210.91.112','3137891313','34.210.91.112',60,'outbound','13','3'),
(193,'BYE','gK009d4f67','67ae4719','u3iHWYs-L6GSAk0sv5rlCw..','200','OK','2025-10-28 04:32:47','34.210.91.112','3137891313','3137891313','146.190.253.188','19475176566','34.210.91.112',0,'','13','3'),
(194,'INVITE','d79b495f','gK00bd8ff6','zR_6NyGpMNKkS2iu26VbMw..','200','OK','2025-10-28 04:36:14','50.192.97.226','16723617*19475176566','16723617*19475176566','34.210.91.112','3137891313','34.210.91.112',61,'outbound','13','3'),
(195,'BYE','gK00bd8ff6','d79b495f','zR_6NyGpMNKkS2iu26VbMw..','200','OK','2025-10-28 04:36:38','34.210.91.112','3137891313','3137891313','146.190.253.188','19475176566','34.210.91.112',0,'','13','3'),
(196,'BYE','d79b495f','gK00bd8ff6','zR_6NyGpMNKkS2iu26VbMw..','481','Call/Transaction Does Not Exist','2025-10-28 04:36:38','50.192.97.226','19475176566','19475176566','146.190.253.188','3137891313','34.210.91.112',61,'','13','3'),
(197,'INVITE','26ca596f','gK0c92c5e3','LX5iNIp6bqAp_OCf7hQRaw..','200','OK','2025-10-28 04:39:09','50.192.97.226','16723617*19475176566','16723617*19475176566','34.210.91.112','3137891313','34.210.91.112',62,'outbound','13','3'),
(198,'BYE','26ca596f','gK0c92c5e3','LX5iNIp6bqAp_OCf7hQRaw..','481','Call/Transaction Does Not Exist','2025-10-28 04:39:16','50.192.97.226','19475176566','19475176566','146.190.253.188','3137891313','34.210.91.112',62,'','13','3'),
(199,'BYE','gK0c92c5e3','26ca596f','LX5iNIp6bqAp_OCf7hQRaw..','481','Call/Transaction Does Not Exist','2025-10-28 04:39:33','34.210.91.112','+13137891313','3137891313','146.190.253.188','+19475176566','fl.gg',0,'','',''),
(200,'INVITE','e3b96679','gK08e1235d','hGC9An3FC6I0TedOQPhf_w..','200','OK','2025-10-28 04:41:26','50.192.97.226','16723617*19475176566','16723617*19475176566','34.210.91.112','3137891313','34.210.91.112',63,'outbound','13','3'),
(201,'BYE','gK08e1235d','e3b96679','hGC9An3FC6I0TedOQPhf_w..','200','OK','2025-10-28 04:41:50','34.210.91.112','3137891313','3137891313','146.190.253.188','19475176566','34.210.91.112',0,'','13','3'),
(202,'INVITE','9dac6815','gK0c94ccb8','JonuNbZQ_R0DA0_oQA6mcg..','200','OK','2025-10-28 04:44:17','50.192.97.226','16723617*19475176566','16723617*19475176566','34.210.91.112','3137891313','34.210.91.112',64,'outbound','13','3'),
(203,'BYE','gK0c94ccb8','9dac6815','JonuNbZQ_R0DA0_oQA6mcg..','200','OK','2025-10-28 04:44:41','34.210.91.112','3137891313','3137891313','146.190.253.188','19475176566','34.210.91.112',0,'','13','3'),
(204,'INVITE','68369615','gK0c82c42a','DTWzP1cS5aGuwEdaIHUGHA..','200','OK','2025-10-28 04:47:59','50.192.97.226','16723617*19475176566','16723617*19475176566','34.210.91.112','3137891313','34.210.91.112',65,'outbound','13','3'),
(205,'BYE','gK0c82c42a','68369615','DTWzP1cS5aGuwEdaIHUGHA..','200','OK','2025-10-28 04:48:48','34.210.91.112','3137891313','3137891313','146.190.253.188','19475176566','34.210.91.112',0,'','13','3'),
(206,'INVITE','gK0429ac91','07669f53-f728-455e-948b-107b738e4588','50618368_121240042@74.120.93.30','200','OK','2025-10-28 13:03:51','34.226.36.33','proj_MrxkZ5BlbAFrpJXiyZBrs6mq','proj_MrxkZ5BlbAFrpJXiyZBrs6mq','sip.api.openai.com','+19475176566','fl.gg',66,'inbound','','14'),
(207,'BYE','gK0429ac91','07669f53-f728-455e-948b-107b738e4588','50618368_121240042@74.120.93.30','200','OK','2025-10-28 13:04:45','34.226.36.33','proj_MrxkZ5BlbAFrpJXiyZBrs6mq','OAI','sip.api.openai.com','+19475176566','fl.gg',66,'','','14'),
(208,'INVITE','gK08130131','f603f310-b88e-472e-b876-8a06e1b27361','386451262_55121521@74.120.93.200','200','OK','2025-10-28 13:04:52','34.226.36.34','proj_MrxkZ5BlbAFrpJXiyZBrs6mq','proj_MrxkZ5BlbAFrpJXiyZBrs6mq','sip.api.openai.com','+19475176566','fl.gg',67,'inbound','','14'),
(209,'BYE','gK08130131','f603f310-b88e-472e-b876-8a06e1b27361','386451262_55121521@74.120.93.200','200','OK','2025-10-28 13:04:58','34.226.36.34','proj_MrxkZ5BlbAFrpJXiyZBrs6mq','OAI','sip.api.openai.com','+19475176566','fl.gg',67,'','','14'),
(210,'INVITE','gK08138319','6ec6ee8c-9a53-43a8-8194-69d23b75437e','386451382_50322849@74.120.93.200','200','OK','2025-10-28 13:05:02','34.226.36.35','proj_MrxkZ5BlbAFrpJXiyZBrs6mq','proj_MrxkZ5BlbAFrpJXiyZBrs6mq','sip.api.openai.com','+19475176566','fl.gg',68,'inbound','','14'),
(211,'BYE','gK08138319','6ec6ee8c-9a53-43a8-8194-69d23b75437e','386451382_50322849@74.120.93.200','200','OK','2025-10-28 13:05:09','34.226.36.35','proj_MrxkZ5BlbAFrpJXiyZBrs6mq','OAI','sip.api.openai.com','+19475176566','fl.gg',68,'','','14'),
(212,'INVITE','gK0c023911','2fc96f60-5c9c-447d-9369-ce553a9e4377','369935905_131067100@74.120.93.30','200','OK','2025-10-31 19:32:37','34.226.36.33','proj_MrxkZ5BlbAFrpJXiyZBrs6mq','proj_MrxkZ5BlbAFrpJXiyZBrs6mq','sip.api.openai.com','+19475176566','fl.gg',69,'inbound','','14'),
(213,'BYE','gK0c023911','2fc96f60-5c9c-447d-9369-ce553a9e4377','369935905_131067100@74.120.93.30','200','OK','2025-10-31 19:34:11','34.226.36.33','proj_MrxkZ5BlbAFrpJXiyZBrs6mq','OAI','sip.api.openai.com','+19475176566','fl.gg',69,'','','14'),
(214,'INVITE','gK0058d197','57db912d-4791-4c61-81c3-e79d47b0a5c0','6299522_58080382@74.120.93.200','200','OK','2025-10-31 21:12:39','34.226.36.35','proj_MrxkZ5BlbAFrpJXiyZBrs6mq','proj_MrxkZ5BlbAFrpJXiyZBrs6mq','sip.api.openai.com','+19475176566','fl.gg',70,'inbound','','14'),
(215,'BYE','gK0058d197','57db912d-4791-4c61-81c3-e79d47b0a5c0','6299522_58080382@74.120.93.200','200','OK','2025-10-31 21:12:49','34.226.36.35','proj_MrxkZ5BlbAFrpJXiyZBrs6mq','OAI','sip.api.openai.com','+19475176566','fl.gg',70,'','','14'),
(216,'INVITE','gK0c325922','0071eb7a-687e-4b12-8939-59f4706416dc','403442354_128660845@74.120.93.30','200','OK','2025-10-31 21:12:54','34.226.36.32','proj_MrxkZ5BlbAFrpJXiyZBrs6mq','proj_MrxkZ5BlbAFrpJXiyZBrs6mq','sip.api.openai.com','+19475176566','fl.gg',71,'inbound','3','14'),
(217,'BYE','gK0c325922','0071eb7a-687e-4b12-8939-59f4706416dc','403442354_128660845@74.120.93.30','200','OK','2025-10-31 21:15:01','34.226.36.32','proj_MrxkZ5BlbAFrpJXiyZBrs6mq','OAI','sip.api.openai.com','+19475176566','fl.gg',71,'','3','14'),
(218,'INVITE','gK047e3756','4d12dc4f-5921-4774-b71f-70027716b535','409214770_92069723@74.120.93.30','200','OK','2025-11-01 00:49:45','34.226.36.33','proj_MrxkZ5BlbAFrpJXiyZBrs6mq','proj_MrxkZ5BlbAFrpJXiyZBrs6mq','sip.api.openai.com','+19475176566','fl.gg',72,'inbound','','14'),
(219,'BYE','gK047e3756','4d12dc4f-5921-4774-b71f-70027716b535','409214770_92069723@74.120.93.30','200','OK','2025-11-01 00:51:08','34.226.36.33','proj_MrxkZ5BlbAFrpJXiyZBrs6mq','OAI','sip.api.openai.com','+19475176566','fl.gg',72,'','','14'),
(220,'INVITE','gK084d5783','73fce51d-8064-41f0-956d-9ce058d001d0','17319824_129664308@74.120.93.200','200','OK','2025-11-01 01:17:24','34.226.36.33','proj_MrxkZ5BlbAFrpJXiyZBrs6mq','proj_MrxkZ5BlbAFrpJXiyZBrs6mq','sip.api.openai.com','+19475176566','fl.gg',73,'inbound','','14'),
(221,'BYE','gK084d5783','73fce51d-8064-41f0-956d-9ce058d001d0','17319824_129664308@74.120.93.200','200','OK','2025-11-01 01:19:35','34.226.36.33','proj_MrxkZ5BlbAFrpJXiyZBrs6mq','OAI','sip.api.openai.com','+19475176566','fl.gg',73,'','','14'),
(222,'INVITE','gK044190f6','59e34f0d-cf8b-4e21-a03c-3e2e7ce7e30a','17088871_99066122@74.120.93.200','200','OK','2025-11-01 01:31:24','34.226.36.34','proj_MrxkZ5BlbAFrpJXiyZBrs6mq','proj_MrxkZ5BlbAFrpJXiyZBrs6mq','sip.api.openai.com','+19475176566','fl.gg',74,'inbound','','14'),
(223,'BYE','gK044190f6','59e34f0d-cf8b-4e21-a03c-3e2e7ce7e30a','17088871_99066122@74.120.93.200','200','OK','2025-11-01 01:31:33','34.226.36.34','proj_MrxkZ5BlbAFrpJXiyZBrs6mq','OAI','sip.api.openai.com','+19475176566','fl.gg',74,'','','14'),
(224,'INVITE','gK0441c31d','451f351b-cec6-4835-a28b-e67053f87c75','17088900_62890530@74.120.93.200','200','OK','2025-11-01 01:31:39','34.226.36.35','proj_MrxkZ5BlbAFrpJXiyZBrs6mq','proj_MrxkZ5BlbAFrpJXiyZBrs6mq','sip.api.openai.com','+19475176566','fl.gg',75,'inbound','','14'),
(225,'BYE','gK0441c31d','451f351b-cec6-4835-a28b-e67053f87c75','17088900_62890530@74.120.93.200','200','OK','2025-11-01 01:33:01','34.226.36.35','proj_MrxkZ5BlbAFrpJXiyZBrs6mq','OAI','sip.api.openai.com','+19475176566','fl.gg',75,'','','14'),
(226,'INVITE','gK044d6cf2','8d8d27d3-cc14-48fe-bde3-2d2db0c13eb4','392472330_115211307@206.147.88.72','200','OK','2025-11-01 01:46:18','34.226.36.34','proj_MrxkZ5BlbAFrpJXiyZBrs6mq','proj_MrxkZ5BlbAFrpJXiyZBrs6mq','sip.api.openai.com','+19475176566','fl.gg',76,'inbound','','14'),
(227,'BYE','gK044d6cf2','8d8d27d3-cc14-48fe-bde3-2d2db0c13eb4','392472330_115211307@206.147.88.72','200','OK','2025-11-01 01:54:15','34.226.36.34','proj_MrxkZ5BlbAFrpJXiyZBrs6mq','OAI','sip.api.openai.com','+19475176566','fl.gg',76,'','','14'),
(228,'INVITE','gK0455ec9d','e7cd2c27-e566-45ba-81ab-9cd21e10a2f6','392474172_121485297@206.147.88.72','200','OK','2025-11-01 01:54:39','34.226.36.35','proj_MrxkZ5BlbAFrpJXiyZBrs6mq','proj_MrxkZ5BlbAFrpJXiyZBrs6mq','sip.api.openai.com','+19475176566','fl.gg',77,'inbound','','14'),
(229,'BYE','gK0455ec9d','e7cd2c27-e566-45ba-81ab-9cd21e10a2f6','392474172_121485297@206.147.88.72','200','OK','2025-11-01 02:01:16','34.226.36.35','proj_MrxkZ5BlbAFrpJXiyZBrs6mq','OAI','sip.api.openai.com','+19475176566','fl.gg',77,'','','14'),
(230,'INVITE','gK0c7707bd','f9cf1807-9402-4990-8cbe-e4fb2948d25c','409747432_121618616@74.120.93.30','200','OK','2025-11-01 02:03:13','34.226.36.33','proj_MrxkZ5BlbAFrpJXiyZBrs6mq','proj_MrxkZ5BlbAFrpJXiyZBrs6mq','sip.api.openai.com','+19475176566','fl.gg',78,'inbound','','14'),
(231,'BYE','gK0c7707bd','f9cf1807-9402-4990-8cbe-e4fb2948d25c','409747432_121618616@74.120.93.30','200','OK','2025-11-01 02:05:19','34.226.36.33','proj_MrxkZ5BlbAFrpJXiyZBrs6mq','OAI','sip.api.openai.com','+19475176566','fl.gg',78,'','','14'),
(232,'INVITE','gK0073c4f4','e107cc3d-66b4-4d5e-955f-3e0593c4b1d8','408991844_133536002@74.120.93.30','200','OK','2025-11-01 02:06:13','34.226.36.35','proj_MrxkZ5BlbAFrpJXiyZBrs6mq','proj_MrxkZ5BlbAFrpJXiyZBrs6mq','sip.api.openai.com','+19475176566','fl.gg',79,'inbound','','14'),
(233,'BYE','gK0073c4f4','e107cc3d-66b4-4d5e-955f-3e0593c4b1d8','408991844_133536002@74.120.93.30','200','OK','2025-11-01 02:06:39','34.226.36.35','proj_MrxkZ5BlbAFrpJXiyZBrs6mq','OAI','sip.api.openai.com','+19475176566','fl.gg',79,'','','14'),
(234,'INVITE','gK085b8f7b','744a6d06-c926-41f3-befd-7fd9a0cc6ca8','409486557_9230871@74.120.93.30','200','OK','2025-11-01 02:09:22','34.226.36.35','proj_MrxkZ5BlbAFrpJXiyZBrs6mq','proj_MrxkZ5BlbAFrpJXiyZBrs6mq','sip.api.openai.com','+19475176566','fl.gg',80,'inbound','','14'),
(235,'BYE','gK085b8f7b','744a6d06-c926-41f3-befd-7fd9a0cc6ca8','409486557_9230871@74.120.93.30','200','OK','2025-11-01 02:13:18','34.226.36.35','proj_MrxkZ5BlbAFrpJXiyZBrs6mq','OAI','sip.api.openai.com','+19475176566','fl.gg',80,'','','14'),
(236,'INVITE','gK007a0a2e','0e37ffaa-80ee-44c4-88d0-9e79d2eba196','408993008_132636985@74.120.93.30','200','OK','2025-11-01 02:15:36','34.226.36.32','proj_MrxkZ5BlbAFrpJXiyZBrs6mq','proj_MrxkZ5BlbAFrpJXiyZBrs6mq','sip.api.openai.com','+19475176566','fl.gg',81,'inbound','3','14'),
(237,'BYE','gK007a0a2e','0e37ffaa-80ee-44c4-88d0-9e79d2eba196','408993008_132636985@74.120.93.30','200','OK','2025-11-01 02:18:16','34.226.36.32','proj_MrxkZ5BlbAFrpJXiyZBrs6mq','OAI','sip.api.openai.com','+19475176566','fl.gg',81,'','3','14'),
(238,'INVITE','gK007cf821','46b9bbdb-282b-44c0-af3b-e5a1531315fb','408993532_133929701@74.120.93.30','200','OK','2025-11-01 02:20:19','34.226.36.35','proj_MrxkZ5BlbAFrpJXiyZBrs6mq','proj_MrxkZ5BlbAFrpJXiyZBrs6mq','sip.api.openai.com','+19475176566','fl.gg',82,'inbound','','14'),
(239,'BYE','gK007cf821','46b9bbdb-282b-44c0-af3b-e5a1531315fb','408993532_133929701@74.120.93.30','200','OK','2025-11-01 02:20:29','34.226.36.35','proj_MrxkZ5BlbAFrpJXiyZBrs6mq','OAI','sip.api.openai.com','+19475176566','fl.gg',82,'','','14'),
(240,'INVITE','gK0c3155cf','261cdb71-393c-4a3d-853e-bd18aca40ba0','17590367_74395316@74.120.93.200','200','OK','2025-11-01 02:27:31','34.226.36.33','proj_MrxkZ5BlbAFrpJXiyZBrs6mq','proj_MrxkZ5BlbAFrpJXiyZBrs6mq','sip.api.openai.com','+18889072085','fl.gg',83,'inbound','','14'),
(241,'BYE','gK0c3155cf','261cdb71-393c-4a3d-853e-bd18aca40ba0','17590367_74395316@74.120.93.200','200','OK','2025-11-01 02:28:09','34.226.36.33','proj_MrxkZ5BlbAFrpJXiyZBrs6mq','OAI','sip.api.openai.com','+18889072085','fl.gg',83,'','','14'),
(242,'INVITE','2cc41976','bf8638324618dc61059d4c604476fea1.2df70000','j6vsP5oEKcPryOuTPyqqGQ..','488','Not acceptable here','2025-11-01 02:29:04','50.192.97.226','16723617*+13134903595','16723617*+13134903595','34.226.36.32','proj_MrxkZ5BlbAFrpJXiyZBrs6mq','34.210.91.112',0,'outbound','13','3'),
(243,'INVITE','fc1b063b','bf8638324618dc61059d4c604476fea1.2df70000','ylVnjpdTxKxlrIFnBVLftA..','488','Not acceptable here','2025-11-01 02:31:31','50.192.97.226','16723617*+13134903595','16723617*+13134903595','34.226.36.32','proj_MrxkZ5BlbAFrpJXiyZBrs6mq','34.210.91.112',0,'outbound','13','3'),
(244,'INVITE','gK046db84e','fb74b4c0-6c4b-4c34-9fb2-4574beb77c7e','17095727_134019348@74.120.93.200','200','OK','2025-11-01 02:31:57','34.226.36.33','proj_MrxkZ5BlbAFrpJXiyZBrs6mq','proj_MrxkZ5BlbAFrpJXiyZBrs6mq','sip.api.openai.com','+18889072085','fl.gg',84,'inbound','','14'),
(245,'BYE','gK046db84e','fb74b4c0-6c4b-4c34-9fb2-4574beb77c7e','17095727_134019348@74.120.93.200','200','OK','2025-11-01 02:34:57','34.226.36.33','proj_MrxkZ5BlbAFrpJXiyZBrs6mq','OAI','sip.api.openai.com','+18889072085','fl.gg',84,'','','14'),
(246,'INVITE','gK04013eb9','230a8c44-e779-45e2-a102-b598d3743ba5','392483373_129712081@206.147.88.72','200','OK','2025-11-01 02:42:12','34.226.36.35','proj_MrxkZ5BlbAFrpJXiyZBrs6mq','proj_MrxkZ5BlbAFrpJXiyZBrs6mq','sip.api.openai.com','+18889072085','fl.gg',85,'inbound','','14'),
(247,'BYE','gK04013eb9','230a8c44-e779-45e2-a102-b598d3743ba5','392483373_129712081@206.147.88.72','200','OK','2025-11-01 02:42:26','34.226.36.35','proj_MrxkZ5BlbAFrpJXiyZBrs6mq','OAI','sip.api.openai.com','+18889072085','fl.gg',85,'','','14'),
(248,'INVITE','gK086e0fc6','afccdf6f-e786-4068-9832-3c2bb48b1a18','409490769_92252316@74.120.93.30','200','OK','2025-11-01 02:48:49','34.226.36.33','proj_MrxkZ5BlbAFrpJXiyZBrs6mq','proj_MrxkZ5BlbAFrpJXiyZBrs6mq','sip.api.openai.com','+19475176566','fl.gg',86,'inbound','','14'),
(249,'BYE','gK086e0fc6','afccdf6f-e786-4068-9832-3c2bb48b1a18','409490769_92252316@74.120.93.30','200','OK','2025-11-01 02:49:59','34.226.36.33','proj_MrxkZ5BlbAFrpJXiyZBrs6mq','OAI','sip.api.openai.com','+19475176566','fl.gg',86,'','','14'),
(250,'INVITE','gK0053213e','ae11bc86-2866-4f25-bf39-642e5a432e19','406895930_129488724@206.147.88.72','200','OK','2025-11-01 12:11:15','34.226.36.35','proj_MrxkZ5BlbAFrpJXiyZBrs6mq','proj_MrxkZ5BlbAFrpJXiyZBrs6mq','sip.api.openai.com','+19475176566','fl.gg',87,'inbound','','14'),
(251,'BYE','gK0053213e','ae11bc86-2866-4f25-bf39-642e5a432e19','406895930_129488724@206.147.88.72','200','OK','2025-11-01 12:12:25','34.226.36.35','proj_MrxkZ5BlbAFrpJXiyZBrs6mq','OAI','sip.api.openai.com','+19475176566','fl.gg',87,'','','14'),
(252,'INVITE','gK0c4ca311','f1f67a32-ddc8-4614-9428-53a4d2dbd605','403483753_117165598@74.120.93.30','200','OK','2025-11-01 14:40:19','34.226.36.32','proj_MrxkZ5BlbAFrpJXiyZBrs6mq','proj_MrxkZ5BlbAFrpJXiyZBrs6mq','sip.api.openai.com','+19475176566','fl.gg',88,'inbound','3','14'),
(253,'BYE','gK0c4ca311','f1f67a32-ddc8-4614-9428-53a4d2dbd605','403483753_117165598@74.120.93.30','200','OK','2025-11-01 14:41:17','34.226.36.32','proj_MrxkZ5BlbAFrpJXiyZBrs6mq','OAI','sip.api.openai.com','+19475176566','fl.gg',88,'','3','14'),
(254,'INVITE','gK006c22bc','494cc884-23f8-4df6-b784-a5512ce43751','21012164_123690908@74.120.93.200','200','OK','2025-11-01 14:44:48','34.226.36.32','proj_MrxkZ5BlbAFrpJXiyZBrs6mq','proj_MrxkZ5BlbAFrpJXiyZBrs6mq','sip.api.openai.com','+19475176566','fl.gg',89,'inbound','3','14'),
(255,'BYE','gK006c22bc','494cc884-23f8-4df6-b784-a5512ce43751','21012164_123690908@74.120.93.200','200','OK','2025-11-01 14:45:34','34.226.36.32','proj_MrxkZ5BlbAFrpJXiyZBrs6mq','OAI','sip.api.openai.com','+19475176566','fl.gg',89,'','3','14'),
(256,'INVITE','gK084f95b4','522f6d98-e6a5-4be5-9c16-2cf935819c97','19444298_126769545@74.120.93.200','200','OK','2025-11-01 14:53:05','34.226.36.35','proj_MrxkZ5BlbAFrpJXiyZBrs6mq','proj_MrxkZ5BlbAFrpJXiyZBrs6mq','sip.api.openai.com','+19475176566','fl.gg',90,'inbound','','14'),
(257,'BYE','gK084f95b4','522f6d98-e6a5-4be5-9c16-2cf935819c97','19444298_126769545@74.120.93.200','200','OK','2025-11-01 14:56:19','34.226.36.35','proj_MrxkZ5BlbAFrpJXiyZBrs6mq','OAI','sip.api.openai.com','+19475176566','fl.gg',90,'','','14'),
(258,'INVITE','gK0c122ee8','2a7b61c2-0dfa-452d-b429-cbbe096c3fd3','407650126_131988222@206.147.88.72','200','OK','2025-11-01 15:00:26','34.226.36.35','proj_MrxkZ5BlbAFrpJXiyZBrs6mq','proj_MrxkZ5BlbAFrpJXiyZBrs6mq','sip.api.openai.com','+19475176566','fl.gg',91,'inbound','','14'),
(259,'BYE','gK0c122ee8','2a7b61c2-0dfa-452d-b429-cbbe096c3fd3','407650126_131988222@206.147.88.72','200','OK','2025-11-01 15:02:27','34.226.36.35','proj_MrxkZ5BlbAFrpJXiyZBrs6mq','OAI','sip.api.openai.com','+19475176566','fl.gg',91,'','','14'),
(260,'INVITE','gK0c1addac','d39eb38c-05f7-4040-b640-907c2cdbacc0','422354841_134209026@74.120.93.30','200','OK','2025-11-01 16:10:20','34.226.36.34','proj_MrxkZ5BlbAFrpJXiyZBrs6mq','proj_MrxkZ5BlbAFrpJXiyZBrs6mq','sip.api.openai.com','+19475176566','fl.gg',92,'inbound','','14'),
(261,'BYE','gK0c1addac','d39eb38c-05f7-4040-b640-907c2cdbacc0','422354841_134209026@74.120.93.30','200','OK','2025-11-01 16:11:13','34.226.36.34','proj_MrxkZ5BlbAFrpJXiyZBrs6mq','OAI','sip.api.openai.com','+19475176566','fl.gg',92,'','','14'),
(262,'INVITE','gK00290ee1','17346942-1420-4d6d-962f-c4efc068a368','236983219_123075107@206.147.88.72','200','OK','2025-11-05 02:53:12','34.226.36.34','proj_MrxkZ5BlbAFrpJXiyZBrs6mq','proj_MrxkZ5BlbAFrpJXiyZBrs6mq','sip.api.openai.com','+19475176566','fl.gg',93,'inbound','','14'),
(263,'BYE','gK00290ee1','17346942-1420-4d6d-962f-c4efc068a368','236983219_123075107@206.147.88.72','200','OK','2025-11-05 02:53:21','34.226.36.34','proj_MrxkZ5BlbAFrpJXiyZBrs6mq','OAI','sip.api.openai.com','+19475176566','fl.gg',93,'','','14'),
(264,'INVITE','gK0013a212','0d7ec36d-3ef1-49a0-9860-21c4971fc1e3','438348757_133764144@206.147.88.72','200','OK','2025-11-05 22:07:49','34.226.36.35','proj_MrxkZ5BlbAFrpJXiyZBrs6mq','proj_MrxkZ5BlbAFrpJXiyZBrs6mq','sip.api.openai.com','+19475176566','fl.gg',94,'inbound','','14'),
(265,'BYE','gK0013a212','0d7ec36d-3ef1-49a0-9860-21c4971fc1e3','438348757_133764144@206.147.88.72','200','OK','2025-11-05 22:08:01','34.226.36.35','proj_MrxkZ5BlbAFrpJXiyZBrs6mq','OAI','sip.api.openai.com','+19475176566','fl.gg',94,'','','14'),
(266,'INVITE','gK0477a885','a0800c87-f947-45cc-bfc2-56d6decfa1c6','218380866_133679447@74.120.93.30','200','OK','2025-11-05 22:08:10','34.226.36.32','proj_MrxkZ5BlbAFrpJXiyZBrs6mq','proj_MrxkZ5BlbAFrpJXiyZBrs6mq','sip.api.openai.com','+19475176566','fl.gg',95,'inbound','3','14'),
(267,'BYE','gK0477a885','a0800c87-f947-45cc-bfc2-56d6decfa1c6','218380866_133679447@74.120.93.30','200','OK','2025-11-05 22:09:07','34.226.36.32','proj_MrxkZ5BlbAFrpJXiyZBrs6mq','OAI','sip.api.openai.com','+19475176566','fl.gg',95,'','3','14'),
(268,'INVITE','gK00524166','79891464-5a7b-420d-8608-1c428ad455c3','220235093_133610229@74.120.93.30','200','OK','2025-11-05 22:33:22','34.226.36.34','proj_MrxkZ5BlbAFrpJXiyZBrs6mq','proj_MrxkZ5BlbAFrpJXiyZBrs6mq','sip.api.openai.com','+19475176566','fl.gg',96,'inbound','','14'),
(269,'BYE','gK00524166','79891464-5a7b-420d-8608-1c428ad455c3','220235093_133610229@74.120.93.30','200','OK','2025-11-05 22:34:56','34.226.36.34','proj_MrxkZ5BlbAFrpJXiyZBrs6mq','OAI','sip.api.openai.com','+19475176566','fl.gg',96,'','','14'),
(270,'INVITE','gK0c3dbf08','90c42907-2353-410d-bbd5-95585aa4a942','141303343_133931688@74.120.93.200','200','OK','2025-11-05 22:48:50','34.226.36.35','proj_MrxkZ5BlbAFrpJXiyZBrs6mq','proj_MrxkZ5BlbAFrpJXiyZBrs6mq','sip.api.openai.com','+19475176566','fl.gg',97,'inbound','','14'),
(271,'BYE','gK0c3dbf08','90c42907-2353-410d-bbd5-95585aa4a942','141303343_133931688@74.120.93.200','200','OK','2025-11-05 22:49:43','34.226.36.35','proj_MrxkZ5BlbAFrpJXiyZBrs6mq','OAI','sip.api.openai.com','+19475176566','fl.gg',97,'','','14'),
(272,'INVITE','gK046aa2ab','8918affd-cd17-4804-bc73-a67597c2ff63','140815143_66754003@74.120.93.200','200','OK','2025-11-05 22:58:06','34.226.36.34','proj_MrxkZ5BlbAFrpJXiyZBrs6mq','proj_MrxkZ5BlbAFrpJXiyZBrs6mq','sip.api.openai.com','+19475176566','fl.gg',98,'inbound','','14'),
(273,'BYE','gK046aa2ab','8918affd-cd17-4804-bc73-a67597c2ff63','140815143_66754003@74.120.93.200','200','OK','2025-11-05 22:58:13','34.226.36.34','proj_MrxkZ5BlbAFrpJXiyZBrs6mq','OAI','sip.api.openai.com','+19475176566','fl.gg',98,'','','14'),
(274,'INVITE','gK0c5277f5','b04a9e33-bbcc-4156-87af-264d7bb459c7','221039266_125750078@74.120.93.30','200','OK','2025-11-05 22:58:19','34.226.36.34','proj_MrxkZ5BlbAFrpJXiyZBrs6mq','proj_MrxkZ5BlbAFrpJXiyZBrs6mq','sip.api.openai.com','+19475176566','fl.gg',99,'inbound','','14'),
(275,'BYE','gK0c5277f5','b04a9e33-bbcc-4156-87af-264d7bb459c7','221039266_125750078@74.120.93.30','200','OK','2025-11-05 22:58:27','34.226.36.34','proj_MrxkZ5BlbAFrpJXiyZBrs6mq','OAI','sip.api.openai.com','+19475176566','fl.gg',99,'','','14'),
(276,'INVITE','gK007b7f5a','fbdf140c-5a4a-474f-8a08-70d73a4ffd72','222314636_133145475@74.120.93.30','200','OK','2025-11-05 22:58:32','34.226.36.32','proj_MrxkZ5BlbAFrpJXiyZBrs6mq','proj_MrxkZ5BlbAFrpJXiyZBrs6mq','sip.api.openai.com','+19475176566','fl.gg',100,'inbound','3','14'),
(277,'BYE','gK007b7f5a','fbdf140c-5a4a-474f-8a08-70d73a4ffd72','222314636_133145475@74.120.93.30','200','OK','2025-11-05 22:59:41','34.226.36.32','proj_MrxkZ5BlbAFrpJXiyZBrs6mq','OAI','sip.api.openai.com','+19475176566','fl.gg',100,'','3','14'),
(278,'INVITE','gK085f2066','4d1365f7-adae-42d5-b5fc-98570eb63a64','491295341_121606613@206.147.88.72','200','OK','2025-11-05 23:25:54','34.226.36.33','proj_MrxkZ5BlbAFrpJXiyZBrs6mq','proj_MrxkZ5BlbAFrpJXiyZBrs6mq','sip.api.openai.com','+19475176566','fl.gg',101,'inbound','','14'),
(279,'BYE','gK085f2066','4d1365f7-adae-42d5-b5fc-98570eb63a64','491295341_121606613@206.147.88.72','200','OK','2025-11-05 23:28:01','34.226.36.33','proj_MrxkZ5BlbAFrpJXiyZBrs6mq','OAI','sip.api.openai.com','+19475176566','fl.gg',101,'','','14'),
(280,'INVITE','gK0c492c24','f0f9d7a1-f814-4b25-928b-374577f0713a','241996277_130924258@74.120.93.30','200','OK','2025-11-06 00:27:54','34.226.36.34','proj_MrxkZ5BlbAFrpJXiyZBrs6mq','proj_MrxkZ5BlbAFrpJXiyZBrs6mq','sip.api.openai.com','+19475176566','fl.gg',102,'inbound','','14'),
(281,'BYE','gK0c492c24','f0f9d7a1-f814-4b25-928b-374577f0713a','241996277_130924258@74.120.93.30','200','OK','2025-11-06 00:28:54','34.226.36.34','proj_MrxkZ5BlbAFrpJXiyZBrs6mq','OAI','sip.api.openai.com','+19475176566','fl.gg',102,'','','14'),
(282,'INVITE','gK00042353','b3cfa9e0-0744-4cdb-885f-1cd405148de6','234884416_113205954@74.120.93.30','200','OK','2025-11-06 00:30:13','34.226.36.35','proj_MrxkZ5BlbAFrpJXiyZBrs6mq','proj_MrxkZ5BlbAFrpJXiyZBrs6mq','sip.api.openai.com','+19475176566','fl.gg',103,'inbound','','14'),
(283,'BYE','gK00042353','b3cfa9e0-0744-4cdb-885f-1cd405148de6','234884416_113205954@74.120.93.30','200','OK','2025-11-06 00:30:57','34.226.36.35','proj_MrxkZ5BlbAFrpJXiyZBrs6mq','OAI','sip.api.openai.com','+19475176566','fl.gg',103,'','','14'),
(284,'INVITE','gK0022c790','e01fba2d-5157-47f2-b597-40bb66480fa2','234891814_95781774@74.120.93.30','200','OK','2025-11-06 00:40:56','34.226.36.33','proj_MrxkZ5BlbAFrpJXiyZBrs6mq','proj_MrxkZ5BlbAFrpJXiyZBrs6mq','sip.api.openai.com','+19475176566','fl.gg',104,'inbound','','14'),
(285,'BYE','gK0022c790','e01fba2d-5157-47f2-b597-40bb66480fa2','234891814_95781774@74.120.93.30','200','OK','2025-11-06 00:41:45','34.226.36.33','proj_MrxkZ5BlbAFrpJXiyZBrs6mq','OAI','sip.api.openai.com','+19475176566','fl.gg',104,'','','14'),
(286,'INVITE','gK000b2ab4','cd9fe14a-a18d-4ba9-ad6e-5c3502e5689e','188745272_66568792@74.120.93.200','200','OK','2025-11-06 03:22:20','34.226.36.34','proj_MrxkZ5BlbAFrpJXiyZBrs6mq','proj_MrxkZ5BlbAFrpJXiyZBrs6mq','sip.api.openai.com','+19475176566','fl.gg',105,'inbound','','14'),
(287,'BYE','gK000b2ab4','cd9fe14a-a18d-4ba9-ad6e-5c3502e5689e','188745272_66568792@74.120.93.200','200','OK','2025-11-06 03:28:22','34.226.36.34','proj_MrxkZ5BlbAFrpJXiyZBrs6mq','OAI','sip.api.openai.com','+19475176566','fl.gg',105,'','','14'),
(288,'INVITE','gK0416f05b','58e5701b-8559-4370-9ac5-fbf0e7f9f1fe','40164784_119248421@206.147.88.72','200','OK','2025-11-06 03:45:23','34.226.36.35','proj_MrxkZ5BlbAFrpJXiyZBrs6mq','proj_MrxkZ5BlbAFrpJXiyZBrs6mq','sip.api.openai.com','+19475176566','fl.gg',106,'inbound','','14'),
(289,'BYE','gK0416f05b','58e5701b-8559-4370-9ac5-fbf0e7f9f1fe','40164784_119248421@206.147.88.72','481','','2025-11-06 03:47:05','34.226.36.35','proj_MrxkZ5BlbAFrpJXiyZBrs6mq','OAI','sip.api.openai.com','+19475176566','fl.gg',106,'','','14'),
(290,'INVITE','gK0c0f7f99','63193eaf-fd24-4619-be90-95577152948e','187440117_27425980@74.120.93.200','200','OK','2025-11-06 03:47:12','34.226.36.32','proj_MrxkZ5BlbAFrpJXiyZBrs6mq','proj_MrxkZ5BlbAFrpJXiyZBrs6mq','sip.api.openai.com','+19475176566','fl.gg',107,'inbound','3','14'),
(291,'BYE','gK0c0f7f99','63193eaf-fd24-4619-be90-95577152948e','187440117_27425980@74.120.93.200','481','','2025-11-06 03:48:39','34.226.36.32','proj_MrxkZ5BlbAFrpJXiyZBrs6mq','OAI','sip.api.openai.com','+19475176566','fl.gg',107,'','3','14'),
(292,'INVITE','gK080063c6','80ff31a4-19ed-4f08-b378-f4f688bd1ba0','235440033_129684062@74.120.93.30','200','OK','2025-11-06 04:12:47','34.226.36.34','proj_MrxkZ5BlbAFrpJXiyZBrs6mq','proj_MrxkZ5BlbAFrpJXiyZBrs6mq','sip.api.openai.com','+19475176566','fl.gg',108,'inbound','','14'),
(293,'BYE','gK080063c6','80ff31a4-19ed-4f08-b378-f4f688bd1ba0','235440033_129684062@74.120.93.30','200','OK','2025-11-06 04:13:17','34.226.36.34','proj_MrxkZ5BlbAFrpJXiyZBrs6mq','OAI','sip.api.openai.com','+19475176566','fl.gg',108,'','','14'),
(294,'INVITE','gK004989c7','fea564aa-6806-4159-84c5-409e9ef11e40','188749853_60792867@74.120.93.200','200','OK','2025-11-06 04:20:11','34.226.36.33','proj_MrxkZ5BlbAFrpJXiyZBrs6mq','proj_MrxkZ5BlbAFrpJXiyZBrs6mq','sip.api.openai.com','+19475176566','fl.gg',109,'inbound','','14'),
(295,'BYE','gK004989c7','fea564aa-6806-4159-84c5-409e9ef11e40','188749853_60792867@74.120.93.200','200','OK','2025-11-06 04:20:19','34.226.36.33','proj_MrxkZ5BlbAFrpJXiyZBrs6mq','OAI','sip.api.openai.com','+19475176566','fl.gg',109,'','','14'),
(296,'INVITE','gK00010414','0553c686-455d-49ef-a05c-8527e4313fc5','35710658_131840209@206.147.88.72','200','OK','2025-11-06 04:20:23','34.226.36.34','proj_MrxkZ5BlbAFrpJXiyZBrs6mq','proj_MrxkZ5BlbAFrpJXiyZBrs6mq','sip.api.openai.com','+19475176566','fl.gg',110,'inbound','','14'),
(297,'BYE','gK00010414','0553c686-455d-49ef-a05c-8527e4313fc5','35710658_131840209@206.147.88.72','200','OK','2025-11-06 04:20:43','34.226.36.34','proj_MrxkZ5BlbAFrpJXiyZBrs6mq','OAI','sip.api.openai.com','+19475176566','fl.gg',110,'','','14'),
(298,'INVITE','gK0433d06b','c192c718-ea77-4b44-9af2-c0a54a2177ff','33818692_70244339@206.147.88.72','200','OK','2025-11-06 04:28:18','34.226.36.34','proj_MrxkZ5BlbAFrpJXiyZBrs6mq','proj_MrxkZ5BlbAFrpJXiyZBrs6mq','sip.api.openai.com','+19475176566','fl.gg',111,'inbound','','14'),
(299,'BYE','gK0433d06b','c192c718-ea77-4b44-9af2-c0a54a2177ff','33818692_70244339@206.147.88.72','200','OK','2025-11-06 04:29:17','34.226.36.34','proj_MrxkZ5BlbAFrpJXiyZBrs6mq','OAI','sip.api.openai.com','+19475176566','fl.gg',111,'','','14'),
(300,'INVITE','gK0c311784','84511a72-7edb-4e5c-8e48-740f39fae675','235705812_102674735@74.120.93.30','200','OK','2025-11-06 04:54:01','34.226.36.34','proj_MrxkZ5BlbAFrpJXiyZBrs6mq','proj_MrxkZ5BlbAFrpJXiyZBrs6mq','sip.api.openai.com','+19475176566','fl.gg',112,'inbound','','14'),
(301,'BYE','gK0c311784','84511a72-7edb-4e5c-8e48-740f39fae675','235705812_102674735@74.120.93.30','481','','2025-11-06 04:54:56','34.226.36.34','proj_MrxkZ5BlbAFrpJXiyZBrs6mq','OAI','sip.api.openai.com','+19475176566','fl.gg',112,'','','14'),
(302,'INVITE','gK00743265','18f9cb20-66c1-4edb-b0b7-c7f7234461bf','188752423_133592721@74.120.93.200','200','OK','2025-11-06 05:02:35','34.226.36.35','proj_MrxkZ5BlbAFrpJXiyZBrs6mq','proj_MrxkZ5BlbAFrpJXiyZBrs6mq','sip.api.openai.com','+19475176566','fl.gg',113,'inbound','','14'),
(303,'BYE','gK00743265','18f9cb20-66c1-4edb-b0b7-c7f7234461bf','188752423_133592721@74.120.93.200','200','OK','2025-11-06 05:03:58','34.226.36.35','proj_MrxkZ5BlbAFrpJXiyZBrs6mq','OAI','sip.api.openai.com','+19475176566','fl.gg',113,'','','14'),
(304,'INVITE','gK043239b3','55ed7276-b471-426c-8a02-c9b5be5b5801','235184282_50299290@74.120.93.30','200','OK','2025-11-06 05:07:33','34.226.36.35','proj_MrxkZ5BlbAFrpJXiyZBrs6mq','proj_MrxkZ5BlbAFrpJXiyZBrs6mq','sip.api.openai.com','+19475176566','fl.gg',114,'inbound','','14'),
(305,'BYE','gK043239b3','55ed7276-b471-426c-8a02-c9b5be5b5801','235184282_50299290@74.120.93.30','200','OK','2025-11-06 05:08:48','34.226.36.35','proj_MrxkZ5BlbAFrpJXiyZBrs6mq','OAI','sip.api.openai.com','+19475176566','fl.gg',114,'','','14'),
(306,'INVITE','gK0c5edb2f','bac53002-7dbc-4696-80d4-0c290a3e5443','34379581_16443681@206.147.88.72','200','OK','2025-11-06 05:10:24','34.226.36.33','proj_MrxkZ5BlbAFrpJXiyZBrs6mq','proj_MrxkZ5BlbAFrpJXiyZBrs6mq','sip.api.openai.com','+19475176566','fl.gg',115,'inbound','','14'),
(307,'BYE','gK0c5edb2f','bac53002-7dbc-4696-80d4-0c290a3e5443','34379581_16443681@206.147.88.72','200','OK','2025-11-06 05:10:29','34.226.36.33','proj_MrxkZ5BlbAFrpJXiyZBrs6mq','OAI','sip.api.openai.com','+19475176566','fl.gg',115,'','','14'),
(308,'INVITE','gK0829d920','427d06da-a026-4dbf-8c1b-2deee869ec0e','271067061_111069076@74.120.93.30','200','OK','2025-11-06 13:34:48','34.226.36.34','proj_MrxkZ5BlbAFrpJXiyZBrs6mq','proj_MrxkZ5BlbAFrpJXiyZBrs6mq','sip.api.openai.com','+19475176566','fl.gg',116,'inbound','','14'),
(309,'BYE','gK0829d920','427d06da-a026-4dbf-8c1b-2deee869ec0e','271067061_111069076@74.120.93.30','200','OK','2025-11-06 13:34:49','34.226.36.34','proj_MrxkZ5BlbAFrpJXiyZBrs6mq','OAI','sip.api.openai.com','+19475176566','fl.gg',116,'','','14'),
(310,'INVITE','21043812_c3356d0b_0c3833a4-1cd6-4ecb-bdce-fa26b84066d7','9a933fd6-7a77-47af-a55b-9284d5deb0ac','dd89bbdce6f544370a93fbdcc0e8ee1b@0.0.0.0','200','OK','2025-11-06 19:36:09','54.244.51.2','proj_MrxkZ5BlbAFrpJXiyZBrs6mq','proj_MrxkZ5BlbAFrpJXiyZBrs6mq','sip.api.openai.com','+19475176566','dsiptest.pstn.twilio.com',117,'inbound','1','14'),
(311,'BYE','21043812_c3356d0b_0c3833a4-1cd6-4ecb-bdce-fa26b84066d7','9a933fd6-7a77-47af-a55b-9284d5deb0ac','dd89bbdce6f544370a93fbdcc0e8ee1b@0.0.0.0','200','OK','2025-11-06 19:36:20','54.244.51.2','+13132468974','OAI','sip.api.openai.com','+19475176566','dsiptest.pstn.twilio.com',117,'','1','14'),
(312,'INVITE','05805446_c3356d0b_4b4993d8-535f-4645-bc83-5c36d4eeea34','f87b109b-cf7b-4884-8930-4ebc998dfae2','85348c4c463d800701f04a76875ce7d6@0.0.0.0','200','OK','2025-11-06 19:37:27','54.172.60.1','proj_LiCooyUxqKrHxGckhR34dpHR','proj_LiCooyUxqKrHxGckhR34dpHR','sip.api.openai.com','+19475176566','dsiptest.pstn.twilio.com',118,'inbound','1','15'),
(313,'BYE','05805446_c3356d0b_4b4993d8-535f-4645-bc83-5c36d4eeea34','f87b109b-cf7b-4884-8930-4ebc998dfae2','85348c4c463d800701f04a76875ce7d6@0.0.0.0','200','OK','2025-11-06 19:37:41','54.172.60.1','+13132468974','OAI','sip.api.openai.com','+19475176566','dsiptest.pstn.twilio.com',118,'','1','15'),
(314,'INVITE','21604887_c3356d0b_339814ab-e7d7-4ef3-b5bf-e7fe88fc320b','57f5105d-bf93-4ac7-912e-08728e127e96','f7e2712e3171615fc256382d092b7436@0.0.0.0','200','OK','2025-11-06 20:02:51','54.172.60.0','proj_LiCooyUxqKrHxGckhR34dpHR','proj_LiCooyUxqKrHxGckhR34dpHR','sip.api.openai.com','+19475176566','dsiptest.pstn.twilio.com',119,'inbound','1','15'),
(315,'BYE','21604887_c3356d0b_339814ab-e7d7-4ef3-b5bf-e7fe88fc320b','57f5105d-bf93-4ac7-912e-08728e127e96','f7e2712e3171615fc256382d092b7436@0.0.0.0','200','OK','2025-11-06 20:03:20','54.172.60.0','+13132468974','OAI','sip.api.openai.com','+19475176566','dsiptest.pstn.twilio.com',119,'','1','15'),
(316,'INVITE','24846813_c3356d0b_30452c08-1e3d-46dd-8b4d-6da896d64ae8','6aed329c-845a-48be-95a4-54f6cfe359ce','d40a8fa5059508200af5b7f36abb32a2@0.0.0.0','200','OK','2025-11-06 20:03:25','54.172.60.2','proj_LiCooyUxqKrHxGckhR34dpHR','proj_LiCooyUxqKrHxGckhR34dpHR','sip.api.openai.com','+19475176566','dsiptest.pstn.twilio.com',120,'inbound','1','15'),
(317,'BYE','24846813_c3356d0b_30452c08-1e3d-46dd-8b4d-6da896d64ae8','6aed329c-845a-48be-95a4-54f6cfe359ce','d40a8fa5059508200af5b7f36abb32a2@0.0.0.0','200','OK','2025-11-06 20:03:32','54.172.60.2','+13132468974','OAI','sip.api.openai.com','+19475176566','dsiptest.pstn.twilio.com',120,'','1','15'),
(318,'INVITE','38665278_c3356d0b_5d0c44d1-818d-4e17-820b-89ae6bdfc1ea','dbeb1d58-1659-4418-90a4-dcdd9dcbdd9e','3fc4ea6dd7e659103a56361daa0e200b@0.0.0.0','200','OK','2025-11-06 20:04:26','54.244.51.1','proj_LiCooyUxqKrHxGckhR34dpHR','proj_LiCooyUxqKrHxGckhR34dpHR','sip.api.openai.com','+19475176566','dsiptest.pstn.twilio.com',121,'inbound','1','15'),
(319,'BYE','38665278_c3356d0b_5d0c44d1-818d-4e17-820b-89ae6bdfc1ea','dbeb1d58-1659-4418-90a4-dcdd9dcbdd9e','3fc4ea6dd7e659103a56361daa0e200b@0.0.0.0','200','OK','2025-11-06 20:05:51','54.244.51.1','+13132468974','OAI','sip.api.openai.com','+19475176566','dsiptest.pstn.twilio.com',121,'','1','15'),
(320,'INVITE','07807462_c3356d0b_67f4aeea-d964-44be-ba8e-9578365d0faa','3b9af439-5b0f-4da5-9aa5-5b31f8472125','37a92d49e7d22394c7bfd07c87fb668e@0.0.0.0','200','OK','2025-11-06 20:11:06','54.172.60.2','proj_LiCooyUxqKrHxGckhR34dpHR','proj_LiCooyUxqKrHxGckhR34dpHR','sip.api.openai.com','+19475176566','dsiptest.pstn.twilio.com',122,'inbound','1','15'),
(321,'BYE','07807462_c3356d0b_67f4aeea-d964-44be-ba8e-9578365d0faa','3b9af439-5b0f-4da5-9aa5-5b31f8472125','37a92d49e7d22394c7bfd07c87fb668e@0.0.0.0','200','OK','2025-11-06 20:11:52','54.172.60.2','+13132468974','OAI','sip.api.openai.com','+19475176566','dsiptest.pstn.twilio.com',122,'','1','15'),
(322,'INVITE','17087905_c3356d0b_6ebce8dd-2cc4-4319-9e70-4aecdaff6239','bde55dc5-bfe6-4553-9ced-4d98b3aafef6','4b4a8abd4374c4022de75be0f6a8c814@0.0.0.0','200','OK','2025-11-06 20:15:15','54.244.51.2','proj_LiCooyUxqKrHxGckhR34dpHR','proj_LiCooyUxqKrHxGckhR34dpHR','sip.api.openai.com','+19475176566','dsiptest.pstn.twilio.com',123,'inbound','1','15'),
(323,'BYE','17087905_c3356d0b_6ebce8dd-2cc4-4319-9e70-4aecdaff6239','bde55dc5-bfe6-4553-9ced-4d98b3aafef6','4b4a8abd4374c4022de75be0f6a8c814@0.0.0.0','200','OK','2025-11-06 20:15:50','54.244.51.2','+13132468974','OAI','sip.api.openai.com','+19475176566','dsiptest.pstn.twilio.com',123,'','1','15'),
(324,'INVITE','24472961_c3356d0b_1a82e05a-820e-46ea-a7fc-edb28311abe8','529d04e5-c904-4d37-8090-0eef8f8eca57','cb1fbe1ee3b952f943c987714df89760@0.0.0.0','200','OK','2025-11-06 20:16:23','54.172.60.0','proj_LiCooyUxqKrHxGckhR34dpHR','proj_LiCooyUxqKrHxGckhR34dpHR','sip.api.openai.com','+19475176566','dsiptest.pstn.twilio.com',124,'inbound','1','15'),
(325,'BYE','24472961_c3356d0b_1a82e05a-820e-46ea-a7fc-edb28311abe8','529d04e5-c904-4d37-8090-0eef8f8eca57','cb1fbe1ee3b952f943c987714df89760@0.0.0.0','200','OK','2025-11-06 20:17:06','54.172.60.0','+13132468974','OAI','sip.api.openai.com','+19475176566','dsiptest.pstn.twilio.com',124,'','1','15'),
(326,'INVITE','02581171_c3356d0b_d4d53f33-5ead-4b7c-8c71-f52a3417fa70','2688bc0b-25a3-42fb-9d06-cc1a0ee1cd53','0d07b1c9f78e9d6e931c9e0e9132b753@0.0.0.0','200','OK','2025-11-06 20:27:51','54.172.60.1','proj_LiCooyUxqKrHxGckhR34dpHR','proj_LiCooyUxqKrHxGckhR34dpHR','sip.api.openai.com','+19475176566','dsiptest.pstn.twilio.com',125,'inbound','1','15'),
(327,'BYE','02581171_c3356d0b_d4d53f33-5ead-4b7c-8c71-f52a3417fa70','2688bc0b-25a3-42fb-9d06-cc1a0ee1cd53','0d07b1c9f78e9d6e931c9e0e9132b753@0.0.0.0','481','','2025-11-06 20:28:42','54.172.60.1','+13132468974','OAI','sip.api.openai.com','+19475176566','dsiptest.pstn.twilio.com',125,'','1','15'),
(328,'INVITE','38560634_c3356d0b_f7eb97d5-543a-4859-afd2-cd03d0921573','bdca2fa5-8a79-4f98-8957-333c7bf140f0','f2b6a6538b8feb1059adf193a6b43ece@0.0.0.0','200','OK','2025-11-06 21:01:07','54.172.60.3','proj_LiCooyUxqKrHxGckhR34dpHR','proj_LiCooyUxqKrHxGckhR34dpHR','sip.api.openai.com','+19475176566','dsiptest.pstn.twilio.com',126,'inbound','1','15'),
(329,'BYE','38560634_c3356d0b_f7eb97d5-543a-4859-afd2-cd03d0921573','bdca2fa5-8a79-4f98-8957-333c7bf140f0','f2b6a6538b8feb1059adf193a6b43ece@0.0.0.0','200','OK','2025-11-06 21:01:27','54.172.60.3','+13132468974','OAI','sip.api.openai.com','+19475176566','dsiptest.pstn.twilio.com',126,'','1','15'),
(330,'INVITE','06383118_c3356d0b_57c77f02-0516-4704-9d11-f180a31ce292','348762a6-b09b-4fe5-b6de-3aefe6e5ccb9','b610d03fa722f88e928f0e8e3a7d1010@0.0.0.0','200','OK','2025-11-06 22:09:41','54.244.51.2','proj_LiCooyUxqKrHxGckhR34dpHR','proj_LiCooyUxqKrHxGckhR34dpHR','sip.api.openai.com','+19475176566','dsiptest.pstn.twilio.com',127,'inbound','1','15'),
(331,'BYE','06383118_c3356d0b_57c77f02-0516-4704-9d11-f180a31ce292','348762a6-b09b-4fe5-b6de-3aefe6e5ccb9','b610d03fa722f88e928f0e8e3a7d1010@0.0.0.0','200','OK','2025-11-06 22:11:44','54.244.51.2','+13132468974','OAI','sip.api.openai.com','+19475176566','dsiptest.pstn.twilio.com',127,'','1','15'),
(332,'INVITE','89772968_c3356d0b_0b0ae86a-6742-47c4-83ef-204db9924b4e','fd7c030b-77f4-42fd-984a-0edfb4cf1558','9d4be0c4690aef1dca8e3cc227d1a2f7@0.0.0.0','200','OK','2025-11-06 22:17:09','54.172.60.3','proj_LiCooyUxqKrHxGckhR34dpHR','proj_LiCooyUxqKrHxGckhR34dpHR','sip.api.openai.com','+19475176566','dsiptest.pstn.twilio.com',128,'inbound','1','15'),
(333,'BYE','89772968_c3356d0b_0b0ae86a-6742-47c4-83ef-204db9924b4e','fd7c030b-77f4-42fd-984a-0edfb4cf1558','9d4be0c4690aef1dca8e3cc227d1a2f7@0.0.0.0','200','OK','2025-11-06 22:18:51','54.172.60.3','+13132468974','OAI','sip.api.openai.com','+19475176566','dsiptest.pstn.twilio.com',128,'','1','15'),
(334,'INVITE','40134249_c3356d0b_60ac177e-d57e-4f9e-9f0c-1551475f38fe','b28637f6-d330-444b-9675-330f80c0544b','11d8692bf0672708a7bdd38e31db8a0c@0.0.0.0','200','OK','2025-11-06 22:21:08','54.244.51.0','proj_LiCooyUxqKrHxGckhR34dpHR','proj_LiCooyUxqKrHxGckhR34dpHR','sip.api.openai.com','+19475176566','dsiptest.pstn.twilio.com',129,'inbound','1','15'),
(335,'BYE','40134249_c3356d0b_60ac177e-d57e-4f9e-9f0c-1551475f38fe','b28637f6-d330-444b-9675-330f80c0544b','11d8692bf0672708a7bdd38e31db8a0c@0.0.0.0','481','','2025-11-06 22:23:30','54.244.51.0','+13132468974','OAI','sip.api.openai.com','+19475176566','dsiptest.pstn.twilio.com',129,'','1','15'),
(336,'INVITE','86702273_c3356d0b_2a947246-c753-4199-b738-a29b235b39b8','922b5ed9-813d-4184-a551-28453e7357da','5fcb7c9013ea7dbf3a30f684b1657e81@0.0.0.0','200','OK','2025-11-06 22:59:57','54.172.60.1','proj_LiCooyUxqKrHxGckhR34dpHR','proj_LiCooyUxqKrHxGckhR34dpHR','sip.api.openai.com','+19475176566','dsiptest.pstn.twilio.com',130,'inbound','1','15'),
(337,'BYE','86702273_c3356d0b_2a947246-c753-4199-b738-a29b235b39b8','922b5ed9-813d-4184-a551-28453e7357da','5fcb7c9013ea7dbf3a30f684b1657e81@0.0.0.0','200','OK','2025-11-06 23:00:49','54.172.60.1','+13132468974','OAI','sip.api.openai.com','+19475176566','dsiptest.pstn.twilio.com',130,'','1','15'),
(338,'INVITE','61150832_c3356d0b_79a17045-2953-4bc3-a32f-576ebc7fcdf8','8410e585-f979-4f59-8c06-e40bb2e9302b','0d2a3cd1a5934cdc2ff96e0c34a4ab26@0.0.0.0','200','OK','2025-11-06 23:10:28','54.244.51.2','proj_LiCooyUxqKrHxGckhR34dpHR','proj_LiCooyUxqKrHxGckhR34dpHR','sip.api.openai.com','+12484706952','dsiptest.pstn.twilio.com',131,'inbound','1','15'),
(339,'BYE','61150832_c3356d0b_79a17045-2953-4bc3-a32f-576ebc7fcdf8','8410e585-f979-4f59-8c06-e40bb2e9302b','0d2a3cd1a5934cdc2ff96e0c34a4ab26@0.0.0.0','481','','2025-11-06 23:12:15','54.244.51.2','+13132468974','OAI','sip.api.openai.com','+12484706952','dsiptest.pstn.twilio.com',131,'','1','15'),
(340,'INVITE','43151728_c3356d0b_057a8106-1333-4f24-9025-9182e57ca436','34fa9516-05e2-4e57-8f4b-69dd5bd9e80e','b94e299e0869f1406cc9dca657d035a9@0.0.0.0','200','OK','2025-11-07 02:41:30','54.172.60.3','proj_LiCooyUxqKrHxGckhR34dpHR','proj_LiCooyUxqKrHxGckhR34dpHR','sip.api.openai.com','+19475176566','dsiptest.pstn.twilio.com',132,'inbound','1','15'),
(341,'BYE','43151728_c3356d0b_057a8106-1333-4f24-9025-9182e57ca436','34fa9516-05e2-4e57-8f4b-69dd5bd9e80e','b94e299e0869f1406cc9dca657d035a9@0.0.0.0','481','','2025-11-07 02:44:48','54.172.60.3','+13132468974','OAI','sip.api.openai.com','+19475176566','dsiptest.pstn.twilio.com',132,'','1','15'),
(342,'INVITE','25980171_c3356d0b_379fb503-8214-47ee-8a59-f1df4add2a6f','9b1ae7ac-3543-4184-a310-99a0757072e4','046bc1cb7ba0d0b416b275fc75d420ea@0.0.0.0','200','OK','2025-11-07 02:48:04','54.244.51.0','proj_LiCooyUxqKrHxGckhR34dpHR','proj_LiCooyUxqKrHxGckhR34dpHR','sip.api.openai.com','+19475176566','dsiptest.pstn.twilio.com',133,'inbound','1','15'),
(343,'BYE','25980171_c3356d0b_379fb503-8214-47ee-8a59-f1df4add2a6f','9b1ae7ac-3543-4184-a310-99a0757072e4','046bc1cb7ba0d0b416b275fc75d420ea@0.0.0.0','481','','2025-11-07 02:51:09','54.244.51.0','+13132468974','OAI','sip.api.openai.com','+19475176566','dsiptest.pstn.twilio.com',133,'','1','15'),
(344,'INVITE','97319035_c3356d0b_24cd15b1-6170-4bf2-a975-af818e8ffe0a','e730805a-65e9-4813-bb4b-2e7e317a29f4','85d4c57c076038ebc83e456505fde1d4@0.0.0.0','200','OK','2025-11-07 04:39:31','54.244.51.1','proj_LiCooyUxqKrHxGckhR34dpHR','proj_LiCooyUxqKrHxGckhR34dpHR','sip.api.openai.com','+19475176566','dsiptest.pstn.twilio.com',134,'inbound','1','15'),
(345,'BYE','97319035_c3356d0b_24cd15b1-6170-4bf2-a975-af818e8ffe0a','e730805a-65e9-4813-bb4b-2e7e317a29f4','85d4c57c076038ebc83e456505fde1d4@0.0.0.0','200','OK','2025-11-07 04:41:18','54.244.51.1','+13132468974','OAI','sip.api.openai.com','+19475176566','dsiptest.pstn.twilio.com',134,'','1','15'),
(346,'INVITE','69727179_c3356d0b_086df6d1-2e1c-4f4e-bc16-125d5587387e','25f4f47c-78a5-49a4-b5c4-2f233fd6fe55','781bf2b2bafeeaac7ce686fad84af3a5@0.0.0.0','200','OK','2025-11-07 04:52:04','54.244.51.1','proj_LiCooyUxqKrHxGckhR34dpHR','proj_LiCooyUxqKrHxGckhR34dpHR','sip.api.openai.com','+19475176566','dsiptest.pstn.twilio.com',135,'inbound','1','15'),
(347,'BYE','69727179_c3356d0b_086df6d1-2e1c-4f4e-bc16-125d5587387e','25f4f47c-78a5-49a4-b5c4-2f233fd6fe55','781bf2b2bafeeaac7ce686fad84af3a5@0.0.0.0','481','','2025-11-07 04:53:44','54.244.51.1','+13132468974','OAI','sip.api.openai.com','+19475176566','dsiptest.pstn.twilio.com',135,'','1','15'),
(348,'INVITE','22546849_c3356d0b_ffaf2828-e3df-4d76-87fc-a941923066c6','df8e3491-4d77-46fe-9f8a-1c5495d4d684','90eb0d24b4cf7db7dc44d194ea3fa5e9@0.0.0.0','200','OK','2025-11-07 04:54:48','54.172.60.0','proj_LiCooyUxqKrHxGckhR34dpHR','proj_LiCooyUxqKrHxGckhR34dpHR','sip.api.openai.com','+19475176566','dsiptest.pstn.twilio.com',136,'inbound','1','15'),
(349,'BYE','22546849_c3356d0b_ffaf2828-e3df-4d76-87fc-a941923066c6','df8e3491-4d77-46fe-9f8a-1c5495d4d684','90eb0d24b4cf7db7dc44d194ea3fa5e9@0.0.0.0','200','OK','2025-11-07 04:56:18','54.172.60.0','+13132468974','OAI','sip.api.openai.com','+19475176566','dsiptest.pstn.twilio.com',136,'','1','15'),
(350,'INVITE','01651560_c3356d0b_4cc3f51f-1f78-49c1-861b-130f719dd712','22d51d79-071e-4f6b-ba22-8011fe5d8b42','46b4a2758b64ffd2b23370d035e285f8@0.0.0.0','200','OK','2025-11-07 05:04:54','54.172.60.3','proj_LiCooyUxqKrHxGckhR34dpHR','proj_LiCooyUxqKrHxGckhR34dpHR','sip.api.openai.com','+19475176566','dsiptest.pstn.twilio.com',137,'inbound','1','15'),
(351,'BYE','01651560_c3356d0b_4cc3f51f-1f78-49c1-861b-130f719dd712','22d51d79-071e-4f6b-ba22-8011fe5d8b42','46b4a2758b64ffd2b23370d035e285f8@0.0.0.0','200','OK','2025-11-07 05:06:38','54.172.60.3','+13132468974','OAI','sip.api.openai.com','+19475176566','dsiptest.pstn.twilio.com',137,'','1','15'),
(352,'INVITE','03942965_c3356d0b_0b906301-9888-478a-8ae1-5a37b0f69122','b6426643-727e-4e5a-a8f8-cc8149f48a07','3735b1e554fb77cd89b5e6468b34026d@0.0.0.0','200','OK','2025-11-07 05:12:04','54.172.60.1','proj_LiCooyUxqKrHxGckhR34dpHR','proj_LiCooyUxqKrHxGckhR34dpHR','sip.api.openai.com','+19475176566','dsiptest.pstn.twilio.com',138,'inbound','1','15'),
(353,'BYE','03942965_c3356d0b_0b906301-9888-478a-8ae1-5a37b0f69122','b6426643-727e-4e5a-a8f8-cc8149f48a07','3735b1e554fb77cd89b5e6468b34026d@0.0.0.0','481','','2025-11-07 05:13:37','54.172.60.1','+13132468974','OAI','sip.api.openai.com','+19475176566','dsiptest.pstn.twilio.com',138,'','1','15'),
(354,'INVITE','07070450_c3356d0b_fbefa2ae-8d74-414b-b176-28dd4d6917a4','9f5cdeff-2f03-4ff7-b645-6feb0d06d3dc','cd9e1423a15fbccc7c056017d3d0f5bf@0.0.0.0','200','OK','2025-11-07 05:23:31','54.172.60.1','proj_LiCooyUxqKrHxGckhR34dpHR','proj_LiCooyUxqKrHxGckhR34dpHR','sip.api.openai.com','+19475176566','dsiptest.pstn.twilio.com',139,'inbound','1','15'),
(355,'BYE','07070450_c3356d0b_fbefa2ae-8d74-414b-b176-28dd4d6917a4','9f5cdeff-2f03-4ff7-b645-6feb0d06d3dc','cd9e1423a15fbccc7c056017d3d0f5bf@0.0.0.0','200','OK','2025-11-07 05:25:36','54.172.60.1','+13132468974','OAI','sip.api.openai.com','+19475176566','dsiptest.pstn.twilio.com',139,'','1','15'),
(356,'INVITE','18848176_c3356d0b_b8028e3f-c0be-4c26-bb7b-e998a05995fe','0977a571-2197-4045-b524-6f5ca1f3743a','5b0edaa9d8352c398d20aa06a3a8487d@0.0.0.0','200','OK','2025-11-07 15:28:51','54.172.60.3','proj_LiCooyUxqKrHxGckhR34dpHR','proj_LiCooyUxqKrHxGckhR34dpHR','sip.api.openai.com','+19475176566','dsiptest.pstn.twilio.com',140,'inbound','1','15'),
(357,'BYE','18848176_c3356d0b_b8028e3f-c0be-4c26-bb7b-e998a05995fe','0977a571-2197-4045-b524-6f5ca1f3743a','5b0edaa9d8352c398d20aa06a3a8487d@0.0.0.0','200','OK','2025-11-07 15:29:12','54.172.60.3','+13132468974','OAI','sip.api.openai.com','+19475176566','dsiptest.pstn.twilio.com',140,'','1','15'),
(358,'INVITE','80788238_c3356d0b_3f65f288-a4a6-40cf-80b8-0ffe1e9d0d45','2529451a-8c73-4bda-8a61-63a1c91f5ddc','dbc915c7bd4bd02eb4e0a40c6877246a@0.0.0.0','200','OK','2025-11-07 15:29:18','54.172.60.1','proj_LiCooyUxqKrHxGckhR34dpHR','proj_LiCooyUxqKrHxGckhR34dpHR','sip.api.openai.com','+19475176566','dsiptest.pstn.twilio.com',141,'inbound','1','15'),
(359,'BYE','80788238_c3356d0b_3f65f288-a4a6-40cf-80b8-0ffe1e9d0d45','2529451a-8c73-4bda-8a61-63a1c91f5ddc','dbc915c7bd4bd02eb4e0a40c6877246a@0.0.0.0','200','OK','2025-11-07 15:29:33','54.172.60.1','+13132468974','OAI','sip.api.openai.com','+19475176566','dsiptest.pstn.twilio.com',141,'','1','15'),
(360,'INVITE','gK00211a7a','bb511a14-4c51-414b-bda6-54b4336417eb','440414293_67069280@74.120.93.30','200','OK','2025-11-07 15:29:43','34.226.36.32','proj_MrxkZ5BlbAFrpJXiyZBrs6mq','proj_MrxkZ5BlbAFrpJXiyZBrs6mq','sip.api.openai.com','+19475176566','fl.gg',142,'inbound','3','14'),
(361,'BYE','gK00211a7a','bb511a14-4c51-414b-bda6-54b4336417eb','440414293_67069280@74.120.93.30','200','OK','2025-11-07 15:30:05','34.226.36.32','proj_MrxkZ5BlbAFrpJXiyZBrs6mq','OAI','sip.api.openai.com','+19475176566','fl.gg',142,'','3','14'),
(362,'INVITE','gK08090144','e830707a-0503-4ea4-9442-8194a489c406','206052666_16230322@74.120.93.200','200','OK','2025-11-07 15:30:11','34.226.36.34','proj_MrxkZ5BlbAFrpJXiyZBrs6mq','proj_MrxkZ5BlbAFrpJXiyZBrs6mq','sip.api.openai.com','+19475176566','fl.gg',143,'inbound','','14'),
(363,'BYE','gK08090144','e830707a-0503-4ea4-9442-8194a489c406','206052666_16230322@74.120.93.200','200','OK','2025-11-07 15:30:23','34.226.36.34','proj_MrxkZ5BlbAFrpJXiyZBrs6mq','OAI','sip.api.openai.com','+19475176566','fl.gg',143,'','','14'),
(364,'INVITE','gK0c426757','4efdf566-e69e-4f47-a8a9-b429039d9473','439143288_123547435@74.120.93.30','200','OK','2025-11-07 15:31:36','34.226.36.33','proj_MrxkZ5BlbAFrpJXiyZBrs6mq','proj_MrxkZ5BlbAFrpJXiyZBrs6mq','sip.api.openai.com','+19475176566','fl.gg',144,'inbound','','14'),
(365,'BYE','gK0c426757','4efdf566-e69e-4f47-a8a9-b429039d9473','439143288_123547435@74.120.93.30','200','OK','2025-11-07 15:32:06','34.226.36.33','proj_MrxkZ5BlbAFrpJXiyZBrs6mq','OAI','sip.api.openai.com','+19475176566','fl.gg',144,'','','14'),
(366,'INVITE','gK0076bae6','21a4e330-d027-4cc1-b4f6-4c10f72f84c8','224411662_28298109@74.120.93.200','200','OK','2025-11-07 15:39:40','34.226.36.34','proj_MrxkZ5BlbAFrpJXiyZBrs6mq','proj_MrxkZ5BlbAFrpJXiyZBrs6mq','sip.api.openai.com','+19475176566','fl.gg',145,'inbound','','14'),
(367,'BYE','gK0076bae6','21a4e330-d027-4cc1-b4f6-4c10f72f84c8','224411662_28298109@74.120.93.200','200','OK','2025-11-07 15:39:53','34.226.36.34','proj_MrxkZ5BlbAFrpJXiyZBrs6mq','OAI','sip.api.openai.com','+19475176566','fl.gg',145,'','','14'),
(368,'INVITE','gK0c1b0b23','59039a7d-ec24-4120-8739-81934df5e0c9','441203170_117435175@74.120.93.30','200','OK','2025-11-07 15:41:00','34.226.36.34','proj_MrxkZ5BlbAFrpJXiyZBrs6mq','proj_MrxkZ5BlbAFrpJXiyZBrs6mq','sip.api.openai.com','+19475176566','fl.gg',146,'inbound','','14'),
(369,'BYE','gK0c1b0b23','59039a7d-ec24-4120-8739-81934df5e0c9','441203170_117435175@74.120.93.30','200','OK','2025-11-07 15:41:16','34.226.36.34','proj_MrxkZ5BlbAFrpJXiyZBrs6mq','OAI','sip.api.openai.com','+19475176566','fl.gg',146,'','','14'),
(370,'INVITE','80724980_c3356d0b_f82a8c56-458c-42f6-af63-94d21d29b089','734ccd43-eb48-4d75-b208-3f5d6b96d967','7ac1377658bb5825ec947ff1c684e289@0.0.0.0','200','OK','2025-11-07 21:46:52','54.244.51.0','proj_LiCooyUxqKrHxGckhR34dpHR','proj_LiCooyUxqKrHxGckhR34dpHR','sip.api.openai.com','+19475176566','dsiptest.pstn.twilio.com',147,'inbound','1','15'),
(371,'BYE','80724980_c3356d0b_f82a8c56-458c-42f6-af63-94d21d29b089','734ccd43-eb48-4d75-b208-3f5d6b96d967','7ac1377658bb5825ec947ff1c684e289@0.0.0.0','200','OK','2025-11-07 21:48:00','54.244.51.0','+13132468974','OAI','sip.api.openai.com','+19475176566','dsiptest.pstn.twilio.com',147,'','1','15'),
(372,'INVITE','35032474_c3356d0b_2e08da86-06fb-482f-ade8-dc726b588cba','753e4e7e-4d87-4e38-a35b-68a309e517e9','3d1f7b95e4256df03347af4eaee63056@0.0.0.0','200','OK','2025-11-08 21:51:49','54.244.51.2','proj_LiCooyUxqKrHxGckhR34dpHR','proj_LiCooyUxqKrHxGckhR34dpHR','sip.api.openai.com','+19475176566','dsiptest.pstn.twilio.com',148,'inbound','1','15'),
(373,'BYE','35032474_c3356d0b_2e08da86-06fb-482f-ade8-dc726b588cba','753e4e7e-4d87-4e38-a35b-68a309e517e9','3d1f7b95e4256df03347af4eaee63056@0.0.0.0','200','OK','2025-11-08 21:52:28','54.244.51.2','+13132468974','OAI','sip.api.openai.com','+19475176566','dsiptest.pstn.twilio.com',148,'','1','15'),
(374,'INVITE','77346911_c3356d0b_cb5ac895-7e42-4e9d-b653-443977c1a05e','f7d0ac41-6cac-49af-bcd7-f73f08dc004b','149a1901280ff526f7a8617350d3b210@0.0.0.0','200','OK','2025-11-09 02:33:32','54.244.51.2','proj_LiCooyUxqKrHxGckhR34dpHR','proj_LiCooyUxqKrHxGckhR34dpHR','sip.api.openai.com','+19475176566','dsiptest.pstn.twilio.com',149,'inbound','1','15'),
(375,'BYE','77346911_c3356d0b_cb5ac895-7e42-4e9d-b653-443977c1a05e','f7d0ac41-6cac-49af-bcd7-f73f08dc004b','149a1901280ff526f7a8617350d3b210@0.0.0.0','200','OK','2025-11-09 02:33:40','54.244.51.2','+13132468974','OAI','sip.api.openai.com','+19475176566','dsiptest.pstn.twilio.com',149,'','1','15'),
(376,'INVITE','72027102_c3356d0b_47e939af-9d89-4a24-96da-8c46f428e5a8','9f92dd53-debb-4e33-ae0e-cde8bba339b6','7ae7c235ef8d7839c8e32e956d105caa@0.0.0.0','200','OK','2025-11-09 02:33:45','54.172.60.0','proj_LiCooyUxqKrHxGckhR34dpHR','proj_LiCooyUxqKrHxGckhR34dpHR','sip.api.openai.com','+19475176566','dsiptest.pstn.twilio.com',150,'inbound','1','15'),
(377,'BYE','72027102_c3356d0b_47e939af-9d89-4a24-96da-8c46f428e5a8','9f92dd53-debb-4e33-ae0e-cde8bba339b6','7ae7c235ef8d7839c8e32e956d105caa@0.0.0.0','200','OK','2025-11-09 02:33:55','54.172.60.0','+13132468974','OAI','sip.api.openai.com','+19475176566','dsiptest.pstn.twilio.com',150,'','1','15'),
(378,'INVITE','10202309_c3356d0b_215e6dde-3414-4404-8a71-5bdd0ee21767','501a829f-14be-42b2-9ef0-a2a9c13d29bc','c941f786b6e8a63111f48037eb0ab331@0.0.0.0','200','OK','2025-11-09 03:12:22','54.172.60.0','proj_LiCooyUxqKrHxGckhR34dpHR','proj_LiCooyUxqKrHxGckhR34dpHR','sip.api.openai.com','+13137891332','dsiptest.pstn.twilio.com',151,'inbound','1','15'),
(379,'BYE','10202309_c3356d0b_215e6dde-3414-4404-8a71-5bdd0ee21767','501a829f-14be-42b2-9ef0-a2a9c13d29bc','c941f786b6e8a63111f48037eb0ab331@0.0.0.0','200','OK','2025-11-09 03:13:59','54.172.60.0','+13132468974','OAI','sip.api.openai.com','+13137891332','dsiptest.pstn.twilio.com',151,'','1','15'),
(380,'INVITE','12167175_c3356d0b_88524362-3ad7-4a50-aa2a-408ccf61fa6f','6e190b7a-171c-41a9-b1db-ff8e0ea78bbb','dd936d469f1dfaba314317119a8de26d@0.0.0.0','200','OK','2025-11-09 17:20:26','54.172.60.3','proj_LiCooyUxqKrHxGckhR34dpHR','proj_LiCooyUxqKrHxGckhR34dpHR','sip.api.openai.com','+19475176566','dsiptest.pstn.twilio.com',152,'inbound','1','15'),
(381,'BYE','12167175_c3356d0b_88524362-3ad7-4a50-aa2a-408ccf61fa6f','6e190b7a-171c-41a9-b1db-ff8e0ea78bbb','dd936d469f1dfaba314317119a8de26d@0.0.0.0','200','OK','2025-11-09 17:21:11','54.172.60.3','+13132468974','OAI','sip.api.openai.com','+19475176566','dsiptest.pstn.twilio.com',152,'','1','15'),
(382,'INVITE','42579995_c3356d0b_40e96ec3-0d6c-487a-a801-a63a18f0f42c','8fc2ac5e-bc71-47a8-aa02-e7617f5e3a7a','fa36519e7787a2697b3d81b5072cd7c4@0.0.0.0','200','OK','2025-11-10 02:14:33','54.244.51.2','proj_LiCooyUxqKrHxGckhR34dpHR','proj_LiCooyUxqKrHxGckhR34dpHR','sip.api.openai.com','+19475176566','dsiptest.pstn.twilio.com',153,'inbound','1','15'),
(383,'INVITE','83513978_c3356d0b_3aeda2fe-99d7-4992-be4b-222408309946','aae04739-e1a4-4a12-945b-42aeaefce961','92c444c825065407774fcf2893009e16@0.0.0.0','200','OK','2025-11-10 02:14:52','54.172.60.3','proj_LiCooyUxqKrHxGckhR34dpHR','proj_LiCooyUxqKrHxGckhR34dpHR','sip.api.openai.com','+18889072085','dsiptest.pstn.twilio.com',154,'inbound','1','15'),
(384,'BYE','42579995_c3356d0b_40e96ec3-0d6c-487a-a801-a63a18f0f42c','8fc2ac5e-bc71-47a8-aa02-e7617f5e3a7a','fa36519e7787a2697b3d81b5072cd7c4@0.0.0.0','200','OK','2025-11-10 02:15:48','54.244.51.2','+13132468974','OAI','sip.api.openai.com','+19475176566','dsiptest.pstn.twilio.com',153,'','1','15'),
(385,'BYE','83513978_c3356d0b_3aeda2fe-99d7-4992-be4b-222408309946','aae04739-e1a4-4a12-945b-42aeaefce961','92c444c825065407774fcf2893009e16@0.0.0.0','200','OK','2025-11-10 02:15:52','54.172.60.3','+13132468974','OAI','sip.api.openai.com','+18889072085','dsiptest.pstn.twilio.com',154,'','1','15'),
(386,'INVITE','24699296_c3356d0b_846f8a69-df00-4614-b2a7-2e2173c26d41','eb84e8e1-8fcb-403d-bce0-73094707458a','48a92e20629596731bbbbcaf3a87b825@0.0.0.0','200','OK','2025-11-11 00:14:52','54.172.60.3','proj_LiCooyUxqKrHxGckhR34dpHR','proj_LiCooyUxqKrHxGckhR34dpHR','sip.api.openai.com','+19475176566','dsiptest.pstn.twilio.com',155,'inbound','1','15'),
(387,'BYE','24699296_c3356d0b_846f8a69-df00-4614-b2a7-2e2173c26d41','eb84e8e1-8fcb-403d-bce0-73094707458a','48a92e20629596731bbbbcaf3a87b825@0.0.0.0','481','','2025-11-11 00:16:36','54.172.60.3','+13132468974','OAI','sip.api.openai.com','+19475176566','dsiptest.pstn.twilio.com',155,'','1','15'),
(388,'INVITE','42358068_c3356d0b_4dfced61-4abf-41ec-8d1e-1432186db5e8','81b6316f-b9b4-42d8-8bdb-a3b90216e79a','84a1b32b5d6f45cd46f86870fdb09048@0.0.0.0','200','OK','2025-11-12 00:45:58','54.244.51.2','proj_LiCooyUxqKrHxGckhR34dpHR','proj_LiCooyUxqKrHxGckhR34dpHR','sip.api.openai.com','+19475176566','dsiptest.pstn.twilio.com',156,'inbound','1','15'),
(389,'BYE','42358068_c3356d0b_4dfced61-4abf-41ec-8d1e-1432186db5e8','81b6316f-b9b4-42d8-8bdb-a3b90216e79a','84a1b32b5d6f45cd46f86870fdb09048@0.0.0.0','200','OK','2025-11-12 00:46:04','54.244.51.2','+13132468974','OAI','sip.api.openai.com','+19475176566','dsiptest.pstn.twilio.com',156,'','1','15'),
(390,'INVITE','95972772_c3356d0b_872197f1-ee73-4ee4-ab33-ec5467971e13','867dd7ae-0a2b-485f-9345-18d93d42b3d1','cc6629fe6c029bafa7ce1ae4191af44e@0.0.0.0','200','OK','2025-11-12 00:54:24','54.244.51.2','proj_s6OMBJOrj60XHHiK8nRjHrBi','proj_s6OMBJOrj60XHHiK8nRjHrBi','sip.api.openai.com','+19475176566','dsiptest.pstn.twilio.com',157,'inbound','1','16'),
(391,'BYE','95972772_c3356d0b_872197f1-ee73-4ee4-ab33-ec5467971e13','867dd7ae-0a2b-485f-9345-18d93d42b3d1','cc6629fe6c029bafa7ce1ae4191af44e@0.0.0.0','200','OK','2025-11-12 00:54:37','54.244.51.2','+13136129074','OAI','sip.api.openai.com','+19475176566','dsiptest.pstn.twilio.com',157,'','1','16'),
(392,'INVITE','95714550_c3356d0b_62a8a806-343d-40bc-80f2-8d33df1237ca','cb9214e8-1b97-40a6-b4b6-9af2b2667bcd','546adc20257ef707b6428692493b43e2@0.0.0.0','200','OK','2025-11-12 00:58:19','54.244.51.1','proj_s6OMBJOrj60XHHiK8nRjHrBi','proj_s6OMBJOrj60XHHiK8nRjHrBi','sip.api.openai.com','+19475176566','dsiptest.pstn.twilio.com',158,'inbound','1','16'),
(393,'BYE','95714550_c3356d0b_62a8a806-343d-40bc-80f2-8d33df1237ca','cb9214e8-1b97-40a6-b4b6-9af2b2667bcd','546adc20257ef707b6428692493b43e2@0.0.0.0','200','OK','2025-11-12 00:58:39','54.244.51.1','+13136129074','OAI','sip.api.openai.com','+19475176566','dsiptest.pstn.twilio.com',158,'','1','16'),
(394,'INVITE','07753033_c3356d0b_4c2f99a3-9fb9-4e9a-9302-997a903cc353','4f43fdbd-e0e5-4d94-8f46-c9eccab1bb7d','7c8960c3084a02b9d3d797e7f8dc79f9@0.0.0.0','200','OK','2025-11-12 01:00:16','54.172.60.2','proj_s6OMBJOrj60XHHiK8nRjHrBi','proj_s6OMBJOrj60XHHiK8nRjHrBi','sip.api.openai.com','+18889072085','dsiptest.pstn.twilio.com',159,'inbound','1','16'),
(395,'BYE','07753033_c3356d0b_4c2f99a3-9fb9-4e9a-9302-997a903cc353','4f43fdbd-e0e5-4d94-8f46-c9eccab1bb7d','7c8960c3084a02b9d3d797e7f8dc79f9@0.0.0.0','200','OK','2025-11-12 01:00:59','54.172.60.2','+13136129074','OAI','sip.api.openai.com','+18889072085','dsiptest.pstn.twilio.com',159,'','1','16'),
(396,'INVITE','89111610_c3356d0b_0b9f22b9-8491-4254-9110-abc7d90be086','ce2a68fb-37e4-4b88-a1ce-bbb53397a038','a499769137c269b9986e9d594121aadc@0.0.0.0','200','OK','2025-11-12 01:05:53','54.244.51.1','proj_s6OMBJOrj60XHHiK8nRjHrBi','proj_s6OMBJOrj60XHHiK8nRjHrBi','sip.api.openai.com','+19475176566','dsiptest.pstn.twilio.com',160,'inbound','1','16'),
(397,'BYE','89111610_c3356d0b_0b9f22b9-8491-4254-9110-abc7d90be086','ce2a68fb-37e4-4b88-a1ce-bbb53397a038','a499769137c269b9986e9d594121aadc@0.0.0.0','200','OK','2025-11-12 01:06:12','54.244.51.1','+13136129074','OAI','sip.api.openai.com','+19475176566','dsiptest.pstn.twilio.com',160,'','1','16'),
(398,'INVITE','49980508_c3356d0b_321b5ff9-dd8e-4282-9c7f-9d54cae1390d','7d983873-d4e2-4cdc-9a8a-8dbe85f2e7fa','caa09920c1cbf9111f39b24bb4ea940d@0.0.0.0','200','OK','2025-11-12 09:32:11','54.172.60.0','proj_s6OMBJOrj60XHHiK8nRjHrBi','proj_s6OMBJOrj60XHHiK8nRjHrBi','sip.api.openai.com','+17348913376','dsiptest.pstn.twilio.com',161,'inbound','1','16'),
(399,'BYE','49980508_c3356d0b_321b5ff9-dd8e-4282-9c7f-9d54cae1390d','7d983873-d4e2-4cdc-9a8a-8dbe85f2e7fa','caa09920c1cbf9111f39b24bb4ea940d@0.0.0.0','200','OK','2025-11-12 09:33:46','54.172.60.0','+13136129074','OAI','sip.api.openai.com','+17348913376','dsiptest.pstn.twilio.com',161,'','1','16'),
(400,'INVITE','70422377_c3356d0b_316656c8-a361-492e-84f1-5d751ee05b5e','24144629-c04d-46f7-a61c-70fa929cf0ec','6ee43c11870fe677a2abba16e967e838@0.0.0.0','200','OK','2025-11-12 18:48:17','54.172.60.0','proj_LiCooyUxqKrHxGckhR34dpHR','proj_LiCooyUxqKrHxGckhR34dpHR','sip.api.openai.com','+19475176566','dsiptest.pstn.twilio.com',162,'inbound','1','15'),
(401,'BYE','70422377_c3356d0b_316656c8-a361-492e-84f1-5d751ee05b5e','24144629-c04d-46f7-a61c-70fa929cf0ec','6ee43c11870fe677a2abba16e967e838@0.0.0.0','200','OK','2025-11-12 18:48:22','54.172.60.0','+13132468974','OAI','sip.api.openai.com','+19475176566','dsiptest.pstn.twilio.com',162,'','1','15'),
(402,'INVITE','89775824_c3356d0b_4aac5e75-e466-465a-b818-4f070774c2b8','3cb1930e-24bf-491c-b261-b6a159c94bc9','cb948c4e708591d2b5852bb7cc06314e@0.0.0.0','200','OK','2025-11-12 18:48:28','54.244.51.2','proj_LiCooyUxqKrHxGckhR34dpHR','proj_LiCooyUxqKrHxGckhR34dpHR','sip.api.openai.com','+19475176566','dsiptest.pstn.twilio.com',163,'inbound','1','15'),
(403,'BYE','89775824_c3356d0b_4aac5e75-e466-465a-b818-4f070774c2b8','3cb1930e-24bf-491c-b261-b6a159c94bc9','cb948c4e708591d2b5852bb7cc06314e@0.0.0.0','481','','2025-11-12 18:50:14','54.244.51.2','+13132468974','OAI','sip.api.openai.com','+19475176566','dsiptest.pstn.twilio.com',163,'','1','15'),
(404,'INVITE','23895342_c3356d0b_20ed7cdc-41b5-4fbb-9d26-6363ceb1e3b6','48e7c530-7ed6-458e-99bd-6769fae4a729','533af9c5d227f11e85dc72c8798eaf90@0.0.0.0','200','OK','2025-11-18 17:57:52','54.172.60.1','proj_LiCooyUxqKrHxGckhR34dpHR','proj_LiCooyUxqKrHxGckhR34dpHR','sip.api.openai.com','+19412530229','dsiptest.pstn.twilio.com',164,'inbound','1','15'),
(405,'BYE','23895342_c3356d0b_20ed7cdc-41b5-4fbb-9d26-6363ceb1e3b6','48e7c530-7ed6-458e-99bd-6769fae4a729','533af9c5d227f11e85dc72c8798eaf90@0.0.0.0','200','OK','2025-11-18 17:59:37','54.172.60.1','+13132468974','OAI','sip.api.openai.com','+19412530229','dsiptest.pstn.twilio.com',164,'','1','15'),
(406,'INVITE','54884537_c3356d0b_bb5ae973-d585-4f35-993f-a588df91fc9c','8c7f9dbf-52c2-4c1f-bcf7-d95703ddf7b3','d9260cf9fa46bc70524ee72ba4d8ff8d@0.0.0.0','200','OK','2025-11-20 02:31:46','54.244.51.1','proj_LiCooyUxqKrHxGckhR34dpHR','proj_LiCooyUxqKrHxGckhR34dpHR','sip.api.openai.com','+19475176566','dsiptest.pstn.twilio.com',165,'inbound','1','15'),
(407,'BYE','54884537_c3356d0b_bb5ae973-d585-4f35-993f-a588df91fc9c','8c7f9dbf-52c2-4c1f-bcf7-d95703ddf7b3','d9260cf9fa46bc70524ee72ba4d8ff8d@0.0.0.0','200','OK','2025-11-20 02:33:25','54.244.51.1','+13132468974','OAI','sip.api.openai.com','+19475176566','dsiptest.pstn.twilio.com',165,'','1','15'),
(408,'INVITE','48650675_c3356d0b_85d70d37-accf-4113-ad2e-1010fea02cbf','c122302b-1b80-475f-8145-9f9fe7cb66e3','fbad0ecc6bca86ff74d11baa600cc019@0.0.0.0','200','OK','2025-11-21 17:30:54','54.172.60.0','proj_LiCooyUxqKrHxGckhR34dpHR','proj_LiCooyUxqKrHxGckhR34dpHR','sip.api.openai.com','+19475176566','dsiptest.pstn.twilio.com',166,'inbound','1','15'),
(409,'BYE','48650675_c3356d0b_85d70d37-accf-4113-ad2e-1010fea02cbf','c122302b-1b80-475f-8145-9f9fe7cb66e3','fbad0ecc6bca86ff74d11baa600cc019@0.0.0.0','200','OK','2025-11-21 17:32:49','54.172.60.0','+13132468974','OAI','sip.api.openai.com','+19475176566','dsiptest.pstn.twilio.com',166,'','1','15'),
(410,'INVITE','04310997_c3356d0b_61dc8585-d33c-4fd9-9f5f-387c566fba62','bc13bfd0-48da-40e5-803f-070b498632c7','c9b7bd479cec9b7566f7a92f57f76bb8@0.0.0.0','200','OK','2025-11-27 02:42:46','54.172.60.3','proj_LiCooyUxqKrHxGckhR34dpHR','proj_LiCooyUxqKrHxGckhR34dpHR','sip.api.openai.com','+19475176566','dsiptest.pstn.twilio.com',167,'inbound','1','15'),
(411,'BYE','04310997_c3356d0b_61dc8585-d33c-4fd9-9f5f-387c566fba62','bc13bfd0-48da-40e5-803f-070b498632c7','c9b7bd479cec9b7566f7a92f57f76bb8@0.0.0.0','200','OK','2025-11-27 02:42:50','54.172.60.3','+13132468974','OAI','sip.api.openai.com','+19475176566','dsiptest.pstn.twilio.com',167,'','1','15'),
(412,'INVITE','13639243_c3356d0b_e6fc4e29-4ab7-448d-9d91-1503bf986860','3f3a90f8-a47b-448f-a691-d23dca1e45ab','440a3bd3b23c421091af2cd423b744a1@0.0.0.0','200','OK','2025-12-02 05:10:56','54.244.51.1','proj_LiCooyUxqKrHxGckhR34dpHR','proj_LiCooyUxqKrHxGckhR34dpHR','sip.api.openai.com','+19475176566','dsiptest.pstn.twilio.com',168,'inbound','1','15'),
(413,'BYE','13639243_c3356d0b_e6fc4e29-4ab7-448d-9d91-1503bf986860','3f3a90f8-a47b-448f-a691-d23dca1e45ab','440a3bd3b23c421091af2cd423b744a1@0.0.0.0','200','OK','2025-12-02 05:11:00','54.244.51.1','+13132468974','OAI','sip.api.openai.com','+19475176566','dsiptest.pstn.twilio.com',168,'','1','15'),
(414,'INVITE','11350921_c3356d0b_a03ec9d6-2f84-4904-a97f-1b9194994c8c','4ffbd23f-e6d6-4a23-adff-a8141af683d1','722125ff9f5502b64a70c8b6fd06434f@0.0.0.0','200','OK','2025-12-10 02:59:34','54.172.60.0','proj_LiCooyUxqKrHxGckhR34dpHR','proj_LiCooyUxqKrHxGckhR34dpHR','sip.api.openai.com','+19475176566','dsiptest.pstn.twilio.com',169,'inbound','1','15'),
(415,'BYE','11350921_c3356d0b_a03ec9d6-2f84-4904-a97f-1b9194994c8c','4ffbd23f-e6d6-4a23-adff-a8141af683d1','722125ff9f5502b64a70c8b6fd06434f@0.0.0.0','200','OK','2025-12-10 02:59:42','54.172.60.0','+13132468974','OAI','sip.api.openai.com','+19475176566','dsiptest.pstn.twilio.com',169,'','1','15'),
(416,'INVITE','gK0c7f1ac5','5bcf9e65-5185-40d2-a9f3-6fd47c4efe71','457999576_53789002@207.223.78.224','200','OK','2025-12-10 04:02:23','34.226.36.33','proj_a02nz7CJlhnK8WtZ2tS2xr2I','proj_a02nz7CJlhnK8WtZ2tS2xr2I','sip.api.openai.com','+19475176566','fl.gg',170,'inbound','','17'),
(417,'BYE','gK0c7f1ac5','5bcf9e65-5185-40d2-a9f3-6fd47c4efe71','457999576_53789002@207.223.78.224','200','OK','2025-12-10 04:02:39','34.226.36.33','proj_a02nz7CJlhnK8WtZ2tS2xr2I','OAI','sip.api.openai.com','+19475176566','fl.gg',170,'','','17'),
(418,'INVITE','gK0033a9fb','ec56b582-e610-4677-aa8e-55a5103f5062','459321547_90105550@207.223.78.224','200','OK','2025-12-10 04:03:38','34.226.36.35','proj_a02nz7CJlhnK8WtZ2tS2xr2I','proj_a02nz7CJlhnK8WtZ2tS2xr2I','sip.api.openai.com','+19475176566','fl.gg',171,'inbound','','17'),
(419,'BYE','gK0033a9fb','ec56b582-e610-4677-aa8e-55a5103f5062','459321547_90105550@207.223.78.224','200','OK','2025-12-10 04:05:04','34.226.36.35','proj_a02nz7CJlhnK8WtZ2tS2xr2I','OAI','sip.api.openai.com','+19475176566','fl.gg',171,'','','17'),
(420,'INVITE','gK0c005e4b','ab47b548-e424-4ccf-976e-624887ae041f','457999842_134201280@207.223.78.224','200','OK','2025-12-10 04:05:14','34.226.36.34','proj_a02nz7CJlhnK8WtZ2tS2xr2I','proj_a02nz7CJlhnK8WtZ2tS2xr2I','sip.api.openai.com','+19475176566','fl.gg',172,'inbound','','17'),
(421,'BYE','gK0c005e4b','ab47b548-e424-4ccf-976e-624887ae041f','457999842_134201280@207.223.78.224','200','OK','2025-12-10 04:05:51','34.226.36.34','proj_a02nz7CJlhnK8WtZ2tS2xr2I','OAI','sip.api.openai.com','+19475176566','fl.gg',172,'','','17'),
(422,'INVITE','gK00519790','617d139c-0a0a-4fb6-b8c0-afe4f035919a','452985810_132635370@207.223.78.224','200','OK','2025-12-10 05:10:02','34.226.36.32','proj_a02nz7CJlhnK8WtZ2tS2xr2I','proj_a02nz7CJlhnK8WtZ2tS2xr2I','sip.api.openai.com','+19475176566','fl.gg',173,'inbound','3','17'),
(423,'BYE','gK00519790','617d139c-0a0a-4fb6-b8c0-afe4f035919a','452985810_132635370@207.223.78.224','200','OK','2025-12-10 05:10:14','34.226.36.32','proj_a02nz7CJlhnK8WtZ2tS2xr2I','OAI','sip.api.openai.com','+19475176566','fl.gg',173,'','3','17'),
(424,'INVITE','gK00088617','649cfdd8-0a6d-47a9-8798-3613591ee066','453030322_129447068@207.223.78.224','200','OK','2025-12-10 12:45:22','34.226.36.33','proj_a02nz7CJlhnK8WtZ2tS2xr2I','proj_a02nz7CJlhnK8WtZ2tS2xr2I','sip.api.openai.com','+19475176566','fl.gg',174,'inbound','','17'),
(425,'BYE','gK00088617','649cfdd8-0a6d-47a9-8798-3613591ee066','453030322_129447068@207.223.78.224','200','OK','2025-12-10 12:45:51','34.226.36.33','proj_a02nz7CJlhnK8WtZ2tS2xr2I','OAI','sip.api.openai.com','+19475176566','fl.gg',174,'','','17'),
(426,'INVITE','gK000957ce','e8826c2c-6a87-42a0-a56e-5e153b90e677','453030472_125685836@207.223.78.224','200','OK','2025-12-10 12:46:26','34.226.36.33','proj_a02nz7CJlhnK8WtZ2tS2xr2I','proj_a02nz7CJlhnK8WtZ2tS2xr2I','sip.api.openai.com','+19475176566','fl.gg',175,'inbound','','17'),
(427,'BYE','gK000957ce','e8826c2c-6a87-42a0-a56e-5e153b90e677','453030472_125685836@207.223.78.224','200','OK','2025-12-10 12:46:40','34.226.36.33','proj_a02nz7CJlhnK8WtZ2tS2xr2I','OAI','sip.api.openai.com','+19475176566','fl.gg',175,'','','17'),
(428,'INVITE','11021950_c3356d0b_27c519a8-2cce-4993-9aa3-efc819eb1631','605d48dc-bd6f-4fc7-ab93-3ec819ebdd1b','0b74e058e5c13ac06400675ecddf37ba@0.0.0.0','200','OK','2025-12-12 16:29:14','54.244.51.0','proj_LiCooyUxqKrHxGckhR34dpHR','proj_LiCooyUxqKrHxGckhR34dpHR','sip.api.openai.com','+19475176566','dsiptest.pstn.twilio.com',176,'inbound','1','15'),
(429,'BYE','11021950_c3356d0b_27c519a8-2cce-4993-9aa3-efc819eb1631','605d48dc-bd6f-4fc7-ab93-3ec819ebdd1b','0b74e058e5c13ac06400675ecddf37ba@0.0.0.0','200','OK','2025-12-12 16:29:17','54.244.51.0','+13132468974','OAI','sip.api.openai.com','+19475176566','dsiptest.pstn.twilio.com',176,'','1','15'),
(430,'INVITE','72610622_c3356d0b_3ec3bd26-5990-46a2-8312-0dd27b29f1fe','998aa569-25d4-445a-a294-6e2266688648','4b2c5092aca1d77eee29e6b6d73e8b13@0.0.0.0','200','OK','2026-01-07 19:20:54','54.244.51.0','proj_LiCooyUxqKrHxGckhR34dpHR','proj_LiCooyUxqKrHxGckhR34dpHR','sip.api.openai.com','+19475176566','dsiptest.pstn.twilio.com',177,'inbound','1','15'),
(431,'BYE','72610622_c3356d0b_3ec3bd26-5990-46a2-8312-0dd27b29f1fe','998aa569-25d4-445a-a294-6e2266688648','4b2c5092aca1d77eee29e6b6d73e8b13@0.0.0.0','200','OK','2026-01-07 19:20:59','54.244.51.0','+13132468974','OAI','sip.api.openai.com','+19475176566','dsiptest.pstn.twilio.com',177,'','1','15'),
(432,'INVITE','78703408_c3356d0b_a194cca8-c965-46c0-b39a-97a378793958','4b36b73c-c361-4425-b1b7-244183545c9d','6a4c62cf8ef3fc7f084b4b0c02666c3b@0.0.0.0','200','OK','2026-01-13 15:28:43','54.172.60.2','proj_LiCooyUxqKrHxGckhR34dpHR','proj_LiCooyUxqKrHxGckhR34dpHR','sip.api.openai.com','+19475176566','dsiptest.pstn.twilio.com',178,'inbound','1','15'),
(433,'BYE','78703408_c3356d0b_a194cca8-c965-46c0-b39a-97a378793958','4b36b73c-c361-4425-b1b7-244183545c9d','6a4c62cf8ef3fc7f084b4b0c02666c3b@0.0.0.0','200','OK','2026-01-13 15:28:45','54.172.60.2','+13132468974','OAI','sip.api.openai.com','+19475176566','dsiptest.pstn.twilio.com',178,'','1','15'),
(434,'INVITE','84362109_c3356d0b_1f919267-2179-4db6-8f8a-248802222a85','58305774-35a8-4215-ba1b-1ededeb2314e','445393e0c36d1eebde62d61e8625dfc8@0.0.0.0','200','OK','2026-01-13 16:24:05','54.244.51.0','proj_LiCooyUxqKrHxGckhR34dpHR','proj_LiCooyUxqKrHxGckhR34dpHR','sip.api.openai.com','+19475176566','dsiptest.pstn.twilio.com',179,'inbound','1','15'),
(435,'BYE','84362109_c3356d0b_1f919267-2179-4db6-8f8a-248802222a85','58305774-35a8-4215-ba1b-1ededeb2314e','445393e0c36d1eebde62d61e8625dfc8@0.0.0.0','200','OK','2026-01-13 16:25:26','54.244.51.0','+13132468974','OAI','sip.api.openai.com','+19475176566','dsiptest.pstn.twilio.com',179,'','1','15'),
(436,'INVITE','25326200_c3356d0b_7d1e8907-6326-4286-bc88-22d9ff8b5223','4deaf16f-469e-41d9-9d94-8d4060cc5631','52c2441ceb0dfc635ad17960debf9357@0.0.0.0','200','OK','2026-01-16 22:46:46','54.244.51.2','proj_s6OMBJOrj60XHHiK8nRjHrBi','proj_s6OMBJOrj60XHHiK8nRjHrBi','sip.api.openai.com','+13135901598','dsiptest.pstn.twilio.com',180,'inbound','1','16'),
(437,'BYE','25326200_c3356d0b_7d1e8907-6326-4286-bc88-22d9ff8b5223','4deaf16f-469e-41d9-9d94-8d4060cc5631','52c2441ceb0dfc635ad17960debf9357@0.0.0.0','200','OK','2026-01-16 22:46:55','54.244.51.2','+13136129074','OAI','sip.api.openai.com','+13135901598','dsiptest.pstn.twilio.com',180,'','1','16'),
(438,'INVITE','53876459_c3356d0b_c3caa04a-1bae-4d8d-b8b3-0c438871bfde','ffe2394a-56ec-4d8d-9165-6c55dd5f6023','2a59f99221a90d2d8e9693c1c8720188@0.0.0.0','200','OK','2026-01-16 22:48:25','54.172.60.2','proj_s6OMBJOrj60XHHiK8nRjHrBi','proj_s6OMBJOrj60XHHiK8nRjHrBi','sip.api.openai.com','+13135901598','dsiptest.pstn.twilio.com',181,'inbound','1','16'),
(439,'BYE','53876459_c3356d0b_c3caa04a-1bae-4d8d-b8b3-0c438871bfde','ffe2394a-56ec-4d8d-9165-6c55dd5f6023','2a59f99221a90d2d8e9693c1c8720188@0.0.0.0','200','OK','2026-01-16 22:50:22','54.172.60.2','+13136129074','OAI','sip.api.openai.com','+13135901598','dsiptest.pstn.twilio.com',181,'','1','16'),
(440,'INVITE','32068939_c3356d0b_aa9e876f-f821-44e2-8b5d-cf36dc98568b','e619d3c4-1ea3-4d6d-b304-8f2460f94b71','7900600cd1da744f4efad35fa610bfbc@0.0.0.0','200','OK','2026-01-17 02:42:02','54.172.60.3','proj_LiCooyUxqKrHxGckhR34dpHR','proj_LiCooyUxqKrHxGckhR34dpHR','sip.api.openai.com','+19475176566','dsiptest.pstn.twilio.com',182,'inbound','1','15'),
(441,'BYE','32068939_c3356d0b_aa9e876f-f821-44e2-8b5d-cf36dc98568b','e619d3c4-1ea3-4d6d-b304-8f2460f94b71','7900600cd1da744f4efad35fa610bfbc@0.0.0.0','200','OK','2026-01-17 02:42:11','54.172.60.3','+13132468974','OAI','sip.api.openai.com','+19475176566','dsiptest.pstn.twilio.com',182,'','1','15'),
(442,'INVITE','83376219_c3356d0b_9381b1d5-ebd0-4416-8350-2c9cd38ce860','9d79e6a5-b863-4154-905a-c98b7c90c284','45760eca8ce85481748951abce8a1fd5@0.0.0.0','200','OK','2026-01-21 14:43:27','54.172.60.2','proj_LiCooyUxqKrHxGckhR34dpHR','proj_LiCooyUxqKrHxGckhR34dpHR','sip.api.openai.com','+19797666651','dsiptest.pstn.twilio.com',183,'inbound','1','15'),
(443,'BYE','83376219_c3356d0b_9381b1d5-ebd0-4416-8350-2c9cd38ce860','9d79e6a5-b863-4154-905a-c98b7c90c284','45760eca8ce85481748951abce8a1fd5@0.0.0.0','200','OK','2026-01-21 14:44:08','54.172.60.2','+13132468974','OAI','sip.api.openai.com','+19797666651','dsiptest.pstn.twilio.com',183,'','1','15'),
(444,'INVITE','65344115_c3356d0b_a2684ffe-aba7-4802-9176-d33f5e097111','ae7817a9-1021-4d1f-ac3b-16f3377f30cd','6956023f71eb457911f6a0e3b08f773a@0.0.0.0','200','OK','2026-01-22 18:29:05','54.244.51.0','proj_LiCooyUxqKrHxGckhR34dpHR','proj_LiCooyUxqKrHxGckhR34dpHR','sip.api.openai.com','+19475176566','dsiptest.pstn.twilio.com',184,'inbound','1','15'),
(445,'BYE','65344115_c3356d0b_a2684ffe-aba7-4802-9176-d33f5e097111','ae7817a9-1021-4d1f-ac3b-16f3377f30cd','6956023f71eb457911f6a0e3b08f773a@0.0.0.0','200','OK','2026-01-22 18:29:39','54.244.51.0','+13132468974','OAI','sip.api.openai.com','+19475176566','dsiptest.pstn.twilio.com',184,'','1','15'),
(446,'INVITE','25654410_c3356d0b_51aefae0-967c-46c4-b87d-b73fc5c8f530','74d688a9-3def-4dcc-bfd4-773fdb76ab95','704a29a2c2d824b1784087704371543b@0.0.0.0','200','OK','2026-01-22 18:32:30','54.244.51.2','proj_LiCooyUxqKrHxGckhR34dpHR','proj_LiCooyUxqKrHxGckhR34dpHR','sip.api.openai.com','+19475176566','dsiptest.pstn.twilio.com',185,'inbound','1','15'),
(447,'BYE','25654410_c3356d0b_51aefae0-967c-46c4-b87d-b73fc5c8f530','74d688a9-3def-4dcc-bfd4-773fdb76ab95','704a29a2c2d824b1784087704371543b@0.0.0.0','200','OK','2026-01-22 18:32:39','54.244.51.2','+13132468974','OAI','sip.api.openai.com','+19475176566','dsiptest.pstn.twilio.com',185,'','1','15'),
(448,'INVITE','42888476_c3356d0b_af908d0d-ea79-47ae-8516-57c3a1ae5cc6','650fea33-f2d4-4ca9-8efa-e1909677d566','a444fe9e5f6ab17aee2568854205326e@0.0.0.0','200','OK','2026-01-22 18:36:40','54.172.60.2','proj_LiCooyUxqKrHxGckhR34dpHR','proj_LiCooyUxqKrHxGckhR34dpHR','sip.api.openai.com','+19475176566','dsiptest.pstn.twilio.com',186,'inbound','1','15'),
(449,'BYE','42888476_c3356d0b_af908d0d-ea79-47ae-8516-57c3a1ae5cc6','650fea33-f2d4-4ca9-8efa-e1909677d566','a444fe9e5f6ab17aee2568854205326e@0.0.0.0','200','OK','2026-01-22 18:37:05','54.172.60.2','+13132468974','OAI','sip.api.openai.com','+19475176566','dsiptest.pstn.twilio.com',186,'','1','15'),
(450,'INVITE','gK047fc6b4','590169a1-3856-4cae-be8b-545e6b4fed00','237253123_83859365@207.223.78.224','200','OK','2026-01-22 19:11:28','34.226.36.33','proj_J7f6NK1rtMoZ0SXI9bbgLpOG','proj_J7f6NK1rtMoZ0SXI9bbgLpOG','sip.api.openai.com','+19475176566','fl.gg',187,'inbound','','25'),
(451,'BYE','gK047fc6b4','590169a1-3856-4cae-be8b-545e6b4fed00','237253123_83859365@207.223.78.224','200','OK','2026-01-22 19:11:33','34.226.36.33','proj_J7f6NK1rtMoZ0SXI9bbgLpOG','OAI','sip.api.openai.com','+19475176566','fl.gg',187,'','','25'),
(452,'INVITE','gK0c303025','66a36a61-9ccd-45b1-a1d9-ff820bc3fb3c','235705921_127836135@207.223.78.224','200','OK','2026-01-22 19:11:37','34.226.36.34','proj_J7f6NK1rtMoZ0SXI9bbgLpOG','proj_J7f6NK1rtMoZ0SXI9bbgLpOG','sip.api.openai.com','+19475176566','fl.gg',188,'inbound','','25'),
(453,'BYE','gK0c303025','66a36a61-9ccd-45b1-a1d9-ff820bc3fb3c','235705921_127836135@207.223.78.224','200','OK','2026-01-22 19:12:15','34.226.36.34','proj_J7f6NK1rtMoZ0SXI9bbgLpOG','OAI','sip.api.openai.com','+19475176566','fl.gg',188,'','','25'),
(454,'INVITE','gK001d22c9','ebf31b54-c146-4422-88b9-581bb0c9d831','237025578_104813816@207.223.78.224','200','OK','2026-01-22 19:14:16','34.226.36.35','proj_J7f6NK1rtMoZ0SXI9bbgLpOG','proj_J7f6NK1rtMoZ0SXI9bbgLpOG','sip.api.openai.com','+13133840357','fl.gg',189,'inbound','','25'),
(455,'BYE','gK001d22c9','ebf31b54-c146-4422-88b9-581bb0c9d831','237025578_104813816@207.223.78.224','200','OK','2026-01-22 19:16:13','34.226.36.35','proj_J7f6NK1rtMoZ0SXI9bbgLpOG','OAI','sip.api.openai.com','+13133840357','fl.gg',189,'','','25'),
(456,'INVITE','gK0c36e07f','ec8337d1-2651-4cd4-b2a4-ae1526b711c4','191632567_128855163@207.223.78.115','200','OK','2026-01-22 19:16:21','34.226.36.32','proj_J7f6NK1rtMoZ0SXI9bbgLpOG','proj_J7f6NK1rtMoZ0SXI9bbgLpOG','sip.api.openai.com','+13133840357','fl.gg',190,'inbound','3','25'),
(457,'BYE','gK0c36e07f','ec8337d1-2651-4cd4-b2a4-ae1526b711c4','191632567_128855163@207.223.78.115','200','OK','2026-01-22 19:16:42','34.226.36.32','proj_J7f6NK1rtMoZ0SXI9bbgLpOG','OAI','sip.api.openai.com','+13133840357','fl.gg',190,'','3','25'),
(458,'INVITE','gK007e087b','ca5e25d8-b373-4cf4-bd0e-e7ce0e80583b','239114900_29343149@207.223.78.224','200','OK','2026-01-22 19:22:41','34.226.36.32','proj_J7f6NK1rtMoZ0SXI9bbgLpOG','proj_J7f6NK1rtMoZ0SXI9bbgLpOG','sip.api.openai.com','+19475176566','fl.gg',191,'inbound','3','25'),
(459,'BYE','gK007e087b','ca5e25d8-b373-4cf4-bd0e-e7ce0e80583b','239114900_29343149@207.223.78.224','200','OK','2026-01-22 19:22:48','34.226.36.32','proj_J7f6NK1rtMoZ0SXI9bbgLpOG','OAI','sip.api.openai.com','+19475176566','fl.gg',191,'','3','25'),
(460,'INVITE','gK040135dc','00ca1ee7-819b-4e33-980a-53509f318546','239351173_124618039@207.223.78.224','200','OK','2026-01-22 19:22:52','34.226.36.35','proj_J7f6NK1rtMoZ0SXI9bbgLpOG','proj_J7f6NK1rtMoZ0SXI9bbgLpOG','sip.api.openai.com','+19475176566','fl.gg',192,'inbound','','25'),
(461,'BYE','gK040135dc','00ca1ee7-819b-4e33-980a-53509f318546','239351173_124618039@207.223.78.224','200','OK','2026-01-22 19:23:08','34.226.36.35','proj_J7f6NK1rtMoZ0SXI9bbgLpOG','OAI','sip.api.openai.com','+19475176566','fl.gg',192,'','','25'),
(462,'INVITE','gK0c36bc96','ea281ccf-f9e1-4640-bbab-af0e2eb16f60','237805407_132898538@207.223.78.224','200','OK','2026-01-22 19:23:29','34.226.36.33','proj_J7f6NK1rtMoZ0SXI9bbgLpOG','proj_J7f6NK1rtMoZ0SXI9bbgLpOG','sip.api.openai.com','+19475176566','fl.gg',193,'inbound','','25'),
(463,'BYE','gK0c36bc96','ea281ccf-f9e1-4640-bbab-af0e2eb16f60','237805407_132898538@207.223.78.224','200','OK','2026-01-22 19:23:48','34.226.36.33','proj_J7f6NK1rtMoZ0SXI9bbgLpOG','OAI','sip.api.openai.com','+19475176566','fl.gg',193,'','','25'),
(464,'INVITE','gK000e0910','532d2bb2-f99f-42e3-ae84-5d3d1119e77e','239119087_124247948@207.223.78.224','200','OK','2026-01-22 19:24:03','34.226.36.35','proj_J7f6NK1rtMoZ0SXI9bbgLpOG','proj_J7f6NK1rtMoZ0SXI9bbgLpOG','sip.api.openai.com','+13133840357','fl.gg',194,'inbound','','25'),
(465,'BYE','gK000e0910','532d2bb2-f99f-42e3-ae84-5d3d1119e77e','239119087_124247948@207.223.78.224','200','OK','2026-01-22 19:25:48','34.226.36.35','proj_J7f6NK1rtMoZ0SXI9bbgLpOG','OAI','sip.api.openai.com','+13133840357','fl.gg',194,'','','25'),
(466,'INVITE','gK0808c680','14d167f0-2545-4316-a0b1-7bc90c42cf76','241736279_100474893@207.223.78.224','200','OK','2026-01-22 19:32:54','34.226.36.33','proj_J7f6NK1rtMoZ0SXI9bbgLpOG','proj_J7f6NK1rtMoZ0SXI9bbgLpOG','sip.api.openai.com','+19475176566','fl.gg',195,'inbound','','25'),
(467,'BYE','gK0808c680','14d167f0-2545-4316-a0b1-7bc90c42cf76','241736279_100474893@207.223.78.224','200','OK','2026-01-22 19:33:39','34.226.36.33','proj_J7f6NK1rtMoZ0SXI9bbgLpOG','OAI','sip.api.openai.com','+19475176566','fl.gg',195,'','','25'),
(468,'INVITE','62623895_c3356d0b_5f33b687-a113-4043-a4fa-259b21bf4d60','2924a404-22f5-4561-b7e2-cdf7a0ffadae','b7a556658d650063672760c53e9a9b67@0.0.0.0','200','OK','2026-01-28 04:28:27','54.244.51.1','proj_LiCooyUxqKrHxGckhR34dpHR','proj_LiCooyUxqKrHxGckhR34dpHR','sip.api.openai.com','+19475176566','dsiptest.pstn.twilio.com',196,'inbound','1','15'),
(469,'BYE','62623895_c3356d0b_5f33b687-a113-4043-a4fa-259b21bf4d60','2924a404-22f5-4561-b7e2-cdf7a0ffadae','b7a556658d650063672760c53e9a9b67@0.0.0.0','200','OK','2026-01-28 04:28:31','54.244.51.1','+13132468974','OAI','sip.api.openai.com','+19475176566','dsiptest.pstn.twilio.com',196,'','1','15'),
(470,'INVITE','35991848_c3356d0b_88937ca4-ec24-4a7b-841c-962769fe2679','61af183c-71c6-4cff-b424-ccf1e88f760d','74fe895174087edffa2d0e427e7f4c48@0.0.0.0','200','OK','2026-02-03 15:10:25','54.244.51.2','proj_s6OMBJOrj60XHHiK8nRjHrBi','proj_s6OMBJOrj60XHHiK8nRjHrBi','sip.api.openai.com','+13135292414','dsiptest.pstn.twilio.com',197,'inbound','1','16'),
(471,'BYE','35991848_c3356d0b_88937ca4-ec24-4a7b-841c-962769fe2679','61af183c-71c6-4cff-b424-ccf1e88f760d','74fe895174087edffa2d0e427e7f4c48@0.0.0.0','200','OK','2026-02-03 15:10:32','54.244.51.2','+13136129074','OAI','sip.api.openai.com','+13135292414','dsiptest.pstn.twilio.com',197,'','1','16'),
(472,'INVITE','14798220_c3356d0b_1a8e5a75-31f9-410f-9f59-f6ae1a4a2642','355f7261-8d00-4511-a4b0-927f69aaec27','8a75b2fe9ee4fa30d0cb9465545adbd8@0.0.0.0','200','OK','2026-02-10 20:29:34','54.172.60.0','proj_s6OMBJOrj60XHHiK8nRjHrBi','proj_s6OMBJOrj60XHHiK8nRjHrBi','sip.api.openai.com','+13135766337','dsiptest.pstn.twilio.com',198,'inbound','1','16'),
(473,'BYE','14798220_c3356d0b_1a8e5a75-31f9-410f-9f59-f6ae1a4a2642','355f7261-8d00-4511-a4b0-927f69aaec27','8a75b2fe9ee4fa30d0cb9465545adbd8@0.0.0.0','200','OK','2026-02-10 20:30:04','54.172.60.0','+13136129074','OAI','sip.api.openai.com','+13135766337','dsiptest.pstn.twilio.com',198,'','1','16'),
(474,'INVITE','e1b19d64','bf8638324618dc61059d4c604476fea1.7fd73a0d','BgOgrrL3XAN6P1tLhc_rpA..','403','Invalid Caller ID','2026-02-13 03:49:30','50.192.97.226','16723617*19475176566','16723617*19475176566','34.226.36.32','6702','34.210.91.112',0,'outbound','32','3'),
(475,'INVITE','94654c7a','bf8638324618dc61059d4c604476fea1.32342988','cSXV4T2_Hpcq5AFIF7t4PQ..','403','Invalid Caller ID','2026-02-13 03:49:55','50.192.97.226','16723617*19475176566','16723617*19475176566','34.226.36.32','6702','34.210.91.112',0,'outbound','32','3'),
(476,'INVITE','a7682d71','bf8638324618dc61059d4c604476fea1.2db37086','B5yy2kc1KfAfYO1ISi-4dA..','403','Invalid Caller ID','2026-02-13 03:50:23','50.192.97.226','16723617*19475176566','16723617*19475176566','34.226.36.32','6702','34.210.91.112',0,'outbound','32','3'),
(477,'INVITE','f655b148','bf8638324618dc61059d4c604476fea1.361d1d11','XIyVjgS3m4-81DChVWwXkg..','403','Invalid Caller ID','2026-02-13 03:52:06','50.192.97.226','16723617*19474222222','16723617*19474222222','34.226.36.32','6702','34.210.91.112',0,'outbound','32','3'),
(478,'INVITE','c295ca2f','bf8638324618dc61059d4c604476fea1.7248c3f8','mI_5kTHkcxyJTeL-X7VrUA..','403','Invalid Caller ID','2026-02-13 03:52:30','50.192.97.226','16723617*19474222222','16723617*19474222222','34.226.36.32','6702','34.210.91.112',0,'outbound','32','3'),
(479,'INVITE','3c8a6500','bf8638324618dc61059d4c604476fea1.db5b8349','88NcTSjikuDJvfKbTiMqTw..','403','Invalid Caller ID','2026-02-13 03:52:51','50.192.97.226','16723617*19474222222','16723617*19474222222','34.226.36.32','6702','34.210.91.112',0,'outbound','32','3'),
(480,'INVITE','7af3f15a','bf8638324618dc61059d4c604476fea1.029c9561','fysZldCd7qHnLflykeGbSA..','403','Invalid Caller ID','2026-02-13 03:53:07','50.192.97.226','16723617*19474222222','16723617*19474222222','34.226.36.32','6702','34.210.91.112',0,'outbound','32','3'),
(481,'INVITE','46004185_c3356d0b_9840959b-5f3b-4689-b65c-99a5fd3ae3ca','d0ec18e0-165e-4989-80ec-dc8f37194636','bae8ea25989f9bac8bf905c26630c58c@0.0.0.0','200','OK','2026-02-24 05:30:37','54.244.51.2','proj_LiCooyUxqKrHxGckhR34dpHR','proj_LiCooyUxqKrHxGckhR34dpHR','sip.api.openai.com','+19475176566','dsiptest.pstn.twilio.com',199,'inbound','1','15'),
(482,'BYE','46004185_c3356d0b_9840959b-5f3b-4689-b65c-99a5fd3ae3ca','d0ec18e0-165e-4989-80ec-dc8f37194636','bae8ea25989f9bac8bf905c26630c58c@0.0.0.0','200','OK','2026-02-24 05:30:43','54.244.51.2','+13132468974','OAI','sip.api.openai.com','+19475176566','dsiptest.pstn.twilio.com',199,'','1','15'),
(483,'INVITE','ea81ba16','bf8638324618dc61059d4c604476fea1.90bb358b','TjrTa4M20bigGP0JXoP9fQ..','403','Invalid Caller ID','2026-02-24 05:47:16','50.192.97.226','16723617*19485224242','16723617*19485224242','34.226.36.32','6702','34.210.91.112',0,'outbound','32','3'),
(484,'INVITE','a85eef24','bf8638324618dc61059d4c604476fea1.e322c5dc','q8T-ao-_vGLD2_zV_HjzMQ..','403','Invalid Caller ID','2026-02-24 05:47:33','50.192.97.226','16723617*19485224242','16723617*19485224242','34.226.36.32','6702','34.210.91.112',0,'outbound','32','3'),
(485,'INVITE','f3ad5261','bf8638324618dc61059d4c604476fea1.36d67762','B7tv7eUPWwwF7tH-h1qvNw..','403','Invalid Caller ID','2026-02-24 05:51:22','50.192.97.226','16723617*19485224242','16723617*19485224242','34.226.36.32','6702','34.210.91.112',0,'outbound','32','3'),
(486,'INVITE','5159ac5a','bf8638324618dc61059d4c604476fea1.98396dca','mk_kAhIp94mm_5OBV2emZQ..','403','Invalid Caller ID','2026-02-24 06:18:13','50.192.97.226','16723617*19485224242','16723617*19485224242','34.226.36.32','6702','34.210.91.112',0,'outbound','32','3'),
(487,'INVITE','827dc43a','bf8638324618dc61059d4c604476fea1.5f768351','LIB-4bk8abo7ccOgO0iyzA..','403','Invalid Caller ID','2026-02-24 06:18:40','50.192.97.226','16723617*19485224242','16723617*19485224242','34.226.36.32','6702','34.210.91.112',0,'outbound','32','3'),
(488,'INVITE','b2c0c129','bf8638324618dc61059d4c604476fea1.9b1374db','v1CltdJ4SXIKFUN7MWPfvA..','403','Invalid Caller ID','2026-02-24 06:24:43','50.192.97.226','16723617*19485224242','16723617*19485224242','34.226.36.32','6702','34.210.91.112',0,'outbound','32','3'),
(489,'INVITE','c1cb0570','bf8638324618dc61059d4c604476fea1.916e910e','SwQo37F1Yo-tRrdSrZ_xtA..','403','Invalid Caller ID','2026-02-24 06:25:07','50.192.97.226','16723617*19485224242','16723617*19485224242','34.226.36.32','6702','34.210.91.112',0,'outbound','32','3'),
(490,'INVITE','8d678157','bf8638324618dc61059d4c604476fea1.bd8f8187','Nn1dU8GNdpPoQ5QMIexgnQ..','403','Invalid Caller ID','2026-03-01 03:04:19','50.192.97.226','16723617*19475176566','16723617*19475176566','34.226.36.32','6702','34.210.91.112',0,'outbound','32','3'),
(491,'INVITE','e5734745','bf8638324618dc61059d4c604476fea1.cf075d30','HB3S33JhKgpeCHcUxxhEOg..','403','Invalid Caller ID','2026-03-01 03:18:11','50.192.97.226','16723617*19475176566','16723617*19475176566','34.226.36.32','6702','34.210.91.112',0,'outbound','13','3'),
(492,'INVITE','93d04f75','594d50c3218065a60bb91fd47a70fbc1-eff976a4','yT1RKpFv9HFE5QjOHrwRng..','403','Insufficient funds remaining - support@flowroute.com','2026-03-01 03:19:41','50.192.97.226','16723617*19475176566','16723617*19475176566','34.226.36.32','2485442883','34.210.91.112',0,'outbound','32','3'),
(493,'INVITE','ceb3bd49','gK04bcd30a','r1Uz0vSn7PqFoJE-w13q_w..','200','OK','2026-03-01 03:24:53','50.192.97.226','16723617*19475176566','16723617*19475176566','34.210.91.112','2485442883','34.210.91.112',200,'outbound','32','3'),
(494,'BYE','gK04bcd30a','ceb3bd49','r1Uz0vSn7PqFoJE-w13q_w..','200','OK','2026-03-01 03:28:44','34.210.91.112','2485442883','2485442883','146.190.253.188','19475176566','34.210.91.112',0,'','32','3'),
(495,'INVITE','8bc34047','bf8638324618dc61059d4c604476fea1.aa6222ac','e90PTXYdhvZaMggG6sdggw..','403','International Calling Disabled - support@flowroute.com','2026-03-01 03:30:07','50.192.97.226','16723617*9475176566','16723617*9475176566','34.226.36.32','2485442883','34.210.91.112',0,'outbound','32','3'),
(496,'INVITE','c63e972a','gK08de2f84','U2LVdSOPP0RldRiIyE7hRQ..','200','OK','2026-03-01 03:30:42','50.192.97.226','16723617*19475176566','16723617*19475176566','34.210.91.112','2485442883','34.210.91.112',201,'outbound','32','3'),
(497,'BYE','gK08de2f84','c63e972a','U2LVdSOPP0RldRiIyE7hRQ..','200','OK','2026-03-01 03:31:06','34.210.91.112','2485442883','2485442883','146.190.253.188','19475176566','34.210.91.112',0,'','32','3'),
(498,'INVITE','a6e56451','gK00be4442','A0zMVhRPX9nHucFOdO8vOQ..','200','OK','2026-03-01 03:32:20','50.192.97.226','16723617*19475176566','16723617*19475176566','34.210.91.112','2485442883','34.210.91.112',202,'outbound','32','3'),
(499,'BYE','a6e56451','gK00be4442','A0zMVhRPX9nHucFOdO8vOQ..','481','Call/Transaction Does Not Exist','2026-03-01 03:32:48','50.192.97.226','19475176566','19475176566','146.190.253.188','2485442883','34.210.91.112',202,'','32','3'),
(500,'INVITE','4fdf2907','bf8638324618dc61059d4c604476fea1.4720120e','c6qK595SkIl9dBDC2YAf7g..','403','International Calling Disabled - support@flowroute.com','2026-03-01 03:32:58','50.192.97.226','16723617*9475176566','16723617*9475176566','34.226.36.32','2485442883','34.210.91.112',0,'outbound','32','3'),
(501,'BYE','gK00be4442','a6e56451','A0zMVhRPX9nHucFOdO8vOQ..','481','Call/Transaction Does Not Exist','2026-03-01 03:33:36','34.210.91.112','+12485442883','2485442883','146.190.253.188','+19475176566','fl.gg',0,'','',''),
(502,'INVITE','ccf4455b','gK00b7a9c5','rt1HicbxqQnIOkeXoYtrHQ..','200','OK','2026-03-01 03:33:39','50.192.97.226','16723617*19475176566','16723617*19475176566','34.210.91.112','2485442883','34.210.91.112',203,'outbound','32','3'),
(503,'BYE','ccf4455b','gK00b7a9c5','rt1HicbxqQnIOkeXoYtrHQ..','481','Call/Transaction Does Not Exist','2026-03-01 03:33:49','50.192.97.226','19475176566','19475176566','146.190.253.188','2485442883','34.210.91.112',203,'','32','3'),
(504,'BYE','gK00b7a9c5','ccf4455b','rt1HicbxqQnIOkeXoYtrHQ..','481','Call/Transaction Does Not Exist','2026-03-01 03:35:46','34.210.91.112','+12485442883','2485442883','146.190.253.188','+19475176566','fl.gg',0,'','',''),
(505,'INVITE','4b1e0a63','gK08e40453','R3UjY_S89D6qEriCtBkEHA..','200','OK','2026-03-01 03:42:16','50.192.97.226','16723617*19475176566','16723617*19475176566','34.210.91.112','2485442883','34.210.91.112',204,'outbound','32','3'),
(506,'BYE','gK08e40453','4b1e0a63','R3UjY_S89D6qEriCtBkEHA..','200','OK','2026-03-01 03:42:43','34.210.91.112','2485442883','2485442883','146.190.253.188','19475176566','34.210.91.112',0,'','32','3'),
(507,'INVITE','6d13f650','gK08b38714','_alf-FWZi169ezM97MwJEw..','200','OK','2026-03-01 03:50:45','50.192.97.226','16723617*19475176566','16723617*19475176566','34.210.91.112','2485442883','34.210.91.112',205,'outbound','32','3'),
(508,'BYE','gK08b38714','6d13f650','_alf-FWZi169ezM97MwJEw..','200','OK','2026-03-01 03:52:01','34.210.91.112','2485442883','2485442883','146.190.253.188','19475176566','34.210.91.112',0,'','32','3'),
(509,'INVITE','3affac49','594d50c3218065a60bb91fd47a70fbc1-60585ddb','F0d1qbnVAfzczRc3jMRV_w..','403','Insufficient funds remaining - support@flowroute.com','2026-03-01 13:33:16','50.192.97.226','16723617*19475176566','16723617*19475176566','34.226.36.32','2485442883','34.210.91.112',0,'outbound','32','3'),
(510,'INVITE','3f549827','594d50c3218065a60bb91fd47a70fbc1-64d941e3','fplzgFYbylmjoZYM8IK1zA..','403','Insufficient funds remaining - support@flowroute.com','2026-03-01 13:33:35','50.192.97.226','16723617*19475176566','16723617*19475176566','34.226.36.32','2485442883','34.210.91.112',0,'outbound','32','3'),
(511,'INVITE','216e8f31','594d50c3218065a60bb91fd47a70fbc1-da9e924c','gkTPuh_fFky2A9ZPzEg18A..','403','Insufficient funds remaining - support@flowroute.com','2026-03-01 13:33:49','50.192.97.226','16723617*19475176566','16723617*19475176566','34.226.36.32','2485442883','34.210.91.112',0,'outbound','32','3'),
(512,'INVITE','07567a3d','gK049fbfa4','-lgmBdhZ8YL6hzEgIUJ2DQ..','200','OK','2026-03-01 13:49:15','50.192.97.226','16723617*19475176566','16723617*19475176566','34.210.91.112','2485442883','34.210.91.112',206,'outbound','32','3'),
(513,'BYE','gK049fbfa4','07567a3d','-lgmBdhZ8YL6hzEgIUJ2DQ..','200','OK','2026-03-01 13:49:45','34.210.91.112','2485442883','2485442883','146.190.253.188','19475176566','34.210.91.112',0,'','32','3'),
(514,'INVITE','5a6c1233','gK0cd1d6a5','ScYmOAgyXm_93bYLNTTXwg..','200','OK','2026-03-01 13:58:40','50.192.97.226','16723617*19475176566','16723617*19475176566','34.210.91.112','2485442883','34.210.91.112',207,'outbound','32','3'),
(515,'BYE','gK0cd1d6a5','5a6c1233','ScYmOAgyXm_93bYLNTTXwg..','200','OK','2026-03-01 14:01:14','34.210.91.112','2485442883','2485442883','146.190.253.188','19475176566','34.210.91.112',0,'','32','3'),
(516,'INVITE','7a589663','gK04cfe849','Ea8L7V9SLSO-jwAvG-B9hA..','200','OK','2026-03-01 14:43:32','50.192.97.226','16723617*19475176566','16723617*19475176566','34.210.91.112','2485442883','34.210.91.112',208,'outbound','32','3'),
(517,'BYE','gK04cfe849','7a589663','Ea8L7V9SLSO-jwAvG-B9hA..','200','OK','2026-03-01 14:55:07','34.210.91.112','2485442883','2485442883','146.190.253.188','19475176566','34.210.91.112',0,'','32','3'),
(518,'INVITE','9dd23706','gK0cb43896','KIiBNJ2i2LChdYFxdzEtlw..','200','OK','2026-03-02 19:03:51','50.192.97.226','16723617*19475176566','16723617*19475176566','34.210.91.112','2485442883','34.210.91.112',209,'outbound','32','3'),
(519,'BYE','gK0cb43896','9dd23706','KIiBNJ2i2LChdYFxdzEtlw..','200','OK','2026-03-02 19:03:57','34.210.91.112','2485442883','2485442883','146.190.253.188','19475176566','34.210.91.112',0,'','32','3'),
(520,'INVITE','gK042a189f','29cd5038-f7fd-4e00-9bf0-25005ce8d13a','172268154_66034116@207.223.78.224','200','OK','2026-03-06 02:04:48','34.226.36.33','proj_a02nz7CJlhnK8WtZ2tS2xr2I','proj_a02nz7CJlhnK8WtZ2tS2xr2I','sip.api.openai.com','+19475176566','fl.gg',210,'inbound','','17'),
(521,'BYE','gK042a189f','29cd5038-f7fd-4e00-9bf0-25005ce8d13a','172268154_66034116@207.223.78.224','200','OK','2026-03-06 02:05:09','34.226.36.33','proj_a02nz7CJlhnK8WtZ2tS2xr2I','OAI','sip.api.openai.com','+19475176566','fl.gg',210,'','','17'),
(522,'INVITE','gK042ab4e2','c9a89aac-ecb3-46cd-ad56-857607a26870','172268299_16559243@207.223.78.224','200','OK','2026-03-06 02:05:13','34.226.36.34','proj_a02nz7CJlhnK8WtZ2tS2xr2I','proj_a02nz7CJlhnK8WtZ2tS2xr2I','sip.api.openai.com','+19475176566','fl.gg',211,'inbound','','17'),
(523,'BYE','gK042ab4e2','c9a89aac-ecb3-46cd-ad56-857607a26870','172268299_16559243@207.223.78.224','200','OK','2026-03-06 02:05:45','34.226.36.34','proj_a02nz7CJlhnK8WtZ2tS2xr2I','OAI','sip.api.openai.com','+19475176566','fl.gg',211,'','','17'),
(524,'INVITE','gK081d2ad3','f8c03d35-158b-4d2e-9da6-b83e68d8905e','172494230_134069982@207.223.78.224','200','OK','2026-03-06 02:09:00','34.226.36.32','proj_a02nz7CJlhnK8WtZ2tS2xr2I','proj_a02nz7CJlhnK8WtZ2tS2xr2I','sip.api.openai.com','+19475176566','fl.gg',212,'inbound','3','17'),
(525,'BYE','gK081d2ad3','f8c03d35-158b-4d2e-9da6-b83e68d8905e','172494230_134069982@207.223.78.224','200','OK','2026-03-06 02:09:06','34.226.36.32','proj_a02nz7CJlhnK8WtZ2tS2xr2I','OAI','sip.api.openai.com','+19475176566','fl.gg',212,'','3','17'),
(526,'INVITE','7618523c','gK089291bb','D3CXEw0vdnb9PZVap-Q8fg..','200','OK','2026-03-10 05:13:46','50.192.97.226','16723617*19475176566','16723617*19475176566','34.210.91.112','2485442883','34.210.91.112',213,'outbound','32','3'),
(527,'BYE','gK089291bb','7618523c','D3CXEw0vdnb9PZVap-Q8fg..','200','OK','2026-03-10 05:13:51','34.210.91.112','2485442883','2485442883','146.190.253.188','19475176566','34.210.91.112',0,'','32','3'),
(528,'INVITE','2d87536c','gK04f7bbe2','ouuDR7AgxhoKCUNstqWQyA..','200','OK','2026-03-10 07:18:31','50.192.97.226','16723617*19475176566','16723617*19475176566','34.210.91.112','2485442883','34.210.91.112',214,'outbound','32','3'),
(529,'BYE','gK04f7bbe2','2d87536c','ouuDR7AgxhoKCUNstqWQyA..','200','OK','2026-03-10 07:18:38','34.210.91.112','2485442883','2485442883','146.190.253.188','19475176566','34.210.91.112',0,'','32','3'),
(530,'INVITE','85b1684f','gK00a67f12','yxfkNUYHP-EL0mmQlBQY-w..','200','OK','2026-03-10 07:19:04','50.192.97.226','16723617*19475176566','16723617*19475176566','34.210.91.112','2485442883','34.210.91.112',215,'outbound','32','3'),
(531,'BYE','gK00a67f12','85b1684f','yxfkNUYHP-EL0mmQlBQY-w..','200','OK','2026-03-10 07:19:06','34.210.91.112','2485442883','2485442883','146.190.253.188','19475176566','34.210.91.112',0,'','32','3'),
(532,'INVITE','00d3e21c','gK04f8d719','S6DxbcI9k9g-VQ4_eKIRNQ..','200','OK','2026-03-10 07:21:35','50.192.97.226','16723617*19475176566','16723617*19475176566','34.210.91.112','2485442883','34.210.91.112',216,'outbound','32','3'),
(533,'BYE','gK04f8d719','00d3e21c','S6DxbcI9k9g-VQ4_eKIRNQ..','200','OK','2026-03-10 07:21:52','34.210.91.112','2485442883','2485442883','146.190.253.188','19475176566','34.210.91.112',0,'','32','3'),
(534,'INVITE','d9528b4f','gK0cf5f13d','lQP9XfmoFVf0xvQwOJHCCw..','200','OK','2026-03-10 15:09:30','50.192.97.226','16723617*19475176566','16723617*19475176566','34.210.91.112','2485442883','34.210.91.112',217,'outbound','32','3'),
(535,'BYE','d9528b4f','gK0cf5f13d','lQP9XfmoFVf0xvQwOJHCCw..','481','Call/Transaction Does Not Exist','2026-03-10 15:09:48','50.192.97.226','19475176566','19475176566','146.190.253.188','2485442883','34.210.91.112',217,'','32','3'),
(536,'INVITE','gK08411b79','681fc0fa-8bb2-4819-8ed3-fad3774c1a9e','4765556_134200404@207.223.78.224','200','OK','2026-03-10 15:24:19','34.226.36.32','proj_a02nz7CJlhnK8WtZ2tS2xr2I','proj_a02nz7CJlhnK8WtZ2tS2xr2I','sip.api.openai.com','+18889072085','fl.gg',218,'inbound','3','17'),
(537,'BYE','gK08411b79','681fc0fa-8bb2-4819-8ed3-fad3774c1a9e','4765556_134200404@207.223.78.224','200','OK','2026-03-10 15:24:38','34.226.36.32','proj_a02nz7CJlhnK8WtZ2tS2xr2I','OAI','sip.api.openai.com','+18889072085','fl.gg',218,'','3','17'),
(538,'BYE','gK0cf5f13d','d9528b4f','lQP9XfmoFVf0xvQwOJHCCw..','481','Call/Transaction Does Not Exist','2026-03-10 15:42:42','34.210.91.112','+12485442883','2485442883','146.190.253.188','+19475176566','fl.gg',0,'','',''),
(539,'INVITE','a9bf4d51','gK00c084c1','oduihk_D4PB_81xIc17nww..','200','OK','2026-03-10 17:59:04','50.192.97.226','16723617*19475176566','16723617*19475176566','34.210.91.112','2485442883','34.210.91.112',219,'outbound','32','3'),
(540,'BYE','gK00c084c1','a9bf4d51','oduihk_D4PB_81xIc17nww..','200','OK','2026-03-10 17:59:27','34.210.91.112','2485442883','2485442883','146.190.253.188','19475176566','34.210.91.112',0,'','32','3'),
(541,'INVITE','83589752','gK04f3c395','k07WV2pJEmV4nWR_DEBHoQ..','200','OK','2026-03-11 02:16:04','50.192.97.226','16723617*19475176566','16723617*19475176566','34.210.91.112','2485442883','34.210.91.112',220,'outbound','32','3'),
(542,'BYE','gK04f3c395','83589752','k07WV2pJEmV4nWR_DEBHoQ..','200','OK','2026-03-11 02:16:21','34.210.91.112','2485442883','2485442883','146.190.253.188','19475176566','34.210.91.112',0,'','32','3'),
(543,'INVITE','2b3fca12','gK08d820ce','UoGgthPn7FKd6Bc17u-4GA..','200','OK','2026-03-11 21:45:25','50.192.97.226','16723617*19475176566','16723617*19475176566','34.210.91.112','2485442883','34.210.91.112',221,'outbound','32','3'),
(544,'BYE','gK08d820ce','2b3fca12','UoGgthPn7FKd6Bc17u-4GA..','200','OK','2026-03-11 21:45:32','34.210.91.112','2485442883','2485442883','146.190.253.188','19475176566','34.210.91.112',0,'','32','3'),
(545,'INVITE','1fbf3e2a','gK08c0449f','h0AYoIQ-K_QCM31Gm3HYFA..','200','OK','2026-03-12 02:02:24','50.192.97.226','16723617*19475176566','16723617*19475176566','34.210.91.112','2485442883','34.210.91.112',222,'outbound','32','3'),
(546,'BYE','gK08c0449f','1fbf3e2a','h0AYoIQ-K_QCM31Gm3HYFA..','200','OK','2026-03-12 02:02:51','34.210.91.112','2485442883','2485442883','146.190.253.188','19475176566','34.210.91.112',0,'','32','3'),
(547,'INVITE','94b7d21f','gK00e13998','p6nu_YZV7qsrSmJgQYwbQQ..','487','Request Terminated','2026-03-12 03:05:35','50.192.97.226','16723617*19475176566','16723617*19475176566','34.210.91.112','2485442883','34.210.91.112',0,'outbound','32','3'),
(548,'INVITE','b0c3e911','gK0ca59ac5','otCej5zN1puJypB_RTQsfQ..','200','OK','2026-03-12 03:09:08','50.192.97.226','16723617*19475176566','16723617*19475176566','34.210.91.112','2485442883','34.210.91.112',223,'outbound','32','3'),
(549,'BYE','gK0ca59ac5','b0c3e911','otCej5zN1puJypB_RTQsfQ..','200','OK','2026-03-12 03:09:20','34.210.91.112','2485442883','2485442883','146.190.253.188','19475176566','34.210.91.112',0,'','32','3'),
(550,'INVITE','gK0c77e702','830e5556-77cc-4d36-825a-d4fe6f19943d','202149423_99049598@207.223.78.224','200','OK','2026-03-12 16:19:45','34.226.36.35','proj_a02nz7CJlhnK8WtZ2tS2xr2I','proj_a02nz7CJlhnK8WtZ2tS2xr2I','sip.api.openai.com','+19475176566','fl.gg',224,'inbound','','17'),
(551,'BYE','gK0c77e702','830e5556-77cc-4d36-825a-d4fe6f19943d','202149423_99049598@207.223.78.224','200','OK','2026-03-12 16:20:02','34.226.36.35','proj_a02nz7CJlhnK8WtZ2tS2xr2I','OAI','sip.api.openai.com','+19475176566','fl.gg',224,'','','17'),
(552,'INVITE','gK0c52e0eb','582d766f-473e-4333-a1e8-d1ed3870be05','204250774_100646228@207.223.78.224','200','OK','2026-03-12 19:26:16','34.226.36.33','proj_a02nz7CJlhnK8WtZ2tS2xr2I','proj_a02nz7CJlhnK8WtZ2tS2xr2I','sip.api.openai.com','+19475176566','fl.gg',225,'inbound','','17'),
(553,'BYE','gK0c52e0eb','582d766f-473e-4333-a1e8-d1ed3870be05','204250774_100646228@207.223.78.224','200','OK','2026-03-12 19:26:26','34.226.36.33','proj_a02nz7CJlhnK8WtZ2tS2xr2I','OAI','sip.api.openai.com','+19475176566','fl.gg',225,'','','17');
/*!40000 ALTER TABLE `acc` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `acc_cdrs`
--

DROP TABLE IF EXISTS `acc_cdrs`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8mb4 */;
CREATE TABLE `acc_cdrs` (
  `id` int(10) unsigned NOT NULL AUTO_INCREMENT,
  `start_time` datetime NOT NULL DEFAULT '2000-01-01 00:00:00',
  `end_time` datetime NOT NULL DEFAULT '2000-01-01 00:00:00',
  `duration` float(10,3) NOT NULL DEFAULT 0.000,
  PRIMARY KEY (`id`),
  KEY `start_time_idx` (`start_time`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb3 COLLATE=utf8mb3_general_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `acc_cdrs`
--

LOCK TABLES `acc_cdrs` WRITE;
/*!40000 ALTER TABLE `acc_cdrs` DISABLE KEYS */;
/*!40000 ALTER TABLE `acc_cdrs` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `active_watchers`
--

DROP TABLE IF EXISTS `active_watchers`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8mb4 */;
CREATE TABLE `active_watchers` (
  `id` int(10) unsigned NOT NULL AUTO_INCREMENT,
  `presentity_uri` varchar(255) NOT NULL,
  `watcher_username` varchar(64) NOT NULL,
  `watcher_domain` varchar(64) NOT NULL,
  `to_user` varchar(64) NOT NULL,
  `to_domain` varchar(64) NOT NULL,
  `event` varchar(64) NOT NULL DEFAULT 'presence',
  `event_id` varchar(64) DEFAULT NULL,
  `to_tag` varchar(128) NOT NULL,
  `from_tag` varchar(128) NOT NULL,
  `callid` varchar(255) NOT NULL,
  `local_cseq` int(11) NOT NULL,
  `remote_cseq` int(11) NOT NULL,
  `contact` varchar(255) NOT NULL,
  `record_route` text DEFAULT NULL,
  `expires` int(11) NOT NULL,
  `status` int(11) NOT NULL DEFAULT 2,
  `reason` varchar(64) DEFAULT NULL,
  `version` int(11) NOT NULL DEFAULT 0,
  `socket_info` varchar(64) NOT NULL,
  `local_contact` varchar(255) NOT NULL,
  `from_user` varchar(64) NOT NULL,
  `from_domain` varchar(64) NOT NULL,
  `updated` int(11) NOT NULL,
  `updated_winfo` int(11) NOT NULL,
  `flags` int(11) NOT NULL DEFAULT 0,
  `user_agent` varchar(255) DEFAULT '',
  PRIMARY KEY (`id`),
  UNIQUE KEY `active_watchers_idx` (`callid`,`to_tag`,`from_tag`),
  KEY `active_watchers_expires` (`expires`),
  KEY `active_watchers_pres` (`presentity_uri`,`event`),
  KEY `updated_idx` (`updated`),
  KEY `updated_winfo_idx` (`updated_winfo`,`presentity_uri`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb3 COLLATE=utf8mb3_general_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `active_watchers`
--

LOCK TABLES `active_watchers` WRITE;
/*!40000 ALTER TABLE `active_watchers` DISABLE KEYS */;
/*!40000 ALTER TABLE `active_watchers` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `address`
--

DROP TABLE IF EXISTS `address`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8mb4 */;
CREATE TABLE `address` (
  `id` int(10) unsigned NOT NULL AUTO_INCREMENT,
  `grp` int(11) unsigned NOT NULL DEFAULT 1,
  `ip_addr` varchar(253) NOT NULL,
  `mask` int(11) NOT NULL DEFAULT 32,
  `port` smallint(5) unsigned NOT NULL DEFAULT 0,
  `tag` varchar(255) NOT NULL DEFAULT '',
  PRIMARY KEY (`id`)
) ENGINE=InnoDB AUTO_INCREMENT=97 DEFAULT CHARSET=utf8mb3 COLLATE=utf8mb3_general_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `address`
--

LOCK TABLES `address` WRITE;
/*!40000 ALTER TABLE `address` DISABLE KEYS */;
INSERT INTO `address` VALUES
(1,17,'52.114.132.46',32,0,'name:msteams-sbc,gwgroup:0'),
(2,17,'52.114.14.70',32,0,'name:msteams-sbc,gwgroup:0'),
(3,17,'52.114.148.0',32,0,'name:msteams-sbc,gwgroup:0'),
(4,17,'52.114.16.74',32,0,'name:msteams-sbc,gwgroup:0'),
(5,17,'52.114.20.29',32,0,'name:msteams-sbc,gwgroup:0'),
(6,17,'52.114.7.24',32,0,'name:msteams-sbc,gwgroup:0'),
(7,17,'52.114.75.24',32,0,'name:msteams-sbc,gwgroup:0'),
(8,17,'52.114.76.76',32,0,'name:msteams-sbc,gwgroup:0'),
(9,17,'52.127.64.33',32,0,'name:msteams-sbc,gwgroup:0'),
(10,17,'52.127.64.34',32,0,'name:msteams-sbc,gwgroup:0'),
(11,17,'52.127.88.59',32,0,'name:msteams-sbc,gwgroup:0'),
(12,17,'52.127.92.64',32,0,'name:msteams-sbc,gwgroup:0'),
(13,17,'sip.pstnhub.microsoft.com',32,0,'name:msteams-sbc,gwgroup:0'),
(14,17,'sip2.pstnhub.microsoft.com',32,0,'name:msteams-sbc,gwgroup:0'),
(15,17,'sip3.pstnhub.microsoft.com',32,0,'name:msteams-sbc,gwgroup:0'),
(16,17,'sip.pstnhub.dod.teams.microsoft.us',32,0,'name:msteams-sbc,gwgroup:0'),
(17,17,'sip.pstnhub.gov.teams.microsoft.us',32,0,'name:msteams-sbc,gwgroup:0'),
(18,8,'54.172.60.0',32,0,'name:Twilio NA Inbound Carrier,gwgroup:1'),
(19,8,'54.172.60.1',32,0,'name:Twilio NA Inbound Carrier,gwgroup:1'),
(20,8,'54.172.60.2',32,0,'name:Twilio NA Inbound Carrier,gwgroup:1'),
(21,8,'54.172.60.3',32,0,'name:Twilio NA Inbound Carrier,gwgroup:1'),
(22,8,'54.244.51.0',32,0,'name:Twilio NA Inbound Carrier,gwgroup:1'),
(23,8,'54.244.51.1',32,0,'name:Twilio NA Inbound Carrier,gwgroup:1'),
(24,8,'54.244.51.2',32,0,'name:Twilio NA Inbound,gwgroup:1'),
(25,8,'54.244.51.3',32,0,'name:Twilio NA Inbound Carrier,gwgroup:1'),
(26,8,'54.244.60.0',23,0,'name:Twilio NA Inbound Carrier,gwgroup:1'),
(27,8,'34.203.250.0',23,0,'name:Twilio NA Inbound Carrier,gwgroup:1'),
(28,8,'54.244.51.0',24,0,'name:Twilio NA Inbound Carrier,gwgroup:1'),
(29,8,'52.41.52.34',32,0,'name:Skyetel North West Inbound,gwgroup:2'),
(30,8,'52.8.201.128',32,0,'name:Skyetel South West Inbound,gwgroup:2'),
(31,8,'52.60.138.31',32,0,'name:Skyetel North East Inbound,gwgroup:2'),
(32,8,'50.17.48.216',32,0,'name:Skyetel South East Inbound,gwgroup:2'),
(33,8,'35.156.192.164',32,0,'name:Skyetel Europe Inbound,gwgroup:2'),
(34,8,'term.skyetel.com',32,0,'name:Skyetel 1st Priority Outbound Call,gwgroup:2'),
(35,8,'52.41.52.34',32,0,'name:Skyetel 2nd Priority Outbound Call,gwgroup:2'),
(36,8,'52.8.201.128',32,0,'name:Skyetel 3rd Priority Outbound Call,gwgroup:2'),
(37,8,'50.17.48.216',32,0,'name:Skyetel 4rd Priority Outbound Call,gwgroup:2'),
(38,8,'52.32.223.28',32,0,'name:Skyetel North West High Cost Outbound Traffic,gwgroup:2'),
(39,8,'52.4.178.107',32,0,'name:Skyetel South East High Cost Outbound Traffic,gwgroup:2'),
(41,8,'34.210.91.112',28,0,'name:Flowroute US-West-OR,gwgroup:3'),
(43,8,'34.226.36.32',28,0,'name:Flowroute US-East-VA,gwgroup:3'),
(44,8,'81.201.82.45',32,0,'name:Voxbone Belgium,gwgroup:4'),
(45,8,'81.201.84.195',32,0,'name:Voxbone LA,gwgroup:4'),
(46,8,'81.201.85.45',32,0,'name:Voxbone NYC,gwgroup:4'),
(47,8,'81.201.83.45',32,0,'name:Voxbone Germany,gwgroup:4'),
(48,8,'81.201.86.45',32,0,'name:Voxbone Hong Kong,gwgroup:4'),
(49,8,'81.201.84.195',32,0,'name:Voxbone Australia,gwgroup:4'),
(50,8,'64.136.174.30',32,0,'name:VoIP Innovations Inbound Carrier,gwgroup:5'),
(51,8,'64.136.173.22',32,0,'name:VoIP Innovations Inbound Carrier,gwgroup:5'),
(52,8,'209.166.128.200',32,0,'name:VoIP Innovations Inbound Carrier,gwgroup:5'),
(53,8,'192.240.151.100',32,0,'name:VoIP Innovations Inbound Carrier,gwgroup:5'),
(54,8,'64.136.173.31',32,0,'name:VoIP Innovations Inbound Carrier,gwgroup:5'),
(55,8,'64.136.174.30',32,0,'name:VoIP Innovations Inbound Carrier,gwgroup:5'),
(56,8,'64.136.174.20',32,0,'name:VoIP Innovations Inbound Carrier,gwgroup:5'),
(57,8,'209.166.154.70',32,0,'name:VoIP Innovations Inbound Carrier,gwgroup:5'),
(58,8,'64.136.174.65',32,0,'name:VoIP Innovations Inbound Carrier,gwgroup:5'),
(59,8,'64.136.173.23',32,0,'name:VoIP Innovations Inbound Carrier,gwgroup:5'),
(60,8,'209.166.128.201',32,0,'name:VoIP Innovations Inbound Carrier,gwgroup:5'),
(61,8,'192.240.151.101',32,0,'name:VoIP Innovations Inbound Carrier,gwgroup:5'),
(62,8,'64.136.173.65',32,0,'name:VoIP Innovations Inbound Carrier,gwgroup:5'),
(63,8,'64.136.174.65',32,0,'name:VoIP Innovations Inbound Carrier,gwgroup:5'),
(64,8,'64.136.174.21',32,0,'name:VoIP Innovations Inbound Carrier,gwgroup:5'),
(65,8,'209.166.154.71',32,0,'name:VoIP Innovations Inbound Carrier,gwgroup:5'),
(66,8,'64.136.174.30',32,0,'name:VoIP Innovations Outbound Conversational Carrier,gwgroup:6'),
(67,8,'64.136.173.22',32,0,'name:VoIP Innovations Outbound Conversational Carrier,gwgroup:6'),
(68,8,'209.166.128.200',32,0,'name:VoIP Innovations Outbound Conversational Carrier,gwgroup:6'),
(69,8,'192.240.151.100',32,0,'name:VoIP Innovations Outbound Conversational Carrier,gwgroup:6'),
(70,8,'72.15.219.140',32,0,'name:Thinq Carrier,gwgroup:7'),
(71,8,'216.147.191.157',32,0,'name:Voxtelesys Carrier,gwgroup:8'),
(72,8,'64.34.181.47',32,0,'name:Les.net Carrier,gwgroup:9'),
(73,8,'206.80.250.100',32,0,'name:ThinkTel,gwgroup:10'),
(74,8,'208.68.17.52',32,0,'name:ThinkTel,gwgroup:10'),
(75,8,'209.197.130.80',32,0,'name:ThinkTel,gwgroup:10'),
(76,9,'143.198.43.186',32,0,'name:,gwgroup:11'),
(77,8,'sip.api.openai.com',32,0,'name:OpenAI,gwgroup:12'),
(78,9,'50.192.97.226',32,0,'name:,gwgroup:13'),
(79,9,'172.65.182.150',32,0,'name:,gwgroup:14'),
(80,9,'172.65.182.150',32,0,'name:,gwgroup:15'),
(81,9,'172.65.182.150',32,0,'name:,gwgroup:16'),
(82,9,'172.65.182.150',32,0,'name:,gwgroup:17'),
(83,9,'192.168.1.100',32,0,'name:FreePBX2,gwgroup:18'),
(84,9,'50.192.97.226',32,0,'name:HOA,gwgroup:19'),
(85,9,'192.168.42.1',32,0,'name:New Customer 546,gwgroup:20'),
(86,9,'188.42.24.2',32,0,'name:Mack\'s Endpoint,gwgroup:23'),
(87,9,'204.24.24.22',32,0,'name:Acme Company,gwgroup:24'),
(88,9,'172.65.182.150',32,0,'name:,gwgroup:25'),
(89,8,'dopensourcedev-5b971b49c6b2.sip.signalwire.com',32,0,'name:SignalWire-uac,gwgroup:33'),
(90,8,'dopensourcedev-5b971b49c6b2.sip.signalwire.com',32,0,'name:Test UAC Failure-uac,gwgroup:34'),
(91,8,'199.14.31.13',32,0,'name:Gen1,gwgroup:35'),
(95,9,'138.197.146.10',32,0,'name:,gwgroup:37'),
(96,9,'104.248.104.160',32,0,'name:,gwgroup:37');
/*!40000 ALTER TABLE `address` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `aliases`
--

DROP TABLE IF EXISTS `aliases`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8mb4 */;
CREATE TABLE `aliases` (
  `id` int(10) unsigned NOT NULL AUTO_INCREMENT,
  `ruid` varchar(64) NOT NULL DEFAULT '',
  `username` varchar(64) NOT NULL DEFAULT '',
  `domain` varchar(64) DEFAULT NULL,
  `contact` varchar(255) NOT NULL DEFAULT '',
  `received` varchar(255) DEFAULT NULL,
  `path` varchar(512) DEFAULT NULL,
  `expires` datetime NOT NULL DEFAULT '2030-05-28 21:32:15',
  `q` float(10,2) NOT NULL DEFAULT 1.00,
  `callid` varchar(255) NOT NULL DEFAULT 'Default-Call-ID',
  `cseq` int(11) NOT NULL DEFAULT 1,
  `last_modified` datetime NOT NULL DEFAULT '2000-01-01 00:00:01',
  `flags` int(11) NOT NULL DEFAULT 0,
  `cflags` int(11) NOT NULL DEFAULT 0,
  `user_agent` varchar(255) NOT NULL DEFAULT '',
  `socket` varchar(64) DEFAULT NULL,
  `methods` int(11) DEFAULT NULL,
  `instance` varchar(255) DEFAULT NULL,
  `reg_id` int(11) NOT NULL DEFAULT 0,
  `server_id` int(11) NOT NULL DEFAULT 0,
  `connection_id` int(11) NOT NULL DEFAULT 0,
  `keepalive` int(11) NOT NULL DEFAULT 0,
  `partition` int(11) NOT NULL DEFAULT 0,
  PRIMARY KEY (`id`),
  UNIQUE KEY `ruid_idx` (`ruid`),
  KEY `account_contact_idx` (`username`,`domain`,`contact`),
  KEY `expires_idx` (`expires`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb3 COLLATE=utf8mb3_general_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `aliases`
--

LOCK TABLES `aliases` WRITE;
/*!40000 ALTER TABLE `aliases` DISABLE KEYS */;
/*!40000 ALTER TABLE `aliases` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `carrier_name`
--

DROP TABLE IF EXISTS `carrier_name`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8mb4 */;
CREATE TABLE `carrier_name` (
  `id` int(10) unsigned NOT NULL AUTO_INCREMENT,
  `carrier` varchar(64) DEFAULT NULL,
  PRIMARY KEY (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb3 COLLATE=utf8mb3_general_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `carrier_name`
--

LOCK TABLES `carrier_name` WRITE;
/*!40000 ALTER TABLE `carrier_name` DISABLE KEYS */;
/*!40000 ALTER TABLE `carrier_name` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `carrierfailureroute`
--

DROP TABLE IF EXISTS `carrierfailureroute`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8mb4 */;
CREATE TABLE `carrierfailureroute` (
  `id` int(10) unsigned NOT NULL AUTO_INCREMENT,
  `carrier` int(10) unsigned NOT NULL DEFAULT 0,
  `domain` int(10) unsigned NOT NULL DEFAULT 0,
  `scan_prefix` varchar(64) NOT NULL DEFAULT '',
  `host_name` varchar(255) NOT NULL DEFAULT '',
  `reply_code` varchar(3) NOT NULL DEFAULT '',
  `flags` int(11) unsigned NOT NULL DEFAULT 0,
  `mask` int(11) unsigned NOT NULL DEFAULT 0,
  `next_domain` int(10) unsigned NOT NULL DEFAULT 0,
  `description` varchar(255) DEFAULT NULL,
  PRIMARY KEY (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb3 COLLATE=utf8mb3_general_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `carrierfailureroute`
--

LOCK TABLES `carrierfailureroute` WRITE;
/*!40000 ALTER TABLE `carrierfailureroute` DISABLE KEYS */;
/*!40000 ALTER TABLE `carrierfailureroute` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `carrierroute`
--

DROP TABLE IF EXISTS `carrierroute`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8mb4 */;
CREATE TABLE `carrierroute` (
  `id` int(10) unsigned NOT NULL AUTO_INCREMENT,
  `carrier` int(10) unsigned NOT NULL DEFAULT 0,
  `domain` int(10) unsigned NOT NULL DEFAULT 0,
  `scan_prefix` varchar(64) NOT NULL DEFAULT '',
  `flags` int(11) unsigned NOT NULL DEFAULT 0,
  `mask` int(11) unsigned NOT NULL DEFAULT 0,
  `prob` float NOT NULL DEFAULT 0,
  `strip` int(11) unsigned NOT NULL DEFAULT 0,
  `rewrite_host` varchar(255) NOT NULL DEFAULT '',
  `rewrite_prefix` varchar(64) NOT NULL DEFAULT '',
  `rewrite_suffix` varchar(64) NOT NULL DEFAULT '',
  `description` varchar(255) DEFAULT NULL,
  PRIMARY KEY (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb3 COLLATE=utf8mb3_general_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `carrierroute`
--

LOCK TABLES `carrierroute` WRITE;
/*!40000 ALTER TABLE `carrierroute` DISABLE KEYS */;
/*!40000 ALTER TABLE `carrierroute` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `cdrs`
--

DROP TABLE IF EXISTS `cdrs`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8mb4 */;
CREATE TABLE `cdrs` (
  `cdr_id` bigint(20) unsigned NOT NULL AUTO_INCREMENT,
  `src_username` varchar(128) NOT NULL DEFAULT '',
  `src_domain` varchar(255) NOT NULL DEFAULT '',
  `dst_username` varchar(128) NOT NULL DEFAULT '',
  `dst_domain` varchar(255) NOT NULL DEFAULT '',
  `dst_ousername` varchar(128) NOT NULL DEFAULT '',
  `call_start_time` datetime NOT NULL,
  `duration` int(10) unsigned NOT NULL DEFAULT 0,
  `sip_call_id` varchar(255) NOT NULL DEFAULT '',
  `sip_from_tag` varchar(128) NOT NULL DEFAULT '',
  `sip_to_tag` varchar(128) NOT NULL DEFAULT '',
  `src_ip` varchar(64) NOT NULL DEFAULT '',
  `cost` int(11) NOT NULL DEFAULT 0,
  `rated` int(11) NOT NULL DEFAULT 0,
  `created` datetime NOT NULL DEFAULT current_timestamp(),
  `calltype` varchar(20) DEFAULT NULL,
  `fraud` tinyint(1) NOT NULL DEFAULT 0,
  `src_gwgroupid` varchar(10) NOT NULL DEFAULT '',
  `dst_gwgroupid` varchar(10) NOT NULL DEFAULT '',
  PRIMARY KEY (`cdr_id`)
) ENGINE=InnoDB AUTO_INCREMENT=226 DEFAULT CHARSET=utf8mb3 COLLATE=utf8mb3_general_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `cdrs`
--

LOCK TABLES `cdrs` WRITE;
/*!40000 ALTER TABLE `cdrs` DISABLE KEYS */;
INSERT INTO `cdrs` VALUES
(1,'2000','143.198.44.195','2001','50.192.97.226','','2025-07-18 00:39:39',0,'12e9af0b-af86-4f06-8705-58709aec288c','ab77c887-56a8-4ea4-9a64-da6192b1e50f','3ab2852c','143.198.44.195',0,0,'2025-07-18 00:43:50','',0,'0','0'),
(2,'2000','test.dsiprouter.net','2001','test.dsiprouter.net','','2025-07-18 00:39:39',0,'6gctvjqjpheg83133pb7','1ocgoffjjv','bf7493ee-a140-4bb0-a3e8-635d0e904dd4','50.192.97.226',0,0,'2025-07-18 00:43:50','',0,'56','1'),
(3,'2000','143.198.44.195','2001','50.192.97.226','','2025-07-18 00:40:36',1,'23d3b164-ff5f-44cc-ab44-e9e977d8dd9c','73677323-a132-4b9c-a7b1-bb538735c89f','d201f37c','143.198.44.195',0,0,'2025-07-18 00:43:50','',0,'0','0'),
(4,'2000','test.dsiprouter.net','2001','test.dsiprouter.net','','2025-07-18 00:40:36',1,'6gctv6sbgs8obj4la82e','5kapev0npa','d85a8fe3-c637-4355-967c-c78403cb34da','50.192.97.226',0,0,'2025-07-18 00:43:50','',0,'0','0'),
(5,'2000','143.198.44.195','2001','50.192.97.226','','2025-07-18 00:48:05',0,'f8a4c0df-85bf-486b-86c3-05413cbf1f17','0fbd9601-c77b-459b-89ef-0adb9a01d918','a175324b','143.198.44.195',0,0,'2025-07-18 00:48:50','',0,'0','0'),
(6,'2000','test.dsiprouter.net','2001','test.dsiprouter.net','','2025-07-18 00:48:05',0,'6gctv0g4u3k4oeidq3hu','t1fpqeaujq','ef1ecac6-ace4-4510-a039-7f9f572ad8aa','50.192.97.226',0,0,'2025-07-18 00:48:50','',0,'0','0'),
(7,'2000','143.198.44.195','2001','50.192.97.226','','2025-07-18 00:57:42',15,'f40698c8-749c-4325-b618-df6422882716','7b4c7bd9-0605-4836-b688-a64cbb5cc3e5','52783c55','143.198.44.195',0,0,'2025-07-18 01:02:15','',0,'0','0'),
(8,'2000','test.dsiprouter.net','2001','test.dsiprouter.net','','2025-07-18 00:57:42',15,'6gctvc79iokc6a0f1s77','k52ebdo4n6','685abf69-1b8a-45d2-aadb-cfba82cb34b2','50.192.97.226',0,0,'2025-07-18 01:02:15','',0,'56','1'),
(9,'2001','test.dsiprouter.net','2000','test.dsiprouter.net','','2025-07-18 01:01:26',1,'XVDo4NXTl_LO_p-bUNHpZw..','01565d57','ed967d5e-c9cf-44de-9297-436842a4245c','50.192.97.226',0,0,'2025-07-18 01:02:15','',0,'0','0'),
(10,'2001','test.dsiprouter.net','2000','test.dsiprouter.net','','2025-07-18 01:08:33',2,'BcMdGz1BSJuEOT2UIvMQqg..','f4e3f57a','f2dbb35d-615d-4ec5-a1ac-458c9c179ce4','50.192.97.226',0,0,'2025-07-18 01:12:15','',0,'0','0'),
(11,'2001','test.dsiprouter.net','2000','test.dsiprouter.net','','2025-07-18 01:51:43',0,'KzCeEt_5R-U3tdN5Bckadg..','9513d73b','17810ca9-4af2-4af2-a960-1be76f5da327','50.192.97.226',0,0,'2025-07-18 02:02:38','',0,'0','0'),
(12,'2001','test.dsiprouter.net','2000','test.dsiprouter.net','','2025-07-18 01:56:48',3,'zGMogbVpyPPOVgYEnCqMfg..','661a163d','7184ad3c-59b2-4eb7-b6e8-0807a7aabb95','50.192.97.226',0,0,'2025-07-18 02:02:38','',0,'0','0'),
(13,'2001','test.dsiprouter.net','2000','test.dsiprouter.net','','2025-07-18 01:58:06',7,'zt8_y5dXtnmXVdCAEUUkkQ..','328ea419','7b64a262-296d-4e16-9f19-72bca321d671','50.192.97.226',0,0,'2025-07-18 02:02:38','',0,'56','1'),
(14,'2001','test.dsiprouter.net','2000','test.dsiprouter.net','','2025-07-18 01:58:28',2,'QftiU4nEv01MHa63HwRdhg..','a8a0d275','686cf599-550d-4c83-bebe-a0fc2b836919','50.192.97.226',0,0,'2025-07-18 02:02:38','',0,'56','1'),
(15,'2001','test.dsiprouter.net','2000','test.dsiprouter.net','','2025-07-18 03:50:46',4,'jHEjw2tsEusNKRMXNY1IXg..','c8cbe924','f5c8d214-3a4d-4784-90a6-e6868de9e365','50.192.97.226',0,0,'2025-07-18 04:10:01','',0,'56','1'),
(16,'2001','test.dsiprouter.net','2000','test.dsiprouter.net','','2025-07-18 03:51:20',4,'Bi1g9sxNBmuNH3ZxPk4HHQ..','bfbe5b6a','f8a6b7d3-286c-4236-8efc-79c264fd41d0','50.192.97.226',0,0,'2025-07-18 04:10:01','',0,'0','0'),
(17,'2001','test.dsiprouter.net','2000','test.dsiprouter.net','','2025-07-18 03:56:00',3,'XVLeVWP7PpEpGVw_GNYnpw..','af07f529','7b182ab5-ac5b-4957-b133-d5a43b811fc6','50.192.97.226',0,0,'2025-07-18 04:10:01','',0,'0','0'),
(18,'2001','test.dsiprouter.net','2000','test.dsiprouter.net','','2025-07-18 04:00:53',1,'jvokpPZB_xPxPucq9_AKJw..','0d780c3f','0ab7027d-af4d-41b9-aaf5-0d0e3c6678e2','50.192.97.226',0,0,'2025-07-18 04:10:01','',0,'0','0'),
(19,'2001','test.dsiprouter.net','2000','test.dsiprouter.net','','2025-07-18 04:05:34',9,'VBxJq1IXREt5lArdzPKuTg..','51ac6130','051aa48f-5186-45b6-ada0-4fb515537891','50.192.97.226',0,0,'2025-07-18 04:10:01','',0,'0','0'),
(20,'2001','test.dsiprouter.net','2000','test.dsiprouter.net','','2025-07-18 04:14:44',12,'PR_AT48gVvGtamUqblL3AA..','b4a10119','0378dfc1-0bee-40bf-bd98-52e69ea3ce0f','50.192.97.226',0,0,'2025-07-18 04:19:27','',0,'0','0'),
(21,'2001','test.dsiprouter.net','2000','test.dsiprouter.net','','2025-07-18 04:17:59',9,'3YE80Cx4X9dWtQPVDRd2Ng..','dad2dd70','9b30f7f1-d591-4c1d-9a31-2955c349b3c3','50.192.97.226',0,0,'2025-07-18 04:19:27','',0,'0','0'),
(22,'2001','143.198.44.195','068e0tg1','n0eciob64cns.invalid','','2025-07-18 04:22:56',32,'2291a552-b53f-4eb3-af49-7da08bc3fee6','b8b7b75d-9a37-4e7e-a7bb-3b36740508ae','stdi2jmcde','143.198.44.195',0,0,'2025-07-18 04:26:36','',0,'0','0'),
(23,'2001','test.dsiprouter.net','2000','test.dsiprouter.net','','2025-07-18 04:22:56',32,'cq2BVTuBA1nG5aT4g4fkwg..','8f93cc1b','33a373f4-498f-49b2-8c5a-dc3fd2c9ffba','50.192.97.226',0,0,'2025-07-18 04:26:36','',0,'56','1'),
(24,'2001','143.198.44.195','068e0tg1','n0eciob64cns.invalid','','2025-07-18 10:50:06',26,'34d370a9-b53f-441d-9597-996f194853c1','b3eba65f-f92f-4321-be23-bd69dfac06e3','qjoj3rnmu4','143.198.44.195',0,0,'2025-07-18 10:58:42','',0,'0','0'),
(25,'2001','test.dsiprouter.net','2000','test.dsiprouter.net','','2025-07-18 10:50:06',26,'b0QInEIov2xdN8N3tcEzMw..','06fc655b','fef763d6-2cd2-4a0c-a37e-d1173cf7ceef','50.192.97.226',0,0,'2025-07-18 10:58:42','',0,'56','1'),
(26,'2001','143.198.44.195','068e0tg1','n0eciob64cns.invalid','','2025-07-18 10:54:08',32,'15a8e07b-4432-4fdc-934b-7301f930c1ea','a98ac50a-e843-4d3b-a0a0-b0ba5f58034a','t6om3877nd','143.198.44.195',0,0,'2025-07-18 10:58:42','',0,'0','0'),
(27,'2001','test.dsiprouter.net','2000','test.dsiprouter.net','','2025-07-18 10:54:08',33,'FPoviMRD9FL8swsNDhZWpw..','faf5ee12','e0a968d5-7c74-47f9-99b1-ca313994331e','50.192.97.226',0,0,'2025-07-18 10:58:42','',0,'56','1'),
(28,'2001','143.198.44.195','068e0tg1','n0eciob64cns.invalid','','2025-07-18 10:55:57',15,'150862a5-e519-4d6f-b625-380665f32c21','8cec5052-73ca-4ec6-832e-cd6c7a137198','uquejo141c','143.198.44.195',0,0,'2025-07-18 10:58:42','',0,'0','0'),
(29,'2001','test.dsiprouter.net','2000','test.dsiprouter.net','','2025-07-18 10:55:57',15,'7ZsTIHVqwEB4gG7oufk75Q..','b018ef15','43311e64-dd9d-4f89-99b7-5018e4a363e8','50.192.97.226',0,0,'2025-07-18 10:58:42','',0,'0','0'),
(30,'2001','143.198.44.195','068e0tg1','n0eciob64cns.invalid','','2025-07-18 11:04:13',425,'74969bc5-cddc-4e7b-9712-7a0a4ddc7221','c05dce07-ddc3-412a-9576-b486b9ab16cc','179qrnve80','143.198.44.195',0,0,'2025-07-18 11:13:43','',0,'0','0'),
(31,'2001','test.dsiprouter.net','2000','test.dsiprouter.net','','2025-07-18 11:04:13',425,'EnSE3ON6FBiJcZg7nAW3xA..','95567500','941ba565-a574-4e50-9779-bb5f9dd87ee9','50.192.97.226',0,0,'2025-07-18 11:13:43','',0,'56','1'),
(32,'2000','test.dsiprouter.net','2001','test.dsiprouter.net','','2025-07-18 11:42:08',9,'6gctvih7dv7fpogqm85k','5d1dv7dj4i','739cfd1d-886d-419a-afd8-b2a06990ef51','50.192.97.226',0,0,'2025-07-18 11:43:43','',0,'56','1'),
(33,'2000','143.198.44.195','2001','50.192.97.226','','2025-07-18 11:42:35',11,'51dc9473-7ec4-438e-80e1-2bd6910a1c9a','3ed1ef93-5adb-4b62-b0a7-d09c77b6da73','9be84269','143.198.44.195',0,0,'2025-07-18 11:43:43','',0,'0','0'),
(34,'2000','test.dsiprouter.net','2001','test.dsiprouter.net','','2025-07-18 11:42:35',11,'6gctvlnpsi7e65nl8ifk','i5tfdlhmmc','e2063827-4ec7-42c8-a0bf-6884f82ed63b','50.192.97.226',0,0,'2025-07-18 11:43:43','',0,'0','0'),
(35,'2000','143.198.44.195','2001','50.192.97.226','','2025-07-18 11:50:21',15,'9ae7000d-206b-471d-9f4f-6884e8cbcc36','203e250f-d01b-4ee1-8b33-c79bd4a2ddba','27ec7c73','143.198.44.195',0,0,'2025-07-18 11:54:57','',0,'0','0'),
(36,'2000','test.dsiprouter.net','2001','test.dsiprouter.net','','2025-07-18 11:50:21',15,'6gctvl2h5m677tedl73v','07c19qmf0k','3af809e9-a547-4300-9870-99f12a0ba94b','50.192.97.226',0,0,'2025-07-18 11:54:57','',0,'56','1'),
(37,'2001','143.198.44.195','068e0tg1','n0eciob64cns.invalid','','2025-07-18 11:50:49',5,'60cf7ba7-f299-41a3-adf7-e4076938c26e','d85315fb-cde1-40a9-b5da-b186c8c12683','s6bkcjuer4','143.198.44.195',0,0,'2025-07-18 11:54:57','',0,'0','0'),
(38,'2001','test.dsiprouter.net','2000','test.dsiprouter.net','','2025-07-18 11:50:49',5,'LsqdSOuhvgBlSgu6mD02qQ..','6d451e13','ea34f396-2b32-48a5-9b49-66f387dd1eec','50.192.97.226',0,0,'2025-07-18 11:54:57','',0,'56','1'),
(39,'+19475176566','fl.gg','proj_MrxkZ5BlbAFrpJXiyZBrs6mq','sip.api.openai.com','','2025-10-24 03:04:54',85,'208428479_133162762@206.147.88.72','gK0c1bc4f8','43d5a9ef-fdbc-4753-86d0-ad786e95b3de','34.226.36.33',0,0,'2025-10-24 03:09:24','inbound',0,'0','14'),
(40,'+19475176566','fl.gg','proj_MrxkZ5BlbAFrpJXiyZBrs6mq','sip.api.openai.com','','2025-10-24 03:20:14',9,'438587087_132045321@74.120.93.30','gK040c0fc7','b2850e68-1dc2-42df-b64a-961410be08ce','34.226.36.33',0,0,'2025-10-24 03:25:04','inbound',0,'0','14'),
(41,'+19475176566','fl.gg','proj_MrxkZ5BlbAFrpJXiyZBrs6mq','sip.api.openai.com','','2025-10-24 04:19:37',75,'438357385_133953516@74.120.93.30','gK00419423','aec90603-fd85-4517-ad7b-b1cc7f609d51','34.226.36.35',0,0,'2025-10-24 04:24:06','inbound',0,'0','14'),
(42,'+19475176566','fl.gg','proj_MrxkZ5BlbAFrpJXiyZBrs6mq','sip.api.openai.com','','2025-10-24 04:42:54',152,'256420411_16749185@74.120.93.200','gK087514f6','7eba831b-ca32-4d6d-84c2-7dcf5becb300','34.226.36.33',0,0,'2025-10-24 04:49:06','inbound',0,'0','14'),
(43,'+19475176566','fl.gg','proj_MrxkZ5BlbAFrpJXiyZBrs6mq','sip.api.openai.com','','2025-10-24 20:51:03',8,'509878254_133211243@74.120.93.30','gK045630cd','3e693041-ebb2-4b8d-84b6-f7af3744c6a4','34.226.36.33',0,0,'2025-10-24 20:54:08','inbound',0,'0','14'),
(44,'+19475176566','fl.gg','proj_MrxkZ5BlbAFrpJXiyZBrs6mq','sip.api.openai.com','','2025-10-24 20:51:24',14,'524295333_133912318@74.120.93.200','gK006770e9','9cbadbd2-05b6-4b90-9620-1b3d1e7a9e25','34.226.36.35',0,0,'2025-10-24 20:54:08','inbound',0,'0','14'),
(45,'+19475176566','fl.gg','proj_MrxkZ5BlbAFrpJXiyZBrs6mq','sip.api.openai.com','','2025-10-24 21:20:37',8,'503842597_134080436@74.120.93.30','gK083999b1','b06475cf-1a24-4b54-afe2-49aeaa6b0617','34.226.36.34',0,0,'2025-10-24 21:24:08','inbound',0,'0','14'),
(46,'+19475176566','fl.gg','proj_MrxkZ5BlbAFrpJXiyZBrs6mq','sip.api.openai.com','','2025-10-24 21:20:49',101,'507820268_121572229@206.147.88.72','gK0474a877','0570103f-175d-4469-8154-ac8c77e4f591','34.226.36.33',0,0,'2025-10-24 21:24:08','inbound',0,'0','14'),
(47,'+19475176566','fl.gg','proj_MrxkZ5BlbAFrpJXiyZBrs6mq','sip.api.openai.com','','2025-10-27 10:41:59',21,'295641_133329785@74.120.93.30','gK04463251','096cb1be-9f71-4beb-9bc5-ab160dfca408','34.226.36.33',0,0,'2025-10-27 10:44:13','inbound',0,'0','14'),
(48,'+19475176566','fl.gg','proj_MrxkZ5BlbAFrpJXiyZBrs6mq','sip.api.openai.com','','2025-10-27 20:59:52',4,'39864624_125792962@74.120.93.30','gK007143a2','253662be-5ee2-4476-9f53-9ed3576f527e','34.226.36.33',0,0,'2025-10-27 21:04:14','inbound',0,'0','14'),
(49,'3137891313','34.210.91.112','16723617*19475176566','34.210.91.112','','2025-10-27 21:03:14',11,'bTsOkw-B-JooRs4tWio6xA..','19cd9b51','gK08ffbd62','50.192.97.226',0,0,'2025-10-27 21:04:14','outbound',0,'13','3'),
(50,'3137891313','34.210.91.112','16723617*19475176566','34.210.91.112','','2025-10-27 22:17:45',15,'SaKuRgvQ2neucUy8u2053g..','2759780b','gK04e633c1','50.192.97.226',0,0,'2025-10-27 22:23:32','outbound',0,'13','3'),
(51,'3137891313','34.210.91.112','16723617*19475176566','34.210.91.112','','2025-10-27 22:21:39',88,'Rg79zJQdr1qmQCcPVX7vOQ..','c42e607b','gK04aa805a','50.192.97.226',0,0,'2025-10-27 22:23:32','outbound',0,'13','3'),
(52,'3137891313','34.210.91.112','16723617*19475176566','34.210.91.112','','2025-10-27 22:23:42',7,'mgtIA_pD29Mr2oKFzr6WSQ..','ee4d0234','gK0c91fc24','50.192.97.226',0,0,'2025-10-27 22:30:13','outbound',0,'13','3'),
(53,'3137891313','34.210.91.112','16723617*19475176566','34.210.91.112','','2025-10-27 22:25:32',2,'s6_dKv0LY6HKj5DQxegRnA..','e5eac314','gK04e20e89','50.192.97.226',0,0,'2025-10-27 22:30:13','outbound',0,'13','3'),
(54,'3137891313','34.210.91.112','16723617*19475176566','34.210.91.112','','2025-10-28 03:05:18',43,'-vPMVYz2yaOjZNOrrnLL5g..','0489c025','gK0cf7e856','50.192.97.226',0,0,'2025-10-28 03:09:49','outbound',0,'13','3'),
(55,'3137891313','34.210.91.112','16723617*19475176566','34.210.91.112','','2025-10-28 03:07:45',6,'JxQtQ4TdtvgTl9a5ckUAhQ..','fec04d65','gK049dc82e','50.192.97.226',0,0,'2025-10-28 03:09:49','outbound',0,'13','3'),
(56,'3137891313','34.210.91.112','16723617*19475176566','34.210.91.112','','2025-10-28 03:08:13',30,'SeJsM9umYiYBpwMrP75YYQ..','ec593724','gK0cb80944','50.192.97.226',0,0,'2025-10-28 03:09:49','outbound',0,'13','3'),
(57,'3137891313','34.210.91.112','16723617*19475176566','34.210.91.112','','2025-10-28 03:10:20',125,'xaCz-lMXL5eCgvAhunmuhw..','fb825b6e','gK08ef5a1d','50.192.97.226',0,0,'2025-10-28 03:15:04','outbound',0,'13','3'),
(58,'3137891313','34.210.91.112','16723617*19475176566','34.210.91.112','','2025-10-28 03:28:17',23,'hBTOVGKIUTZMLnV6AHlAjg..','b76fa61c','gK0c863b20','50.192.97.226',0,0,'2025-10-28 03:32:56','outbound',0,'13','3'),
(59,'3137891313','34.210.91.112','16723617*19475176566','34.210.91.112','','2025-10-28 04:06:15',8,'HYskrUUBNmULhsjyAiEQaQ..','dd1e5d79','gK089c9017','50.192.97.226',0,0,'2025-10-28 04:10:40','outbound',0,'13','3'),
(60,'3137891313','34.210.91.112','16723617*19475176566','34.210.91.112','','2025-10-28 04:32:23',24,'u3iHWYs-L6GSAk0sv5rlCw..','67ae4719','gK009d4f67','50.192.97.226',0,0,'2025-10-28 04:52:33','outbound',0,'13','3'),
(61,'3137891313','34.210.91.112','16723617*19475176566','34.210.91.112','','2025-10-28 04:36:14',24,'zR_6NyGpMNKkS2iu26VbMw..','d79b495f','gK00bd8ff6','50.192.97.226',0,0,'2025-10-28 04:52:33','outbound',0,'13','3'),
(62,'3137891313','34.210.91.112','16723617*19475176566','34.210.91.112','','2025-10-28 04:39:09',7,'LX5iNIp6bqAp_OCf7hQRaw..','26ca596f','gK0c92c5e3','50.192.97.226',0,0,'2025-10-28 04:52:33','outbound',0,'13','3'),
(63,'3137891313','34.210.91.112','16723617*19475176566','34.210.91.112','','2025-10-28 04:41:26',24,'hGC9An3FC6I0TedOQPhf_w..','e3b96679','gK08e1235d','50.192.97.226',0,0,'2025-10-28 04:52:33','outbound',0,'13','3'),
(64,'3137891313','34.210.91.112','16723617*19475176566','34.210.91.112','','2025-10-28 04:44:17',24,'JonuNbZQ_R0DA0_oQA6mcg..','9dac6815','gK0c94ccb8','50.192.97.226',0,0,'2025-10-28 04:52:33','outbound',0,'13','3'),
(65,'3137891313','34.210.91.112','16723617*19475176566','34.210.91.112','','2025-10-28 04:47:59',49,'DTWzP1cS5aGuwEdaIHUGHA..','68369615','gK0c82c42a','50.192.97.226',0,0,'2025-10-28 04:52:33','outbound',0,'13','3'),
(66,'+19475176566','fl.gg','proj_MrxkZ5BlbAFrpJXiyZBrs6mq','sip.api.openai.com','','2025-10-28 13:03:51',54,'50618368_121240042@74.120.93.30','gK0429ac91','07669f53-f728-455e-948b-107b738e4588','34.226.36.33',0,0,'2025-10-28 13:07:34','inbound',0,'0','14'),
(67,'+19475176566','fl.gg','proj_MrxkZ5BlbAFrpJXiyZBrs6mq','sip.api.openai.com','','2025-10-28 13:04:52',6,'386451262_55121521@74.120.93.200','gK08130131','f603f310-b88e-472e-b876-8a06e1b27361','34.226.36.34',0,0,'2025-10-28 13:07:34','inbound',0,'0','14'),
(68,'+19475176566','fl.gg','proj_MrxkZ5BlbAFrpJXiyZBrs6mq','sip.api.openai.com','','2025-10-28 13:05:02',7,'386451382_50322849@74.120.93.200','gK08138319','6ec6ee8c-9a53-43a8-8194-69d23b75437e','34.226.36.35',0,0,'2025-10-28 13:07:34','inbound',0,'0','14'),
(69,'+19475176566','fl.gg','proj_MrxkZ5BlbAFrpJXiyZBrs6mq','sip.api.openai.com','','2025-10-31 19:32:37',94,'369935905_131067100@74.120.93.30','gK0c023911','2fc96f60-5c9c-447d-9369-ce553a9e4377','34.226.36.33',0,0,'2025-10-31 19:37:41','inbound',0,'0','14'),
(70,'+19475176566','fl.gg','proj_MrxkZ5BlbAFrpJXiyZBrs6mq','sip.api.openai.com','','2025-10-31 21:12:39',10,'6299522_58080382@74.120.93.200','gK0058d197','57db912d-4791-4c61-81c3-e79d47b0a5c0','34.226.36.35',0,0,'2025-10-31 21:17:41','inbound',0,'0','14'),
(71,'+19475176566','fl.gg','proj_MrxkZ5BlbAFrpJXiyZBrs6mq','sip.api.openai.com','','2025-10-31 21:12:54',127,'403442354_128660845@74.120.93.30','gK0c325922','0071eb7a-687e-4b12-8939-59f4706416dc','34.226.36.32',0,0,'2025-10-31 21:17:41','inbound',0,'3','14'),
(72,'+19475176566','fl.gg','proj_MrxkZ5BlbAFrpJXiyZBrs6mq','sip.api.openai.com','','2025-11-01 00:49:45',83,'409214770_92069723@74.120.93.30','gK047e3756','4d12dc4f-5921-4774-b71f-70027716b535','34.226.36.33',0,0,'2025-11-01 00:52:41','inbound',0,'0','14'),
(73,'+19475176566','fl.gg','proj_MrxkZ5BlbAFrpJXiyZBrs6mq','sip.api.openai.com','','2025-11-01 01:17:24',131,'17319824_129664308@74.120.93.200','gK084d5783','73fce51d-8064-41f0-956d-9ce058d001d0','34.226.36.33',0,0,'2025-11-01 01:22:41','inbound',0,'0','14'),
(74,'+19475176566','fl.gg','proj_MrxkZ5BlbAFrpJXiyZBrs6mq','sip.api.openai.com','','2025-11-01 01:31:24',9,'17088871_99066122@74.120.93.200','gK044190f6','59e34f0d-cf8b-4e21-a03c-3e2e7ce7e30a','34.226.36.34',0,0,'2025-11-01 01:32:41','inbound',0,'0','14'),
(75,'+19475176566','fl.gg','proj_MrxkZ5BlbAFrpJXiyZBrs6mq','sip.api.openai.com','','2025-11-01 01:31:39',82,'17088900_62890530@74.120.93.200','gK0441c31d','451f351b-cec6-4835-a28b-e67053f87c75','34.226.36.35',0,0,'2025-11-01 01:37:41','inbound',0,'0','14'),
(76,'+19475176566','fl.gg','proj_MrxkZ5BlbAFrpJXiyZBrs6mq','sip.api.openai.com','','2025-11-01 01:46:18',477,'392472330_115211307@206.147.88.72','gK044d6cf2','8d8d27d3-cc14-48fe-bde3-2d2db0c13eb4','34.226.36.34',0,0,'2025-11-01 01:57:41','inbound',0,'0','14'),
(77,'+19475176566','fl.gg','proj_MrxkZ5BlbAFrpJXiyZBrs6mq','sip.api.openai.com','','2025-11-01 01:54:39',397,'392474172_121485297@206.147.88.72','gK0455ec9d','e7cd2c27-e566-45ba-81ab-9cd21e10a2f6','34.226.36.35',0,0,'2025-11-01 02:02:41','inbound',0,'0','14'),
(78,'+19475176566','fl.gg','proj_MrxkZ5BlbAFrpJXiyZBrs6mq','sip.api.openai.com','','2025-11-01 02:03:13',126,'409747432_121618616@74.120.93.30','gK0c7707bd','f9cf1807-9402-4990-8cbe-e4fb2948d25c','34.226.36.33',0,0,'2025-11-01 02:07:41','inbound',0,'0','14'),
(79,'+19475176566','fl.gg','proj_MrxkZ5BlbAFrpJXiyZBrs6mq','sip.api.openai.com','','2025-11-01 02:06:13',26,'408991844_133536002@74.120.93.30','gK0073c4f4','e107cc3d-66b4-4d5e-955f-3e0593c4b1d8','34.226.36.35',0,0,'2025-11-01 02:07:41','inbound',0,'0','14'),
(80,'+19475176566','fl.gg','proj_MrxkZ5BlbAFrpJXiyZBrs6mq','sip.api.openai.com','','2025-11-01 02:09:22',236,'409486557_9230871@74.120.93.30','gK085b8f7b','744a6d06-c926-41f3-befd-7fd9a0cc6ca8','34.226.36.35',0,0,'2025-11-01 02:17:41','inbound',0,'0','14'),
(81,'+19475176566','fl.gg','proj_MrxkZ5BlbAFrpJXiyZBrs6mq','sip.api.openai.com','','2025-11-01 02:15:36',160,'408993008_132636985@74.120.93.30','gK007a0a2e','0e37ffaa-80ee-44c4-88d0-9e79d2eba196','34.226.36.32',0,0,'2025-11-01 02:22:41','inbound',0,'3','14'),
(82,'+19475176566','fl.gg','proj_MrxkZ5BlbAFrpJXiyZBrs6mq','sip.api.openai.com','','2025-11-01 02:20:19',10,'408993532_133929701@74.120.93.30','gK007cf821','46b9bbdb-282b-44c0-af3b-e5a1531315fb','34.226.36.35',0,0,'2025-11-01 02:22:41','inbound',0,'0','14'),
(83,'+18889072085','fl.gg','proj_MrxkZ5BlbAFrpJXiyZBrs6mq','sip.api.openai.com','','2025-11-01 02:27:31',38,'17590367_74395316@74.120.93.200','gK0c3155cf','261cdb71-393c-4a3d-853e-bd18aca40ba0','34.226.36.33',0,0,'2025-11-01 02:32:41','inbound',0,'0','14'),
(84,'+18889072085','fl.gg','proj_MrxkZ5BlbAFrpJXiyZBrs6mq','sip.api.openai.com','','2025-11-01 02:31:57',180,'17095727_134019348@74.120.93.200','gK046db84e','fb74b4c0-6c4b-4c34-9fb2-4574beb77c7e','34.226.36.33',0,0,'2025-11-01 02:37:41','inbound',0,'0','14'),
(85,'+18889072085','fl.gg','proj_MrxkZ5BlbAFrpJXiyZBrs6mq','sip.api.openai.com','','2025-11-01 02:42:12',14,'392483373_129712081@206.147.88.72','gK04013eb9','230a8c44-e779-45e2-a102-b598d3743ba5','34.226.36.35',0,0,'2025-11-01 02:42:41','inbound',0,'0','14'),
(86,'+19475176566','fl.gg','proj_MrxkZ5BlbAFrpJXiyZBrs6mq','sip.api.openai.com','','2025-11-01 02:48:49',70,'409490769_92252316@74.120.93.30','gK086e0fc6','afccdf6f-e786-4068-9832-3c2bb48b1a18','34.226.36.33',0,0,'2025-11-01 02:52:41','inbound',0,'0','14'),
(87,'+19475176566','fl.gg','proj_MrxkZ5BlbAFrpJXiyZBrs6mq','sip.api.openai.com','','2025-11-01 12:11:15',70,'406895930_129488724@206.147.88.72','gK0053213e','ae11bc86-2866-4f25-bf39-642e5a432e19','34.226.36.35',0,0,'2025-11-01 12:12:42','inbound',0,'0','14'),
(88,'+19475176566','fl.gg','proj_MrxkZ5BlbAFrpJXiyZBrs6mq','sip.api.openai.com','','2025-11-01 14:40:19',58,'403483753_117165598@74.120.93.30','gK0c4ca311','f1f67a32-ddc8-4614-9428-53a4d2dbd605','34.226.36.32',0,0,'2025-11-01 14:42:42','inbound',0,'3','14'),
(89,'+19475176566','fl.gg','proj_MrxkZ5BlbAFrpJXiyZBrs6mq','sip.api.openai.com','','2025-11-01 14:44:48',46,'21012164_123690908@74.120.93.200','gK006c22bc','494cc884-23f8-4df6-b784-a5512ce43751','34.226.36.32',0,0,'2025-11-01 14:47:42','inbound',0,'3','14'),
(90,'+19475176566','fl.gg','proj_MrxkZ5BlbAFrpJXiyZBrs6mq','sip.api.openai.com','','2025-11-01 14:53:05',194,'19444298_126769545@74.120.93.200','gK084f95b4','522f6d98-e6a5-4be5-9c16-2cf935819c97','34.226.36.35',0,0,'2025-11-01 14:57:42','inbound',0,'0','14'),
(91,'+19475176566','fl.gg','proj_MrxkZ5BlbAFrpJXiyZBrs6mq','sip.api.openai.com','','2025-11-01 15:00:26',121,'407650126_131988222@206.147.88.72','gK0c122ee8','2a7b61c2-0dfa-452d-b429-cbbe096c3fd3','34.226.36.35',0,0,'2025-11-01 15:02:42','inbound',0,'0','14'),
(92,'+19475176566','fl.gg','proj_MrxkZ5BlbAFrpJXiyZBrs6mq','sip.api.openai.com','','2025-11-01 16:10:20',53,'422354841_134209026@74.120.93.30','gK0c1addac','d39eb38c-05f7-4040-b640-907c2cdbacc0','34.226.36.34',0,0,'2025-11-01 16:12:42','inbound',0,'0','14'),
(93,'+19475176566','fl.gg','proj_MrxkZ5BlbAFrpJXiyZBrs6mq','sip.api.openai.com','','2025-11-05 02:53:12',9,'236983219_123075107@206.147.88.72','gK00290ee1','17346942-1420-4d6d-962f-c4efc068a368','34.226.36.34',0,0,'2025-11-05 02:57:50','inbound',0,'0','14'),
(94,'+19475176566','fl.gg','proj_MrxkZ5BlbAFrpJXiyZBrs6mq','sip.api.openai.com','','2025-11-05 22:07:49',12,'438348757_133764144@206.147.88.72','gK0013a212','0d7ec36d-3ef1-49a0-9860-21c4971fc1e3','34.226.36.35',0,0,'2025-11-05 22:12:52','inbound',0,'0','14'),
(95,'+19475176566','fl.gg','proj_MrxkZ5BlbAFrpJXiyZBrs6mq','sip.api.openai.com','','2025-11-05 22:08:10',57,'218380866_133679447@74.120.93.30','gK0477a885','a0800c87-f947-45cc-bfc2-56d6decfa1c6','34.226.36.32',0,0,'2025-11-05 22:12:52','inbound',0,'3','14'),
(96,'+19475176566','fl.gg','proj_MrxkZ5BlbAFrpJXiyZBrs6mq','sip.api.openai.com','','2025-11-05 22:33:22',94,'220235093_133610229@74.120.93.30','gK00524166','79891464-5a7b-420d-8608-1c428ad455c3','34.226.36.34',0,0,'2025-11-05 22:37:52','inbound',0,'0','14'),
(97,'+19475176566','fl.gg','proj_MrxkZ5BlbAFrpJXiyZBrs6mq','sip.api.openai.com','','2025-11-05 22:48:50',53,'141303343_133931688@74.120.93.200','gK0c3dbf08','90c42907-2353-410d-bbd5-95585aa4a942','34.226.36.35',0,0,'2025-11-05 22:52:52','inbound',0,'0','14'),
(98,'+19475176566','fl.gg','proj_MrxkZ5BlbAFrpJXiyZBrs6mq','sip.api.openai.com','','2025-11-05 22:58:06',7,'140815143_66754003@74.120.93.200','gK046aa2ab','8918affd-cd17-4804-bc73-a67597c2ff63','34.226.36.34',0,0,'2025-11-05 23:02:52','inbound',0,'0','14'),
(99,'+19475176566','fl.gg','proj_MrxkZ5BlbAFrpJXiyZBrs6mq','sip.api.openai.com','','2025-11-05 22:58:19',8,'221039266_125750078@74.120.93.30','gK0c5277f5','b04a9e33-bbcc-4156-87af-264d7bb459c7','34.226.36.34',0,0,'2025-11-05 23:02:52','inbound',0,'0','14'),
(100,'+19475176566','fl.gg','proj_MrxkZ5BlbAFrpJXiyZBrs6mq','sip.api.openai.com','','2025-11-05 22:58:32',69,'222314636_133145475@74.120.93.30','gK007b7f5a','fbdf140c-5a4a-474f-8a08-70d73a4ffd72','34.226.36.32',0,0,'2025-11-05 23:02:52','inbound',0,'3','14'),
(101,'+19475176566','fl.gg','proj_MrxkZ5BlbAFrpJXiyZBrs6mq','sip.api.openai.com','','2025-11-05 23:25:54',127,'491295341_121606613@206.147.88.72','gK085f2066','4d1365f7-adae-42d5-b5fc-98570eb63a64','34.226.36.33',0,0,'2025-11-05 23:32:52','inbound',0,'0','14'),
(102,'+19475176566','fl.gg','proj_MrxkZ5BlbAFrpJXiyZBrs6mq','sip.api.openai.com','','2025-11-06 00:27:54',60,'241996277_130924258@74.120.93.30','gK0c492c24','f0f9d7a1-f814-4b25-928b-374577f0713a','34.226.36.34',0,0,'2025-11-06 00:32:52','inbound',0,'0','14'),
(103,'+19475176566','fl.gg','proj_MrxkZ5BlbAFrpJXiyZBrs6mq','sip.api.openai.com','','2025-11-06 00:30:13',44,'234884416_113205954@74.120.93.30','gK00042353','b3cfa9e0-0744-4cdb-885f-1cd405148de6','34.226.36.35',0,0,'2025-11-06 00:32:52','inbound',0,'0','14'),
(104,'+19475176566','fl.gg','proj_MrxkZ5BlbAFrpJXiyZBrs6mq','sip.api.openai.com','','2025-11-06 00:40:56',49,'234891814_95781774@74.120.93.30','gK0022c790','e01fba2d-5157-47f2-b597-40bb66480fa2','34.226.36.33',0,0,'2025-11-06 00:42:52','inbound',0,'0','14'),
(105,'+19475176566','fl.gg','proj_MrxkZ5BlbAFrpJXiyZBrs6mq','sip.api.openai.com','','2025-11-06 03:22:20',362,'188745272_66568792@74.120.93.200','gK000b2ab4','cd9fe14a-a18d-4ba9-ad6e-5c3502e5689e','34.226.36.34',0,0,'2025-11-06 03:32:53','inbound',0,'0','14'),
(106,'+19475176566','fl.gg','proj_MrxkZ5BlbAFrpJXiyZBrs6mq','sip.api.openai.com','','2025-11-06 03:45:23',102,'40164784_119248421@206.147.88.72','gK0416f05b','58e5701b-8559-4370-9ac5-fbf0e7f9f1fe','34.226.36.35',0,0,'2025-11-06 03:47:53','inbound',0,'0','14'),
(107,'+19475176566','fl.gg','proj_MrxkZ5BlbAFrpJXiyZBrs6mq','sip.api.openai.com','','2025-11-06 03:47:12',87,'187440117_27425980@74.120.93.200','gK0c0f7f99','63193eaf-fd24-4619-be90-95577152948e','34.226.36.32',0,0,'2025-11-06 03:52:53','inbound',0,'3','14'),
(108,'+19475176566','fl.gg','proj_MrxkZ5BlbAFrpJXiyZBrs6mq','sip.api.openai.com','','2025-11-06 04:12:47',30,'235440033_129684062@74.120.93.30','gK080063c6','80ff31a4-19ed-4f08-b378-f4f688bd1ba0','34.226.36.34',0,0,'2025-11-06 04:17:53','inbound',0,'0','14'),
(109,'+19475176566','fl.gg','proj_MrxkZ5BlbAFrpJXiyZBrs6mq','sip.api.openai.com','','2025-11-06 04:20:11',8,'188749853_60792867@74.120.93.200','gK004989c7','fea564aa-6806-4159-84c5-409e9ef11e40','34.226.36.33',0,0,'2025-11-06 04:22:53','inbound',0,'0','14'),
(110,'+19475176566','fl.gg','proj_MrxkZ5BlbAFrpJXiyZBrs6mq','sip.api.openai.com','','2025-11-06 04:20:23',20,'35710658_131840209@206.147.88.72','gK00010414','0553c686-455d-49ef-a05c-8527e4313fc5','34.226.36.34',0,0,'2025-11-06 04:22:53','inbound',0,'0','14'),
(111,'+19475176566','fl.gg','proj_MrxkZ5BlbAFrpJXiyZBrs6mq','sip.api.openai.com','','2025-11-06 04:28:18',59,'33818692_70244339@206.147.88.72','gK0433d06b','c192c718-ea77-4b44-9af2-c0a54a2177ff','34.226.36.34',0,0,'2025-11-06 04:32:53','inbound',0,'0','14'),
(112,'+19475176566','fl.gg','proj_MrxkZ5BlbAFrpJXiyZBrs6mq','sip.api.openai.com','','2025-11-06 04:54:01',55,'235705812_102674735@74.120.93.30','gK0c311784','84511a72-7edb-4e5c-8e48-740f39fae675','34.226.36.34',0,0,'2025-11-06 04:57:53','inbound',0,'0','14'),
(113,'+19475176566','fl.gg','proj_MrxkZ5BlbAFrpJXiyZBrs6mq','sip.api.openai.com','','2025-11-06 05:02:35',83,'188752423_133592721@74.120.93.200','gK00743265','18f9cb20-66c1-4edb-b0b7-c7f7234461bf','34.226.36.35',0,0,'2025-11-06 05:07:53','inbound',0,'0','14'),
(114,'+19475176566','fl.gg','proj_MrxkZ5BlbAFrpJXiyZBrs6mq','sip.api.openai.com','','2025-11-06 05:07:33',75,'235184282_50299290@74.120.93.30','gK043239b3','55ed7276-b471-426c-8a02-c9b5be5b5801','34.226.36.35',0,0,'2025-11-06 05:12:53','inbound',0,'0','14'),
(115,'+19475176566','fl.gg','proj_MrxkZ5BlbAFrpJXiyZBrs6mq','sip.api.openai.com','','2025-11-06 05:10:24',5,'34379581_16443681@206.147.88.72','gK0c5edb2f','bac53002-7dbc-4696-80d4-0c290a3e5443','34.226.36.33',0,0,'2025-11-06 05:12:53','inbound',0,'0','14'),
(116,'+19475176566','fl.gg','proj_MrxkZ5BlbAFrpJXiyZBrs6mq','sip.api.openai.com','','2025-11-06 13:34:48',1,'271067061_111069076@74.120.93.30','gK0829d920','427d06da-a026-4dbf-8c1b-2deee869ec0e','34.226.36.34',0,0,'2025-11-06 13:37:53','inbound',0,'0','14'),
(117,'+19475176566','dsiptest.pstn.twilio.com','proj_MrxkZ5BlbAFrpJXiyZBrs6mq','sip.api.openai.com','','2025-11-06 19:36:09',11,'dd89bbdce6f544370a93fbdcc0e8ee1b@0.0.0.0','21043812_c3356d0b_0c3833a4-1cd6-4ecb-bdce-fa26b84066d7','9a933fd6-7a77-47af-a55b-9284d5deb0ac','54.244.51.2',0,0,'2025-11-06 19:37:54','inbound',0,'1','14'),
(118,'+19475176566','dsiptest.pstn.twilio.com','proj_LiCooyUxqKrHxGckhR34dpHR','sip.api.openai.com','','2025-11-06 19:37:27',14,'85348c4c463d800701f04a76875ce7d6@0.0.0.0','05805446_c3356d0b_4b4993d8-535f-4645-bc83-5c36d4eeea34','f87b109b-cf7b-4884-8930-4ebc998dfae2','54.172.60.1',0,0,'2025-11-06 19:37:54','inbound',0,'1','15'),
(119,'+19475176566','dsiptest.pstn.twilio.com','proj_LiCooyUxqKrHxGckhR34dpHR','sip.api.openai.com','','2025-11-06 20:02:51',29,'f7e2712e3171615fc256382d092b7436@0.0.0.0','21604887_c3356d0b_339814ab-e7d7-4ef3-b5bf-e7fe88fc320b','57f5105d-bf93-4ac7-912e-08728e127e96','54.172.60.0',0,0,'2025-11-06 20:07:54','inbound',0,'1','15'),
(120,'+19475176566','dsiptest.pstn.twilio.com','proj_LiCooyUxqKrHxGckhR34dpHR','sip.api.openai.com','','2025-11-06 20:03:25',7,'d40a8fa5059508200af5b7f36abb32a2@0.0.0.0','24846813_c3356d0b_30452c08-1e3d-46dd-8b4d-6da896d64ae8','6aed329c-845a-48be-95a4-54f6cfe359ce','54.172.60.2',0,0,'2025-11-06 20:07:54','inbound',0,'1','15'),
(121,'+19475176566','dsiptest.pstn.twilio.com','proj_LiCooyUxqKrHxGckhR34dpHR','sip.api.openai.com','','2025-11-06 20:04:26',85,'3fc4ea6dd7e659103a56361daa0e200b@0.0.0.0','38665278_c3356d0b_5d0c44d1-818d-4e17-820b-89ae6bdfc1ea','dbeb1d58-1659-4418-90a4-dcdd9dcbdd9e','54.244.51.1',0,0,'2025-11-06 20:07:54','inbound',0,'1','15'),
(122,'+19475176566','dsiptest.pstn.twilio.com','proj_LiCooyUxqKrHxGckhR34dpHR','sip.api.openai.com','','2025-11-06 20:11:06',46,'37a92d49e7d22394c7bfd07c87fb668e@0.0.0.0','07807462_c3356d0b_67f4aeea-d964-44be-ba8e-9578365d0faa','3b9af439-5b0f-4da5-9aa5-5b31f8472125','54.172.60.2',0,0,'2025-11-06 20:12:54','inbound',0,'1','15'),
(123,'+19475176566','dsiptest.pstn.twilio.com','proj_LiCooyUxqKrHxGckhR34dpHR','sip.api.openai.com','','2025-11-06 20:15:15',35,'4b4a8abd4374c4022de75be0f6a8c814@0.0.0.0','17087905_c3356d0b_6ebce8dd-2cc4-4319-9e70-4aecdaff6239','bde55dc5-bfe6-4553-9ced-4d98b3aafef6','54.244.51.2',0,0,'2025-11-06 20:17:54','inbound',0,'1','15'),
(124,'+19475176566','dsiptest.pstn.twilio.com','proj_LiCooyUxqKrHxGckhR34dpHR','sip.api.openai.com','','2025-11-06 20:16:23',43,'cb1fbe1ee3b952f943c987714df89760@0.0.0.0','24472961_c3356d0b_1a82e05a-820e-46ea-a7fc-edb28311abe8','529d04e5-c904-4d37-8090-0eef8f8eca57','54.172.60.0',0,0,'2025-11-06 20:17:54','inbound',0,'1','15'),
(125,'+19475176566','dsiptest.pstn.twilio.com','proj_LiCooyUxqKrHxGckhR34dpHR','sip.api.openai.com','','2025-11-06 20:27:51',51,'0d07b1c9f78e9d6e931c9e0e9132b753@0.0.0.0','02581171_c3356d0b_d4d53f33-5ead-4b7c-8c71-f52a3417fa70','2688bc0b-25a3-42fb-9d06-cc1a0ee1cd53','54.172.60.1',0,0,'2025-11-06 20:32:54','inbound',0,'1','15'),
(126,'+19475176566','dsiptest.pstn.twilio.com','proj_LiCooyUxqKrHxGckhR34dpHR','sip.api.openai.com','','2025-11-06 21:01:07',20,'f2b6a6538b8feb1059adf193a6b43ece@0.0.0.0','38560634_c3356d0b_f7eb97d5-543a-4859-afd2-cd03d0921573','bdca2fa5-8a79-4f98-8957-333c7bf140f0','54.172.60.3',0,0,'2025-11-06 21:02:54','inbound',0,'1','15'),
(127,'+19475176566','dsiptest.pstn.twilio.com','proj_LiCooyUxqKrHxGckhR34dpHR','sip.api.openai.com','','2025-11-06 22:09:41',123,'b610d03fa722f88e928f0e8e3a7d1010@0.0.0.0','06383118_c3356d0b_57c77f02-0516-4704-9d11-f180a31ce292','348762a6-b09b-4fe5-b6de-3aefe6e5ccb9','54.244.51.2',0,0,'2025-11-06 22:12:54','inbound',0,'1','15'),
(128,'+19475176566','dsiptest.pstn.twilio.com','proj_LiCooyUxqKrHxGckhR34dpHR','sip.api.openai.com','','2025-11-06 22:17:09',102,'9d4be0c4690aef1dca8e3cc227d1a2f7@0.0.0.0','89772968_c3356d0b_0b0ae86a-6742-47c4-83ef-204db9924b4e','fd7c030b-77f4-42fd-984a-0edfb4cf1558','54.172.60.3',0,0,'2025-11-06 22:22:54','inbound',0,'1','15'),
(129,'+19475176566','dsiptest.pstn.twilio.com','proj_LiCooyUxqKrHxGckhR34dpHR','sip.api.openai.com','','2025-11-06 22:21:08',142,'11d8692bf0672708a7bdd38e31db8a0c@0.0.0.0','40134249_c3356d0b_60ac177e-d57e-4f9e-9f0c-1551475f38fe','b28637f6-d330-444b-9675-330f80c0544b','54.244.51.0',0,0,'2025-11-06 22:27:54','inbound',0,'1','15'),
(130,'+19475176566','dsiptest.pstn.twilio.com','proj_LiCooyUxqKrHxGckhR34dpHR','sip.api.openai.com','','2025-11-06 22:59:57',52,'5fcb7c9013ea7dbf3a30f684b1657e81@0.0.0.0','86702273_c3356d0b_2a947246-c753-4199-b738-a29b235b39b8','922b5ed9-813d-4184-a551-28453e7357da','54.172.60.1',0,0,'2025-11-06 23:02:54','inbound',0,'1','15'),
(131,'+12484706952','dsiptest.pstn.twilio.com','proj_LiCooyUxqKrHxGckhR34dpHR','sip.api.openai.com','','2025-11-06 23:10:28',107,'0d2a3cd1a5934cdc2ff96e0c34a4ab26@0.0.0.0','61150832_c3356d0b_79a17045-2953-4bc3-a32f-576ebc7fcdf8','8410e585-f979-4f59-8c06-e40bb2e9302b','54.244.51.2',0,0,'2025-11-06 23:12:54','inbound',0,'1','15'),
(132,'+19475176566','dsiptest.pstn.twilio.com','proj_LiCooyUxqKrHxGckhR34dpHR','sip.api.openai.com','','2025-11-07 02:41:30',198,'b94e299e0869f1406cc9dca657d035a9@0.0.0.0','43151728_c3356d0b_057a8106-1333-4f24-9025-9182e57ca436','34fa9516-05e2-4e57-8f4b-69dd5bd9e80e','54.172.60.3',0,0,'2025-11-07 02:47:55','inbound',0,'1','15'),
(133,'+19475176566','dsiptest.pstn.twilio.com','proj_LiCooyUxqKrHxGckhR34dpHR','sip.api.openai.com','','2025-11-07 02:48:04',185,'046bc1cb7ba0d0b416b275fc75d420ea@0.0.0.0','25980171_c3356d0b_379fb503-8214-47ee-8a59-f1df4add2a6f','9b1ae7ac-3543-4184-a310-99a0757072e4','54.244.51.0',0,0,'2025-11-07 02:52:55','inbound',0,'1','15'),
(134,'+19475176566','dsiptest.pstn.twilio.com','proj_LiCooyUxqKrHxGckhR34dpHR','sip.api.openai.com','','2025-11-07 04:39:31',107,'85d4c57c076038ebc83e456505fde1d4@0.0.0.0','97319035_c3356d0b_24cd15b1-6170-4bf2-a975-af818e8ffe0a','e730805a-65e9-4813-bb4b-2e7e317a29f4','54.244.51.1',0,0,'2025-11-07 04:42:55','inbound',0,'1','15'),
(135,'+19475176566','dsiptest.pstn.twilio.com','proj_LiCooyUxqKrHxGckhR34dpHR','sip.api.openai.com','','2025-11-07 04:52:04',100,'781bf2b2bafeeaac7ce686fad84af3a5@0.0.0.0','69727179_c3356d0b_086df6d1-2e1c-4f4e-bc16-125d5587387e','25f4f47c-78a5-49a4-b5c4-2f233fd6fe55','54.244.51.1',0,0,'2025-11-07 04:57:55','inbound',0,'1','15'),
(136,'+19475176566','dsiptest.pstn.twilio.com','proj_LiCooyUxqKrHxGckhR34dpHR','sip.api.openai.com','','2025-11-07 04:54:48',90,'90eb0d24b4cf7db7dc44d194ea3fa5e9@0.0.0.0','22546849_c3356d0b_ffaf2828-e3df-4d76-87fc-a941923066c6','df8e3491-4d77-46fe-9f8a-1c5495d4d684','54.172.60.0',0,0,'2025-11-07 04:57:55','inbound',0,'1','15'),
(137,'+19475176566','dsiptest.pstn.twilio.com','proj_LiCooyUxqKrHxGckhR34dpHR','sip.api.openai.com','','2025-11-07 05:04:54',104,'46b4a2758b64ffd2b23370d035e285f8@0.0.0.0','01651560_c3356d0b_4cc3f51f-1f78-49c1-861b-130f719dd712','22d51d79-071e-4f6b-ba22-8011fe5d8b42','54.172.60.3',0,0,'2025-11-07 05:07:55','inbound',0,'1','15'),
(138,'+19475176566','dsiptest.pstn.twilio.com','proj_LiCooyUxqKrHxGckhR34dpHR','sip.api.openai.com','','2025-11-07 05:12:04',93,'3735b1e554fb77cd89b5e6468b34026d@0.0.0.0','03942965_c3356d0b_0b906301-9888-478a-8ae1-5a37b0f69122','b6426643-727e-4e5a-a8f8-cc8149f48a07','54.172.60.1',0,0,'2025-11-07 05:17:55','inbound',0,'1','15'),
(139,'+19475176566','dsiptest.pstn.twilio.com','proj_LiCooyUxqKrHxGckhR34dpHR','sip.api.openai.com','','2025-11-07 05:23:31',125,'cd9e1423a15fbccc7c056017d3d0f5bf@0.0.0.0','07070450_c3356d0b_fbefa2ae-8d74-414b-b176-28dd4d6917a4','9f5cdeff-2f03-4ff7-b645-6feb0d06d3dc','54.172.60.1',0,0,'2025-11-07 05:27:55','inbound',0,'1','15'),
(140,'+19475176566','dsiptest.pstn.twilio.com','proj_LiCooyUxqKrHxGckhR34dpHR','sip.api.openai.com','','2025-11-07 15:28:51',21,'5b0edaa9d8352c398d20aa06a3a8487d@0.0.0.0','18848176_c3356d0b_b8028e3f-c0be-4c26-bb7b-e998a05995fe','0977a571-2197-4045-b524-6f5ca1f3743a','54.172.60.3',0,0,'2025-11-07 15:32:56','inbound',0,'1','15'),
(141,'+19475176566','dsiptest.pstn.twilio.com','proj_LiCooyUxqKrHxGckhR34dpHR','sip.api.openai.com','','2025-11-07 15:29:18',15,'dbc915c7bd4bd02eb4e0a40c6877246a@0.0.0.0','80788238_c3356d0b_3f65f288-a4a6-40cf-80b8-0ffe1e9d0d45','2529451a-8c73-4bda-8a61-63a1c91f5ddc','54.172.60.1',0,0,'2025-11-07 15:32:56','inbound',0,'1','15'),
(142,'+19475176566','fl.gg','proj_MrxkZ5BlbAFrpJXiyZBrs6mq','sip.api.openai.com','','2025-11-07 15:29:43',22,'440414293_67069280@74.120.93.30','gK00211a7a','bb511a14-4c51-414b-bda6-54b4336417eb','34.226.36.32',0,0,'2025-11-07 15:32:56','inbound',0,'3','14'),
(143,'+19475176566','fl.gg','proj_MrxkZ5BlbAFrpJXiyZBrs6mq','sip.api.openai.com','','2025-11-07 15:30:11',12,'206052666_16230322@74.120.93.200','gK08090144','e830707a-0503-4ea4-9442-8194a489c406','34.226.36.34',0,0,'2025-11-07 15:32:56','inbound',0,'0','14'),
(144,'+19475176566','fl.gg','proj_MrxkZ5BlbAFrpJXiyZBrs6mq','sip.api.openai.com','','2025-11-07 15:31:36',30,'439143288_123547435@74.120.93.30','gK0c426757','4efdf566-e69e-4f47-a8a9-b429039d9473','34.226.36.33',0,0,'2025-11-07 15:32:56','inbound',0,'0','14'),
(145,'+19475176566','fl.gg','proj_MrxkZ5BlbAFrpJXiyZBrs6mq','sip.api.openai.com','','2025-11-07 15:39:40',13,'224411662_28298109@74.120.93.200','gK0076bae6','21a4e330-d027-4cc1-b4f6-4c10f72f84c8','34.226.36.34',0,0,'2025-11-07 15:42:56','inbound',0,'0','14'),
(146,'+19475176566','fl.gg','proj_MrxkZ5BlbAFrpJXiyZBrs6mq','sip.api.openai.com','','2025-11-07 15:41:00',16,'441203170_117435175@74.120.93.30','gK0c1b0b23','59039a7d-ec24-4120-8739-81934df5e0c9','34.226.36.34',0,0,'2025-11-07 15:42:56','inbound',0,'0','14'),
(147,'+19475176566','dsiptest.pstn.twilio.com','proj_LiCooyUxqKrHxGckhR34dpHR','sip.api.openai.com','','2025-11-07 21:46:52',68,'7ac1377658bb5825ec947ff1c684e289@0.0.0.0','80724980_c3356d0b_f82a8c56-458c-42f6-af63-94d21d29b089','734ccd43-eb48-4d75-b208-3f5d6b96d967','54.244.51.0',0,0,'2025-11-07 21:52:56','inbound',0,'1','15'),
(148,'+19475176566','dsiptest.pstn.twilio.com','proj_LiCooyUxqKrHxGckhR34dpHR','sip.api.openai.com','','2025-11-08 21:51:49',39,'3d1f7b95e4256df03347af4eaee63056@0.0.0.0','35032474_c3356d0b_2e08da86-06fb-482f-ade8-dc726b588cba','753e4e7e-4d87-4e38-a35b-68a309e517e9','54.244.51.2',0,0,'2025-11-08 21:52:59','inbound',0,'1','15'),
(149,'+19475176566','dsiptest.pstn.twilio.com','proj_LiCooyUxqKrHxGckhR34dpHR','sip.api.openai.com','','2025-11-09 02:33:32',8,'149a1901280ff526f7a8617350d3b210@0.0.0.0','77346911_c3356d0b_cb5ac895-7e42-4e9d-b653-443977c1a05e','f7d0ac41-6cac-49af-bcd7-f73f08dc004b','54.244.51.2',0,0,'2025-11-09 02:37:59','inbound',0,'1','15'),
(150,'+19475176566','dsiptest.pstn.twilio.com','proj_LiCooyUxqKrHxGckhR34dpHR','sip.api.openai.com','','2025-11-09 02:33:45',10,'7ae7c235ef8d7839c8e32e956d105caa@0.0.0.0','72027102_c3356d0b_47e939af-9d89-4a24-96da-8c46f428e5a8','9f92dd53-debb-4e33-ae0e-cde8bba339b6','54.172.60.0',0,0,'2025-11-09 02:37:59','inbound',0,'1','15'),
(151,'+13137891332','dsiptest.pstn.twilio.com','proj_LiCooyUxqKrHxGckhR34dpHR','sip.api.openai.com','','2025-11-09 03:12:22',97,'c941f786b6e8a63111f48037eb0ab331@0.0.0.0','10202309_c3356d0b_215e6dde-3414-4404-8a71-5bdd0ee21767','501a829f-14be-42b2-9ef0-a2a9c13d29bc','54.172.60.0',0,0,'2025-11-09 03:17:59','inbound',0,'1','15'),
(152,'+19475176566','dsiptest.pstn.twilio.com','proj_LiCooyUxqKrHxGckhR34dpHR','sip.api.openai.com','','2025-11-09 17:20:26',45,'dd936d469f1dfaba314317119a8de26d@0.0.0.0','12167175_c3356d0b_88524362-3ad7-4a50-aa2a-408ccf61fa6f','6e190b7a-171c-41a9-b1db-ff8e0ea78bbb','54.172.60.3',0,0,'2025-11-09 17:23:00','inbound',0,'1','15'),
(153,'+19475176566','dsiptest.pstn.twilio.com','proj_LiCooyUxqKrHxGckhR34dpHR','sip.api.openai.com','','2025-11-10 02:14:33',75,'fa36519e7787a2697b3d81b5072cd7c4@0.0.0.0','42579995_c3356d0b_40e96ec3-0d6c-487a-a801-a63a18f0f42c','8fc2ac5e-bc71-47a8-aa02-e7617f5e3a7a','54.244.51.2',0,0,'2025-11-10 02:18:01','inbound',0,'1','15'),
(154,'+18889072085','dsiptest.pstn.twilio.com','proj_LiCooyUxqKrHxGckhR34dpHR','sip.api.openai.com','','2025-11-10 02:14:52',60,'92c444c825065407774fcf2893009e16@0.0.0.0','83513978_c3356d0b_3aeda2fe-99d7-4992-be4b-222408309946','aae04739-e1a4-4a12-945b-42aeaefce961','54.172.60.3',0,0,'2025-11-10 02:18:01','inbound',0,'1','15'),
(155,'+19475176566','dsiptest.pstn.twilio.com','proj_LiCooyUxqKrHxGckhR34dpHR','sip.api.openai.com','','2025-11-11 00:14:52',104,'48a92e20629596731bbbbcaf3a87b825@0.0.0.0','24699296_c3356d0b_846f8a69-df00-4614-b2a7-2e2173c26d41','eb84e8e1-8fcb-403d-bce0-73094707458a','54.172.60.3',0,0,'2025-11-11 00:18:04','inbound',0,'1','15'),
(156,'+19475176566','dsiptest.pstn.twilio.com','proj_LiCooyUxqKrHxGckhR34dpHR','sip.api.openai.com','','2025-11-12 00:45:58',6,'84a1b32b5d6f45cd46f86870fdb09048@0.0.0.0','42358068_c3356d0b_4dfced61-4abf-41ec-8d1e-1432186db5e8','81b6316f-b9b4-42d8-8bdb-a3b90216e79a','54.244.51.2',0,0,'2025-11-12 00:48:06','inbound',0,'1','15'),
(157,'+19475176566','dsiptest.pstn.twilio.com','proj_s6OMBJOrj60XHHiK8nRjHrBi','sip.api.openai.com','','2025-11-12 00:54:24',13,'cc6629fe6c029bafa7ce1ae4191af44e@0.0.0.0','95972772_c3356d0b_872197f1-ee73-4ee4-ab33-ec5467971e13','867dd7ae-0a2b-485f-9345-18d93d42b3d1','54.244.51.2',0,0,'2025-11-12 00:58:06','inbound',0,'1','16'),
(158,'+19475176566','dsiptest.pstn.twilio.com','proj_s6OMBJOrj60XHHiK8nRjHrBi','sip.api.openai.com','','2025-11-12 00:58:19',20,'546adc20257ef707b6428692493b43e2@0.0.0.0','95714550_c3356d0b_62a8a806-343d-40bc-80f2-8d33df1237ca','cb9214e8-1b97-40a6-b4b6-9af2b2667bcd','54.244.51.1',0,0,'2025-11-12 01:03:06','inbound',0,'1','16'),
(159,'+18889072085','dsiptest.pstn.twilio.com','proj_s6OMBJOrj60XHHiK8nRjHrBi','sip.api.openai.com','','2025-11-12 01:00:16',43,'7c8960c3084a02b9d3d797e7f8dc79f9@0.0.0.0','07753033_c3356d0b_4c2f99a3-9fb9-4e9a-9302-997a903cc353','4f43fdbd-e0e5-4d94-8f46-c9eccab1bb7d','54.172.60.2',0,0,'2025-11-12 01:03:06','inbound',0,'1','16'),
(160,'+19475176566','dsiptest.pstn.twilio.com','proj_s6OMBJOrj60XHHiK8nRjHrBi','sip.api.openai.com','','2025-11-12 01:05:53',19,'a499769137c269b9986e9d594121aadc@0.0.0.0','89111610_c3356d0b_0b9f22b9-8491-4254-9110-abc7d90be086','ce2a68fb-37e4-4b88-a1ce-bbb53397a038','54.244.51.1',0,0,'2025-11-12 01:08:06','inbound',0,'1','16'),
(161,'+17348913376','dsiptest.pstn.twilio.com','proj_s6OMBJOrj60XHHiK8nRjHrBi','sip.api.openai.com','','2025-11-12 09:32:11',95,'caa09920c1cbf9111f39b24bb4ea940d@0.0.0.0','49980508_c3356d0b_321b5ff9-dd8e-4282-9c7f-9d54cae1390d','7d983873-d4e2-4cdc-9a8a-8dbe85f2e7fa','54.172.60.0',0,0,'2025-11-12 09:38:07','inbound',0,'1','16'),
(162,'+19475176566','dsiptest.pstn.twilio.com','proj_LiCooyUxqKrHxGckhR34dpHR','sip.api.openai.com','','2025-11-12 18:48:17',5,'6ee43c11870fe677a2abba16e967e838@0.0.0.0','70422377_c3356d0b_316656c8-a361-492e-84f1-5d751ee05b5e','24144629-c04d-46f7-a61c-70fa929cf0ec','54.172.60.0',0,0,'2025-11-12 18:53:08','inbound',0,'1','15'),
(163,'+19475176566','dsiptest.pstn.twilio.com','proj_LiCooyUxqKrHxGckhR34dpHR','sip.api.openai.com','','2025-11-12 18:48:28',106,'cb948c4e708591d2b5852bb7cc06314e@0.0.0.0','89775824_c3356d0b_4aac5e75-e466-465a-b818-4f070774c2b8','3cb1930e-24bf-491c-b261-b6a159c94bc9','54.244.51.2',0,0,'2025-11-12 18:53:08','inbound',0,'1','15'),
(164,'+19412530229','dsiptest.pstn.twilio.com','proj_LiCooyUxqKrHxGckhR34dpHR','sip.api.openai.com','','2025-11-18 17:57:52',105,'533af9c5d227f11e85dc72c8798eaf90@0.0.0.0','23895342_c3356d0b_20ed7cdc-41b5-4fbb-9d26-6363ceb1e3b6','48e7c530-7ed6-458e-99bd-6769fae4a729','54.172.60.1',0,0,'2025-11-18 18:03:21','inbound',0,'1','15'),
(165,'+19475176566','dsiptest.pstn.twilio.com','proj_LiCooyUxqKrHxGckhR34dpHR','sip.api.openai.com','','2025-11-20 02:31:46',99,'d9260cf9fa46bc70524ee72ba4d8ff8d@0.0.0.0','54884537_c3356d0b_bb5ae973-d585-4f35-993f-a588df91fc9c','8c7f9dbf-52c2-4c1f-bcf7-d95703ddf7b3','54.244.51.1',0,0,'2025-11-20 02:38:24','inbound',0,'1','15'),
(166,'+19475176566','dsiptest.pstn.twilio.com','proj_LiCooyUxqKrHxGckhR34dpHR','sip.api.openai.com','','2025-11-21 17:30:54',115,'fbad0ecc6bca86ff74d11baa600cc019@0.0.0.0','48650675_c3356d0b_85d70d37-accf-4113-ad2e-1010fea02cbf','c122302b-1b80-475f-8145-9f9fe7cb66e3','54.172.60.0',0,0,'2025-11-21 17:33:28','inbound',0,'1','15'),
(167,'+19475176566','dsiptest.pstn.twilio.com','proj_LiCooyUxqKrHxGckhR34dpHR','sip.api.openai.com','','2025-11-27 02:42:46',4,'c9b7bd479cec9b7566f7a92f57f76bb8@0.0.0.0','04310997_c3356d0b_61dc8585-d33c-4fd9-9f5f-387c566fba62','bc13bfd0-48da-40e5-803f-070b498632c7','54.172.60.3',0,0,'2025-11-27 02:43:41','inbound',0,'1','15'),
(168,'+19475176566','dsiptest.pstn.twilio.com','proj_LiCooyUxqKrHxGckhR34dpHR','sip.api.openai.com','','2025-12-02 05:10:56',4,'440a3bd3b23c421091af2cd423b744a1@0.0.0.0','13639243_c3356d0b_e6fc4e29-4ab7-448d-9d91-1503bf986860','3f3a90f8-a47b-448f-a691-d23dca1e45ab','54.244.51.1',0,0,'2025-12-02 05:13:54','inbound',0,'1','15'),
(169,'+19475176566','dsiptest.pstn.twilio.com','proj_LiCooyUxqKrHxGckhR34dpHR','sip.api.openai.com','','2025-12-10 02:59:34',8,'722125ff9f5502b64a70c8b6fd06434f@0.0.0.0','11350921_c3356d0b_a03ec9d6-2f84-4904-a97f-1b9194994c8c','4ffbd23f-e6d6-4a23-adff-a8141af683d1','54.172.60.0',0,0,'2025-12-10 03:04:14','inbound',0,'1','15'),
(170,'+19475176566','fl.gg','proj_a02nz7CJlhnK8WtZ2tS2xr2I','sip.api.openai.com','','2025-12-10 04:02:23',16,'457999576_53789002@207.223.78.224','gK0c7f1ac5','5bcf9e65-5185-40d2-a9f3-6fd47c4efe71','34.226.36.33',0,0,'2025-12-10 04:04:14','inbound',0,'0','17'),
(171,'+19475176566','fl.gg','proj_a02nz7CJlhnK8WtZ2tS2xr2I','sip.api.openai.com','','2025-12-10 04:03:38',86,'459321547_90105550@207.223.78.224','gK0033a9fb','ec56b582-e610-4677-aa8e-55a5103f5062','34.226.36.35',0,0,'2025-12-10 04:09:14','inbound',0,'0','17'),
(172,'+19475176566','fl.gg','proj_a02nz7CJlhnK8WtZ2tS2xr2I','sip.api.openai.com','','2025-12-10 04:05:14',37,'457999842_134201280@207.223.78.224','gK0c005e4b','ab47b548-e424-4ccf-976e-624887ae041f','34.226.36.34',0,0,'2025-12-10 04:09:14','inbound',0,'0','17'),
(173,'+19475176566','fl.gg','proj_a02nz7CJlhnK8WtZ2tS2xr2I','sip.api.openai.com','','2025-12-10 05:10:02',12,'452985810_132635370@207.223.78.224','gK00519790','617d139c-0a0a-4fb6-b8c0-afe4f035919a','34.226.36.32',0,0,'2025-12-10 05:14:14','inbound',0,'3','17'),
(174,'+19475176566','fl.gg','proj_a02nz7CJlhnK8WtZ2tS2xr2I','sip.api.openai.com','','2025-12-10 12:45:22',29,'453030322_129447068@207.223.78.224','gK00088617','649cfdd8-0a6d-47a9-8798-3613591ee066','34.226.36.33',0,0,'2025-12-10 12:49:15','inbound',0,'0','17'),
(175,'+19475176566','fl.gg','proj_a02nz7CJlhnK8WtZ2tS2xr2I','sip.api.openai.com','','2025-12-10 12:46:26',14,'453030472_125685836@207.223.78.224','gK000957ce','e8826c2c-6a87-42a0-a56e-5e153b90e677','34.226.36.33',0,0,'2025-12-10 12:49:15','inbound',0,'0','17'),
(176,'+19475176566','dsiptest.pstn.twilio.com','proj_LiCooyUxqKrHxGckhR34dpHR','sip.api.openai.com','','2025-12-12 16:29:14',3,'0b74e058e5c13ac06400675ecddf37ba@0.0.0.0','11021950_c3356d0b_27c519a8-2cce-4993-9aa3-efc819eb1631','605d48dc-bd6f-4fc7-ab93-3ec819ebdd1b','54.244.51.0',0,0,'2025-12-12 16:29:20','inbound',0,'1','15'),
(177,'+19475176566','dsiptest.pstn.twilio.com','proj_LiCooyUxqKrHxGckhR34dpHR','sip.api.openai.com','','2026-01-07 19:20:54',5,'4b2c5092aca1d77eee29e6b6d73e8b13@0.0.0.0','72610622_c3356d0b_3ec3bd26-5990-46a2-8312-0dd27b29f1fe','998aa569-25d4-445a-a294-6e2266688648','54.244.51.0',0,0,'2026-01-07 19:23:57','inbound',0,'1','15'),
(178,'+19475176566','dsiptest.pstn.twilio.com','proj_LiCooyUxqKrHxGckhR34dpHR','sip.api.openai.com','','2026-01-13 15:28:43',2,'6a4c62cf8ef3fc7f084b4b0c02666c3b@0.0.0.0','78703408_c3356d0b_a194cca8-c965-46c0-b39a-97a378793958','4b36b73c-c361-4425-b1b7-244183545c9d','54.172.60.2',0,0,'2026-01-13 15:29:13','inbound',0,'1','15'),
(179,'+19475176566','dsiptest.pstn.twilio.com','proj_LiCooyUxqKrHxGckhR34dpHR','sip.api.openai.com','','2026-01-13 16:24:05',81,'445393e0c36d1eebde62d61e8625dfc8@0.0.0.0','84362109_c3356d0b_1f919267-2179-4db6-8f8a-248802222a85','58305774-35a8-4215-ba1b-1ededeb2314e','54.244.51.0',0,0,'2026-01-13 16:29:13','inbound',0,'1','15'),
(180,'+13135901598','dsiptest.pstn.twilio.com','proj_s6OMBJOrj60XHHiK8nRjHrBi','sip.api.openai.com','','2026-01-16 22:46:46',9,'52c2441ceb0dfc635ad17960debf9357@0.0.0.0','25326200_c3356d0b_7d1e8907-6326-4286-bc88-22d9ff8b5223','4deaf16f-469e-41d9-9d94-8d4060cc5631','54.244.51.2',0,0,'2026-01-16 22:49:21','inbound',0,'1','16'),
(181,'+13135901598','dsiptest.pstn.twilio.com','proj_s6OMBJOrj60XHHiK8nRjHrBi','sip.api.openai.com','','2026-01-16 22:48:25',117,'2a59f99221a90d2d8e9693c1c8720188@0.0.0.0','53876459_c3356d0b_c3caa04a-1bae-4d8d-b8b3-0c438871bfde','ffe2394a-56ec-4d8d-9165-6c55dd5f6023','54.172.60.2',0,0,'2026-01-16 22:54:21','inbound',0,'1','16'),
(182,'+19475176566','dsiptest.pstn.twilio.com','proj_LiCooyUxqKrHxGckhR34dpHR','sip.api.openai.com','','2026-01-17 02:42:02',9,'7900600cd1da744f4efad35fa610bfbc@0.0.0.0','32068939_c3356d0b_aa9e876f-f821-44e2-8b5d-cf36dc98568b','e619d3c4-1ea3-4d6d-b304-8f2460f94b71','54.172.60.3',0,0,'2026-01-17 02:44:22','inbound',0,'1','15'),
(183,'+19797666651','dsiptest.pstn.twilio.com','proj_LiCooyUxqKrHxGckhR34dpHR','sip.api.openai.com','','2026-01-21 14:43:27',41,'45760eca8ce85481748951abce8a1fd5@0.0.0.0','83376219_c3356d0b_9381b1d5-ebd0-4416-8350-2c9cd38ce860','9d79e6a5-b863-4154-905a-c98b7c90c284','54.172.60.2',0,0,'2026-01-21 14:46:17','inbound',0,'1','15'),
(184,'+19475176566','dsiptest.pstn.twilio.com','proj_LiCooyUxqKrHxGckhR34dpHR','sip.api.openai.com','','2026-01-22 18:29:05',34,'6956023f71eb457911f6a0e3b08f773a@0.0.0.0','65344115_c3356d0b_a2684ffe-aba7-4802-9176-d33f5e097111','ae7817a9-1021-4d1f-ac3b-16f3377f30cd','54.244.51.0',0,0,'2026-01-22 18:31:20','inbound',0,'1','15'),
(185,'+19475176566','dsiptest.pstn.twilio.com','proj_LiCooyUxqKrHxGckhR34dpHR','sip.api.openai.com','','2026-01-22 18:32:30',9,'704a29a2c2d824b1784087704371543b@0.0.0.0','25654410_c3356d0b_51aefae0-967c-46c4-b87d-b73fc5c8f530','74d688a9-3def-4dcc-bfd4-773fdb76ab95','54.244.51.2',0,0,'2026-01-22 18:36:20','inbound',0,'1','15'),
(186,'+19475176566','dsiptest.pstn.twilio.com','proj_LiCooyUxqKrHxGckhR34dpHR','sip.api.openai.com','','2026-01-22 18:36:40',25,'a444fe9e5f6ab17aee2568854205326e@0.0.0.0','42888476_c3356d0b_af908d0d-ea79-47ae-8516-57c3a1ae5cc6','650fea33-f2d4-4ca9-8efa-e1909677d566','54.172.60.2',0,0,'2026-01-22 18:41:20','inbound',0,'1','15'),
(187,'+19475176566','fl.gg','proj_J7f6NK1rtMoZ0SXI9bbgLpOG','sip.api.openai.com','','2026-01-22 19:11:28',5,'237253123_83859365@207.223.78.224','gK047fc6b4','590169a1-3856-4cae-be8b-545e6b4fed00','34.226.36.33',0,0,'2026-01-22 19:16:20','inbound',0,'0','25'),
(188,'+19475176566','fl.gg','proj_J7f6NK1rtMoZ0SXI9bbgLpOG','sip.api.openai.com','','2026-01-22 19:11:37',38,'235705921_127836135@207.223.78.224','gK0c303025','66a36a61-9ccd-45b1-a1d9-ff820bc3fb3c','34.226.36.34',0,0,'2026-01-22 19:16:20','inbound',0,'0','25'),
(189,'+13133840357','fl.gg','proj_J7f6NK1rtMoZ0SXI9bbgLpOG','sip.api.openai.com','','2026-01-22 19:14:16',117,'237025578_104813816@207.223.78.224','gK001d22c9','ebf31b54-c146-4422-88b9-581bb0c9d831','34.226.36.35',0,0,'2026-01-22 19:16:20','inbound',0,'0','25'),
(190,'+13133840357','fl.gg','proj_J7f6NK1rtMoZ0SXI9bbgLpOG','sip.api.openai.com','','2026-01-22 19:16:21',21,'191632567_128855163@207.223.78.115','gK0c36e07f','ec8337d1-2651-4cd4-b2a4-ae1526b711c4','34.226.36.32',0,0,'2026-01-22 19:21:20','inbound',0,'3','25'),
(191,'+19475176566','fl.gg','proj_J7f6NK1rtMoZ0SXI9bbgLpOG','sip.api.openai.com','','2026-01-22 19:22:41',7,'239114900_29343149@207.223.78.224','gK007e087b','ca5e25d8-b373-4cf4-bd0e-e7ce0e80583b','34.226.36.32',0,0,'2026-01-22 19:26:20','inbound',0,'3','25'),
(192,'+19475176566','fl.gg','proj_J7f6NK1rtMoZ0SXI9bbgLpOG','sip.api.openai.com','','2026-01-22 19:22:52',16,'239351173_124618039@207.223.78.224','gK040135dc','00ca1ee7-819b-4e33-980a-53509f318546','34.226.36.35',0,0,'2026-01-22 19:26:20','inbound',0,'0','25'),
(193,'+19475176566','fl.gg','proj_J7f6NK1rtMoZ0SXI9bbgLpOG','sip.api.openai.com','','2026-01-22 19:23:29',19,'237805407_132898538@207.223.78.224','gK0c36bc96','ea281ccf-f9e1-4640-bbab-af0e2eb16f60','34.226.36.33',0,0,'2026-01-22 19:26:20','inbound',0,'0','25'),
(194,'+13133840357','fl.gg','proj_J7f6NK1rtMoZ0SXI9bbgLpOG','sip.api.openai.com','','2026-01-22 19:24:03',105,'239119087_124247948@207.223.78.224','gK000e0910','532d2bb2-f99f-42e3-ae84-5d3d1119e77e','34.226.36.35',0,0,'2026-01-22 19:26:20','inbound',0,'0','25'),
(195,'+19475176566','fl.gg','proj_J7f6NK1rtMoZ0SXI9bbgLpOG','sip.api.openai.com','','2026-01-22 19:32:54',45,'241736279_100474893@207.223.78.224','gK0808c680','14d167f0-2545-4316-a0b1-7bc90c42cf76','34.226.36.33',0,0,'2026-01-22 19:36:20','inbound',0,'0','25'),
(196,'+19475176566','dsiptest.pstn.twilio.com','proj_LiCooyUxqKrHxGckhR34dpHR','sip.api.openai.com','','2026-01-28 04:28:27',4,'b7a556658d650063672760c53e9a9b67@0.0.0.0','62623895_c3356d0b_5f33b687-a113-4043-a4fa-259b21bf4d60','2924a404-22f5-4561-b7e2-cdf7a0ffadae','54.244.51.1',0,0,'2026-01-28 04:31:35','inbound',0,'1','15'),
(197,'+13135292414','dsiptest.pstn.twilio.com','proj_s6OMBJOrj60XHHiK8nRjHrBi','sip.api.openai.com','','2026-02-03 15:10:25',7,'74fe895174087edffa2d0e427e7f4c48@0.0.0.0','35991848_c3356d0b_88937ca4-ec24-4a7b-841c-962769fe2679','61af183c-71c6-4cff-b424-ccf1e88f760d','54.244.51.2',0,0,'2026-02-03 15:11:53','inbound',0,'1','16'),
(198,'+13135766337','dsiptest.pstn.twilio.com','proj_s6OMBJOrj60XHHiK8nRjHrBi','sip.api.openai.com','','2026-02-10 20:29:34',30,'8a75b2fe9ee4fa30d0cb9465545adbd8@0.0.0.0','14798220_c3356d0b_1a8e5a75-31f9-410f-9f59-f6ae1a4a2642','355f7261-8d00-4511-a4b0-927f69aaec27','54.172.60.0',0,0,'2026-02-10 20:32:15','inbound',0,'1','16'),
(199,'+19475176566','dsiptest.pstn.twilio.com','proj_LiCooyUxqKrHxGckhR34dpHR','sip.api.openai.com','','2026-02-24 05:30:37',6,'bae8ea25989f9bac8bf905c26630c58c@0.0.0.0','46004185_c3356d0b_9840959b-5f3b-4689-b65c-99a5fd3ae3ca','d0ec18e0-165e-4989-80ec-dc8f37194636','54.244.51.2',0,0,'2026-02-24 05:33:00','inbound',0,'1','15'),
(200,'2485442883','34.210.91.112','16723617*19475176566','34.210.91.112','','2026-03-01 03:24:53',231,'r1Uz0vSn7PqFoJE-w13q_w..','ceb3bd49','gK04bcd30a','50.192.97.226',0,0,'2026-03-01 03:33:17','outbound',0,'32','3'),
(201,'2485442883','34.210.91.112','16723617*19475176566','34.210.91.112','','2026-03-01 03:30:42',24,'U2LVdSOPP0RldRiIyE7hRQ..','c63e972a','gK08de2f84','50.192.97.226',0,0,'2026-03-01 03:33:17','outbound',0,'32','3'),
(202,'2485442883','34.210.91.112','16723617*19475176566','34.210.91.112','','2026-03-01 03:32:20',28,'A0zMVhRPX9nHucFOdO8vOQ..','a6e56451','gK00be4442','50.192.97.226',0,0,'2026-03-01 03:33:18','outbound',0,'32','3'),
(203,'2485442883','34.210.91.112','16723617*19475176566','34.210.91.112','','2026-03-01 03:33:39',10,'rt1HicbxqQnIOkeXoYtrHQ..','ccf4455b','gK00b7a9c5','50.192.97.226',0,0,'2026-03-01 03:38:18','outbound',0,'32','3'),
(204,'2485442883','34.210.91.112','16723617*19475176566','34.210.91.112','','2026-03-01 03:42:16',27,'R3UjY_S89D6qEriCtBkEHA..','4b1e0a63','gK08e40453','50.192.97.226',0,0,'2026-03-01 03:43:18','outbound',0,'32','3'),
(205,'2485442883','34.210.91.112','16723617*19475176566','34.210.91.112','','2026-03-01 03:50:45',76,'_alf-FWZi169ezM97MwJEw..','6d13f650','gK08b38714','50.192.97.226',0,0,'2026-03-01 03:53:18','outbound',0,'32','3'),
(206,'2485442883','34.210.91.112','16723617*19475176566','34.210.91.112','','2026-03-01 13:49:15',30,'-lgmBdhZ8YL6hzEgIUJ2DQ..','07567a3d','gK049fbfa4','50.192.97.226',0,0,'2026-03-01 13:53:19','outbound',0,'32','3'),
(207,'2485442883','34.210.91.112','16723617*19475176566','34.210.91.112','','2026-03-01 13:58:40',154,'ScYmOAgyXm_93bYLNTTXwg..','5a6c1233','gK0cd1d6a5','50.192.97.226',0,0,'2026-03-01 14:03:19','outbound',0,'32','3'),
(208,'2485442883','34.210.91.112','16723617*19475176566','34.210.91.112','','2026-03-01 14:43:32',695,'Ea8L7V9SLSO-jwAvG-B9hA..','7a589663','gK04cfe849','50.192.97.226',0,0,'2026-03-01 14:58:20','outbound',0,'32','3'),
(209,'2485442883','34.210.91.112','16723617*19475176566','34.210.91.112','','2026-03-02 19:03:51',6,'KIiBNJ2i2LChdYFxdzEtlw..','9dd23706','gK0cb43896','50.192.97.226',0,0,'2026-03-02 19:07:30','outbound',0,'32','3'),
(210,'+19475176566','fl.gg','proj_a02nz7CJlhnK8WtZ2tS2xr2I','sip.api.openai.com','','2026-03-06 02:04:48',21,'172268154_66034116@207.223.78.224','gK042a189f','29cd5038-f7fd-4e00-9bf0-25005ce8d13a','34.226.36.33',0,0,'2026-03-06 02:07:44','inbound',0,'0','17'),
(211,'+19475176566','fl.gg','proj_a02nz7CJlhnK8WtZ2tS2xr2I','sip.api.openai.com','','2026-03-06 02:05:13',32,'172268299_16559243@207.223.78.224','gK042ab4e2','c9a89aac-ecb3-46cd-ad56-857607a26870','34.226.36.34',0,0,'2026-03-06 02:07:44','inbound',0,'0','17'),
(212,'+19475176566','fl.gg','proj_a02nz7CJlhnK8WtZ2tS2xr2I','sip.api.openai.com','','2026-03-06 02:09:00',6,'172494230_134069982@207.223.78.224','gK081d2ad3','f8c03d35-158b-4d2e-9da6-b83e68d8905e','34.226.36.32',0,0,'2026-03-06 02:12:44','inbound',0,'3','17'),
(213,'2485442883','34.210.91.112','16723617*19475176566','34.210.91.112','','2026-03-10 05:13:46',5,'D3CXEw0vdnb9PZVap-Q8fg..','7618523c','gK089291bb','50.192.97.226',0,0,'2026-03-10 05:15:20','outbound',0,'32','3'),
(214,'2485442883','34.210.91.112','16723617*19475176566','34.210.91.112','','2026-03-10 07:18:31',7,'ouuDR7AgxhoKCUNstqWQyA..','2d87536c','gK04f7bbe2','50.192.97.226',0,0,'2026-03-10 07:21:56','outbound',0,'32','3'),
(215,'2485442883','34.210.91.112','16723617*19475176566','34.210.91.112','','2026-03-10 07:19:04',2,'yxfkNUYHP-EL0mmQlBQY-w..','85b1684f','gK00a67f12','50.192.97.226',0,0,'2026-03-10 07:21:56','outbound',0,'32','3'),
(216,'2485442883','34.210.91.112','16723617*19475176566','34.210.91.112','','2026-03-10 07:21:35',17,'S6DxbcI9k9g-VQ4_eKIRNQ..','00d3e21c','gK04f8d719','50.192.97.226',0,0,'2026-03-10 07:21:56','outbound',0,'32','3'),
(217,'2485442883','34.210.91.112','16723617*19475176566','34.210.91.112','','2026-03-10 15:09:30',18,'lQP9XfmoFVf0xvQwOJHCCw..','d9528b4f','gK0cf5f13d','50.192.97.226',0,0,'2026-03-10 15:12:27','outbound',0,'32','3'),
(218,'+18889072085','fl.gg','proj_a02nz7CJlhnK8WtZ2tS2xr2I','sip.api.openai.com','','2026-03-10 15:24:19',19,'4765556_134200404@207.223.78.224','gK08411b79','681fc0fa-8bb2-4819-8ed3-fad3774c1a9e','34.226.36.32',0,0,'2026-03-10 15:27:28','inbound',0,'3','17'),
(219,'2485442883','34.210.91.112','16723617*19475176566','34.210.91.112','','2026-03-10 17:59:04',23,'oduihk_D4PB_81xIc17nww..','a9bf4d51','gK00c084c1','50.192.97.226',0,0,'2026-03-10 18:03:58','outbound',0,'32','3'),
(220,'2485442883','34.210.91.112','16723617*19475176566','34.210.91.112','','2026-03-11 02:16:04',17,'k07WV2pJEmV4nWR_DEBHoQ..','83589752','gK04f3c395','50.192.97.226',0,0,'2026-03-11 02:20:54','outbound',0,'32','3'),
(221,'2485442883','34.210.91.112','16723617*19475176566','34.210.91.112','','2026-03-11 21:45:25',7,'UoGgthPn7FKd6Bc17u-4GA..','2b3fca12','gK08d820ce','50.192.97.226',0,0,'2026-03-11 21:48:53','outbound',0,'32','3'),
(222,'2485442883','34.210.91.112','16723617*19475176566','34.210.91.112','','2026-03-12 02:02:24',27,'h0AYoIQ-K_QCM31Gm3HYFA..','1fbf3e2a','gK08c0449f','50.192.97.226',0,0,'2026-03-12 02:03:55','outbound',0,'32','3'),
(223,'2485442883','34.210.91.112','16723617*19475176566','34.210.91.112','','2026-03-12 03:09:08',12,'otCej5zN1puJypB_RTQsfQ..','b0c3e911','gK0ca59ac5','50.192.97.226',0,0,'2026-03-12 03:13:55','outbound',0,'32','3'),
(224,'+19475176566','fl.gg','proj_a02nz7CJlhnK8WtZ2tS2xr2I','sip.api.openai.com','','2026-03-12 16:19:45',17,'202149423_99049598@207.223.78.224','gK0c77e702','830e5556-77cc-4d36-825a-d4fe6f19943d','34.226.36.35',0,0,'2026-03-12 16:23:57','inbound',0,'0','17'),
(225,'+19475176566','fl.gg','proj_a02nz7CJlhnK8WtZ2tS2xr2I','sip.api.openai.com','','2026-03-12 19:26:16',10,'204250774_100646228@207.223.78.224','gK0c52e0eb','582d766f-473e-4333-a1e8-d1ed3870be05','34.226.36.33',0,0,'2026-03-12 19:28:58','inbound',0,'0','17');
/*!40000 ALTER TABLE `cdrs` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `cpl`
--

DROP TABLE IF EXISTS `cpl`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8mb4 */;
CREATE TABLE `cpl` (
  `id` int(10) unsigned NOT NULL AUTO_INCREMENT,
  `username` varchar(64) NOT NULL,
  `domain` varchar(64) NOT NULL DEFAULT '',
  `cpl_xml` text DEFAULT NULL,
  `cpl_bin` text DEFAULT NULL,
  PRIMARY KEY (`id`),
  UNIQUE KEY `account_idx` (`username`,`domain`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb3 COLLATE=utf8mb3_general_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `cpl`
--

LOCK TABLES `cpl` WRITE;
/*!40000 ALTER TABLE `cpl` DISABLE KEYS */;
/*!40000 ALTER TABLE `cpl` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `dbaliases`
--

DROP TABLE IF EXISTS `dbaliases`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8mb4 */;
CREATE TABLE `dbaliases` (
  `id` int(10) unsigned NOT NULL AUTO_INCREMENT,
  `alias_username` varchar(64) NOT NULL DEFAULT '',
  `alias_domain` varchar(64) NOT NULL DEFAULT '',
  `username` varchar(64) NOT NULL DEFAULT '',
  `domain` varchar(64) NOT NULL DEFAULT '',
  PRIMARY KEY (`id`),
  KEY `alias_user_idx` (`alias_username`),
  KEY `alias_idx` (`alias_username`,`alias_domain`),
  KEY `target_idx` (`username`,`domain`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb3 COLLATE=utf8mb3_general_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `dbaliases`
--

LOCK TABLES `dbaliases` WRITE;
/*!40000 ALTER TABLE `dbaliases` DISABLE KEYS */;
/*!40000 ALTER TABLE `dbaliases` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `dialog`
--

DROP TABLE IF EXISTS `dialog`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8mb4 */;
CREATE TABLE `dialog` (
  `id` int(10) unsigned NOT NULL AUTO_INCREMENT,
  `hash_entry` int(10) unsigned NOT NULL,
  `hash_id` int(10) unsigned NOT NULL,
  `callid` varchar(255) NOT NULL,
  `from_uri` varchar(255) NOT NULL,
  `from_tag` varchar(128) NOT NULL,
  `to_uri` varchar(255) NOT NULL,
  `to_tag` varchar(128) NOT NULL,
  `caller_cseq` varchar(20) NOT NULL,
  `callee_cseq` varchar(20) NOT NULL,
  `caller_route_set` varchar(512) DEFAULT NULL,
  `callee_route_set` varchar(512) DEFAULT NULL,
  `caller_contact` varchar(255) NOT NULL,
  `callee_contact` varchar(255) NOT NULL,
  `caller_sock` varchar(64) NOT NULL,
  `callee_sock` varchar(64) NOT NULL,
  `state` int(10) unsigned NOT NULL,
  `start_time` int(10) unsigned NOT NULL,
  `timeout` int(10) unsigned NOT NULL DEFAULT 0,
  `sflags` int(10) unsigned NOT NULL DEFAULT 0,
  `iflags` int(10) unsigned NOT NULL DEFAULT 0,
  `toroute_name` varchar(32) DEFAULT NULL,
  `req_uri` varchar(255) NOT NULL,
  `xdata` varchar(512) DEFAULT NULL,
  PRIMARY KEY (`id`),
  KEY `hash_idx` (`hash_entry`,`hash_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb3 COLLATE=utf8mb3_general_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `dialog`
--

LOCK TABLES `dialog` WRITE;
/*!40000 ALTER TABLE `dialog` DISABLE KEYS */;
/*!40000 ALTER TABLE `dialog` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `dialog_vars`
--

DROP TABLE IF EXISTS `dialog_vars`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8mb4 */;
CREATE TABLE `dialog_vars` (
  `id` int(10) unsigned NOT NULL AUTO_INCREMENT,
  `hash_entry` int(10) unsigned NOT NULL,
  `hash_id` int(10) unsigned NOT NULL,
  `dialog_key` varchar(128) NOT NULL,
  `dialog_value` varchar(512) NOT NULL,
  PRIMARY KEY (`id`),
  KEY `hash_idx` (`hash_entry`,`hash_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb3 COLLATE=utf8mb3_general_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `dialog_vars`
--

LOCK TABLES `dialog_vars` WRITE;
/*!40000 ALTER TABLE `dialog_vars` DISABLE KEYS */;
/*!40000 ALTER TABLE `dialog_vars` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `dialplan`
--

DROP TABLE IF EXISTS `dialplan`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8mb4 */;
CREATE TABLE `dialplan` (
  `id` int(10) unsigned NOT NULL AUTO_INCREMENT,
  `dpid` int(11) NOT NULL,
  `pr` int(11) NOT NULL,
  `match_op` int(11) NOT NULL,
  `match_exp` varchar(64) NOT NULL,
  `match_len` int(11) NOT NULL,
  `subst_exp` varchar(64) NOT NULL,
  `repl_exp` varchar(256) NOT NULL,
  `attrs` varchar(64) NOT NULL,
  PRIMARY KEY (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb3 COLLATE=utf8mb3_general_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `dialplan`
--

LOCK TABLES `dialplan` WRITE;
/*!40000 ALTER TABLE `dialplan` DISABLE KEYS */;
/*!40000 ALTER TABLE `dialplan` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `dispatcher`
--

DROP TABLE IF EXISTS `dispatcher`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8mb4 */;
CREATE TABLE `dispatcher` (
  `id` int(10) unsigned NOT NULL AUTO_INCREMENT,
  `setid` int(11) NOT NULL DEFAULT 0,
  `destination` varchar(192) NOT NULL DEFAULT '',
  `flags` int(11) NOT NULL DEFAULT 0,
  `priority` int(11) NOT NULL DEFAULT 0,
  `attrs` varchar(128) NOT NULL DEFAULT '',
  `description` varchar(255) NOT NULL DEFAULT '',
  PRIMARY KEY (`id`)
) ENGINE=InnoDB AUTO_INCREMENT=82 DEFAULT CHARSET=utf8mb3 COLLATE=utf8mb3_general_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `dispatcher`
--

LOCK TABLES `dispatcher` WRITE;
/*!40000 ALTER TABLE `dispatcher` DISABLE KEYS */;
INSERT INTO `dispatcher` VALUES
(1,1,'sip:54.172.60.0:5060',0,0,'signalling=proxy;media=proxy;rweight=1','name=Twilio NA-Virginia Carrier;gwid=1'),
(2,1,'sip:54.172.60.1:5060',0,0,'signalling=proxy;media=proxy;rweight=1','name=Twilio NA-Virginia  Carrier;gwid=2'),
(3,1,'sip:54.172.60.2:5060',0,0,'signalling=proxy;media=proxy;rweight=1','name=Twilio NA-Virginia Carrier;gwid=3'),
(4,1,'sip:54.172.60.3:5060',0,0,'signalling=proxy;media=proxy;rweight=1','name=Twilio NA-Virginia Carrier;gwid=4'),
(5,1,'sip:54.244.51.0:5060',0,0,'signalling=proxy;media=proxy;rweight=1','name=Twilio NA-Oregon Carrier;gwid=5'),
(6,1,'sip:54.244.51.1:5060',0,0,'signalling=proxy;media=proxy;rweight=1','name=Twilio NA-Oregon  Carrier;gwid=6'),
(7,1,'sip:54.244.51.2:5060',0,0,'signalling=proxy;media=proxy;rweight=1','name=Twilio NA-Oregon Carrier;gwid=7'),
(8,1,'sip:54.244.51.3:5060',0,0,'signalling=proxy;media=proxy;rweight=1','name=Twilio NA-Oregon Carrier;gwid=8'),
(9,2,'sip:52.41.52.34:5060',0,0,'signalling=proxy;media=proxy;rweight=1','name=Skyetel North West Inbound;gwid=9'),
(10,2,'sip:52.8.201.128:5060',0,0,'signalling=proxy;media=proxy;rweight=1','name=Skyetel South West Inbound;gwid=10'),
(11,2,'sip:52.60.138.31:5060',0,0,'signalling=proxy;media=proxy;rweight=1','name=Skyetel North East Inbound;gwid=11'),
(12,2,'sip:50.17.48.216:5060',0,0,'signalling=proxy;media=proxy;rweight=1','name=Skyetel South East Inbound;gwid=12'),
(13,2,'sip:35.156.192.164:5060',0,0,'signalling=proxy;media=proxy;rweight=1','name=Skyetel Europe Inbound;gwid=13'),
(14,2,'sip:sip.api.openai.com:5061;transport=tls',0,0,'signalling=proxy;media=proxy;rweight=1','name=Skyetel 1st Priority Outbound Call;gwid=14'),
(15,2,'sip:sip.api.openai.com:5061;transport=tls',0,0,'signalling=proxy;media=proxy;rweight=1','name=Skyetel 2nd Priority Outbound Call;gwid=15'),
(16,2,'sip:sip.api.openai.com:5061;transport=tls',0,0,'signalling=proxy;media=proxy;rweight=1','name=Skyetel 3rd Priority Outbound Call;gwid=16'),
(17,2,'sip:sip.api.openai.com:5061;transport=tls',0,0,'signalling=proxy;media=proxy;rweight=1','name=Skyetel 4rd Priority Outbound Call;gwid=17'),
(18,2,'sip:52.32.223.28:5060',0,0,'signalling=proxy;media=proxy;rweight=1','name=Skyetel North West High Cost Outbound Traffic;gwid=18'),
(19,2,'sip:52.4.178.107:5060',0,0,'signalling=proxy;media=proxy;rweight=1','name=Skyetel South East High Cost Outbound Traffic;gwid=19'),
(20,3,'sip:147.75.60.160:5060',0,0,'signalling=proxy;media=proxy;rweight=1','name=Flowroute US-West-WA;gwid=20'),
(21,3,'sip:34.210.91.112:5060',0,0,'signalling=proxy;media=proxy;rweight=1','name=Flowroute US-West-OR;gwid=21'),
(22,3,'sip:147.75.65.192:5060',0,0,'signalling=proxy;media=proxy;rweight=1','name=Flowroute US-East-NJ;gwid=22'),
(23,3,'sip:34.226.36.32:5060',0,0,'signalling=proxy;media=proxy;rweight=1','name=Flowroute US-East-VA;gwid=23'),
(24,4,'sip:81.201.82.45:5060',0,0,'signalling=proxy;media=proxy;rweight=1','name=Voxbone Belgium;gwid=24'),
(25,4,'sip:81.201.84.195:5060',0,0,'signalling=proxy;media=proxy;rweight=1','name=Voxbone LA;gwid=25'),
(26,4,'sip:81.201.85.45:5060',0,0,'signalling=proxy;media=proxy;rweight=1','name=Voxbone NYC;gwid=26'),
(27,4,'sip:81.201.83.45:5060',0,0,'signalling=proxy;media=proxy;rweight=1','name=Voxbone Germany;gwid=27'),
(28,4,'sip:81.201.86.45:5060',0,0,'signalling=proxy;media=proxy;rweight=1','name=Voxbone Hong Kong;gwid=28'),
(29,4,'sip:81.201.84.195:5060',0,0,'signalling=proxy;media=proxy;rweight=1','name=Voxbone Australia;gwid=29'),
(30,5,'sip:64.136.174.30:5060',0,0,'signalling=proxy;media=proxy;rweight=1','name=VoIP Innovations Inbound Carrier;gwid=30'),
(31,5,'sip:64.136.173.22:5060',0,0,'signalling=proxy;media=proxy;rweight=1','name=VoIP Innovations Inbound Carrier;gwid=31'),
(32,5,'sip:209.166.128.200:5060',0,0,'signalling=proxy;media=proxy;rweight=1','name=VoIP Innovations Inbound Carrier;gwid=32'),
(33,5,'sip:192.240.151.100:5060',0,0,'signalling=proxy;media=proxy;rweight=1','name=VoIP Innovations Inbound Carrier;gwid=33'),
(34,5,'sip:64.136.173.31:5060',0,0,'signalling=proxy;media=proxy;rweight=1','name=VoIP Innovations Inbound Carrier;gwid=34'),
(35,5,'sip:64.136.174.30:5060',0,0,'signalling=proxy;media=proxy;rweight=1','name=VoIP Innovations Inbound Carrier;gwid=35'),
(36,5,'sip:64.136.174.20:5060',0,0,'signalling=proxy;media=proxy;rweight=1','name=VoIP Innovations Inbound Carrier;gwid=36'),
(37,5,'sip:209.166.154.70:5060',0,0,'signalling=proxy;media=proxy;rweight=1','name=VoIP Innovations Inbound Carrier;gwid=37'),
(38,5,'sip:64.136.174.65:5060',0,0,'signalling=proxy;media=proxy;rweight=1','name=VoIP Innovations Inbound Carrier;gwid=38'),
(39,5,'sip:64.136.173.23:5060',0,0,'signalling=proxy;media=proxy;rweight=1','name=VoIP Innovations Inbound Carrier;gwid=39'),
(40,5,'sip:209.166.128.201:5060',0,0,'signalling=proxy;media=proxy;rweight=1','name=VoIP Innovations Inbound Carrier;gwid=40'),
(41,5,'sip:192.240.151.101:5060',0,0,'signalling=proxy;media=proxy;rweight=1','name=VoIP Innovations Inbound Carrier;gwid=41'),
(42,5,'sip:64.136.173.65:5060',0,0,'signalling=proxy;media=proxy;rweight=1','name=VoIP Innovations Inbound Carrier;gwid=42'),
(43,5,'sip:64.136.174.65:5060',0,0,'signalling=proxy;media=proxy;rweight=1','name=VoIP Innovations Inbound Carrier;gwid=43'),
(44,5,'sip:64.136.174.21:5060',0,0,'signalling=proxy;media=proxy;rweight=1','name=VoIP Innovations Inbound Carrier;gwid=44'),
(45,5,'sip:209.166.154.71:5060',0,0,'signalling=proxy;media=proxy;rweight=1','name=VoIP Innovations Inbound Carrier;gwid=45'),
(46,6,'sip:64.136.174.30:5060',0,0,'signalling=proxy;media=proxy;rweight=1','name=VoIP Innovations Outbound Conversational Carrier;gwid=46'),
(47,6,'sip:64.136.173.22:5060',0,0,'signalling=proxy;media=proxy;rweight=1','name=VoIP Innovations Outbound Conversational Carrier;gwid=47'),
(48,6,'sip:209.166.128.200:5060',0,0,'signalling=proxy;media=proxy;rweight=1','name=VoIP Innovations Outbound Conversational Carrier;gwid=48'),
(49,6,'sip:192.240.151.100:5060',0,0,'signalling=proxy;media=proxy;rweight=1','name=VoIP Innovations Outbound Conversational Carrier;gwid=49'),
(50,7,'sip:72.15.219.140:5060',0,0,'signalling=proxy;media=proxy;rweight=1','name=Thinq Carrier;gwid=50'),
(51,8,'sip:216.147.191.157:5060',0,0,'signalling=proxy;media=proxy;rweight=1','name=Voxtelesys Carrier;gwid=51'),
(52,9,'sip:64.34.181.47:5060',0,0,'signalling=proxy;media=proxy;rweight=1','name=Les.net Carrier;gwid=52'),
(53,10,'sip:206.80.250.100:5060',0,0,'signalling=proxy;media=proxy;rweight=1','name=ThinkTel;gwid=53'),
(54,10,'sip:208.68.17.52:5060',0,0,'signalling=proxy;media=proxy;rweight=1','name=ThinkTel;gwid=54'),
(55,10,'sip:209.197.130.80:5060',0,0,'signalling=proxy;media=proxy;rweight=1','name=ThinkTel;gwid=55'),
(56,11,'sip:freepbx.dsiprouter.net:5060',0,0,'signalling=proxy;media=proxy;rweight=1','name=;gwid=56'),
(57,12,'sip:sip.api.openai.com:5060',0,0,'signalling=proxy;media=proxy;rweight=1','name=OpenAI;gwid=57'),
(58,13,'sip:50.192.97.226:5060',0,0,'signalling=proxy;media=proxy;rweight=1','name=;gwid=58'),
(59,14,'sip:sip.api.openai.com:5061;transport=tls',0,0,'signalling=sips_tls;media=proxy;rweight=1;rU=proj_MrxkZ5BlbAFrpJXiyZBrs6mq','name=;gwid=59'),
(60,15,'sip:sip.api.openai.com:5061;transport=tls',0,0,'signalling=sips_tls;media=proxy;rweight=1;rU=proj_LiCooyUxqKrHxGckhR34dpHR','name=;gwid=60'),
(61,16,'sip:sip.api.openai.com:5061;transport=tls',0,0,'signalling=sips_tls;media=proxy;rweight=1;rU=proj_s6OMBJOrj60XHHiK8nRjHrBi','name=;gwid=61'),
(62,17,'sip:sip.api.openai.com:5061;transport=tls',0,0,'signalling=sips_tls;media=proxy;rweight=1;rU=proj_a02nz7CJlhnK8WtZ2tS2xr2I','name=;gwid=62'),
(63,18,'sip:192.168.1.100:5060',0,0,'signalling=proxy;media=proxy;rweight=1','name=FreePBX2;gwid=63'),
(64,19,'sip:50.192.97.226:5060',0,0,'signalling=proxy;media=proxy;rweight=1','name=HOA;gwid=64'),
(65,20,'sip:192.168.42.1:5060',0,0,'signalling=proxy;media=proxy;rweight=1','name=New Customer 546;gwid=65'),
(66,23,'sip:188.42.24.2:5060',0,0,'signalling=proxy;media=proxy;rweight=1','name=Mack\'s Endpoint;gwid=66'),
(67,24,'sip:204.24.24.22:5060',0,0,'signalling=proxy;media=proxy;rweight=1','name=Acme Company;gwid=67'),
(68,25,'sip:sip.api.openai.com:5061',0,0,'signalling=sips_tls;media=proxy;rweight=1;rU=proj_J7f6NK1rtMoZ0SXI9bbgLpOG','name=;gwid=68'),
(69,32,'sip:75.15.188.163:52042',4,0,'signalling=proxy;media=proxy;rweight=0','name=autoregister;gwid=154'),
(70,32,'sip:50.192.97.226:58917',4,0,'signalling=proxy;media=proxy;rweight=0','name=autoregister;gwid=239'),
(71,35,'sip:199.14.31.13:5060',0,0,'signalling=proxy;media=proxy;rweight=1','name=Gen1;gwid=290'),
(78,37,'sip:fusionpbx.dsiprouter.net:5060',0,0,'signalling=proxy;media=proxy;rweight=1','name='),
(79,1037,'sip:fusionpbx.dsiprouter.net:5080',0,0,'signalling=proxy;media=proxy;rweight=1','name='),
(80,37,'sip:demo.dsiprouter.net:5060',0,0,'signalling=proxy;media=proxy;rweight=1','name='),
(81,1037,'sip:demo.dsiprouter.net:5080',0,0,'signalling=proxy;media=proxy;rweight=1','name=');
/*!40000 ALTER TABLE `dispatcher` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `domain`
--

DROP TABLE IF EXISTS `domain`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8mb4 */;
CREATE TABLE `domain` (
  `id` int(10) unsigned NOT NULL AUTO_INCREMENT,
  `domain` varchar(64) NOT NULL,
  `did` varchar(64) DEFAULT NULL,
  `last_modified` datetime NOT NULL DEFAULT '2000-01-01 00:00:01',
  PRIMARY KEY (`id`),
  UNIQUE KEY `domain_idx` (`domain`)
) ENGINE=InnoDB AUTO_INCREMENT=74 DEFAULT CHARSET=utf8mb3 COLLATE=utf8mb3_general_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `domain`
--

LOCK TABLES `domain` WRITE;
/*!40000 ALTER TABLE `domain` DISABLE KEYS */;
INSERT INTO `domain` VALUES
(38,'dogfood.dsiprouter.net','dogfood.dsiprouter.net','2026-03-11 12:27:02'),
(39,'macktest.dsiprouter.net','macktest.dsiprouter.net','2026-03-11 12:27:02'),
(40,'pbx1.customers.dsiprouter.net','pbx1.customers.dsiprouter.net','2026-03-11 12:27:02'),
(41,'training.dsiprouter.net','training.dsiprouter.net','2026-03-11 12:27:02'),
(42,'AprilandMackCo','AprilandMackCo','2026-03-11 12:27:02'),
(43,'MackandCrewCo','MackandCrewCo','2026-03-11 12:27:02'),
(44,'domain.dsiprouter.net','domain.dsiprouter.net','2026-03-11 12:27:02'),
(45,'domain1.dsiprouter.net','domain1.dsiprouter.net','2026-03-11 12:27:02'),
(46,'domain2.dsiprouter.net','domain2.dsiprouter.net','2026-03-11 12:27:02'),
(47,'domain3.dsiprouter.net','domain3.dsiprouter.net','2026-03-11 12:27:02'),
(48,'domain4.dsiprouter.net','domain4.dsiprouter.net','2026-03-11 12:27:02'),
(49,'domain5.dsiprouter.net','domain5.dsiprouter.net','2026-03-11 12:27:02'),
(50,'domain6.dsiprouter.net','domain6.dsiprouter.net','2026-03-11 12:27:02'),
(51,'testing1.dsiprouter.net','testing1.dsiprouter.net','2026-03-11 12:27:02'),
(52,'testing2.dsiprouter.net','testing2.dsiprouter.net','2026-03-11 12:27:02'),
(53,'testing3.dsiprouter.net','testing3.dsiprouter.net','2026-03-11 12:27:02'),
(54,'testing4.dsiprouter.net','testing4.dsiprouter.net','2026-03-11 12:27:02'),
(55,'testing5.dsiprouter.net','testing5.dsiprouter.net','2026-03-11 12:27:02'),
(56,'testing10.dsiprouter.net','testing10.dsiprouter.net','2026-03-11 12:27:02'),
(57,'testing7.dsiprouter.net','testing7.dsiprouter.net','2026-03-11 12:27:02'),
(58,'testing8.dsiprouter.net','testing8.dsiprouter.net','2026-03-11 12:27:02'),
(59,'testing9.dsiprouter.net','testing9.dsiprouter.net','2026-03-11 12:27:02'),
(60,'testing13.dsiprouter.net','testing13.dsiprouter.net','2026-03-11 12:27:02'),
(61,'letsgo.dsiprouter.net','letsgo.dsiprouter.net','2026-03-11 12:27:02'),
(62,'miami.dsiprouter.net','miami.dsiprouter.net','2026-03-11 12:27:02'),
(63,'test.dsiprouter.net','test.dsiprouter.net','2026-03-11 12:27:02'),
(64,'macklevin.dsiprouter.net','macklevin.dsiprouter.net','2026-03-11 12:27:02'),
(65,'demo.dsiprouter.net','demo.dsiprouter.net','2026-03-11 12:27:02'),
(66,'fusionpbx.dsiprouter.net','fusionpbx.dsiprouter.net','2026-03-11 12:27:02'),
(67,'deb12-dev.dsiprouter.net','deb12-dev.dsiprouter.net','2026-03-11 12:27:02'),
(68,'centos9-dev.dsiprouter.net','centos9-dev.dsiprouter.net','2026-03-11 12:27:02'),
(69,'dealerb.xyz.com','dealerb.xyz.com','2026-03-11 12:27:02'),
(70,'linda.dsiprouter.net','linda.dsiprouter.net','2026-03-11 12:27:02'),
(71,'ese-test.dsiprouter.net','ese-test.dsiprouter.net','2026-03-11 12:27:02'),
(72,'meltapi.detroitpbx.com','meltapi.detroitpbx.com','2026-03-11 12:27:02'),
(73,'solo.orange64.com','solo.orange64.com','2026-03-11 12:27:02');
/*!40000 ALTER TABLE `domain` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `domain_attrs`
--

DROP TABLE IF EXISTS `domain_attrs`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8mb4 */;
CREATE TABLE `domain_attrs` (
  `id` int(10) unsigned NOT NULL AUTO_INCREMENT,
  `did` varchar(64) NOT NULL,
  `name` varchar(32) NOT NULL,
  `type` int(10) unsigned NOT NULL,
  `value` varchar(255) NOT NULL,
  `last_modified` datetime NOT NULL DEFAULT '2000-01-01 00:00:01',
  PRIMARY KEY (`id`),
  KEY `domain_attrs_idx` (`did`,`name`)
) ENGINE=InnoDB AUTO_INCREMENT=583 DEFAULT CHARSET=utf8mb3 COLLATE=utf8mb3_general_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `domain_attrs`
--

LOCK TABLES `domain_attrs` WRITE;
/*!40000 ALTER TABLE `domain_attrs` DISABLE KEYS */;
INSERT INTO `domain_attrs` VALUES
(295,'dogfood.dsiprouter.net','pbx_ip',2,'fusionpbx.dsiprouter.net:5060','2026-03-11 12:27:02'),
(296,'dogfood.dsiprouter.net','pbx_type',2,'2','2026-03-11 12:27:02'),
(297,'dogfood.dsiprouter.net','created_by',2,'37','2026-03-11 12:27:02'),
(298,'dogfood.dsiprouter.net','dispatcher_set_id',2,'37','2026-03-11 12:27:02'),
(299,'dogfood.dsiprouter.net','dispatcher_reg_alg',2,'4','2026-03-11 12:27:02'),
(300,'dogfood.dsiprouter.net','domain_auth',2,'passthru','2026-03-11 12:27:02'),
(301,'dogfood.dsiprouter.net','pbx_list',2,'37','2026-03-11 12:27:02'),
(302,'dogfood.dsiprouter.net','description',2,'notes:','2026-03-11 12:27:02'),
(303,'macktest.dsiprouter.net','pbx_ip',2,'fusionpbx.dsiprouter.net:5060','2026-03-11 12:27:02'),
(304,'macktest.dsiprouter.net','pbx_type',2,'2','2026-03-11 12:27:02'),
(305,'macktest.dsiprouter.net','created_by',2,'37','2026-03-11 12:27:02'),
(306,'macktest.dsiprouter.net','dispatcher_set_id',2,'37','2026-03-11 12:27:02'),
(307,'macktest.dsiprouter.net','dispatcher_reg_alg',2,'4','2026-03-11 12:27:02'),
(308,'macktest.dsiprouter.net','domain_auth',2,'passthru','2026-03-11 12:27:02'),
(309,'macktest.dsiprouter.net','pbx_list',2,'37','2026-03-11 12:27:02'),
(310,'macktest.dsiprouter.net','description',2,'notes:','2026-03-11 12:27:02'),
(311,'pbx1.customers.dsiprouter.net','pbx_ip',2,'fusionpbx.dsiprouter.net:5060','2026-03-11 12:27:02'),
(312,'pbx1.customers.dsiprouter.net','pbx_type',2,'2','2026-03-11 12:27:02'),
(313,'pbx1.customers.dsiprouter.net','created_by',2,'37','2026-03-11 12:27:02'),
(314,'pbx1.customers.dsiprouter.net','dispatcher_set_id',2,'37','2026-03-11 12:27:02'),
(315,'pbx1.customers.dsiprouter.net','dispatcher_reg_alg',2,'4','2026-03-11 12:27:02'),
(316,'pbx1.customers.dsiprouter.net','domain_auth',2,'passthru','2026-03-11 12:27:02'),
(317,'pbx1.customers.dsiprouter.net','pbx_list',2,'37','2026-03-11 12:27:02'),
(318,'pbx1.customers.dsiprouter.net','description',2,'notes:','2026-03-11 12:27:02'),
(319,'training.dsiprouter.net','pbx_ip',2,'fusionpbx.dsiprouter.net:5060','2026-03-11 12:27:02'),
(320,'training.dsiprouter.net','pbx_type',2,'2','2026-03-11 12:27:02'),
(321,'training.dsiprouter.net','created_by',2,'37','2026-03-11 12:27:02'),
(322,'training.dsiprouter.net','dispatcher_set_id',2,'37','2026-03-11 12:27:02'),
(323,'training.dsiprouter.net','dispatcher_reg_alg',2,'4','2026-03-11 12:27:02'),
(324,'training.dsiprouter.net','domain_auth',2,'passthru','2026-03-11 12:27:02'),
(325,'training.dsiprouter.net','pbx_list',2,'37','2026-03-11 12:27:02'),
(326,'training.dsiprouter.net','description',2,'notes:','2026-03-11 12:27:02'),
(327,'AprilandMackCo','pbx_ip',2,'fusionpbx.dsiprouter.net:5060','2026-03-11 12:27:02'),
(328,'AprilandMackCo','pbx_type',2,'2','2026-03-11 12:27:02'),
(329,'AprilandMackCo','created_by',2,'37','2026-03-11 12:27:02'),
(330,'AprilandMackCo','dispatcher_set_id',2,'37','2026-03-11 12:27:02'),
(331,'AprilandMackCo','dispatcher_reg_alg',2,'4','2026-03-11 12:27:02'),
(332,'AprilandMackCo','domain_auth',2,'passthru','2026-03-11 12:27:02'),
(333,'AprilandMackCo','pbx_list',2,'37','2026-03-11 12:27:02'),
(334,'AprilandMackCo','description',2,'notes:','2026-03-11 12:27:02'),
(335,'MackandCrewCo','pbx_ip',2,'fusionpbx.dsiprouter.net:5060','2026-03-11 12:27:02'),
(336,'MackandCrewCo','pbx_type',2,'2','2026-03-11 12:27:02'),
(337,'MackandCrewCo','created_by',2,'37','2026-03-11 12:27:02'),
(338,'MackandCrewCo','dispatcher_set_id',2,'37','2026-03-11 12:27:02'),
(339,'MackandCrewCo','dispatcher_reg_alg',2,'4','2026-03-11 12:27:02'),
(340,'MackandCrewCo','domain_auth',2,'passthru','2026-03-11 12:27:02'),
(341,'MackandCrewCo','pbx_list',2,'37','2026-03-11 12:27:02'),
(342,'MackandCrewCo','description',2,'notes:','2026-03-11 12:27:02'),
(343,'domain.dsiprouter.net','pbx_ip',2,'fusionpbx.dsiprouter.net:5060','2026-03-11 12:27:02'),
(344,'domain.dsiprouter.net','pbx_type',2,'2','2026-03-11 12:27:02'),
(345,'domain.dsiprouter.net','created_by',2,'37','2026-03-11 12:27:02'),
(346,'domain.dsiprouter.net','dispatcher_set_id',2,'37','2026-03-11 12:27:02'),
(347,'domain.dsiprouter.net','dispatcher_reg_alg',2,'4','2026-03-11 12:27:02'),
(348,'domain.dsiprouter.net','domain_auth',2,'passthru','2026-03-11 12:27:02'),
(349,'domain.dsiprouter.net','pbx_list',2,'37','2026-03-11 12:27:02'),
(350,'domain.dsiprouter.net','description',2,'notes:','2026-03-11 12:27:02'),
(351,'domain1.dsiprouter.net','pbx_ip',2,'fusionpbx.dsiprouter.net:5060','2026-03-11 12:27:02'),
(352,'domain1.dsiprouter.net','pbx_type',2,'2','2026-03-11 12:27:02'),
(353,'domain1.dsiprouter.net','created_by',2,'37','2026-03-11 12:27:02'),
(354,'domain1.dsiprouter.net','dispatcher_set_id',2,'37','2026-03-11 12:27:02'),
(355,'domain1.dsiprouter.net','dispatcher_reg_alg',2,'4','2026-03-11 12:27:02'),
(356,'domain1.dsiprouter.net','domain_auth',2,'passthru','2026-03-11 12:27:02'),
(357,'domain1.dsiprouter.net','pbx_list',2,'37','2026-03-11 12:27:02'),
(358,'domain1.dsiprouter.net','description',2,'notes:','2026-03-11 12:27:02'),
(359,'domain2.dsiprouter.net','pbx_ip',2,'fusionpbx.dsiprouter.net:5060','2026-03-11 12:27:02'),
(360,'domain2.dsiprouter.net','pbx_type',2,'2','2026-03-11 12:27:02'),
(361,'domain2.dsiprouter.net','created_by',2,'37','2026-03-11 12:27:02'),
(362,'domain2.dsiprouter.net','dispatcher_set_id',2,'37','2026-03-11 12:27:02'),
(363,'domain2.dsiprouter.net','dispatcher_reg_alg',2,'4','2026-03-11 12:27:02'),
(364,'domain2.dsiprouter.net','domain_auth',2,'passthru','2026-03-11 12:27:02'),
(365,'domain2.dsiprouter.net','pbx_list',2,'37','2026-03-11 12:27:02'),
(366,'domain2.dsiprouter.net','description',2,'notes:','2026-03-11 12:27:02'),
(367,'domain3.dsiprouter.net','pbx_ip',2,'fusionpbx.dsiprouter.net:5060','2026-03-11 12:27:02'),
(368,'domain3.dsiprouter.net','pbx_type',2,'2','2026-03-11 12:27:02'),
(369,'domain3.dsiprouter.net','created_by',2,'37','2026-03-11 12:27:02'),
(370,'domain3.dsiprouter.net','dispatcher_set_id',2,'37','2026-03-11 12:27:02'),
(371,'domain3.dsiprouter.net','dispatcher_reg_alg',2,'4','2026-03-11 12:27:02'),
(372,'domain3.dsiprouter.net','domain_auth',2,'passthru','2026-03-11 12:27:02'),
(373,'domain3.dsiprouter.net','pbx_list',2,'37','2026-03-11 12:27:02'),
(374,'domain3.dsiprouter.net','description',2,'notes:','2026-03-11 12:27:02'),
(375,'domain4.dsiprouter.net','pbx_ip',2,'fusionpbx.dsiprouter.net:5060','2026-03-11 12:27:02'),
(376,'domain4.dsiprouter.net','pbx_type',2,'2','2026-03-11 12:27:02'),
(377,'domain4.dsiprouter.net','created_by',2,'37','2026-03-11 12:27:02'),
(378,'domain4.dsiprouter.net','dispatcher_set_id',2,'37','2026-03-11 12:27:02'),
(379,'domain4.dsiprouter.net','dispatcher_reg_alg',2,'4','2026-03-11 12:27:02'),
(380,'domain4.dsiprouter.net','domain_auth',2,'passthru','2026-03-11 12:27:02'),
(381,'domain4.dsiprouter.net','pbx_list',2,'37','2026-03-11 12:27:02'),
(382,'domain4.dsiprouter.net','description',2,'notes:','2026-03-11 12:27:02'),
(383,'domain5.dsiprouter.net','pbx_ip',2,'fusionpbx.dsiprouter.net:5060','2026-03-11 12:27:02'),
(384,'domain5.dsiprouter.net','pbx_type',2,'2','2026-03-11 12:27:02'),
(385,'domain5.dsiprouter.net','created_by',2,'37','2026-03-11 12:27:02'),
(386,'domain5.dsiprouter.net','dispatcher_set_id',2,'37','2026-03-11 12:27:02'),
(387,'domain5.dsiprouter.net','dispatcher_reg_alg',2,'4','2026-03-11 12:27:02'),
(388,'domain5.dsiprouter.net','domain_auth',2,'passthru','2026-03-11 12:27:02'),
(389,'domain5.dsiprouter.net','pbx_list',2,'37','2026-03-11 12:27:02'),
(390,'domain5.dsiprouter.net','description',2,'notes:','2026-03-11 12:27:02'),
(391,'domain6.dsiprouter.net','pbx_ip',2,'fusionpbx.dsiprouter.net:5060','2026-03-11 12:27:02'),
(392,'domain6.dsiprouter.net','pbx_type',2,'2','2026-03-11 12:27:02'),
(393,'domain6.dsiprouter.net','created_by',2,'37','2026-03-11 12:27:02'),
(394,'domain6.dsiprouter.net','dispatcher_set_id',2,'37','2026-03-11 12:27:02'),
(395,'domain6.dsiprouter.net','dispatcher_reg_alg',2,'4','2026-03-11 12:27:02'),
(396,'domain6.dsiprouter.net','domain_auth',2,'passthru','2026-03-11 12:27:02'),
(397,'domain6.dsiprouter.net','pbx_list',2,'37','2026-03-11 12:27:02'),
(398,'domain6.dsiprouter.net','description',2,'notes:','2026-03-11 12:27:02'),
(399,'testing1.dsiprouter.net','pbx_ip',2,'fusionpbx.dsiprouter.net:5060','2026-03-11 12:27:02'),
(400,'testing1.dsiprouter.net','pbx_type',2,'2','2026-03-11 12:27:02'),
(401,'testing1.dsiprouter.net','created_by',2,'37','2026-03-11 12:27:02'),
(402,'testing1.dsiprouter.net','dispatcher_set_id',2,'37','2026-03-11 12:27:02'),
(403,'testing1.dsiprouter.net','dispatcher_reg_alg',2,'4','2026-03-11 12:27:02'),
(404,'testing1.dsiprouter.net','domain_auth',2,'passthru','2026-03-11 12:27:02'),
(405,'testing1.dsiprouter.net','pbx_list',2,'37','2026-03-11 12:27:02'),
(406,'testing1.dsiprouter.net','description',2,'notes:','2026-03-11 12:27:02'),
(407,'testing2.dsiprouter.net','pbx_ip',2,'fusionpbx.dsiprouter.net:5060','2026-03-11 12:27:02'),
(408,'testing2.dsiprouter.net','pbx_type',2,'2','2026-03-11 12:27:02'),
(409,'testing2.dsiprouter.net','created_by',2,'37','2026-03-11 12:27:02'),
(410,'testing2.dsiprouter.net','dispatcher_set_id',2,'37','2026-03-11 12:27:02'),
(411,'testing2.dsiprouter.net','dispatcher_reg_alg',2,'4','2026-03-11 12:27:02'),
(412,'testing2.dsiprouter.net','domain_auth',2,'passthru','2026-03-11 12:27:02'),
(413,'testing2.dsiprouter.net','pbx_list',2,'37','2026-03-11 12:27:02'),
(414,'testing2.dsiprouter.net','description',2,'notes:','2026-03-11 12:27:02'),
(415,'testing3.dsiprouter.net','pbx_ip',2,'fusionpbx.dsiprouter.net:5060','2026-03-11 12:27:02'),
(416,'testing3.dsiprouter.net','pbx_type',2,'2','2026-03-11 12:27:02'),
(417,'testing3.dsiprouter.net','created_by',2,'37','2026-03-11 12:27:02'),
(418,'testing3.dsiprouter.net','dispatcher_set_id',2,'37','2026-03-11 12:27:02'),
(419,'testing3.dsiprouter.net','dispatcher_reg_alg',2,'4','2026-03-11 12:27:02'),
(420,'testing3.dsiprouter.net','domain_auth',2,'passthru','2026-03-11 12:27:02'),
(421,'testing3.dsiprouter.net','pbx_list',2,'37','2026-03-11 12:27:02'),
(422,'testing3.dsiprouter.net','description',2,'notes:','2026-03-11 12:27:02'),
(423,'testing4.dsiprouter.net','pbx_ip',2,'fusionpbx.dsiprouter.net:5060','2026-03-11 12:27:02'),
(424,'testing4.dsiprouter.net','pbx_type',2,'2','2026-03-11 12:27:02'),
(425,'testing4.dsiprouter.net','created_by',2,'37','2026-03-11 12:27:02'),
(426,'testing4.dsiprouter.net','dispatcher_set_id',2,'37','2026-03-11 12:27:02'),
(427,'testing4.dsiprouter.net','dispatcher_reg_alg',2,'4','2026-03-11 12:27:02'),
(428,'testing4.dsiprouter.net','domain_auth',2,'passthru','2026-03-11 12:27:02'),
(429,'testing4.dsiprouter.net','pbx_list',2,'37','2026-03-11 12:27:02'),
(430,'testing4.dsiprouter.net','description',2,'notes:','2026-03-11 12:27:02'),
(431,'testing5.dsiprouter.net','pbx_ip',2,'fusionpbx.dsiprouter.net:5060','2026-03-11 12:27:02'),
(432,'testing5.dsiprouter.net','pbx_type',2,'2','2026-03-11 12:27:02'),
(433,'testing5.dsiprouter.net','created_by',2,'37','2026-03-11 12:27:02'),
(434,'testing5.dsiprouter.net','dispatcher_set_id',2,'37','2026-03-11 12:27:02'),
(435,'testing5.dsiprouter.net','dispatcher_reg_alg',2,'4','2026-03-11 12:27:02'),
(436,'testing5.dsiprouter.net','domain_auth',2,'passthru','2026-03-11 12:27:02'),
(437,'testing5.dsiprouter.net','pbx_list',2,'37','2026-03-11 12:27:02'),
(438,'testing5.dsiprouter.net','description',2,'notes:','2026-03-11 12:27:02'),
(439,'testing10.dsiprouter.net','pbx_ip',2,'fusionpbx.dsiprouter.net:5060','2026-03-11 12:27:02'),
(440,'testing10.dsiprouter.net','pbx_type',2,'2','2026-03-11 12:27:02'),
(441,'testing10.dsiprouter.net','created_by',2,'37','2026-03-11 12:27:02'),
(442,'testing10.dsiprouter.net','dispatcher_set_id',2,'37','2026-03-11 12:27:02'),
(443,'testing10.dsiprouter.net','dispatcher_reg_alg',2,'4','2026-03-11 12:27:02'),
(444,'testing10.dsiprouter.net','domain_auth',2,'passthru','2026-03-11 12:27:02'),
(445,'testing10.dsiprouter.net','pbx_list',2,'37','2026-03-11 12:27:02'),
(446,'testing10.dsiprouter.net','description',2,'notes:','2026-03-11 12:27:02'),
(447,'testing7.dsiprouter.net','pbx_ip',2,'fusionpbx.dsiprouter.net:5060','2026-03-11 12:27:02'),
(448,'testing7.dsiprouter.net','pbx_type',2,'2','2026-03-11 12:27:02'),
(449,'testing7.dsiprouter.net','created_by',2,'37','2026-03-11 12:27:02'),
(450,'testing7.dsiprouter.net','dispatcher_set_id',2,'37','2026-03-11 12:27:02'),
(451,'testing7.dsiprouter.net','dispatcher_reg_alg',2,'4','2026-03-11 12:27:02'),
(452,'testing7.dsiprouter.net','domain_auth',2,'passthru','2026-03-11 12:27:02'),
(453,'testing7.dsiprouter.net','pbx_list',2,'37','2026-03-11 12:27:02'),
(454,'testing7.dsiprouter.net','description',2,'notes:','2026-03-11 12:27:02'),
(455,'testing8.dsiprouter.net','pbx_ip',2,'fusionpbx.dsiprouter.net:5060','2026-03-11 12:27:02'),
(456,'testing8.dsiprouter.net','pbx_type',2,'2','2026-03-11 12:27:02'),
(457,'testing8.dsiprouter.net','created_by',2,'37','2026-03-11 12:27:02'),
(458,'testing8.dsiprouter.net','dispatcher_set_id',2,'37','2026-03-11 12:27:02'),
(459,'testing8.dsiprouter.net','dispatcher_reg_alg',2,'4','2026-03-11 12:27:02'),
(460,'testing8.dsiprouter.net','domain_auth',2,'passthru','2026-03-11 12:27:02'),
(461,'testing8.dsiprouter.net','pbx_list',2,'37','2026-03-11 12:27:02'),
(462,'testing8.dsiprouter.net','description',2,'notes:','2026-03-11 12:27:02'),
(463,'testing9.dsiprouter.net','pbx_ip',2,'fusionpbx.dsiprouter.net:5060','2026-03-11 12:27:02'),
(464,'testing9.dsiprouter.net','pbx_type',2,'2','2026-03-11 12:27:02'),
(465,'testing9.dsiprouter.net','created_by',2,'37','2026-03-11 12:27:02'),
(466,'testing9.dsiprouter.net','dispatcher_set_id',2,'37','2026-03-11 12:27:02'),
(467,'testing9.dsiprouter.net','dispatcher_reg_alg',2,'4','2026-03-11 12:27:02'),
(468,'testing9.dsiprouter.net','domain_auth',2,'passthru','2026-03-11 12:27:02'),
(469,'testing9.dsiprouter.net','pbx_list',2,'37','2026-03-11 12:27:02'),
(470,'testing9.dsiprouter.net','description',2,'notes:','2026-03-11 12:27:02'),
(471,'testing13.dsiprouter.net','pbx_ip',2,'fusionpbx.dsiprouter.net:5060','2026-03-11 12:27:02'),
(472,'testing13.dsiprouter.net','pbx_type',2,'2','2026-03-11 12:27:02'),
(473,'testing13.dsiprouter.net','created_by',2,'37','2026-03-11 12:27:02'),
(474,'testing13.dsiprouter.net','dispatcher_set_id',2,'37','2026-03-11 12:27:02'),
(475,'testing13.dsiprouter.net','dispatcher_reg_alg',2,'4','2026-03-11 12:27:02'),
(476,'testing13.dsiprouter.net','domain_auth',2,'passthru','2026-03-11 12:27:02'),
(477,'testing13.dsiprouter.net','pbx_list',2,'37','2026-03-11 12:27:02'),
(478,'testing13.dsiprouter.net','description',2,'notes:','2026-03-11 12:27:02'),
(479,'letsgo.dsiprouter.net','pbx_ip',2,'fusionpbx.dsiprouter.net:5060','2026-03-11 12:27:02'),
(480,'letsgo.dsiprouter.net','pbx_type',2,'2','2026-03-11 12:27:02'),
(481,'letsgo.dsiprouter.net','created_by',2,'37','2026-03-11 12:27:02'),
(482,'letsgo.dsiprouter.net','dispatcher_set_id',2,'37','2026-03-11 12:27:02'),
(483,'letsgo.dsiprouter.net','dispatcher_reg_alg',2,'4','2026-03-11 12:27:02'),
(484,'letsgo.dsiprouter.net','domain_auth',2,'passthru','2026-03-11 12:27:02'),
(485,'letsgo.dsiprouter.net','pbx_list',2,'37','2026-03-11 12:27:02'),
(486,'letsgo.dsiprouter.net','description',2,'notes:','2026-03-11 12:27:02'),
(487,'miami.dsiprouter.net','pbx_ip',2,'fusionpbx.dsiprouter.net:5060','2026-03-11 12:27:02'),
(488,'miami.dsiprouter.net','pbx_type',2,'2','2026-03-11 12:27:02'),
(489,'miami.dsiprouter.net','created_by',2,'37','2026-03-11 12:27:02'),
(490,'miami.dsiprouter.net','dispatcher_set_id',2,'37','2026-03-11 12:27:02'),
(491,'miami.dsiprouter.net','dispatcher_reg_alg',2,'4','2026-03-11 12:27:02'),
(492,'miami.dsiprouter.net','domain_auth',2,'passthru','2026-03-11 12:27:02'),
(493,'miami.dsiprouter.net','pbx_list',2,'37','2026-03-11 12:27:02'),
(494,'miami.dsiprouter.net','description',2,'notes:','2026-03-11 12:27:02'),
(495,'test.dsiprouter.net','pbx_ip',2,'fusionpbx.dsiprouter.net:5060','2026-03-11 12:27:02'),
(496,'test.dsiprouter.net','pbx_type',2,'2','2026-03-11 12:27:02'),
(497,'test.dsiprouter.net','created_by',2,'37','2026-03-11 12:27:02'),
(498,'test.dsiprouter.net','dispatcher_set_id',2,'37','2026-03-11 12:27:02'),
(499,'test.dsiprouter.net','dispatcher_reg_alg',2,'4','2026-03-11 12:27:02'),
(500,'test.dsiprouter.net','domain_auth',2,'passthru','2026-03-11 12:27:02'),
(501,'test.dsiprouter.net','pbx_list',2,'37','2026-03-11 12:27:02'),
(502,'test.dsiprouter.net','description',2,'notes:','2026-03-11 12:27:02'),
(503,'macklevin.dsiprouter.net','pbx_ip',2,'fusionpbx.dsiprouter.net:5060','2026-03-11 12:27:02'),
(504,'macklevin.dsiprouter.net','pbx_type',2,'2','2026-03-11 12:27:02'),
(505,'macklevin.dsiprouter.net','created_by',2,'37','2026-03-11 12:27:02'),
(506,'macklevin.dsiprouter.net','dispatcher_set_id',2,'37','2026-03-11 12:27:02'),
(507,'macklevin.dsiprouter.net','dispatcher_reg_alg',2,'4','2026-03-11 12:27:02'),
(508,'macklevin.dsiprouter.net','domain_auth',2,'passthru','2026-03-11 12:27:02'),
(509,'macklevin.dsiprouter.net','pbx_list',2,'37','2026-03-11 12:27:02'),
(510,'macklevin.dsiprouter.net','description',2,'notes:','2026-03-11 12:27:02'),
(511,'demo.dsiprouter.net','pbx_ip',2,'fusionpbx.dsiprouter.net:5060','2026-03-11 12:27:02'),
(512,'demo.dsiprouter.net','pbx_type',2,'2','2026-03-11 12:27:02'),
(513,'demo.dsiprouter.net','created_by',2,'37','2026-03-11 12:27:02'),
(514,'demo.dsiprouter.net','dispatcher_set_id',2,'37','2026-03-11 12:27:02'),
(515,'demo.dsiprouter.net','dispatcher_reg_alg',2,'4','2026-03-11 12:27:02'),
(516,'demo.dsiprouter.net','domain_auth',2,'passthru','2026-03-11 12:27:02'),
(517,'demo.dsiprouter.net','pbx_list',2,'37','2026-03-11 12:27:02'),
(518,'demo.dsiprouter.net','description',2,'notes:','2026-03-11 12:27:02'),
(519,'fusionpbx.dsiprouter.net','pbx_ip',2,'fusionpbx.dsiprouter.net:5060','2026-03-11 12:27:02'),
(520,'fusionpbx.dsiprouter.net','pbx_type',2,'2','2026-03-11 12:27:02'),
(521,'fusionpbx.dsiprouter.net','created_by',2,'37','2026-03-11 12:27:02'),
(522,'fusionpbx.dsiprouter.net','dispatcher_set_id',2,'37','2026-03-11 12:27:02'),
(523,'fusionpbx.dsiprouter.net','dispatcher_reg_alg',2,'4','2026-03-11 12:27:02'),
(524,'fusionpbx.dsiprouter.net','domain_auth',2,'passthru','2026-03-11 12:27:02'),
(525,'fusionpbx.dsiprouter.net','pbx_list',2,'37','2026-03-11 12:27:02'),
(526,'fusionpbx.dsiprouter.net','description',2,'notes:','2026-03-11 12:27:02'),
(527,'deb12-dev.dsiprouter.net','pbx_ip',2,'fusionpbx.dsiprouter.net:5060','2026-03-11 12:27:02'),
(528,'deb12-dev.dsiprouter.net','pbx_type',2,'2','2026-03-11 12:27:02'),
(529,'deb12-dev.dsiprouter.net','created_by',2,'37','2026-03-11 12:27:02'),
(530,'deb12-dev.dsiprouter.net','dispatcher_set_id',2,'37','2026-03-11 12:27:02'),
(531,'deb12-dev.dsiprouter.net','dispatcher_reg_alg',2,'4','2026-03-11 12:27:02'),
(532,'deb12-dev.dsiprouter.net','domain_auth',2,'passthru','2026-03-11 12:27:02'),
(533,'deb12-dev.dsiprouter.net','pbx_list',2,'37','2026-03-11 12:27:02'),
(534,'deb12-dev.dsiprouter.net','description',2,'notes:','2026-03-11 12:27:02'),
(535,'centos9-dev.dsiprouter.net','pbx_ip',2,'fusionpbx.dsiprouter.net:5060','2026-03-11 12:27:02'),
(536,'centos9-dev.dsiprouter.net','pbx_type',2,'2','2026-03-11 12:27:02'),
(537,'centos9-dev.dsiprouter.net','created_by',2,'37','2026-03-11 12:27:02'),
(538,'centos9-dev.dsiprouter.net','dispatcher_set_id',2,'37','2026-03-11 12:27:02'),
(539,'centos9-dev.dsiprouter.net','dispatcher_reg_alg',2,'4','2026-03-11 12:27:02'),
(540,'centos9-dev.dsiprouter.net','domain_auth',2,'passthru','2026-03-11 12:27:02'),
(541,'centos9-dev.dsiprouter.net','pbx_list',2,'37','2026-03-11 12:27:02'),
(542,'centos9-dev.dsiprouter.net','description',2,'notes:','2026-03-11 12:27:02'),
(543,'dealerb.xyz.com','pbx_ip',2,'fusionpbx.dsiprouter.net:5060','2026-03-11 12:27:02'),
(544,'dealerb.xyz.com','pbx_type',2,'2','2026-03-11 12:27:02'),
(545,'dealerb.xyz.com','created_by',2,'37','2026-03-11 12:27:02'),
(546,'dealerb.xyz.com','dispatcher_set_id',2,'37','2026-03-11 12:27:02'),
(547,'dealerb.xyz.com','dispatcher_reg_alg',2,'4','2026-03-11 12:27:02'),
(548,'dealerb.xyz.com','domain_auth',2,'passthru','2026-03-11 12:27:02'),
(549,'dealerb.xyz.com','pbx_list',2,'37','2026-03-11 12:27:02'),
(550,'dealerb.xyz.com','description',2,'notes:','2026-03-11 12:27:02'),
(551,'linda.dsiprouter.net','pbx_ip',2,'fusionpbx.dsiprouter.net:5060','2026-03-11 12:27:02'),
(552,'linda.dsiprouter.net','pbx_type',2,'2','2026-03-11 12:27:02'),
(553,'linda.dsiprouter.net','created_by',2,'37','2026-03-11 12:27:02'),
(554,'linda.dsiprouter.net','dispatcher_set_id',2,'37','2026-03-11 12:27:02'),
(555,'linda.dsiprouter.net','dispatcher_reg_alg',2,'4','2026-03-11 12:27:02'),
(556,'linda.dsiprouter.net','domain_auth',2,'passthru','2026-03-11 12:27:02'),
(557,'linda.dsiprouter.net','pbx_list',2,'37','2026-03-11 12:27:02'),
(558,'linda.dsiprouter.net','description',2,'notes:','2026-03-11 12:27:02'),
(559,'ese-test.dsiprouter.net','pbx_ip',2,'fusionpbx.dsiprouter.net:5060','2026-03-11 12:27:02'),
(560,'ese-test.dsiprouter.net','pbx_type',2,'2','2026-03-11 12:27:02'),
(561,'ese-test.dsiprouter.net','created_by',2,'37','2026-03-11 12:27:02'),
(562,'ese-test.dsiprouter.net','dispatcher_set_id',2,'37','2026-03-11 12:27:02'),
(563,'ese-test.dsiprouter.net','dispatcher_reg_alg',2,'4','2026-03-11 12:27:02'),
(564,'ese-test.dsiprouter.net','domain_auth',2,'passthru','2026-03-11 12:27:02'),
(565,'ese-test.dsiprouter.net','pbx_list',2,'37','2026-03-11 12:27:02'),
(566,'ese-test.dsiprouter.net','description',2,'notes:','2026-03-11 12:27:02'),
(567,'meltapi.detroitpbx.com','pbx_ip',2,'fusionpbx.dsiprouter.net:5060','2026-03-11 12:27:02'),
(568,'meltapi.detroitpbx.com','pbx_type',2,'2','2026-03-11 12:27:02'),
(569,'meltapi.detroitpbx.com','created_by',2,'37','2026-03-11 12:27:02'),
(570,'meltapi.detroitpbx.com','dispatcher_set_id',2,'37','2026-03-11 12:27:02'),
(571,'meltapi.detroitpbx.com','dispatcher_reg_alg',2,'4','2026-03-11 12:27:02'),
(572,'meltapi.detroitpbx.com','domain_auth',2,'passthru','2026-03-11 12:27:02'),
(573,'meltapi.detroitpbx.com','pbx_list',2,'37','2026-03-11 12:27:02'),
(574,'meltapi.detroitpbx.com','description',2,'notes:','2026-03-11 12:27:02'),
(575,'solo.orange64.com','pbx_ip',2,'fusionpbx.dsiprouter.net:5060','2026-03-11 12:27:02'),
(576,'solo.orange64.com','pbx_type',2,'2','2026-03-11 12:27:02'),
(577,'solo.orange64.com','created_by',2,'37','2026-03-11 12:27:02'),
(578,'solo.orange64.com','dispatcher_set_id',2,'37','2026-03-11 12:27:02'),
(579,'solo.orange64.com','dispatcher_reg_alg',2,'4','2026-03-11 12:27:02'),
(580,'solo.orange64.com','domain_auth',2,'passthru','2026-03-11 12:27:02'),
(581,'solo.orange64.com','pbx_list',2,'37','2026-03-11 12:27:02'),
(582,'solo.orange64.com','description',2,'notes:','2026-03-11 12:27:02');
/*!40000 ALTER TABLE `domain_attrs` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `domain_name`
--

DROP TABLE IF EXISTS `domain_name`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8mb4 */;
CREATE TABLE `domain_name` (
  `id` int(10) unsigned NOT NULL AUTO_INCREMENT,
  `domain` varchar(64) DEFAULT NULL,
  PRIMARY KEY (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb3 COLLATE=utf8mb3_general_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `domain_name`
--

LOCK TABLES `domain_name` WRITE;
/*!40000 ALTER TABLE `domain_name` DISABLE KEYS */;
/*!40000 ALTER TABLE `domain_name` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `domainpolicy`
--

DROP TABLE IF EXISTS `domainpolicy`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8mb4 */;
CREATE TABLE `domainpolicy` (
  `id` int(10) unsigned NOT NULL AUTO_INCREMENT,
  `rule` varchar(255) NOT NULL,
  `type` varchar(255) NOT NULL,
  `att` varchar(255) DEFAULT NULL,
  `val` varchar(128) DEFAULT NULL,
  `description` varchar(255) NOT NULL,
  PRIMARY KEY (`id`),
  UNIQUE KEY `rav_idx` (`rule`,`att`,`val`),
  KEY `rule_idx` (`rule`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb3 COLLATE=utf8mb3_general_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `domainpolicy`
--

LOCK TABLES `domainpolicy` WRITE;
/*!40000 ALTER TABLE `domainpolicy` DISABLE KEYS */;
/*!40000 ALTER TABLE `domainpolicy` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `dr_custom_rules`
--

DROP TABLE IF EXISTS `dr_custom_rules`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8mb4 */;
CREATE TABLE `dr_custom_rules` (
  `dr_ruleid` int(10) unsigned NOT NULL AUTO_INCREMENT,
  `locality` varchar(64) NOT NULL DEFAULT '',
  `ppm` decimal(10,2) NOT NULL DEFAULT 0.00,
  `description` varchar(128) NOT NULL DEFAULT '',
  PRIMARY KEY (`dr_ruleid`),
  CONSTRAINT `dr_custom_rules_ibfk_1` FOREIGN KEY (`dr_ruleid`) REFERENCES `dr_rules` (`ruleid`) ON DELETE CASCADE ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb3 COLLATE=utf8mb3_general_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `dr_custom_rules`
--

LOCK TABLES `dr_custom_rules` WRITE;
/*!40000 ALTER TABLE `dr_custom_rules` DISABLE KEYS */;
/*!40000 ALTER TABLE `dr_custom_rules` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `dr_gateways`
--

DROP TABLE IF EXISTS `dr_gateways`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8mb4 */;
CREATE TABLE `dr_gateways` (
  `gwid` int(10) unsigned NOT NULL AUTO_INCREMENT,
  `type` int(11) unsigned NOT NULL DEFAULT 0,
  `address` varchar(253) NOT NULL,
  `strip` int(11) unsigned NOT NULL DEFAULT 0,
  `pri_prefix` varchar(64) NOT NULL DEFAULT '',
  `attrs` varchar(255) NOT NULL DEFAULT '',
  `description` varchar(255) NOT NULL DEFAULT '',
  PRIMARY KEY (`gwid`)
) ENGINE=InnoDB AUTO_INCREMENT=358 DEFAULT CHARSET=utf8mb3 COLLATE=utf8mb3_general_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `dr_gateways`
--

LOCK TABLES `dr_gateways` WRITE;
/*!40000 ALTER TABLE `dr_gateways` DISABLE KEYS */;
INSERT INTO `dr_gateways` VALUES
(1,8,'54.172.60.0',0,'','1,8,,proxy,proxy','name:Twilio NA-Virginia Carrier,gwgroup:1,addr_id:18'),
(2,8,'54.172.60.1',0,'','2,8,,proxy,proxy','name:Twilio NA-Virginia  Carrier,gwgroup:1,addr_id:19'),
(3,8,'54.172.60.2',0,'','3,8,,proxy,proxy','name:Twilio NA-Virginia Carrier,gwgroup:1,addr_id:20'),
(4,8,'54.172.60.3',0,'','4,8,,proxy,proxy','name:Twilio NA-Virginia Carrier,gwgroup:1,addr_id:21'),
(5,8,'54.244.51.0',0,'','5,8,,proxy,proxy','name:Twilio NA-Oregon Carrier,gwgroup:1,addr_id:22'),
(6,8,'54.244.51.1',0,'','6,8,,proxy,proxy','name:Twilio NA-Oregon  Carrier,gwgroup:1,addr_id:23'),
(7,8,'54.244.51.2',0,'','7,8,,proxy,proxy','name:Twilio NA-Oregon Carrier,gwgroup:1,addr_id:24'),
(8,8,'54.244.51.3',0,'','8,8,,proxy,proxy','name:Twilio NA-Oregon Carrier,gwgroup:1,addr_id:25'),
(9,8,'52.41.52.34',0,'','9,8,,proxy,proxy','name:Skyetel North West Inbound,gwgroup:2,addr_id:29'),
(10,8,'52.8.201.128',0,'','10,8,,proxy,proxy','name:Skyetel South West Inbound,gwgroup:2,addr_id:30'),
(11,8,'52.60.138.31',0,'','11,8,,proxy,proxy','name:Skyetel North East Inbound,gwgroup:2,addr_id:31'),
(12,8,'50.17.48.216',0,'','12,8,,proxy,proxy','name:Skyetel South East Inbound,gwgroup:2,addr_id:32'),
(13,8,'35.156.192.164',0,'','13,8,,proxy,proxy','name:Skyetel Europe Inbound,gwgroup:2,addr_id:33'),
(14,8,'term.skyetel.com',0,'','14,8,,proxy,proxy','name:Skyetel 1st Priority Outbound Call,gwgroup:2,addr_id:34'),
(15,8,'52.41.52.34',0,'','15,8,,proxy,proxy','name:Skyetel 2nd Priority Outbound Call,gwgroup:2,addr_id:35'),
(16,8,'52.8.201.128',0,'','16,8,,proxy,proxy','name:Skyetel 3rd Priority Outbound Call,gwgroup:2,addr_id:36'),
(17,8,'50.17.48.216',0,'','17,8,,proxy,proxy','name:Skyetel 4rd Priority Outbound Call,gwgroup:2,addr_id:37'),
(18,8,'52.32.223.28',0,'','18,8,,proxy,proxy','name:Skyetel North West High Cost Outbound Traffic,gwgroup:2,addr_id:38'),
(21,8,'34.210.91.112:5060',0,'16723617*','21,8,,proxy,proxy','name:Flowroute US-West-OR,gwgroup:3,addr_id:41'),
(23,8,'34.226.36.32:5060',0,'16723617*','23,8,,proxy,proxy','name:Flowroute US-East-VA,gwgroup:3,addr_id:43'),
(24,8,'81.201.82.45',0,'','24,8,,proxy,proxy','name:Voxbone Belgium,gwgroup:4,addr_id:44'),
(25,8,'81.201.84.195',0,'','25,8,,proxy,proxy','name:Voxbone LA,gwgroup:4,addr_id:45'),
(26,8,'81.201.85.45',0,'','26,8,,proxy,proxy','name:Voxbone NYC,gwgroup:4,addr_id:46'),
(27,8,'81.201.83.45',0,'','27,8,,proxy,proxy','name:Voxbone Germany,gwgroup:4,addr_id:47'),
(28,8,'81.201.86.45',0,'','28,8,,proxy,proxy','name:Voxbone Hong Kong,gwgroup:4,addr_id:48'),
(29,8,'81.201.84.195',0,'','29,8,,proxy,proxy','name:Voxbone Australia,gwgroup:4,addr_id:49'),
(30,8,'64.136.174.30',0,'','30,8,,proxy,proxy','name:VoIP Innovations Inbound Carrier,gwgroup:5,addr_id:50'),
(31,8,'64.136.173.22',0,'','31,8,,proxy,proxy','name:VoIP Innovations Inbound Carrier,gwgroup:5,addr_id:51'),
(32,8,'209.166.128.200',0,'','32,8,,proxy,proxy','name:VoIP Innovations Inbound Carrier,gwgroup:5,addr_id:52'),
(33,8,'192.240.151.100',0,'','33,8,,proxy,proxy','name:VoIP Innovations Inbound Carrier,gwgroup:5,addr_id:53'),
(34,8,'64.136.173.31',0,'','34,8,,proxy,proxy','name:VoIP Innovations Inbound Carrier,gwgroup:5,addr_id:54'),
(35,8,'64.136.174.30',0,'','35,8,,proxy,proxy','name:VoIP Innovations Inbound Carrier,gwgroup:5,addr_id:55'),
(36,8,'64.136.174.20',0,'','36,8,,proxy,proxy','name:VoIP Innovations Inbound Carrier,gwgroup:5,addr_id:56'),
(37,8,'209.166.154.70',0,'','37,8,,proxy,proxy','name:VoIP Innovations Inbound Carrier,gwgroup:5,addr_id:57'),
(38,8,'64.136.174.65',0,'','38,8,,proxy,proxy','name:VoIP Innovations Inbound Carrier,gwgroup:5,addr_id:58'),
(39,8,'64.136.173.23',0,'','39,8,,proxy,proxy','name:VoIP Innovations Inbound Carrier,gwgroup:5,addr_id:59'),
(40,8,'209.166.128.201',0,'','40,8,,proxy,proxy','name:VoIP Innovations Inbound Carrier,gwgroup:5,addr_id:60'),
(41,8,'192.240.151.101',0,'','41,8,,proxy,proxy','name:VoIP Innovations Inbound Carrier,gwgroup:5,addr_id:61'),
(42,8,'64.136.173.65',0,'','42,8,,proxy,proxy','name:VoIP Innovations Inbound Carrier,gwgroup:5,addr_id:62'),
(43,8,'64.136.174.65',0,'','43,8,,proxy,proxy','name:VoIP Innovations Inbound Carrier,gwgroup:5,addr_id:63'),
(44,8,'64.136.174.21',0,'','44,8,,proxy,proxy','name:VoIP Innovations Inbound Carrier,gwgroup:5,addr_id:64'),
(45,8,'209.166.154.71',0,'','45,8,,proxy,proxy','name:VoIP Innovations Inbound Carrier,gwgroup:5,addr_id:65'),
(46,8,'64.136.174.30',0,'','46,8,,proxy,proxy','name:VoIP Innovations Outbound Conversational Carrier,gwgroup:6,addr_id:66'),
(47,8,'64.136.173.22',0,'','47,8,,proxy,proxy','name:VoIP Innovations Outbound Conversational Carrier,gwgroup:6,addr_id:67'),
(48,8,'209.166.128.200',0,'','48,8,,proxy,proxy','name:VoIP Innovations Outbound Conversational Carrier,gwgroup:6,addr_id:68'),
(49,8,'192.240.151.100',0,'','49,8,,proxy,proxy','name:VoIP Innovations Outbound Conversational Carrier,gwgroup:6,addr_1d:69'),
(50,8,'72.15.219.140',0,'','50,8,,proxy,proxy','name:Thinq Carrier,gwgroup:7,addr_id:70'),
(51,8,'216.147.191.157',0,'','51,8,,proxy,proxy','name:Voxtelesys Carrier,gwgroup:8,addr_id:71'),
(52,8,'64.34.181.47',0,'','52,8,,proxy,proxy','name:Les.net Carrier,gwgroup:9,addr_id:72'),
(53,8,'206.80.250.100',0,'','53,8,,proxy,proxy','name:ThinkTel,gwgroup:10,addr_id:73'),
(54,8,'208.68.17.52',0,'','54,8,,proxy,proxy','name:ThinkTel,gwgroup:10,addr_id:74'),
(55,8,'209.197.130.80',0,'','55,8,,proxy,proxy','name:ThinkTel,gwgroup:10,addr_id:75'),
(56,9,'freepbx.dsiprouter.net:5060',0,'','56,9,,proxy,proxy','name:,gwgroup:11,addr_id:76'),
(57,8,'sip.api.openai.com:5061',0,'','57,8,,proxy,proxy','name:OpenAI,gwgroup:12,addr_id:77'),
(58,9,'50.192.97.226:5060',0,'','58,9,,proxy,proxy','name:,gwgroup:13,addr_id:78'),
(59,9,'sip.api.openai.com:5061',0,'','59,9,,sips_tls,proxy,proj_MrxkZ5BlbAFrpJXiyZBrs6mq','name:,gwgroup:14,addr_id:79'),
(60,9,'sip.api.openai.com:5061',0,'','60,9,,sips_tls,proxy,proj_LiCooyUxqKrHxGckhR34dpHR','name:,gwgroup:15,addr_id:80'),
(61,9,'sip.api.openai.com:5061',0,'','61,9,,sips_tls,proxy,proj_s6OMBJOrj60XHHiK8nRjHrBi','name:,gwgroup:16,addr_id:81'),
(62,9,'sip.api.openai.com:5061',0,'','62,9,,sips_tls,proxy,proj_a02nz7CJlhnK8WtZ2tS2xr2I','name:,gwgroup:17,addr_id:82'),
(63,9,'192.168.1.100:5060',0,'','63,9,,proxy,proxy','name:FreePBX2,gwgroup:18,addr_id:83'),
(64,9,'50.192.97.226:5060',0,'','64,9,,proxy,proxy','name:HOA,gwgroup:19,addr_id:84'),
(65,9,'192.168.42.1:5060',0,'','65,9,,proxy,proxy','name:New Customer 546,gwgroup:20,addr_id:85'),
(66,9,'188.42.24.2:5060',0,'','66,9,,proxy,proxy','name:Mack\'s Endpoint,gwgroup:23,addr_id:86'),
(67,9,'204.24.24.22:5060',0,'','67,9,,proxy,proxy','name:Acme Company,gwgroup:24,addr_id:87'),
(68,9,'sip.api.openai.com:5061',0,'','68,9,,sips_tls,proxy,proj_J7f6NK1rtMoZ0SXI9bbgLpOG','name:,gwgroup:25,addr_id:88'),
(154,9,'75.15.188.163:52042',0,'','154,9,,proxy,proxy','name:autoregister,type:9,gwgroup:32'),
(290,8,'199.14.31.13:5060',0,'','290,8,,proxy,proxy','name:Gen1,gwgroup:35,addr_id:91'),
(337,9,'50.192.97.226:62648',0,'','337,9,,proxy,proxy','name:autoregister,type:9,gwgroup:32'),
(341,9,'fusionpbx.dsiprouter.net:5060',0,'','341,9,,proxy,proxy','name:,gwgroup:37,addr_id:95'),
(342,9,'demo.dsiprouter.net:5060',0,'','342,9,,proxy,proxy','name:,gwgroup:37,addr_id:96');
/*!40000 ALTER TABLE `dr_gateways` ENABLE KEYS */;
UNLOCK TABLES;
/*!50003 SET @saved_cs_client      = @@character_set_client */ ;
/*!50003 SET @saved_cs_results     = @@character_set_results */ ;
/*!50003 SET @saved_col_connection = @@collation_connection */ ;
/*!50003 SET character_set_client  = utf8mb3 */ ;
/*!50003 SET character_set_results = utf8mb3 */ ;
/*!50003 SET collation_connection  = utf8mb3_general_ci */ ;
/*!50003 SET @saved_sql_mode       = @@sql_mode */ ;
/*!50003 SET sql_mode              = 'STRICT_TRANS_TABLES,ERROR_FOR_DIVISION_BY_ZERO,NO_AUTO_CREATE_USER,NO_ENGINE_SUBSTITUTION' */ ;
DELIMITER ;;
/*!50003 CREATE*/ /*!50017 DEFINER=`root`@`localhost`*/ /*!50003 TRIGGER insert_dr_gateways
  BEFORE INSERT
  ON dr_gateways
  FOR EACH ROW
BEGIN

  
  IF (NEW.gwid = 0) THEN
    SET NEW.gwid = NULL;
  END IF;
  IF (NEW.attrs IS NULL) THEN
    SET NEW.attrs = '';
  END IF;

  SET @new_gwid := COALESCE(NEW.gwid, @new_gwid, (
    SELECT auto_increment
    FROM information_schema.tables
    WHERE table_name = 'dr_gateways' AND table_schema = DATABASE()));

  
  SET NEW.attrs = CONCAT(CAST(@new_gwid AS char), ',', CAST(NEW.type AS char),
                         SUBSTRING(NEW.attrs, LENGTH(SUBSTRING_INDEX(NEW.attrs, ',', 2)) + 1));
  SET @new_gwid = @new_gwid + 1;

END */;;
DELIMITER ;
/*!50003 SET sql_mode              = @saved_sql_mode */ ;
/*!50003 SET character_set_client  = @saved_cs_client */ ;
/*!50003 SET character_set_results = @saved_cs_results */ ;
/*!50003 SET collation_connection  = @saved_col_connection */ ;
/*!50003 SET @saved_cs_client      = @@character_set_client */ ;
/*!50003 SET @saved_cs_results     = @@character_set_results */ ;
/*!50003 SET @saved_col_connection = @@collation_connection */ ;
/*!50003 SET character_set_client  = utf8mb3 */ ;
/*!50003 SET character_set_results = utf8mb3 */ ;
/*!50003 SET collation_connection  = utf8mb3_general_ci */ ;
/*!50003 SET @saved_sql_mode       = @@sql_mode */ ;
/*!50003 SET sql_mode              = 'STRICT_TRANS_TABLES,ERROR_FOR_DIVISION_BY_ZERO,NO_AUTO_CREATE_USER,NO_ENGINE_SUBSTITUTION' */ ;
DELIMITER ;;
/*!50003 CREATE*/ /*!50017 DEFINER=`root`@`localhost`*/ /*!50003 TRIGGER update_dr_gateways
  BEFORE UPDATE
  ON dr_gateways
  FOR EACH ROW
BEGIN

  
  SET NEW.attrs = CONCAT(CAST(NEW.gwid AS char), ',', CAST(NEW.type AS char),
                         SUBSTRING(NEW.attrs, LENGTH(SUBSTRING_INDEX(NEW.attrs, ',', 2)) + 1));

END */;;
DELIMITER ;
/*!50003 SET sql_mode              = @saved_sql_mode */ ;
/*!50003 SET character_set_client  = @saved_cs_client */ ;
/*!50003 SET character_set_results = @saved_cs_results */ ;
/*!50003 SET collation_connection  = @saved_col_connection */ ;

--
-- Table structure for table `dr_groups`
--

DROP TABLE IF EXISTS `dr_groups`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8mb4 */;
CREATE TABLE `dr_groups` (
  `id` int(10) unsigned NOT NULL AUTO_INCREMENT,
  `username` varchar(64) NOT NULL,
  `domain` varchar(128) NOT NULL DEFAULT '',
  `groupid` int(11) unsigned NOT NULL DEFAULT 0,
  `description` varchar(128) NOT NULL DEFAULT '',
  PRIMARY KEY (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb3 COLLATE=utf8mb3_general_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `dr_groups`
--

LOCK TABLES `dr_groups` WRITE;
/*!40000 ALTER TABLE `dr_groups` DISABLE KEYS */;
/*!40000 ALTER TABLE `dr_groups` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `dr_gw_lists`
--

DROP TABLE IF EXISTS `dr_gw_lists`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8mb4 */;
CREATE TABLE `dr_gw_lists` (
  `id` int(10) unsigned NOT NULL AUTO_INCREMENT,
  `gwlist` varchar(255) NOT NULL,
  `description` varchar(255) NOT NULL DEFAULT '',
  PRIMARY KEY (`id`)
) ENGINE=InnoDB AUTO_INCREMENT=38 DEFAULT CHARSET=utf8mb3 COLLATE=utf8mb3_general_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `dr_gw_lists`
--

LOCK TABLES `dr_gw_lists` WRITE;
/*!40000 ALTER TABLE `dr_gw_lists` DISABLE KEYS */;
INSERT INTO `dr_gw_lists` VALUES
(1,'1,2,3,4,5,6,7,8','name:Twilio NA Inbound CarrierGroup,type:8,lb:1'),
(2,'9,10,11,12,13,14,15,16,17,18,19','name:Skyetel CarrierGroup,type:8,lb:2'),
(3,'21,23','name:Flowroute CarrierGroup,type:8,lb:3'),
(4,'24,25,26,27,28,29','name:Voxbone CarrierGroup,type:8,lb:4'),
(5,'30,31,32,33,34,35,36,37,38,39,40,41,42,43,44,45','name:VoIP Innovations Inbound CarrierGroup,type:8,lb:5'),
(6,'46,47,48,49','name:VoIP Innovations Outbound Conversational CarrierGroup,type:8,lb:6'),
(7,'50','name:Thinq CarrierGroup,type:8,lb:7'),
(8,'51','name:Voxtelesys CarrierGroup,type:8,lb:8'),
(9,'52','name:Les.net CarrierGroup,type:8,lb:9'),
(10,'53,54,55','name:ThinkTel CarrierGroup,type:8,lb:10'),
(11,'56','name:FreePBX,type:9,lb:11'),
(12,'57','name:OpenAI,type:8,lb:12'),
(13,'58','name:VoIP Client,type:9,lb:13'),
(14,'59','name:Bamboo Midtown Agent,type:9,lb:14'),
(15,'60','name:DetroitPBX Agent,type:9,lb:15'),
(16,'61','name:Brad Bright Lights Agent,type:9,lb:16'),
(17,'62','name:East Side Primary Care,type:9,lb:17'),
(18,'63','name:FreePBX2,type:9,lb:18'),
(19,'64','name:HOA,type:9,lb:19'),
(20,'65','name:New Customer 546,type:9,lb:20'),
(21,'','name:Mack\'s Test,type:8,lb:21'),
(22,'','name:Mack\'s Backup,type:8,lb:22'),
(23,'66','name:Mack\'s Endpoint,type:9,lb:23'),
(24,'67','name:Acme Company,type:9,lb:24'),
(25,'68','name:DDC Agent,type:9,lb:25'),
(28,'','name:Test,type:9'),
(29,'','name:Test,type:9'),
(30,'','name:Test,type:9'),
(31,'','name:Test ,type:9'),
(32,'154,337','name:Test ABC,type:9,lb:32'),
(33,'','name:SignalWire,type:8,lb:33'),
(34,'','name:Test UAC Failure,type:8,lb:34'),
(35,'290','name:Genesis Cloud,type:8,lb:35'),
(37,'341,342','name:FusionPBX,type:9,lb:37,lb_ext:1037');
/*!40000 ALTER TABLE `dr_gw_lists` ENABLE KEYS */;
UNLOCK TABLES;
/*!50003 SET @saved_cs_client      = @@character_set_client */ ;
/*!50003 SET @saved_cs_results     = @@character_set_results */ ;
/*!50003 SET @saved_col_connection = @@collation_connection */ ;
/*!50003 SET character_set_client  = utf8mb3 */ ;
/*!50003 SET character_set_results = utf8mb3 */ ;
/*!50003 SET collation_connection  = utf8mb3_general_ci */ ;
/*!50003 SET @saved_sql_mode       = @@sql_mode */ ;
/*!50003 SET sql_mode              = 'STRICT_TRANS_TABLES,ERROR_FOR_DIVISION_BY_ZERO,NO_AUTO_CREATE_USER,NO_ENGINE_SUBSTITUTION' */ ;
DELIMITER ;;
/*!50003 CREATE*/ /*!50017 DEFINER=`root`@`localhost`*/ /*!50003 TRIGGER insert_gw2gwgroup
  AFTER INSERT
  ON dr_gw_lists
  FOR EACH ROW
BEGIN

  DECLARE num_gws int DEFAULT 0;
  DECLARE gw_index int DEFAULT 1;

  IF CHAR_LENGTH(NEW.gwlist) > 0 THEN
    SET num_gws := (CHAR_LENGTH(NEW.gwlist) - CHAR_LENGTH(REPLACE(NEW.gwlist, ',', '')) + 1);

    
    WHILE gw_index <= num_gws
      DO
        INSERT IGNORE INTO dsip_gw2gwgroup
        VALUES (SUBSTRING_INDEX(SUBSTRING_INDEX(NEW.gwlist, ',', gw_index), ',', -1), cast(NEW.id AS char(64)), DEFAULT,
                DEFAULT);
        SET gw_index := gw_index + 1;
      END WHILE;
  END IF;

END */;;
DELIMITER ;
/*!50003 SET sql_mode              = @saved_sql_mode */ ;
/*!50003 SET character_set_client  = @saved_cs_client */ ;
/*!50003 SET character_set_results = @saved_cs_results */ ;
/*!50003 SET collation_connection  = @saved_col_connection */ ;
/*!50003 SET @saved_cs_client      = @@character_set_client */ ;
/*!50003 SET @saved_cs_results     = @@character_set_results */ ;
/*!50003 SET @saved_col_connection = @@collation_connection */ ;
/*!50003 SET character_set_client  = utf8mb3 */ ;
/*!50003 SET character_set_results = utf8mb3 */ ;
/*!50003 SET collation_connection  = utf8mb3_general_ci */ ;
/*!50003 SET @saved_sql_mode       = @@sql_mode */ ;
/*!50003 SET sql_mode              = 'STRICT_TRANS_TABLES,ERROR_FOR_DIVISION_BY_ZERO,NO_AUTO_CREATE_USER,NO_ENGINE_SUBSTITUTION' */ ;
DELIMITER ;;
/*!50003 CREATE*/ /*!50017 DEFINER=`root`@`localhost`*/ /*!50003 TRIGGER insert_gwgroup2lb
  AFTER INSERT
  ON dr_gw_lists
  FOR EACH ROW
BEGIN
  DECLARE v_setid varchar(64);

  SET @new_gwgroupid := COALESCE(NEW.id, @new_gwgroupid, (
    SELECT auto_increment
    FROM information_schema.tables
    WHERE table_name = 'dr_gw_lists' AND table_schema = DATABASE()));

  IF NEW.description REGEXP '(?:lb:|lb_ext:)([0-9]+)' THEN
    SET v_setid = REGEXP_REPLACE(NEW.description, '.*(?:lb:|lb_ext:)([0-9]+).*', '\\1');
    REPLACE INTO dsip_gwgroup2lb
      VALUES (CAST(@new_gwgroupid AS char), CAST(v_setid AS char), DEFAULT, DEFAULT, DEFAULT);
  END IF;

  SET @new_gwgroupid = @new_gwgroupid + 1;
END */;;
DELIMITER ;
/*!50003 SET sql_mode              = @saved_sql_mode */ ;
/*!50003 SET character_set_client  = @saved_cs_client */ ;
/*!50003 SET character_set_results = @saved_cs_results */ ;
/*!50003 SET collation_connection  = @saved_col_connection */ ;
/*!50003 SET @saved_cs_client      = @@character_set_client */ ;
/*!50003 SET @saved_cs_results     = @@character_set_results */ ;
/*!50003 SET @saved_col_connection = @@collation_connection */ ;
/*!50003 SET character_set_client  = utf8mb3 */ ;
/*!50003 SET character_set_results = utf8mb3 */ ;
/*!50003 SET collation_connection  = utf8mb3_general_ci */ ;
/*!50003 SET @saved_sql_mode       = @@sql_mode */ ;
/*!50003 SET sql_mode              = 'STRICT_TRANS_TABLES,ERROR_FOR_DIVISION_BY_ZERO,NO_AUTO_CREATE_USER,NO_ENGINE_SUBSTITUTION' */ ;
DELIMITER ;;
/*!50003 CREATE*/ /*!50017 DEFINER=`root`@`localhost`*/ /*!50003 TRIGGER update_gw2gwgroup
  AFTER UPDATE
  ON dr_gw_lists
  FOR EACH ROW
BEGIN

  DECLARE num_gws int DEFAULT 0;
  DECLARE gw_index int DEFAULT 1;

  
  IF NOT (NEW.gwlist <=> OLD.gwlist) THEN
    DELETE FROM dsip_gw2gwgroup WHERE gwgroupid = cast(OLD.id AS char(64));

    IF CHAR_LENGTH(NEW.gwlist) > 0 THEN
      SET num_gws := (CHAR_LENGTH(NEW.gwlist) - CHAR_LENGTH(REPLACE(NEW.gwlist, ',', '')) + 1);

      
      WHILE gw_index <= num_gws
        DO
          INSERT IGNORE INTO dsip_gw2gwgroup
          VALUES (SUBSTRING_INDEX(SUBSTRING_INDEX(NEW.gwlist, ',', gw_index), ',', -1), cast(NEW.id AS char(64)),
                  DEFAULT,
                  DEFAULT);
          SET gw_index := gw_index + 1;
        END WHILE;
    END IF;

    
  ELSEIF NOT (NEW.id <=> OLD.id) THEN
    UPDATE dsip_gw2gwgroup SET gwgroupid = cast(NEW.id AS char(64)) WHERE gwgroupid = cast(OLD.id AS char(64));
  END IF;

END */;;
DELIMITER ;
/*!50003 SET sql_mode              = @saved_sql_mode */ ;
/*!50003 SET character_set_client  = @saved_cs_client */ ;
/*!50003 SET character_set_results = @saved_cs_results */ ;
/*!50003 SET collation_connection  = @saved_col_connection */ ;
/*!50003 SET @saved_cs_client      = @@character_set_client */ ;
/*!50003 SET @saved_cs_results     = @@character_set_results */ ;
/*!50003 SET @saved_col_connection = @@collation_connection */ ;
/*!50003 SET character_set_client  = utf8mb3 */ ;
/*!50003 SET character_set_results = utf8mb3 */ ;
/*!50003 SET collation_connection  = utf8mb3_general_ci */ ;
/*!50003 SET @saved_sql_mode       = @@sql_mode */ ;
/*!50003 SET sql_mode              = 'STRICT_TRANS_TABLES,ERROR_FOR_DIVISION_BY_ZERO,NO_AUTO_CREATE_USER,NO_ENGINE_SUBSTITUTION' */ ;
DELIMITER ;;
/*!50003 CREATE*/ /*!50017 DEFINER=`root`@`localhost`*/ /*!50003 TRIGGER update_gwgroup2lb
  AFTER UPDATE
  ON dr_gw_lists
  FOR EACH ROW
BEGIN
  DECLARE v_gwgroupid varchar(64) DEFAULT NULL;
  DECLARE v_setid varchar(64) DEFAULT NULL;

  
  IF NOT (NEW.description <=> OLD.description) THEN
    
    SET v_gwgroupid = CAST(COALESCE(NEW.id, OLD.id) AS char);

    
    IF NEW.description REGEXP '(?:lb:|lb_ext:)([0-9]+)' THEN
      SET v_setid = REGEXP_REPLACE(NEW.description, '.*(?:lb:|lb_ext:)([0-9]+).*', '\\1');
      INSERT INTO dsip_gwgroup2lb VALUES(v_gwgroupid, v_setid, DEFAULT, DEFAULT, DEFAULT)
                                  ON DUPLICATE KEY UPDATE setid=v_setid;
    END IF;
  END IF;
END */;;
DELIMITER ;
/*!50003 SET sql_mode              = @saved_sql_mode */ ;
/*!50003 SET character_set_client  = @saved_cs_client */ ;
/*!50003 SET character_set_results = @saved_cs_results */ ;
/*!50003 SET collation_connection  = @saved_col_connection */ ;
/*!50003 SET @saved_cs_client      = @@character_set_client */ ;
/*!50003 SET @saved_cs_results     = @@character_set_results */ ;
/*!50003 SET @saved_col_connection = @@collation_connection */ ;
/*!50003 SET character_set_client  = utf8mb3 */ ;
/*!50003 SET character_set_results = utf8mb3 */ ;
/*!50003 SET collation_connection  = utf8mb3_general_ci */ ;
/*!50003 SET @saved_sql_mode       = @@sql_mode */ ;
/*!50003 SET sql_mode              = 'STRICT_TRANS_TABLES,ERROR_FOR_DIVISION_BY_ZERO,NO_AUTO_CREATE_USER,NO_ENGINE_SUBSTITUTION' */ ;
DELIMITER ;;
/*!50003 CREATE*/ /*!50017 DEFINER=`root`@`localhost`*/ /*!50003 TRIGGER delete_gw2gwgroup
  AFTER DELETE
  ON dr_gw_lists
  FOR EACH ROW
BEGIN

  DELETE FROM dsip_gw2gwgroup WHERE gwgroupid = cast(OLD.id AS char(64));

END */;;
DELIMITER ;
/*!50003 SET sql_mode              = @saved_sql_mode */ ;
/*!50003 SET character_set_client  = @saved_cs_client */ ;
/*!50003 SET character_set_results = @saved_cs_results */ ;
/*!50003 SET collation_connection  = @saved_col_connection */ ;
/*!50003 SET @saved_cs_client      = @@character_set_client */ ;
/*!50003 SET @saved_cs_results     = @@character_set_results */ ;
/*!50003 SET @saved_col_connection = @@collation_connection */ ;
/*!50003 SET character_set_client  = utf8mb3 */ ;
/*!50003 SET character_set_results = utf8mb3 */ ;
/*!50003 SET collation_connection  = utf8mb3_general_ci */ ;
/*!50003 SET @saved_sql_mode       = @@sql_mode */ ;
/*!50003 SET sql_mode              = 'STRICT_TRANS_TABLES,ERROR_FOR_DIVISION_BY_ZERO,NO_AUTO_CREATE_USER,NO_ENGINE_SUBSTITUTION' */ ;
DELIMITER ;;
/*!50003 CREATE*/ /*!50017 DEFINER=`root`@`localhost`*/ /*!50003 TRIGGER delete_gwgroup2lb
  AFTER DELETE
  ON dr_gw_lists
  FOR EACH ROW
BEGIN
  DELETE FROM dsip_gwgroup2lb WHERE gwgroupid = cast(OLD.id AS char);
END */;;
DELIMITER ;
/*!50003 SET sql_mode              = @saved_sql_mode */ ;
/*!50003 SET character_set_client  = @saved_cs_client */ ;
/*!50003 SET character_set_results = @saved_cs_results */ ;
/*!50003 SET collation_connection  = @saved_col_connection */ ;

--
-- Table structure for table `dr_rules`
--

DROP TABLE IF EXISTS `dr_rules`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8mb4 */;
CREATE TABLE `dr_rules` (
  `ruleid` int(10) unsigned NOT NULL AUTO_INCREMENT,
  `groupid` varchar(255) NOT NULL,
  `prefix` varchar(64) NOT NULL,
  `timerec` varchar(255) NOT NULL,
  `priority` int(11) NOT NULL DEFAULT 0,
  `routeid` varchar(64) NOT NULL,
  `gwlist` varchar(255) NOT NULL,
  `description` varchar(255) NOT NULL DEFAULT '',
  PRIMARY KEY (`ruleid`)
) ENGINE=InnoDB AUTO_INCREMENT=32 DEFAULT CHARSET=utf8mb3 COLLATE=utf8mb3_general_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `dr_rules`
--

LOCK TABLES `dr_rules` WRITE;
/*!40000 ALTER TABLE `dr_rules` DISABLE KEYS */;
INSERT INTO `dr_rules` VALUES
(2,'9000','5554443333','',0,'','#11','name:DID,lb_enabled:0'),
(3,'9000','12482438601','',0,'','#11','name:,lb_enabled:0'),
(4,'9000','1112223333','',0,'','#11','name:,lb_enabled:0'),
(5,'9000','13134903595','',0,'','#14','name:Bamboo Midtown Agent,lb_enabled:1'),
(6,'8000','','',0,'','#3','name:Default'),
(7,'9000','+13132468974','',0,'','#15','name:DetroitPBX Agent,lb_enabled:1'),
(8,'9000','+13136129074','',0,'','#16','name:Brad Bright Lights,lb_enabled:1'),
(9,'9000','13137891800','',0,'','#17','name:East Side Primary Care,lb_enabled:1'),
(15,'9000','13334442222','',0,'','#11','name:,lb_enabled:0'),
(22,'9000','15554442222','',0,'','#11',''),
(23,'9000','13132222223','',0,'','#19','name:Taste Pizzabar'),
(24,'9000','13132222224','',0,'','#11',''),
(25,'9000','7778889999','',0,'','#20',''),
(26,'9000','+17778889999','',0,'','#20',''),
(27,'9000','+18661234567','',0,'','#23',''),
(28,'9000','13132222225','',0,'','#11','name:Taste Pizzabar'),
(29,'9000','9994352222','',0,'','#11',''),
(30,'9000','1112229999','',0,'','#24',''),
(31,'9000','13137891315','',0,'','#25','name:DDC Agent,lb_enabled:1');
/*!40000 ALTER TABLE `dr_rules` ENABLE KEYS */;
UNLOCK TABLES;
/*!50003 SET @saved_cs_client      = @@character_set_client */ ;
/*!50003 SET @saved_cs_results     = @@character_set_results */ ;
/*!50003 SET @saved_col_connection = @@collation_connection */ ;
/*!50003 SET character_set_client  = utf8mb3 */ ;
/*!50003 SET character_set_results = utf8mb3 */ ;
/*!50003 SET collation_connection  = utf8mb3_general_ci */ ;
/*!50003 SET @saved_sql_mode       = @@sql_mode */ ;
/*!50003 SET sql_mode              = 'STRICT_TRANS_TABLES,ERROR_FOR_DIVISION_BY_ZERO,NO_AUTO_CREATE_USER,NO_ENGINE_SUBSTITUTION' */ ;
DELIMITER ;;
/*!50003 CREATE*/ /*!50017 DEFINER=`root`@`localhost`*/ /*!50003 TRIGGER insert_rule_gwgroup2lb
  AFTER INSERT
  ON dr_rules
  FOR EACH ROW
BEGIN
  
  IF (NEW.groupid = 9000) THEN
    IF (NEW.description REGEXP 'lb_enabled:1(,|$)') THEN
      UPDATE dsip_gwgroup2lb SET enabled = '1' WHERE gwgroupid = REPLACE(NEW.gwlist, '#', '');
    ELSE
      UPDATE dsip_gwgroup2lb SET enabled = '0' WHERE gwgroupid = REPLACE(NEW.gwlist, '#', '');
    END IF;
  END IF;
END */;;
DELIMITER ;
/*!50003 SET sql_mode              = @saved_sql_mode */ ;
/*!50003 SET character_set_client  = @saved_cs_client */ ;
/*!50003 SET character_set_results = @saved_cs_results */ ;
/*!50003 SET collation_connection  = @saved_col_connection */ ;
/*!50003 SET @saved_cs_client      = @@character_set_client */ ;
/*!50003 SET @saved_cs_results     = @@character_set_results */ ;
/*!50003 SET @saved_col_connection = @@collation_connection */ ;
/*!50003 SET character_set_client  = utf8mb3 */ ;
/*!50003 SET character_set_results = utf8mb3 */ ;
/*!50003 SET collation_connection  = utf8mb3_general_ci */ ;
/*!50003 SET @saved_sql_mode       = @@sql_mode */ ;
/*!50003 SET sql_mode              = 'STRICT_TRANS_TABLES,ERROR_FOR_DIVISION_BY_ZERO,NO_AUTO_CREATE_USER,NO_ENGINE_SUBSTITUTION' */ ;
DELIMITER ;;
/*!50003 CREATE*/ /*!50017 DEFINER=`root`@`localhost`*/ /*!50003 TRIGGER update_rule_gwgroup2lb
  AFTER UPDATE
  ON dr_rules
  FOR EACH ROW
BEGIN
  DECLARE v_gwgroupid varchar(64) DEFAULT NULL;
  DECLARE v_description varchar(255) DEFAULT '';
  DECLARE v_groupid varchar(255) DEFAULT '';

  SET v_gwgroupid = REPLACE(COALESCE(NEW.gwlist, OLD.gwlist), '#', '');
  SET v_description = COALESCE(NEW.description, OLD.description);
  SET v_groupid = CAST(COALESCE(NEW.groupid, OLD.groupid) AS int);

  
  IF (v_groupid = 9000) THEN
    IF (v_description REGEXP 'lb_enabled:1(,|$)') THEN
      UPDATE dsip_gwgroup2lb SET enabled = '1' WHERE gwgroupid = v_gwgroupid;
    ELSE
      UPDATE dsip_gwgroup2lb SET enabled = '0' WHERE gwgroupid = v_gwgroupid;
    END IF;
  END IF;
END */;;
DELIMITER ;
/*!50003 SET sql_mode              = @saved_sql_mode */ ;
/*!50003 SET character_set_client  = @saved_cs_client */ ;
/*!50003 SET character_set_results = @saved_cs_results */ ;
/*!50003 SET collation_connection  = @saved_col_connection */ ;
/*!50003 SET @saved_cs_client      = @@character_set_client */ ;
/*!50003 SET @saved_cs_results     = @@character_set_results */ ;
/*!50003 SET @saved_col_connection = @@collation_connection */ ;
/*!50003 SET character_set_client  = utf8mb3 */ ;
/*!50003 SET character_set_results = utf8mb3 */ ;
/*!50003 SET collation_connection  = utf8mb3_general_ci */ ;
/*!50003 SET @saved_sql_mode       = @@sql_mode */ ;
/*!50003 SET sql_mode              = 'STRICT_TRANS_TABLES,ERROR_FOR_DIVISION_BY_ZERO,NO_AUTO_CREATE_USER,NO_ENGINE_SUBSTITUTION' */ ;
DELIMITER ;;
/*!50003 CREATE*/ /*!50017 DEFINER=`root`@`localhost`*/ /*!50003 TRIGGER delete_rule_gwgroup2lb
  AFTER DELETE
  ON dr_rules
  FOR EACH ROW
BEGIN
  
  IF (OLD.groupid = 9000) THEN
    
    IF ((SELECT COUNT(ruleid) FROM dr_rules WHERE gwlist=OLD.gwlist AND groupid=OLD.groupid AND ruleid!=OLD.ruleid) = 0) THEN
      DELETE FROM dsip_gwgroup2lb WHERE gwgroupid=REPLACE(OLD.gwlist, '#', '');
    END IF;
  END IF;
END */;;
DELIMITER ;
/*!50003 SET sql_mode              = @saved_sql_mode */ ;
/*!50003 SET character_set_client  = @saved_cs_client */ ;
/*!50003 SET character_set_results = @saved_cs_results */ ;
/*!50003 SET collation_connection  = @saved_col_connection */ ;

--
-- Table structure for table `dsip_agent`
--

DROP TABLE IF EXISTS `dsip_agent`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8mb4 */;
CREATE TABLE `dsip_agent` (
  `id` int(10) NOT NULL AUTO_INCREMENT,
  `name` varchar(255) NOT NULL,
  `type` varchar(128) NOT NULL,
  `project-id` varchar(255) NOT NULL,
  `greeting-message` varchar(512) NOT NULL,
  `instructions` varchar(1024) NOT NULL,
  `instructions_id` int(10) NOT NULL DEFAULT 0,
  `guardrails` varchar(255) NOT NULL DEFAULT '',
  `tools` varchar(255) NOT NULL DEFAULT '',
  `callback-email` varchar(255) NOT NULL DEFAULT '',
  `deployment-type` varchar(255) NOT NULL DEFAULT '',
  `deployment-profile-id` int(10) NOT NULL DEFAULT 0,
  `created_at` timestamp NOT NULL DEFAULT current_timestamp() ON UPDATE current_timestamp(),
  `modified_at` timestamp NOT NULL DEFAULT current_timestamp() ON UPDATE current_timestamp(),
  `status` int(2) NOT NULL DEFAULT 0,
  `error` varchar(200) NOT NULL DEFAULT '',
  PRIMARY KEY (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb3 COLLATE=utf8mb3_general_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `dsip_agent`
--

LOCK TABLES `dsip_agent` WRITE;
/*!40000 ALTER TABLE `dsip_agent` DISABLE KEYS */;
/*!40000 ALTER TABLE `dsip_agent` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `dsip_call_settings`
--

DROP TABLE IF EXISTS `dsip_call_settings`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8mb4 */;
CREATE TABLE `dsip_call_settings` (
  `gwgroupid` int(10) unsigned NOT NULL,
  `limit` int(10) unsigned DEFAULT NULL,
  `timeout` int(10) unsigned DEFAULT NULL,
  PRIMARY KEY (`gwgroupid`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb3 COLLATE=utf8mb3_general_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `dsip_call_settings`
--

LOCK TABLES `dsip_call_settings` WRITE;
/*!40000 ALTER TABLE `dsip_call_settings` DISABLE KEYS */;
INSERT INTO `dsip_call_settings` VALUES
(11,NULL,NULL),
(13,NULL,NULL),
(14,NULL,NULL),
(15,NULL,NULL),
(16,NULL,NULL),
(17,NULL,NULL),
(18,NULL,NULL),
(19,NULL,NULL),
(20,NULL,NULL),
(23,NULL,NULL),
(24,NULL,NULL),
(25,NULL,NULL),
(32,NULL,NULL),
(37,NULL,NULL);
/*!40000 ALTER TABLE `dsip_call_settings` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Temporary table structure for view `dsip_call_settings_h`
--

DROP TABLE IF EXISTS `dsip_call_settings_h`;
/*!50001 DROP VIEW IF EXISTS `dsip_call_settings_h`*/;
SET @saved_cs_client     = @@character_set_client;
SET character_set_client = utf8mb4;
/*!50001 CREATE VIEW `dsip_call_settings_h` AS SELECT
 1 AS `gwgroupid`,
  1 AS `limit`,
  1 AS `timeout` */;
SET character_set_client = @saved_cs_client;

--
-- Table structure for table `dsip_cdrinfo`
--

DROP TABLE IF EXISTS `dsip_cdrinfo`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8mb4 */;
CREATE TABLE `dsip_cdrinfo` (
  `gwgroupid` int(11) NOT NULL,
  `email` varchar(255) NOT NULL DEFAULT '',
  `send_interval` varchar(255) NOT NULL DEFAULT '* * 1 * *',
  `last_sent` timestamp NOT NULL DEFAULT current_timestamp() ON UPDATE current_timestamp(),
  PRIMARY KEY (`gwgroupid`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb3 COLLATE=utf8mb3_general_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `dsip_cdrinfo`
--

LOCK TABLES `dsip_cdrinfo` WRITE;
/*!40000 ALTER TABLE `dsip_cdrinfo` DISABLE KEYS */;
/*!40000 ALTER TABLE `dsip_cdrinfo` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `dsip_certificates`
--

DROP TABLE IF EXISTS `dsip_certificates`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8mb4 */;
CREATE TABLE `dsip_certificates` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `domain` varchar(128) DEFAULT NULL,
  `type` varchar(45) DEFAULT NULL,
  `email` varchar(128) DEFAULT NULL,
  `cert` blob DEFAULT NULL,
  `key` blob DEFAULT NULL,
  PRIMARY KEY (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb3 COLLATE=utf8mb3_general_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `dsip_certificates`
--

LOCK TABLES `dsip_certificates` WRITE;
/*!40000 ALTER TABLE `dsip_certificates` DISABLE KEYS */;
/*!40000 ALTER TABLE `dsip_certificates` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `dsip_dnid_enrich_lnp`
--

DROP TABLE IF EXISTS `dsip_dnid_enrich_lnp`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8mb4 */;
CREATE TABLE `dsip_dnid_enrich_lnp` (
  `id` int(10) unsigned NOT NULL AUTO_INCREMENT,
  `dnid` varchar(64) NOT NULL,
  `country_code` varchar(64) NOT NULL DEFAULT '',
  `routing_number` varchar(64) NOT NULL DEFAULT '',
  `description` varchar(128) NOT NULL DEFAULT '',
  PRIMARY KEY (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb3 COLLATE=utf8mb3_general_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `dsip_dnid_enrich_lnp`
--

LOCK TABLES `dsip_dnid_enrich_lnp` WRITE;
/*!40000 ALTER TABLE `dsip_dnid_enrich_lnp` DISABLE KEYS */;
/*!40000 ALTER TABLE `dsip_dnid_enrich_lnp` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Temporary table structure for view `dsip_dnid_lnp_mapping`
--

DROP TABLE IF EXISTS `dsip_dnid_lnp_mapping`;
/*!50001 DROP VIEW IF EXISTS `dsip_dnid_lnp_mapping`*/;
SET @saved_cs_client     = @@character_set_client;
SET character_set_client = utf8mb4;
/*!50001 CREATE VIEW `dsip_dnid_lnp_mapping` AS SELECT
 1 AS `dnid`,
  1 AS `prefix`,
  1 AS `key_type`,
  1 AS `value_type` */;
SET character_set_client = @saved_cs_client;

--
-- Table structure for table `dsip_domain_mapping`
--

DROP TABLE IF EXISTS `dsip_domain_mapping`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8mb4 */;
CREATE TABLE `dsip_domain_mapping` (
  `id` int(10) NOT NULL AUTO_INCREMENT,
  `pbx_id` int(10) NOT NULL,
  `domain_id` int(10) NOT NULL,
  `attr_list` varchar(255) NOT NULL,
  `type` tinyint(3) NOT NULL DEFAULT 0,
  `enabled` tinyint(1) NOT NULL DEFAULT 0,
  PRIMARY KEY (`id`)
) ENGINE=InnoDB AUTO_INCREMENT=4 DEFAULT CHARSET=utf8mb3 COLLATE=utf8mb3_general_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `dsip_domain_mapping`
--

LOCK TABLES `dsip_domain_mapping` WRITE;
/*!40000 ALTER TABLE `dsip_domain_mapping` DISABLE KEYS */;
/*!40000 ALTER TABLE `dsip_domain_mapping` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `dsip_endpoint_lease`
--

DROP TABLE IF EXISTS `dsip_endpoint_lease`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8mb4 */;
CREATE TABLE `dsip_endpoint_lease` (
  `id` int(10) unsigned NOT NULL AUTO_INCREMENT,
  `gwid` int(10) unsigned NOT NULL,
  `sid` int(10) unsigned NOT NULL,
  `expiration` datetime NOT NULL,
  PRIMARY KEY (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb3 COLLATE=utf8mb3_general_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `dsip_endpoint_lease`
--

LOCK TABLES `dsip_endpoint_lease` WRITE;
/*!40000 ALTER TABLE `dsip_endpoint_lease` DISABLE KEYS */;
/*!40000 ALTER TABLE `dsip_endpoint_lease` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `dsip_failfwd`
--

DROP TABLE IF EXISTS `dsip_failfwd`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8mb4 */;
CREATE TABLE `dsip_failfwd` (
  `dr_ruleid` varchar(64) NOT NULL,
  `did` varchar(64) NOT NULL,
  `dr_groupid` varchar(64) NOT NULL,
  `key_type` varchar(64) NOT NULL DEFAULT '0',
  `value_type` varchar(64) NOT NULL DEFAULT '0',
  PRIMARY KEY (`dr_ruleid`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb3 COLLATE=utf8mb3_general_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `dsip_failfwd`
--

LOCK TABLES `dsip_failfwd` WRITE;
/*!40000 ALTER TABLE `dsip_failfwd` DISABLE KEYS */;
/*!40000 ALTER TABLE `dsip_failfwd` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `dsip_gw2gwgroup`
--

DROP TABLE IF EXISTS `dsip_gw2gwgroup`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8mb4 */;
CREATE TABLE `dsip_gw2gwgroup` (
  `gwid` varchar(64) NOT NULL,
  `gwgroupid` varchar(64) NOT NULL,
  `key_type` varchar(64) NOT NULL DEFAULT '0',
  `value_type` varchar(64) NOT NULL DEFAULT '0',
  PRIMARY KEY (`gwid`,`gwgroupid`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb3 COLLATE=utf8mb3_general_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `dsip_gw2gwgroup`
--

LOCK TABLES `dsip_gw2gwgroup` WRITE;
/*!40000 ALTER TABLE `dsip_gw2gwgroup` DISABLE KEYS */;
INSERT INTO `dsip_gw2gwgroup` VALUES
('1','1','0','0'),
('10','2','0','0'),
('11','2','0','0'),
('12','2','0','0'),
('13','2','0','0'),
('14','2','0','0'),
('15','2','0','0'),
('154','32','0','0'),
('16','2','0','0'),
('17','2','0','0'),
('18','2','0','0'),
('19','2','0','0'),
('2','1','0','0'),
('21','3','0','0'),
('23','3','0','0'),
('24','4','0','0'),
('25','4','0','0'),
('26','4','0','0'),
('27','4','0','0'),
('28','4','0','0'),
('29','4','0','0'),
('290','35','0','0'),
('3','1','0','0'),
('30','5','0','0'),
('31','5','0','0'),
('32','5','0','0'),
('33','5','0','0'),
('337','32','0','0'),
('34','5','0','0'),
('341','37','0','0'),
('342','37','0','0'),
('35','5','0','0'),
('36','5','0','0'),
('37','5','0','0'),
('38','5','0','0'),
('39','5','0','0'),
('4','1','0','0'),
('40','5','0','0'),
('41','5','0','0'),
('42','5','0','0'),
('43','5','0','0'),
('44','5','0','0'),
('45','5','0','0'),
('46','6','0','0'),
('47','6','0','0'),
('48','6','0','0'),
('49','6','0','0'),
('5','1','0','0'),
('50','7','0','0'),
('51','8','0','0'),
('52','9','0','0'),
('53','10','0','0'),
('54','10','0','0'),
('55','10','0','0'),
('56','11','0','0'),
('57','12','0','0'),
('58','13','0','0'),
('59','14','0','0'),
('6','1','0','0'),
('60','15','0','0'),
('61','16','0','0'),
('62','17','0','0'),
('63','18','0','0'),
('64','19','0','0'),
('65','20','0','0'),
('66','23','0','0'),
('67','24','0','0'),
('68','25','0','0'),
('7','1','0','0'),
('8','1','0','0'),
('9','2','0','0');
/*!40000 ALTER TABLE `dsip_gw2gwgroup` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `dsip_gwgroup2lb`
--

DROP TABLE IF EXISTS `dsip_gwgroup2lb`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8mb4 */;
CREATE TABLE `dsip_gwgroup2lb` (
  `gwgroupid` varchar(64) NOT NULL,
  `setid` varchar(64) NOT NULL,
  `enabled` char(1) NOT NULL DEFAULT '0',
  `key_type` varchar(64) NOT NULL DEFAULT '0',
  `value_type` varchar(64) NOT NULL DEFAULT '0',
  PRIMARY KEY (`gwgroupid`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `dsip_gwgroup2lb`
--

LOCK TABLES `dsip_gwgroup2lb` WRITE;
/*!40000 ALTER TABLE `dsip_gwgroup2lb` DISABLE KEYS */;
INSERT INTO `dsip_gwgroup2lb` VALUES
('1','1','0','0','0'),
('10','10','0','0','0'),
('11','11','0','0','0'),
('12','12','0','0','0'),
('13','13','0','0','0'),
('14','14','1','0','0'),
('15','15','1','0','0'),
('16','16','1','0','0'),
('17','17','1','0','0'),
('18','18','0','0','0'),
('2','2','0','0','0'),
('20','20','0','0','0'),
('21','21','0','0','0'),
('22','22','0','0','0'),
('23','23','0','0','0'),
('24','24','0','0','0'),
('25','25','1','0','0'),
('3','3','0','0','0'),
('32','32','0','0','0'),
('33','33','0','0','0'),
('34','34','0','0','0'),
('35','35','0','0','0'),
('37','1037','0','0','0'),
('4','4','0','0','0'),
('5','5','0','0','0'),
('6','6','0','0','0'),
('7','7','0','0','0'),
('8','8','0','0','0'),
('9','9','0','0','0');
/*!40000 ALTER TABLE `dsip_gwgroup2lb` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `dsip_hardfwd`
--

DROP TABLE IF EXISTS `dsip_hardfwd`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8mb4 */;
CREATE TABLE `dsip_hardfwd` (
  `dr_ruleid` varchar(64) NOT NULL,
  `did` varchar(64) NOT NULL,
  `dr_groupid` varchar(64) NOT NULL,
  `key_type` varchar(64) NOT NULL DEFAULT '0',
  `value_type` varchar(64) NOT NULL DEFAULT '0',
  PRIMARY KEY (`dr_ruleid`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb3 COLLATE=utf8mb3_general_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `dsip_hardfwd`
--

LOCK TABLES `dsip_hardfwd` WRITE;
/*!40000 ALTER TABLE `dsip_hardfwd` DISABLE KEYS */;
/*!40000 ALTER TABLE `dsip_hardfwd` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `dsip_lcr`
--

DROP TABLE IF EXISTS `dsip_lcr`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8mb4 */;
CREATE TABLE `dsip_lcr` (
  `pattern` varchar(64) NOT NULL DEFAULT '',
  `key_type` varchar(64) NOT NULL DEFAULT '0',
  `dr_groupid` varchar(64) NOT NULL DEFAULT '',
  `value_type` varchar(64) NOT NULL DEFAULT '0',
  `cost` decimal(3,2) NOT NULL DEFAULT 0.00,
  `from_prefix` varchar(64) NOT NULL DEFAULT '',
  `expires` int(11) NOT NULL DEFAULT 0,
  PRIMARY KEY (`pattern`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb3 COLLATE=utf8mb3_general_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `dsip_lcr`
--

LOCK TABLES `dsip_lcr` WRITE;
/*!40000 ALTER TABLE `dsip_lcr` DISABLE KEYS */;
/*!40000 ALTER TABLE `dsip_lcr` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `dsip_maintmode`
--

DROP TABLE IF EXISTS `dsip_maintmode`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8mb4 */;
CREATE TABLE `dsip_maintmode` (
  `ipaddr` varchar(64) NOT NULL DEFAULT '',
  `key_type` varchar(64) NOT NULL DEFAULT '0',
  `gwid` varchar(64) NOT NULL DEFAULT '',
  `value_type` varchar(64) NOT NULL DEFAULT '0',
  `status` tinyint(4) NOT NULL DEFAULT 1,
  PRIMARY KEY (`ipaddr`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb3 COLLATE=utf8mb3_general_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `dsip_maintmode`
--

LOCK TABLES `dsip_maintmode` WRITE;
/*!40000 ALTER TABLE `dsip_maintmode` DISABLE KEYS */;
/*!40000 ALTER TABLE `dsip_maintmode` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `dsip_multidomain_mapping`
--

DROP TABLE IF EXISTS `dsip_multidomain_mapping`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8mb4 */;
CREATE TABLE `dsip_multidomain_mapping` (
  `id` int(10) NOT NULL AUTO_INCREMENT,
  `pbx_id` int(10) NOT NULL,
  `db_host` varchar(255) NOT NULL,
  `db_username` varchar(255) NOT NULL,
  `db_password` varchar(255) NOT NULL,
  `domain_list` varchar(255) NOT NULL DEFAULT '',
  `domain_list_hash` varchar(255) NOT NULL DEFAULT '',
  `attr_list` varchar(255) NOT NULL DEFAULT '',
  `type` tinyint(3) NOT NULL DEFAULT 0,
  `enabled` tinyint(1) NOT NULL DEFAULT 0,
  `lastsync` timestamp NOT NULL DEFAULT current_timestamp() ON UPDATE current_timestamp(),
  `syncstatus` tinyint(1) NOT NULL DEFAULT 0,
  `syncerror` varchar(200) NOT NULL DEFAULT '',
  PRIMARY KEY (`id`)
) ENGINE=InnoDB AUTO_INCREMENT=3 DEFAULT CHARSET=utf8mb3 COLLATE=utf8mb3_general_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `dsip_multidomain_mapping`
--

LOCK TABLES `dsip_multidomain_mapping` WRITE;
/*!40000 ALTER TABLE `dsip_multidomain_mapping` DISABLE KEYS */;
INSERT INTO `dsip_multidomain_mapping` VALUES
(2,37,'fusionpbx.dsiprouter.net','fusionpbx','','38,39,40,41,42,43,44,45,46,47,48,49,50,51,52,53,54,55,56,57,58,59,60,61,62,63,64,65,66,67,68,69,70,71,72,73','b2bc32f8dd2da8ef86ae0c83313092c2','',2,1,'2026-03-14 14:48:01',2,'');
/*!40000 ALTER TABLE `dsip_multidomain_mapping` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `dsip_notification`
--

DROP TABLE IF EXISTS `dsip_notification`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8mb4 */;
CREATE TABLE `dsip_notification` (
  `gwgroupid` int(11) NOT NULL,
  `type` int(11) NOT NULL,
  `method` int(11) DEFAULT NULL,
  `value` varchar(255) DEFAULT NULL,
  `createdate` timestamp NOT NULL DEFAULT current_timestamp() ON UPDATE current_timestamp(),
  PRIMARY KEY (`gwgroupid`,`type`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb3 COLLATE=utf8mb3_general_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `dsip_notification`
--

LOCK TABLES `dsip_notification` WRITE;
/*!40000 ALTER TABLE `dsip_notification` DISABLE KEYS */;
INSERT INTO `dsip_notification` VALUES
(11,0,0,'','2025-07-17 21:55:00'),
(11,1,0,'','2025-07-17 21:55:00'),
(13,0,0,'','2025-10-23 17:52:09'),
(13,1,0,'','2025-10-23 17:52:09'),
(14,0,0,'','2025-10-23 23:06:28'),
(14,1,0,'','2025-10-23 23:06:28'),
(15,0,0,'','2025-11-06 19:22:05'),
(15,1,0,'','2025-11-06 19:22:05'),
(16,0,0,'','2025-11-11 23:47:40'),
(16,1,0,'','2025-11-11 23:47:40'),
(17,0,0,'','2025-12-10 03:53:40'),
(17,1,0,'','2025-12-10 03:53:40'),
(19,0,0,'','2026-01-12 03:32:27'),
(19,1,0,'','2026-01-12 03:32:27'),
(20,0,0,'','2026-01-12 18:47:08'),
(20,1,0,'','2026-01-12 18:47:08'),
(23,0,0,'','2026-01-13 01:41:08'),
(23,1,0,'','2026-01-13 01:41:08'),
(24,0,0,'','2026-01-13 03:19:15'),
(24,1,0,'','2026-01-13 03:19:15'),
(25,0,0,'','2026-01-22 18:59:05'),
(25,1,0,'','2026-01-22 18:59:05'),
(32,0,0,'','2026-02-13 03:45:40'),
(32,1,0,'','2026-02-13 03:45:40'),
(37,0,0,'','2026-03-11 12:25:41'),
(37,1,0,'','2026-03-11 12:25:41');
/*!40000 ALTER TABLE `dsip_notification` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `dsip_number`
--

DROP TABLE IF EXISTS `dsip_number`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8mb4 */;
CREATE TABLE `dsip_number` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `did` varchar(64) NOT NULL,
  `status` varchar(64) DEFAULT NULL,
  `carrier` varchar(128) DEFAULT NULL,
  `pool` varchar(128) DEFAULT NULL,
  `assigned_length` varchar(256) DEFAULT NULL,
  `assigned_reference_id` varchar(256) DEFAULT NULL,
  `assigned_date` datetime DEFAULT NULL,
  `date_created` datetime DEFAULT NULL,
  PRIMARY KEY (`id`)
) ENGINE=InnoDB AUTO_INCREMENT=2 DEFAULT CHARSET=utf8mb3 COLLATE=utf8mb3_general_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `dsip_number`
--

LOCK TABLES `dsip_number` WRITE;
/*!40000 ALTER TABLE `dsip_number` DISABLE KEYS */;
INSERT INTO `dsip_number` VALUES
(1,'1314344111','unassigned','carrier1','pool1','','',NULL,'2026-03-14 04:27:38');
/*!40000 ALTER TABLE `dsip_number` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Temporary table structure for view `dsip_prefix_mapping`
--

DROP TABLE IF EXISTS `dsip_prefix_mapping`;
/*!50001 DROP VIEW IF EXISTS `dsip_prefix_mapping`*/;
SET @saved_cs_client     = @@character_set_client;
SET character_set_client = utf8mb4;
/*!50001 CREATE VIEW `dsip_prefix_mapping` AS SELECT
 1 AS `prefix`,
  1 AS `ruleid`,
  1 AS `priority`,
  1 AS `key_type`,
  1 AS `value_type` */;
SET character_set_client = @saved_cs_client;

--
-- Table structure for table `dsip_settings`
--

DROP TABLE IF EXISTS `dsip_settings`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8mb4 */;
CREATE TABLE `dsip_settings` (
  `DSIP_ID` varbinary(128) NOT NULL,
  `DSIP_CLUSTER_ID` int(10) unsigned NOT NULL DEFAULT 1,
  `DSIP_CLUSTER_SYNC` tinyint(1) NOT NULL DEFAULT 1,
  `DSIP_PROTO` varchar(16) NOT NULL DEFAULT 'http',
  `DSIP_PORT` int(11) NOT NULL DEFAULT 5000,
  `DSIP_USERNAME` varchar(255) NOT NULL DEFAULT 'admin',
  `DSIP_PASSWORD` varbinary(128) NOT NULL,
  `DSIP_IPC_PASS` varbinary(144) NOT NULL,
  `DSIP_API_PROTO` varchar(16) NOT NULL DEFAULT 'http',
  `DSIP_API_PORT` int(11) NOT NULL DEFAULT 5000,
  `DSIP_PRIV_KEY` varchar(255) NOT NULL DEFAULT '/etc/dsiprouter/privkey',
  `DSIP_PID_FILE` varchar(255) NOT NULL DEFAULT '/run/dsiprouter/dsiprouter.pid',
  `DSIP_UNIX_SOCK` varchar(255) NOT NULL DEFAULT '/run/dsiprouter/dsiprouter.sock',
  `DSIP_IPC_SOCK` varchar(255) NOT NULL DEFAULT '/run/dsiprouter/ipc.sock',
  `DSIP_API_TOKEN` varbinary(144) NOT NULL,
  `DSIP_LOG_LEVEL` int(11) NOT NULL DEFAULT 3,
  `DSIP_LOG_FACILITY` int(11) NOT NULL DEFAULT 18,
  `DSIP_SSL_KEY` varchar(255) NOT NULL DEFAULT '',
  `DSIP_SSL_CERT` varchar(255) NOT NULL DEFAULT '',
  `DSIP_SSL_CA` varchar(255) NOT NULL DEFAULT '/etc/dsiprouter/certs/ca-list.pem',
  `DSIP_SSL_EMAIL` varchar(255) NOT NULL DEFAULT '',
  `DSIP_CERTS_DIR` varchar(255) NOT NULL DEFAULT '/etc/dsiprouter/certs',
  `VERSION` varchar(32) NOT NULL,
  `DEBUG` tinyint(1) NOT NULL DEFAULT 0,
  `ROLE` varchar(32) NOT NULL DEFAULT '',
  `GUI_INACTIVE_TIMEOUT` int(10) unsigned NOT NULL DEFAULT 20,
  `KAM_DB_HOST` varchar(255) NOT NULL DEFAULT 'localhost',
  `KAM_DB_DRIVER` varchar(255) NOT NULL DEFAULT '',
  `KAM_DB_TYPE` varchar(255) NOT NULL DEFAULT 'mysql',
  `KAM_DB_PORT` varchar(255) NOT NULL DEFAULT '3306',
  `KAM_DB_NAME` varchar(255) NOT NULL DEFAULT 'kamailio',
  `KAM_DB_USER` varchar(255) NOT NULL DEFAULT 'kamailio',
  `KAM_DB_PASS` varbinary(144) NOT NULL,
  `KAM_KAMCMD_PATH` varchar(255) NOT NULL DEFAULT '/usr/sbin/kamcmd',
  `KAM_CFG_PATH` varchar(255) NOT NULL DEFAULT '/etc/kamailio/kamailio.cfg',
  `KAM_TLSCFG_PATH` varchar(255) NOT NULL DEFAULT '/etc/kamailio/tls.cfg',
  `RTP_CFG_PATH` varchar(255) NOT NULL DEFAULT '/etc/kamailio/kamailio.cfg',
  `FLT_CARRIER` int(11) NOT NULL DEFAULT 8,
  `FLT_PBX` int(11) NOT NULL DEFAULT 9,
  `FLT_MSTEAMS` int(11) NOT NULL DEFAULT 17,
  `FLT_OUTBOUND` int(11) NOT NULL DEFAULT 8000,
  `FLT_INBOUND` int(11) NOT NULL DEFAULT 9000,
  `FLT_LCR_MIN` int(11) NOT NULL DEFAULT 10000,
  `FLT_FWD_MIN` int(11) NOT NULL DEFAULT 20000,
  `DEFAULT_AUTH_DOMAIN` varchar(255) NOT NULL DEFAULT 'sip.dsiprouter.org',
  `TELEBLOCK_GW_ENABLED` tinyint(1) NOT NULL DEFAULT 0,
  `TELEBLOCK_GW_IP` varchar(255) NOT NULL DEFAULT '62.34.24.22',
  `TELEBLOCK_GW_PORT` varchar(255) NOT NULL DEFAULT '5066',
  `TELEBLOCK_MEDIA_IP` varchar(255) NOT NULL DEFAULT '',
  `TELEBLOCK_MEDIA_PORT` varchar(255) NOT NULL DEFAULT '',
  `FLOWROUTE_ACCESS_KEY` varchar(255) NOT NULL DEFAULT '',
  `FLOWROUTE_SECRET_KEY` varchar(255) NOT NULL DEFAULT '',
  `FLOWROUTE_API_ROOT_URL` varchar(255) NOT NULL DEFAULT 'https://api.flowroute.com/v2',
  `HOMER_ID` bigint(20) NOT NULL,
  `HOMER_HEP_HOST` varchar(255) NOT NULL DEFAULT '',
  `HOMER_HEP_PORT` int(11) NOT NULL DEFAULT 9060,
  `NETWORK_MODE` int(11) NOT NULL DEFAULT 0,
  `IPV6_ENABLED` tinyint(1) NOT NULL DEFAULT 0,
  `INTERNAL_IP_ADDR` varchar(255) NOT NULL DEFAULT '',
  `INTERNAL_IP_NET` varchar(255) NOT NULL DEFAULT '',
  `INTERNAL_IP6_ADDR` varchar(255) NOT NULL DEFAULT '',
  `INTERNAL_IP6_NET` varchar(255) NOT NULL DEFAULT '',
  `INTERNAL_FQDN` varchar(255) NOT NULL DEFAULT '',
  `EXTERNAL_IP_ADDR` varchar(255) NOT NULL DEFAULT '',
  `EXTERNAL_IP6_ADDR` varchar(255) NOT NULL DEFAULT '',
  `EXTERNAL_FQDN` varchar(255) NOT NULL DEFAULT '',
  `PUBLIC_IFACE` varchar(255) NOT NULL DEFAULT '',
  `PRIVATE_IFACE` varchar(255) NOT NULL DEFAULT '',
  `UPLOAD_FOLDER` varchar(255) NOT NULL DEFAULT '/tmp',
  `MAIL_SERVER` varchar(255) NOT NULL DEFAULT 'smtp.gmail.com',
  `MAIL_PORT` int(11) NOT NULL DEFAULT 587,
  `MAIL_USE_TLS` tinyint(1) NOT NULL DEFAULT 1,
  `MAIL_USERNAME` varchar(255) NOT NULL DEFAULT '',
  `MAIL_PASSWORD` varbinary(144) NOT NULL,
  `MAIL_ASCII_ATTACHMENTS` tinyint(1) NOT NULL DEFAULT 0,
  `MAIL_DEFAULT_SENDER` varchar(255) NOT NULL DEFAULT 'DoNotReply@smtp.gmail.com',
  `MAIL_DEFAULT_SUBJECT` varchar(255) NOT NULL DEFAULT 'dSIPRouter System Notification',
  `DSIP_LICENSE_STORE` blob NOT NULL,
  `RTPENGINE_URI` varchar(255) NOT NULL DEFAULT 'udp:localhost:7722',
  PRIMARY KEY (`DSIP_ID`),
  CONSTRAINT `CONSTRAINT_1` CHECK (`ROLE` in ('','outbound','inout'))
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci MIN_ROWS=1;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `dsip_settings`
--

LOCK TABLES `dsip_settings` WRITE;
/*!40000 ALTER TABLE `dsip_settings` DISABLE KEYS */;
INSERT INTO `dsip_settings` VALUES
('0e0f26d213aac4562d8ccea623112e1fac347b570da112b511da2ede675f204035a92fafc2c6ca0d8687f540ab20adee46653845393864334446463741644632',1,0,'https',5000,'admin','94e66ef3e4f0ed3dd9131e83b38889c832cc9d0947a01920b271aef160fc7b78dc175ec3c2ef631dd958cc4a1e82649a63313641434234354531363641326136','f4bef215ea23eab21ec9d2632e43746ec3a1613e1dba74b56127d4967556e9e422554f15500bc6063921f353b514d0763cb66b01a2448f17fef6b166f0c6cf7dc89c283e299e7d32','https',5000,'/etc/dsiprouter/privkey','/run/dsiprouter/dsiprouter.pid','/run/dsiprouter/dsiprouter.sock','/run/dsiprouter/ipc.sock','cdfb19b6a6175589eea80b07d7c4913fdb65fc',3,18,'/etc/dsiprouter/certs/dsiprouter-key.pem','/etc/dsiprouter/certs/dsiprouter-cert.pem','/etc/dsiprouter/certs/ca-list.pem','admin@mack.test.dsiprouter.net','/etc/dsiprouter/certs','0.78',0,'',20,'localhost','','mysql','3306','kamailio','kamailio','e8811975e7114b59f90b9a8552eafaa745f5d446e6e54d8f9775280d70af568d9d1ded7318623eff4aaace7ba46620a9fee40a2b5cfe41c4cc6cd123ee7728e9199242e9074a450a','/usr/sbin/kamcmd','/etc/kamailio/kamailio.cfg','/etc/kamailio/tls.cfg','/etc/rtpengine/rtpengine.conf',8,9,17,8000,9000,10000,20000,'sip6.dsiprouter.org',0,'62.34.24.22','5066','','','a4d64247','c97527888b0e40cda3f2a61e54784fe4','https://api.flowroute.com/v2',3792440501,'',9060,0,0,'146.190.253.188','146.190.253.188/20','fe80::ccc2:a0ff:fe0a:3cfc','','aq.test.dsiprouter.net','146.190.253.188','fe80::ccc2:a0ff:fe0a:3cfc','mack.test.dsiprouter.net','','','/tmp','smtp.gmail.com',587,1,'','',0,'dSIPRouter <donotreply@sip.dsiprouter.org>','dSIPRouter System Notification','nwAAAAUxMzQAkAAAAABhZTYyY2Q1MmJmYjkzZGRiMGEwMTRiNTAxNTc0YWRhZjQxMjYzMGMyYmM5NWU5N2UwZDMwNmM5ZTllNzAzN2QyMmMyMWM5ZWVkMzk3YTEzYWU4Zjg5Nzk0MzNlOWYzNDRkMmRjMTAzOTA5ZjkzNjhiYjRhOGViZjNlZDcxN2QxYzgyZWQxYjhiOGU0OTE2MzMA','udp:localhost:7722');
/*!40000 ALTER TABLE `dsip_settings` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `dsip_user`
--

DROP TABLE IF EXISTS `dsip_user`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8mb4 */;
CREATE TABLE `dsip_user` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `firstname` varchar(255) NOT NULL,
  `lastname` varchar(255) DEFAULT NULL,
  `username` varchar(255) NOT NULL,
  `password` varchar(255) NOT NULL,
  `roles` varchar(255) DEFAULT NULL,
  `domains` varchar(255) DEFAULT NULL,
  `token` varchar(255) DEFAULT NULL,
  `token_expiration` datetime DEFAULT NULL,
  PRIMARY KEY (`id`),
  UNIQUE KEY `id` (`id`),
  UNIQUE KEY `username` (`username`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb3 COLLATE=utf8mb3_general_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `dsip_user`
--

LOCK TABLES `dsip_user` WRITE;
/*!40000 ALTER TABLE `dsip_user` DISABLE KEYS */;
/*!40000 ALTER TABLE `dsip_user` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `globalblocklist`
--

DROP TABLE IF EXISTS `globalblocklist`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8mb4 */;
CREATE TABLE `globalblocklist` (
  `id` int(10) unsigned NOT NULL AUTO_INCREMENT,
  `prefix` varchar(64) NOT NULL DEFAULT '',
  `allowlist` tinyint(1) NOT NULL DEFAULT 0,
  `description` varchar(255) DEFAULT NULL,
  PRIMARY KEY (`id`),
  KEY `globalblocklist_idx` (`prefix`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb3 COLLATE=utf8mb3_general_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `globalblocklist`
--

LOCK TABLES `globalblocklist` WRITE;
/*!40000 ALTER TABLE `globalblocklist` DISABLE KEYS */;
/*!40000 ALTER TABLE `globalblocklist` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `grp`
--

DROP TABLE IF EXISTS `grp`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8mb4 */;
CREATE TABLE `grp` (
  `id` int(10) unsigned NOT NULL AUTO_INCREMENT,
  `username` varchar(64) NOT NULL DEFAULT '',
  `domain` varchar(64) NOT NULL DEFAULT '',
  `grp` varchar(64) NOT NULL DEFAULT '',
  `last_modified` datetime NOT NULL DEFAULT '2000-01-01 00:00:01',
  PRIMARY KEY (`id`),
  UNIQUE KEY `account_group_idx` (`username`,`domain`,`grp`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb3 COLLATE=utf8mb3_general_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `grp`
--

LOCK TABLES `grp` WRITE;
/*!40000 ALTER TABLE `grp` DISABLE KEYS */;
/*!40000 ALTER TABLE `grp` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `htable`
--

DROP TABLE IF EXISTS `htable`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8mb4 */;
CREATE TABLE `htable` (
  `id` int(10) unsigned NOT NULL AUTO_INCREMENT,
  `key_name` varchar(64) NOT NULL DEFAULT '',
  `key_type` int(11) NOT NULL DEFAULT 0,
  `value_type` int(11) NOT NULL DEFAULT 0,
  `key_value` varchar(128) NOT NULL DEFAULT '',
  `expires` int(11) NOT NULL DEFAULT 0,
  PRIMARY KEY (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb3 COLLATE=utf8mb3_general_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `htable`
--

LOCK TABLES `htable` WRITE;
/*!40000 ALTER TABLE `htable` DISABLE KEYS */;
/*!40000 ALTER TABLE `htable` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `imc_members`
--

DROP TABLE IF EXISTS `imc_members`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8mb4 */;
CREATE TABLE `imc_members` (
  `id` int(10) unsigned NOT NULL AUTO_INCREMENT,
  `username` varchar(64) NOT NULL,
  `domain` varchar(64) NOT NULL,
  `room` varchar(64) NOT NULL,
  `flag` int(11) NOT NULL,
  PRIMARY KEY (`id`),
  UNIQUE KEY `account_room_idx` (`username`,`domain`,`room`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb3 COLLATE=utf8mb3_general_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `imc_members`
--

LOCK TABLES `imc_members` WRITE;
/*!40000 ALTER TABLE `imc_members` DISABLE KEYS */;
/*!40000 ALTER TABLE `imc_members` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `imc_rooms`
--

DROP TABLE IF EXISTS `imc_rooms`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8mb4 */;
CREATE TABLE `imc_rooms` (
  `id` int(10) unsigned NOT NULL AUTO_INCREMENT,
  `name` varchar(64) NOT NULL,
  `domain` varchar(64) NOT NULL,
  `flag` int(11) NOT NULL,
  PRIMARY KEY (`id`),
  UNIQUE KEY `name_domain_idx` (`name`,`domain`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb3 COLLATE=utf8mb3_general_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `imc_rooms`
--

LOCK TABLES `imc_rooms` WRITE;
/*!40000 ALTER TABLE `imc_rooms` DISABLE KEYS */;
/*!40000 ALTER TABLE `imc_rooms` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `lcr_gw`
--

DROP TABLE IF EXISTS `lcr_gw`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8mb4 */;
CREATE TABLE `lcr_gw` (
  `id` int(10) unsigned NOT NULL AUTO_INCREMENT,
  `lcr_id` smallint(5) unsigned NOT NULL,
  `gw_name` varchar(128) DEFAULT NULL,
  `ip_addr` varchar(50) DEFAULT NULL,
  `hostname` varchar(64) DEFAULT NULL,
  `port` smallint(5) unsigned DEFAULT NULL,
  `params` varchar(64) DEFAULT NULL,
  `uri_scheme` tinyint(3) unsigned DEFAULT NULL,
  `transport` tinyint(3) unsigned DEFAULT NULL,
  `strip` tinyint(3) unsigned DEFAULT NULL,
  `prefix` varchar(16) DEFAULT NULL,
  `tag` varchar(64) DEFAULT NULL,
  `flags` int(10) unsigned NOT NULL DEFAULT 0,
  `defunct` int(10) unsigned DEFAULT NULL,
  PRIMARY KEY (`id`),
  KEY `lcr_id_idx` (`lcr_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb3 COLLATE=utf8mb3_general_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `lcr_gw`
--

LOCK TABLES `lcr_gw` WRITE;
/*!40000 ALTER TABLE `lcr_gw` DISABLE KEYS */;
/*!40000 ALTER TABLE `lcr_gw` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `lcr_rule`
--

DROP TABLE IF EXISTS `lcr_rule`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8mb4 */;
CREATE TABLE `lcr_rule` (
  `id` int(10) unsigned NOT NULL AUTO_INCREMENT,
  `lcr_id` smallint(5) unsigned NOT NULL,
  `prefix` varchar(16) DEFAULT NULL,
  `from_uri` varchar(64) DEFAULT NULL,
  `request_uri` varchar(64) DEFAULT NULL,
  `mt_tvalue` varchar(128) DEFAULT NULL,
  `stopper` int(10) unsigned NOT NULL DEFAULT 0,
  `enabled` int(10) unsigned NOT NULL DEFAULT 1,
  PRIMARY KEY (`id`),
  UNIQUE KEY `lcr_id_prefix_from_uri_idx` (`lcr_id`,`prefix`,`from_uri`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb3 COLLATE=utf8mb3_general_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `lcr_rule`
--

LOCK TABLES `lcr_rule` WRITE;
/*!40000 ALTER TABLE `lcr_rule` DISABLE KEYS */;
/*!40000 ALTER TABLE `lcr_rule` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `lcr_rule_target`
--

DROP TABLE IF EXISTS `lcr_rule_target`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8mb4 */;
CREATE TABLE `lcr_rule_target` (
  `id` int(10) unsigned NOT NULL AUTO_INCREMENT,
  `lcr_id` smallint(5) unsigned NOT NULL,
  `rule_id` int(10) unsigned NOT NULL,
  `gw_id` int(10) unsigned NOT NULL,
  `priority` tinyint(3) unsigned NOT NULL,
  `weight` int(10) unsigned NOT NULL DEFAULT 1,
  PRIMARY KEY (`id`),
  UNIQUE KEY `rule_id_gw_id_idx` (`rule_id`,`gw_id`),
  KEY `lcr_id_idx` (`lcr_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb3 COLLATE=utf8mb3_general_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `lcr_rule_target`
--

LOCK TABLES `lcr_rule_target` WRITE;
/*!40000 ALTER TABLE `lcr_rule_target` DISABLE KEYS */;
/*!40000 ALTER TABLE `lcr_rule_target` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `locale_lookup`
--

DROP TABLE IF EXISTS `locale_lookup`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8mb4 */;
CREATE TABLE `locale_lookup` (
  `id` int(10) unsigned NOT NULL AUTO_INCREMENT,
  `locale` varchar(64) NOT NULL DEFAULT '',
  `fprefix` varchar(64) NOT NULL DEFAULT '0',
  `tprefix` varchar(64) NOT NULL DEFAULT '0',
  PRIMARY KEY (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb3 COLLATE=utf8mb3_general_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `locale_lookup`
--

LOCK TABLES `locale_lookup` WRITE;
/*!40000 ALTER TABLE `locale_lookup` DISABLE KEYS */;
/*!40000 ALTER TABLE `locale_lookup` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `location`
--

DROP TABLE IF EXISTS `location`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8mb4 */;
CREATE TABLE `location` (
  `id` int(10) unsigned NOT NULL AUTO_INCREMENT,
  `ruid` varchar(64) NOT NULL DEFAULT '',
  `username` varchar(64) NOT NULL DEFAULT '',
  `domain` varchar(64) DEFAULT NULL,
  `contact` varchar(512) NOT NULL DEFAULT '',
  `received` varchar(128) DEFAULT NULL,
  `path` varchar(512) DEFAULT NULL,
  `expires` datetime NOT NULL DEFAULT '2030-05-28 21:32:15',
  `q` float(10,2) NOT NULL DEFAULT 1.00,
  `callid` varchar(255) NOT NULL DEFAULT 'Default-Call-ID',
  `cseq` int(11) NOT NULL DEFAULT 1,
  `last_modified` datetime NOT NULL DEFAULT '2000-01-01 00:00:01',
  `flags` int(11) NOT NULL DEFAULT 0,
  `cflags` int(11) NOT NULL DEFAULT 0,
  `user_agent` varchar(255) NOT NULL DEFAULT '',
  `socket` varchar(64) DEFAULT NULL,
  `methods` int(11) DEFAULT NULL,
  `instance` varchar(255) DEFAULT NULL,
  `reg_id` int(11) NOT NULL DEFAULT 0,
  `server_id` int(11) NOT NULL DEFAULT 0,
  `connection_id` int(11) NOT NULL DEFAULT 0,
  `keepalive` int(11) NOT NULL DEFAULT 0,
  `partition` int(11) NOT NULL DEFAULT 0,
  PRIMARY KEY (`id`),
  UNIQUE KEY `ruid_idx` (`ruid`),
  KEY `account_contact_idx` (`username`,`domain`,`contact`),
  KEY `expires_idx` (`expires`),
  KEY `tcpcon_idx` (`connection_id`),
  KEY `connection_idx` (`server_id`,`connection_id`)
) ENGINE=InnoDB AUTO_INCREMENT=156521 DEFAULT CHARSET=utf8mb3 COLLATE=utf8mb3_general_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `location`
--

LOCK TABLES `location` WRITE;
/*!40000 ALTER TABLE `location` DISABLE KEYS */;
/*!40000 ALTER TABLE `location` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `location_attrs`
--

DROP TABLE IF EXISTS `location_attrs`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8mb4 */;
CREATE TABLE `location_attrs` (
  `id` int(10) unsigned NOT NULL AUTO_INCREMENT,
  `ruid` varchar(64) NOT NULL DEFAULT '',
  `username` varchar(64) NOT NULL DEFAULT '',
  `domain` varchar(64) DEFAULT NULL,
  `aname` varchar(64) NOT NULL DEFAULT '',
  `atype` int(11) NOT NULL DEFAULT 0,
  `avalue` varchar(512) NOT NULL DEFAULT '',
  `last_modified` datetime NOT NULL DEFAULT '2000-01-01 00:00:01',
  PRIMARY KEY (`id`),
  KEY `account_record_idx` (`username`,`domain`,`ruid`),
  KEY `last_modified_idx` (`last_modified`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb3 COLLATE=utf8mb3_general_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `location_attrs`
--

LOCK TABLES `location_attrs` WRITE;
/*!40000 ALTER TABLE `location_attrs` DISABLE KEYS */;
/*!40000 ALTER TABLE `location_attrs` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `missed_calls`
--

DROP TABLE IF EXISTS `missed_calls`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8mb4 */;
CREATE TABLE `missed_calls` (
  `id` int(10) unsigned NOT NULL AUTO_INCREMENT,
  `method` varchar(16) NOT NULL DEFAULT '',
  `from_tag` varchar(128) NOT NULL DEFAULT '',
  `to_tag` varchar(128) NOT NULL DEFAULT '',
  `callid` varchar(255) NOT NULL DEFAULT '',
  `sip_code` varchar(3) NOT NULL DEFAULT '',
  `sip_reason` varchar(128) NOT NULL DEFAULT '',
  `time` datetime NOT NULL,
  PRIMARY KEY (`id`),
  KEY `callid_idx` (`callid`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb3 COLLATE=utf8mb3_general_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `missed_calls`
--

LOCK TABLES `missed_calls` WRITE;
/*!40000 ALTER TABLE `missed_calls` DISABLE KEYS */;
/*!40000 ALTER TABLE `missed_calls` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `mohqcalls`
--

DROP TABLE IF EXISTS `mohqcalls`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8mb4 */;
CREATE TABLE `mohqcalls` (
  `id` int(10) unsigned NOT NULL AUTO_INCREMENT,
  `mohq_id` int(10) unsigned NOT NULL,
  `call_id` varchar(100) NOT NULL,
  `call_status` int(10) unsigned NOT NULL,
  `call_from` varchar(100) NOT NULL,
  `call_contact` varchar(100) DEFAULT NULL,
  `call_time` datetime NOT NULL,
  PRIMARY KEY (`id`),
  UNIQUE KEY `mohqcalls_idx` (`call_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb3 COLLATE=utf8mb3_general_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `mohqcalls`
--

LOCK TABLES `mohqcalls` WRITE;
/*!40000 ALTER TABLE `mohqcalls` DISABLE KEYS */;
/*!40000 ALTER TABLE `mohqcalls` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `mohqueues`
--

DROP TABLE IF EXISTS `mohqueues`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8mb4 */;
CREATE TABLE `mohqueues` (
  `id` int(10) unsigned NOT NULL AUTO_INCREMENT,
  `name` varchar(25) NOT NULL,
  `uri` varchar(100) NOT NULL,
  `mohdir` varchar(100) DEFAULT NULL,
  `mohfile` varchar(100) NOT NULL,
  `debug` int(11) NOT NULL,
  PRIMARY KEY (`id`),
  UNIQUE KEY `mohqueue_uri_idx` (`uri`),
  UNIQUE KEY `mohqueue_name_idx` (`name`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb3 COLLATE=utf8mb3_general_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `mohqueues`
--

LOCK TABLES `mohqueues` WRITE;
/*!40000 ALTER TABLE `mohqueues` DISABLE KEYS */;
/*!40000 ALTER TABLE `mohqueues` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `mtree`
--

DROP TABLE IF EXISTS `mtree`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8mb4 */;
CREATE TABLE `mtree` (
  `id` int(10) unsigned NOT NULL AUTO_INCREMENT,
  `tprefix` varchar(32) NOT NULL DEFAULT '',
  `tvalue` varchar(128) NOT NULL DEFAULT '',
  PRIMARY KEY (`id`),
  UNIQUE KEY `tprefix_idx` (`tprefix`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb3 COLLATE=utf8mb3_general_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `mtree`
--

LOCK TABLES `mtree` WRITE;
/*!40000 ALTER TABLE `mtree` DISABLE KEYS */;
/*!40000 ALTER TABLE `mtree` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `mtrees`
--

DROP TABLE IF EXISTS `mtrees`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8mb4 */;
CREATE TABLE `mtrees` (
  `id` int(10) unsigned NOT NULL AUTO_INCREMENT,
  `tname` varchar(128) NOT NULL DEFAULT '',
  `tprefix` varchar(32) NOT NULL DEFAULT '',
  `tvalue` varchar(128) NOT NULL DEFAULT '',
  PRIMARY KEY (`id`),
  UNIQUE KEY `tname_tprefix_tvalue_idx` (`tname`,`tprefix`,`tvalue`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb3 COLLATE=utf8mb3_general_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `mtrees`
--

LOCK TABLES `mtrees` WRITE;
/*!40000 ALTER TABLE `mtrees` DISABLE KEYS */;
/*!40000 ALTER TABLE `mtrees` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `pdt`
--

DROP TABLE IF EXISTS `pdt`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8mb4 */;
CREATE TABLE `pdt` (
  `id` int(10) unsigned NOT NULL AUTO_INCREMENT,
  `sdomain` varchar(255) NOT NULL,
  `prefix` varchar(32) NOT NULL,
  `domain` varchar(255) NOT NULL DEFAULT '',
  PRIMARY KEY (`id`),
  UNIQUE KEY `sdomain_prefix_idx` (`sdomain`,`prefix`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb3 COLLATE=utf8mb3_general_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `pdt`
--

LOCK TABLES `pdt` WRITE;
/*!40000 ALTER TABLE `pdt` DISABLE KEYS */;
/*!40000 ALTER TABLE `pdt` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `pl_pipes`
--

DROP TABLE IF EXISTS `pl_pipes`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8mb4 */;
CREATE TABLE `pl_pipes` (
  `id` int(10) unsigned NOT NULL AUTO_INCREMENT,
  `pipeid` varchar(64) NOT NULL DEFAULT '',
  `algorithm` varchar(32) NOT NULL DEFAULT '',
  `plimit` int(11) NOT NULL DEFAULT 0,
  PRIMARY KEY (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb3 COLLATE=utf8mb3_general_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `pl_pipes`
--

LOCK TABLES `pl_pipes` WRITE;
/*!40000 ALTER TABLE `pl_pipes` DISABLE KEYS */;
/*!40000 ALTER TABLE `pl_pipes` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `presentity`
--

DROP TABLE IF EXISTS `presentity`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8mb4 */;
CREATE TABLE `presentity` (
  `id` int(10) unsigned NOT NULL AUTO_INCREMENT,
  `username` varchar(64) NOT NULL,
  `domain` varchar(64) NOT NULL,
  `event` varchar(64) NOT NULL,
  `etag` varchar(128) NOT NULL,
  `expires` int(11) NOT NULL,
  `received_time` int(11) NOT NULL,
  `body` blob NOT NULL,
  `sender` varchar(255) NOT NULL,
  `priority` int(11) NOT NULL DEFAULT 0,
  `ruid` varchar(64) DEFAULT NULL,
  PRIMARY KEY (`id`),
  UNIQUE KEY `presentity_idx` (`username`,`domain`,`event`,`etag`),
  UNIQUE KEY `ruid_idx` (`ruid`),
  KEY `presentity_expires` (`expires`),
  KEY `account_idx` (`username`,`domain`,`event`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb3 COLLATE=utf8mb3_general_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `presentity`
--

LOCK TABLES `presentity` WRITE;
/*!40000 ALTER TABLE `presentity` DISABLE KEYS */;
/*!40000 ALTER TABLE `presentity` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `pua`
--

DROP TABLE IF EXISTS `pua`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8mb4 */;
CREATE TABLE `pua` (
  `id` int(10) unsigned NOT NULL AUTO_INCREMENT,
  `pres_uri` varchar(255) NOT NULL,
  `pres_id` varchar(255) NOT NULL,
  `event` int(11) NOT NULL,
  `expires` int(11) NOT NULL,
  `desired_expires` int(11) NOT NULL,
  `flag` int(11) NOT NULL,
  `etag` varchar(128) NOT NULL,
  `tuple_id` varchar(64) DEFAULT NULL,
  `watcher_uri` varchar(255) NOT NULL,
  `call_id` varchar(255) NOT NULL,
  `to_tag` varchar(128) NOT NULL,
  `from_tag` varchar(128) NOT NULL,
  `cseq` int(11) NOT NULL,
  `record_route` text DEFAULT NULL,
  `contact` varchar(255) NOT NULL,
  `remote_contact` varchar(255) NOT NULL,
  `version` int(11) NOT NULL,
  `extra_headers` text NOT NULL,
  PRIMARY KEY (`id`),
  UNIQUE KEY `pua_idx` (`etag`,`tuple_id`,`call_id`,`from_tag`),
  KEY `expires_idx` (`expires`),
  KEY `dialog1_idx` (`pres_id`,`pres_uri`),
  KEY `dialog2_idx` (`call_id`,`from_tag`),
  KEY `record_idx` (`pres_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb3 COLLATE=utf8mb3_general_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `pua`
--

LOCK TABLES `pua` WRITE;
/*!40000 ALTER TABLE `pua` DISABLE KEYS */;
/*!40000 ALTER TABLE `pua` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `purplemap`
--

DROP TABLE IF EXISTS `purplemap`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8mb4 */;
CREATE TABLE `purplemap` (
  `id` int(10) unsigned NOT NULL AUTO_INCREMENT,
  `sip_user` varchar(255) NOT NULL,
  `ext_user` varchar(255) NOT NULL,
  `ext_prot` varchar(16) NOT NULL,
  `ext_pass` varchar(64) DEFAULT NULL,
  PRIMARY KEY (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb3 COLLATE=utf8mb3_general_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `purplemap`
--

LOCK TABLES `purplemap` WRITE;
/*!40000 ALTER TABLE `purplemap` DISABLE KEYS */;
/*!40000 ALTER TABLE `purplemap` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `re_grp`
--

DROP TABLE IF EXISTS `re_grp`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8mb4 */;
CREATE TABLE `re_grp` (
  `id` int(10) unsigned NOT NULL AUTO_INCREMENT,
  `reg_exp` varchar(128) NOT NULL DEFAULT '',
  `group_id` int(11) NOT NULL DEFAULT 0,
  PRIMARY KEY (`id`),
  KEY `group_idx` (`group_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb3 COLLATE=utf8mb3_general_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `re_grp`
--

LOCK TABLES `re_grp` WRITE;
/*!40000 ALTER TABLE `re_grp` DISABLE KEYS */;
/*!40000 ALTER TABLE `re_grp` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `rls_presentity`
--

DROP TABLE IF EXISTS `rls_presentity`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8mb4 */;
CREATE TABLE `rls_presentity` (
  `id` int(10) unsigned NOT NULL AUTO_INCREMENT,
  `rlsubs_did` varchar(255) NOT NULL,
  `resource_uri` varchar(255) NOT NULL,
  `content_type` varchar(255) NOT NULL,
  `presence_state` blob NOT NULL,
  `expires` int(11) NOT NULL,
  `updated` int(11) NOT NULL,
  `auth_state` int(11) NOT NULL,
  `reason` varchar(64) NOT NULL,
  PRIMARY KEY (`id`),
  UNIQUE KEY `rls_presentity_idx` (`rlsubs_did`,`resource_uri`),
  KEY `rlsubs_idx` (`rlsubs_did`),
  KEY `updated_idx` (`updated`),
  KEY `expires_idx` (`expires`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb3 COLLATE=utf8mb3_general_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `rls_presentity`
--

LOCK TABLES `rls_presentity` WRITE;
/*!40000 ALTER TABLE `rls_presentity` DISABLE KEYS */;
/*!40000 ALTER TABLE `rls_presentity` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `rls_watchers`
--

DROP TABLE IF EXISTS `rls_watchers`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8mb4 */;
CREATE TABLE `rls_watchers` (
  `id` int(10) unsigned NOT NULL AUTO_INCREMENT,
  `presentity_uri` varchar(255) NOT NULL,
  `to_user` varchar(64) NOT NULL,
  `to_domain` varchar(64) NOT NULL,
  `watcher_username` varchar(64) NOT NULL,
  `watcher_domain` varchar(64) NOT NULL,
  `event` varchar(64) NOT NULL DEFAULT 'presence',
  `event_id` varchar(64) DEFAULT NULL,
  `to_tag` varchar(128) NOT NULL,
  `from_tag` varchar(128) NOT NULL,
  `callid` varchar(255) NOT NULL,
  `local_cseq` int(11) NOT NULL,
  `remote_cseq` int(11) NOT NULL,
  `contact` varchar(255) NOT NULL,
  `record_route` text DEFAULT NULL,
  `expires` int(11) NOT NULL,
  `status` int(11) NOT NULL DEFAULT 2,
  `reason` varchar(64) NOT NULL,
  `version` int(11) NOT NULL DEFAULT 0,
  `socket_info` varchar(64) NOT NULL,
  `local_contact` varchar(255) NOT NULL,
  `from_user` varchar(64) NOT NULL,
  `from_domain` varchar(64) NOT NULL,
  `updated` int(11) NOT NULL,
  PRIMARY KEY (`id`),
  UNIQUE KEY `rls_watcher_idx` (`callid`,`to_tag`,`from_tag`),
  KEY `rls_watchers_update` (`watcher_username`,`watcher_domain`,`event`),
  KEY `rls_watchers_expires` (`expires`),
  KEY `updated_idx` (`updated`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb3 COLLATE=utf8mb3_general_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `rls_watchers`
--

LOCK TABLES `rls_watchers` WRITE;
/*!40000 ALTER TABLE `rls_watchers` DISABLE KEYS */;
/*!40000 ALTER TABLE `rls_watchers` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `rtpengine`
--

DROP TABLE IF EXISTS `rtpengine`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8mb4 */;
CREATE TABLE `rtpengine` (
  `id` int(10) unsigned NOT NULL AUTO_INCREMENT,
  `setid` int(10) unsigned NOT NULL DEFAULT 0,
  `url` varchar(64) NOT NULL,
  `weight` int(10) unsigned NOT NULL DEFAULT 1,
  `disabled` int(1) NOT NULL DEFAULT 0,
  `stamp` datetime NOT NULL DEFAULT '1900-01-01 00:00:01',
  PRIMARY KEY (`id`),
  UNIQUE KEY `rtpengine_nodes` (`setid`,`url`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb3 COLLATE=utf8mb3_general_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `rtpengine`
--

LOCK TABLES `rtpengine` WRITE;
/*!40000 ALTER TABLE `rtpengine` DISABLE KEYS */;
/*!40000 ALTER TABLE `rtpengine` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `rtpproxy`
--

DROP TABLE IF EXISTS `rtpproxy`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8mb4 */;
CREATE TABLE `rtpproxy` (
  `id` int(10) unsigned NOT NULL AUTO_INCREMENT,
  `setid` varchar(32) NOT NULL DEFAULT '0',
  `url` varchar(64) NOT NULL DEFAULT '',
  `flags` int(11) NOT NULL DEFAULT 0,
  `weight` int(11) NOT NULL DEFAULT 1,
  `description` varchar(64) NOT NULL DEFAULT '',
  PRIMARY KEY (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb3 COLLATE=utf8mb3_general_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `rtpproxy`
--

LOCK TABLES `rtpproxy` WRITE;
/*!40000 ALTER TABLE `rtpproxy` DISABLE KEYS */;
/*!40000 ALTER TABLE `rtpproxy` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `sca_subscriptions`
--

DROP TABLE IF EXISTS `sca_subscriptions`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8mb4 */;
CREATE TABLE `sca_subscriptions` (
  `id` int(10) unsigned NOT NULL AUTO_INCREMENT,
  `subscriber` varchar(255) NOT NULL,
  `aor` varchar(255) NOT NULL,
  `event` int(11) NOT NULL DEFAULT 0,
  `expires` int(11) NOT NULL DEFAULT 0,
  `state` int(11) NOT NULL DEFAULT 0,
  `app_idx` int(11) NOT NULL DEFAULT 0,
  `call_id` varchar(255) NOT NULL,
  `from_tag` varchar(128) NOT NULL,
  `to_tag` varchar(128) NOT NULL,
  `record_route` text DEFAULT NULL,
  `notify_cseq` int(11) NOT NULL,
  `subscribe_cseq` int(11) NOT NULL,
  `server_id` int(11) NOT NULL DEFAULT 0,
  PRIMARY KEY (`id`),
  UNIQUE KEY `sca_subscriptions_idx` (`subscriber`,`call_id`,`from_tag`,`to_tag`),
  KEY `sca_expires_idx` (`server_id`,`expires`),
  KEY `sca_subscribers_idx` (`subscriber`,`event`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb3 COLLATE=utf8mb3_general_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `sca_subscriptions`
--

LOCK TABLES `sca_subscriptions` WRITE;
/*!40000 ALTER TABLE `sca_subscriptions` DISABLE KEYS */;
/*!40000 ALTER TABLE `sca_subscriptions` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `secfilter`
--

DROP TABLE IF EXISTS `secfilter`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8mb4 */;
CREATE TABLE `secfilter` (
  `id` int(10) unsigned NOT NULL AUTO_INCREMENT,
  `action` smallint(6) NOT NULL DEFAULT 0,
  `type` smallint(6) NOT NULL DEFAULT 0,
  `data` varchar(64) NOT NULL DEFAULT '',
  PRIMARY KEY (`id`),
  KEY `secfilter_idx` (`action`,`type`,`data`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb3 COLLATE=utf8mb3_general_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `secfilter`
--

LOCK TABLES `secfilter` WRITE;
/*!40000 ALTER TABLE `secfilter` DISABLE KEYS */;
/*!40000 ALTER TABLE `secfilter` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `silo`
--

DROP TABLE IF EXISTS `silo`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8mb4 */;
CREATE TABLE `silo` (
  `id` int(10) unsigned NOT NULL AUTO_INCREMENT,
  `src_addr` varchar(255) NOT NULL DEFAULT '',
  `dst_addr` varchar(255) NOT NULL DEFAULT '',
  `username` varchar(64) NOT NULL DEFAULT '',
  `domain` varchar(64) NOT NULL DEFAULT '',
  `inc_time` int(11) NOT NULL DEFAULT 0,
  `exp_time` int(11) NOT NULL DEFAULT 0,
  `snd_time` int(11) NOT NULL DEFAULT 0,
  `ctype` varchar(32) NOT NULL DEFAULT 'text/plain',
  `body` blob DEFAULT NULL,
  `extra_hdrs` text DEFAULT NULL,
  `callid` varchar(128) NOT NULL DEFAULT '',
  `status` int(11) NOT NULL DEFAULT 0,
  PRIMARY KEY (`id`),
  KEY `account_idx` (`username`,`domain`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb3 COLLATE=utf8mb3_general_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `silo`
--

LOCK TABLES `silo` WRITE;
/*!40000 ALTER TABLE `silo` DISABLE KEYS */;
/*!40000 ALTER TABLE `silo` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `sip_trace`
--

DROP TABLE IF EXISTS `sip_trace`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8mb4 */;
CREATE TABLE `sip_trace` (
  `id` int(10) unsigned NOT NULL AUTO_INCREMENT,
  `time_stamp` datetime NOT NULL DEFAULT '2000-01-01 00:00:01',
  `time_us` int(10) unsigned NOT NULL DEFAULT 0,
  `callid` varchar(255) NOT NULL DEFAULT '',
  `traced_user` varchar(255) NOT NULL DEFAULT '',
  `msg` mediumtext NOT NULL,
  `method` varchar(50) NOT NULL DEFAULT '',
  `status` varchar(255) NOT NULL DEFAULT '',
  `fromip` varchar(64) NOT NULL DEFAULT '',
  `toip` varchar(64) NOT NULL DEFAULT '',
  `fromtag` varchar(128) NOT NULL DEFAULT '',
  `totag` varchar(128) NOT NULL DEFAULT '',
  `direction` varchar(4) NOT NULL DEFAULT '',
  PRIMARY KEY (`id`),
  KEY `traced_user_idx` (`traced_user`),
  KEY `date_idx` (`time_stamp`),
  KEY `fromip_idx` (`fromip`),
  KEY `callid_idx` (`callid`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb3 COLLATE=utf8mb3_general_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `sip_trace`
--

LOCK TABLES `sip_trace` WRITE;
/*!40000 ALTER TABLE `sip_trace` DISABLE KEYS */;
/*!40000 ALTER TABLE `sip_trace` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `speed_dial`
--

DROP TABLE IF EXISTS `speed_dial`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8mb4 */;
CREATE TABLE `speed_dial` (
  `id` int(10) unsigned NOT NULL AUTO_INCREMENT,
  `username` varchar(64) NOT NULL DEFAULT '',
  `domain` varchar(64) NOT NULL DEFAULT '',
  `sd_username` varchar(64) NOT NULL DEFAULT '',
  `sd_domain` varchar(64) NOT NULL DEFAULT '',
  `new_uri` varchar(255) NOT NULL DEFAULT '',
  `fname` varchar(64) NOT NULL DEFAULT '',
  `lname` varchar(64) NOT NULL DEFAULT '',
  `description` varchar(64) NOT NULL DEFAULT '',
  PRIMARY KEY (`id`),
  UNIQUE KEY `speed_dial_idx` (`username`,`domain`,`sd_domain`,`sd_username`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb3 COLLATE=utf8mb3_general_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `speed_dial`
--

LOCK TABLES `speed_dial` WRITE;
/*!40000 ALTER TABLE `speed_dial` DISABLE KEYS */;
/*!40000 ALTER TABLE `speed_dial` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `subscriber`
--

DROP TABLE IF EXISTS `subscriber`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8mb4 */;
CREATE TABLE `subscriber` (
  `id` int(10) unsigned NOT NULL AUTO_INCREMENT,
  `username` varchar(64) NOT NULL DEFAULT '',
  `domain` varchar(64) NOT NULL DEFAULT '',
  `password` varchar(64) NOT NULL DEFAULT '',
  `ha1` varchar(128) NOT NULL DEFAULT '',
  `ha1b` varchar(128) NOT NULL DEFAULT '',
  `email_address` varchar(128) NOT NULL DEFAULT '',
  `rpid` varchar(128) NOT NULL DEFAULT '',
  PRIMARY KEY (`id`),
  UNIQUE KEY `account_idx` (`username`,`domain`),
  KEY `username_idx` (`username`)
) ENGINE=InnoDB AUTO_INCREMENT=2 DEFAULT CHARSET=utf8mb3 COLLATE=utf8mb3_general_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `subscriber`
--

LOCK TABLES `subscriber` WRITE;
/*!40000 ALTER TABLE `subscriber` DISABLE KEYS */;
INSERT INTO `subscriber` VALUES
(1,'2485442883','sip.dsiprouter.org','testtest!','','','','32');
/*!40000 ALTER TABLE `subscriber` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `topos_d`
--

DROP TABLE IF EXISTS `topos_d`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8mb4 */;
CREATE TABLE `topos_d` (
  `id` int(10) unsigned NOT NULL AUTO_INCREMENT,
  `rectime` datetime NOT NULL,
  `x_context` varchar(64) NOT NULL DEFAULT '',
  `s_method` varchar(64) NOT NULL DEFAULT '',
  `s_cseq` varchar(64) NOT NULL DEFAULT '',
  `a_callid` varchar(255) NOT NULL DEFAULT '',
  `a_uuid` varchar(255) NOT NULL DEFAULT '',
  `b_uuid` varchar(255) NOT NULL DEFAULT '',
  `a_contact` varchar(512) NOT NULL DEFAULT '',
  `b_contact` varchar(512) NOT NULL DEFAULT '',
  `as_contact` varchar(512) NOT NULL DEFAULT '',
  `bs_contact` varchar(512) NOT NULL DEFAULT '',
  `a_tag` varchar(255) NOT NULL DEFAULT '',
  `b_tag` varchar(255) NOT NULL DEFAULT '',
  `a_rr` mediumtext DEFAULT NULL,
  `b_rr` mediumtext DEFAULT NULL,
  `s_rr` mediumtext DEFAULT NULL,
  `iflags` int(10) unsigned NOT NULL DEFAULT 0,
  `a_uri` varchar(255) NOT NULL DEFAULT '',
  `b_uri` varchar(255) NOT NULL DEFAULT '',
  `r_uri` varchar(255) NOT NULL DEFAULT '',
  `a_srcaddr` varchar(128) NOT NULL DEFAULT '',
  `b_srcaddr` varchar(128) NOT NULL DEFAULT '',
  `a_socket` varchar(128) NOT NULL DEFAULT '',
  `b_socket` varchar(128) NOT NULL DEFAULT '',
  PRIMARY KEY (`id`),
  KEY `rectime_idx` (`rectime`),
  KEY `a_callid_idx` (`a_callid`),
  KEY `a_uuid_idx` (`a_uuid`),
  KEY `b_uuid_idx` (`b_uuid`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb3 COLLATE=utf8mb3_general_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `topos_d`
--

LOCK TABLES `topos_d` WRITE;
/*!40000 ALTER TABLE `topos_d` DISABLE KEYS */;
/*!40000 ALTER TABLE `topos_d` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `topos_t`
--

DROP TABLE IF EXISTS `topos_t`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8mb4 */;
CREATE TABLE `topos_t` (
  `id` int(10) unsigned NOT NULL AUTO_INCREMENT,
  `rectime` datetime NOT NULL,
  `x_context` varchar(64) NOT NULL DEFAULT '',
  `s_method` varchar(64) NOT NULL DEFAULT '',
  `s_cseq` varchar(64) NOT NULL DEFAULT '',
  `a_callid` varchar(255) NOT NULL DEFAULT '',
  `a_uuid` varchar(255) NOT NULL DEFAULT '',
  `b_uuid` varchar(255) NOT NULL DEFAULT '',
  `direction` int(11) NOT NULL DEFAULT 0,
  `x_via` mediumtext DEFAULT NULL,
  `x_vbranch` varchar(255) NOT NULL DEFAULT '',
  `x_rr` mediumtext DEFAULT NULL,
  `y_rr` mediumtext DEFAULT NULL,
  `s_rr` mediumtext DEFAULT NULL,
  `x_uri` varchar(255) NOT NULL DEFAULT '',
  `a_contact` varchar(512) NOT NULL DEFAULT '',
  `b_contact` varchar(512) NOT NULL DEFAULT '',
  `as_contact` varchar(512) NOT NULL DEFAULT '',
  `bs_contact` varchar(512) NOT NULL DEFAULT '',
  `x_tag` varchar(255) NOT NULL DEFAULT '',
  `a_tag` varchar(255) NOT NULL DEFAULT '',
  `b_tag` varchar(255) NOT NULL DEFAULT '',
  `a_srcaddr` varchar(255) NOT NULL DEFAULT '',
  `b_srcaddr` varchar(255) NOT NULL DEFAULT '',
  `a_socket` varchar(128) NOT NULL DEFAULT '',
  `b_socket` varchar(128) NOT NULL DEFAULT '',
  PRIMARY KEY (`id`),
  KEY `rectime_idx` (`rectime`),
  KEY `a_callid_idx` (`a_callid`),
  KEY `x_vbranch_idx` (`x_vbranch`),
  KEY `a_uuid_idx` (`a_uuid`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb3 COLLATE=utf8mb3_general_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `topos_t`
--

LOCK TABLES `topos_t` WRITE;
/*!40000 ALTER TABLE `topos_t` DISABLE KEYS */;
/*!40000 ALTER TABLE `topos_t` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `trusted`
--

DROP TABLE IF EXISTS `trusted`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8mb4 */;
CREATE TABLE `trusted` (
  `id` int(10) unsigned NOT NULL AUTO_INCREMENT,
  `src_ip` varchar(50) NOT NULL,
  `proto` varchar(4) NOT NULL,
  `from_pattern` varchar(64) DEFAULT NULL,
  `ruri_pattern` varchar(64) DEFAULT NULL,
  `tag` varchar(64) DEFAULT NULL,
  `priority` int(11) NOT NULL DEFAULT 0,
  PRIMARY KEY (`id`),
  KEY `peer_idx` (`src_ip`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb3 COLLATE=utf8mb3_general_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `trusted`
--

LOCK TABLES `trusted` WRITE;
/*!40000 ALTER TABLE `trusted` DISABLE KEYS */;
/*!40000 ALTER TABLE `trusted` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `uacreg`
--

DROP TABLE IF EXISTS `uacreg`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8mb4 */;
CREATE TABLE `uacreg` (
  `id` int(10) unsigned NOT NULL AUTO_INCREMENT,
  `l_uuid` varchar(64) NOT NULL DEFAULT '',
  `l_username` varchar(64) NOT NULL DEFAULT '',
  `l_domain` varchar(253) NOT NULL DEFAULT '',
  `r_username` varchar(64) NOT NULL DEFAULT '',
  `r_domain` varchar(253) NOT NULL DEFAULT '',
  `realm` varchar(253) NOT NULL DEFAULT '',
  `auth_username` varchar(64) NOT NULL DEFAULT '',
  `auth_password` varchar(64) NOT NULL DEFAULT '',
  `auth_ha1` varchar(128) NOT NULL DEFAULT '',
  `auth_proxy` varchar(16000) NOT NULL DEFAULT '',
  `expires` int(11) NOT NULL DEFAULT 0,
  `flags` int(11) NOT NULL DEFAULT 0,
  `reg_delay` int(11) NOT NULL DEFAULT 0,
  `contact_addr` varchar(255) NOT NULL DEFAULT '',
  `socket` varchar(128) NOT NULL DEFAULT '',
  PRIMARY KEY (`id`),
  UNIQUE KEY `l_uuid_idx` (`l_uuid`)
) ENGINE=InnoDB AUTO_INCREMENT=3 DEFAULT CHARSET=utf8mb3 COLLATE=utf8mb3_general_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `uacreg`
--

LOCK TABLES `uacreg` WRITE;
/*!40000 ALTER TABLE `uacreg` DISABLE KEYS */;
INSERT INTO `uacreg` VALUES
(1,'33','dsip','mack.test.dsiprouter.net','dsip','dopensourcedev-5b971b49c6b2.sip.signalwire.com','dopensourcedev-5b971b49c6b2.sip.signalwire.com','dsip','rwe1kR6NNa0nWWo11pOV9o5h9lc2bLcP','','sip:dopensourcedev-5b971b49c6b2.sip.signalwire.com:5060',60,0,0,'',''),
(2,'34','dsip','mack.test.dsiprouter.net','dsip','dopensourcedev-5b971b49c6b2.sip.signalwire.com','dopensourcedev-5b971b49c6b2.sip.signalwire.com','dsip','dsip','','sip:dopensourcedev-5b971b49c6b2.sip.signalwire.com:5060',60,0,0,'','');
/*!40000 ALTER TABLE `uacreg` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `uid_credentials`
--

DROP TABLE IF EXISTS `uid_credentials`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8mb4 */;
CREATE TABLE `uid_credentials` (
  `id` int(10) unsigned NOT NULL AUTO_INCREMENT,
  `auth_username` varchar(64) NOT NULL,
  `did` varchar(64) NOT NULL DEFAULT '_default',
  `realm` varchar(64) NOT NULL,
  `password` varchar(28) NOT NULL DEFAULT '',
  `flags` int(11) NOT NULL DEFAULT 0,
  `ha1` varchar(32) NOT NULL,
  `ha1b` varchar(32) NOT NULL DEFAULT '',
  `uid` varchar(64) NOT NULL,
  PRIMARY KEY (`id`),
  KEY `cred_idx` (`auth_username`,`did`),
  KEY `uid` (`uid`),
  KEY `did_idx` (`did`),
  KEY `realm_idx` (`realm`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb3 COLLATE=utf8mb3_general_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `uid_credentials`
--

LOCK TABLES `uid_credentials` WRITE;
/*!40000 ALTER TABLE `uid_credentials` DISABLE KEYS */;
/*!40000 ALTER TABLE `uid_credentials` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `uid_domain`
--

DROP TABLE IF EXISTS `uid_domain`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8mb4 */;
CREATE TABLE `uid_domain` (
  `id` int(10) unsigned NOT NULL AUTO_INCREMENT,
  `did` varchar(64) NOT NULL,
  `domain` varchar(64) NOT NULL,
  `flags` int(10) unsigned NOT NULL DEFAULT 0,
  PRIMARY KEY (`id`),
  UNIQUE KEY `domain_idx` (`domain`),
  KEY `did_idx` (`did`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb3 COLLATE=utf8mb3_general_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `uid_domain`
--

LOCK TABLES `uid_domain` WRITE;
/*!40000 ALTER TABLE `uid_domain` DISABLE KEYS */;
/*!40000 ALTER TABLE `uid_domain` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `uid_domain_attrs`
--

DROP TABLE IF EXISTS `uid_domain_attrs`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8mb4 */;
CREATE TABLE `uid_domain_attrs` (
  `id` int(10) unsigned NOT NULL AUTO_INCREMENT,
  `did` varchar(64) DEFAULT NULL,
  `name` varchar(32) NOT NULL,
  `type` int(11) NOT NULL DEFAULT 0,
  `value` varchar(128) DEFAULT NULL,
  `flags` int(10) unsigned NOT NULL DEFAULT 0,
  PRIMARY KEY (`id`),
  UNIQUE KEY `domain_attr_idx` (`did`,`name`,`value`),
  KEY `domain_did` (`did`,`flags`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb3 COLLATE=utf8mb3_general_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `uid_domain_attrs`
--

LOCK TABLES `uid_domain_attrs` WRITE;
/*!40000 ALTER TABLE `uid_domain_attrs` DISABLE KEYS */;
/*!40000 ALTER TABLE `uid_domain_attrs` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `uid_global_attrs`
--

DROP TABLE IF EXISTS `uid_global_attrs`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8mb4 */;
CREATE TABLE `uid_global_attrs` (
  `id` int(10) unsigned NOT NULL AUTO_INCREMENT,
  `name` varchar(32) NOT NULL,
  `type` int(11) NOT NULL DEFAULT 0,
  `value` varchar(128) DEFAULT NULL,
  `flags` int(10) unsigned NOT NULL DEFAULT 0,
  PRIMARY KEY (`id`),
  UNIQUE KEY `global_attrs_idx` (`name`,`value`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb3 COLLATE=utf8mb3_general_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `uid_global_attrs`
--

LOCK TABLES `uid_global_attrs` WRITE;
/*!40000 ALTER TABLE `uid_global_attrs` DISABLE KEYS */;
/*!40000 ALTER TABLE `uid_global_attrs` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `uid_uri`
--

DROP TABLE IF EXISTS `uid_uri`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8mb4 */;
CREATE TABLE `uid_uri` (
  `id` int(10) unsigned NOT NULL AUTO_INCREMENT,
  `uid` varchar(64) NOT NULL,
  `did` varchar(64) NOT NULL,
  `username` varchar(64) NOT NULL,
  `flags` int(10) unsigned NOT NULL DEFAULT 0,
  `scheme` varchar(8) NOT NULL DEFAULT 'sip',
  PRIMARY KEY (`id`),
  KEY `uri_idx1` (`username`,`did`,`scheme`),
  KEY `uri_uid` (`uid`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb3 COLLATE=utf8mb3_general_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `uid_uri`
--

LOCK TABLES `uid_uri` WRITE;
/*!40000 ALTER TABLE `uid_uri` DISABLE KEYS */;
/*!40000 ALTER TABLE `uid_uri` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `uid_uri_attrs`
--

DROP TABLE IF EXISTS `uid_uri_attrs`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8mb4 */;
CREATE TABLE `uid_uri_attrs` (
  `id` int(10) unsigned NOT NULL AUTO_INCREMENT,
  `username` varchar(64) NOT NULL,
  `did` varchar(64) NOT NULL,
  `name` varchar(32) NOT NULL,
  `value` varchar(128) DEFAULT NULL,
  `type` int(11) NOT NULL DEFAULT 0,
  `flags` int(10) unsigned NOT NULL DEFAULT 0,
  `scheme` varchar(8) NOT NULL DEFAULT 'sip',
  PRIMARY KEY (`id`),
  UNIQUE KEY `uriattrs_idx` (`username`,`did`,`name`,`value`,`scheme`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb3 COLLATE=utf8mb3_general_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `uid_uri_attrs`
--

LOCK TABLES `uid_uri_attrs` WRITE;
/*!40000 ALTER TABLE `uid_uri_attrs` DISABLE KEYS */;
/*!40000 ALTER TABLE `uid_uri_attrs` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `uid_user_attrs`
--

DROP TABLE IF EXISTS `uid_user_attrs`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8mb4 */;
CREATE TABLE `uid_user_attrs` (
  `id` int(10) unsigned NOT NULL AUTO_INCREMENT,
  `uid` varchar(64) NOT NULL,
  `name` varchar(32) NOT NULL,
  `value` varchar(128) DEFAULT NULL,
  `type` int(11) NOT NULL DEFAULT 0,
  `flags` int(10) unsigned NOT NULL DEFAULT 0,
  PRIMARY KEY (`id`),
  UNIQUE KEY `userattrs_idx` (`uid`,`name`,`value`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb3 COLLATE=utf8mb3_general_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `uid_user_attrs`
--

LOCK TABLES `uid_user_attrs` WRITE;
/*!40000 ALTER TABLE `uid_user_attrs` DISABLE KEYS */;
/*!40000 ALTER TABLE `uid_user_attrs` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `uri`
--

DROP TABLE IF EXISTS `uri`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8mb4 */;
CREATE TABLE `uri` (
  `id` int(10) unsigned NOT NULL AUTO_INCREMENT,
  `username` varchar(64) NOT NULL DEFAULT '',
  `domain` varchar(64) NOT NULL DEFAULT '',
  `uri_user` varchar(64) NOT NULL DEFAULT '',
  `last_modified` datetime NOT NULL DEFAULT '2000-01-01 00:00:01',
  PRIMARY KEY (`id`),
  UNIQUE KEY `account_idx` (`username`,`domain`,`uri_user`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb3 COLLATE=utf8mb3_general_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `uri`
--

LOCK TABLES `uri` WRITE;
/*!40000 ALTER TABLE `uri` DISABLE KEYS */;
/*!40000 ALTER TABLE `uri` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `userblocklist`
--

DROP TABLE IF EXISTS `userblocklist`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8mb4 */;
CREATE TABLE `userblocklist` (
  `id` int(10) unsigned NOT NULL AUTO_INCREMENT,
  `username` varchar(64) NOT NULL DEFAULT '',
  `domain` varchar(64) NOT NULL DEFAULT '',
  `prefix` varchar(64) NOT NULL DEFAULT '',
  `allowlist` tinyint(1) NOT NULL DEFAULT 0,
  PRIMARY KEY (`id`),
  KEY `userblocklist_idx` (`username`,`domain`,`prefix`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb3 COLLATE=utf8mb3_general_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `userblocklist`
--

LOCK TABLES `userblocklist` WRITE;
/*!40000 ALTER TABLE `userblocklist` DISABLE KEYS */;
/*!40000 ALTER TABLE `userblocklist` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `usr_preferences`
--

DROP TABLE IF EXISTS `usr_preferences`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8mb4 */;
CREATE TABLE `usr_preferences` (
  `id` int(10) unsigned NOT NULL AUTO_INCREMENT,
  `uuid` varchar(64) NOT NULL DEFAULT '',
  `username` varchar(255) NOT NULL DEFAULT '0',
  `domain` varchar(64) NOT NULL DEFAULT '',
  `attribute` varchar(32) NOT NULL DEFAULT '',
  `type` int(11) NOT NULL DEFAULT 0,
  `value` varchar(128) NOT NULL DEFAULT '',
  `last_modified` datetime NOT NULL DEFAULT '2000-01-01 00:00:01',
  PRIMARY KEY (`id`),
  KEY `ua_idx` (`uuid`,`attribute`),
  KEY `uda_idx` (`username`,`domain`,`attribute`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb3 COLLATE=utf8mb3_general_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `usr_preferences`
--

LOCK TABLES `usr_preferences` WRITE;
/*!40000 ALTER TABLE `usr_preferences` DISABLE KEYS */;
/*!40000 ALTER TABLE `usr_preferences` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `version`
--

DROP TABLE IF EXISTS `version`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8mb4 */;
CREATE TABLE `version` (
  `id` int(10) unsigned NOT NULL AUTO_INCREMENT,
  `table_name` varchar(32) NOT NULL,
  `table_version` int(10) unsigned NOT NULL DEFAULT 0,
  PRIMARY KEY (`id`),
  UNIQUE KEY `table_name_idx` (`table_name`)
) ENGINE=InnoDB AUTO_INCREMENT=75 DEFAULT CHARSET=utf8mb3 COLLATE=utf8mb3_general_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `version`
--

LOCK TABLES `version` WRITE;
/*!40000 ALTER TABLE `version` DISABLE KEYS */;
INSERT INTO `version` VALUES
(1,'version',1),
(2,'acc',5),
(3,'acc_cdrs',2),
(4,'missed_calls',4),
(5,'lcr_gw',3),
(6,'lcr_rule_target',1),
(7,'lcr_rule',3),
(8,'domain',2),
(9,'domain_attrs',1),
(10,'grp',2),
(11,'re_grp',1),
(12,'trusted',6),
(13,'address',6),
(14,'aliases',8),
(15,'location',9),
(16,'location_attrs',1),
(17,'silo',8),
(18,'dbaliases',1),
(19,'uri',1),
(20,'speed_dial',2),
(21,'usr_preferences',2),
(22,'subscriber',7),
(23,'pdt',1),
(24,'dialog',7),
(25,'dialog_vars',1),
(26,'dispatcher',4),
(27,'dialplan',2),
(28,'topos_d',2),
(29,'topos_t',2),
(30,'presentity',5),
(31,'active_watchers',12),
(32,'watchers',3),
(33,'xcap',4),
(34,'pua',7),
(35,'rls_presentity',1),
(36,'rls_watchers',3),
(37,'imc_rooms',1),
(38,'imc_members',1),
(39,'cpl',1),
(40,'sip_trace',4),
(41,'domainpolicy',2),
(42,'carrierroute',3),
(43,'carrierfailureroute',2),
(44,'carrier_name',1),
(45,'domain_name',1),
(50,'userblocklist',1),
(51,'globalblocklist',1),
(52,'htable',2),
(53,'purplemap',1),
(54,'uacreg',5),
(55,'pl_pipes',1),
(56,'mtree',1),
(57,'mtrees',2),
(58,'sca_subscriptions',2),
(59,'mohqcalls',1),
(60,'mohqueues',1),
(61,'rtpproxy',1),
(62,'rtpengine',1),
(63,'secfilter',1),
(64,'uid_credentials',7),
(65,'uid_user_attrs',3),
(66,'uid_domain',2),
(67,'uid_domain_attrs',1),
(68,'uid_global_attrs',1),
(69,'uid_uri',3),
(70,'uid_uri_attrs',2),
(71,'dr_gateways',3),
(72,'dr_rules',3),
(73,'dr_gw_lists',1),
(74,'dr_groups',2);
/*!40000 ALTER TABLE `version` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `watchers`
--

DROP TABLE IF EXISTS `watchers`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8mb4 */;
CREATE TABLE `watchers` (
  `id` int(10) unsigned NOT NULL AUTO_INCREMENT,
  `presentity_uri` varchar(255) NOT NULL,
  `watcher_username` varchar(64) NOT NULL,
  `watcher_domain` varchar(64) NOT NULL,
  `event` varchar(64) NOT NULL DEFAULT 'presence',
  `status` int(11) NOT NULL,
  `reason` varchar(64) DEFAULT NULL,
  `inserted_time` int(11) NOT NULL,
  PRIMARY KEY (`id`),
  UNIQUE KEY `watcher_idx` (`presentity_uri`,`watcher_username`,`watcher_domain`,`event`),
  KEY `time_status_idx` (`inserted_time`,`status`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb3 COLLATE=utf8mb3_general_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `watchers`
--

LOCK TABLES `watchers` WRITE;
/*!40000 ALTER TABLE `watchers` DISABLE KEYS */;
/*!40000 ALTER TABLE `watchers` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `xcap`
--

DROP TABLE IF EXISTS `xcap`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8mb4 */;
CREATE TABLE `xcap` (
  `id` int(10) unsigned NOT NULL AUTO_INCREMENT,
  `username` varchar(64) NOT NULL,
  `domain` varchar(64) NOT NULL,
  `doc` mediumblob NOT NULL,
  `doc_type` int(11) NOT NULL,
  `etag` varchar(128) NOT NULL,
  `source` int(11) NOT NULL,
  `doc_uri` varchar(255) NOT NULL,
  `port` int(11) NOT NULL,
  PRIMARY KEY (`id`),
  UNIQUE KEY `doc_uri_idx` (`doc_uri`),
  KEY `account_doc_type_idx` (`username`,`domain`,`doc_type`),
  KEY `account_doc_type_uri_idx` (`username`,`domain`,`doc_type`,`doc_uri`),
  KEY `account_doc_uri_idx` (`username`,`domain`,`doc_uri`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb3 COLLATE=utf8mb3_general_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `xcap`
--

LOCK TABLES `xcap` WRITE;
/*!40000 ALTER TABLE `xcap` DISABLE KEYS */;
/*!40000 ALTER TABLE `xcap` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Dumping routines for database 'kamailio'
--
/*!50003 SET @saved_sql_mode       = @@sql_mode */ ;
/*!50003 SET sql_mode              = '' */ ;
/*!50003 DROP PROCEDURE IF EXISTS `kamailio_cdrs` */;
/*!50003 SET @saved_cs_client      = @@character_set_client */ ;
/*!50003 SET @saved_cs_results     = @@character_set_results */ ;
/*!50003 SET @saved_col_connection = @@collation_connection */ ;
/*!50003 SET character_set_client  = utf8mb3 */ ;
/*!50003 SET character_set_results = utf8mb3 */ ;
/*!50003 SET collation_connection  = utf8mb3_general_ci */ ;
DELIMITER ;;
CREATE DEFINER=`root`@`localhost` PROCEDURE `kamailio_cdrs`()
BEGIN
  DECLARE done int DEFAULT 0;
  DECLARE bye_record int DEFAULT 0;
  DECLARE v_src_user,v_src_domain,v_dst_user,v_dst_domain,v_callid,v_from_tag,
    v_to_tag,v_src_ip,v_calltype varchar(255);
  DECLARE v_src_gwgroupid, v_dst_gwgroupid int(11);
  DECLARE v_inv_time, v_bye_time datetime;
  DECLARE inv_cursor CURSOR FOR
    SELECT src_user,
           src_domain,
           dst_user,
           dst_domain,
           time,
           callid,
           from_tag,
           to_tag,
           src_ip,
           calltype,
           src_gwgroupid,
           dst_gwgroupid
    FROM acc
    WHERE method = 'INVITE'
      AND cdr_id = '0';
  DECLARE CONTINUE HANDLER FOR SQLSTATE '02000' SET done = 1;
  OPEN inv_cursor;
  REPEAT
    FETCH inv_cursor INTO v_src_user, v_src_domain, v_dst_user, v_dst_domain,
      v_inv_time, v_callid, v_from_tag, v_to_tag, v_src_ip, v_calltype,
      v_src_gwgroupid, v_dst_gwgroupid;
    IF NOT done THEN
      SET bye_record = 0;
      SELECT 1, time
      INTO bye_record, v_bye_time
      FROM acc
      WHERE method = 'BYE'
        AND callid = v_callid
        AND ((from_tag = v_from_tag
        AND to_tag = v_to_tag)
        OR (from_tag = v_to_tag AND to_tag = v_from_tag))
      ORDER BY time ASC
      LIMIT 1;
      IF bye_record = 1 THEN
        INSERT INTO cdrs (src_username, src_domain, dst_username, dst_domain,
                          call_start_time, duration, sip_call_id, sip_from_tag,
                          sip_to_tag, src_ip, created, calltype, src_gwgroupid, dst_gwgroupid)
        VALUES (v_src_user, v_src_domain, v_dst_user, v_dst_domain, v_inv_time,
                UNIX_TIMESTAMP(v_bye_time) - UNIX_TIMESTAMP(v_inv_time),
                v_callid, v_from_tag, v_to_tag, v_src_ip, NOW(), v_calltype,
                v_src_gwgroupid, v_dst_gwgroupid);
        UPDATE acc
        SET cdr_id=last_insert_id()
        WHERE callid = v_callid
          AND from_tag = v_from_tag
          AND to_tag = v_to_tag;
      END IF;
      SET done = 0;
    END IF;
  UNTIL done END REPEAT;
END ;;
DELIMITER ;
/*!50003 SET sql_mode              = @saved_sql_mode */ ;
/*!50003 SET character_set_client  = @saved_cs_client */ ;
/*!50003 SET character_set_results = @saved_cs_results */ ;
/*!50003 SET collation_connection  = @saved_col_connection */ ;
/*!50003 SET @saved_sql_mode       = @@sql_mode */ ;
/*!50003 SET sql_mode              = '' */ ;
/*!50003 DROP PROCEDURE IF EXISTS `kamailio_rating` */;
/*!50003 SET @saved_cs_client      = @@character_set_client */ ;
/*!50003 SET @saved_cs_results     = @@character_set_results */ ;
/*!50003 SET @saved_col_connection = @@collation_connection */ ;
/*!50003 SET character_set_client  = utf8mb3 */ ;
/*!50003 SET character_set_results = utf8mb3 */ ;
/*!50003 SET collation_connection  = utf8mb3_general_ci */ ;
DELIMITER ;;
CREATE DEFINER=`root`@`localhost` PROCEDURE `kamailio_rating`(`rgroup` varchar(64))
BEGIN
  DECLARE done, rate_record, vx_cost int DEFAULT 0;
  DECLARE v_cdr_id bigint DEFAULT 0;
  DECLARE v_duration, v_rate_unit, v_time_unit int DEFAULT 0;
  DECLARE v_dst_username varchar(255);
  DECLARE cdrs_cursor CURSOR FOR SELECT cdr_id, dst_username, duration
                                 FROM cdrs
                                 WHERE rated = 0;
  DECLARE CONTINUE HANDLER FOR SQLSTATE '02000' SET done = 1;
  OPEN cdrs_cursor;
  REPEAT
    FETCH cdrs_cursor INTO v_cdr_id, v_dst_username, v_duration;
    IF NOT done THEN
      SET rate_record = 0;
      SELECT 1, rate_unit, time_unit
      INTO rate_record, v_rate_unit, v_time_unit
      FROM billing_rates
      WHERE rate_group = rgroup
        AND v_dst_username LIKE concat(prefix, '%')
      ORDER BY prefix DESC
      LIMIT 1;
      IF rate_record = 1 THEN
        SET vx_cost = v_rate_unit * CEIL(v_duration / v_time_unit);
        UPDATE cdrs SET rated=1, cost=vx_cost WHERE cdr_id = v_cdr_id;
      END IF;
      SET done = 0;
    END IF;
  UNTIL done END REPEAT;
END ;;
DELIMITER ;
/*!50003 SET sql_mode              = @saved_sql_mode */ ;
/*!50003 SET character_set_client  = @saved_cs_client */ ;
/*!50003 SET character_set_results = @saved_cs_results */ ;
/*!50003 SET collation_connection  = @saved_col_connection */ ;
/*!50003 SET @saved_sql_mode       = @@sql_mode */ ;
/*!50003 SET sql_mode              = 'STRICT_TRANS_TABLES,ERROR_FOR_DIVISION_BY_ZERO,NO_AUTO_CREATE_USER,NO_ENGINE_SUBSTITUTION' */ ;
/*!50003 DROP PROCEDURE IF EXISTS `update_dsip_settings` */;
/*!50003 SET @saved_cs_client      = @@character_set_client */ ;
/*!50003 SET @saved_cs_results     = @@character_set_results */ ;
/*!50003 SET @saved_col_connection = @@collation_connection */ ;
/*!50003 SET character_set_client  = utf8mb3 */ ;
/*!50003 SET character_set_results = utf8mb3 */ ;
/*!50003 SET collation_connection  = utf8mb3_general_ci */ ;
DELIMITER ;;
CREATE DEFINER=`root`@`localhost` PROCEDURE `update_dsip_settings`(
  IN NEW_DSIP_ID VARBINARY(128),
  IN NEW_DSIP_CLUSTER_ID INT UNSIGNED,
  IN NEW_DSIP_CLUSTER_SYNC TINYINT(1),
  IN NEW_DSIP_PROTO VARCHAR(16),
  IN NEW_DSIP_PORT INT,
  IN NEW_DSIP_USERNAME VARCHAR(255),
  IN NEW_DSIP_PASSWORD VARBINARY(128),
  IN NEW_DSIP_IPC_PASS VARBINARY(144),
  IN NEW_DSIP_API_PROTO VARCHAR(16),
  IN NEW_DSIP_API_PORT INT,
  IN NEW_DSIP_PRIV_KEY VARCHAR(255),
  IN NEW_DSIP_PID_FILE VARCHAR(255),
  IN NEW_DSIP_UNIX_SOCK VARCHAR(255),
  IN NEW_DSIP_IPC_SOCK VARCHAR(255),
  IN NEW_DSIP_API_TOKEN VARBINARY(144),
  IN NEW_DSIP_LOG_LEVEL INT,
  IN NEW_DSIP_LOG_FACILITY INT,
  IN NEW_DSIP_SSL_KEY VARCHAR(255),
  IN NEW_DSIP_SSL_CERT VARCHAR(255),
  IN NEW_DSIP_SSL_CA VARCHAR(255),
  IN NEW_DSIP_SSL_EMAIL VARCHAR(255),
  IN NEW_DSIP_CERTS_DIR VARCHAR(255),
  IN NEW_VERSION VARCHAR(32),
  IN NEW_DEBUG TINYINT(1),
  IN NEW_ROLE VARCHAR(32),
  IN NEW_GUI_INACTIVE_TIMEOUT INT UNSIGNED,
  IN NEW_KAM_DB_HOST VARCHAR(255),
  IN NEW_KAM_DB_DRIVER VARCHAR(255),
  IN NEW_KAM_DB_TYPE VARCHAR(255),
  IN NEW_KAM_DB_PORT VARCHAR(255),
  IN NEW_KAM_DB_NAME VARCHAR(255),
  IN NEW_KAM_DB_USER VARCHAR(255),
  IN NEW_KAM_DB_PASS VARBINARY(144),
  IN NEW_KAM_KAMCMD_PATH VARCHAR(255),
  IN NEW_KAM_CFG_PATH VARCHAR(255),
  IN NEW_KAM_TLSCFG_PATH VARCHAR(255),
  IN NEW_RTP_CFG_PATH VARCHAR(255),
  IN NEW_FLT_CARRIER INT,
  IN NEW_FLT_PBX INT,
  IN NEW_FLT_MSTEAMS INT,
  IN NEW_FLT_OUTBOUND INT,
  IN NEW_FLT_INBOUND INT,
  IN NEW_FLT_LCR_MIN INT,
  IN NEW_FLT_FWD_MIN INT,
  IN NEW_DEFAULT_AUTH_DOMAIN VARCHAR(255),
  IN NEW_TELEBLOCK_GW_ENABLED TINYINT(1),
  IN NEW_TELEBLOCK_GW_IP VARCHAR(255),
  IN NEW_TELEBLOCK_GW_PORT VARCHAR(255),
  IN NEW_TELEBLOCK_MEDIA_IP VARCHAR(255),
  IN NEW_TELEBLOCK_MEDIA_PORT VARCHAR(255),
  IN NEW_FLOWROUTE_ACCESS_KEY VARCHAR(255),
  IN NEW_FLOWROUTE_SECRET_KEY VARCHAR(255),
  IN NEW_FLOWROUTE_API_ROOT_URL VARCHAR(255),
  IN NEW_HOMER_ID BIGINT,
  IN NEW_HOMER_HEP_HOST VARCHAR(255),
  IN NEW_HOMER_HEP_PORT INT,
  IN NEW_NETWORK_MODE INT,
  IN NEW_IPV6_ENABLED TINYINT(1),
  IN NEW_INTERNAL_IP_ADDR VARCHAR(255),
  IN NEW_INTERNAL_IP_NET VARCHAR(255),
  IN NEW_INTERNAL_IP6_ADDR VARCHAR(255),
  IN NEW_INTERNAL_IP6_NET VARCHAR(255),
  IN NEW_INTERNAL_FQDN VARCHAR(255),
  IN NEW_EXTERNAL_IP_ADDR VARCHAR(255),
  IN NEW_EXTERNAL_IP6_ADDR VARCHAR(255),
  IN NEW_EXTERNAL_FQDN VARCHAR(255),
  IN NEW_PUBLIC_IFACE VARCHAR(255),
  IN NEW_PRIVATE_IFACE VARCHAR(255),
  IN NEW_UPLOAD_FOLDER VARCHAR(255),
  IN NEW_MAIL_SERVER VARCHAR(255),
  IN NEW_MAIL_PORT INT,
  IN NEW_MAIL_USE_TLS TINYINT(1),
  IN NEW_MAIL_USERNAME VARCHAR(255),
  IN NEW_MAIL_PASSWORD VARBINARY(144),
  IN NEW_MAIL_ASCII_ATTACHMENTS TINYINT(1),
  IN NEW_MAIL_DEFAULT_SENDER VARCHAR(255),
  IN NEW_MAIL_DEFAULT_SUBJECT VARCHAR(255),
  IN NEW_DSIP_LICENSE_STORE BLOB,
  IN NEW_RTPENGINE_URI VARCHAR(255)
)
BEGIN
  START TRANSACTION;

  REPLACE INTO dsip_settings
  VALUES (NEW_DSIP_ID,
          NEW_DSIP_CLUSTER_ID,
          NEW_DSIP_CLUSTER_SYNC,
          NEW_DSIP_PROTO,
          NEW_DSIP_PORT,
          NEW_DSIP_USERNAME,
          NEW_DSIP_PASSWORD,
          NEW_DSIP_IPC_PASS,
          NEW_DSIP_API_PROTO,
          NEW_DSIP_API_PORT,
          NEW_DSIP_PRIV_KEY,
          NEW_DSIP_PID_FILE,
          NEW_DSIP_UNIX_SOCK,
          NEW_DSIP_IPC_SOCK,
          NEW_DSIP_API_TOKEN,
          NEW_DSIP_LOG_LEVEL,
          NEW_DSIP_LOG_FACILITY,
          NEW_DSIP_SSL_KEY,
          NEW_DSIP_SSL_CERT,
          NEW_DSIP_SSL_CA,
          NEW_DSIP_SSL_EMAIL,
          NEW_DSIP_CERTS_DIR,
          NEW_VERSION,
          NEW_DEBUG,
          NEW_ROLE,
          NEW_GUI_INACTIVE_TIMEOUT,
          NEW_KAM_DB_HOST,
          NEW_KAM_DB_DRIVER,
          NEW_KAM_DB_TYPE,
          NEW_KAM_DB_PORT,
          NEW_KAM_DB_NAME,
          NEW_KAM_DB_USER,
          NEW_KAM_DB_PASS,
          NEW_KAM_KAMCMD_PATH,
          NEW_KAM_CFG_PATH,
          NEW_KAM_TLSCFG_PATH,
          NEW_RTP_CFG_PATH,
          NEW_FLT_CARRIER,
          NEW_FLT_PBX,
          NEW_FLT_MSTEAMS,
          NEW_FLT_OUTBOUND,
          NEW_FLT_INBOUND,
          NEW_FLT_LCR_MIN,
          NEW_FLT_FWD_MIN,
          NEW_DEFAULT_AUTH_DOMAIN,
          NEW_TELEBLOCK_GW_ENABLED,
          NEW_TELEBLOCK_GW_IP,
          NEW_TELEBLOCK_GW_PORT,
          NEW_TELEBLOCK_MEDIA_IP,
          NEW_TELEBLOCK_MEDIA_PORT,
          NEW_FLOWROUTE_ACCESS_KEY,
          NEW_FLOWROUTE_SECRET_KEY,
          NEW_FLOWROUTE_API_ROOT_URL,
          NEW_HOMER_ID,
          NEW_HOMER_HEP_HOST,
          NEW_HOMER_HEP_PORT,
          NEW_NETWORK_MODE,
          NEW_IPV6_ENABLED,
          NEW_INTERNAL_IP_ADDR,
          NEW_INTERNAL_IP_NET,
          NEW_INTERNAL_IP6_ADDR,
          NEW_INTERNAL_IP6_NET,
          NEW_INTERNAL_FQDN,
          NEW_EXTERNAL_IP_ADDR,
          NEW_EXTERNAL_IP6_ADDR,
          NEW_EXTERNAL_FQDN,
          NEW_PUBLIC_IFACE,
          NEW_PRIVATE_IFACE,
          NEW_UPLOAD_FOLDER,
          NEW_MAIL_SERVER,
          NEW_MAIL_PORT,
          NEW_MAIL_USE_TLS,
          NEW_MAIL_USERNAME,
          NEW_MAIL_PASSWORD,
          NEW_MAIL_ASCII_ATTACHMENTS,
          NEW_MAIL_DEFAULT_SENDER,
          NEW_MAIL_DEFAULT_SUBJECT,
          NEW_DSIP_LICENSE_STORE,
          NEW_RTPENGINE_URI);

  IF NEW_DSIP_CLUSTER_SYNC = 1 THEN
    UPDATE dsip_settings
    SET DSIP_PROTO             = NEW_DSIP_PROTO,
        DSIP_PORT              = NEW_DSIP_PORT,
        DSIP_USERNAME          = NEW_DSIP_USERNAME,
        DSIP_PASSWORD          = NEW_DSIP_PASSWORD,
        DSIP_IPC_PASS          = NEW_DSIP_IPC_PASS,
        DSIP_API_PROTO         = NEW_DSIP_API_PROTO,
        DSIP_API_PORT          = NEW_DSIP_API_PORT,
        DSIP_PRIV_KEY          = NEW_DSIP_PRIV_KEY,
        DSIP_PID_FILE          = NEW_DSIP_PID_FILE,
        DSIP_UNIX_SOCK         = NEW_DSIP_UNIX_SOCK,
        DSIP_IPC_SOCK          = NEW_DSIP_IPC_SOCK,
        DSIP_API_TOKEN         = NEW_DSIP_API_TOKEN,
        DSIP_LOG_LEVEL         = NEW_DSIP_LOG_LEVEL,
        DSIP_LOG_FACILITY      = NEW_DSIP_LOG_FACILITY,
        DSIP_SSL_KEY           = NEW_DSIP_SSL_KEY,
        DSIP_SSL_CERT          = NEW_DSIP_SSL_CERT,
        DSIP_SSL_CA            = NEW_DSIP_SSL_CA,
        DSIP_SSL_EMAIL         = NEW_DSIP_SSL_EMAIL,
        DSIP_CERTS_DIR         = NEW_DSIP_CERTS_DIR,
        VERSION                = NEW_VERSION,
        DEBUG                  = NEW_DEBUG,
        `ROLE`                 = NEW_ROLE,
        GUI_INACTIVE_TIMEOUT   = NEW_GUI_INACTIVE_TIMEOUT,
        KAM_DB_HOST            = NEW_KAM_DB_HOST,
        KAM_DB_DRIVER          = NEW_KAM_DB_DRIVER,
        KAM_DB_TYPE            = NEW_KAM_DB_TYPE,
        KAM_DB_PORT            = NEW_KAM_DB_PORT,
        KAM_DB_NAME            = NEW_KAM_DB_NAME,
        KAM_DB_USER            = NEW_KAM_DB_USER,
        KAM_DB_PASS            = NEW_KAM_DB_PASS,
        KAM_KAMCMD_PATH        = NEW_KAM_KAMCMD_PATH,
        KAM_CFG_PATH           = NEW_KAM_CFG_PATH,
        KAM_TLSCFG_PATH        = NEW_KAM_TLSCFG_PATH,
        RTP_CFG_PATH           = NEW_RTP_CFG_PATH,
        FLT_CARRIER            = NEW_FLT_CARRIER,
        FLT_PBX                = NEW_FLT_PBX,
        FLT_MSTEAMS            = NEW_FLT_MSTEAMS,
        FLT_OUTBOUND           = NEW_FLT_OUTBOUND,
        FLT_INBOUND            = NEW_FLT_INBOUND,
        FLT_LCR_MIN            = NEW_FLT_LCR_MIN,
        FLT_FWD_MIN            = NEW_FLT_FWD_MIN,
        DEFAULT_AUTH_DOMAIN    = NEW_DEFAULT_AUTH_DOMAIN,
        TELEBLOCK_GW_ENABLED   = NEW_TELEBLOCK_GW_ENABLED,
        TELEBLOCK_GW_IP        = NEW_TELEBLOCK_GW_IP,
        TELEBLOCK_GW_PORT      = NEW_TELEBLOCK_GW_PORT,
        TELEBLOCK_MEDIA_IP     = NEW_TELEBLOCK_MEDIA_IP,
        TELEBLOCK_MEDIA_PORT   = NEW_TELEBLOCK_MEDIA_PORT,
        FLOWROUTE_ACCESS_KEY   = NEW_FLOWROUTE_ACCESS_KEY,
        FLOWROUTE_SECRET_KEY   = NEW_FLOWROUTE_SECRET_KEY,
        FLOWROUTE_API_ROOT_URL = NEW_FLOWROUTE_API_ROOT_URL,
        HOMER_HEP_HOST         = NEW_HOMER_HEP_HOST,
        HOMER_HEP_PORT         = NEW_HOMER_HEP_PORT,
        UPLOAD_FOLDER          = NEW_UPLOAD_FOLDER,
        MAIL_SERVER            = NEW_MAIL_SERVER,
        MAIL_PORT              = NEW_MAIL_PORT,
        MAIL_USE_TLS           = NEW_MAIL_USE_TLS,
        MAIL_USERNAME          = NEW_MAIL_USERNAME,
        MAIL_PASSWORD          = NEW_MAIL_PASSWORD,
        MAIL_ASCII_ATTACHMENTS = NEW_MAIL_ASCII_ATTACHMENTS,
        MAIL_DEFAULT_SENDER    = NEW_MAIL_DEFAULT_SENDER,
        MAIL_DEFAULT_SUBJECT   = NEW_MAIL_DEFAULT_SUBJECT,
        RTPENGINE_URI          = NEW_RTPENGINE_URI
    WHERE DSIP_CLUSTER_ID = NEW_DSIP_CLUSTER_ID
      AND DSIP_CLUSTER_SYNC = 1
      AND DSIP_ID != NEW_DSIP_ID;
  END IF;
  COMMIT;
END ;;
DELIMITER ;
/*!50003 SET sql_mode              = @saved_sql_mode */ ;
/*!50003 SET character_set_client  = @saved_cs_client */ ;
/*!50003 SET character_set_results = @saved_cs_results */ ;
/*!50003 SET collation_connection  = @saved_col_connection */ ;

--
-- Final view structure for view `dsip_call_settings_h`
--

/*!50001 DROP VIEW IF EXISTS `dsip_call_settings_h`*/;
/*!50001 SET @saved_cs_client          = @@character_set_client */;
/*!50001 SET @saved_cs_results         = @@character_set_results */;
/*!50001 SET @saved_col_connection     = @@collation_connection */;
/*!50001 SET character_set_client      = utf8mb3 */;
/*!50001 SET character_set_results     = utf8mb3 */;
/*!50001 SET collation_connection      = utf8mb3_general_ci */;
/*!50001 CREATE ALGORITHM=UNDEFINED */
/*!50013 DEFINER=`root`@`localhost` SQL SECURITY DEFINER */
/*!50001 VIEW `dsip_call_settings_h` AS select cast(`dsip_call_settings`.`gwgroupid` as char charset utf8mb3) AS `gwgroupid`,cast(`dsip_call_settings`.`limit` as char charset utf8mb3) AS `limit`,cast(`dsip_call_settings`.`timeout` as char charset utf8mb3) AS `timeout` from `dsip_call_settings` */;
/*!50001 SET character_set_client      = @saved_cs_client */;
/*!50001 SET character_set_results     = @saved_cs_results */;
/*!50001 SET collation_connection      = @saved_col_connection */;

--
-- Final view structure for view `dsip_dnid_lnp_mapping`
--

/*!50001 DROP VIEW IF EXISTS `dsip_dnid_lnp_mapping`*/;
/*!50001 SET @saved_cs_client          = @@character_set_client */;
/*!50001 SET @saved_cs_results         = @@character_set_results */;
/*!50001 SET @saved_col_connection     = @@collation_connection */;
/*!50001 SET character_set_client      = utf8mb3 */;
/*!50001 SET character_set_results     = utf8mb3 */;
/*!50001 SET collation_connection      = utf8mb3_general_ci */;
/*!50001 CREATE ALGORITHM=UNDEFINED */
/*!50013 DEFINER=`root`@`localhost` SQL SECURITY DEFINER */
/*!50001 VIEW `dsip_dnid_lnp_mapping` AS select `dsip_dnid_enrich_lnp`.`dnid` AS `dnid`,concat(`dsip_dnid_enrich_lnp`.`country_code`,`dsip_dnid_enrich_lnp`.`routing_number`) AS `prefix`,'0' AS `key_type`,'0' AS `value_type` from `dsip_dnid_enrich_lnp` */;
/*!50001 SET character_set_client      = @saved_cs_client */;
/*!50001 SET character_set_results     = @saved_cs_results */;
/*!50001 SET collation_connection      = @saved_col_connection */;

--
-- Final view structure for view `dsip_prefix_mapping`
--

/*!50001 DROP VIEW IF EXISTS `dsip_prefix_mapping`*/;
/*!50001 SET @saved_cs_client          = @@character_set_client */;
/*!50001 SET @saved_cs_results         = @@character_set_results */;
/*!50001 SET @saved_col_connection     = @@collation_connection */;
/*!50001 SET character_set_client      = utf8mb3 */;
/*!50001 SET character_set_results     = utf8mb3 */;
/*!50001 SET collation_connection      = utf8mb3_general_ci */;
/*!50001 CREATE ALGORITHM=UNDEFINED */
/*!50013 DEFINER=`root`@`localhost` SQL SECURITY DEFINER */
/*!50001 VIEW `dsip_prefix_mapping` AS select `dr_rules`.`prefix` AS `prefix`,cast(`dr_rules`.`ruleid` as char charset utf8mb3) AS `ruleid`,cast(`dr_rules`.`priority` as char charset utf8mb3) AS `priority`,'0' AS `key_type`,'0' AS `value_type` from `dr_rules` where `dr_rules`.`groupid` = '9000' */;
/*!50001 SET character_set_client      = @saved_cs_client */;
/*!50001 SET character_set_results     = @saved_cs_results */;
/*!50001 SET collation_connection      = @saved_col_connection */;
/*!40103 SET TIME_ZONE=@OLD_TIME_ZONE */;

/*!40101 SET SQL_MODE=@OLD_SQL_MODE */;
/*!40014 SET FOREIGN_KEY_CHECKS=@OLD_FOREIGN_KEY_CHECKS */;
/*!40014 SET UNIQUE_CHECKS=@OLD_UNIQUE_CHECKS */;
/*!40101 SET CHARACTER_SET_CLIENT=@OLD_CHARACTER_SET_CLIENT */;
/*!40101 SET CHARACTER_SET_RESULTS=@OLD_CHARACTER_SET_RESULTS */;
/*!40101 SET COLLATION_CONNECTION=@OLD_COLLATION_CONNECTION */;
/*!40111 SET SQL_NOTES=@OLD_SQL_NOTES */;

-- Dump completed on 2026-03-14 14:48:31
