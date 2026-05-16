<?php
// PHP 接口公共方法。
// 所有接口都 require 这个文件，保证请求读取、JSON 输出、字段校验风格一致。
header('Content-Type: application/json; charset=utf-8');

// 读取请求参数。
// iOS 客户端主要用 JSON POST；这里同时兼容普通表单 POST，方便浏览器或 curl 调试。
function badGetRequestData() {
    $data = json_decode(file_get_contents('php://input'), true);
    if (!$data) {
        $data = $_POST;
    }
    return is_array($data) ? $data : [];
}

// 输出统一 JSON 响应并立即结束脚本。
// code=200 表示成功，其它 code 表示业务或服务端错误。
function badResponse($code, $msg, $extra = []) {
    echo json_encode(array_merge([
        'code' => $code,
        'msg' => $msg
    ], $extra));
    exit;
}

// 获取客户端 IP，优先读取代理转发头。
function badGetIp() {
    if (!empty($_SERVER["HTTP_X_FORWARDED_FOR"])) return $_SERVER["HTTP_X_FORWARDED_FOR"];
    if (!empty($_SERVER["HTTP_CLIENT_IP"])) return $_SERVER["HTTP_CLIENT_IP"];
    if (!empty($_SERVER["REMOTE_ADDR"])) return $_SERVER["REMOTE_ADDR"];
    return "Unknown";
}

// 必填字段校验。
// 缺字段时直接返回 JSON，不继续执行数据库逻辑。
function badRequireFields($data, $fields) {
    foreach ($fields as $field) {
        if (!isset($data[$field]) || $data[$field] === '') {
            badResponse(400, 'MissingField', ['field' => $field]);
        }
    }
}

// 统一习惯类型：1 表示好习惯，-1 表示坏习惯。
// 客户端未传或传错时默认按坏习惯处理，避免错误加分。
function badNormalizeBehaviorType($value) {
    return intval($value) === 1 ? 1 : -1;
}

// 默认单次记录分值：好习惯 +1，坏习惯 -2。
// 具体习惯可以通过 bad_Behavior.scoreUnit 覆盖这个默认值。
function badScoreUnitByBehaviorType($behaviorType) {
    return badNormalizeBehaviorType($behaviorType) === 1 ? 1 : -2;
}

// 规范化单次分值：好习惯只允许 +1 ~ +5，坏习惯只允许 -1 ~ -5。
function badNormalizeScoreUnit($scoreUnit, $behaviorType) {
    $behaviorType = badNormalizeBehaviorType($behaviorType);
    $scoreUnit = intval($scoreUnit);

    if ($behaviorType === 1) {
        if ($scoreUnit < 1 || $scoreUnit > 5) {
            return 1;
        }
        return $scoreUnit;
    }

    if ($scoreUnit > 0) {
        $scoreUnit = -$scoreUnit;
    }
    if ($scoreUnit > -1 || $scoreUnit < -5) {
        return -2;
    }
    return $scoreUnit;
}

// 从习惯行里读取单次分值；兼容旧数据没有 scoreUnit 的情况。
function badScoreUnitByBehavior($behavior) {
    $behaviorType = isset($behavior['behaviorType']) ? $behavior['behaviorType'] : -1;
    if (isset($behavior['scoreUnit']) && $behavior['scoreUnit'] !== null && $behavior['scoreUnit'] !== '') {
        return badNormalizeScoreUnit($behavior['scoreUnit'], $behaviorType);
    }
    return badScoreUnitByBehaviorType($behaviorType);
}

// 呵护码算法：
// 1. userId 先经过可逆仿射变换，避免呵护码直接暴露递增 ID。
// 2. 再转成 6 位 base36 字符串，展示为大写，输入时忽略大小写。
// 3. 62 位字符虽然容量更大，但大小写容易输错；这里优先降低用户输入成本。
function badCareCodeAlphabet() {
    return '0123456789ABCDEFGHIJKLMNOPQRSTUVWXYZ';
}

function badMulMod($left, $right, $mod) {
    $left = $left % $mod;
    $right = intval($right);
    $result = 0;
    while ($right > 0) {
        if ($right % 2 === 1) {
            $result = ($result + $left) % $mod;
        }
        $left = ($left * 2) % $mod;
        $right = intval($right / 2);
    }
    return $result;
}

function badEncodeCareCode($userId) {
    $alphabet = badCareCodeAlphabet();
    $base = 36;
    $mod = 2176782336;
    $a = 1000003;
    $b = 31415926;

    $userId = intval($userId);
    if ($userId <= 0 || $userId >= $mod) {
        return '';
    }

    $value = (($userId * $a) + $b) % $mod;
    $code = '';
    for ($i = 0; $i < 6; $i++) {
        $index = $value % $base;
        $code = $alphabet[$index] . $code;
        $value = intval($value / $base);
    }
    return $code;
}

function badDecodeCareCode($careCode) {
    $alphabet = badCareCodeAlphabet();
    $base = 36;
    $mod = 2176782336;
    $aInverse = 910375531;
    $b = 31415926;

    $careCode = strtoupper(trim((string)$careCode));
    if (!preg_match('/^[0-9A-Za-z]{6}$/', $careCode)) {
        return 0;
    }

    $value = 0;
    for ($i = 0; $i < 6; $i++) {
        $pos = strpos($alphabet, $careCode[$i]);
        if ($pos === false) {
            return 0;
        }
        $value = ($value * $base) + $pos;
    }

    $normalized = ($value - $b) % $mod;
    if ($normalized < 0) {
        $normalized += $mod;
    }
    $userId = badMulMod($normalized, $aInverse, $mod);
    if ($userId <= 0 || $userId >= $mod) {
        return 0;
    }
    return intval($userId);
}

