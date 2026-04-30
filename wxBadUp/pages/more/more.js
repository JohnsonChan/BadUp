const app = getApp()

Page({
  data: {
    user: null,
    registerDate: '-',
  },

  onShow() {
    const user = app.globalData.user || wx.getStorageSync('badup.cached.user') || null

    // 这里优先读全局内存，其次读本地缓存，避免页面刷新后信息丢失。
    this.setData({
      user,
      registerDate: user && user.createdAt ? user.createdAt : '-',
    })
  },
})
