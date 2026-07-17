import { createClient } from '@supabase/supabase-js'

/**
 * Supabase client สำหรับ Real-time subscriptions และ Storage เท่านั้น
 * CRUD ปกติให้เรียกผ่าน PHP API (VITE_API_BASE_URL)
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
