<?php
require_once "bad_Common.php";
require_once "bad_Database.php";

$data = badGetRequestData();
badRequireFields($data, ['userId', 'behaviorIds']);

$userId = intval($data['userId']);
$subjectUserId = isset($data['subjectUserId']) && $data['subjectUserId'] !== '' ? intval($data['subjectUserId']) : $userId;
$behaviorIds = $data['behaviorIds'];
if (!is_array($behaviorIds)) {
    $behaviorIds = explode(',', strval($behaviorIds));
}

$cleanIds = [];
$seen = [];
foreach ($behaviorIds as $behaviorId) {
    $id = intval($behaviorId);
    if ($id > 0 && !isset($seen[$id])) {
        $cleanIds[] = $id;
        $seen[$id] = true;
    }
}

if (count($cleanIds) === 0) {
    badResponse(400, 'NoBehaviorIds');
}

try {
    $pdo = Database::getPdoInstance();
    badRequireCanManageSubject($pdo, $userId, $subjectUserId);
    $pdo->beginTransaction();

    // 只更新当前作用用户的习惯，呵护者排序时也不会影响其它人的数据。
    $stmt = $pdo->prepare("
        UPDATE bad_Behavior
           SET sortOrder = :sortOrder
         WHERE behaviorId = :behaviorId
           AND userId = :subjectUserId
         LIMIT 1
    ");

    $updated = 0;
    foreach ($cleanIds as $index => $behaviorId) {
        $stmt->execute([
            ':sortOrder' => ($index + 1) * 10,
            ':behaviorId' => $behaviorId,
            ':subjectUserId' => $subjectUserId
        ]);
        $updated += $stmt->rowCount();
    }

    $pdo->commit();
    badResponse(200, 'SortUpdateSuccess', ['updated' => $updated]);
} catch (PDOException $e) {
    if ($pdo->inTransaction()) {
        $pdo->rollBack();
    }
    badResponse(500, 'DataError: ' . $e->getMessage());
}
?>
