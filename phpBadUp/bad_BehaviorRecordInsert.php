<?php
require_once "bad_Common.php";
require_once "bad_Database.php";

$data = badGetRequestData();
badRequireFields($data, ['behaviorId']);

try {
    $pdo = Database::getPdoInstance();
    $now = date('Y-m-d H:i:s');
    $recordedAt = !empty($data['recordedAt']) ? trim($data['recordedAt']) : $now;
    $recordDate = !empty($data['recordDate']) ? trim($data['recordDate']) : substr($recordedAt, 0, 10);

    $stmt = $pdo->prepare("
        INSERT INTO bad_BehaviorRecord
        (userId, behaviorId, recordDate, recordedAt, countNum, clientUid, createdAt)
        VALUES
        (:userId, :behaviorId, :recordDate, :recordedAt, :countNum, :clientUid, :createdAt)
    ");
    $stmt->execute([
        ':userId' => isset($data['userId']) && $data['userId'] !== '' ? intval($data['userId']) : null,
        ':behaviorId' => intval($data['behaviorId']),
        ':recordDate' => $recordDate,
        ':recordedAt' => $recordedAt,
        ':countNum' => isset($data['countNum']) ? intval($data['countNum']) : 1,
        ':clientUid' => isset($data['clientUid']) ? trim($data['clientUid']) : null,
        ':createdAt' => $now
    ]);

    badResponse(200, 'InsertSuccess', ['recordId' => $pdo->lastInsertId()]);
} catch (PDOException $e) {
    badResponse(500, 'DataError: ' . $e->getMessage());
}
?>
