// 小程序不能直接用 web-view 打开包内 HTML 文件。
// 这里把 static 目录里的协议正文转成 rich-text 可渲染的本地内容。
const baseStyle = 'font-size:30rpx;line-height:1.75;color:#33413e;word-break:break-all;'
const h1Style = 'font-size:38rpx;line-height:1.35;text-align:center;margin:0 0 34rpx;color:#182827;font-weight:900;'
const h2Style = 'font-size:31rpx;line-height:1.45;margin:34rpx 0 14rpx;color:#182827;font-weight:900;'
const pStyle = 'margin:0 0 14rpx;text-align:justify;'

const privacyPolicy = `
<div style="${baseStyle}">
  <h1 style="${h1Style}">芽记-日常打卡次数 隐私保护说明</h1>

  <h2 style="${h2Style}">一、指引说明</h2>
  <p style="${pStyle}">本指引由「芽记-日常打卡次数」开发者（个人主体）制定，用于说明在使用小程序时，如何处理用户的个人信息。本小程序遵循合法、正当、必要、诚信原则处理信息。</p>

  <h2 style="${h2Style}">二、开发者处理的信息</h2>
  <p style="${pStyle}">根据法律规定，开发者仅处理实现小程序功能所必要的信息，不收集多余信息。</p>
  <p style="${pStyle}">为实现小程序登录、识别用户、展示个人身份，开发者仅收集你的<strong>微信昵称</strong>。</p>
  <p style="${pStyle}">本小程序<strong>不收集</strong>手机号、身份证号、性别、地区、位置、相册、相机、通讯录等任何其他个人信息。</p>

  <h2 style="${h2Style}">三、第三方插件信息/SDK信息</h2>
  <p style="${pStyle}">本小程序<strong>未接入任何第三方插件、未使用任何第三方SDK</strong>，无第三方处理用户个人信息。</p>

  <h2 style="${h2Style}">四、你的权益</h2>
  <p style="${pStyle}">开发者承诺，除法律法规另有规定外，对你的信息的保存期限为实现处理目的所必要的最短时间。</p>
  <p style="${pStyle}">你可通过小程序主页右上角“…”—“设置”—点击对应信息权限—选择“不允许”，撤回授权。</p>
  <p style="${pStyle}">关于你的个人信息，你可联系开发者行使查阅、复制、更正、删除等法定权利。</p>

  <h2 style="${h2Style}">五、开发者对信息的存储</h2>
  <p style="${pStyle}">开发者承诺，除法律法规另有规定外，对你的信息的保存期限为实现处理目的所必要的最短时间。</p>
  <p style="${pStyle}">你的信息仅存储在<strong>中国大陆</strong>境内，不进行跨境传输。</p>

  <h2 style="${h2Style}">六、信息的使用规则</h2>
  <p style="${pStyle}">开发者仅在本指引明示的用途内使用收集的信息，仅用于登录识别、展示用户身份、提供打卡记录服务。</p>
  <p style="${pStyle}">如开发者使用信息超出本指引目的或合理范围，将再次告知并征得你的明示同意。</p>

  <h2 style="${h2Style}">七、信息对外提供</h2>
  <p style="${pStyle}">开发者承诺，不会主动共享或转让你的信息至任何第三方。如确需共享或转让，将直接征得你的单独同意。</p>
  <p style="${pStyle}">开发者不会对外公开披露你的信息，如必须公开披露时，将向你告知目的、类型并征得单独同意。</p>

  <h2 style="${h2Style}">八、联系我们</h2>
  <p style="${pStyle}">如果你认为开发者未遵守本指引约定、有投诉建议，或涉及未成年人个人信息保护问题，可通过以下方式联系开发者，也可向微信平台投诉。</p>
  <p style="${pStyle}">联系邮箱：chenrs2024@gmail.com</p>

  <h2 style="${h2Style}">九、政策更新</h2>
  <p style="${pStyle}">更新日期：2026-05-09</p>
  <p style="${pStyle}">生效日期：2026-05-09</p>
</div>
`

const userAgreement = `
<div style="${baseStyle}">
  <h1 style="${h1Style}">用户协议</h1>

  <h2 style="${h2Style}">一、协议主体</h2>
  <p style="${pStyle}">本用户协议由您与【芽记-日常打卡次数】开发者（个人主体）共同签订。</p>

  <h2 style="${h2Style}">二、服务内容</h2>
  <p style="${pStyle}">本小程序为用户提供【打卡好习惯，记录坏习惯，和朋友相互守护成长的】服务。</p>

  <h2 style="${h2Style}">三、用户义务</h2>
  <p style="${pStyle}">1. 用户不得利用本小程序从事违法违规行为。</p>
  <p style="${pStyle}">2. 用户不得恶意攻击、破解、干扰小程序正常运行。</p>

  <h2 style="${h2Style}">四、免责声明</h2>
  <p style="${pStyle}">1. 本小程序仅提供功能服务，不对用户使用行为产生的后果承担责任。</p>
  <p style="${pStyle}">2. 因网络、设备、第三方平台等问题导致的服务中断，开发者不承担责任。</p>

  <h2 style="${h2Style}">五、服务变更与终止</h2>
  <p style="${pStyle}">开发者有权随时调整、暂停或终止服务，无需提前通知。</p>

  <h2 style="${h2Style}">六、联系方式</h2>
  <p style="${pStyle}">开发者：陈桌升</p>
  <p style="${pStyle}">联系邮箱：chenrs2024@gmail.com</p>
</div>
`

const docs = {
  privacy: {
    title: '隐私政策',
    nodes: privacyPolicy,
  },
  agreement: {
    title: '用户协议',
    nodes: userAgreement,
  },
}

function getLegalDoc(type) {
  return docs[type] || docs.privacy
}

module.exports = {
  getLegalDoc,
}
