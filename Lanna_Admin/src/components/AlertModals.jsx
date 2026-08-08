import React, { useEffect } from "react";
import { Trash2 } from "lucide-react";
import LannaText from "./LannaText.jsx";

/*
  SuccessModal props:
  - isOpen: boolean
  - onClose: () => void
  - message: string
  - autoCloseMs: number (optional, default 2000)
*/
export function SuccessModal({ isOpen, onClose, message, autoCloseMs = 2000 }) {
  useEffect(() => {
    if (isOpen && autoCloseMs > 0) {
      const timer = setTimeout(() => {
        onClose();
      }, autoCloseMs);
      return () => clearTimeout(timer);
    }
  }, [isOpen, autoCloseMs, onClose]);

  if (!isOpen) return null;

  return (
    <div className="fixed inset-0 bg-black/40 flex items-center justify-center z-50 p-4">
      <div className="bg-white rounded-2xl w-full max-w-md p-6 shadow-xl relative overflow-x-hidden flex flex-col items-center text-center space-y-5">
        <div className="w-20 h-20 flex items-center justify-center rounded-full bg-green-100 flex-shrink-0 animate-bounce">
          <svg
            className="w-10 h-10 text-green-500"
            fill="none"
            stroke="currentColor"
            strokeWidth="3"
            viewBox="0 0 24 24"
          >
            <path strokeLinecap="round" strokeLinejoin="round" d="M5 13l4 4L19 7" />
          </svg>
        </div>
        <h3 className="text-xl font-bold text-gray-800">{message}</h3>
        <button
          onClick={onClose}
          className="px-8 py-3 rounded-xl bg-green-500 text-white font-semibold hover:bg-green-600 transition shadow"
        >
          ตกลง
        </button>
      </div>
    </div>
  );
}

/*
  ConfirmDeleteModal props:
  - isOpen: boolean
  - onClose: () => void
  - onConfirm: () => void
  - title: string (e.g. "ยืนยันการลบอักขระ")
  - itemName: string (e.g. name of the item)
  - itemSubtitle: string (optional, e.g. code/translation)
  - isLannaText: boolean (optional, true if name should use LannaText)
*/
export function ConfirmDeleteModal({
  isOpen,
  onClose,
  onConfirm,
  title = "ยืนยันการลบข้อมูล",
  itemName = "",
  itemSubtitle = "",
  isLannaText = false,
  usageWarningText = "",
}) {
  if (!isOpen) return null;

  return (
    <div className="fixed inset-0 bg-black/40 flex items-center justify-center z-50 p-4">
      <div className="bg-white rounded-2xl w-full max-w-md p-6 shadow-xl relative overflow-x-hidden flex flex-col items-center text-center space-y-5 animate-in fade-in zoom-in-95 duration-150">
        <button
          onClick={onClose}
          className="absolute top-4 right-4 text-gray-400 hover:text-black text-xl leading-none"
        >
          ✕
        </button>
        <div className="w-20 h-20 flex items-center justify-center rounded-full bg-red-100 flex-shrink-0">
          <Trash2 size={36} className="text-red-500" />
        </div>

        <div>
          <h3 className="text-xl font-bold text-gray-800">{title}</h3>
          {usageWarningText ? (
            <div className="mt-3 p-3 bg-red-50 border border-red-200 rounded-xl text-xs text-red-700 leading-relaxed text-left space-y-1">
              <p className="font-semibold text-red-800">⚠️ หมวดหมู่นี้ถูกใช้งานอยู่!</p>
              <p>หมวดหมู่ <span className="font-bold">"{itemName}"</span> ถูกเรียกใช้อยู่ใน <span className="font-bold text-red-900">{usageWarningText}</span></p>
              <p className="text-red-600">หากยืนยันที่จะลบ ระบบจะทำการลบหมวดหมู่นี้รวมถึงข้อมูลทั้งหมดที่เกี่ยวข้องโดยอัตโนมัติ</p>
            </div>
          ) : (
            <p className="text-gray-500 mt-2 text-sm leading-relaxed px-2">
              คุณแน่ใจหรือไม่ว่าต้องการลบ
              <br />
              <span className="font-semibold text-gray-700">
                {isLannaText ? <LannaText>{itemName}</LannaText> : `"${itemName}"`}
                {itemSubtitle ? ` (${itemSubtitle})` : ""}
              </span>
              <br />
              เมื่อลบแล้วจะไม่สามารถกู้คืนได้
            </p>
          )}
        </div>

        <div className="flex w-full gap-3 pt-2">
          <button
            type="button"
            onClick={onClose}
            className="flex-1 py-3 rounded-xl border border-gray-200 text-gray-600 hover:bg-gray-100 font-medium transition"
          >
            ยกเลิก
          </button>

          <button
            type="button"
            onClick={onConfirm}
            className="flex-1 py-3 rounded-xl bg-red-500 text-white font-semibold hover:bg-red-600 transition shadow"
          >
            {usageWarningText ? "ยืนยันที่จะลบ" : "ลบข้อมูล"}
          </button>
        </div>
      </div>
    </div>
  );
}
