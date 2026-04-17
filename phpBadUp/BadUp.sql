/******************************************/
/*   DatabaseName = badup                */
/*   TableName = bad_user                */
/******************************************/
CREATE TABLE `bad_User` (
  `userId` int(10) unsigned NOT NULL AUTO_INCREMENT COMMENT '用户主键，自增',
  `userCode` varchar(64) DEFAULT NULL COMMENT '用户编号或邀请码，可选',
  `userName` varchar(64) DEFAULT NULL COMMENT '用户名或昵称',
  `phone` varchar(20) DEFAULT NULL COMMENT '手机号',
  `email` varchar(100) DEFAULT NULL COMMENT '邮箱',
  `password` varchar(255) DEFAULT NULL COMMENT '密码摘要，可选',
  `avatar` varchar(255) DEFAULT NULL COMMENT '头像地址',
  `deviceId` varchar(100) DEFAULT NULL COMMENT '设备唯一标识',
  `platform` varchar(20) DEFAULT NULL COMMENT '平台，例如 iOS',
  `appVersion` varchar(20) DEFAULT NULL COMMENT 'App版本号',
  `systemVersion` varchar(20) DEFAULT NULL COMMENT '系统版本号',
  `ip` varchar(45) DEFAULT NULL COMMENT '最近一次登录IP',
  `status` tinyint(1) NOT NULL DEFAULT '1' COMMENT '状态，1正常，0禁用',
  `createdAt` datetime NOT NULL COMMENT '创建时间，由PHP赋值',
  `updatedAt` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT '更新时间',
  PRIMARY KEY (`userId`),
  UNIQUE KEY `uniq_userCode` (`userCode`) USING BTREE,
  UNIQUE KEY `uniq_phone` (`phone`) USING BTREE,
  KEY `idx_deviceId` (`deviceId`) USING BTREE
) ENGINE=InnoDB AUTO_INCREMENT=10001 DEFAULT CHARSET=utf8 ROW_FORMAT=COMPACT COMMENT='用户信息表'
;

/******************************************/
/*   DatabaseName = badup                */
/*   TableName = bad_behavior            */
/******************************************/
CREATE TABLE `bad_Behavior` (
  `behaviorId` int(10) unsigned NOT NULL AUTO_INCREMENT COMMENT '行为项主键，自增',
  `userId` int(10) unsigned DEFAULT NULL COMMENT '所属用户，空表示系统默认行为',
  `behaviorName` varchar(100) NOT NULL COMMENT '行为名称，例如刷视频',
  `behaviorDesc` varchar(255) DEFAULT NULL COMMENT '行为描述',
  `colorHex` varchar(7) NOT NULL COMMENT '按钮颜色，例如 #F55F52',
  `sortOrder` int(11) NOT NULL DEFAULT '0' COMMENT '排序值，数值越小越靠前',
  `isActive` tinyint(1) NOT NULL DEFAULT '1' COMMENT '是否启用，1启用，0停用',
  `createdAt` datetime NOT NULL COMMENT '创建时间，由PHP赋值',
  `updatedAt` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT '更新时间',
  PRIMARY KEY (`behaviorId`),
  UNIQUE KEY `uniq_userId_behaviorName` (`userId`,`behaviorName`) USING BTREE,
  KEY `idx_userId_isActive_sortOrder` (`userId`,`isActive`,`sortOrder`) USING BTREE
) ENGINE=InnoDB AUTO_INCREMENT=101 DEFAULT CHARSET=utf8 ROW_FORMAT=COMPACT COMMENT='行为项定义表'
;

/******************************************/
/*   DatabaseName = badup                */
/*   TableName = bad_behaviorRecord      */
/******************************************/
CREATE TABLE `bad_BehaviorRecord` (
  `recordId` bigint(20) unsigned NOT NULL AUTO_INCREMENT COMMENT '行为记录主键，自增',
  `userId` int(10) unsigned DEFAULT NULL COMMENT '所属用户',
  `behaviorId` int(10) unsigned NOT NULL COMMENT '对应 bad_ehavior.behaviorId',
  `recordDate` date NOT NULL COMMENT '按天统计用的日期',
  `recordedAt` datetime NOT NULL COMMENT '精确记录时间，由PHP赋值',
  `countNum` int(11) NOT NULL DEFAULT '1' COMMENT '本次记录次数，通常为1',
  `clientUid` varchar(64) DEFAULT NULL COMMENT '客户端去重标识，可选',
  `createdAt` datetime NOT NULL COMMENT '创建时间，由PHP赋值',
  `updatedAt` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT '更新时间',
  PRIMARY KEY (`recordId`),
  UNIQUE KEY `uniq_clientUid` (`clientUid`) USING BTREE,
  KEY `idx_userId_behaviorId_recordDate` (`userId`,`behaviorId`,`recordDate`) USING BTREE,
  KEY `idx_behaviorId_recordedAt` (`behaviorId`,`recordedAt`) USING BTREE
) ENGINE=InnoDB AUTO_INCREMENT=1001 DEFAULT CHARSET=utf8 ROW_FORMAT=COMPACT COMMENT='行为记录表'
;


