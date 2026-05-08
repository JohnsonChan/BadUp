<?php
require_once "bad_Common.php";
require_once "bad_Database.php";

$data = badGetRequestData();
$userId = isset($data['userId']) && $data['userId'] !== '' ? intval($data['userId']) : null;
$subjectUserId = isset($data['subjectUserId']) && $data['subjectUserId'] !== '' ? intval($data['subjectUserId']) : $userId;

try {
    $pdo = Database::getPdoInstance();
    badRequireCanViewSubject($pdo, $userId, $subjectUserId);

    if ($subjectUserId) {
        $sql = "
            SELECT *
            FROM bad_Behavior
            WHERE userId IS NULL OR COALESCE(subjectUserId, userId) = :subjectUserId
            ORDER BY sortOrder ASC, behaviorId ASC
        ";
        $stmt = $pdo->prepare($sql);
        $stmt->execute([':subjectUserId' => $subjectUserId]);
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
