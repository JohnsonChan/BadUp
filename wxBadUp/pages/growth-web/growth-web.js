const stages = [
  { name: '静谧萌发', desc: '生命在泥土中沉睡，积蓄破土的力量。' },
  { name: '破土嫩芽', desc: '勇敢地顶开泥土，向世界问好。' },
  { name: '写实双叶', desc: '舒展的嫩芽，汲取岁月精华。' },
  { name: '韧性初显', desc: '躯干逐渐挺拔，无惧微风掠过。' },
  { name: '向光生长', desc: '每一个分叉，都是向天空的探索。' },
  { name: '少年青葱', desc: '枝干交叠错落，初现生命繁华。' },
  { name: '繁枝错落', desc: '岁月留下痕迹，构筑独特风骨。' },
  { name: '绿意叠嶂', desc: '叶影在阳光下，交织光阴故事。' },
  { name: '生命礼赞', desc: '厚重而苍劲，守护脚下土地。' },
  { name: '参天屹立', desc: '阅尽千帆，归于大自然的平静。' },
]

function getStageFromIndex(index) {
  if (index <= 0) return 0
  if (index <= 10) return 1
  if (index <= 50) return 2
  if (index <= 100) return 3
  if (index <= 300) return 4
  if (index <= 500) return 5
  if (index <= 1000) return 6
  if (index <= 2000) return 7
  if (index <= 3000) return 8
  return 9
}

function noise(seed) {
  const raw = Math.sin(seed * 12.9898) * 43758.5453
  return raw - Math.floor(raw)
}

