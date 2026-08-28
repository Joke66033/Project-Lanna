<?php
/**
 * Import one reviewed-letter JSONL batch into vocabulary_review.
 *
 * Preview only:
 *   php import_vocabulary_review.php --letter=ก --file=.../ก_evidence.jsonl
 * Apply to staging table:
 *   php import_vocabulary_review.php --letter=ก --file=.../ก_evidence.jsonl --apply
 *
 * This script never writes directly to vocabulary. Promotion is intentionally
 * a separate, explicit operation after owner/expert verification.
 */

function cliOption(array $argv, string $name): ?string {
    $prefix = '--' . $name . '=';
    foreach ($argv as $argument) {
        if (strpos($argument, $prefix) === 0) {
            return substr($argument, strlen($prefix));
        }
    }
    return null;
}

function loadJsonLines(string $path): array {
    if (!is_file($path)) {
        throw new RuntimeException("ไม่พบไฟล์: $path");
    }
    $rows = [];
    $handle = fopen($path, 'rb');
    if ($handle === false) throw new RuntimeException("เปิดไฟล์ไม่ได้: $path");
    $lineNumber = 0;
    while (($line = fgets($handle)) !== false) {
        $lineNumber++;
        if (trim($line) === '') continue;
        $row = json_decode($line, true);
        if (!is_array($row)) {
            throw new RuntimeException("JSON ไม่ถูกต้องที่บรรทัด $lineNumber");
        }
        $rows[] = $row;
    }
    fclose($handle);
    return $rows;
}

function validateReviewRow(array $row, string $letter): array {
    $issues = [];
    foreach (['thai', 'lanna', 'pronunciation', 'meaning', 'initial', 'source_id', 'verification_status'] as $field) {
        if (!isset($row[$field]) || trim((string)$row[$field]) === '') $issues[] = "missing_$field";
    }
    if (($row['initial'] ?? '') !== $letter) $issues[] = 'wrong_initial';
    if (strpos((string)($row['thai'] ?? ''), '..') !== false) $issues[] = 'damaged_headword';
    if (strpos((string)($row['lanna'] ?? ''), '<ctrl') !== false) $issues[] = 'control_placeholder';
    if (preg_match('/[\x{0E00}-\x{0E7F}]/u', (string)($row['lanna'] ?? ''))) $issues[] = 'thai_in_lanna';
    if (!preg_match('/[\x{1A20}-\x{1AAF}]/u', (string)($row['lanna'] ?? ''))) $issues[] = 'no_tai_tham';
    $allowed = ['auto_checked_needs_expert', 'source_image_verified', 'owner_verified', 'expert_verified', 'verified_alias_to_source', 'rejected'];
    if (!in_array($row['verification_status'] ?? '', $allowed, true)) $issues[] = 'invalid_status';
    if (in_array(($row['verification_status'] ?? ''), ['source_image_verified', 'verified_alias_to_source'], true) && empty($row['category_reviewed'])) {
        $issues[] = 'verified_word_category_not_reviewed';
    }
    $searchAllowed = ['source_image_verified', 'reviewed_rejected', 'candidate_pages_need_manual_review', 'not_located_after_dual_ocr_needs_manual_review', 'verified_alias_to_source'];
    if (!in_array($row['source_search_status'] ?? '', $searchAllowed, true)) $issues[] = 'invalid_source_search_status';
    if (isset($row['senses'])) {
        if (!is_array($row['senses']) || $row['senses'] === []) {
            $issues[] = 'invalid_senses';
        } else {
            foreach (array_values($row['senses']) as $index => $sense) {
                if (!is_array($sense) || ($sense['sense_no'] ?? null) !== $index + 1) {
                    $issues[] = 'invalid_sense_numbering';
                    break;
                }
                foreach (['part_of_speech', 'pronunciation', 'meaning', 'category'] as $field) {
                    if (!isset($sense[$field]) || trim((string)$sense[$field]) === '') {
                        $issues[] = 'missing_sense_' . $field;
                    }
                }
            }
        }
    }
    return $issues;
}

$letter = cliOption($argv, 'letter');
$file = cliOption($argv, 'file');
$apply = in_array('--apply', $argv, true);
if ($letter === null || $file === null) {
    throw new InvalidArgumentException('ต้องระบุ --letter=ก และ --file=path/to/ก_evidence.jsonl');
}

$rows = loadJsonLines($file);
$rowsByThai = [];
foreach ($rows as $row) $rowsByThai[$row['thai'] ?? ''] = $row;
$valid = [];
$invalid = [];
foreach ($rows as $index => $row) {
    $issues = validateReviewRow($row, $letter);
    if (($row['verification_status'] ?? '') === 'verified_alias_to_source') {
        $canonical = $row['canonical_thai'] ?? '';
        if ($canonical === '' || !isset($rowsByThai[$canonical])) {
            $issues[] = 'alias_canonical_target_missing';
        } elseif (!in_array($rowsByThai[$canonical]['verification_status'] ?? '', ['source_image_verified', 'owner_verified', 'expert_verified'], true)) {
            $issues[] = 'alias_canonical_target_not_verified';
        }
        if (trim((string)($row['canonical_lanna'] ?? '')) === '') $issues[] = 'alias_canonical_lanna_missing';
    }
    if ($issues) {
        $invalid[] = ['line' => $index + 1, 'thai' => $row['thai'] ?? '', 'issues' => $issues];
    } else {
        $valid[] = $row;
    }
}

