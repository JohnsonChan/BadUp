const api = require('../../utils/api')

const app = getApp()

// 完整颜色板，与 iOS 版本保持一致。
const fullPalette = [
  { hex: '#F55F52', name: '珊瑚红' },
  { hex: '#F9B536', name: '橙黄' },
  { hex: '#31B3C5', name: '湖蓝' },
  { hex: '#6C7EF7', name: '钴蓝' },
  { hex: '#43C77A', name: '薄荷绿' },
  { hex: '#F56EA4', name: '粉红' },
  { hex: '#8C5CF6', name: '紫罗兰' },
  { hex: '#A66A43', name: '焦糖棕' },
  { hex: '#16A085', name: '青绿' },
  { hex: '#D35400', name: '南瓜橙' },
  { hex: '#C0392B', name: '砖红' },
  { hex: '#2C3E50', name: '深海军蓝' },
  { hex: '#7F8C8D', name: '石墨灰' },
  { hex: '#27AE60', name: '森林绿' },
  { hex: '#E84393', name: '洋红' },
  { hex: '#00A8FF', name: '天空蓝' },
  { hex: '#F1C40F', name: '明黄' },
  { hex: '#6D214F', name: '酒红' },
]

// 首屏只展示 7 个常用颜色，第 8 个作为“更多选择”入口。
const primaryPalette = [
  ...fullPalette.slice(0, 7),
  { type: 'more', hex: '__more__', name: '更多选择' },
]
const primaryColorHexes = fullPalette.slice(0, 7).map((item) => item.hex)
const behaviorTypes = [
  { value: 1, name: '好习惯', desc: '记录一次 +1 分' },
  { value: -1, name: '坏习惯', desc: '记录一次 -10 分' },
]

Page({
  data: {
    // add: 新增习惯；edit: 编辑已有习惯。
    mode: 'add',
    behaviorId: null,
    name: '',
    desc: '',
    colorHex: '#F55F52',
    behaviorType: 1,

    // 编辑模式下保留原值，用于判断是否真的发生修改。
    original: null,
    behaviorTypes,
    palette: primaryPalette,
    fullPalette,
    isMoreColorsVisible: false,
    isMoreColorSelected: false,
    isSaving: false,
  },

  onLoad(options) {
    // 编辑模式下，从首页传入 query 初始化表单。
    if (options.mode === 'edit') {
      const behaviorId = Number(options.behaviorId)
      const name = decodeURIComponent(options.name || '')
      const desc = decodeURIComponent(options.desc || '')
      const colorHex = decodeURIComponent(options.color || '#F55F52')
      const behaviorType = Number(options.type) === 1 ? 1 : -1
      this.setData({
        mode: 'edit',
        behaviorId,
        name,
        desc,
        colorHex,
        behaviorType,
        original: { name, desc, colorHex, behaviorType },
        isMoreColorSelected: !primaryColorHexes.includes(colorHex),
      })
    }
  },

  // 表单输入同步到 data，方便实时预览。
  onNameInput(event) {
    this.setData({ name: event.detail.value })
  },

  onDescInput(event) {
    this.setData({ desc: event.detail.value })
  },

  selectBehaviorType(event) {
    if (this.data.mode === 'edit') {
      return
    }
    this.setData({ behaviorType: Number(event.currentTarget.dataset.type) === 1 ? 1 : -1 })
  },

  // 选择颜色时，预览卡片会即时变化；更多入口会打开完整颜色板。
  selectColor(event) {
    const { hex, type } = event.currentTarget.dataset
    if (type === 'more') {
      this.setData({ isMoreColorsVisible: true })
      return
    }
    this.setData({
      colorHex: hex,
      isMoreColorSelected: false,
    })
  },

  selectMoreColor(event) {
    const colorHex = event.currentTarget.dataset.hex
    this.setData({
      colorHex,
      isMoreColorsVisible: false,
      isMoreColorSelected: !primaryColorHexes.includes(colorHex),
    })
  },

  closeMoreColors() {
    this.setData({ isMoreColorsVisible: false })
  },

  noop() {},

  // 新增和编辑共用一个保存入口。
  save() {
    const user = app.globalData.user || wx.getStorageSync('badup.cached.user')
    const name = this.data.name.trim()
    const desc = this.data.desc.trim()

    if (!user) {
      wx.showToast({ title: '用户信息异常', icon: 'none' })
      return
    }
    if (!name) {
      wx.showToast({ title: '请输入习惯名称', icon: 'none' })
      return
    }

    // 编辑模式下如果没有改动，直接返回，避免无意义调用接口。
    if (this.data.mode === 'edit' && this.hasNoChanges(name, desc)) {
      wx.navigateBack()
      return
    }

    this.setData({ isSaving: true })
    const task = this.data.mode === 'edit'
      ? api.updateBehavior(user.userId, this.data.behaviorId, name, desc, this.data.colorHex)
      : api.addBehavior(user.userId, name, desc, this.data.colorHex, this.data.behaviorType)

    task.then(() => {
      wx.navigateBack()
    }).catch((error) => {
      wx.showToast({ title: error.message || '保存失败', icon: 'none' })
    }).finally(() => {
      this.setData({ isSaving: false })
    })
  },

  // 判断编辑页内容是否与原始值完全一致。
  hasNoChanges(name, desc) {
    const original = this.data.original
    if (!original) return false
    return original.name === name
      && original.desc === desc
      && original.colorHex === this.data.colorHex
  },
})
