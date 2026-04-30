// 后端接口封装。
// iOS App 和小程序共用同一套 PHP 接口，方便后续维护数据一致性。

const baseURL = 'http://66zqx.com/phpBadUp/'

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
    text.indexOf('这个行为名称已经存在') !== -1
  ) {
    return '这个行为名称已经存在，请换一个名称'
  }
  return text
}

// 小程序无法像原生 App 一样拿到稳定设备标识，这里退而求其次：
// 首次运行生成一个本地 deviceId，后续从 storage 复用。
function getDeviceId() {
  const key = 'badup.device.id'
  const existing = wx.getStorageSync(key)
  if (existing) return existing

  const random = Math.random().toString(16).slice(2)
  const deviceId = `wx-${Date.now()}-${random}`
  wx.setStorageSync(key, deviceId)
  return deviceId
}

// 启动时自动登录或注册。
// 后端会根据 deviceId 判断是否需要创建新用户。
function loginOrRegister() {
  const system = wx.getSystemInfoSync()
  return request('bad_UserLoginRegister.php', {
    deviceId: getDeviceId(),
    platform: 'WeChatMiniProgram',
    appVersion: '1.0.0',
    systemVersion: system.system || '',
  }).then((res) => res.data)
}

// 拉取今天的行为列表和对应计数。
function fetchTodayCounts(userId, recordDate) {
  return request('bad_BehaviorTodayCount.php', { userId, recordDate })
    .then((res) => res.list || [])
}

// 新增一个行为项。
function addBehavior(userId, behaviorName, behaviorDesc, colorHex, behaviorType) {
  return request('bad_BehaviorInsert.php', {
    userId,
    behaviorName,
    behaviorDesc,
    colorHex,
    behaviorType,
  }).then((res) => res.data)
}

// 编辑已有行为项。
function updateBehavior(userId, behaviorId, behaviorName, behaviorDesc, colorHex) {
  return request('bad_BehaviorUpdate.php', {
    userId,
    behaviorId,
    behaviorName,
    behaviorDesc,
    colorHex,
  }).then((res) => res.data)
}

// 删除行为项及其相关记录。
function deleteBehavior(userId, behaviorId) {
  return request('bad_BehaviorDelete.php', { userId, behaviorId })
}

// 追加一条行为记录。
// clientUid 用来给服务端做幂等或排查时的客户端标识。
function insertRecord(userId, behaviorId, recordDate, recordedAt) {
  return request('bad_BehaviorRecordInsert.php', {
    userId,
    behaviorId,
    recordDate,
    recordedAt,
    countNum: 1,
    clientUid: `wx-${Date.now()}-${Math.random().toString(16).slice(2)}`,
  })
}

// 按年聚合，返回 1~12 月统计。
function fetchYearStats(behaviorId, year) {
  return request('bad_BehaviorYearStats.php', { behaviorId, year })
    .then((res) => res.list || [])
}

// 按月聚合，返回每天统计。
function fetchMonthStats(behaviorId, year, month) {
  return request('bad_BehaviorMonthStats.php', { behaviorId, year, month })
    .then((res) => res.list || [])
}

// 按天聚合，返回 0~23 点小时统计。
function fetchDayStats(behaviorId, recordDate) {
  return request('bad_BehaviorDayStats.php', { behaviorId, recordDate })
    .then((res) => res.list || [])
}

// 拉取用户累计行为分。
function fetchUserBehaviorScore(userId) {
  return request('bad_UserBehaviorScore.php', { userId })
    .then((res) => res.data || { behaviorScore: 0, totalCount: 0 })
}

module.exports = {
  baseURL,
  loginOrRegister,
  fetchTodayCounts,
  addBehavior,
  updateBehavior,
  deleteBehavior,
  insertRecord,
  fetchYearStats,
  fetchMonthStats,
  fetchDayStats,
  fetchUserBehaviorScore,
}
