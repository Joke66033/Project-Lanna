<?php
/**
 * lanna_generator.php (D:\PROJECT_LANNA\Lanna_API\helpers\lanna_generator.php)
 * AI-Powered Lanna Translation & Orthography Engine Helper.
 * Calls Python Lanna AI Server (Port 8005) or uses local dictionary + rule fallback.
 */

function translateThaiToLannaFull(string $word): array {
    $word = trim($word);
    if ($word === '') {
        return [
            'lanna_word' => '',
            'reading'    => '',
            'meaning'    => ''
        ];
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
                'meaning'    => $json['meaning'] ?? 'ถอดอักขระล้านนาตามหลักอักขรวิทยา'
            ];
        }
    }

    // 2. Fallback: Internal Dictionary & Rule Engine
    $specialMap = [
        'พระยา' => ['lanna' => 'ᨻᩕ᩠ᨿᩣ', 'reading' => '[พะ-ยา]', 'meaning' => 'พญา เจ้าเมือง ยศขุนนาง'],
        'ผะญ่า' => ['lanna' => 'ᨽ᩠ᨿᩣ', 'reading' => '[ผะ-หญ้า]', 'meaning' => 'ปัญญา ความรู้ สติปัญญา'],
        'ต่อคำยาวสาวคำยืด' => ['lanna' => 'ᨲᩬ᩵ᨣᩴ᩠ᨿᩣ᩠ᩅᩈᩣ᩠ᩅᨣᩴ᩠ᨿᩢ᩠ᨯ', 'reading' => '[ต่อ - กำ - ยาว - สาว - กำ - ยืด]', 'meaning' => 'สำนวน ต่อความยาวสาวความยืด ไม่จบเรื่องง่ายๆ'],
        'ดอกมัดกล้า' => ['lanna' => 'ᨯᩁ᩠ᨠᨾᩢ᩠ᨯᨠ᩠ᩃ᩶ᩣ', 'reading' => '[ดอก - มัด - กำ]', 'meaning' => 'ไม้ไผ่จักเป็นเส้นๆ ใช้มัดต้นกล้าข้าว'],
        'ทั้งหลาย' => ['lanna' => 'ᨴ᩠ᩃᩢ᩠ᨿ', 'reading' => '[ทั้ง-หลาย]', 'meaning' => 'ทั้งหมด ทุกสิ่งทุกอย่าง'],
        'สวัสดี' => ['lanna' => 'ᩈᩢ᩠ᩅᩢᩈ᩠ᨯᩦ', 'reading' => '[สะ-วัด-ดี]', 'meaning' => 'คำทักทาย สวัสดิภาพ'],
        'เวียง' => ['lanna' => 'ᩅ᩠ᨿ᩠ᨦ', 'reading' => '[เวียง]', 'meaning' => 'เมือง เมืองหลวง'],
        'ช้าง' => ['lanna' => 'ᩁᩣ', 'reading' => '[ช้าง]', 'meaning' => 'สัตว์สี่เท้าขนาดใหญ่ ช้าง'],
        'นาค' => ['lanna' => 'ᩁᩣᨠ', 'reading' => '[นาก]', 'meaning' => 'งูใหญ่ พญานาค'],
        'ปลา' => ['lanna' => 'ᨸ᩠ᩃᩣ', 'reading' => '[ปลา]', 'meaning' => 'สัตว์น้ำ']
    ];

    if (isset($specialMap[$word])) {
        return [
            'lanna_word' => $specialMap[$word]['lanna'],
            'reading'    => $specialMap[$word]['reading'],
            'meaning'    => $specialMap[$word]['meaning']
        ];
    }

    // Basic Rule-based transliteration fallback
    $generatedLanna = generateLannaUnicode($word);
    return [
        'lanna_word' => $generatedLanna,
        'reading'    => "[$word]",
        'meaning'    => 'ถอดอักขระล้านนาตามหลักอักขรวิทยา'
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
