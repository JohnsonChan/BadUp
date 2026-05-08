<?php
// 修改呵护关系权限。
// 只有发起呵护申请的人可以修改权限，并且只允许修改已经同意的关系。
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
    if (intval($row['status']) !== 1) {
        badResponse(409, '呵护关系还未建立，暂不能修改权限');
    }
    if (intval($row['requesterUserId']) !== $userId) {
        badResponse(403, 'PermissionDenied');
    }

    $stmt = $pdo->prepare("
        UPDATE bad_CareRelation
           SET permissionLevel = :permissionLevel
         WHERE careId = :careId
         LIMIT 1
    ");
    $stmt->execute([
        ':permissionLevel' => $permissionLevel,
        ':careId' => $careId
    ]);

    badResponse(200, 'PermissionUpdated', [
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
