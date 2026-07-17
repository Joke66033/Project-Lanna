export default function LannaText({ children, className = '', as = 'span' }) {
  const Tag = as;
  return <Tag className={`lanna-text ${className}`}>{children}</Tag>;
}
