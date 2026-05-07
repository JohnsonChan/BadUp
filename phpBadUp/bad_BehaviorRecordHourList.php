<?php
// 某小时内单条习惯记录列表。
// 日详情页点击某个小时后调用，拿到 recordId 后才能删除其中一条记录。
require_once "bad_Common.php";
require_once "bad_Database.php";

$data = badGetRequestData();
badRequireFields($data, ['userId', 'behaviorId', 'recordDate', 'hourNum']);

try {
    $userId = intval($data['userId']);
    $behaviorId = intval($data['behaviorId']);
    $recordDate = trim($data['recordDate']);
    $hourNum = intval($data['hourNum']);

    if ($hourNum < 0 || $hourNum > 23) {
        badResponse(400, 'InvalidHour');
    }
    if (!preg_match('/^\d{4}-\d{2}-\d{2}$/', $recordDate)) {
        badResponse(400, 'InvalidRecordDate');
    }

    $startAt = sprintf('%s %02d:00:00', $recordDate, $hourNum);
    $endAt = date('Y-m-d H:i:s', strtotime($startAt . ' +1 hour'));

    $pdo = Database::getPdoInstance();
    $stmt = $pdo->prepare("
        SELECT recordId, userId, behaviorId, recordDate, recordedAt, countNum, scoreValue, createdAt
        FROM bad_BehaviorRecord
        WHERE userId = :userId
          AND behaviorId = :behaviorId
          AND recordDate = :recordDate
          AND recordedAt >= :startAt
          AND recordedAt < :endAt
        ORDER BY recordedAt ASC, recordId ASC
    ");
    $stmt->execute([
        ':userId' => $userId,
        ':behaviorId' => $behaviorId,
        ':recordDate' => $recordDate,
        ':startAt' => $startAt,
        ':endAt' => $endAt
    ]);

    badResponse(200, 'OK', ['list' => $stmt->fetchAll()]);
} catch (PDOException $e) {
    badResponse(500, 'DataError: ' . $e->getMessage());
}
?>
