<?php
require_once "bad_Common.php";
require_once "bad_Database.php";

$data = badGetRequestData();
badRequireFields($data, ['behaviorName', 'colorHex']);

try {
    $pdo = Database::getPdoInstance();
    $createdAt = date('Y-m-d H:i:s');

    $stmt = $pdo->prepare("
        INSERT INTO bad_Behavior
        (userId, behaviorName, behaviorDesc, colorHex, behaviorType, sortOrder, isActive, createdAt)
        VALUES
        (:userId, :behaviorName, :behaviorDesc, :colorHex, :behaviorType, :sortOrder, :isActive, :createdAt)
    ");
    $stmt->execute([
        ':userId' => isset($data['userId']) && $data['userId'] !== '' ? intval($data['userId']) : null,
        ':behaviorName' => trim($data['behaviorName']),
        ':behaviorDesc' => isset($data['behaviorDesc']) ? trim($data['behaviorDesc']) : '',
        ':colorHex' => trim($data['colorHex']),
        ':behaviorType' => isset($data['behaviorType']) ? badNormalizeBehaviorType($data['behaviorType']) : -1,
        ':sortOrder' => isset($data['sortOrder']) ? intval($data['sortOrder']) : 0,
        ':isActive' => isset($data['isActive']) ? intval($data['isActive']) : 1,
        ':createdAt' => $createdAt
    ]);

    $behaviorId = $pdo->lastInsertId();
    $query = $pdo->prepare("SELECT * FROM bad_Behavior WHERE behaviorId = :behaviorId LIMIT 1");
    $query->execute([':behaviorId' => $behaviorId]);
    badResponse(200, 'InsertSuccess', ['data' => $query->fetch()]);
} catch (PDOException $e) {
    badResponse(500, 'DataError: ' . $e->getMessage());
}
?>
