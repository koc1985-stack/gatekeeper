// MV3 service worker — kept intentionally thin. content.js talks straight to the native
// handler via browser.runtime.sendNativeMessage, so no relaying is needed here.
browser.runtime.onInstalled.addListener(() => {
  console.log("Bekle: Alışveriş Freni yüklendi.");
});
