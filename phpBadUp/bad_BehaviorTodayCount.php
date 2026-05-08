<?php
// 首页今日统计接口。
// 返回用户可见的习惯项列表，并附带指定日期的统计次数。
require_once "bad_Common.php";
require_once "bad_Database.php";

$data = badGetRequestData();
$userId = isset($data['userId']) && $data['userId'] !== '' ? intval($data['userId']) : null;
$subjectUserId = isset($data['subjectUserId']) && $data['subjectUserId'] !== '' ? intval($data['subjectUserId']) : $userId;
$recordDate = !empty($data['recordDate']) ? trim($data['recordDate']) : date('Y-m-d');

try {
    $pdo = Database::getPdoInstance();
    badRequireCanViewSubject($pdo, $userId, $subjectUserId);

    // LEFT JOIN 保证即使今天没有记录，习惯项也会返回，todayCount 为 0。
    $sql = "
        SELECT b.behaviorId, b.userId, b.creatorUserId, b.subjectUserId,
               b.behaviorName, b.behaviorDesc, b.colorHex, b.behaviorType, b.sortOrder,
               IFNULL(SUM(r.countNum), 0) AS todayCount
        FROM bad_Behavior b
        LEFT JOIN bad_BehaviorRecord r
          ON b.behaviorId = r.behaviorId
         AND r.recordDate = :recordDate
         AND (
                COALESCE(b.subjectUserId, b.userId) IS NOT NULL
             OR
                r.subjectUserId = :recordSubjectUserId
             OR (r.subjectUserId IS NULL AND r.userId = :recordLegacyUserId)
          )
    ";

    if ($subjectUserId) {
        // 登录用户可以看到系统默认习惯和目标用户自己的习惯。
        $sql .= " WHERE b.userId IS NULL OR COALESCE(b.subjectUserId, b.userId) = :subjectUserId";
    } else {
        $sql .= " WHERE b.userId IS NULL";
    }

    $sql .= " GROUP BY b.behaviorId ORDER BY b.sortOrder ASC, b.behaviorId ASC";

    $stmt = $pdo->prepare($sql);
    $params = [
        ':recordDate' => $recordDate,
        ':recordSubjectUserId' => $subjectUserId,
        ':recordLegacyUserId' => $subjectUserId
    ];
    if ($subjectUserId) {
        $params[':subjectUserId'] = $subjectUserId;
    }
    $stmt->execute($params);

    badResponse(200, 'OK', ['list' => $stmt->fetchAll()]);
} catch (PDOException $e) {
    badResponse(500, 'DataError: ' . $e->getMessage());
}
?>
