<?php
// 用户习惯分汇总接口。
// 好习惯每次 +1，坏习惯每次 -10；分数在写入记录时固化到 scoreValue。
require_once "bad_Common.php";
require_once "bad_Database.php";

$data = badGetRequestData();
badRequireFields($data, ['userId']);

try {
    $pdo = Database::getPdoInstance();
    $userId = intval($data['userId']);

    $stmt = $pdo->prepare("
        SELECT IFNULL(SUM(scoreValue), 0) AS behaviorScore,
               IFNULL(SUM(countNum), 0) AS totalCount
        FROM bad_BehaviorRecord
        WHERE userId = :userId
    ");
    $stmt->execute([':userId' => $userId]);
    $row = $stmt->fetch();

    badResponse(200, 'OK', [
        'data' => [
            'behaviorScore' => isset($row['behaviorScore']) ? intval($row['behaviorScore']) : 0,
            'totalCount' => isset($row['totalCount']) ? intval($row['totalCount']) : 0
        ]
    ]);
} catch (PDOException $e) {
    badResponse(500, 'DataError: ' . $e->getMessage());
}
?>
