import React, { useMemo } from 'react';

/**
 * StrokePreviewCanvas
 * Renders SVG paths for stroke coordinates defined on a 100x100 grid.
 * Highlights each stroke with different distinct colors and shows start/end points with arrows and numbers.
 */
const STROKE_COLORS = [
  '#4f46e5', // Indigo
  '#059669', // Emerald
  '#d97706', // Amber
  '#dc2626', // Red
  '#7c3aed', // Purple
  '#0284c7', // Sky blue
  '#db2777', // Pink
  '#65a30d', // Lime
];

export default function StrokePreviewCanvas({ strokeDataStr, charSymbol = '', size = 260 }) {
  const { strokes, isValid, error } = useMemo(() => {
    if (!strokeDataStr || !strokeDataStr.trim()) {
      return { strokes: [], isValid: true, error: null };
    }
    try {
      let parsed = JSON.parse(strokeDataStr);
      if (!Array.isArray(parsed)) {
        return { strokes: [], isValid: false, error: 'ข้อมูลต้องเป็น Array' };
      }
      // If it's a single stroke array of points [ {x, y}, ... ], wrap it
      if (parsed.length > 0 && !Array.isArray(parsed[0]) && typeof parsed[0] === 'object') {
        parsed = [parsed];
      }
      return { strokes: parsed, isValid: true, error: null };
    } catch (err) {
      return { strokes: [], isValid: false, error: 'รูปแบบ JSON ไม่ถูกต้อง' };
    }
  }, [strokeDataStr]);

  return (
    <div className="flex flex-col items-center justify-center p-3.5 bg-slate-50 border border-slate-200 rounded-2xl h-full">
      <div className="flex items-center justify-between w-full mb-2.5 px-1 text-xs font-bold" style={{ color: '#000000' }}>
        <span style={{ color: '#000000', fontWeight: '700' }}>ตัวอย่างเส้นทางการวาด (100x100 Grid)</span>
        <span className={isValid ? "text-emerald-700 font-bold" : "text-rose-600 font-bold"}>
          {isValid ? `${strokes.length} เส้น` : 'JSON Error'}
        </span>
      </div>

      <div 
        className="relative bg-white rounded-xl shadow-inner border-2 border-slate-300 overflow-hidden select-none flex-shrink-0"
        style={{ width: size, height: size }}
      >
        {/* Grid Background */}
        <svg 
          width={size} 
          height={size} 
          viewBox="0 0 100 100" 
          className="absolute inset-0 w-full h-full"
        >
          {/* Subtle Grid Lines */}
          <line x1="0" y1="50" x2="100" y2="50" stroke="#e2e8f0" strokeWidth="1" strokeDasharray="2,2" />
          <line x1="50" y1="0" x2="50" y2="100" stroke="#e2e8f0" strokeWidth="1" strokeDasharray="2,2" />
          <line x1="0" y1="25" x2="100" y2="25" stroke="#f1f5f9" strokeWidth="0.6" />
          <line x1="0" y1="75" x2="100" y2="75" stroke="#f1f5f9" strokeWidth="0.6" />
          <line x1="25" y1="0" x2="25" y2="100" stroke="#f1f5f9" strokeWidth="0.6" />
          <line x1="75" y1="0" x2="75" y2="100" stroke="#f1f5f9" strokeWidth="0.6" />
          


          {/* Stroke Paths */}
          {isValid && strokes.map((stroke, strokeIdx) => {
            if (!Array.isArray(stroke) || stroke.length === 0) return null;
            const color = STROKE_COLORS[strokeIdx % STROKE_COLORS.length];
            
            // Generate Path 'M x y L x y ...'
            let d = '';
            stroke.forEach((pt, idx) => {
              const x = typeof pt.x === 'number' ? pt.x : (pt[0] ?? 0);
              const y = typeof pt.y === 'number' ? pt.y : (pt[1] ?? 0);
              if (idx === 0) {
                d += `M ${x} ${y}`;
              } else {
                d += ` L ${x} ${y}`;
              }
            });

            const startPt = stroke[0];
            const startX = typeof startPt.x === 'number' ? startPt.x : (startPt[0] ?? 0);
            const startY = typeof startPt.y === 'number' ? startPt.y : (startPt[1] ?? 0);

            const endPt = stroke[stroke.length - 1];
            const endX = typeof endPt.x === 'number' ? endPt.x : (endPt[0] ?? 0);
            const endY = typeof endPt.y === 'number' ? endPt.y : (endPt[1] ?? 0);

            return (
              <g key={strokeIdx}>
                {/* Stroke Main Line */}
                <path
                  d={d}
                  fill="none"
                  stroke={color}
                  strokeWidth="3.5"
                  strokeLinecap="round"
                  strokeLinejoin="round"
                  opacity="0.85"
                />

                {/* Point Nodes */}
                {stroke.map((pt, pIdx) => {
                  const px = typeof pt.x === 'number' ? pt.x : (pt[0] ?? 0);
                  const py = typeof pt.y === 'number' ? pt.y : (pt[1] ?? 0);
                  return (
                    <circle
                      key={pIdx}
                      cx={px}
                      cy={py}
                      r="1.4"
                      fill="#ffffff"
                      stroke={color}
                      strokeWidth="0.8"
                    />
                  );
                })}

                {/* Start Point Marker (Circle with Number) */}
                <circle cx={startX} cy={startY} r="3.2" fill={color} />
                <text
                  x={startX}
                  y={startY + 1.1}
                  textAnchor="middle"
                  fontSize="3"
                  fontWeight="bold"
                  fill="#ffffff"
                >
                  {strokeIdx + 1}
                </text>

                {/* End Point Marker (Small Ring) */}
                {stroke.length > 1 && (
                  <circle
                    cx={endX}
                    cy={endY}
                    r="2.2"
                    fill="none"
                    stroke={color}
                    strokeWidth="1.2"
                  />
                )}
              </g>
            );
          })}
        </svg>

        {/* Error Overlay */}
        {!isValid && (
          <div className="absolute inset-0 bg-rose-50/90 flex flex-col items-center justify-center p-4 text-center">
            <span className="text-rose-600 font-bold text-xs mb-1">⚠️ รูปแบบพิกัดไม่ถูกต้อง</span>
            <span className="text-rose-500 text-[11px] font-mono">{error}</span>
          </div>
        )}
      </div>

      <div className="mt-2.5 text-xs font-bold flex items-center justify-center gap-4" style={{ color: '#000000' }}>
        <span className="flex items-center gap-1.5" style={{ color: '#000000' }}>
          <span className="w-2.5 h-2.5 rounded-full bg-indigo-600 inline-block shadow-sm"></span>
          จุดเริ่มต้น (1, 2...)
        </span>
        <span className="flex items-center gap-1.5" style={{ color: '#000000' }}>
          <span className="w-2.5 h-2.5 rounded-full border-2 border-indigo-600 inline-block"></span>
          จุดสิ้นสุด
        </span>
      </div>
    </div>
  );
}
