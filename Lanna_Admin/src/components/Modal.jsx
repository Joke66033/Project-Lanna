import React from "react";

/*
  Shared Modal Component
  - Centers content on screen
  - Limits max height to 90vh
  - Sticky header (if title provided) and close button
  - Animates in smoothly
*/
export default function Modal({ title, onClose, children, maxWidthClass = "max-w-lg" }) {
  return (
    <div className="fixed inset-0 bg-black/40 flex items-center justify-center z-50 p-4">
      <div className={`bg-white rounded-2xl w-full ${maxWidthClass} shadow-xl flex flex-col max-h-[90vh] overflow-hidden animate-in fade-in zoom-in-95 duration-150`}>
        {title && (
          <div className="flex justify-between items-center px-6 py-4 border-b border-gray-100 flex-shrink-0">
            <h2 className="font-bold text-xl text-gray-800">{title}</h2>
            <button onClick={onClose} className="text-gray-400 hover:text-black text-xl leading-none">
              ✕
            </button>
          </div>
        )}
        {children}
      </div>
    </div>
  );
}
