<?php
// 首页今日统计接口。
// 返回用户可见的习惯项列表，并附带指定日期的统计次数。
require_once "bad_Common.php";
require_once "bad_Database.php";

$data = badGetRequestData();
$userId = isset($data['userId']) && $data['userId'] !== '' ? intval($data['userId']) : null;
$recordDate = !empty($data['recordDate']) ? trim($data['recordDate']) : date('Y-m-d');

try {
    $pdo = Database::getPdoInstance();

    // LEFT JOIN 保证即使今天没有记录，习惯项也会返回，todayCount 为 0。
    $sql = "
        SELECT b.behaviorId, b.userId, b.behaviorName, b.behaviorDesc, b.colorHex, b.behaviorType, b.sortOrder,
               IFNULL(SUM(r.countNum), 0) AS todayCount
        FROM bad_Behavior b
        LEFT JOIN bad_BehaviorRecord r
          ON b.behaviorId = r.behaviorId
         AND r.recordDate = :recordDate
    ";

    if ($userId) {
        // 登录用户可以看到系统默认习惯和自己创建的习惯。
        $sql .= " WHERE b.userId IS NULL OR b.userId = :userId";
    } else {
        $sql .= " WHERE b.userId IS NULL";
    }

    $sql .= " GROUP BY b.behaviorId ORDER BY b.sortOrder ASC, b.behaviorId ASC";

    $stmt = $pdo->prepare($sql);
    $params = [':recordDate' => $recordDate];
    if ($userId) {
        $params[':userId'] = $userId;
    }
    $stmt->execute($params);

    badResponse(200, 'OK', ['list' => $stmt->fetchAll()]);
} catch (PDOException $e) {
    badResponse(500, 'DataError: ' . $e->getMessage());
}
?>
