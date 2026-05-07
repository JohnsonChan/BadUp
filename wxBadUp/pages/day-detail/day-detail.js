const api = require('../../utils/api')
const app = getApp()

Page({
  data: {
    behavior: null,
    date: '',
    dayTitle: '',
    // 固定渲染 24 个小时段。
    hours: [],
    totalCount: 0,

    // 小时记录明细弹层。
    isRecordSheetVisible: false,
    isRecordLoading: false,
    selectedHour: null,
    selectedHourText: '',
    hourRecords: [],
  },

  onLoad(options) {
    // 日详情只需要习惯信息和日期。
    const behavior = {
      behaviorId: Number(options.behaviorId),
      behaviorName: decodeURIComponent(options.name || ''),
      colorHex: decodeURIComponent(options.color || '#F55F52'),
    }
    const date = options.date || ''
    this.setData({
      behavior,
      date,
      dayTitle: this.toChineseDate(date),
    })
    this.load()
  },

  // 把服务端返回的“有记录的小时”补齐成完整 0~23 点时间轴。
  load() {
    const { behavior, date } = this.data
    if (!behavior || !date) return

    api.fetchDayStats(behavior.behaviorId, date)
      .then((list) => {
        const counts = {}
        list.forEach((item) => {
          counts[Number(item.hourNum)] = Number(item.totalCount || 0)
        })

        const hours = Array.from({ length: 24 }, (_, hour) => ({
          hour,
          hourText: `${hour < 10 ? '0' : ''}${hour}:00`,
          count: counts[hour] || 0,
          clickable: (counts[hour] || 0) > 0,
        }))
        const totalCount = hours.reduce((sum, item) => sum + item.count, 0)
        this.setData({ hours, totalCount })
      })
      .catch((error) => {
        wx.showToast({ title: error.message || '加载失败', icon: 'none' })
      })
  },

  // 点击有记录的小时，拉取这个小时里的每一条记录并展示底部弹层。
  openHourRecords(event) {
    const hour = Number(event.currentTarget.dataset.hour)
    const count = Number(event.currentTarget.dataset.count)
    if (!count) return

    const user = app.globalData.user || wx.getStorageSync('badup.cached.user') || null
    const userId = user && user.userId
    const { behavior, date } = this.data
    if (!userId || !behavior || !date) {
      wx.showToast({ title: '用户信息异常，请重新打开小程序', icon: 'none' })
      return
    }

    this.setData({
      isRecordSheetVisible: true,
      isRecordLoading: true,
      selectedHour: hour,
      selectedHourText: `${hour < 10 ? '0' : ''}${hour}:00`,
      hourRecords: [],
    })

    api.fetchHourRecords(userId, behavior.behaviorId, date, hour)
      .then((list) => {
        const hourRecords = list.map((item) => {
          const recordedAt = item.recordedAt || ''
          const timeText = recordedAt.length >= 16 ? recordedAt.slice(11, 16) : recordedAt
          const scoreValue = Number(item.scoreValue || 0)
          const countNum = Number(item.countNum || 1)
          return {
            recordId: Number(item.recordId),
            recordedAt,
            timeText: timeText || this.data.selectedHourText,
            countNum,
            countText: countNum > 1 ? `${countNum}次` : '1次',
            scoreText: scoreValue > 0 ? `+${scoreValue}分` : `${scoreValue}分`,
          }
        })
        this.setData({ hourRecords, isRecordLoading: false })
      })
      .catch((error) => {
        this.setData({ isRecordLoading: false })
        wx.showToast({ title: error.message || '记录明细加载失败', icon: 'none' })
      })
  },

  closeRecordSheet() {
    this.setData({
      isRecordSheetVisible: false,
      isRecordLoading: false,
      selectedHour: null,
      selectedHourText: '',
      hourRecords: [],
    })
  },

  // 删除单条记录前二次确认，避免误删历史数据。
  confirmDeleteRecord(event) {
    const recordId = Number(event.currentTarget.dataset.id)
    const record = this.data.hourRecords.find((item) => item.recordId === recordId)
    if (!record) return

    wx.showModal({
      title: '删除这条记录？',
      content: `将删除 ${record.timeText} 的这一次记录，不会删除习惯项。`,
      confirmText: '删除',
      confirmColor: '#D84F49',
      cancelText: '取消',
      success: (res) => {
        if (res.confirm) {
          this.deleteRecord(recordId)
        }
      },
    })
  },

  deleteRecord(recordId) {
    const user = app.globalData.user || wx.getStorageSync('badup.cached.user') || null
    const userId = user && user.userId
    if (!userId) {
      wx.showToast({ title: '用户信息异常，请重新打开小程序', icon: 'none' })
      return
    }

    wx.showLoading({ title: '删除中' })
    api.deleteBehaviorRecord(userId, recordId)
      .then(() => {
        wx.hideLoading()
        wx.showToast({ title: '已删除', icon: 'success' })
        const change = this.markRecordStatsChanged()
        this.notifyPreviousStatPages(change)
        this.reloadCurrentHourRecords()
        this.load()
      })
      .catch((error) => {
        wx.hideLoading()
        wx.showToast({ title: error.message || '删除失败', icon: 'none' })
      })
  },

  // 只在删除成功后标记统计变更，供返回月/年页面时精准刷新。
  markRecordStatsChanged() {
    const { behavior, date } = this.data
    if (!behavior || !date) return null

    const parts = date.split('-')
    const year = Number(parts[0])
    const month = Number(parts[1])
    const current = app.globalData.recordStatsChange || { token: 0 }

    const change = {
      token: Number(current.token || 0) + 1,
      behaviorId: Number(behavior.behaviorId),
      recordDate: date,
      year,
      month,
    }
    app.globalData.recordStatsChange = change
    return change
  },

  // 直接通知页面栈里的月/年页面刷新。
  // 这样即使返回时 onShow 没有按预期触发，上一页的数据也已经在后台更新。
  notifyPreviousStatPages(change) {
    if (!change) return

    const pages = getCurrentPages()
    pages.forEach((page) => {
      const route = page.route || ''
      const data = page.data || {}
      const behavior = data.behavior

      if (
        route === 'pages/month-detail/month-detail' &&
        behavior &&
        Number(behavior.behaviorId) === Number(change.behaviorId) &&
        Number(data.year) === Number(change.year) &&
        Number(data.month) === Number(change.month)
      ) {
        page.handledRecordChangeToken = change.token
        if (typeof page.load === 'function') {
          page.load()
        }
      }

      if (
        route === 'pages/year-detail/year-detail' &&
        behavior &&
        Number(behavior.behaviorId) === Number(change.behaviorId) &&
        Number(data.year) === Number(change.year)
      ) {
        page.handledRecordChangeToken = change.token
        if (typeof page.load === 'function') {
          page.load()
        }
      }
    })
  },

  reloadCurrentHourRecords() {
    const hour = this.data.selectedHour
    if (hour === null || hour === undefined) {
      return
    }

    const user = app.globalData.user || wx.getStorageSync('badup.cached.user') || null
    const userId = user && user.userId
    const { behavior, date } = this.data
    if (!userId || !behavior || !date) {
      return
    }

    this.setData({ isRecordLoading: true })
    api.fetchHourRecords(userId, behavior.behaviorId, date, hour)
      .then((list) => {
        const hourRecords = list.map((item) => {
          const recordedAt = item.recordedAt || ''
          const timeText = recordedAt.length >= 16 ? recordedAt.slice(11, 16) : recordedAt
          const scoreValue = Number(item.scoreValue || 0)
          const countNum = Number(item.countNum || 1)
          return {
            recordId: Number(item.recordId),
            recordedAt,
            timeText: timeText || this.data.selectedHourText,
            countNum,
            countText: countNum > 1 ? `${countNum}次` : '1次',
            scoreText: scoreValue > 0 ? `+${scoreValue}分` : `${scoreValue}分`,
          }
        })
        this.setData({
          hourRecords,
          isRecordLoading: false,
          isRecordSheetVisible: hourRecords.length > 0,
        })
      })
      .catch((error) => {
        this.setData({ isRecordLoading: false })
        wx.showToast({ title: error.message || '刷新失败', icon: 'none' })
      })
  },

  // 把 2026-04-24 转成 2026年4月24日，便于做页面标题。
  toChineseDate(date) {
    const parts = date.split('-')
    if (parts.length !== 3) return date
    return `${Number(parts[0])}年${Number(parts[1])}月${Number(parts[2])}日`
  },
})
