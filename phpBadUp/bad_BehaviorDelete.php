<?php
require_once "bad_Common.php";
require_once "bad_Database.php";

$data = badGetRequestData();
badRequireFields($data, ['behaviorId']);

try {
    $pdo = Database::getPdoInstance();
    $pdo->beginTransaction();

    $find = $pdo->prepare("SELECT * FROM bad_Behavior WHERE behaviorId = :behaviorId LIMIT 1");
    $find->execute([':behaviorId' => intval($data['behaviorId'])]);
    $behavior = $find->fetch();

    if (!$behavior) {
        $pdo->rollBack();
        badResponse(404, 'BehaviorNotFound');
    }

    if (isset($data['userId']) && $data['userId'] !== '' && $behavior['userId'] !== null && intval($behavior['userId']) !== intval($data['userId'])) {
        $pdo->rollBack();
        badResponse(403, 'PermissionDenied');
    }

    $deleteRecord = $pdo->prepare("DELETE FROM bad_BehaviorRecord WHERE behaviorId = :behaviorId");
    $deleteRecord->execute([':behaviorId' => intval($data['behaviorId'])]);

    $deleteBehavior = $pdo->prepare("UPDATE bad_Behavior SET isActive = 0 WHERE behaviorId = :behaviorId LIMIT 1");
    $deleteBehavior->execute([':behaviorId' => intval($data['behaviorId'])]);

    $pdo->commit();
    badResponse(200, 'DeleteSuccess');
} catch (PDOException $e) {
    if ($pdo->inTransaction()) {
        $pdo->rollBack();
    }
    badResponse(500, 'DataError: ' . $e->getMessage());
}
?>
