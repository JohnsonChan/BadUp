<?php
// 处理呵护申请：只有被输入呵护码的一方，也就是呵护者，可以通过或拒绝。
require_once "bad_Common.php";
require_once "bad_Database.php";

$data = badGetRequestData();
badRequireFields($data, ['userId', 'careId', 'action']);

try {
    $pdo = Database::getPdoInstance();
    $userId = intval($data['userId']);
    $careId = intval($data['careId']);
    $action = trim($data['action']);
    $nextStatus = $action === 'accept' ? 1 : 2;
    $rejectReason = isset($data['rejectReason']) ? trim($data['rejectReason']) : '';

    if ($nextStatus === 2 && $rejectReason === '') {
        badResponse(400, '拒绝时需要填写原因');
    }

    $find = $pdo->prepare("
        SELECT *
        FROM bad_CareRelation
        WHERE careId = :careId
          AND status = 0
          AND guardianUserId = :userId
        LIMIT 1
    ");
    $find->execute([
        ':careId' => $careId,
        ':userId' => $userId
    ]);
    $row = $find->fetch();

    if (!$row) {
        badResponse(404, '呵护申请不存在或已处理');
    }
    if (intval($row['requesterUserId']) === $userId) {
        badResponse(403, '不能确认自己发起的申请');
    }

    $stmt = $pdo->prepare("
        UPDATE bad_CareRelation
           SET status = :status,
               rejectReason = :rejectReason
         WHERE careId = :careId
         LIMIT 1
    ");
    $stmt->execute([
        ':status' => $nextStatus,
        ':rejectReason' => $nextStatus === 2 ? $rejectReason : null,
        ':careId' => $careId
    ]);

    badResponse(200, $nextStatus === 1 ? 'CareAccepted' : 'CareRejected');
} catch (PDOException $e) {
    badResponse(500, 'DataError: ' . $e->getMessage());
}
?>
