const supabaseUrl = 'https://bwyynehcrdytismwgbgs.supabase.co';
const supabaseAnonKey = 'sb_publishable_TLJ9C5qUCSr7IMG24tyo4g_Y26LbgWk';

async function run() {
  console.log("=== VOCABULARY DATA ===");
  try {
    const res = await fetch(`${supabaseUrl}/rest/v1/vocabulary?select=lanna_word,thai_word,reading,meaning&limit=10`, {
      headers: {
        'apikey': supabaseAnonKey,
        'Authorization': `Bearer ${supabaseAnonKey}`
      }
    });
    const vocab = await res.json();
    vocab.forEach(row => {
      console.log(`Lanna: ${row.lanna_word} | Hex: ${toHex(row.lanna_word)} | Thai: ${row.thai_word}`);
    });
  } catch (err) {
    console.error(err);
  }

  console.log("\n=== LANNA CHAR DATA ===");
  try {
    const res = await fetch(`${supabaseUrl}/rest/v1/lanna_char?select=lanna_char,thai_equivalent&limit=10`, {
      headers: {
        'apikey': supabaseAnonKey,
        'Authorization': `Bearer ${supabaseAnonKey}`
      }
    });
    const chars = await res.json();
    chars.forEach(row => {
      console.log(`Lanna: ${row.lanna_char} | Hex: ${toHex(row.lanna_char)} | Thai Equiv: ${row.thai_equivalent}`);
    });
  } catch (err) {
    console.error(err);
  }
}

function toHex(str) {
  if (!str) return '';
  return str.split('').map(c => 'U+' + c.charCodeAt(0).toString(16).toUpperCase().padStart(4, '0')).join(' ');
}

run();
