// Best-effort DOM hooks per retailer. These are educated guesses at common checkout markup —
// I (the assistant that wrote this) could not open these sites to verify them, so treat every
// selector here as "probably needs tuning on a real device." content.js always falls back to a
// manual price entry + a generic checkout-URL trigger when a selector below finds nothing, so
// the feature still works even when a selector is stale.
const BEKLE_SITE_SELECTORS = {
  "trendyol.com": {
    checkoutUrlPattern: /(sepet|checkout|siparis-oncesi|odeme)/i,
    confirmButtonSelectors: [
      "[data-testid='checkout-confirm-button']",
      "button.checkout-approve",
      ".basket-confirm-button",
      "button[class*='confirm']"
    ],
    totalPriceSelectors: [
      "[data-testid='basket-total-price']",
      ".total-price",
      ".summary-total-price",
      ".cart-total-price"
    ]
  },
  "amazon": {
    checkoutUrlPattern: /(gp\/buy|checkout|cart)/i,
    confirmButtonSelectors: [
      "#placeOrder",
      "input[name='placeOrder']",
      "#buy-now-button",
      "#proceedToRetailCheckout"
    ],
    totalPriceSelectors: [
      "#sc-subtotal-amount-activecart",
      ".grand-total-price",
      "#grandTotalAmount"
    ]
  },
  "zara.com": {
    checkoutUrlPattern: /(cart|checkout|basket|sepet)/i,
    confirmButtonSelectors: [
      "[data-qa-action='checkout-continue']",
      ".checkout-button",
      "button[class*='checkout']"
    ],
    totalPriceSelectors: [
      ".cart-summary__total-amount",
      ".money-amount__main",
      "[data-qa-id='cart-item-total-price']"
    ]
  },
  "hm.com": {
    checkoutUrlPattern: /(cart|checkout|sepet)/i,
    confirmButtonSelectors: [
      "[data-elid='cart-checkout-button']",
      ".checkout-button",
      "button[class*='checkout']"
    ],
    totalPriceSelectors: [
      ".cart-summary-total",
      "[data-elid='cart-total-price']"
    ]
  }
};

function bekleMatchSite(hostname) {
  for (const key of Object.keys(BEKLE_SITE_SELECTORS)) {
    if (hostname.includes(key)) return { key, ...BEKLE_SITE_SELECTORS[key] };
  }
  return null;
}

function bekleFindFirst(selectors) {
  for (const selector of selectors) {
    try {
      const el = document.querySelector(selector);
      if (el) return el;
    } catch (e) {
      // Selector may be invalid on this page's DOM quirks — just try the next one.
    }
  }
  return null;
}

// Handles both "1.234,56" (TR) and "1,234.56" (US) style formatted prices.
function bekleParsePrice(text) {
  if (!text) return null;
  let cleaned = text.replace(/[^0-9,.-]/g, "");
  if (!cleaned) return null;
  const lastComma = cleaned.lastIndexOf(",");
  const lastDot = cleaned.lastIndexOf(".");
  const decimalSep = lastComma > lastDot ? "," : ".";
  const thousandSep = decimalSep === "," ? "." : ",";
  cleaned = cleaned.split(thousandSep).join("");
  cleaned = cleaned.replace(decimalSep, ".");
  const value = parseFloat(cleaned);
  return Number.isNaN(value) ? null : value;
}