Page({
  data: {
    indexValue: 0,
    stageName: stages[0].name,
    stageDesc: stages[0].desc,
    progressPercent: 0,
  },

  onLoad(options) {
    // 与 phpBadUp/yaji.html 保持一致：index 决定阶段，进度条按 0-5000 显示。
    const rawIndex = Number(options.index || 0)
    const indexValue = Number.isFinite(rawIndex) ? rawIndex : 0
    const clampedIndex = Math.max(0, Math.min(5000, indexValue))
    const stageIndex = getStageFromIndex(indexValue)
    const stage = stages[stageIndex]

    this.currentStage = stageIndex
    this.setData({
      indexValue,
      stageName: stage.name,
      stageDesc: stage.desc,
      progressPercent: (clampedIndex / 5000) * 100,
    })
  },

  onReady() {
    this.drawTree()
  },

  onResize() {
    this.drawTree()
  },

  drawTree() {
    const query = wx.createSelectorQuery().in(this)
    query.select('#treeCanvas').fields({ node: true, size: true }).exec((res) => {
      const canvasInfo = res && res[0]
      if (!canvasInfo || !canvasInfo.node || !canvasInfo.width || !canvasInfo.height) {
        setTimeout(() => this.drawTree(), 80)
        return
      }

      const canvas = canvasInfo.node
      const ctx = canvas.getContext('2d')
      const systemInfo = wx.getWindowInfo ? wx.getWindowInfo() : wx.getSystemInfoSync()
      const dpr = systemInfo.pixelRatio || 1
      const width = canvasInfo.width
      const height = canvasInfo.height

      canvas.width = width * dpr
      canvas.height = height * dpr
      ctx.scale(dpr, dpr)
      ctx.clearRect(0, 0, width, height)

      const viewSize = Math.min(width, height) * 0.86
      const offsetX = (width - viewSize) / 2
      const offsetY = (height - viewSize) / 2

      ctx.save()
      ctx.translate(offsetX, offsetY)
      this.renderTree(ctx, viewSize, this.currentStage || 0)
      ctx.restore()
    })
  },

  renderTree(ctx, viewSize, currentStage) {
    const baseX = viewSize / 2
    const baseY = viewSize - 35

    if (currentStage === 0) {
      this.drawSeed(ctx, baseX, baseY - 15)
      return
    }

    if (currentStage === 1) {
      ctx.strokeStyle = '#689f38'
      ctx.lineWidth = 5
      ctx.lineCap = 'round'
      ctx.beginPath()
      ctx.moveTo(baseX, baseY)
      ctx.quadraticCurveTo(baseX + 12, baseY - 20, baseX, baseY - 45)
      ctx.stroke()
      this.drawLeaf(ctx, baseX, baseY - 45, 0.1, 0.8, 1)
      return
    }

    const baseLen = (viewSize * 0.15) + (currentStage * 4)
    const baseWidth = 2.5 + (currentStage * 1.6)
    this.drawBranch(ctx, baseX, baseY, baseLen, 0, baseWidth, 1, currentStage)
  },

  drawSeed(ctx, x, y) {
    ctx.save()
    ctx.translate(x, y)
    ctx.rotate(-0.2)
    ctx.scale(10, 7)

    const seedGrad = ctx.createRadialGradient(-0.2, -0.42, 0.1, 0, 0, 1)
    seedGrad.addColorStop(0, '#a1887f')
    seedGrad.addColorStop(0.5, '#5d4037')
    seedGrad.addColorStop(1, '#2b160e')

    ctx.fillStyle = seedGrad
    ctx.beginPath()
    ctx.arc(0, 0, 1, 0, Math.PI * 2)
    ctx.fill()

    ctx.restore()

    ctx.save()
    ctx.translate(x, y)
    ctx.rotate(-0.2)
    ctx.translate(-3, -3)
    ctx.rotate(0.5)
    ctx.scale(4, 2)
    ctx.fillStyle = 'rgba(255, 255, 255, 0.15)'
    ctx.beginPath()
    ctx.arc(0, 0, 1, 0, Math.PI * 2)
    ctx.fill()
    ctx.restore()
  },

  drawLeaf(ctx, x, y, angle, scale, opacity) {
    ctx.save()
    ctx.translate(x, y)
    ctx.rotate(angle)
    ctx.scale(scale, scale)

    const grad = ctx.createRadialGradient(0, 5, 0, 0, 5, 15)
    grad.addColorStop(0, `rgba(165, 214, 167, ${opacity})`)
    grad.addColorStop(1, `rgba(27, 94, 32, ${opacity})`)

    ctx.beginPath()
    ctx.moveTo(0, 0)
    ctx.bezierCurveTo(8, -8, 12, 8, 0, 22)
    ctx.bezierCurveTo(-12, 8, -8, -8, 0, 0)
    ctx.fillStyle = grad
    ctx.fill()
    ctx.restore()
  },

  drawBranch(ctx, startX, startY, len, angle, width, level, maxLevel) {
    ctx.save()
    ctx.translate(startX, startY)
    ctx.rotate((angle * Math.PI) / 180)

    const trunkGrad = ctx.createLinearGradient(0, 0, width, 0)
    trunkGrad.addColorStop(0, '#3e2723')
    trunkGrad.addColorStop(0.5, '#5d4037')
    trunkGrad.addColorStop(1, '#3e2723')

    ctx.strokeStyle = trunkGrad
    ctx.lineWidth = width
    ctx.lineCap = 'round'
    ctx.beginPath()
    ctx.moveTo(0, 0)
    ctx.lineTo(0, -len)
    ctx.stroke()

    if (level >= maxLevel) {
      const count = 2 + (maxLevel > 5 ? 1 : 0)
      for (let index = 0; index < count; index += 1) {
        const leafNoise = noise((level + 1) * 31 + index * 17 + maxLevel)
        const leafAngle = (index - 1) * 0.7 + (leafNoise - 0.5) * 0.5
        this.drawLeaf(ctx, 0, -len, leafAngle, 0.6 + (level / 10), 0.9)
      }
      ctx.restore()
      return
    }

    const nextLen = len * (0.72 + (maxLevel * 0.005))
    const nextWidth = width * 0.7
    const spread = 22 + (maxLevel * 0.7)
    const leftJitter = noise(level * 19 + maxLevel * 7 + 1) * 3
    const rightJitter = noise(level * 23 + maxLevel * 11 + 2) * 3

    this.drawBranch(ctx, 0, -len, nextLen, spread + leftJitter, nextWidth, level + 1, maxLevel)
    this.drawBranch(ctx, 0, -len, nextLen, -spread - rightJitter, nextWidth, level + 1, maxLevel)
    ctx.restore()
  },
})
