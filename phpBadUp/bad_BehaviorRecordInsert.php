<?php
// 习惯记录新增接口。
// 点击首页习惯按钮并确认后，客户端会调用这里写入一条 bad_BehaviorRecord。
require_once "bad_Common.php";
require_once "bad_Database.php";

$data = badGetRequestData();
badRequireFields($data, ['behaviorId']);

try {
    $pdo = Database::getPdoInstance();
    $now = date('Y-m-d H:i:s');
    // recordDate 用于按天统计，recordedAt 用于日详情按小时统计。
    $recordedAt = !empty($data['recordedAt']) ? trim($data['recordedAt']) : $now;
    $recordDate = !empty($data['recordDate']) ? trim($data['recordDate']) : substr($recordedAt, 0, 10);
    $userId = isset($data['userId']) && $data['userId'] !== '' ? intval($data['userId']) : null;
    $behaviorId = intval($data['behaviorId']);
    $countNum = isset($data['countNum']) ? intval($data['countNum']) : 1;
    if ($countNum <= 0) {
        $countNum = 1;
    }

    // 分数按习惯当前类型写入记录表，避免以后修改习惯类型影响历史分数。
    $behaviorQuery = $pdo->prepare("SELECT userId, behaviorType FROM bad_Behavior WHERE behaviorId = :behaviorId LIMIT 1");
    $behaviorQuery->execute([':behaviorId' => $behaviorId]);
    $behavior = $behaviorQuery->fetch();

    if (!$behavior) {
        badResponse(404, 'BehaviorNotFound');
    }
    if ($userId !== null && $behavior['userId'] !== null && intval($behavior['userId']) !== $userId) {
        badResponse(403, 'PermissionDenied');
    }

    $scoreValue = $countNum * badScoreUnitByBehaviorType($behavior['behaviorType']);

    $stmt = $pdo->prepare("
        INSERT INTO bad_BehaviorRecord
        (userId, behaviorId, recordDate, recordedAt, countNum, scoreValue, clientUid, createdAt)
        VALUES
        (:userId, :behaviorId, :recordDate, :recordedAt, :countNum, :scoreValue, :clientUid, :createdAt)
    ");
    $stmt->execute([
        ':userId' => $userId,
        ':behaviorId' => $behaviorId,
        ':recordDate' => $recordDate,
        ':recordedAt' => $recordedAt,
        ':countNum' => $countNum,
        ':scoreValue' => $scoreValue,
        ':clientUid' => isset($data['clientUid']) ? trim($data['clientUid']) : null,
        ':createdAt' => $now
    ]);

    badResponse(200, 'InsertSuccess', [
        'recordId' => $pdo->lastInsertId(),
        'scoreValue' => $scoreValue
    ]);
} catch (PDOException $e) {
    badResponse(500, 'DataError: ' . $e->getMessage());
}
?>
