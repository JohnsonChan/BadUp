<?php
require_once "bad_Common.php";
require_once "bad_Database.php";

$data = badGetRequestData();
$userId = isset($data['userId']) && $data['userId'] !== '' ? intval($data['userId']) : null;
$recordDate = !empty($data['recordDate']) ? trim($data['recordDate']) : date('Y-m-d');

try {
    $pdo = Database::getPdoInstance();

    $sql = "
        SELECT b.behaviorId, b.userId, b.behaviorName, b.behaviorDesc, b.colorHex, b.sortOrder, b.isActive,
               IFNULL(SUM(r.countNum), 0) AS todayCount
        FROM bad_Behavior b
        LEFT JOIN bad_BehaviorRecord r
          ON b.behaviorId = r.behaviorId
         AND r.recordDate = :recordDate
    ";

    if ($userId) {
        $sql .= " WHERE b.isActive = 1 AND (b.userId IS NULL OR b.userId = :userId)";
    } else {
        $sql .= " WHERE b.isActive = 1 AND b.userId IS NULL";
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
