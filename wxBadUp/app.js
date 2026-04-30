// app.js
// 全局 App 对象：保存登录用户，避免每个页面重复读取 storage。
App({
  globalData: {
    user: null,
  },
})
