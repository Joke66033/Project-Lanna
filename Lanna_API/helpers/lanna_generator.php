<?php
/**
 * lanna_generator.php (D:\PROJECT_LANNA\Lanna_API\helpers\lanna_generator.php)
 * AI-Powered Lanna Translation & Orthography Engine Helper.
 * Calls Python Lanna AI Server (Port 8005) or uses local dictionary + rule fallback.
 */

require_once __DIR__ . '/../config/db.php';

function translateThaiToLannaFull(string $word): array {
    $word = trim($word);
    if ($word === '') {
        return [
            'lanna_word' => '',
            'reading'    => '',
            'meaning'    => ''
        ];
    }

    // 0. Database lookup first (Single Source of Truth for verified words)
    try {
        $pdo = getPdo();
        
        // A. Check if the word is an exact headword (Lanna-in-Thai)
        $stmt = $pdo->prepare("SELECT * FROM `vocabulary` WHERE BINARY `thai_word` = :word LIMIT 1");
        $stmt->execute(['word' => $word]);
        $row = $stmt->fetch(PDO::FETCH_ASSOC);
        
        if ($row) {
            return [
                'lanna_word' => $row['lanna_word'],
                'reading'    => $row['reading'],
                'meaning'    => $row['meaning'],
                'confidence' => 1.0,
                'needs_review' => false,
                'result_label' => 'คำที่ตรวจสอบแล้ว (ฐานข้อมูล)',
                'segments' => []
            ];
        }
        
        // B. Check if the word is inside the meaning (Central Thai -> Lanna translation)
        $stmt = $pdo->prepare("SELECT * FROM `vocabulary` WHERE `meaning` LIKE :pattern LIMIT 10");
        $stmt->execute(['pattern' => '%' . $word . '%']);
        $rows = $stmt->fetchAll(PDO::FETCH_ASSOC);
        
        if (!empty($rows)) {
            // Find the best match: prefer one where the meaning defines the word directly (e.g. starts with "น. สับปะรด")
            $bestRow = null;
            foreach ($rows as $r) {
                $m = trim($r['meaning']);
                if (preg_match('/^([a-zA-Zก-ฮ]+\.\s*)?' . preg_quote($word, '/') . '(\s*|;|,|$)/iu', $m)) {
                    $bestRow = $r;
                    break;
                }
            }
            if ($bestRow !== null) {
                return [
                    'lanna_word' => $bestRow['lanna_word'],
                    'reading'    => $bestRow['reading'],
                    'meaning'    => $bestRow['meaning'],
                    'confidence' => 0.95,
                    'needs_review' => false,
                    'result_label' => 'คำที่ตรวจสอบแล้ว (ฐานข้อมูล)',
                    'segments' => []
                ];
            }
        }
    } catch (Exception $e) {
        // Fallback to AI if database is offline/unreachable
    }

    // 1. Try calling the Python Lanna AI Server (Port 8005)
    $aiUrl = 'http://localhost:8005/translate?keyword=' . rawurlencode($word);
    $ch = curl_init();
    curl_setopt($ch, CURLOPT_URL, $aiUrl);
    curl_setopt($ch, CURLOPT_RETURNTRANSFER, true);
    curl_setopt($ch, CURLOPT_TIMEOUT, 3);
    $response = curl_exec($ch);
    $httpCode = curl_getinfo($ch, CURLINFO_HTTP_CODE);
    curl_close($ch);

    if ($httpCode === 200 && $response) {
        $json = json_decode($response, true);
        if (isset($json['status']) && $json['status'] === 'success') {
            return [
                'lanna_word' => $json['lanna_word'] ?? '',
                'reading'    => $json['reading'] ?? "[$word]",
                'meaning'    => $json['meaning'] ?? 'ถอดอักขระล้านนาตามหลักอักขรวิทยา',
                'confidence' => $json['confidence'] ?? 0.0,
                'needs_review' => $json['needs_review'] ?? true,
                'result_label' => $json['result_label'] ?? 'คำแนะนำอัตโนมัติ',
                'segments' => $json['segments'] ?? []
            ];
        }
    }

    // 2. Fallback: Internal Dictionary & Rule Engine
    $specialMap = [
        'ล้านนา' => ['lanna' => 'ᩃ᩶ᩣᨶᨶᩣ', 'reading' => '[ล้าน-นา]', 'meaning' => 'น. ดินแดนทางภาคเหนือของไทย เดิมเป็นอาณาจักรใหญ่'],
        'พระยา' => ['lanna' => 'ᨻᩕ᩠ᨿᩣ', 'reading' => '[พะ-ยา]', 'meaning' => 'พญา เจ้าเมือง ยศขุนนาง'],
        'ผะญ่า' => ['lanna' => 'ᨽ᩠ᨿᩣ', 'reading' => '[ผะ-หญ้า]', 'meaning' => 'ปัญญา ความรู้ สติปัญญา'],
        'ต่อคำยาวสาวคำยืด' => ['lanna' => 'ᨲᩬ᩵ᨣᩴ᩠ᨿᩣ᩠ᩅᩈᩣ᩠ᩅᨣᩴ᩠ᨿᩢ᩠ᨯ', 'reading' => '[ต่อ - กำ - ยาว - สาว - กำ - ยืด]', 'meaning' => 'สำนวน ต่อความยาวสาวความยืด ไม่จบเรื่องง่ายๆ'],
        'ดอกมัดกล้า' => ['lanna' => 'ᨯᩁ᩠ᨠᨾᩢ᩠ᨯᨠ᩠ᩃ᩶ᩣ', 'reading' => '[ดอก - มัด - กำ]', 'meaning' => 'ไม้ไผ่จักเป็นเส้นๆ ใช้มัดต้นกล้าข้าว'],
        'ทั้งหลาย' => ['lanna' => 'ᨴ᩠ᩃᩢ᩠ᨿ', 'reading' => '[ทั้ง-หลาย]', 'meaning' => 'ทั้งหมด ทุกสิ่งทุกอย่าง'],
        'สวัสดี' => ['lanna' => 'ᩈ᩠ᩅᩢᩈ᩠ᨯᩦ', 'reading' => '[สะ-วัด-ดี]', 'meaning' => 'คำทักทาย สวัสดิภาพ'],
        'เวียง' => ['lanna' => 'ᩅ᩠ᨿ᩠ᨦ', 'reading' => '[เวียง]', 'meaning' => 'เมือง เมืองหลวง'],
        'ช้าง' => ['lanna' => 'ᩁᩣ', 'reading' => '[ช้าง]', 'meaning' => 'สัตว์สี่เท้าขนาดใหญ่ ช้าง'],
        'นาค' => ['lanna' => 'ᩁᩣᨠ', 'reading' => '[นาก]', 'meaning' => 'งูใหญ่ พญานาค'],
        'ปลา' => ['lanna' => 'ᨸ᩠ᩃᩣ', 'reading' => '[ปลา]', 'meaning' => 'สัตว์น้ำ'],
        'ข้าว' => ['lanna' => 'ᨡ᩶ᩣ', 'reading' => '[เข้า]', 'meaning' => 'น. เมล็ดข้าวสีขาวที่เอาไว้กิน พืชธัญญาชาติ'],
        'เข้า' => ['lanna' => 'ᨡ᩶ᩣ', 'reading' => '[เข้า]', 'meaning' => 'น. ข้าว พืชที่ใช้เมล็ดบริโภคเป็นอาหารหลัก'],
        'ขนม' => ['lanna' => 'ᨡ᩶ᩣᩉ᩠ᨶᨾ', 'reading' => '[เข้า - หนม]', 'meaning' => 'น. ขนม ของหวาน ของกินเล่น'],
        'เข้าหนม' => ['lanna' => 'ᨡ᩶ᩣᩉ᩠ᨶᨾ', 'reading' => '[เข้า - หนม]', 'meaning' => 'น. ขนม'],
        'วัด' => ['lanna' => 'ᩅ᩠ᨯ', 'reading' => '[วัด]', 'meaning' => 'น. วัด ศาสนสถานของชาวพุทธ'],
        'วัดพระสิงห์' => ['lanna' => 'ᩅ᩠ᨯᨻᩕᩈᩥᨦ᩠ᨻ᩺', 'reading' => '[วัด - พระ - สิงห์]', 'meaning' => 'น. วัดพระสิงห์วรมหาวิหาร พระอารามหลวงชั้นเอก จังหวัดเชียงใหม่']
    ];

    if (isset($specialMap[$word])) {
        return [
            'lanna_word' => $specialMap[$word]['lanna'],
            'reading'    => $specialMap[$word]['reading'],
            'meaning'    => $specialMap[$word]['meaning'],
            'confidence' => 0.95,
            'needs_review' => false,
            'result_label' => 'คำที่ตรวจสอบแล้ว',
            'segments' => []
        ];
    }

    // Basic Rule-based transliteration fallback
    $generatedLanna = generateLannaUnicode($word);
    return [
        'lanna_word' => $generatedLanna,
        'reading'    => "[$word]",
        'meaning'    => 'ผลถอดอักษรอัตโนมัติ โปรดตรวจสอบ',
        'confidence' => 0.55,
        'needs_review' => true,
        'result_label' => 'คำแนะนำอัตโนมัติ',
        'segments' => []
    ];
}

