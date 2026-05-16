<?php
// 发送呵护申请。
// 用户输入对方呵护码，请求“对方呵护我”；落库仍然只保存用户ID。
require_once "bad_Common.php";
require_once "bad_Database.php";

$data = badGetRequestData();
badRequireFields($data, ['userId', 'careCode', 'permissionLevel']);

try {
    $pdo = Database::getPdoInstance();
    $userId = intval($data['userId']);
    $guardianUserId = badDecodeCareCode($data['careCode']);
    $caredUserId = $userId;
    $permissionLevel = badNormalizeCarePermission($data['permissionLevel']);

    if ($guardianUserId <= 0 || $caredUserId <= 0 || $userId <= 0) {
        badResponse(400, '呵护码不正确，请检查后再试');
    }
    if ($guardianUserId === $caredUserId) {
        badResponse(400, '不能和自己建立呵护关系');
    }

    $guardianQuery = $pdo->prepare("SELECT userId FROM bad_User WHERE userId = :userId LIMIT 1");
    $guardianQuery->execute([':userId' => $guardianUserId]);
    if (!$guardianQuery->fetch()) {
        badResponse(404, '呵护码不正确，请检查后再试');
    }

    $existing = $pdo->prepare("
        SELECT careId, status, requesterUserId
        FROM bad_CareRelation
        WHERE guardianUserId = :guardianUserId
          AND caredUserId = :caredUserId
        LIMIT 1
    ");
    $existing->execute([
        ':guardianUserId' => $guardianUserId,
        ':caredUserId' => $caredUserId
    ]);
    $row = $existing->fetch();

    if ($row && intval($row['status']) === 1) {
        badResponse(409, '呵护关系已经建立');
    }
    if ($row && intval($row['status']) === 0) {
        badResponse(409, '呵护申请已发送，请等待对方确认');
    }

    $reverse = $pdo->prepare("
        SELECT guardianRemark, caredRemark
        FROM bad_CareRelation
        WHERE guardianUserId = :caredUserId
          AND caredUserId = :guardianUserId
        LIMIT 1
    ");
    $reverse->execute([
        ':guardianUserId' => $guardianUserId,
        ':caredUserId' => $caredUserId
    ]);
    $reverseRow = $reverse->fetch();
    $initialGuardianRemark = null;
    $initialCaredRemark = null;
    if ($reverseRow) {
        $reverseCaredRemark = trim((string)$reverseRow['caredRemark']);
        $reverseGuardianRemark = trim((string)$reverseRow['guardianRemark']);
        $initialGuardianRemark = $reverseCaredRemark !== '' ? $reverseCaredRemark : null;
        $initialCaredRemark = $reverseGuardianRemark !== '' ? $reverseGuardianRemark : null;
    }

    if ($row) {
        $stmt = $pdo->prepare("
            UPDATE bad_CareRelation
               SET requesterUserId = :requesterUserId,
                   permissionLevel = :permissionLevel,
                   status = 0,
                   rejectReason = NULL,
                   guardianRemark = :guardianRemark,
                   caredRemark = :caredRemark
             WHERE careId = :careId
             LIMIT 1
        ");
        $stmt->execute([
            ':requesterUserId' => $userId,
            ':permissionLevel' => $permissionLevel,
            ':guardianRemark' => $initialGuardianRemark,
            ':caredRemark' => $initialCaredRemark,
            ':careId' => intval($row['careId'])
        ]);
        badResponse(200, 'CareRequestSent', ['careId' => intval($row['careId'])]);
    }

    $stmt = $pdo->prepare("
        INSERT INTO bad_CareRelation
        (guardianUserId, caredUserId, requesterUserId, permissionLevel, status, rejectReason, guardianRemark, caredRemark, createdAt)
        VALUES
        (:guardianUserId, :caredUserId, :requesterUserId, :permissionLevel, 0, NULL, :guardianRemark, :caredRemark, :createdAt)
    ");
    $stmt->execute([
        ':guardianUserId' => $guardianUserId,
        ':caredUserId' => $caredUserId,
        ':requesterUserId' => $userId,
        ':permissionLevel' => $permissionLevel,
        ':guardianRemark' => $initialGuardianRemark,
        ':caredRemark' => $initialCaredRemark,
        ':createdAt' => date('Y-m-d H:i:s')
    ]);

    badResponse(200, 'CareRequestSent', ['careId' => $pdo->lastInsertId()]);
} catch (PDOException $e) {
    badResponse(500, 'DataError: ' . $e->getMessage());
}
?>
