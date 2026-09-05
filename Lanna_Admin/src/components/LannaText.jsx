import { toTilokFontString } from "../lib/thaiToLanna.js";

export default function LannaText({ children, className = '', as = 'span', fallbackThai = '' }) {
  const Tag = as;
  let content = children;
  if (typeof children === 'string') {
    content = toTilokFontString(children, fallbackThai);
  }
  return <Tag className={`lanna-text font-lanna ${className}`}>{content}</Tag>;
}
