<?php
// 被拒绝后重新发起呵护请求。
// 只允许原发起方操作，并且只处理已拒绝的关系。
require_once "bad_Common.php";
require_once "bad_Database.php";

$data = badGetRequestData();
badRequireFields($data, ['userId', 'careId', 'permissionLevel']);

try {
    $pdo = Database::getPdoInstance();
    $userId = intval($data['userId']);
    $careId = intval($data['careId']);
    $permissionLevel = badNormalizeCarePermission($data['permissionLevel']);

    $find = $pdo->prepare("
        SELECT careId, requesterUserId, status
        FROM bad_CareRelation
        WHERE careId = :careId
        LIMIT 1
    ");
    $find->execute([':careId' => $careId]);
    $row = $find->fetch();

    if (!$row) {
        badResponse(404, '呵护关系不存在');
    }
    if (intval($row['requesterUserId']) !== $userId) {
        badResponse(403, 'PermissionDenied');
    }
    if (intval($row['status']) === 1) {
        badResponse(409, '呵护关系已经建立');
    }
    if (intval($row['status']) === 0) {
        badResponse(409, '呵护申请已发送，请等待对方确认');
    }

    $stmt = $pdo->prepare("
        UPDATE bad_CareRelation
           SET permissionLevel = :permissionLevel,
               status = 0,
               rejectReason = NULL
         WHERE careId = :careId
         LIMIT 1
    ");
    $stmt->execute([
        ':permissionLevel' => $permissionLevel,
        ':careId' => $careId
    ]);

    badResponse(200, 'CareRequestSent', [
        'data' => [
            'careId' => $careId,
            'permissionLevel' => $permissionLevel,
            'permissionName' => badCarePermissionName($permissionLevel)
        ]
    ]);
} catch (PDOException $e) {
    badResponse(500, 'DataError: ' . $e->getMessage());
}
?>
