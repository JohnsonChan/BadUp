const { getLegalDoc } = require('../../utils/legal-docs')

Page({
  data: {
    title: '隐私政策',
    nodes: '',
  },

  onLoad(options) {
    const doc = getLegalDoc((options && options.type) || 'privacy')
    this.setData({
      title: doc.title,
      nodes: doc.nodes,
    })
  },
})
