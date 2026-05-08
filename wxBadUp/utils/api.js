// 后端接口封装。
// iOS App 和小程序共用同一套 PHP 接口，方便后续维护数据一致性。

const baseURL = 'http://shouzhuan007.com/phpBadUp/'
const appVersion = '1.0.2'

// 统一的 POST 请求入口：
// 1. 发起请求
// 2. 校验 HTTP 状态码
// 3. 校验 PHP 返回结构是否符合约定
function request(endpoint, data = {}) {
  return new Promise((resolve, reject) => {
    wx.request({
      url: baseURL + endpoint,
      method: 'POST',
      data,
      header: {
        'content-type': 'application/json',
      },
      success(res) {
        const body = res.data
        if (res.statusCode < 200 || res.statusCode >= 300) {
          reject(new Error(`HTTP ${res.statusCode}`))
          return
        }
        if (!body || typeof body !== 'object') {
          reject(new Error('服务端响应异常'))
          return
        }
        if (Number(body.code) !== 200) {
          reject(new Error(formatApiMessage(body.msg || '服务端返回失败')))
          return
        }
        resolve(body)
      },
      fail(err) {
        reject(new Error(err.errMsg || '网络请求失败'))
      },
    })
  })
}

function formatApiMessage(message) {
  const text = String(message || '')
  if (
    text.indexOf('DuplicateBehaviorName') !== -1 ||
    text.indexOf('Integrity constraint') !== -1 ||
    text.indexOf('Duplicate entry') !== -1 ||
    text.indexOf('uniq_userId_behaviorName') !== -1 ||
    text.indexOf('名称已经存在') !== -1 ||
    text.indexOf('这个习惯名称已经存在') !== -1
  ) {
    return '这个习惯名称已经存在，请换一个名称'
  }
  if (text.indexOf('RecordNotFound') !== -1) {
    return '这条记录不存在或已被删除'
  }
  if (text.indexOf('PermissionDenied') !== -1) {
    return '当前没有权限操作'
  }
  if (text.indexOf('WeChatConfigMissing') !== -1) {
    return '微信登录配置缺失，请检查服务端配置'
  }
  if (
    text.indexOf('WeChatLoginFailed') !== -1 ||
    text.indexOf('WeChatLoginRequestFailed') !== -1 ||
    text.indexOf('WeChatLoginInvalidResponse') !== -1 ||
    text.indexOf('WeChatOpenIdMissing') !== -1
  ) {
    return '微信登录失败，请稍后重试'
  }
  if (text.indexOf('呵护申请已发送') !== -1 || text.indexOf('CareRequestPending') !== -1) {
    return '呵护申请已发送，请等待对方确认'
  }
  return text
}

// 小程序登录以微信 openid 为准：
// 1. 小程序端调用 wx.login 拿一次性 code
// 2. code 发给 PHP，PHP 请求微信接口换 openid
// 3. 服务端按 openid 登录或注册用户
function getWechatLoginCode() {
  return new Promise((resolve, reject) => {
    wx.login({
      success(res) {
        if (res.code) {
          resolve(res.code)
          return
        }
        reject(new Error(res.errMsg || '微信登录失败'))
      },
      fail(err) {
        reject(new Error(err.errMsg || '微信登录失败'))
      },
    })
  })
}

// 启动时自动登录或注册。
// 小程序只传 loginCode，服务端只按 openid 识别微信用户。
function loginOrRegister() {
  const system = wx.getSystemInfoSync()
  return getWechatLoginCode()
    .then((loginCode) => request('bad_UserLoginRegister.php', {
      loginCode,
      platform: 'WeChatMiniProgram',
      appVersion,
      systemVersion: system.system || '',
    }))
    .then((res) => res.data)
}

// 拉取今天的习惯列表和对应计数。
function fetchTodayCounts(userId, recordDate, subjectUserId) {
  return request('bad_BehaviorTodayCount.php', { userId, recordDate, subjectUserId })
    .then((res) => res.list || [])
}

// 新增一个习惯项。
function addBehavior(userId, behaviorName, behaviorDesc, colorHex, behaviorType, subjectUserId) {
  return request('bad_BehaviorInsert.php', {
    userId,
    subjectUserId,
    behaviorName,
    behaviorDesc,
    colorHex,
    behaviorType,
  }).then((res) => res.data)
}