function generateLannaUnicode(string $word): string {
    $word = trim($word);
    if ($word === '') return '';

    $consonants = [
        'ก' => 'ᨠ', 'ข' => 'ᨡ', 'ฃ' => 'ᨡ', 'ค' => 'ᨣ', 'ฅ' => 'ᨣ', 'ฆ' => 'ᨤ', 'ง' => 'ᨦ',
        'จ' => 'ᨧ', 'ฉ' => 'ᨨ', 'ช' => 'ᨩ', 'ซ' => 'ᨪ', 'ฌ' => 'ᨫ', 'ญ' => 'ᨬ',
        'ฎ' => 'ᨯ', 'ฏ' => 'ᨲ', 'ฐ' => 'ᨳ', 'ฑ' => 'ᨴ', 'ฒ' => 'ᨵ', 'ณ' => 'ᨶ',
        'ด' => 'ᨯ', 'ต' => 'ᨲ', 'ถ' => 'ᨳ', 'ท' => 'ᨴ', 'ธ' => 'ᨵ', 'น' => 'ᨶ',
        'บ' => 'ᨷ', 'ป' => 'ᨸ', 'ผ' => 'ᨹ', 'ฝ' => 'ᨺ', 'พ' => 'ᨻ', 'ฟ' => 'ᨼ', 'ภ' => 'ᨽ', 'ม' => 'ᨾ',
        'ย' => 'ᨿ', 'ร' => 'ᩁ', 'ล' => 'ᩃ', 'ว' => 'ᩅ', 'ศ' => 'ᩈ', 'ษ' => 'ᩈ', 'ส' => 'ᩈ', 'ห' => 'ᩉ', 'ฬ' => 'ᩃ', 'อ' => 'ᩋ', 'ฮ' => 'ᩉ'
    ];

    $vowels = [
        'ะ' => "\u{1A61}", 'า' => "\u{1A63}", 'ิ' => "\u{1A65}", 'ี' => "\u{1A66}",
        'ึ' => "\u{1A67}", 'ื' => "\u{1A68}", 'ุ' => "\u{1A69}", 'ู' => "\u{1A6A}",
        'เ' => "\u{1A6E}", 'แ' => "\u{1A6F}", 'โ' => "\u{1A70}", 'ใ' => "\u{1A72}", 'ไ' => "\u{1A71}",
        'ำ' => "\u{1A63}\u{1A74}", '็' => "\u{1A7C}", 'ั' => "\u{1A62}"
    ];

    $tones = [
        '่' => "\u{1A75}", '้' => "\u{1A76}", '๊' => "\u{1A77}", '๋' => "\u{1A78}"
    ];

    $chars = mb_str_split($word);
    $output = '';
    foreach ($chars as $ch) {
        if (isset($consonants[$ch])) {
            $output .= $consonants[$ch];
        } elseif (isset($vowels[$ch])) {
            $output .= $vowels[$ch];
        } elseif (isset($tones[$ch])) {
            $output .= $tones[$ch];
        } else {
            $output .= $ch;
        }
    }
    return $output;
}

/**
 * Generate Lanna Typing Sequence string format (e.g. "เน + ้ + ๋ + ๑ + ฯ" or "นายฯ / น่านฯ / เน + ้ + ๋ + ๑ + ฯ")
 */
function generateLannaTypingSequence(string $word): string {
    $word = trim($word);
    if ($word === '') return '';

    // If input already contains '+' or '/', return as is
    if (strpos($word, '+') !== false || strpos($word, '/') !== false) {
        return $word;
    }

    $chars = mb_str_split($word);
    $parts = [];
    
    foreach ($chars as $ch) {
        if (trim($ch) === '') continue;
        $parts[] = $ch;
    }

    return implode(' + ', $parts);
}

