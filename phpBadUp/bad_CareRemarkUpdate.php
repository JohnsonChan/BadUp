<?php
// 更新守护备注：备注属于“当前用户给对方的昵称”，双向守护时两条方向关系同步更新。
require_once "bad_Common.php";
require_once "bad_Database.php";

$data = badGetRequestData();
badRequireFields($data, ['userId', 'careId']);

try {
    $pdo = Database::getPdoInstance();
    $userId = intval($data['userId']);
    $careId = intval($data['careId']);
    $remark = isset($data['remark']) ? trim($data['remark']) : '';

    $find = $pdo->prepare("
        SELECT guardianUserId, caredUserId
        FROM bad_CareRelation
        WHERE careId = :careId
          AND status = 1
        LIMIT 1
    ");
    $find->execute([':careId' => $careId]);
    $row = $find->fetch();

    if (!$row) {
        badResponse(404, '呵护关系不存在');
    }

    if (intval($row['guardianUserId']) === $userId) {
        $otherUserId = intval($row['caredUserId']);
    } else if (intval($row['caredUserId']) === $userId) {
        $otherUserId = intval($row['guardianUserId']);
    } else {
        badResponse(403, 'PermissionDenied');
    }

    $asGuardian = $pdo->prepare("
        UPDATE bad_CareRelation
           SET guardianRemark = :remark
         WHERE guardianUserId = :userId
           AND caredUserId = :otherUserId
    ");
    $asGuardian->execute([
        ':remark' => $remark,
        ':userId' => $userId,
        ':otherUserId' => $otherUserId
    ]);

    $asCared = $pdo->prepare("
        UPDATE bad_CareRelation
           SET caredRemark = :remark
         WHERE guardianUserId = :otherUserId
           AND caredUserId = :userId
    ");
    $asCared->execute([
        ':remark' => $remark,
        ':userId' => $userId,
        ':otherUserId' => $otherUserId
    ]);

    badResponse(200, 'RemarkUpdated');
} catch (PDOException $e) {
    badResponse(500, 'DataError: ' . $e->getMessage());
}
?>
