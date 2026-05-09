<?php
// 删除单条呵护关系。
// 只有创建者/发起方可以删除；双向呵护时只删除当前这一条方向，不影响反向关系。
require_once "bad_Common.php";
require_once "bad_Database.php";

$data = badGetRequestData();
badRequireFields($data, ['userId', 'careId']);

try {
    $pdo = Database::getPdoInstance();
    $userId = intval($data['userId']);
    $careId = intval($data['careId']);

    $find = $pdo->prepare("
        SELECT careId, guardianUserId, caredUserId, requesterUserId
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

    $delete = $pdo->prepare("
        DELETE FROM bad_CareRelation
        WHERE careId = :careId
        LIMIT 1
    ");
    $delete->execute([':careId' => $careId]);

    badResponse(200, 'CareDeleted');
} catch (PDOException $e) {
    badResponse(500, 'DataError: ' . $e->getMessage());
}
?>
