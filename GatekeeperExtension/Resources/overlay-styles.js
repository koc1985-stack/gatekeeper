// Injected into the overlay's shadow root (mode: "closed") so host-page CSS can never leak in
// or out — kept as a plain string rather than a separate stylesheet file for simplicity.
const BEKLE_OVERLAY_CSS = `
  .bekle-floating-badge {
    position: fixed;
    right: 16px;
    bottom: 24px;
    z-index: 2147483000;
    width: 52px;
    height: 52px;
    border-radius: 50%;
    border: none;
    background: #ff6b35;
    box-shadow: 0 6px 16px rgba(0,0,0,0.3);
    font-size: 24px;
    cursor: pointer;
    display: flex;
    align-items: center;
    justify-content: center;
  }
  .bekle-backdrop {
    position: fixed;
    inset: 0;
    z-index: 2147483647;
    background: rgba(20, 16, 12, 0.72);
    display: flex;
    align-items: center;
    justify-content: center;
    padding: 20px;
    font-family: -apple-system, BlinkMacSystemFont, "Segoe UI", sans-serif;
  }
  .bekle-card {
    background: #fff;
    color: #1a1a1a;
    border-radius: 20px;
    padding: 24px;
    width: 100%;
    max-width: 380px;
    max-height: 85vh;
    overflow-y: auto;
    box-shadow: 0 20px 60px rgba(0,0,0,0.35);
  }
  .bekle-header {
    display: flex;
    justify-content: space-between;
    align-items: center;
    margin-bottom: 12px;
  }
  .bekle-logo { font-weight: 700; font-size: 15px; }
  .bekle-close {
    background: none;
    border: none;
    font-size: 18px;
    color: #888;
    cursor: pointer;
    padding: 4px 8px;
  }
  .bekle-card h1 {
    font-size: 22px;
    margin: 0 0 12px;
  }
  .bekle-price {
    font-size: 32px;
    font-weight: 800;
    color: #ff6b35;
    margin: 0 0 12px;
  }
  .bekle-manual-price {
    display: block;
    font-size: 13px;
    color: #555;
    margin-bottom: 12px;
  }
  .bekle-manual-price input {
    display: block;
    width: 100%;
    box-sizing: border-box;
    margin-top: 6px;
    padding: 10px;
    font-size: 16px;
    border: 1px solid #ddd;
    border-radius: 10px;
  }
  .bekle-hours {
    font-size: 15px;
    margin: 0 0 16px;
    line-height: 1.4;
  }
  .bekle-invest {
    background: #f4f9f4;
    border-radius: 14px;
    padding: 14px;
    margin-bottom: 16px;
  }
  .bekle-invest-title {
    font-size: 12px;
    color: #4c8c4c;
    margin: 0 0 8px;
    font-weight: 600;
  }
  .bekle-invest-row {
    display: flex;
    justify-content: space-between;
    font-size: 14px;
    padding: 2px 0;
  }
  .bekle-reflect {
    background: #fdf6ec;
    border-radius: 14px;
    padding: 14px;
    margin-bottom: 16px;
  }
  .bekle-reflect-title {
    font-size: 13px;
    font-weight: 700;
    color: #a3690f;
    margin: 0 0 10px;
  }
  .bekle-reflect-label {
    font-size: 12px;
    color: #555;
    margin: 10px 0 6px;
  }
  .bekle-choice-row {
    display: flex;
    gap: 6px;
  }
  .bekle-choice {
    flex: 1;
    font-size: 12px;
    padding: 8px 4px;
    border-radius: 10px;
    border: 1px solid #eee;
    background: #fff;
    cursor: pointer;
  }
  .bekle-choice-selected {
    background: #fff1e8;
    border-color: #ff6b35;
  }
  .bekle-select {
    width: 100%;
    box-sizing: border-box;
    margin-top: 4px;
    padding: 8px;
    font-size: 13px;
    border-radius: 10px;
    border: 1px solid #eee;
    background: #fff;
  }
  .bekle-insight {
    margin-top: 10px;
  }
  .bekle-insight-verdict {
    font-size: 12px;
    font-weight: 700;
    margin: 0 0 4px;
  }
  .bekle-insight-line {
    font-size: 11px;
    color: #666;
    margin: 2px 0;
  }
  .bekle-mood-label {
    font-size: 13px;
    color: #555;
    margin: 0 0 8px;
  }
  .bekle-mood-row {
    display: flex;
    gap: 6px;
    margin-bottom: 18px;
  }
  .bekle-mood {
    flex: 1;
    font-size: 11px;
    padding: 8px 4px;
    border-radius: 10px;
    border: 1px solid #eee;
    background: #fafafa;
    cursor: pointer;
  }
  .bekle-mood-selected {
    background: #fff1e8;
    border-color: #ff6b35;
  }
  .bekle-primary {
    display: block;
    width: 100%;
    box-sizing: border-box;
    padding: 14px;
    font-size: 16px;
    font-weight: 700;
    color: #fff;
    background: #ff6b35;
    border: none;
    border-radius: 14px;
    cursor: pointer;
    margin-bottom: 8px;
  }
  .bekle-secondary {
    display: block;
    width: 100%;
    box-sizing: border-box;
    padding: 10px;
    font-size: 13px;
    color: #999;
    background: none;
    border: none;
    cursor: pointer;
  }
  .bekle-status {
    text-align: center;
    font-size: 13px;
    color: #4c8c4c;
    min-height: 16px;
  }
  .bekle-night-gate {
    position: fixed;
    inset: 0;
    z-index: 2147483647;
    background: rgba(10, 8, 20, 0.9);
    display: flex;
    align-items: center;
    justify-content: center;
  }
  .bekle-night-card {
    background: #1c1730;
    color: #fff;
    border-radius: 20px;
    padding: 28px;
    width: 90%;
    max-width: 320px;
    text-align: center;
    font-family: -apple-system, BlinkMacSystemFont, "Segoe UI", sans-serif;
  }
  .bekle-night-question {
    font-size: 26px;
    font-weight: 800;
    margin: 12px 0;
  }
  .bekle-night-card input {
    width: 100%;
    box-sizing: border-box;
    padding: 10px;
    font-size: 16px;
    border-radius: 10px;
    border: none;
    margin-bottom: 12px;
    text-align: center;
  }
  .bekle-night-error {
    color: #ff8a8a;
    font-size: 12px;
    min-height: 16px;
  }
  .bekle-hold-circle {
    width: 110px;
    height: 110px;
    margin: 16px auto 0;
    border-radius: 50%;
    border: 4px solid #6a5acd;
    display: flex;
    align-items: center;
    justify-content: center;
    font-size: 28px;
    font-weight: 700;
    user-select: none;
    -webkit-user-select: none;
  }
`;
