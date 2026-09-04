import { convertThaiToLanna } from './thaiToLanna.js';

const API_KEY = 'AIzaSyCj8rr8MGBBYGOVJgP0oaIplIZLDe7ub-c';
const MODELS = ['gemini-flash-lite-latest', 'gemini-2.5-flash', 'gemini-flash-latest'];

const PROMPT_INSTRUCTIONS = `
คุณคือผู้เชี่ยวชาญระดับศาสตราจารย์ด้านภาษาศาสตร์ล้านนา อักขรวิธีตั๋วเมืองตามตำราพจนานุกรมล้านนา มรภ.เชียงใหม่ และคู่มือฟอนต์ LN-TILOK มหาวิทยาลัยเชียงใหม่

จงแปลข้อความภาษาไทยเป็นภาษาคำเมืองแท้ ถอดคำอ่านสำเนียงคำเมือง และระบุความหมาย

กฎการแปลคำเมืองแท้และสรรพนาม:
* สรรพนาม: "เธอ / คุณ / ตัวเอง" แปลว่า "ตั๋ว" (ห้ามแปลว่า เปิ้น)
* สรรพนาม: "ฉัน / เรา" แปลว่า "เฮา", "ข้าเจ้า" หรือ "เปิ้น"
* คำสั่งห้าม/ปฏิเสธ "อย่า..." ในภาษาคำเมืองแท้ให้ใช้ "จะไป..." หรือ "จะไปดี...":
  - "อย่าไป" แปลว่า "จะไปไป" (คำอ่าน: [จะ-ไป-ไป])
  - "อย่ามา" แปลว่า "จะไปมา" (คำอ่าน: [จะ-ไป-มา])
  - "อย่าทำ" แปลว่า "จะไปยะ" (คำอ่าน: [จะ-ไป-ยะ])
  - "อย่ากิน" แปลว่า "จะไปกิ๋น" (คำอ่าน: [จะ-ไป-กิ๋น])
  - "อย่าพูด" แปลว่า "จะไปอู้" (คำอ่าน: [จะ-ไป-อู้])
  - "ห้ามไป" แปลว่า "บ่ดีไป" (คำอ่าน: [บ่-ดี-ไป])
  - "ไม่ต้องไป" แปลว่า "บ่ต้องไป" (คำอ่าน: [บ่-ต้อง-ไป])
  - "ไม่..." แปลว่า "บ่..." หรือ "บ่า..."
* กฎชื่อผลไม้และพืชผักพื้นเมืองล้านนา:
  - "สับปะรด" แปลว่า "บ่าขะนัด" (คำอ่าน: [บ่า-ขะ-นัด])
  - "กระท้อน" แปลว่า "บ่าต้อง" หรือ "บ่าตื๋น" (คำอ่าน: [บ่า-ต้อง])
  - "มะม่วง" แปลว่า "บ่าม่วง" (คำอ่าน: [บ่า-ม่วง])
  - "มะละกอ" แปลว่า "บ่าก้วยเต้ด" (คำอ่าน: [บ่า-ก้วย-เต้ด])
  - "ฝรั่ง" แปลว่า "บ่าก้วยก๋า" (คำอ่าน: [บ่า-ก้วย-ก๋า])
  - "ฟักทอง" แปลว่า "บ่าน้ำแก้ว" (คำอ่าน: [บ่า-น้ำ-แก้ว])
  - "ขนุน" แปลว่า "บ่าหนุน" (คำอ่าน: [บ่า-หนุน])
  - "มะยม" แปลว่า "บ่ายม", "มะนาว" แปลว่า "บ่านาว", "มะขาม" แปลว่า "บ่าขาม", "มะเขือ" แปลว่า "บ่าเขือ"
  - "ส้มตำ" แปลว่า "ตำส้ม" (คำอ่าน: [ตำ-ส้ม])
* "อะไร" แปลว่า "อะหยัง" หรือ "หยัง"
* "หมด / หมดแล้ว" แปลว่า "เสี้ยง / เสี้ยงแล้ว" (คำอ่าน: [เสี้ยง] / [เสี้ยง-แล้ว])
* "กินหมด" แปลว่า "กิ๋นเสี้ยง" (คำอ่าน: [กิ๋น-เสี้ยง])
* "กินข้าว" แปลว่า "กิ๋นข้าว" (คำอ่าน: [กิ๋น-ข้าว])
* "ขอบคุณมาก" แปลเป็น "ขอบคุณจ๊าดนัก" หรือ "ยินดีจ๊าดนัก"
* "สวัสดี" แปลเป็น "สวัสดี" (คำอ่าน: [สะ-หวัด-ดี])
* "ยินดีต้อนรับ" แปลเป็น "ยินดีต้อนฮับ" (คำอ่าน: [ยิน-ดี-ต้อน-ฮับ])
* "ขอโทษ" แปลเป็น "สูมา" (คำอ่าน: [สู-มา])

ตอบกลับเป็น JSON เท่านั้น รูปแบบ:
{
  "kam_mueang": "คำแปลคำเมือง",
  "phonetic": "คำอ่านสำเนียงคำเมือง เป็นภาษาไทย คั่นด้วยขีดลบ เช่น สะ-หวัด-ดี หรือ กิ๋น-ข้าว",
  "meaning": "คำอธิบายความหมาย 1 ประโยค"
}
`;

