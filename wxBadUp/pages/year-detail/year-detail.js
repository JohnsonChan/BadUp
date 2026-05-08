const api = require('../../utils/api')
const app = getApp()

Page({
  data: {
    behavior: null,
    year: new Date().getFullYear(),
    // summaries 固定为 12 项，每项对应一个月。
    summaries: [],
    totalCount: 0,
    canManageRecords: true,
    subjectUserId: null,
  },

  onLoad(options) {
    // 详情页所需的习惯信息由首页通过 query 传入。
    const behavior = {
      behaviorId: Number(options.behaviorId),
      behaviorName: decodeURIComponent(options.name || ''),
      behaviorDesc: decodeURIComponent(options.desc || ''),
      colorHex: decodeURIComponent(options.color || '#F55F52'),
    }
    this.setData({
      behavior,
      subjectUserId: Number(options.subjectUserId) || null,
      canManageRecords: String(options.canManage || '1') !== '0',
    })
    this.handledRecordChangeToken = (app.globalData.recordStatsChange || {}).token || 0
    this.load()
  },

  onShow() {
    this.reloadIfRecordStatsChanged()
  },

  // 切换年份后重新拉取该年的汇总。
  prevYear() {
    this.setData({ year: this.data.year - 1 })
    this.load()
  },

  nextYear() {
    this.setData({ year: this.data.year + 1 })
    this.load()
  },

  // 服务端可能只返回有记录的月份，这里补齐成完整 1~12 月，方便渲染。
  load() {
    const { behavior, year } = this.data
    if (!behavior) return
    const user = app.globalData.user || wx.getStorageSync('badup.cached.user') || null
    api.fetchYearStats(behavior.behaviorId, year, user && user.userId, this.data.subjectUserId)
      .then((list) => {
        const counts = {}
        list.forEach((item) => {
          counts[Number(item.monthNum)] = Number(item.totalCount || 0)
        })
        const summaries = Array.from({ length: 12 }, (_, index) => {
          const month = index + 1
          return { month, count: counts[month] || 0 }
        })
        const totalCount = summaries.reduce((sum, item) => sum + item.count, 0)
        this.setData({ summaries, totalCount })
      })
      .catch((error) => {
        wx.showToast({ title: error.message || '加载失败', icon: 'none' })
      })
  },

  // 从下级页面返回时，只有发生过删除且属于当前习惯/年份才刷新。
  reloadIfRecordStatsChanged() {
    const change = app.globalData.recordStatsChange || {}
    const token = Number(change.token || 0)
    if (!token || token === this.handledRecordChangeToken) {
      return
    }

    const { behavior, year } = this.data
    this.handledRecordChangeToken = token

    if (
      behavior &&
      Number(change.behaviorId) === Number(behavior.behaviorId) &&
      Number(change.year) === Number(year)
    ) {
      this.load()
    }
  },

  // 年 -> 月详情。
  goMonth(event) {
    const month = Number(event.currentTarget.dataset.month)
    const { behavior, year } = this.data
    wx.navigateTo({
      url: `/pages/month-detail/month-detail?behaviorId=${behavior.behaviorId}&name=${encodeURIComponent(behavior.behaviorName)}&desc=${encodeURIComponent(behavior.behaviorDesc)}&color=${encodeURIComponent(behavior.colorHex)}&year=${year}&month=${month}&subjectUserId=${this.data.subjectUserId || ''}&canManage=${this.data.canManageRecords ? 1 : 0}`,
    })
  },
})
