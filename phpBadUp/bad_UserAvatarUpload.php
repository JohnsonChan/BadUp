<?php
// 用户头像上传接口。
// 小程序 chooseAvatar 返回的是临时文件路径，必须上传到服务端后才能长期展示。
require_once "bad_Common.php";
require_once "bad_Database.php";

if (empty($_POST['userId'])) {
    badResponse(400, 'MissingField', ['field' => 'userId']);
}

if (empty($_FILES['avatar']) || !isset($_FILES['avatar']['tmp_name'])) {
    badResponse(400, 'NoAvatarFile');
}

$userId = intval($_POST['userId']);
$file = $_FILES['avatar'];

if (!empty($file['error'])) {
    badResponse(400, 'AvatarUploadError: ' . intval($file['error']));
}

if (empty($file['tmp_name']) || !is_uploaded_file($file['tmp_name'])) {
    badResponse(400, 'InvalidAvatarFile');
}

if (!empty($file['size']) && intval($file['size']) > 3 * 1024 * 1024) {
    badResponse(400, 'AvatarTooLarge');
}

$imageInfo = @getimagesize($file['tmp_name']);
if (!$imageInfo || empty($imageInfo['mime'])) {
    badResponse(400, 'InvalidAvatarImage');
}

$mime = strtolower($imageInfo['mime']);
$ext = '';
if ($mime === 'image/jpeg') {
    $ext = 'jpg';
} else if ($mime === 'image/png') {
    $ext = 'png';
} else if ($mime === 'image/gif') {
    $ext = 'gif';
} else if ($mime === 'image/webp') {
    $ext = 'webp';
} else {
    badResponse(400, 'UnsupportedAvatarType');
}

try {
    $pdo = Database::getPdoInstance();
    $query = $pdo->prepare("SELECT userId FROM bad_User WHERE userId = :userId LIMIT 1");
    $query->execute([':userId' => $userId]);
    if (!$query->fetch()) {
        badResponse(404, 'UserNotFound');
    }

    $uploadDir = dirname(__FILE__) . '/uploads/avatar';
    if (!is_dir($uploadDir)) {
        if (!mkdir($uploadDir, 0755, true)) {
            badResponse(500, 'AvatarDirCreateFailed');
        }
    }

    $fileName = 'avatar_' . $userId . '_' . date('YmdHis') . '_' . rand(1000, 9999) . '.' . $ext;
    $targetPath = $uploadDir . '/' . $fileName;

    if (!move_uploaded_file($file['tmp_name'], $targetPath)) {
        badResponse(500, 'AvatarMoveFailed');
    }

    $scheme = (!empty($_SERVER['HTTPS']) && $_SERVER['HTTPS'] !== 'off') ? 'https' : 'http';
    $host = isset($_SERVER['HTTP_HOST']) ? $_SERVER['HTTP_HOST'] : 'shouzhuan007.com';
    $scriptDir = str_replace('\\', '/', dirname($_SERVER['SCRIPT_NAME']));
    $scriptDir = rtrim($scriptDir, '/');
    $avatarUrl = $scheme . '://' . $host . $scriptDir . '/uploads/avatar/' . $fileName;

    badResponse(200, 'OK', [
        'data' => [
            'avatar' => $avatarUrl
        ]
    ]);
} catch (PDOException $e) {
    badResponse(500, 'DataError: ' . $e->getMessage());
}
?>
