import React from "react";

export default function Pagination({ currentPage, totalItems, pageSize, onPageChange, colors }) {
  const totalPages = Math.ceil(totalItems / pageSize);
  
  if (totalItems === 0) {
    return (
      <div className="flex flex-col sm:flex-row justify-between items-center gap-4 py-4 px-6 border-t text-sm text-gray-600 bg-gray-50/50">
        <div>ไม่มีข้อมูลสำหรับแสดงผล</div>
      </div>
    );
  }

  const startItem = (currentPage - 1) * pageSize + 1;
  const endItem = Math.min(currentPage * pageSize, totalItems);

  const getPageNumbers = () => {
    const pageNumbers = [];
    const maxVisiblePages = 5;
    
    if (totalPages <= maxVisiblePages) {
      for (let i = 1; i <= totalPages; i++) {
        pageNumbers.push(i);
      }
      return pageNumbers;
    }
    
    const chunkIndex = Math.floor((currentPage - 1) / maxVisiblePages);
    const startPage = chunkIndex * maxVisiblePages + 1;
    const endPage = Math.min(startPage + maxVisiblePages - 1, totalPages);
    
    if (startPage > 1) {
      pageNumbers.push("prev-ellipsis");
    }
    
    for (let i = startPage; i <= endPage; i++) {
      pageNumbers.push(i);
    }
    
    if (endPage < totalPages) {
      pageNumbers.push("next-ellipsis");
    }
    
    return pageNumbers;
  };

  const pageNumbers = getPageNumbers();
  const chunkIndex = Math.floor((currentPage - 1) / 5);
  const startPage = chunkIndex * 5 + 1;
  const endPage = Math.min(startPage + 4, totalPages);

  return (
    <div className="flex flex-col sm:flex-row justify-between items-center gap-4 py-4 px-6 border-t text-sm text-gray-600 bg-gray-50/50 select-none">
      {/* Left Side: X - Y of Z items */}
      <div>
        แสดง {startItem} - {endItem} จากทั้งหมด {totalItems} รายการ
      </div>

      {/* Right Side: Navigation buttons (only show if totalPages > 1) */}
      {totalPages > 1 && (
        <div className="flex justify-center items-center gap-1.5">
          {/* Previous Button */}
          <button
            type="button"
            onClick={() => onPageChange(Math.max(currentPage - 1, 1))}
            disabled={currentPage === 1}
            className="px-3 h-9 rounded-lg border bg-white text-sm hover:bg-gray-100 disabled:text-gray-300 disabled:bg-gray-100 disabled:hover:bg-gray-100 transition duration-150"
          >
            ก่อนหน้า
          </button>

          {/* Page Numbers with Ellipses */}
          {pageNumbers.map((page, index) => {
            if (page === "prev-ellipsis") {
              return (
                <button
                  key={`prev-${index}`}
                  type="button"
                  onClick={() => onPageChange(startPage - 1)}
                  className="w-9 h-9 rounded-lg border text-sm font-medium bg-white hover:bg-gray-100 transition duration-150 text-gray-400"
                  title="ย้อนไปกลุ่มก่อนหน้า"
                >
                  ...
                </button>
              );
            }
            if (page === "next-ellipsis") {
              return (
                <button
                  key={`next-${index}`}
                  type="button"
                  onClick={() => onPageChange(endPage + 1)}
                  className="w-9 h-9 rounded-lg border text-sm font-medium bg-white hover:bg-gray-100 transition duration-150 text-gray-400"
                  title="ไปกลุ่มถัดไป"
                >
                  ...
                </button>
              );
            }
            return (
              <button
                key={page}
                type="button"
                onClick={() => onPageChange(page)}
                className={`w-9 h-9 rounded-lg border text-sm font-medium transition duration-150 ${
                  currentPage === page
                    ? colors
                      ? `${colors.primaryBg} ${colors.borderCol} text-white font-semibold shadow-sm`
                      : "bg-orange-500 text-white border-orange-500 font-semibold shadow-sm"
                    : "bg-white hover:bg-gray-100"
                }`}
              >
                {page}
              </button>
            );
          })}

          {/* Next Button */}
          <button
            type="button"
            onClick={() => onPageChange(Math.min(currentPage + 1, totalPages))}
            disabled={currentPage === totalPages}
            className="px-3 h-9 rounded-lg border bg-white text-sm hover:bg-gray-100 disabled:text-gray-300 disabled:bg-gray-100 disabled:hover:bg-gray-100 transition duration-150"
          >
            ถัดไป
          </button>
        </div>
      )}
    </div>
  );
}
