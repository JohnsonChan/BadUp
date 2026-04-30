Component({
  options: {
    // 允许外部页面传入 left / center / right 三个 slot。
    multipleSlots: true
  },
  properties: {
    extClass: {
      type: String,
      value: ''
    },
    title: {
      type: String,
      value: ''
    },
    background: {
      type: String,
      value: ''
    },
    color: {
      type: String,
      value: ''
    },
    back: {
      type: Boolean,
      value: true
    },
    loading: {
      type: Boolean,
      value: false
    },
    homeButton: {
      type: Boolean,
      value: false,
    },
    animated: {
      // show 切换时，是否带透明度动画。
      type: Boolean,
      value: true
    },
    show: {
      // 是否显示导航栏；隐藏时仍然保留占位高度。
      type: Boolean,
      value: true,
      observer: '_showChange'
    },
    // back 为 true 时，返回的页面深度。
    delta: {
      type: Number,
      value: 1
    },
  },
  data: {
    displayStyle: ''
  },
  lifetimes: {
    attached() {
      // 根据微信右上角胶囊按钮的位置动态计算标题栏安全区域：
      // 1. 标题需要避开胶囊
      // 2. 右侧自定义按钮要显示在胶囊左边
      const rect = wx.getMenuButtonBoundingClientRect()
      const platform = (wx.getDeviceInfo() || wx.getSystemInfoSync()).platform
      const isAndroid = platform === 'android'
      const isDevtools = platform === 'devtools'
      const { windowWidth, safeArea: { top = 0, bottom = 0 } = {} } = wx.getWindowInfo() || wx.getSystemInfoSync()
      const capsuleSpace = windowWidth - rect.left
      const titleSideSpace = Math.max(capsuleSpace, rect.width + 24)
      this.setData({
        ios: !isAndroid,
        titlePadding: `padding-left: ${titleSideSpace}px; padding-right: ${titleSideSpace}px;`,
        leftWidth: `width: ${titleSideSpace}px`,
        rightStyle: `right: ${capsuleSpace}px; width: ${titleSideSpace}px;`,
        safeAreaTop: isDevtools || isAndroid ? `height: calc(var(--height) + ${top}px); padding-top: ${top}px` : ``
      })
    },
  },
  methods: {
    // 根据 show / animated 组合出最终样式。
    _showChange(show) {
      const animated = this.data.animated
      let displayStyle = ''
      if (animated) {
        displayStyle = `opacity: ${show ? '1' : '0'
          };transition:opacity 0.5s;`
      } else {
        displayStyle = `display: ${show ? '' : 'none'}`
      }
      this.setData({
        displayStyle
      })
    },

    // 默认返回上一页；页面也可以监听 back 事件做额外处理。
    back() {
      const data = this.data
      if (data.delta) {
        wx.navigateBack({
          delta: data.delta
        })
      }
      this.triggerEvent('back', { delta: data.delta }, {})
    }
  },
})
