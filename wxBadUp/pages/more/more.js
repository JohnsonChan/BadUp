const api = require('../../utils/api')

const app = getApp()

Page({
  data: {
    user: null,
    registerDate: '-',
    platformName: '-',
    behaviorScore: '-',
    behaviorScoreClass: '',
  },

  onShow() {
    const user = app.globalData.user || wx.getStorageSync('badup.cached.user') || null

    // 这里优先读全局内存，其次读本地缓存，避免页面刷新后信息丢失。
    this.setData({
      user,
      registerDate: user && user.createdAt ? user.createdAt : '-',
      platformName: this.formatPlatformName(user && user.platform),
      behaviorScore: '-',
      behaviorScoreClass: '',
    })

    if (user && user.userId) {
      this.loadBehaviorScore(user.userId)
    }
  },

  loadBehaviorScore(userId) {
    api.fetchUserBehaviorScore(userId)
      .then((score) => {
        const behaviorScore = Number(score.behaviorScore || 0)
        this.setData({
          behaviorScore,
          behaviorScoreClass: behaviorScore > 0 ? 'positive' : (behaviorScore < 0 ? 'negative' : ''),
        })
      })
      .catch((error) => {
        this.setData({ behaviorScore: '-' })
        wx.showToast({ title: error.message || '习惯分加载失败', icon: 'none' })
      })
  },

  // 点击生长指数时，进入网页页，并把当前指数作为 index 参数传给网页。
  openGrowthIndexPage() {
    const score = Number(this.data.behaviorScore)
    const index = Number.isFinite(score) ? score : 0

    wx.navigateTo({
      url: `/pages/growth-web/growth-web?index=${encodeURIComponent(index)}`,
    })
  },

  // 将服务端 platform 字段统一转换为页面展示文案。
  formatPlatformName(platform) {
    const value = String(platform || '').trim().toLowerCase()

    if (!value) {
      return '-'
    }

    if (
      value === 'wechatminiprogram' ||
      value === 'wechat_mini_program' ||
      value === 'wechat-mini-program' ||
      value === 'miniprogram' ||
      value === 'weapp' ||
      value === 'wx' ||
      value.indexOf('wechat') !== -1 ||
      value.indexOf('mini') !== -1
    ) {
      return '微信小程序'
    }

    if (value.indexOf('android') !== -1) {
      return 'Android'
    }

    if (value === 'ios' || value === 'iphone' || value === 'ipad' || value.indexOf('ios') !== -1) {
      return 'iOS App'
    }

    return '-'
  },
})
