<?php
require_once "bad_Common.php";
require_once "bad_Database.php";

$data = badGetRequestData();
badRequireFields($data, ['behaviorId', 'year', 'month']);

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
        ':year' => intval($data['year']),
        ':month' => intval($data['month'])
    ];
    if ($behaviorSubjectUserId === null && $subjectUserId !== null) {
        $subjectWhere = " AND (subjectUserId = :subjectUserId OR (subjectUserId IS NULL AND userId = :legacyUserId))";
        $params[':subjectUserId'] = $subjectUserId;
        $params[':legacyUserId'] = $subjectUserId;
    }

    $stmt = $pdo->prepare("
        SELECT DAY(recordDate) AS dayNum, IFNULL(SUM(countNum), 0) AS totalCount
        FROM bad_BehaviorRecord
        WHERE behaviorId = :behaviorId
          $subjectWhere
          AND YEAR(recordDate) = :year
          AND MONTH(recordDate) = :month
        GROUP BY DAY(recordDate)
        ORDER BY dayNum ASC
    ");
    $stmt->execute($params);

    badResponse(200, 'OK', ['list' => $stmt->fetchAll()]);
} catch (PDOException $e) {
    badResponse(500, 'DataError: ' . $e->getMessage());
}
?>
