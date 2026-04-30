<?php
require_once "bad_Common.php";
require_once "bad_Database.php";

$data = badGetRequestData();
$userId = isset($data['userId']) && $data['userId'] !== '' ? intval($data['userId']) : null;

try {
    $pdo = Database::getPdoInstance();

    if ($userId) {
        $sql = "
            SELECT *
            FROM bad_Behavior
            WHERE userId IS NULL OR userId = :userId
            ORDER BY sortOrder ASC, behaviorId ASC
        ";
        $stmt = $pdo->prepare($sql);
        $stmt->execute([':userId' => $userId]);
    } else {
        $sql = "
            SELECT *
            FROM bad_Behavior
            WHERE userId IS NULL
            ORDER BY sortOrder ASC, behaviorId ASC
        ";
        $stmt = $pdo->query($sql);
    }

    badResponse(200, 'OK', ['list' => $stmt->fetchAll()]);
} catch (PDOException $e) {
    badResponse(500, 'DataError: ' . $e->getMessage());
}
?>
