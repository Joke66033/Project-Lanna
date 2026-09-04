import React from "react";

/*
  Shared Modal Component
  - Centers content on screen
  - Limits max height to 90vh
  - Sticky header (if title provided) and close button
  - Animates in smoothly
*/
export default function Modal({ isOpen = true, title, onClose, children, maxWidthClass = "max-w-lg" }) {
  if (isOpen === false) return null;

  return (
    <div
      className="fixed inset-0 flex items-center justify-center p-4"
      style={{
        position: 'fixed',
        top: 0,
        left: 0,
        right: 0,
        bottom: 0,
        zIndex: 99999,
        backgroundColor: 'rgba(0, 0, 0, 0.55)',
        backdropFilter: 'blur(2px)',
        display: 'flex',
        alignItems: 'center',
        justifyContent: 'center',
      }}
      onClick={(e) => {
        if (e.target === e.currentTarget && onClose) onClose();
      }}
    >
      <div
        className={`bg-white rounded-2xl w-full ${maxWidthClass} shadow-2xl flex flex-col max-h-[90vh] overflow-hidden`}
        style={{
          position: 'relative',
          zIndex: 100000,
          backgroundColor: '#ffffff',
          maxHeight: '90vh',
        }}
        onClick={(e) => e.stopPropagation()}
      >
        {title && (
          <div className="flex justify-between items-center px-6 py-4 border-b border-gray-100 flex-shrink-0 bg-white">
            <h2 className="font-bold text-xl text-gray-800">{title}</h2>
            <button
              type="button"
              onClick={onClose}
              className="text-gray-400 hover:text-black text-2xl font-bold leading-none p-1 cursor-pointer transition"
            >
              ✕
            </button>
          </div>
        )}
        {children}
      </div>
    </div>
  );
}