// 编辑已有习惯项。
function updateBehavior(userId, behaviorId, behaviorName, behaviorDesc, colorHex, subjectUserId) {
  return request('bad_BehaviorUpdate.php', {
    userId,
    subjectUserId,
    behaviorId,
    behaviorName,
    behaviorDesc,
    colorHex,
  }).then((res) => res.data)
}

// 删除习惯项及其相关记录。
function deleteBehavior(userId, behaviorId, subjectUserId) {
  return request('bad_BehaviorDelete.php', { userId, behaviorId, subjectUserId })
}

// 更新习惯项展示顺序。
function updateBehaviorSort(userId, behaviorIds, subjectUserId) {
  return request('bad_BehaviorSortUpdate.php', { userId, behaviorIds, subjectUserId })
}

// 追加一条习惯记录。
// clientUid 用来给服务端做幂等或排查时的客户端标识。
function insertRecord(userId, behaviorId, recordDate, recordedAt, subjectUserId) {
  return request('bad_BehaviorRecordInsert.php', {
    userId,
    subjectUserId,
    behaviorId,
    recordDate,
    recordedAt,
    countNum: 1,
    clientUid: `wx-${Date.now()}-${Math.random().toString(16).slice(2)}`,
  })
}

// 按年聚合，返回 1~12 月统计。
function fetchYearStats(behaviorId, year, userId, subjectUserId) {
  return request('bad_BehaviorYearStats.php', { behaviorId, year, userId, subjectUserId })
    .then((res) => res.list || [])
}

// 按月聚合，返回每天统计。
function fetchMonthStats(behaviorId, year, month, userId, subjectUserId) {
  return request('bad_BehaviorMonthStats.php', { behaviorId, year, month, userId, subjectUserId })
    .then((res) => res.list || [])
}

// 按天聚合，返回 0~23 点小时统计。
function fetchDayStats(behaviorId, recordDate, userId, subjectUserId) {
  return request('bad_BehaviorDayStats.php', { behaviorId, recordDate, userId, subjectUserId })
    .then((res) => res.list || [])
}

// 拉取某一天某个小时内的单条记录，用于删除其中一条。
function fetchHourRecords(userId, behaviorId, recordDate, hourNum, subjectUserId) {
  return request('bad_BehaviorRecordHourList.php', {
    userId,
    subjectUserId,
    behaviorId,
    recordDate,
    hourNum,
  }).then((res) => res.list || [])
}

// 删除单条习惯记录，不删除习惯项本身。
function deleteBehaviorRecord(userId, recordId) {
  return request('bad_BehaviorRecordDelete.php', { userId, recordId })
}

// 拉取用户累计习惯分。
function fetchUserBehaviorScore(userId) {
  return request('bad_UserBehaviorScore.php', { userId })
    .then((res) => res.data || { behaviorScore: 0, totalCount: 0 })
}

function fetchCareList(userId) {
  return request('bad_CareList.php', { userId })
}

function requestCare(userId, careCode, permissionLevel) {
  return request('bad_CareRequest.php', {
    userId,
    careCode,
    permissionLevel,
  })
}

function respondCare(userId, careId, action, rejectReason = '') {
  return request('bad_CareRespond.php', { userId, careId, action, rejectReason })
}

function updateCareRemark(userId, careId, remark) {
  return request('bad_CareRemarkUpdate.php', { userId, careId, remark })
}

// 修改已建立呵护关系的权限。服务端只允许发起方修改。
function updateCarePermission(userId, careId, permissionLevel) {
  return request('bad_CarePermissionUpdate.php', { userId, careId, permissionLevel })
}

module.exports = {
  baseURL,
  appVersion,
  loginOrRegister,
  fetchTodayCounts,
  addBehavior,
  updateBehavior,
  deleteBehavior,
  updateBehaviorSort,
  insertRecord,
  fetchYearStats,
  fetchMonthStats,
  fetchDayStats,
  fetchHourRecords,
  deleteBehaviorRecord,
  fetchUserBehaviorScore,
  fetchCareList,
  requestCare,
  respondCare,
  updateCareRemark,
  updateCarePermission,
}
