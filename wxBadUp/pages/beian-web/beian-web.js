const defaultBeianURL = 'https://beian.miit.gov.cn/'

Page({
  data: {
    url: defaultBeianURL,
  },

  onLoad(options) {
    const decodedURL = options && options.url ? decodeURIComponent(options.url) : defaultBeianURL
    const title = options && options.title ? decodeURIComponent(options.title) : '备案信息'
    this.setData({
      url: decodedURL || defaultBeianURL,
    })
    wx.setNavigationBarTitle({ title })
  },
})
