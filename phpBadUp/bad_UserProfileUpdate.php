<?php
// 用户资料更新接口。
// 小程序首次登录后，用户主动确认获取微信昵称和头像，再调用这里保存。
require_once "bad_Common.php";
require_once "bad_Database.php";

$data = badGetRequestData();
badRequireFields($data, ['userId']);

function badCleanProfileText($value, $maxLength) {
    $text = trim((string)$value);
    // 当前数据库是 utf8，不能保存 4 字节 emoji；这里移除，避免昵称导致写库失败。
    $text = preg_replace('/[\x{10000}-\x{10FFFF}]/u', '', $text);
    if (function_exists('mb_substr')) {
        return mb_substr($text, 0, $maxLength, 'UTF-8');
    }
    return substr($text, 0, $maxLength);
}

try {
    $pdo = Database::getPdoInstance();
    $userId = intval($data['userId']);
    $userName = isset($data['userName']) ? badCleanProfileText($data['userName'], 64) : '';
    $avatar = isset($data['avatar']) ? badCleanProfileText($data['avatar'], 255) : '';

    $updateFields = [];
    $updateParams = [':userId' => $userId];

    if ($userName !== '') {
        $updateFields[] = 'userName = :userName';
        $updateParams[':userName'] = $userName;
    }

    if ($avatar !== '') {
        $updateFields[] = 'avatar = :avatar';
        $updateParams[':avatar'] = $avatar;
    }

    if (count($updateFields) === 0) {
        badResponse(400, 'NoProfileData');
    }

    $updateFields[] = 'updatedAt = NOW()';

    $stmt = $pdo->prepare("
        UPDATE bad_User
        SET " . implode(",\n            ", $updateFields) . "
        WHERE userId = :userId
    ");
    $stmt->execute($updateParams);

    $query = $pdo->prepare("SELECT * FROM bad_User WHERE userId = :userId LIMIT 1");
    $query->execute([':userId' => $userId]);
    $user = $query->fetch();
    if (!$user) {
        badResponse(404, 'UserNotFound');
    }

    badResponse(200, 'OK', ['data' => badAttachCareCode($user)]);
} catch (PDOException $e) {
    badResponse(500, 'DataError: ' . $e->getMessage());
}
?>
