<?php
// 呵护关系列表：只保留“我呵护的”和“呵护我的”两组关系。
require_once "bad_Common.php";
require_once "bad_Database.php";

$data = badGetRequestData();
badRequireFields($data, ['userId']);

function badMapCareRow($pdo, $row, $currentUserId, $mode) {
    $permissionLevel = badNormalizeCarePermission($row['permissionLevel']);
    if ($mode === 'guardian') {
        $otherUserId = intval($row['caredUserId']);
        $otherUserName = $row['caredUserName'];
    } else {
        $otherUserId = intval($row['guardianUserId']);
        $otherUserName = $row['guardianUserName'];
    }
    $remark = badCareRemarkOwnedBy($pdo, $currentUserId, $otherUserId);

    $status = intval($row['status']);
    if ($status === 1) {
        $statusName = '已同意';
    } else if ($status === 2) {
        $statusName = '已拒绝';
    } else {
        $statusName = '等待同意';
    }

    return [
        'careId' => intval($row['careId']),
        'guardianUserId' => intval($row['guardianUserId']),
        'guardianUserName' => $row['guardianUserName'],
        'caredUserId' => intval($row['caredUserId']),
        'caredUserName' => $row['caredUserName'],
        'otherUserId' => $otherUserId,
        'otherUserName' => $otherUserName,
        'remark' => $remark,
        'displayName' => badCareDisplayName($otherUserId, $otherUserName, $remark),
        'permissionLevel' => $permissionLevel,
        'permissionName' => badCarePermissionName($permissionLevel),
        'status' => $status,
        'statusName' => $statusName,
        'rejectReason' => isset($row['rejectReason']) ? $row['rejectReason'] : '',
        'requesterUserId' => intval($row['requesterUserId']),
        'isRequester' => intval($row['requesterUserId']) === intval($currentUserId) ? 1 : 0,
        'canUpdatePermission' => ($status === 1 && intval($row['requesterUserId']) === intval($currentUserId)) ? 1 : 0,
        'canRespond' => ($status === 0 && intval($row['guardianUserId']) === intval($currentUserId) && intval($row['requesterUserId']) !== intval($currentUserId)) ? 1 : 0,
        'canDelete' => intval($row['requesterUserId']) === intval($currentUserId) ? 1 : 0,
        'createdAt' => $row['createdAt']
    ];
}

try {
    $pdo = Database::getPdoInstance();
    $userId = intval($data['userId']);

    $baseSql = "
        SELECT cr.*,
               g.userName AS guardianUserName,
               c.userName AS caredUserName
        FROM bad_CareRelation cr
        INNER JOIN bad_User g ON g.userId = cr.guardianUserId
        INNER JOIN bad_User c ON c.userId = cr.caredUserId
    ";

    $guardianQuery = $pdo->prepare($baseSql . "
        WHERE cr.guardianUserId = :userId
        ORDER BY cr.updatedAt DESC, cr.careId DESC
    ");
    $guardianQuery->execute([':userId' => $userId]);
    $careAsGuardian = [];
    foreach ($guardianQuery->fetchAll() as $row) {
        $careAsGuardian[] = badMapCareRow($pdo, $row, $userId, 'guardian');
    }

    $caredQuery = $pdo->prepare($baseSql . "
        WHERE cr.caredUserId = :userId
        ORDER BY cr.updatedAt DESC, cr.careId DESC
    ");
    $caredQuery->execute([':userId' => $userId]);
    $careAsCared = [];
    foreach ($caredQuery->fetchAll() as $row) {
        $careAsCared[] = badMapCareRow($pdo, $row, $userId, 'cared');
    }

    badResponse(200, 'OK', [
        'careAsGuardian' => $careAsGuardian,
        'careAsCared' => $careAsCared
    ]);
} catch (PDOException $e) {
    badResponse(500, 'DataError: ' . $e->getMessage());
}
?>
