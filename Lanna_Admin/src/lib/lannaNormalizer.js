import { toTilokFontString, tilokDirectMap } from "./thaiToLanna.js";

export function normalizeLannaText(text) {
  if (!text) return "";
  return toTilokFontString(text);
}

export async function loadLannaMap() {
  return tilokDirectMap;
}
