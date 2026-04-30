const api = require('../../utils/api')
const dateUtil = require('../../utils/date')

const app = getApp()
const behaviorCardDescLimit = 88
const countRowDescLimit = 66

Page({
  data: {
    // 闪屏和登录状态。
    isSplashVisible: true,
    isLoading: false,
    errorMessage: '',
    didShowMinimumSplash: false,
    didFinishLaunchLogin: false,

    // 用户和当天日期。
    user: null,
    todayText: '',
    todayDate: '',

    // 首页展示数据：
    // behaviors 用于上方彩色按钮列表，
    // todayCounts 用于下方今日统计列表。
    behaviors: [],
    todayCounts: [],

    // 两种弹窗状态：
    // pendingRecord -> 点击按钮后的“确认记录”
    // pendingAction -> 长按按钮后的“编辑/删除”
    pendingRecord: null,
    pendingAction: null,

    // 长按后会顺带触发 tap，这个字段用于屏蔽那一次误触。
    skipNextTapBehaviorId: null,
  },

  onLoad() {
    // 页面启动时先确定“今天”的文案和日期值。
    const now = new Date()
    this.setData({
      todayText: dateUtil.formatChineseDate(now),
      todayDate: dateUtil.formatDate(now),
    })

    // 启动流程与 iOS 一致：
    // 1. 闪屏至少展示 1.5 秒
    // 2. 登录完成且拿到 user 后才进入首页
    this.startLaunchFlow()
  },

  onShow() {
    // 从新增/编辑页返回首页时，重新刷新今天的数据。
    if (this.data.user && !this.data.isSplashVisible) {
      this.loadToday()
    }
  },

  onUnload() {
    if (this.minimumSplashTimer) {
      clearTimeout(this.minimumSplashTimer)
      this.minimumSplashTimer = null
    }
  },

  // 与 iOS RootView 对齐的启动门槛：
  // 只有“最短闪屏时间已到”且“启动登录已成功”时，才隐藏闪屏。
  startLaunchFlow() {
    if (this.minimumSplashTimer) {
      clearTimeout(this.minimumSplashTimer)
    }

    this.setData({
      isSplashVisible: true,
      isLoading: false,
      errorMessage: '',
      didShowMinimumSplash: false,
      didFinishLaunchLogin: false,
    })

    this.minimumSplashTimer = setTimeout(() => {
      this.minimumSplashTimer = null
      this.setData({ didShowMinimumSplash: true }, () => {
        this.syncSplashVisibility()
      })
    }, 1500)

    this.loginAndLoad()
  },

  // 根据当前启动状态决定是否离开闪屏页。
  syncSplashVisibility() {
    const canEnterApp = this.data.didShowMinimumSplash && this.data.didFinishLaunchLogin && !!this.data.user
    this.setData({ isSplashVisible: !canEnterApp })
  },

  // 统一处理登录和首页数据加载。
  loginAndLoad() {
    this.setData({ isLoading: true, errorMessage: '' })
    return api.loginOrRegister()
      .then((user) => {
        // 登录后的用户同时放到全局和本地缓存，方便其他页面直接读取。
        app.globalData.user = user
        wx.setStorageSync('badup.cached.user', user)
        this.setData({
          user,
          didFinishLaunchLogin: true,
        }, () => {
          this.syncSplashVisibility()
        })
        return this.loadToday()
      })
      .catch((error) => {
        this.setData({
          didFinishLaunchLogin: false,
          errorMessage: error.message || '登录失败，请重试',
        }, () => {
          this.syncSplashVisibility()
        })
      })
      .finally(() => {
        this.setData({ isLoading: false })
      })
  },

  // 重试登录时，重置为与首次启动相同的闪屏逻辑。
  retryLogin() {
    this.startLaunchFlow()
  },

  // 拉取首页今天的行为和统计，并整理成页面更好用的结构。
  loadToday() {
    const { user, todayDate } = this.data
    if (!user) return Promise.resolve()

    return api.fetchTodayCounts(user.userId, todayDate)
      .then((list) => {
        const mapped = list.map((item) => {
          const behavior = this.normalizeBehavior(item)
          return {
            id: behavior.behaviorId,
            behavior,
            count: Number(item.todayCount || 0),
          }
        })
        this.setData({
          behaviors: mapped.map((item) => item.behavior),
          todayCounts: mapped,
        })
      })
      .catch((error) => {
        wx.showToast({ title: error.message || '加载失败', icon: 'none' })
      })
  },

  // 后端字段转成前端统一结构，避免页面里反复兼容 null / string / number。
  normalizeBehavior(item) {
    const behaviorDesc = item.behaviorDesc || ''
    return {
      behaviorId: Number(item.behaviorId),
      userId: item.userId === null || item.userId === undefined ? null : Number(item.userId),
      behaviorName: item.behaviorName || '',
      behaviorDesc,
      behaviorCardDesc: this.truncateText(behaviorDesc, behaviorCardDescLimit),
      countRowDesc: this.truncateText(behaviorDesc, countRowDescLimit),
      colorHex: item.colorHex || '#F55F52',
    }
  },

  // 小程序 Skyline 对多行省略的 CSS 支持不稳定，这里提前生成展示用短文本。
  // 中文按 2 个宽度单位计算，英文和数字按 1 个宽度单位计算。
  truncateText(text, maxUnits) {
    if (!text) return ''

    let units = 0
    let result = ''
    const chars = Array.from(text)

    for (let index = 0; index < chars.length; index += 1) {
      const char = chars[index]
      const charUnits = /[^\x00-\xff]/.test(char) ? 2 : 1
      if (units + charUnits > maxUnits) {
        return `${result}...`
      }
      units += charUnits
      result += char
    }

    return result
  },

  // 进入新增行为页。
  goAddBehavior() {
    wx.navigateTo({ url: '/pages/behavior-form/behavior-form' })
  },

  // 进入更多页。
  goMore() {
    wx.navigateTo({ url: '/pages/more/more' })
  },

  // 普通点击：弹出“确认记录”。
  onBehaviorTap(event) {
    const behaviorId = Number(event.currentTarget.dataset.id)
    if (this.data.skipNextTapBehaviorId === behaviorId) {
      this.setData({ skipNextTapBehaviorId: null })
      return
    }
    const behavior = this.data.behaviors.find((item) => item.behaviorId === behaviorId)
    if (behavior) {
      this.setData({ pendingRecord: behavior })
    }
  },

  // 长按：弹出“编辑/删除”。
  // 同时短暂屏蔽一次 tap，避免长按后又立刻触发记录弹窗。
  onBehaviorLongPress(event) {
    const behaviorId = Number(event.currentTarget.dataset.id)
    const behavior = this.data.behaviors.find((item) => item.behaviorId === behaviorId)
    if (behavior) {
      this.setData({
        pendingAction: behavior,
        skipNextTapBehaviorId: behaviorId,
      })
      setTimeout(() => {
        if (this.data.skipNextTapBehaviorId === behaviorId) {
          this.setData({ skipNextTapBehaviorId: null })
        }
      }, 500)
    }
  },

  // 关闭所有弹窗。
  cancelDialog() {
    this.setData({
      pendingRecord: null,
      pendingAction: null,
    })
  },

  // 真正向服务端写入一条记录。
  confirmRecord() {
    const { user, pendingRecord, todayDate } = this.data
    if (!user || !pendingRecord) return

    api.insertRecord(
      user.userId,
      pendingRecord.behaviorId,
      todayDate,
      dateUtil.formatDateTime(new Date()),
    )
      .then(() => {
        this.setData({ pendingRecord: null })
        return this.loadToday()
      })
      .catch((error) => {
        wx.showToast({ title: error.message || '记录失败', icon: 'none' })
      })
  },

  // 进入编辑页，并把当前行为信息拼到 query 里带过去。
  editBehavior() {
    const behavior = this.data.pendingAction
    if (!behavior) return

    const url = `/pages/behavior-form/behavior-form?mode=edit&behaviorId=${behavior.behaviorId}&name=${encodeURIComponent(behavior.behaviorName)}&desc=${encodeURIComponent(behavior.behaviorDesc)}&color=${encodeURIComponent(behavior.colorHex)}`
    this.setData({ pendingAction: null })
    wx.navigateTo({ url })
  },

  // 删除行为后，重新刷新首页列表。
  deleteBehavior() {
    const { user, pendingAction } = this.data
    if (!user || !pendingAction) return

    api.deleteBehavior(user.userId, pendingAction.behaviorId)
      .then(() => {
        this.setData({ pendingAction: null })
        return this.loadToday()
      })
      .catch((error) => {
        wx.showToast({ title: error.message || '删除失败', icon: 'none' })
      })
  },

  // 点击“今天统计”中的项目，进入年份统计页。
  goYearDetail(event) {
    const behaviorId = Number(event.currentTarget.dataset.id)
    const item = this.data.todayCounts.find((countItem) => countItem.behavior.behaviorId === behaviorId)
    if (!item) return

    const behavior = item.behavior
    wx.navigateTo({
      url: `/pages/year-detail/year-detail?behaviorId=${behavior.behaviorId}&name=${encodeURIComponent(behavior.behaviorName)}&desc=${encodeURIComponent(behavior.behaviorDesc)}&color=${encodeURIComponent(behavior.colorHex)}`,
    })
  },
})
