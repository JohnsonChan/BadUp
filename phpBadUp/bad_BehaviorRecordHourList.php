<?php
// 某小时内单条习惯记录列表。
// 日详情页点击某个小时后调用，拿到 recordId 后才能删除其中一条记录。
require_once "bad_Common.php";
require_once "bad_Database.php";

$data = badGetRequestData();
badRequireFields($data, ['userId', 'behaviorId', 'recordDate', 'hourNum']);

function badRecordOperatorDisplayName($pdo, $viewerUserId, $operatorUserId) {
    $operatorUserId = intval($operatorUserId);
    if ($operatorUserId <= 0) {
        return '';
    }

    $userQuery = $pdo->prepare("SELECT userName FROM bad_User WHERE userId = :userId LIMIT 1");
    $userQuery->execute([':userId' => $operatorUserId]);
    $operator = $userQuery->fetch();
    $fallbackName = $operator && !empty($operator['userName']) ? $operator['userName'] : ('种子' . $operatorUserId);

    if (intval($viewerUserId) === $operatorUserId) {
        return $fallbackName;
    }

    $guardianRemarkQuery = $pdo->prepare("
        SELECT guardianRemark
        FROM bad_CareRelation
        WHERE status = 1
          AND guardianUserId = :viewerUserId
          AND caredUserId = :operatorUserId
        ORDER BY updatedAt DESC, careId DESC
        LIMIT 1
    ");
    $guardianRemarkQuery->execute([
        ':viewerUserId' => intval($viewerUserId),
        ':operatorUserId' => $operatorUserId
    ]);
    $guardianRemarkRow = $guardianRemarkQuery->fetch();
    if ($guardianRemarkRow) {
        $remark = trim((string)$guardianRemarkRow['guardianRemark']);
        if ($remark !== '') return $remark;
    }

    $caredRemarkQuery = $pdo->prepare("
        SELECT caredRemark
        FROM bad_CareRelation
        WHERE status = 1
          AND guardianUserId = :operatorUserId
          AND caredUserId = :viewerUserId
        ORDER BY updatedAt DESC, careId DESC
        LIMIT 1
    ");
    $caredRemarkQuery->execute([
        ':operatorUserId' => $operatorUserId,
        ':viewerUserId' => intval($viewerUserId)
    ]);
    $caredRemarkRow = $caredRemarkQuery->fetch();
    if ($caredRemarkRow) {
        $remark = trim((string)$caredRemarkRow['caredRemark']);
        if ($remark !== '') return $remark;
    }

    return $fallbackName;
}

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

    $pdo = Database::getPdoInstance();
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
    $subjectUserId = $requestSubjectUserId !== null ? $requestSubjectUserId : ($behaviorSubjectUserId !== null ? $behaviorSubjectUserId : $userId);
    if ($subjectUserId === null || $subjectUserId <= 0) {
        $subjectUserId = $userId;
    }
    badRequireCanViewSubject($pdo, $userId, $subjectUserId);
    $canDelete = badCanManageSubject($pdo, $userId, $subjectUserId) ? 1 : 0;

    $subjectWhere = "";
    $params = [
        ':behaviorId' => $behaviorId,
        ':recordDate' => $recordDate,
        ':hourNum' => $hourNum
    ];
    if ($behaviorSubjectUserId === null && $subjectUserId !== null) {
        $subjectWhere = " AND (subjectUserId = :subjectUserId OR (subjectUserId IS NULL AND userId = :legacyUserId))";
        $params[':subjectUserId'] = $subjectUserId;
        $params[':legacyUserId'] = $subjectUserId;
    }

    $stmt = $pdo->prepare("
        SELECT recordId, userId, operatorUserId, subjectUserId, behaviorId, recordDate, recordedAt, countNum, scoreValue, createdAt
        FROM bad_BehaviorRecord
        WHERE behaviorId = :behaviorId
          $subjectWhere
          AND recordDate = :recordDate
          AND HOUR(recordedAt) = :hourNum
        ORDER BY recordedAt ASC, recordId ASC
    ");
    $stmt->execute($params);

    $records = [];
    foreach ($stmt->fetchAll() as $record) {
        $operatorUserId = isset($record['operatorUserId']) && $record['operatorUserId'] !== null && $record['operatorUserId'] !== ''
            ? intval($record['operatorUserId'])
            : intval($record['userId']);
        $operatorDisplayName = badRecordOperatorDisplayName($pdo, $userId, $operatorUserId);
        $record['operatorUserId'] = $operatorUserId;
        $record['operatorDisplayName'] = $operatorDisplayName;
        $record['showOperatorNote'] = $operatorUserId !== $userId ? 1 : 0;
        $record['operatorRecordText'] = $operatorUserId !== $userId && $operatorDisplayName !== '' ? ($operatorDisplayName . '记录') : '';
        $record['canDelete'] = $canDelete;
        $records[] = $record;
    }

    badResponse(200, 'OK', ['list' => $records]);
} catch (PDOException $e) {
    badResponse(500, 'DataError: ' . $e->getMessage());
}
?>
