<?php
// 用户自动登录/注册接口。
// 小程序通过 wx.login code 换 openId 登录；iOS 继续通过 Keychain deviceId 登录。
require_once "bad_Common.php";
require_once "bad_Database.php";

$data = badGetRequestData();

if (empty($data['loginCode']) && empty($data['deviceId']) && empty($data['phone']) && empty($data['userCode'])) {
    badResponse(400, 'NoLoginKey');
}

// 读取微信配置。AppId 可以公开，AppSecret 只能放在服务端。
function badGetWechatConfigValue($constantName, $envName, $defaultValue) {
    if (defined($constantName)) {
        return trim((string)constant($constantName));
    }

    $envValue = getenv($envName);
    if ($envValue !== false && $envValue !== '') {
        return trim((string)$envValue);
    }

    return trim((string)$defaultValue);
}

function badEnsureWechatConfigLoaded() {
    $configPath = dirname(__FILE__) . '/bad_WechatConfig.php';
    if (file_exists($configPath)) {
        require_once $configPath;
    }
}

function badHttpGet($url) {
    if (function_exists('curl_init')) {
        $ch = curl_init();
        curl_setopt($ch, CURLOPT_URL, $url);
        curl_setopt($ch, CURLOPT_RETURNTRANSFER, true);
        curl_setopt($ch, CURLOPT_CONNECTTIMEOUT, 8);
        curl_setopt($ch, CURLOPT_TIMEOUT, 12);
        curl_setopt($ch, CURLOPT_SSL_VERIFYPEER, true);
        curl_setopt($ch, CURLOPT_SSL_VERIFYHOST, 2);
        $response = curl_exec($ch);
        $errorNo = curl_errno($ch);
        curl_close($ch);
        if ($errorNo === 0 && $response !== false) {
            return $response;
        }
    }

    if (ini_get('allow_url_fopen')) {
        return @file_get_contents($url);
    }

    return false;
}

function badGetWechatOpenId($loginCode) {
    $loginCode = trim((string)$loginCode);
    if ($loginCode === '') {
        return '';
    }

    badEnsureWechatConfigLoaded();

    $appId = badGetWechatConfigValue('BAD_WECHAT_APP_ID', 'BAD_WECHAT_APP_ID', 'wx2321df4ab9559638');
    $appSecret = badGetWechatConfigValue('BAD_WECHAT_APP_SECRET', 'BAD_WECHAT_APP_SECRET', '');

    if ($appId === '' || $appSecret === '') {
        badResponse(500, 'WeChatConfigMissing');
    }

    $url = 'https://api.weixin.qq.com/sns/jscode2session'
        . '?appid=' . rawurlencode($appId)
        . '&secret=' . rawurlencode($appSecret)
        . '&js_code=' . rawurlencode($loginCode)
        . '&grant_type=authorization_code';

    $responseText = badHttpGet($url);
    if ($responseText === false || $responseText === '') {
        badResponse(502, 'WeChatLoginRequestFailed');
    }

    $response = json_decode($responseText, true);
    if (!is_array($response)) {
        badResponse(502, 'WeChatLoginInvalidResponse');
    }

    if (!empty($response['errcode'])) {
        $errorMessage = isset($response['errmsg']) ? $response['errmsg'] : '';
        badResponse(400, 'WeChatLoginFailed: ' . $response['errcode'] . ' ' . $errorMessage);
    }

    if (empty($response['openid'])) {
        badResponse(502, 'WeChatOpenIdMissing');
    }

    return trim((string)$response['openid']);
}

