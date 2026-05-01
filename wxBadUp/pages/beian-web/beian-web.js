const defaultBeianURL = 'https://beian.miit.gov.cn/'

Page({
  data: {
    url: defaultBeianURL,
  },

  onLoad(options) {
    const decodedURL = options && options.url ? decodeURIComponent(options.url) : defaultBeianURL
    this.setData({
      url: decodedURL || defaultBeianURL,
    })
  },
})
