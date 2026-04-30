<?php
require_once "bad_Common.php";
require_once "bad_Database.php";

$data = badGetRequestData();
badRequireFields($data, ['behaviorId', 'userId']);

try {
    $pdo = Database::getPdoInstance();
    $pdo->beginTransaction();

    $behaviorId = intval($data['behaviorId']);
    $userId = intval($data['userId']);

    $find = $pdo->prepare("SELECT * FROM bad_Behavior WHERE behaviorId = :behaviorId LIMIT 1");
    $find->execute([':behaviorId' => $behaviorId]);
    $behavior = $find->fetch();

    if (!$behavior) {
        $pdo->rollBack();
        badResponse(404, 'BehaviorNotFound');
    }

    // 只允许删除当前用户自己创建的行为，避免误删系统共享行为。
    if ($behavior['userId'] === null || intval($behavior['userId']) !== $userId) {
        $pdo->rollBack();
        badResponse(403, 'PermissionDenied');
    }

    $deleteRecord = $pdo->prepare("DELETE FROM bad_BehaviorRecord WHERE behaviorId = :behaviorId");
    $deleteRecord->execute([':behaviorId' => $behaviorId]);

    $deleteBehavior = $pdo->prepare("DELETE FROM bad_Behavior WHERE behaviorId = :behaviorId LIMIT 1");
    $deleteBehavior->execute([':behaviorId' => $behaviorId]);

    $pdo->commit();
    badResponse(200, 'DeleteSuccess');
} catch (PDOException $e) {
    if ($pdo->inTransaction()) {
        $pdo->rollBack();
    }
    badResponse(500, 'DataError: ' . $e->getMessage());
}
?>
