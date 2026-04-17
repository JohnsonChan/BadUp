<?php
require_once "bad_Common.php";
require_once "bad_Database.php";

$data = badGetRequestData();
badRequireFields($data, ['behaviorId', 'year', 'month']);

try {
    $pdo = Database::getPdoInstance();
    $stmt = $pdo->prepare("
        SELECT DAY(recordDate) AS dayNum, IFNULL(SUM(countNum), 0) AS totalCount
        FROM bad_BehaviorRecord
        WHERE behaviorId = :behaviorId
          AND YEAR(recordDate) = :year
          AND MONTH(recordDate) = :month
        GROUP BY DAY(recordDate)
        ORDER BY dayNum ASC
    ");
    $stmt->execute([
        ':behaviorId' => intval($data['behaviorId']),
        ':year' => intval($data['year']),
        ':month' => intval($data['month'])
    ]);

    badResponse(200, 'OK', ['list' => $stmt->fetchAll()]);
} catch (PDOException $e) {
    badResponse(500, 'DataError: ' . $e->getMessage());
}
?>
