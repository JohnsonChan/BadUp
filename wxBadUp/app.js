// app.js
// 全局 App 对象：保存登录用户，避免每个页面重复读取 storage。
App({
  globalData: {
    user: null,
    // 日期页删除单条记录后写入这里。
    // 月页和年页只在 token 变化且数据范围匹配时刷新，避免无删除动作也重复请求。
    recordStatsChange: {
      token: 0,
      behaviorId: null,
      recordDate: '',
      year: null,
      month: null,
    },
  },
})
