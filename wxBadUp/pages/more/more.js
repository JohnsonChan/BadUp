const api = require('../../utils/api')

const app = getApp()
const contactText = 'BooTry'
Page({
  data: {
    pageTitle: '更多',
    user: null,
    viewerUser: null,
    subjectUserId: null,
    subjectName: '',
    isSubjectMode: false,
    hideCareManagement: false,
    displayName: '未设置昵称',
    hasAvatar: false,
    registerDate: '-',
    platformName: '-',
    behaviorScore: '-',
    behaviorScoreClass: '',
  },

  onLoad(options) {
    const subjectUserId = Number(options && options.subjectUserId)
    const isSubjectMode = Number.isFinite(subjectUserId) && subjectUserId > 0
    const subjectName = isSubjectMode ? decodeURIComponent((options && options.subjectName) || '') : ''
    this.setData({
      pageTitle: isSubjectMode ? '种子信息' : '更多',
      subjectUserId: isSubjectMode ? subjectUserId : null,
      subjectName,
      isSubjectMode,
      hideCareManagement: Boolean(Number(options && options.hideCareManagement)),
    })
  },

  onShow() {
    const viewerUser = app.globalData.user || wx.getStorageSync('badup.cached.user') || null
    const fallbackUser = this.data.isSubjectMode
      ? { userId: this.data.subjectUserId, userName: this.data.subjectName }
      : viewerUser

    // 先用本地或路由里的信息占位，随后如果是守护对象，再向服务端读取目标用户资料。
    this.setData({
      viewerUser,
      user: fallbackUser,
      displayName: this.formatDisplayName(fallbackUser),
      hasAvatar: !!(fallbackUser && fallbackUser.avatar),
      registerDate: fallbackUser && fallbackUser.createdAt ? fallbackUser.createdAt : '-',
      platformName: this.formatPlatformName(fallbackUser && fallbackUser.platform),
      behaviorScore: '-',
      behaviorScoreClass: '',
    })

    if (this.data.isSubjectMode) {
      this.loadSubjectUserInfo()
      return
    }

    if (viewerUser && viewerUser.userId) {
      this.loadBehaviorScore(viewerUser.userId, viewerUser.userId)
    }
  },

  loadSubjectUserInfo() {
    const viewerUser = this.data.viewerUser
    const subjectUserId = this.data.subjectUserId
    if (!viewerUser || !viewerUser.userId || !subjectUserId) return

    api.fetchUserInfo(viewerUser.userId, subjectUserId)
      .then((user) => {
        this.setData({
          user,
          displayName: this.formatDisplayName(user),
          hasAvatar: !!(user && user.avatar),
          registerDate: user && user.createdAt ? user.createdAt : '-',
          platformName: this.formatPlatformName(user && user.platform),
        })
        this.loadBehaviorScore(viewerUser.userId, subjectUserId)
      })
      .catch((error) => {
        wx.showToast({ title: error.message || '种子信息加载失败', icon: 'none' })
        this.loadBehaviorScore(viewerUser.userId, subjectUserId)
      })
  },

  formatDisplayName(user) {
    if (user && user.userName) {
      return user.userName
    }
    if (user && user.userId) {
      return `种子${user.userId}`
    }
    return '未设置昵称'
  },

  loadBehaviorScore(userId, subjectUserId) {
    api.fetchUserBehaviorScore(userId, subjectUserId)
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

  // 点击生长分数时，进入网页页，并把当前指数作为 index 参数传给网页。
  openGrowthIndexPage() {
    const score = Number(this.data.behaviorScore)
    const index = Number.isFinite(score) ? score : 0

    wx.navigateTo({
      url: `/pages/growth-web/growth-web?index=${encodeURIComponent(index)}`,
    })
  },

  // 进入守护关系管理页。
  openCarePage() {
    wx.navigateTo({ url: '/pages/care/care' })
  },

  // 点击“联系我们”时复制联系方式，减少用户手动选择文本的成本。
  copyContactInfo() {
    wx.setClipboardData({
      data: contactText,
      success: () => {
        wx.showToast({ title: '已复制', icon: 'success' })
      },
      fail: () => {
        wx.showToast({ title: '复制失败', icon: 'none' })
      },
    })
  },

  openPrivacyPolicy() {
    this.openLegalDoc('privacy')
  },

  openUserAgreement() {
    this.openLegalDoc('agreement')
  },

  openLegalDoc(type) {
    wx.navigateTo({
      url: `/pages/legal/legal?type=${encodeURIComponent(type)}`,
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
