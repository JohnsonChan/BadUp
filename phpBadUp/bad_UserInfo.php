<?php
// 用户信息查询接口。
// 查看自己时直接返回；查看守护对象时必须已有可查看权限。
require_once "bad_Common.php";
require_once "bad_Database.php";

$data = badGetRequestData();
badRequireFields($data, ['userId']);

try {
    $pdo = Database::getPdoInstance();
    $userId = intval($data['userId']);
    $subjectUserId = isset($data['subjectUserId']) && $data['subjectUserId'] !== '' ? intval($data['subjectUserId']) : $userId;

    badRequireCanViewSubject($pdo, $userId, $subjectUserId);

    $stmt = $pdo->prepare("
        SELECT userId, userCode, userName, avatar, platform, appVersion, createdAt
        FROM bad_User
        WHERE userId = :subjectUserId
        LIMIT 1
    ");
    $stmt->execute([':subjectUserId' => $subjectUserId]);
    $user = $stmt->fetch();

    if (!$user) {
        badResponse(404, 'UserNotFound');
    }

    badResponse(200, 'OK', ['data' => $user]);
} catch (PDOException $e) {
    badResponse(500, 'DataError: ' . $e->getMessage());
}
?>
