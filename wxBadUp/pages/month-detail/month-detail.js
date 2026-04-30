const api = require('../../utils/api')
const dateUtil = require('../../utils/date')

Page({
  data: {
    behavior: null,
    year: 0,
    month: 0,

    // leadingDays 用来补齐月初前面的空白占位，
    // daySummaries 则是这个月每一天的统计结果。
    leadingDays: [],
    daySummaries: [],
    totalCount: 0,
    weekdays: ['日', '一', '二', '三', '四', '五', '六'],
  },

  onLoad(options) {
    // 从上一层页面接收行为信息和年月。
    const year = Number(options.year)
    const month = Number(options.month)
    const behavior = {
      behaviorId: Number(options.behaviorId),
      behaviorName: decodeURIComponent(options.name || ''),
      behaviorDesc: decodeURIComponent(options.desc || ''),
      colorHex: decodeURIComponent(options.color || '#F55F52'),
    }
    this.setData({ behavior, year, month })
    this.load()
  },

  // 构造月视图需要的完整日历数据。
  load() {
    const { behavior, year, month } = this.data
    if (!behavior) return

    // 计算这个月 1 号是星期几，用来补前导空白格。
    const firstDay = new Date(year, month - 1, 1).getDay()
    const leadingDays = Array.from({ length: firstDay }, (_, index) => ({
      id: `empty-${index}`,
    }))
    const dayCount = dateUtil.daysInMonth(year, month)

    api.fetchMonthStats(behavior.behaviorId, year, month)
      .then((list) => {
        // 先转成 day -> count 的映射，再生成完整的 1~月末数组。
        const counts = {}
        list.forEach((item) => {
          counts[Number(item.dayNum)] = Number(item.totalCount || 0)
        })

        const today = dateUtil.formatDate(new Date())
        const daySummaries = Array.from({ length: dayCount }, (_, index) => {
          const day = index + 1
          const date = dateUtil.formatDate(dateUtil.dateFromYMD(year, month, day))
          const count = counts[day] || 0
          return {
            day,
            date,
            count,
            isToday: date === today,
            dayStyle: date === today ? `background: ${behavior.colorHex};` : '',
            countText: count > 0 ? `${count}次` : '-',
            countColor: count > 0 ? behavior.colorHex : '#8b9693',
            barColor: count > 0 ? behavior.colorHex : 'rgba(0,0,0,0.10)',
          }
        })
        const totalCount = daySummaries.reduce((sum, item) => sum + item.count, 0)
        this.setData({ leadingDays, daySummaries, totalCount })
      })
      .catch((error) => {
        wx.showToast({ title: error.message || '加载失败', icon: 'none' })
      })
  },

  // 月 -> 日详情。
  goDay(event) {
    const day = Number(event.currentTarget.dataset.day)
    const { behavior, year, month } = this.data
    const date = dateUtil.formatDate(dateUtil.dateFromYMD(year, month, day))
    wx.navigateTo({
      url: `/pages/day-detail/day-detail?behaviorId=${behavior.behaviorId}&name=${encodeURIComponent(behavior.behaviorName)}&color=${encodeURIComponent(behavior.colorHex)}&date=${date}`,
    })
  },
})
