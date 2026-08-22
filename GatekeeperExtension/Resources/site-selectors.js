// Best-effort DOM hooks per retailer. These are educated guesses at common checkout markup —
// I (the assistant that wrote this) could not open these sites to verify them, so treat every
// selector here as "probably needs tuning on a real device." For sites without an entry (or
// where the entry's selectors don't match), content.js falls back to bekleFindButtonByText /
// bekleFindPriceGeneric below, which work by scanning for common confirm-button label text and
// price-shaped numbers rather than relying on any one site's exact class names — much more
// resilient to redesigns, at the cost of being a bit less precise.
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
  },
  "hepsiburada.com": {
    checkoutUrlPattern: /(sepet|checkout|odeme)/i,
    confirmButtonSelectors: ["button[class*='confirm']", "button[class*='onayla']"],
    totalPriceSelectors: [".price-summary-total", "[class*='grand-total']"]
  },
  "n11.com": {
    checkoutUrlPattern: /(sepet|checkout|odeme)/i,
    confirmButtonSelectors: ["button[class*='confirm']", "a[class*='confirm']"],
    totalPriceSelectors: [".proceedToPaymentSection .amount", "[class*='grandTotal']"]
  },
  "boyner.com.tr": {
    checkoutUrlPattern: /(sepet|checkout|odeme)/i,
    confirmButtonSelectors: [],
    totalPriceSelectors: []
  },
  "lcw.com": {
    checkoutUrlPattern: /(sepet|checkout|odeme)/i,
    confirmButtonSelectors: [],
    totalPriceSelectors: []
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

// Site-agnostic fallback: look for a clickable element whose visible label matches a common
// "confirm the purchase" phrase, in Turkish or English. Far more resilient to redesigns than
// hardcoded class names, and works on sites we never explicitly configured.
const BEKLE_CONFIRM_BUTTON_PHRASES = [
  "sepeti onayla",
  "siparişi onayla",
  "siparişi tamamla",
  "siparişi ver",
  "ödemeye geç",
  "ödemeyi tamamla",
  "ödeme yap",
  "satın al",
  "hemen al",
  "place order",
  "complete order",
  "proceed to checkout",
  "pay now",
  "confirm order",
  "confirm purchase",
  "buy now",
  "checkout now"
];

function bekleFindButtonByText() {
  const candidates = document.querySelectorAll("button, a[role='button'], input[type='submit'], input[type='button']");
  for (const el of candidates) {
    const raw = el.innerText || el.value || el.getAttribute("aria-label") || "";
    const text = raw.trim().toLowerCase();
    if (!text || text.length > 40) continue;
    for (const phrase of BEKLE_CONFIRM_BUTTON_PHRASES) {
      if (text.includes(phrase)) return el;
    }
  }
  return null;
}

// Site-agnostic price fallback: scan elements whose class/id hints at a price/total and whose
// text actually looks like a currency amount.
function bekleFindPriceGeneric() {
  const candidates = document.querySelectorAll(
    "[class*='price' i], [class*='fiyat' i], [class*='tutar' i], [class*='total' i], [id*='price' i], [id*='total' i]"
  );
  for (const el of candidates) {
    const text = el.textContent || "";
    if (/[₺$€]|\bTL\b/.test(text)) {
      const price = bekleParsePrice(text);
      if (price && price > 0 && price < 10000000) return price;
    }
  }
  return null;
}
