<?php
require_once "bad_Common.php";
require_once "bad_Database.php";

$data = badGetRequestData();

if (empty($data['deviceId']) && empty($data['phone']) && empty($data['userCode'])) {
    badResponse(400, 'NoLoginKey');
}

try {
    $pdo = Database::getPdoInstance();

    $conditions = [];
    $params = [];

    if (!empty($data['deviceId'])) {
        $conditions[] = 'deviceId = :deviceId';
        $params[':deviceId'] = trim($data['deviceId']);
    }
    if (!empty($data['phone'])) {
        $conditions[] = 'phone = :phone';
        $params[':phone'] = trim($data['phone']);
    }
    if (!empty($data['userCode'])) {
        $conditions[] = 'userCode = :userCode';
        $params[':userCode'] = trim($data['userCode']);
    }

    $sql = "SELECT * FROM bad_User WHERE " . implode(' OR ', $conditions) . " LIMIT 1";
    $stmt = $pdo->prepare($sql);
    $stmt->execute($params);
    $user = $stmt->fetch();

    if ($user) {
        $update = $pdo->prepare("
            UPDATE bad_User
            SET ip = :ip,
                appVersion = :appVersion,
                systemVersion = :systemVersion,
                updatedAt = NOW()
            WHERE userId = :userId
        ");
        $update->execute([
            ':ip' => badGetIp(),
            ':appVersion' => isset($data['appVersion']) ? $data['appVersion'] : null,
            ':systemVersion' => isset($data['systemVersion']) ? $data['systemVersion'] : null,
            ':userId' => $user['userId']
        ]);

        $stmt = $pdo->prepare("SELECT * FROM bad_User WHERE userId = :userId LIMIT 1");
        $stmt->execute([':userId' => $user['userId']]);
        badResponse(200, 'logOk', ['data' => $stmt->fetch()]);
    }

    $createdAt = date('Y-m-d H:i:s');
    $insert = $pdo->prepare("
        INSERT INTO bad_User
        (userCode, userName, phone, email, password, avatar, deviceId, platform, appVersion, systemVersion, ip, status, createdAt)
        VALUES
        (:userCode, :userName, :phone, :email, :password, :avatar, :deviceId, :platform, :appVersion, :systemVersion, :ip, :status, :createdAt)
    ");

    $userCode = !empty($data['userCode']) ? trim($data['userCode']) : ('U' . date('YmdHis') . rand(100, 999));
    $insert->execute([
        ':userCode' => $userCode,
        ':userName' => isset($data['userName']) ? trim($data['userName']) : null,
        ':phone' => isset($data['phone']) ? trim($data['phone']) : null,
        ':email' => isset($data['email']) ? trim($data['email']) : null,
        ':password' => isset($data['password']) ? trim($data['password']) : null,
        ':avatar' => isset($data['avatar']) ? trim($data['avatar']) : null,
        ':deviceId' => isset($data['deviceId']) ? trim($data['deviceId']) : null,
        ':platform' => isset($data['platform']) ? trim($data['platform']) : 'iOS',
        ':appVersion' => isset($data['appVersion']) ? trim($data['appVersion']) : null,
        ':systemVersion' => isset($data['systemVersion']) ? trim($data['systemVersion']) : null,
        ':ip' => badGetIp(),
        ':status' => 1,
        ':createdAt' => $createdAt
    ]);

    $userId = $pdo->lastInsertId();
    $stmt = $pdo->prepare("SELECT * FROM bad_User WHERE userId = :userId LIMIT 1");
    $stmt->execute([':userId' => $userId]);
    badResponse(200, 'regOk', ['data' => $stmt->fetch()]);
} catch (PDOException $e) {
    badResponse(500, 'DataError: ' . $e->getMessage());
}
?>
