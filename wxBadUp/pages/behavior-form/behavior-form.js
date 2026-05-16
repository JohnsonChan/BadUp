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
  { hex: '#B57EDC', name: '薰衣草' },
  { hex: '#B8E986', name: '柠檬绿' },
]

// 首屏只展示 7 个常用颜色，第 8 个作为“更多选择”入口。
const primaryPalette = [
  ...fullPalette.slice(0, 7),
  { type: 'more', hex: '__more__', name: '更多选择' },
]
const primaryColorHexes = fullPalette.slice(0, 7).map((item) => item.hex)

// 单次记录分值规则：
// 好习惯只能选择 +1 到 +5，默认 +1；
// 坏习惯只能选择 -1 到 -5，默认 -2。
const defaultGoodScoreUnit = 1
const defaultBadScoreUnit = -2
const goodScoreOptions = [1, 2, 3, 4, 5].map((value) => ({ value, text: `+${value} 分` }))
const badScoreOptions = [-1, -2, -3, -4, -5].map((value) => ({ value, text: `${value} 分` }))

function formatScoreUnit(scoreUnit) {
  return scoreUnit > 0 ? `+${scoreUnit}` : `${scoreUnit}`
}

function normalizeBehaviorType(value) {
  return Number(value) === 1 ? 1 : -1
}

function normalizeScoreUnit(value, behaviorType) {
  const type = normalizeBehaviorType(behaviorType)
  const score = Number(value)

  if (type === 1) {
    return Number.isFinite(score) && score >= 1 && score <= 5 ? Math.round(score) : defaultGoodScoreUnit
  }

  if (Number.isFinite(score)) {
    const negativeScore = score > 0 ? -score : score
    if (negativeScore <= -1 && negativeScore >= -5) {
      return Math.round(negativeScore)
    }
  }
  return defaultBadScoreUnit
}

function buildBehaviorTypes(goodScoreUnit, badScoreUnit) {
  return [
    { value: 1, name: '好习惯', desc: `记录一次 ${formatScoreUnit(goodScoreUnit)} 分` },
    { value: -1, name: '坏习惯', desc: `记录一次 ${formatScoreUnit(badScoreUnit)} 分` },
  ]
}

const behaviorTypes = buildBehaviorTypes(defaultGoodScoreUnit, defaultBadScoreUnit)

function scoreOptionsForType(behaviorType) {
  return normalizeBehaviorType(behaviorType) === 1 ? goodScoreOptions : badScoreOptions
}

function scoreSheetTitleForType(behaviorType) {
  return normalizeBehaviorType(behaviorType) === 1 ? '选择好习惯分数' : '选择坏习惯分数'
}

function scoreSheetTipForType(behaviorType) {
  return normalizeBehaviorType(behaviorType) === 1
    ? '好习惯记录一次会增加对应分数'
    : '坏习惯记录一次会扣除对应分数'
}

function scoreSheetClassForType(behaviorType) {
  return normalizeBehaviorType(behaviorType) === 1 ? 'good' : 'bad'
}

Page({
  data: {
    // add: 新增习惯；edit: 编辑已有习惯。
    mode: 'add',
    behaviorId: null,
    subjectUserId: null,
    name: '',
    desc: '',
    colorHex: '#F55F52',
    behaviorType: 1,
    scoreUnit: defaultGoodScoreUnit,
    goodScoreUnit: defaultGoodScoreUnit,
    badScoreUnit: defaultBadScoreUnit,

    // 编辑模式下保留原值，用于判断是否真的发生修改。
    original: null,
    behaviorTypes,
    scoreOptions: goodScoreOptions,
    scoreSheetTitle: scoreSheetTitleForType(1),
    scoreSheetTip: scoreSheetTipForType(1),
    scoreSheetClass: scoreSheetClassForType(1),
    scoreSheetType: 1,
    palette: primaryPalette,
    fullPalette,
    isScoreSheetVisible: false,
    isMoreColorsVisible: false,
    isMoreColorSelected: false,
    isSaving: false,
  },

  onLoad(options) {
    const subjectUserId = Number(options.subjectUserId)
    if (Number.isFinite(subjectUserId) && subjectUserId > 0) {
      this.setData({ subjectUserId })
    }

    // 编辑模式下，从首页传入 query 初始化表单。
    if (options.mode === 'edit') {
      const behaviorId = Number(options.behaviorId)
      const name = decodeURIComponent(options.name || '')
      const desc = decodeURIComponent(options.desc || '')
      const colorHex = decodeURIComponent(options.color || '#F55F52')
      const behaviorType = normalizeBehaviorType(options.type)
      const scoreUnit = normalizeScoreUnit(options.scoreUnit, behaviorType)
      const goodScoreUnit = behaviorType === 1 ? scoreUnit : defaultGoodScoreUnit
      const badScoreUnit = behaviorType === -1 ? scoreUnit : defaultBadScoreUnit
      this.setData({
        mode: 'edit',
        behaviorId,
        name,
        desc,
        colorHex,
        behaviorType,
        scoreUnit,
        goodScoreUnit,
        badScoreUnit,
        behaviorTypes: buildBehaviorTypes(goodScoreUnit, badScoreUnit),
        scoreOptions: scoreOptionsForType(behaviorType),
        scoreSheetTitle: scoreSheetTitleForType(behaviorType),
        scoreSheetTip: scoreSheetTipForType(behaviorType),
        scoreSheetClass: scoreSheetClassForType(behaviorType),
        scoreSheetType: behaviorType,
        original: { name, desc, colorHex, behaviorType, scoreUnit },
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
    const nextType = normalizeBehaviorType(event.currentTarget.dataset.type)

    // 编辑页保持“类型和分值都不可改”：分值是创建习惯时敲定的历史规则。
    if (this.data.mode === 'edit') {
      return
    }

    const nextScoreUnit = nextType === 1 ? this.data.goodScoreUnit : this.data.badScoreUnit
    this.setData({
      behaviorType: nextType,
      scoreUnit: nextScoreUnit,
      scoreOptions: scoreOptionsForType(nextType),
      scoreSheetTitle: scoreSheetTitleForType(nextType),
      scoreSheetTip: scoreSheetTipForType(nextType),
      scoreSheetClass: scoreSheetClassForType(nextType),
      scoreSheetType: nextType,
      behaviorTypes: buildBehaviorTypes(this.data.goodScoreUnit, this.data.badScoreUnit),
      isScoreSheetVisible: true,
    })
  },

  // 分数弹层中选择具体分值；好习惯保存正数，坏习惯保存负数。
  selectScoreUnit(event) {
    const scoreUnit = normalizeScoreUnit(event.currentTarget.dataset.value, this.data.scoreSheetType)
    const nextData = {
      scoreUnit,
      isScoreSheetVisible: false,
    }

    if (this.data.scoreSheetType === 1) {
      nextData.goodScoreUnit = scoreUnit
      nextData.behaviorTypes = buildBehaviorTypes(scoreUnit, this.data.badScoreUnit)
    } else {
      nextData.badScoreUnit = scoreUnit
      nextData.behaviorTypes = buildBehaviorTypes(this.data.goodScoreUnit, scoreUnit)
    }

    this.setData(nextData)
  },

  closeScoreSheet() {
    this.setData({ isScoreSheetVisible: false })
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
      ? api.updateBehavior(user.userId, this.data.behaviorId, name, desc, this.data.colorHex, this.data.subjectUserId)
      : api.addBehavior(user.userId, name, desc, this.data.colorHex, this.data.behaviorType, this.data.scoreUnit, this.data.subjectUserId)

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
