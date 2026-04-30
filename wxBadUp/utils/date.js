// 日期工具：统一小程序和 PHP 接口使用的日期格式。

// 补零，保证月/日/时分秒是两位数。
function pad(value) {
  return value < 10 ? `0${value}` : `${value}`
}

// 输出 YYYY-MM-DD。
function formatDate(date = new Date()) {
  return `${date.getFullYear()}-${pad(date.getMonth() + 1)}-${pad(date.getDate())}`
}

// 输出 YYYY-MM-DD HH:mm:ss。
function formatDateTime(date = new Date()) {
  return `${formatDate(date)} ${pad(date.getHours())}:${pad(date.getMinutes())}:${pad(date.getSeconds())}`
}

// 输出中文日期，用于首页标题展示。
function formatChineseDate(date = new Date()) {
  return `${date.getFullYear()}年${date.getMonth() + 1}月${date.getDate()}日`
}

// 获取某年某月有多少天。
function daysInMonth(year, month) {
  return new Date(year, month, 0).getDate()
}

// 用于生成指定年月日的 Date 对象。
function dateFromYMD(year, month, day) {
  return new Date(year, month - 1, day)
}

module.exports = {
  formatDate,
  formatDateTime,
  formatChineseDate,
  daysInMonth,
  dateFromYMD,
}
