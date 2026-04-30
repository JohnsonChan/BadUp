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

// 统一行为类型：1 表示好行为，-1 表示坏行为。
// 客户端未传或传错时默认按坏行为处理，避免错误加分。
function badNormalizeBehaviorType($value) {
    return intval($value) === 1 ? 1 : -1;
}

// 单次记录的行为分：好行为 +1，坏行为 -10。
function badScoreUnitByBehaviorType($behaviorType) {
    return badNormalizeBehaviorType($behaviorType) === 1 ? 1 : -10;
}
?>
