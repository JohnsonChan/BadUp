<?php
require_once "bad_Common.php";
require_once "bad_Database.php";

$data = badGetRequestData();
badRequireFields($data, ['behaviorId', 'behaviorName', 'colorHex']);

try {
    $pdo = Database::getPdoInstance();
    $behaviorId = intval($data['behaviorId']);
    $userId = isset($data['userId']) && $data['userId'] !== '' ? intval($data['userId']) : null;

    $find = $pdo->prepare("SELECT * FROM bad_Behavior WHERE behaviorId = :behaviorId LIMIT 1");
    $find->execute([':behaviorId' => $behaviorId]);
    $behavior = $find->fetch();

    if (!$behavior) {
        badResponse(404, 'BehaviorNotFound');
    }

    if ($userId !== null && $behavior['userId'] !== null && intval($behavior['userId']) !== $userId) {
        badResponse(403, 'PermissionDenied');
    }

    $stmt = $pdo->prepare("
        UPDATE bad_Behavior
           SET behaviorName = :behaviorName,
               behaviorDesc = :behaviorDesc,
               colorHex = :colorHex
         WHERE behaviorId = :behaviorId
         LIMIT 1
    ");

    $stmt->execute([
        ':behaviorName' => trim($data['behaviorName']),
        ':behaviorDesc' => isset($data['behaviorDesc']) ? trim($data['behaviorDesc']) : '',
        ':colorHex' => trim($data['colorHex']),
        ':behaviorId' => $behaviorId
    ]);

    $query = $pdo->prepare("SELECT * FROM bad_Behavior WHERE behaviorId = :behaviorId LIMIT 1");
    $query->execute([':behaviorId' => $behaviorId]);
    badResponse(200, 'UpdateSuccess', ['data' => $query->fetch()]);
} catch (PDOException $e) {
    if ($e->getCode() === '23000') {
        badResponse(409, '这个行为名称已经存在，请换一个名称');
    }
    badResponse(500, 'DataError: ' . $e->getMessage());
}
?>
