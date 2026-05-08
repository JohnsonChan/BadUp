<?php
// 更新呵护关系备注：呵护者维护 guardianRemark，被呵护者维护 caredRemark。
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
        $field = 'guardianRemark';
    } else if (intval($row['caredUserId']) === $userId) {
        $field = 'caredRemark';
    } else {
        badResponse(403, 'PermissionDenied');
    }

    $stmt = $pdo->prepare("UPDATE bad_CareRelation SET $field = :remark WHERE careId = :careId LIMIT 1");
    $stmt->execute([
        ':remark' => $remark,
        ':careId' => $careId
    ]);

    badResponse(200, 'RemarkUpdated');
} catch (PDOException $e) {
    badResponse(500, 'DataError: ' . $e->getMessage());
}
?>
