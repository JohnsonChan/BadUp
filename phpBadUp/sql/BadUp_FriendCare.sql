/******************************************/
/*   DatabaseName = hdm33422916_db        */
/*   Feature = Care Relations              */
/*   Compatible with MySQL 5.1.73          */
/******************************************/

/******************************************/
/*   Upgrade TableName = bad_Behavior      */
/******************************************/
ALTER TABLE `bad_Behavior`
  ADD COLUMN `creatorUserId` int(10) unsigned DEFAULT NULL COMMENT '习惯创建者用户ID，自己创建或呵护者代创建' AFTER `userId`
;

ALTER TABLE `bad_Behavior`
  ADD COLUMN `subjectUserId` int(10) unsigned DEFAULT NULL COMMENT '习惯作用用户ID，也就是这个习惯属于谁' AFTER `creatorUserId`
;

ALTER TABLE `bad_Behavior`
  ADD KEY `idx_creatorUserId` (`creatorUserId`) USING BTREE
;

ALTER TABLE `bad_Behavior`
  ADD KEY `idx_subjectUserId_sortOrder` (`subjectUserId`,`sortOrder`) USING BTREE
;

UPDATE `bad_Behavior`
SET `subjectUserId` = `userId`
WHERE `subjectUserId` IS NULL
;

UPDATE `bad_Behavior`
SET `creatorUserId` = `userId`
WHERE `creatorUserId` IS NULL
  AND `userId` IS NOT NULL
;

/******************************************/
/*   Upgrade TableName = bad_BehaviorRecord */
/******************************************/
ALTER TABLE `bad_BehaviorRecord`
  ADD COLUMN `operatorUserId` int(10) unsigned DEFAULT NULL COMMENT '记录操作者用户ID，谁点了记录/删除' AFTER `userId`
;

ALTER TABLE `bad_BehaviorRecord`
  ADD COLUMN `subjectUserId` int(10) unsigned DEFAULT NULL COMMENT '记录作用用户ID，记录算到谁身上' AFTER `operatorUserId`
;

ALTER TABLE `bad_BehaviorRecord`
  ADD KEY `idx_subject_behavior_recordDate` (`subjectUserId`,`behaviorId`,`recordDate`) USING BTREE
;

ALTER TABLE `bad_BehaviorRecord`
  ADD KEY `idx_operator_recordedAt` (`operatorUserId`,`recordedAt`) USING BTREE
;

UPDATE `bad_BehaviorRecord`
SET `subjectUserId` = `userId`
WHERE `subjectUserId` IS NULL
;

UPDATE `bad_BehaviorRecord`
SET `operatorUserId` = `userId`
WHERE `operatorUserId` IS NULL
;

/******************************************/
/*   TableName = bad_CareRelation          */
/******************************************/
CREATE TABLE `bad_CareRelation` (
  `careId` int(10) unsigned NOT NULL AUTO_INCREMENT COMMENT '呵护关系主键，自增',
  `guardianUserId` int(10) unsigned NOT NULL COMMENT '呵护者用户ID',
  `caredUserId` int(10) unsigned NOT NULL COMMENT '被呵护者用户ID',
  `requesterUserId` int(10) unsigned NOT NULL COMMENT '发起呵护申请的用户ID',
  `permissionLevel` tinyint(4) NOT NULL DEFAULT '1' COMMENT '权限：1低，仅查看；2中，双方可改；3高，呵护者全权管理',
  `status` tinyint(4) NOT NULL DEFAULT '0' COMMENT '状态：0待确认，1已通过，2已拒绝',
  `rejectReason` varchar(255) DEFAULT NULL COMMENT '拒绝原因，拒绝时必填',
  `guardianRemark` varchar(64) DEFAULT NULL COMMENT '呵护者给被呵护者的备注',
  `caredRemark` varchar(64) DEFAULT NULL COMMENT '被呵护者给呵护者的备注',
  `createdAt` datetime NOT NULL COMMENT '创建时间，由PHP赋值',
  `updatedAt` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT '更新时间',
  PRIMARY KEY (`careId`),
  UNIQUE KEY `uniq_guardian_cared` (`guardianUserId`,`caredUserId`) USING BTREE,
  KEY `idx_cared_status` (`caredUserId`,`status`) USING BTREE,
  KEY `idx_guardian_status` (`guardianUserId`,`status`) USING BTREE,
  KEY `idx_requester_status` (`requesterUserId`,`status`) USING BTREE
) ENGINE=InnoDB DEFAULT CHARSET=utf8 ROW_FORMAT=COMPACT COMMENT='用户呵护关系表'
;