// 确保新用户有默认习惯项。
// 改为真实删除习惯后，只在注册时调用，避免用户删完习惯后下次登录又被自动恢复。
// 小程序和 iOS 使用不同的默认项，方便分别迭代。
function badEnsureDefaultBehaviors($pdo, $userId, $platform) {
    $count = $pdo->prepare("SELECT COUNT(*) FROM bad_Behavior WHERE userId = :userId");
    $count->execute([':userId' => $userId]);
    if (intval($count->fetchColumn()) > 0) {
        return;
    }

    $createdAt = date('Y-m-d H:i:s');
    $platform = trim((string)$platform);

    $defaults = [
            ['运动', '身体舒展了，心情自然就顺了', '#43C77A', 1, 1, 10],
            ['学习', '悄悄努力，静待自己慢慢蜕变', '#31B3C5', 1, 1, 20],
            ['熬夜', '放下执念早睡，也是一种通透', '#6C7EF7', -1, -2, 30]
        ];

    $insert = $pdo->prepare("
        INSERT INTO bad_Behavior
        (userId, creatorUserId, subjectUserId, behaviorName, behaviorDesc, colorHex, behaviorType, scoreUnit, sortOrder, createdAt)
        VALUES
        (:userId, :creatorUserId, :subjectUserId, :behaviorName, :behaviorDesc, :colorHex, :behaviorType, :scoreUnit, :sortOrder, :createdAt)
    ");

    foreach ($defaults as $item) {
        $insert->execute([
            ':userId' => $userId,
            ':creatorUserId' => $userId,
            ':subjectUserId' => $userId,
            ':behaviorName' => $item[0],
            ':behaviorDesc' => $item[1],
            ':colorHex' => $item[2],
            ':behaviorType' => badNormalizeBehaviorType($item[3]),
            ':scoreUnit' => badNormalizeScoreUnit($item[4], $item[3]),
            ':sortOrder' => $item[5],
            ':createdAt' => $createdAt
        ]);
    }
}

try {
    $pdo = Database::getPdoInstance();
    $wechatOpenId = !empty($data['loginCode']) ? badGetWechatOpenId($data['loginCode']) : '';
    $deviceId = !empty($data['deviceId']) ? trim($data['deviceId']) : '';

    $user = null;

    // 小程序优先按 openId 查找，这是删除重装后仍稳定的用户标识。
    if ($wechatOpenId !== '') {
        $stmt = $pdo->prepare("SELECT * FROM bad_User WHERE openId = :openId LIMIT 1");
        $stmt->execute([':openId' => $wechatOpenId]);
        $user = $stmt->fetch();
    } else {
        // iOS 或旧接口仍允许用 deviceId、phone、userCode 登录。
        $conditions = [];
        $params = [];

        if ($deviceId !== '') {
            $conditions[] = 'deviceId = :deviceId';
            $params[':deviceId'] = $deviceId;
        }
        if (!empty($data['phone'])) {
            $conditions[] = 'phone = :phone';
            $params[':phone'] = trim($data['phone']);
        }
        if (!empty($data['userCode'])) {
            $conditions[] = 'userCode = :userCode';
            $params[':userCode'] = trim($data['userCode']);
        }

        if (count($conditions) > 0) {
            $sql = "SELECT * FROM bad_User WHERE " . implode(' OR ', $conditions) . " LIMIT 1";
            $stmt = $pdo->prepare($sql);
            $stmt->execute($params);
            $user = $stmt->fetch();
        }
    }

    if ($user) {
        // 老用户登录时刷新最近登录信息。
        $updateFields = [
            'ip = :ip',
            'appVersion = :appVersion',
            'systemVersion = :systemVersion',
            'updatedAt = NOW()'
        ];
        $updateParams = [
            ':ip' => badGetIp(),
            ':appVersion' => isset($data['appVersion']) ? $data['appVersion'] : null,
            ':systemVersion' => isset($data['systemVersion']) ? $data['systemVersion'] : null,
            ':userId' => $user['userId']
        ];

        if ($deviceId !== '' && (empty($user['deviceId']))) {
            $updateFields[] = 'deviceId = :deviceId';
            $updateParams[':deviceId'] = $deviceId;
        }

        $update = $pdo->prepare("
            UPDATE bad_User
            SET " . implode(",\n                ", $updateFields) . "
            WHERE userId = :userId
        ");
        $update->execute($updateParams);

        $stmt = $pdo->prepare("SELECT * FROM bad_User WHERE userId = :userId LIMIT 1");
        $stmt->execute([':userId' => $user['userId']]);
        badResponse(200, 'logOk', ['data' => badAttachCareCode($stmt->fetch())]);
    }

    $createdAt = date('Y-m-d H:i:s');
    // 没找到用户时自动注册。
    $insert = $pdo->prepare("
        INSERT INTO bad_User
        (userCode, userName, phone, email, password, avatar, openId, deviceId, platform, appVersion, systemVersion, ip, status, createdAt)
        VALUES
        (:userCode, :userName, :phone, :email, :password, :avatar, :openId, :deviceId, :platform, :appVersion, :systemVersion, :ip, :status, :createdAt)
    ");

    $userCode = !empty($data['userCode']) ? trim($data['userCode']) : ('U' . date('YmdHis') . rand(100, 999));
    $insert->execute([
        ':userCode' => $userCode,
        ':userName' => isset($data['userName']) ? trim($data['userName']) : null,
        ':phone' => isset($data['phone']) ? trim($data['phone']) : null,
        ':email' => isset($data['email']) ? trim($data['email']) : null,
        ':password' => isset($data['password']) ? trim($data['password']) : null,
        ':avatar' => isset($data['avatar']) ? trim($data['avatar']) : null,
        ':openId' => $wechatOpenId !== '' ? $wechatOpenId : null,
        ':deviceId' => $deviceId !== '' ? $deviceId : null,
        ':platform' => isset($data['platform']) ? trim($data['platform']) : 'iOS',
        ':appVersion' => isset($data['appVersion']) ? trim($data['appVersion']) : null,
        ':systemVersion' => isset($data['systemVersion']) ? trim($data['systemVersion']) : null,
        ':ip' => badGetIp(),
        ':status' => 1,
        ':createdAt' => $createdAt
    ]);

    $userId = $pdo->lastInsertId();
    badEnsureDefaultBehaviors(
        $pdo,
        $userId,
        isset($data['platform']) ? $data['platform'] : ''
    );
    $stmt = $pdo->prepare("SELECT * FROM bad_User WHERE userId = :userId LIMIT 1");
    $stmt->execute([':userId' => $userId]);
    badResponse(200, 'regOk', ['data' => badAttachCareCode($stmt->fetch())]);
} catch (PDOException $e) {
    badResponse(500, 'DataError: ' . $e->getMessage());
}
?>
