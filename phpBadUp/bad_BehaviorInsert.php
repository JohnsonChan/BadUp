<?php
require_once "bad_Common.php";
require_once "bad_Database.php";

$data = badGetRequestData();
badRequireFields($data, ['behaviorName', 'colorHex']);

try {
    $pdo = Database::getPdoInstance();
    $createdAt = date('Y-m-d H:i:s');
    $userId = isset($data['userId']) && $data['userId'] !== '' ? intval($data['userId']) : null;

    if (isset($data['sortOrder'])) {
        $sortOrder = intval($data['sortOrder']);
    } else if ($userId === null) {
        $sortQuery = $pdo->query("SELECT IFNULL(MAX(sortOrder), 0) + 10 FROM bad_Behavior WHERE userId IS NULL");
        $sortOrder = intval($sortQuery->fetchColumn());
    } else {
        $sortQuery = $pdo->prepare("SELECT IFNULL(MAX(sortOrder), 0) + 10 FROM bad_Behavior WHERE userId = :userId");
        $sortQuery->execute([':userId' => $userId]);
        $sortOrder = intval($sortQuery->fetchColumn());
    }

    $stmt = $pdo->prepare("
        INSERT INTO bad_Behavior
        (userId, behaviorName, behaviorDesc, colorHex, behaviorType, sortOrder, createdAt)
        VALUES
        (:userId, :behaviorName, :behaviorDesc, :colorHex, :behaviorType, :sortOrder, :createdAt)
    ");
    $stmt->execute([
        ':userId' => $userId,
        ':behaviorName' => trim($data['behaviorName']),
        ':behaviorDesc' => isset($data['behaviorDesc']) ? trim($data['behaviorDesc']) : '',
        ':colorHex' => trim($data['colorHex']),
        ':behaviorType' => isset($data['behaviorType']) ? badNormalizeBehaviorType($data['behaviorType']) : 1,
        ':sortOrder' => $sortOrder,
        ':createdAt' => $createdAt
    ]);

    $behaviorId = $pdo->lastInsertId();
    $query = $pdo->prepare("SELECT * FROM bad_Behavior WHERE behaviorId = :behaviorId LIMIT 1");
    $query->execute([':behaviorId' => $behaviorId]);
    badResponse(200, 'InsertSuccess', ['data' => $query->fetch()]);
} catch (PDOException $e) {
    if ($e->getCode() === '23000') {
        badResponse(409, '这个行为名称已经存在，请换一个名称');
    }
    badResponse(500, 'DataError: ' . $e->getMessage());
}
?>
