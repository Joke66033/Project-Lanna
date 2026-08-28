SET @has_senses_json = (
  SELECT COUNT(*)
  FROM information_schema.columns
  WHERE table_schema = DATABASE()
    AND table_name = 'vocabulary_review'
    AND column_name = 'senses_json'
);

SET @add_senses_sql = IF(
  @has_senses_json = 0,
  'ALTER TABLE `vocabulary_review` ADD COLUMN `senses_json` JSON NULL AFTER `meaning`',
  'SELECT 1'
);

PREPARE add_senses_statement FROM @add_senses_sql;
EXECUTE add_senses_statement;
DEALLOCATE PREPARE add_senses_statement;
