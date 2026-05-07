<?php
// 删除单条习惯记录。
// 只删除 bad_BehaviorRecord 的一行，不删除习惯项本身。
require_once "bad_Common.php";
require_once "bad_Database.php";

$data = badGetRequestData();
badRequireFields($data, ['userId', 'recordId']);

try {
    $pdo = Database::getPdoInstance();
    $userId = intval($data['userId']);
    $recordId = intval($data['recordId']);

    $find = $pdo->prepare("
        SELECT recordId
        FROM bad_BehaviorRecord
        WHERE recordId = :recordId
          AND userId = :userId
        LIMIT 1
    ");
    $find->execute([
        ':recordId' => $recordId,
        ':userId' => $userId
    ]);

    if (!$find->fetch()) {
        badResponse(404, 'RecordNotFound');
    }

    $delete = $pdo->prepare("
        DELETE FROM bad_BehaviorRecord
        WHERE recordId = :recordId
          AND userId = :userId
        LIMIT 1
    ");
    $delete->execute([
        ':recordId' => $recordId,
        ':userId' => $userId
    ]);

    badResponse(200, 'DeleteSuccess');
} catch (PDOException $e) {
    badResponse(500, 'DataError: ' . $e->getMessage());
}
?>
