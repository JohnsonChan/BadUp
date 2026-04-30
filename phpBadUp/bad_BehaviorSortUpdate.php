<?php
require_once "bad_Common.php";
require_once "bad_Database.php";

$data = badGetRequestData();
badRequireFields($data, ['userId', 'behaviorIds']);

$userId = intval($data['userId']);
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
    $pdo->beginTransaction();

    // 只更新当前用户自己的行为，避免用户调整系统共享行为或其它用户的数据。
    $stmt = $pdo->prepare("
        UPDATE bad_Behavior
           SET sortOrder = :sortOrder
         WHERE behaviorId = :behaviorId
           AND userId = :userId
         LIMIT 1
    ");

    $updated = 0;
    foreach ($cleanIds as $index => $behaviorId) {
        $stmt->execute([
            ':sortOrder' => ($index + 1) * 10,
            ':behaviorId' => $behaviorId,
            ':userId' => $userId
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
