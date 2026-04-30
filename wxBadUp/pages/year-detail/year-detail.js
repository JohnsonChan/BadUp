const api = require('../../utils/api')

Page({
  data: {
    behavior: null,
    year: new Date().getFullYear(),
    // summaries 固定为 12 项，每项对应一个月。
    summaries: [],
    totalCount: 0,
  },

  onLoad(options) {
    // 详情页所需的行为信息由首页通过 query 传入。
    const behavior = {
      behaviorId: Number(options.behaviorId),
      behaviorName: decodeURIComponent(options.name || ''),
      behaviorDesc: decodeURIComponent(options.desc || ''),
      colorHex: decodeURIComponent(options.color || '#F55F52'),
    }
    this.setData({ behavior })
    this.load()
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
    api.fetchYearStats(behavior.behaviorId, year)
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

  // 年 -> 月详情。
  goMonth(event) {
    const month = Number(event.currentTarget.dataset.month)
    const { behavior, year } = this.data
    wx.navigateTo({
      url: `/pages/month-detail/month-detail?behaviorId=${behavior.behaviorId}&name=${encodeURIComponent(behavior.behaviorName)}&desc=${encodeURIComponent(behavior.behaviorDesc)}&color=${encodeURIComponent(behavior.colorHex)}&year=${year}&month=${month}`,
    })
  },
})
