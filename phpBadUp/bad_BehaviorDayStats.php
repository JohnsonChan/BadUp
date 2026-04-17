<?php
require_once "bad_Common.php";
require_once "bad_Database.php";

$data = badGetRequestData();
badRequireFields($data, ['behaviorId', 'recordDate']);

try {
    $pdo = Database::getPdoInstance();
    $stmt = $pdo->prepare("
        SELECT HOUR(recordedAt) AS hourNum, IFNULL(SUM(countNum), 0) AS totalCount
        FROM bad_BehaviorRecord
        WHERE behaviorId = :behaviorId
          AND recordDate = :recordDate
        GROUP BY HOUR(recordedAt)
        ORDER BY hourNum ASC
    ");
    $stmt->execute([
        ':behaviorId' => intval($data['behaviorId']),
        ':recordDate' => trim($data['recordDate'])
    ]);

    badResponse(200, 'OK', ['list' => $stmt->fetchAll()]);
} catch (PDOException $e) {
    badResponse(500, 'DataError: ' . $e->getMessage());
}
?>
