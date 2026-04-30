const api = require('../../utils/api')

Page({
  data: {
    behavior: null,
    date: '',
    dayTitle: '',
    // 固定渲染 24 个小时段。
    hours: [],
    totalCount: 0,
  },

  onLoad(options) {
    // 日详情只需要行为信息和日期。
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
        }))
        const totalCount = hours.reduce((sum, item) => sum + item.count, 0)
        this.setData({ hours, totalCount })
      })
      .catch((error) => {
        wx.showToast({ title: error.message || '加载失败', icon: 'none' })
      })
  },

  // 把 2026-04-24 转成 2026年4月24日，便于做页面标题。
  toChineseDate(date) {
    const parts = date.split('-')
    if (parts.length !== 3) return date
    return `${Number(parts[0])}年${Number(parts[1])}月${Number(parts[2])}日`
  },
})
