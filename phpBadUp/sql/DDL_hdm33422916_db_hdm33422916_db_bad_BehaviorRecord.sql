/******************************************/
/*   DatabaseName = hdm33422916_db   */
/*   TableName = bad_BehaviorRecord   */
/******************************************/
CREATE TABLE `bad_BehaviorRecord` (
  `recordId` bigint(20) unsigned NOT NULL AUTO_INCREMENT COMMENT '行为记录主键，自增',
  `userId` int(10) unsigned DEFAULT NULL COMMENT '所属用户',
  `behaviorId` int(10) unsigned NOT NULL COMMENT '对应 bad_ehavior.behaviorId',
  `recordDate` date NOT NULL COMMENT '按天统计用的日期',
  `recordedAt` datetime NOT NULL COMMENT '精确记录时间，由PHP赋值',
  `countNum` int(11) NOT NULL DEFAULT '1' COMMENT '本次记录次数，通常为1',
  `scoreValue` int(11) NOT NULL DEFAULT '-10' COMMENT '本条记录产生的行为分，按countNum计算',
  `clientUid` varchar(64) DEFAULT NULL COMMENT '客户端去重标识，可选',
  `createdAt` datetime NOT NULL COMMENT '创建时间，由PHP赋值',
  `updatedAt` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT '更新时间',
  PRIMARY KEY (`recordId`),
  UNIQUE KEY `uniq_clientUid` (`clientUid`) USING BTREE,
  KEY `idx_userId_behaviorId_recordDate` (`userId`,`behaviorId`,`recordDate`) USING BTREE,
  KEY `idx_behaviorId_recordedAt` (`behaviorId`,`recordedAt`) USING BTREE
) ENGINE=InnoDB AUTO_INCREMENT=1015 DEFAULT CHARSET=utf8 ROW_FORMAT=COMPACT COMMENT='行为记录表'
;
