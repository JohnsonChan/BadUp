/******************************************/
/*   TableName = bad_Behavior             */
/*   Add scoreUnit for configurable score  */
/******************************************/

ALTER TABLE `bad_Behavior`
  ADD COLUMN `scoreUnit` int(11) NOT NULL DEFAULT '-2' COMMENT '单次记录分值：好习惯1到5，坏习惯-1到-5' AFTER `behaviorType`;

UPDATE `bad_Behavior`
   SET `scoreUnit` = CASE
       WHEN `behaviorType` = 1 THEN 1
       ELSE -2
   END;
