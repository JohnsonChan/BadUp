<?php
require_once "bad_Common.php";
require_once "bad_Database.php";

$data = badGetRequestData();
badRequireFields($data, ['behaviorName', 'colorHex']);

try {
    $pdo = Database::getPdoInstance();
    $createdAt = date('Y-m-d H:i:s');
    $userId = isset($data['userId']) && $data['userId'] !== '' ? intval($data['userId']) : null;
    $subjectUserId = isset($data['subjectUserId']) && $data['subjectUserId'] !== '' ? intval($data['subjectUserId']) : $userId;

    badRequireCanManageSubject($pdo, $userId, $subjectUserId);

    if (isset($data['sortOrder'])) {
        $sortOrder = intval($data['sortOrder']);
    } else if ($subjectUserId === null) {
        $sortQuery = $pdo->query("SELECT IFNULL(MAX(sortOrder), 0) + 10 FROM bad_Behavior WHERE userId IS NULL");
        $sortOrder = intval($sortQuery->fetchColumn());
    } else {
        $sortQuery = $pdo->prepare("SELECT IFNULL(MAX(sortOrder), 0) + 10 FROM bad_Behavior WHERE userId = :subjectUserId");
        $sortQuery->execute([':subjectUserId' => $subjectUserId]);
        $sortOrder = intval($sortQuery->fetchColumn());
    }

    // scoreUnit 按习惯类型校验，避免客户端传入越界分值。
    $behaviorType = isset($data['behaviorType']) ? badNormalizeBehaviorType($data['behaviorType']) : 1;
    $scoreUnit = isset($data['scoreUnit'])
        ? badNormalizeScoreUnit($data['scoreUnit'], $behaviorType)
        : badScoreUnitByBehaviorType($behaviorType);

    $stmt = $pdo->prepare("
        INSERT INTO bad_Behavior
        (userId, creatorUserId, subjectUserId, behaviorName, behaviorDesc, colorHex, behaviorType, scoreUnit, sortOrder, createdAt)
        VALUES
        (:userId, :creatorUserId, :subjectUserId, :behaviorName, :behaviorDesc, :colorHex, :behaviorType, :scoreUnit, :sortOrder, :createdAt)
    ");
    $stmt->execute([
        ':userId' => $subjectUserId,
        ':creatorUserId' => $userId,
        ':subjectUserId' => $subjectUserId,
        ':behaviorName' => trim($data['behaviorName']),
        ':behaviorDesc' => isset($data['behaviorDesc']) ? trim($data['behaviorDesc']) : '',
        ':colorHex' => trim($data['colorHex']),
        ':behaviorType' => $behaviorType,
        ':scoreUnit' => $scoreUnit,
        ':sortOrder' => $sortOrder,
        ':createdAt' => $createdAt
    ]);

    $behaviorId = $pdo->lastInsertId();
    $query = $pdo->prepare("SELECT * FROM bad_Behavior WHERE behaviorId = :behaviorId LIMIT 1");
    $query->execute([':behaviorId' => $behaviorId]);
    badResponse(200, 'InsertSuccess', ['data' => $query->fetch()]);
} catch (PDOException $e) {
    if ($e->getCode() === '23000') {
        badResponse(409, '这个习惯名称已经存在，请换一个名称');
    }
    badResponse(500, 'DataError: ' . $e->getMessage());
}
?>
