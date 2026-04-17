<?php
header('Content-Type: application/json; charset=utf-8');

function badGetRequestData() {
    $data = json_decode(file_get_contents('php://input'), true);
    if (!$data) {
        $data = $_POST;
    }
    return is_array($data) ? $data : [];
}

function badResponse($code, $msg, $extra = []) {
    echo json_encode(array_merge([
        'code' => $code,
        'msg' => $msg
    ], $extra));
    exit;
}

function badGetIp() {
    if (!empty($_SERVER["HTTP_X_FORWARDED_FOR"])) return $_SERVER["HTTP_X_FORWARDED_FOR"];
    if (!empty($_SERVER["HTTP_CLIENT_IP"])) return $_SERVER["HTTP_CLIENT_IP"];
    if (!empty($_SERVER["REMOTE_ADDR"])) return $_SERVER["REMOTE_ADDR"];
    return "Unknown";
}

function badRequireFields($data, $fields) {
    foreach ($fields as $field) {
        if (!isset($data[$field]) || $data[$field] === '') {
            badResponse(400, 'MissingField', ['field' => $field]);
        }
    }
}
?>
