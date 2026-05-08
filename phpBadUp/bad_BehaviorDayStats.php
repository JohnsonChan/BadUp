<?php
require_once "bad_Common.php";
require_once "bad_Database.php";

$data = badGetRequestData();
badRequireFields($data, ['behaviorId', 'recordDate']);

try {
    $pdo = Database::getPdoInstance();
    $behaviorId = intval($data['behaviorId']);
    $actorUserId = isset($data['userId']) && $data['userId'] !== '' ? intval($data['userId']) : null;

    $behaviorQuery = $pdo->prepare("SELECT * FROM bad_Behavior WHERE behaviorId = :behaviorId LIMIT 1");
    $behaviorQuery->execute([':behaviorId' => $behaviorId]);
    $behavior = $behaviorQuery->fetch();
    if (!$behavior) {
        badResponse(404, 'BehaviorNotFound');
    }
    $behaviorSubjectUserId = badBehaviorSubjectUserId($behavior);
    $requestSubjectUserId = isset($data['subjectUserId']) && $data['subjectUserId'] !== '' ? intval($data['subjectUserId']) : null;
    if ($behaviorSubjectUserId !== null && $requestSubjectUserId !== null && $behaviorSubjectUserId !== $requestSubjectUserId) {
        badResponse(403, 'PermissionDenied');
    }
    $subjectUserId = $requestSubjectUserId !== null ? $requestSubjectUserId : ($behaviorSubjectUserId !== null ? $behaviorSubjectUserId : $actorUserId);
    if ($actorUserId !== null) {
        badRequireCanViewSubject($pdo, $actorUserId, $subjectUserId);
    }

    $subjectWhere = "";
    $params = [
        ':behaviorId' => $behaviorId,
        ':recordDate' => trim($data['recordDate'])
    ];
    if ($behaviorSubjectUserId === null && $subjectUserId !== null) {
        $subjectWhere = " AND (subjectUserId = :subjectUserId OR (subjectUserId IS NULL AND userId = :legacyUserId))";
        $params[':subjectUserId'] = $subjectUserId;
        $params[':legacyUserId'] = $subjectUserId;
    }

    $stmt = $pdo->prepare("
        SELECT HOUR(recordedAt) AS hourNum, IFNULL(SUM(countNum), 0) AS totalCount
        FROM bad_BehaviorRecord
        WHERE behaviorId = :behaviorId
          $subjectWhere
          AND recordDate = :recordDate
        GROUP BY HOUR(recordedAt)
        ORDER BY hourNum ASC
    ");
    $stmt->execute($params);

    badResponse(200, 'OK', ['list' => $stmt->fetchAll()]);
} catch (PDOException $e) {
    badResponse(500, 'DataError: ' . $e->getMessage());
}
?>
