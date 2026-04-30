/******************************************/
/*   DatabaseName = hdm33422916_db   */
/*   TableName = bad_Behavior   */
/******************************************/
CREATE TABLE `bad_Behavior` (
  `behaviorId` int(10) unsigned NOT NULL AUTO_INCREMENT COMMENT '行为项主键，自增',
  `userId` int(10) unsigned DEFAULT NULL COMMENT '所属用户，空表示系统默认行为',
  `behaviorName` varchar(100) NOT NULL COMMENT '行为名称，例如刷视频',
  `behaviorDesc` varchar(255) DEFAULT NULL COMMENT '行为描述',
  `colorHex` varchar(7) NOT NULL COMMENT '按钮颜色，例如 #F55F52',
  `behaviorType` tinyint(4) NOT NULL DEFAULT '-1' COMMENT '行为类型：1好行为，-1坏行为',
  `sortOrder` int(11) NOT NULL DEFAULT '0' COMMENT '排序值，数值越小越靠前，暂时没用',
  `createdAt` datetime NOT NULL COMMENT '创建时间，由PHP赋值',
  `updatedAt` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT '更新时间',
  PRIMARY KEY (`behaviorId`),
  UNIQUE KEY `uniq_userId_behaviorName` (`userId`,`behaviorName`) USING BTREE,
  KEY `idx_userId_isActive_sortOrder` (`userId`,`isActive`,`sortOrder`) USING BTREE,
  KEY `idx_userId_behaviorType` (`userId`,`behaviorType`) USING BTREE
) ENGINE=InnoDB AUTO_INCREMENT=115 DEFAULT CHARSET=utf8 ROW_FORMAT=COMPACT COMMENT='行为项定义表'
;
