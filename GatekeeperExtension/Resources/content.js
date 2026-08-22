// Bekle content script. Runs on the sites listed in manifest.json. Tries to find the checkout
// page's confirm button and total price via site-selectors.js's per-site config, then its
// text/price-shape-based generic fallbacks; if even those find nothing, a persistent floating
// badge still lets the user trigger the reflection flow manually. This file could not be tested
// against the live sites — see site-selectors.js header.
(function () {
  "use strict";

  const hostname = window.location.hostname;
  const siteConfig = bekleMatchSite(hostname);
  const genericCheckoutPattern = /(checkout|sepet|basket|cart|siparis|odeme)/i;
  const urlLooksLikeCheckout = siteConfig
    ? siteConfig.checkoutUrlPattern.test(window.location.pathname)
    : genericCheckoutPattern.test(window.location.pathname);

  if (!urlLooksLikeCheckout) return;

  let overlayShown = false;
  let shadowRoot = null;
  window.__bekleBypassed = window.__bekleBypassed || false;

  function detectPrice() {
    if (siteConfig) {
      const el = bekleFindFirst(siteConfig.totalPriceSelectors);
      const price = el ? bekleParsePrice(el.textContent) : null;
      if (price) return price;
    }
    return bekleFindPriceGeneric();
  }

  function detectName() {
    const el = document.querySelector("h1");
    const text = el ? el.textContent.trim() : document.title;
    return (text || "Sepetim").trim().slice(0, 120);
  }

  function findConfirmButton() {
    if (siteConfig) {
      const bySelector = bekleFindFirst(siteConfig.confirmButtonSelectors);
      if (bySelector) return bySelector;
    }
    return bekleFindButtonByText();
  }

  function interceptConfirmButton() {
    const button = findConfirmButton();
    if (!button || button.dataset.bekleIntercepted) return;
    button.dataset.bekleIntercepted = "true";
    button.addEventListener("click", handleConfirmClick, true);
  }

  function handleConfirmClick(event) {
    if (window.__bekleBypassed) return;
    event.preventDefault();
    event.stopImmediatePropagation();
    showOverlay();
  }

  function proceedAnyway() {
    window.__bekleBypassed = true;
    removeOverlay();
    const button = findConfirmButton();
    if (button) button.click();
    setTimeout(() => {
      window.__bekleBypassed = false;
    }, 3000);
  }

  function bekleSendMessage(message) {
    return new Promise((resolve) => {
      try {
        browser.runtime.sendNativeMessage(message, (response) => {
          resolve(response || { ok: false });
        });
      } catch (e) {
        resolve({ ok: false, error: String(e) });
      }
    });
  }

  function formatCurrency(amount, currencyCode) {
    try {
      return new Intl.NumberFormat("tr-TR", { style: "currency", currency: currencyCode || "TRY" }).format(amount);
    } catch (e) {
      return `${amount.toFixed(2)} ${currencyCode || "TRY"}`;
    }
  }

  function formatHours(hours) {
    if (hours < 1) return `${Math.max(1, Math.round(hours * 60))} dakika`;
    if (hours < 100) return `${(Math.round(hours * 10) / 10).toFixed(1)} saat`;
    return `${Math.round(hours / 24)} gün`;
  }

  async function showOverlay() {
    if (overlayShown) return;
    overlayShown = true;

    const [wageInfo, nightInfo] = await Promise.all([
      bekleSendMessage({ type: "getWageInfo" }),
      bekleSendMessage({ type: "getNightModeConfig" })
    ]);

    buildOverlay({ wageInfo, nightInfo, price: detectPrice(), name: detectName() });
  }

  function removeOverlay() {
    const host = document.getElementById("bekle-overlay-host");
    if (host) host.remove();
    overlayShown = false;
    shadowRoot = null;
  }

  function buildOverlay(state) {
    const host = document.createElement("div");
    host.id = "bekle-overlay-host";
    document.documentElement.appendChild(host);
    shadowRoot = host.attachShadow({ mode: "closed" });

    const style = document.createElement("style");
    style.textContent = BEKLE_OVERLAY_CSS;
    shadowRoot.appendChild(style);

    const wrapper = document.createElement("div");
    wrapper.className = "bekle-backdrop";
    wrapper.innerHTML = renderStep(state);
    shadowRoot.appendChild(wrapper);

    wireEvents(state);

    const needsNightChallenge = state.nightInfo?.ok && state.nightInfo.enabled && state.nightInfo.isNight;
    if (needsNightChallenge) {
      showNightChallenge(state);
    }
  }

  function renderStep(state) {
    const hourlyWage = state.wageInfo?.ok ? state.wageInfo.hourlyWage : 0;
    const currencyCode = state.wageInfo?.ok ? state.wageInfo.currencyCode : "TRY";
    const hasPrice = typeof state.price === "number" && state.price > 0;
    const hours = hasPrice && hourlyWage > 0 ? state.price / hourlyWage : 0;
    const sp500 = hasPrice ? state.price * Math.pow(1.10, 3) : 0;
    const gold = hasPrice ? state.price * Math.pow(1.07, 3) : 0;

    return `
      <div class="bekle-card">
        <div class="bekle-header">
          <span class="bekle-logo">🛡️ DurBi</span>
          <button class="bekle-close" data-action="dismiss" title="Kapat (yine de kilitli kalır)">✕</button>
        </div>
        <h1>Bir saniye dur bakalım</h1>
        ${
          hasPrice
            ? `<p class="bekle-price">${formatCurrency(state.price, currencyCode)}</p>`
            : `<label class="bekle-manual-price">
                 Ürünün fiyatını bulamadım, girer misin?
                 <input type="number" inputmode="decimal" id="bekle-manual-price-input" placeholder="Örn. 1200" />
               </label>`
        }
        ${
          hourlyWage > 0 && hasPrice
            ? `<p class="bekle-hours">Bunu almak için <strong>${formatHours(hours)}</strong> çalışman gerekiyor.</p>`
            : ""
        }
        ${
          hasPrice
            ? `<div class="bekle-invest">
                 <p class="bekle-invest-title">Bu parayı 3 yıl yatırsaydın?</p>
                 <div class="bekle-invest-row"><span>S&amp;P 500</span><strong>${formatCurrency(sp500, currencyCode)}</strong></div>
                 <div class="bekle-invest-row"><span>Altın</span><strong>${formatCurrency(gold, currencyCode)}</strong></div>
               </div>`
            : ""
        }
        <div class="bekle-reflect">
          <p class="bekle-reflect-title">Bir düşün</p>
          <p class="bekle-reflect-label">İhtiyaç mı, istek mi?</p>
          <div class="bekle-choice-row" data-group="need">
            <button class="bekle-choice" data-value="true">İhtiyaç</button>
            <button class="bekle-choice" data-value="false">İstek</button>
          </div>
          <p class="bekle-reflect-label">Zaten benzer bir şeyin var mı?</p>
          <div class="bekle-choice-row" data-group="owns">
            <button class="bekle-choice" data-value="true">Var</button>
            <button class="bekle-choice" data-value="false">Yok</button>
          </div>
          <p class="bekle-reflect-label">Bunu nereden gördün?</p>
          <select class="bekle-select" id="bekle-trigger-select">
            <option value="">Seçilmedi</option>
            <option value="ad">Sosyal medya reklamı</option>
            <option value="friend">Arkadaş önerisi</option>
            <option value="store">Mağazada/vitrinde gördüm</option>
            <option value="browsing">Sıkılıp gezerken denk geldim</option>
            <option value="other">Diğer</option>
          </select>
          <div id="bekle-insight" class="bekle-insight"></div>
        </div>
        <p class="bekle-mood-label">Şu an nasıl hissediyorsun?</p>
        <div class="bekle-mood-row">
          <button class="bekle-mood" data-mood="stressed">😣 Stresli</button>
          <button class="bekle-mood" data-mood="sad">😢 Üzgün</button>
          <button class="bekle-mood" data-mood="bored">🥱 Sıkılmış</button>
          <button class="bekle-mood" data-mood="happy">😊 Mutlu</button>
        </div>
        <button class="bekle-primary" data-action="lock">Bekleme Listesine Ekle (24 saat)</button>
        <button class="bekle-secondary" data-action="proceed">Yine de satın almaya devam et</button>
        <p class="bekle-status" id="bekle-status"></p>
      </div>
    `;
  }

  function wireEvents(state) {
    if (!shadowRoot) return;
    let selectedMood = null;
    let selectedIsNeed = null;
    let selectedOwns = null;
    let selectedTrigger = null;

    shadowRoot.querySelectorAll(".bekle-mood").forEach((btn) => {
      btn.addEventListener("click", () => {
        selectedMood = btn.dataset.mood;
        shadowRoot.querySelectorAll(".bekle-mood").forEach((b) => b.classList.remove("bekle-mood-selected"));
        btn.classList.add("bekle-mood-selected");
      });
    });

    function updateInsight() {
      const insightEl = shadowRoot.querySelector("#bekle-insight");
      if (!insightEl) return;
      const lines = [];
      if (selectedIsNeed === false) lines.push("Bunu \"istek\" olarak işaretledin, ihtiyaç değil.");
      if (selectedOwns === true) lines.push("Zaten benzer bir şeyin olduğunu söyledin.");
      const monthlyIncome = state.wageInfo?.ok ? state.wageInfo.monthlyIncome : 0;
      if (monthlyIncome > 0 && state.price > 0) {
        const percent = (state.price / monthlyIncome) * 100;
        if (percent >= 5) lines.push(`Bu, aylık gelirinin yaklaşık %${Math.round(percent)}'i.`);
      }
      if (selectedTrigger === "ad" || selectedTrigger === "browsing") {
        lines.push("Bunu bir reklamda ya da sıkılıp gezinirken görmüşsün — bu genelde dürtüsel bir tetikleyicidir.");
      }
      if (lines.length === 0) {
        insightEl.innerHTML = "";
        return;
      }
      const verdict = lines.length > 1 ? "⚠️ Yüksek dürtü riski" : "💡 Bir kez daha düşün";
      insightEl.innerHTML =
        `<p class="bekle-insight-verdict">${verdict}</p>` +
        lines.map((line) => `<p class="bekle-insight-line">• ${line}</p>`).join("");
    }

    shadowRoot.querySelectorAll('.bekle-choice-row[data-group="need"] .bekle-choice').forEach((btn) => {
      btn.addEventListener("click", () => {
        selectedIsNeed = btn.dataset.value === "true";
        shadowRoot.querySelectorAll('.bekle-choice-row[data-group="need"] .bekle-choice').forEach((b) => b.classList.remove("bekle-choice-selected"));
        btn.classList.add("bekle-choice-selected");
        updateInsight();
      });
    });

    shadowRoot.querySelectorAll('.bekle-choice-row[data-group="owns"] .bekle-choice').forEach((btn) => {
      btn.addEventListener("click", () => {
        selectedOwns = btn.dataset.value === "true";
        shadowRoot.querySelectorAll('.bekle-choice-row[data-group="owns"] .bekle-choice').forEach((b) => b.classList.remove("bekle-choice-selected"));
        btn.classList.add("bekle-choice-selected");
        updateInsight();
      });
    });

    const triggerSelect = shadowRoot.querySelector("#bekle-trigger-select");
    if (triggerSelect) {
      triggerSelect.addEventListener("change", () => {
        selectedTrigger = triggerSelect.value || null;
        updateInsight();
      });
    }

    const dismissBtn = shadowRoot.querySelector('[data-action="dismiss"]');
    if (dismissBtn) dismissBtn.addEventListener("click", removeOverlay);

    const proceedBtn = shadowRoot.querySelector('[data-action="proceed"]');
    if (proceedBtn) proceedBtn.addEventListener("click", proceedAnyway);

    const lockBtn = shadowRoot.querySelector('[data-action="lock"]');
    if (lockBtn) {
      lockBtn.addEventListener("click", async () => {
        lockBtn.disabled = true;
        const manualInput = shadowRoot.querySelector("#bekle-manual-price-input");
        const price = state.price || (manualInput ? parseFloat(manualInput.value) : null);
        const statusEl = shadowRoot.querySelector("#bekle-status");

        if (!price || price <= 0) {
          if (statusEl) statusEl.textContent = "Önce fiyatı gir.";
          lockBtn.disabled = false;
          return;
        }

        const result = await bekleSendMessage({
          type: "lockItem",
          data: {
            name: state.name,
            price,
            currencyCode: state.wageInfo?.ok ? state.wageInfo.currencyCode : "TRY",
            domain: hostname,
            isNeed: selectedIsNeed,
            alreadyOwnsSimilar: selectedOwns,
            trigger: selectedTrigger
          }
        });

        if (selectedMood) {
          bekleSendMessage({ type: "setMood", data: { name: state.name, mood: selectedMood } });
        }

        if (result.ok) {
          if (statusEl) {
            statusEl.textContent = "Eklendi. 24 saat sonra karar vermen için hatırlatacağız.";
          }
          if (lockBtn) lockBtn.style.display = "none";
        } else {
          if (statusEl) statusEl.textContent = "Bir şeyler ters gitti, uygulamayı açıp manuel ekleyebilirsin.";
          lockBtn.disabled = false;
        }
      });
    }
  }

  function showNightChallenge(state) {
    if (!shadowRoot) return;
    const challenge = state.nightInfo?.challenge || "hold";
    const overlayCard = shadowRoot.querySelector(".bekle-card");
    if (!overlayCard) return;

    const gate = document.createElement("div");
    gate.className = "bekle-night-gate";
    if (challenge === "math") {
      const a = 10 + Math.floor(Math.random() * 40);
      const b = 10 + Math.floor(Math.random() * 40);
      gate.innerHTML = `
        <div class="bekle-night-card">
          <p>🌙 Gece Kuşu Kilidi</p>
          <p class="bekle-night-question">${a} + ${b} = ?</p>
          <input type="number" inputmode="numeric" id="bekle-night-answer" />
          <button class="bekle-primary" id="bekle-night-submit">Devam Et</button>
          <p class="bekle-night-error" id="bekle-night-error"></p>
        </div>
      `;
      shadowRoot.appendChild(gate);
      const submit = shadowRoot.getElementById
        ? shadowRoot.getElementById("bekle-night-submit")
        : gate.querySelector("#bekle-night-submit");
      submit.addEventListener("click", () => {
        const input = gate.querySelector("#bekle-night-answer");
        if (parseInt(input.value, 10) === a + b) {
          gate.remove();
        } else {
          gate.querySelector("#bekle-night-error").textContent = "Yanlış cevap, tekrar dene.";
          input.value = "";
        }
      });
    } else {
      gate.innerHTML = `
        <div class="bekle-night-card">
          <p>🌙 Gece Kuşu Kilidi</p>
          <p>15 saniye boyunca parmağını aşağıdaki daireden çekme</p>
          <div class="bekle-hold-circle" id="bekle-hold-circle">15</div>
        </div>
      `;
      shadowRoot.appendChild(gate);
      const circle = gate.querySelector("#bekle-hold-circle");
      let remaining = 15;
      let timer = null;

      const start = () => {
        if (timer) return;
        timer = setInterval(() => {
          remaining -= 1;
          circle.textContent = String(Math.max(remaining, 0));
          if (remaining <= 0) {
            clearInterval(timer);
            gate.remove();
          }
        }, 1000);
      };
      const stop = () => {
        if (timer) clearInterval(timer);
        timer = null;
        remaining = 15;
        circle.textContent = "15";
      };
      circle.addEventListener("mousedown", start);
      circle.addEventListener("touchstart", start);
      circle.addEventListener("mouseup", stop);
      circle.addEventListener("mouseleave", stop);
      circle.addEventListener("touchend", stop);
    }
  }

  function ensureFloatingBadge() {
    if (document.getElementById("bekle-badge-host") || overlayShown) return;
    const host = document.createElement("div");
    host.id = "bekle-badge-host";
    document.documentElement.appendChild(host);
    const badgeRoot = host.attachShadow({ mode: "closed" });
    const style = document.createElement("style");
    style.textContent = BEKLE_OVERLAY_CSS;
    badgeRoot.appendChild(style);
    const badge = document.createElement("button");
    badge.className = "bekle-floating-badge";
    badge.textContent = "🛡️";
    badge.title = "Almadan önce DurBi ile kontrol et";
    badge.addEventListener("click", () => showOverlay());
    badgeRoot.appendChild(badge);
  }

  function boot() {
    interceptConfirmButton();
    const observer = new MutationObserver(() => interceptConfirmButton());
    observer.observe(document.body, { childList: true, subtree: true });
    // Some sites' confirm button never matches (unusual markup, needs a real click to render,
    // etc.) — a persistent manual trigger means the feature still does *something* everywhere
    // this content script runs, instead of silently doing nothing.
    setTimeout(ensureFloatingBadge, 2000);
  }

  if (document.readyState === "loading") {
    document.addEventListener("DOMContentLoaded", boot);
  } else {
    boot();
  }
})();
