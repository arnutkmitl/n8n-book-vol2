-- ตารางประกอบบทที่ 12: บันทึก error จาก error workflow
-- รันด้วย: docker compose exec -T postgres psql -U n8nadmin -d lab < ch12-ops.sql
CREATE TABLE IF NOT EXISTS ops_errors (
  id            bigserial PRIMARY KEY,
  workflow_id   text,
  workflow_name text,
  execution_id  text,
  failed_node   text,
  message       text,
  created_at    timestamptz NOT NULL DEFAULT now()
);
CREATE INDEX IF NOT EXISTS ops_errors_wf_time ON ops_errors (workflow_id, created_at);
