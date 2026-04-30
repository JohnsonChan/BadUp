/******************************************/
/*   DatabaseName = hdm33422916_db   */
/*   TableName = bad_User   */
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
) ENGINE=InnoDB AUTO_INCREMENT=10015 DEFAULT CHARSET=utf8 ROW_FORMAT=COMPACT COMMENT='用户信息表'
;
