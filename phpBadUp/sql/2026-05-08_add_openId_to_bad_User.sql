ALTER TABLE `bad_User`
  ADD COLUMN `openId` varchar(64) DEFAULT NULL COMMENT '微信OpenID，微信小程序稳定用户标识' AFTER `avatar`,
  ADD UNIQUE KEY `uniq_openId` (`openId`) USING BTREE;