echo "พยัญชนะ: $letter" . PHP_EOL;
echo 'รายการทั้งหมด: ' . count($rows) . PHP_EOL;
echo 'พร้อมเข้าตารางพักตรวจ: ' . count($valid) . PHP_EOL;
echo 'ไม่ผ่าน: ' . count($invalid) . PHP_EOL;
if ($invalid) {
    echo json_encode(array_slice($invalid, 0, 20), JSON_UNESCAPED_UNICODE | JSON_PRETTY_PRINT) . PHP_EOL;
}
if (!$apply) {
    echo 'โหมดตรวจสอบเท่านั้น ยังไม่เขียนฐานข้อมูล' . PHP_EOL;
    exit($invalid ? 2 : 0);
}
if ($invalid) {
    throw new RuntimeException('ยกเลิกการนำเข้า เพราะยังมีรายการไม่ผ่าน');
}

require_once __DIR__ . '/../config/db.php';
$pdo = getPdo();
$exists = $pdo->query("SHOW TABLES LIKE 'vocabulary_review'")->fetchColumn();
if (!$exists) {
    throw new RuntimeException('ยังไม่มีตาราง vocabulary_review กรุณารัน migration ก่อน');
}
$sql = "INSERT INTO vocabulary_review (
    thai_word, lanna_word, reading, meaning, senses_json, initial_letter,
    proposed_category, category_confidence, category_status, category_source,
    source_type, source_id, source_page, source_url, pdf_evidence, verification_status,
    source_search_status, source_search_note,
    canonical_thai_word, canonical_lanna_word, alias_relation
) VALUES (
    :thai_word, :lanna_word, :reading, :meaning, :senses_json, :initial_letter,
    :proposed_category, :category_confidence, :category_status, :category_source,
    :source_type, :source_id, :source_page, :source_url, :pdf_evidence, :verification_status,
    :source_search_status, :source_search_note,
    :canonical_thai_word, :canonical_lanna_word, :alias_relation
) ON DUPLICATE KEY UPDATE
    reading = VALUES(reading), meaning = VALUES(meaning), senses_json = VALUES(senses_json),
    proposed_category = VALUES(proposed_category),
    category_confidence = VALUES(category_confidence),
    category_status = VALUES(category_status),
    category_source = VALUES(category_source),
    source_page = VALUES(source_page), source_url = VALUES(source_url),
    pdf_evidence = VALUES(pdf_evidence),
    source_search_status = VALUES(source_search_status),
    source_search_note = VALUES(source_search_note),
    canonical_thai_word = VALUES(canonical_thai_word),
    canonical_lanna_word = VALUES(canonical_lanna_word),
    alias_relation = VALUES(alias_relation),
    verification_status = IF(
      verification_status IN ('owner_verified', 'expert_verified'),
      verification_status,
      VALUES(verification_status)
    )";
$statement = $pdo->prepare($sql);
$pdo->beginTransaction();
try {
    foreach ($valid as $row) {
        $evidence = $row['pdf_evidence'] ?? [];
        $statement->execute([
            ':thai_word' => $row['thai'],
            ':lanna_word' => $row['lanna'],
            ':reading' => $row['pronunciation'],
            ':meaning' => $row['meaning'],
            ':senses_json' => !empty($row['senses']) ? json_encode($row['senses'], JSON_UNESCAPED_UNICODE) : null,
            ':initial_letter' => $row['initial'],
            ':proposed_category' => $row['category'] ?? 'คำศัพท์ทั่วไป',
            ':category_confidence' => (float)($row['category_confidence'] ?? 0),
            ':category_status' => !empty($row['category_reviewed']) ? 'source_reviewed' : 'proposed',
            ':category_source' => $row['category_review_source'] ?? 'automatic_rules',
            ':source_type' => $row['source_type'] ?? 'unknown',
            ':source_id' => $row['source_id'],
            ':source_page' => isset($row['source_page']) ? (string)$row['source_page'] : null,
            ':source_url' => $row['source_url'] ?? null,
            ':pdf_evidence' => json_encode($evidence, JSON_UNESCAPED_UNICODE),
            ':verification_status' => $row['verification_status'],
            ':source_search_status' => $row['source_search_status'],
            ':source_search_note' => $row['source_search_note'] ?? null,
            ':canonical_thai_word' => $row['canonical_thai'] ?? null,
            ':canonical_lanna_word' => $row['canonical_lanna'] ?? null,
            ':alias_relation' => $row['alias_relation'] ?? null,
        ]);
    }
    $pdo->commit();
    echo 'นำเข้าตารางพักตรวจสำเร็จ: ' . count($valid) . PHP_EOL;
} catch (Throwable $error) {
    if ($pdo->inTransaction()) $pdo->rollBack();
    throw $error;
}
