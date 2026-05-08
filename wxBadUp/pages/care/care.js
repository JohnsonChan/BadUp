const api = require('../../utils/api')

const app = getApp()

const permissions = [
  { value: 1, name: '低权限', desc: '授权查看我的记录' },
  { value: 2, name: '中权限', desc: '授权修改/查看我的记录' },
  { value: 3, name: '高权限', desc: '授权修改/查看我的记录（我只能查看）' },
]

Page({
  data: {
    user: null,
    careCodeInput: '',
    selectedPermission: 1,
    permissions,

    careAsGuardian: [],
    careAsCared: [],

    isLoading: false,
    remarkModal: null,
    rejectModal: null,
    permissionModal: null,
  },

  onShow() {
    const user = app.globalData.user || wx.getStorageSync('badup.cached.user') || null
    this.setData({ user })
    if (user && user.userId && user.careCode) {
      this.loadAll()
      return
    }

    // 旧缓存里没有 careCode 时，重新登录一次从服务端拿临时生成的呵护码。
    api.loginOrRegister()
      .then((freshUser) => {
        app.globalData.user = freshUser
        wx.setStorageSync('badup.cached.user', freshUser)
        this.setData({ user: freshUser })
        this.loadAll()
      })
      .catch((error) => {
        this.showError(error, '用户信息刷新失败')
      })
  },

  loadAll() {
    const userId = this.data.user && this.data.user.userId
    if (!userId) return

    this.setData({ isLoading: true })
    api.fetchCareList(userId)
      .then((careRes) => {
        this.setData({
          careAsGuardian: this.normalizeCareRows(careRes.careAsGuardian || [], 'guardian'),
          careAsCared: this.normalizeCareRows(careRes.careAsCared || [], 'cared'),
        })
      })
      .catch((error) => {
        this.showError(error, '加载失败')
      })
      .finally(() => {
        this.setData({ isLoading: false })
      })
  },

  normalizeCareRows(list, mode) {
    const userId = Number(this.data.user && this.data.user.userId)
    return list.map((item) => {
      const guardianUserId = Number(item.guardianUserId)
      const caredUserId = Number(item.caredUserId)
      const guardianName = item.guardianUserName || `种子${guardianUserId}`
      const caredName = item.caredUserName || `种子${caredUserId}`
      const displayName = item.displayName || (mode === 'guardian' ? caredName : guardianName)
      const status = Number(item.status || 0)
      const statusClass = status === 1 ? 'accepted' : (status === 2 ? 'rejected' : 'pending')
      let relationText = mode === 'guardian' ? `正在呵护${displayName}` : `${displayName}正在呵护我`

      if (mode === 'guardian' && status === 0 && Number(item.requesterUserId) !== userId) {
        relationText = `${displayName}请求你呵护`
      } else if (mode === 'cared' && status === 0) {
        relationText = `等待${displayName}同意呵护我`
      } else if (mode === 'cared' && status === 2) {
        relationText = `${displayName}已拒绝呵护我`
      }

      return {
        ...item,
        status,
        statusClass,
        relationText,
        canUpdatePermission: status === 1 && Number(item.requesterUserId) === userId,
      }
    })
  },

  copyCareCode() {
    const careCode = this.data.user && this.data.user.careCode
    if (!careCode) {
      wx.showToast({ title: '呵护码暂不可用，请重新进入小程序', icon: 'none' })
      return
    }

    wx.setClipboardData({
      data: String(careCode),
      success: () => wx.showToast({ title: '呵护码已复制', icon: 'success' }),
    })
  },

  onCareCodeInput(event) {
    this.setData({ careCodeInput: String(event.detail.value || '').trim().toUpperCase() })
  },

  selectPermission(event) {
    this.setData({ selectedPermission: Number(event.currentTarget.dataset.value) })
  },

  requestCare() {
    const userId = this.data.user && this.data.user.userId
    const careCode = this.data.careCodeInput
    if (!userId) return
    if (!/^[0-9A-Z]{6}$/.test(careCode)) {
      wx.showToast({ title: '请输入6位呵护码', icon: 'none' })
      return
    }

    api.requestCare(userId, careCode, this.data.selectedPermission)
      .then(() => {
        wx.showToast({ title: '已发送申请', icon: 'success' })
        this.setData({ careCodeInput: '' })
        this.loadAll()
      })
      .catch((error) => {
        this.showError(error, '申请失败')
      })
  },

  acceptCare(event) {
    const userId = this.data.user && this.data.user.userId
    const careId = Number(event.currentTarget.dataset.id)
    if (!userId || !careId) return

    api.respondCare(userId, careId, 'accept')
      .then(() => {
        wx.showToast({ title: '已同意', icon: 'success' })
        this.loadAll()
      })
      .catch((error) => {
        this.showError(error, '处理失败')
      })
  },

  openRejectModal(event) {
    this.setData({
      rejectModal: {
        careId: Number(event.currentTarget.dataset.id),
        value: '',
      },
    })
  },

  onRejectReasonInput(event) {
    if (!this.data.rejectModal) return
    this.setData({
      rejectModal: {
        ...this.data.rejectModal,
        value: event.detail.value,
      },
    })
  },

  closeRejectModal() {
    this.setData({ rejectModal: null })
  },

  saveReject() {
    const userId = this.data.user && this.data.user.userId
    const modal = this.data.rejectModal
    const reason = modal ? String(modal.value || '').trim() : ''
    if (!userId || !modal) return
    if (!reason) {
      wx.showToast({ title: '请填写拒绝原因', icon: 'none' })
      return
    }

    api.respondCare(userId, modal.careId, 'reject', reason)
      .then(() => {
        wx.showToast({ title: '已拒绝', icon: 'success' })
        this.setData({ rejectModal: null })
        this.loadAll()
      })
      .catch((error) => {
        this.showError(error, '处理失败')
      })
  },

  openCaredHome(event) {
    const userId = Number(event.currentTarget.dataset.userid)
    const name = event.currentTarget.dataset.name || ''
    const permissionLevel = Number(event.currentTarget.dataset.permission || 1)
    if (!userId) return

    wx.navigateTo({
      url: `/pages/index/index?subjectUserId=${userId}&subjectName=${encodeURIComponent(name)}&permissionLevel=${permissionLevel}`,
    })
  },

  openRemarkModal(event) {
    this.setData({
      remarkModal: {
        id: Number(event.currentTarget.dataset.id),
        value: event.currentTarget.dataset.value || '',
        title: event.currentTarget.dataset.title || '修改备注',
      },
    })
  },

  onRemarkInput(event) {
    if (!this.data.remarkModal) return
    this.setData({
      remarkModal: {
        ...this.data.remarkModal,
        value: event.detail.value,
      },
    })
  },

  closeRemarkModal() {
    this.setData({ remarkModal: null })
  },

  saveRemark() {
    const userId = this.data.user && this.data.user.userId
    const modal = this.data.remarkModal
    if (!userId || !modal) return

    api.updateCareRemark(userId, modal.id, modal.value)
      .then(() => {
        wx.showToast({ title: '已保存', icon: 'success' })
        this.setData({ remarkModal: null })
        this.loadAll()
      })
      .catch((error) => {
        this.showError(error, '保存失败')
      })
  },

  openPermissionModal(event) {
    this.setData({
      permissionModal: {
        id: Number(event.currentTarget.dataset.id),
        value: Number(event.currentTarget.dataset.permission || 1),
      },
    })
  },

  selectModalPermission(event) {
    if (!this.data.permissionModal) return
    this.setData({
      permissionModal: {
        ...this.data.permissionModal,
        value: Number(event.currentTarget.dataset.value),
      },
    })
  },

  closePermissionModal() {
    this.setData({ permissionModal: null })
  },

  savePermission() {
    const userId = this.data.user && this.data.user.userId
    const modal = this.data.permissionModal
    if (!userId || !modal) return

    api.updateCarePermission(userId, modal.id, modal.value)
      .then(() => {
        wx.showToast({ title: '权限已更新', icon: 'success' })
        this.setData({ permissionModal: null })
        this.loadAll()
      })
      .catch((error) => {
        this.showError(error, '保存失败')
      })
  },

  showError(error, fallback) {
    wx.showModal({
      title: fallback,
      content: error && error.message ? String(error.message) : fallback,
      showCancel: false,
      confirmText: '知道了',
    })
  },
})
