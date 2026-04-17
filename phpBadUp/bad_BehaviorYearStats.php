<?php
require_once "bad_Common.php";
require_once "bad_Database.php";

$data = badGetRequestData();
badRequireFields($data, ['behaviorId', 'year']);

try {
    $pdo = Database::getPdoInstance();
    $stmt = $pdo->prepare("
        SELECT MONTH(recordDate) AS monthNum, IFNULL(SUM(countNum), 0) AS totalCount
        FROM bad_BehaviorRecord
        WHERE behaviorId = :behaviorId
          AND YEAR(recordDate) = :year
        GROUP BY MONTH(recordDate)
        ORDER BY monthNum ASC
    ");
    $stmt->execute([
        ':behaviorId' => intval($data['behaviorId']),
        ':year' => intval($data['year'])
    ]);

    badResponse(200, 'OK', ['list' => $stmt->fetchAll()]);
} catch (PDOException $e) {
    badResponse(500, 'DataError: ' . $e->getMessage());
}
?>
