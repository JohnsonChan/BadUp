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

    // 只允许有管理权限的人删除该用户的习惯，避免误删系统共享习惯或其它用户数据。
    $subjectUserId = badBehaviorSubjectUserId($behavior);
    if (!badCanManageSubject($pdo, $userId, $subjectUserId)) {
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
