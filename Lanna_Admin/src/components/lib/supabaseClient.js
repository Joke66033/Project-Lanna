import { createClient } from '@supabase/supabase-js'

/**
 * supabaseClient.js
 * สร้าง Supabase client พิเศษที่ intercept (ดักจับ) ทุก HTTP request
 * แล้ว redirect ไปที่ PHP API ของเราเองแทน Supabase Cloud
 *
 * ทำไมต้องทำแบบนี้:
 *   - Admin pages ใช้ Supabase JS SDK เพื่อ query / subscribe ข้อมูล
 *   - แต่ฐานข้อมูลจริงอยู่บน MySQL (lnw.mn) ไม่ใช่ Supabase Cloud
 *   - จึง intercept request ที่มี URL รูป /rest/v1/<tableName>
 *     แล้ว redirect ไปที่ supabase_proxy.php บน server ของเราแทน
 *
 * Flow:
 *   Component → supabase.from('table')... → fetch intercept (ใน global.fetch)
 *             → https://siripaporn.lnw.mn/endpoints/supabase_proxy.php?table=<table>
 *             → MySQL DB
 *
 * ⚠️  supabase SDK ยังคงถูกใช้สำหรับ:
 *       - Real-time subscriptions (.channel / .on)
 *       - อ่าน/เขียนข้อมูลผ่าน supabase.from()
 *     ทั้งหมดถูก redirect ผ่าน proxy นี้ ไม่มีการเชื่อมต่อ Supabase Cloud จริง
 */
const supabaseUrl = import.meta.env.VITE_SUPABASE_URL
const supabaseAnonKey = import.meta.env.VITE_SUPABASE_ANON_KEY

export const supabase = createClient(supabaseUrl, supabaseAnonKey, {
  global: {
    fetch: (url, options) => {
      let rewrittenUrl = url;
      if (typeof url === 'string' && url.includes('/rest/v1/')) {
        const match = url.match(/\/rest\/v1\/([a-zA-Z0-9_]+)/);
        if (match) {
          const tableName = match[1];
          
          // หาตำแหน่ง '?' ตัวสุดท้ายซึ่งเป็นจุดเริ่มต้นของ Query Parameters จริงจาก Supabase
          const lastQuestionMarkIdx = url.lastIndexOf('?');
          let queryStr = '';
          if (lastQuestionMarkIdx !== -1) {
            queryStr = url.substring(lastQuestionMarkIdx + 1);
          }

          if (options && options.headers) {
            const range = options.headers['Range'] || options.headers['range'];
            if (range && typeof range === 'string') {
              const rangeMatch = range.match(/(\d+)-(\d+)/);
              if (rangeMatch) {
                const from = parseInt(rangeMatch[1]);
                const to = parseInt(rangeMatch[2]);
                const limit = to - from + 1;
                const offset = from;
                queryStr += (queryStr ? '&' : '') + `limit=${limit}&offset=${offset}`;
              }
            }
          }

          rewrittenUrl = `https://siripaporn.lnw.mn/endpoints/supabase_proxy.php?table=${tableName}`;
          if (queryStr) {
            rewrittenUrl += `&${queryStr}`;
          }
        }
      }
      return fetch(rewrittenUrl, options);
    }
  }
})
