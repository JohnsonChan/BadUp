<?php
// 用户自动登录/注册接口。
// iOS 启动页会把 Keychain 里的 deviceId 发过来；服务端按 deviceId 找用户，找不到就创建。
require_once "bad_Common.php";
require_once "bad_Database.php";

$data = badGetRequestData();

if (empty($data['deviceId']) && empty($data['phone']) && empty($data['userCode'])) {
    badResponse(400, 'NoLoginKey');
}

// 确保新用户或旧空用户有默认行为项。
// 只在该 userId 没有任何行为项时初始化，避免用户删除后下次登录又被自动恢复。
function badEnsureDefaultBehaviors($pdo, $userId) {
    $count = $pdo->prepare("SELECT COUNT(*) FROM bad_Behavior WHERE userId = :userId");
    $count->execute([':userId' => $userId]);
    if (intval($count->fetchColumn()) > 0) {
        return;
    }

    $createdAt = date('Y-m-d H:i:s');
    $defaults = [
        ['撸管', '记录一次没忍住', '#F55F52', 10],
        ['刷视频', '记录一次沉迷短视频', '#31B3C5', 20],
        ['熬夜', '记录一次睡太晚', '#6C7EF7', 30],
        ['吃太饱', '记录一次吃撑了', '#F9B536', 40]
    ];

    $insert = $pdo->prepare("
        INSERT INTO bad_Behavior
        (userId, behaviorName, behaviorDesc, colorHex, sortOrder, isActive, createdAt)
        VALUES
        (:userId, :behaviorName, :behaviorDesc, :colorHex, :sortOrder, 1, :createdAt)
    ");

    foreach ($defaults as $item) {
        $insert->execute([
            ':userId' => $userId,
            ':behaviorName' => $item[0],
            ':behaviorDesc' => $item[1],
            ':colorHex' => $item[2],
            ':sortOrder' => $item[3],
            ':createdAt' => $createdAt
        ]);
    }
}

try {
    $pdo = Database::getPdoInstance();

    // 允许用 deviceId、phone、userCode 三种方式匹配已有用户。
    // 当前 iOS 端只传 deviceId，其它字段预留给后续账号体系。
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
        // 老用户登录时刷新最近登录信息。
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
        badEnsureDefaultBehaviors($pdo, $user['userId']);
        badResponse(200, 'logOk', ['data' => $stmt->fetch()]);
    }

    $createdAt = date('Y-m-d H:i:s');
    // 没找到用户时自动注册。
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
    badEnsureDefaultBehaviors($pdo, $userId);
    $stmt = $pdo->prepare("SELECT * FROM bad_User WHERE userId = :userId LIMIT 1");
    $stmt->execute([':userId' => $userId]);
    badResponse(200, 'regOk', ['data' => $stmt->fetch()]);
} catch (PDOException $e) {
    badResponse(500, 'DataError: ' . $e->getMessage());
}
?>