export async function translateWithAi(thaiText, lannaMap = null) {
  const cleanInput = (thaiText || '').trim();
  if (!cleanInput) {
    throw new Error('กรุณาระบุคำภาษาไทยก่อนแปลงด้วย AI');
  }

  let lastError = null;

  for (const model of MODELS) {
    try {
      const url = `https://generativelanguage.googleapis.com/v1beta/models/${model}:generateContent?key=${API_KEY}`;
      const res = await fetch(url, {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({
          contents: [
            {
              parts: [
                {
                  text: `${PROMPT_INSTRUCTIONS}\n\nข้อความภาษาไทยที่ต้องการแปล: "${cleanInput}"`
                }
              ]
            }
          ],
          generationConfig: {
            temperature: 0.1,
            maxOutputTokens: 1024,
            responseMimeType: 'application/json'
          }
        })
      });

      if (!res.ok) {
        throw new Error(`HTTP ${res.status}: ${res.statusText}`);
      }

      const json = await res.json();
      const rawText = json?.candidates?.[0]?.content?.parts?.[0]?.text;
      if (!rawText) {
        throw new Error('ไม่พบข้อมูลผลลัพธ์จาก AI');
      }

      const parsed = JSON.parse(rawText);
      const kamMueang = (parsed.kam_mueang || cleanInput).replace(/[\[\]]/g, '').trim();
      const reading = (parsed.phonetic || kamMueang).replace(/[\[\]]/g, '').trim();
      const meaning = parsed.meaning || '';

      // นำคำเมืองหรือคำอ่านมาแปลงเป็นตัวอักขระล้านนา Tai Tham
      const lannaWord = convertThaiToLanna(kamMueang || reading || cleanInput, lannaMap);

      return {
        kam_mueang: kamMueang,
        reading: reading,
        lanna_word: lannaWord,
        meaning: meaning,
        model: model,
      };
    } catch (err) {
      console.warn(`Gemini model ${model} failed:`, err);
      lastError = err;
    }
  }

  // Fallback: หาก AI เชื่อมต่อไม่ได้ ให้ใช้กฎการแปลงพื้นฐาน
  console.info('Falling back to local rule-based translation');
  const fallbackLanna = convertThaiToLanna(cleanInput, lannaMap);
  return {
    kam_mueang: cleanInput,
    reading: cleanInput,
    lanna_word: fallbackLanna,
    meaning: '',
    fallback: true,
  };
}