function badAttachCareCode($user) {
    if (is_array($user) && isset($user['userId'])) {
        $user['careCode'] = badEncodeCareCode($user['userId']);
    }
    return $user;
}

// 呵护权限等级：1 低权限只查看，2 中权限可查看可改，3 高权限可全权管理。
function badNormalizeCarePermission($value) {
    $level = intval($value);
    if ($level < 1) return 1;
    if ($level > 3) return 3;
    return $level;
}

// 权限等级展示文案，接口直接返回给小程序使用。
function badCarePermissionName($level) {
    $level = badNormalizeCarePermission($level);
    if ($level === 3) return '高权限';
    if ($level === 2) return '中权限';
    return '低权限';
}

// 从习惯行里取“这个习惯作用于谁”。老数据没有 subjectUserId 时回退到 userId。
function badBehaviorSubjectUserId($behavior) {
    if (isset($behavior['subjectUserId']) && $behavior['subjectUserId'] !== null && $behavior['subjectUserId'] !== '') {
        return intval($behavior['subjectUserId']);
    }
    if (isset($behavior['userId']) && $behavior['userId'] !== null && $behavior['userId'] !== '') {
        return intval($behavior['userId']);
    }
    return null;
}

// 从记录行里取“这条记录算到谁身上”。老数据没有 subjectUserId 时回退到 userId。
function badRecordSubjectUserId($record) {
    if (isset($record['subjectUserId']) && $record['subjectUserId'] !== null && $record['subjectUserId'] !== '') {
        return intval($record['subjectUserId']);
    }
    if (isset($record['userId']) && $record['userId'] !== null && $record['userId'] !== '') {
        return intval($record['userId']);
    }
    return null;
}

// 修复旧记录或旧接口写入的数据：
// subjectUserId 是记录归属人，operatorUserId 是实际操作人。
// 个人习惯可以从 bad_Behavior.subjectUserId/userId 推出归属；系统默认习惯则退回记录行 userId。
function badNormalizeBehaviorRecordOwnership($pdo, $behaviorId) {
    $stmt = $pdo->prepare("
        UPDATE bad_BehaviorRecord r
        INNER JOIN bad_Behavior b ON b.behaviorId = r.behaviorId
        SET r.subjectUserId = CASE
                WHEN r.subjectUserId IS NULL THEN COALESCE(b.subjectUserId, b.userId, r.userId)
                ELSE r.subjectUserId
            END,
            r.operatorUserId = CASE
                WHEN r.operatorUserId IS NULL THEN r.userId
                ELSE r.operatorUserId
            END
        WHERE r.behaviorId = :behaviorId
          AND (r.subjectUserId IS NULL OR r.operatorUserId IS NULL)
    ");
    $stmt->execute([':behaviorId' => intval($behaviorId)]);
}

// 是否有高权限呵护者正在锁定被呵护者自己的修改权。
function badHasHighCareLock($pdo, $subjectUserId) {
    $stmt = $pdo->prepare("
        SELECT careId
        FROM bad_CareRelation
        WHERE caredUserId = :subjectUserId
          AND status = 1
          AND permissionLevel = 3
        LIMIT 1
    ");
    $stmt->execute([':subjectUserId' => intval($subjectUserId)]);
    return $stmt->fetch() ? true : false;
}

// 判断操作者是否可以查看某个用户的习惯和记录。
function badCanViewSubject($pdo, $actorUserId, $subjectUserId) {
    if ($subjectUserId === null) {
        return true;
    }
    if ($actorUserId === null) {
        return false;
    }

    $actorUserId = intval($actorUserId);
    $subjectUserId = intval($subjectUserId);
    if ($actorUserId === $subjectUserId) {
        return true;
    }

    $stmt = $pdo->prepare("
        SELECT careId
        FROM bad_CareRelation
        WHERE guardianUserId = :actorUserId
          AND caredUserId = :subjectUserId
          AND status = 1
          AND permissionLevel >= 1
        LIMIT 1
    ");
    $stmt->execute([
        ':actorUserId' => $actorUserId,
        ':subjectUserId' => $subjectUserId
    ]);
    return $stmt->fetch() ? true : false;
}

// 判断操作者是否可以新增、编辑、删除某个用户的习惯或记录。
function badCanManageSubject($pdo, $actorUserId, $subjectUserId) {
    if ($subjectUserId === null) {
        return $actorUserId === null;
    }
    if ($actorUserId === null) {
        return false;
    }

    $actorUserId = intval($actorUserId);
    $subjectUserId = intval($subjectUserId);
    if ($actorUserId === $subjectUserId) {
        return !badHasHighCareLock($pdo, $subjectUserId);
    }

    $stmt = $pdo->prepare("
        SELECT careId
        FROM bad_CareRelation
        WHERE guardianUserId = :actorUserId
          AND caredUserId = :subjectUserId
          AND status = 1
          AND permissionLevel >= 2
        LIMIT 1
    ");
    $stmt->execute([
        ':actorUserId' => $actorUserId,
        ':subjectUserId' => $subjectUserId
    ]);
    return $stmt->fetch() ? true : false;
}

// 无权限时统一返回 PermissionDenied，客户端已有对应中文提示。
function badRequireCanViewSubject($pdo, $actorUserId, $subjectUserId) {
    if (!badCanViewSubject($pdo, $actorUserId, $subjectUserId)) {
        badResponse(403, 'PermissionDenied');
    }
}

function badRequireCanManageSubject($pdo, $actorUserId, $subjectUserId) {
    if (!badCanManageSubject($pdo, $actorUserId, $subjectUserId)) {
        badResponse(403, 'PermissionDenied');
    }
}
?>
