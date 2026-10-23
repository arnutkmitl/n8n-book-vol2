-- ตารางของบทที่ 10 ผู้ช่วยสยามพาร์ท (ข้อมูลสมมุติ) ต้องรัน ch05-siampart.sql ก่อน
-- คัดลอกไฟล์นี้ไปไว้ในโฟลเดอร์ n8n-lab แล้วรัน
-- docker compose exec -T postgres psql -U n8nadmin -d lab < ch10-siampart-shop.sql

-- ใบเสนอราคา ราคาทุกบรรทัดคำนวณจากตาราง products ใน workflow ไม่ได้มาจากโมเดล
CREATE TABLE IF NOT EXISTS quotes (
  id          serial PRIMARY KEY,
  quote_no    text GENERATED ALWAYS AS ('QT-' || lpad(id::text, 5, '0')) STORED,
  session_id  text,
  customer    text NOT NULL,
  email       text NOT NULL,
  lines       jsonb NOT NULL,
  net         numeric(12,2) NOT NULL,
  vat         numeric(12,2) NOT NULL,
  total       numeric(12,2) NOT NULL,
  status      text NOT NULL DEFAULT 'pending',   -- pending, sent, rejected
  created_at  timestamptz NOT NULL DEFAULT now(),
  decided_at  timestamptz
);

-- บันทึกทุกรอบสนทนา ใช้วัดผลและหาบทสนทนาที่จบแล้วเพื่อสรุปเข้า CRM
CREATE TABLE IF NOT EXISTS chat_metrics (
  id          serial PRIMARY KEY,
  session_id  text NOT NULL,
  route       text NOT NULL,        -- manual, sales, staff, other
  answered    boolean NOT NULL,     -- false เมื่อตอบว่าไม่มีข้อมูลหรือเกิดข้อผิดพลาด
  latency_ms  integer NOT NULL,
  created_at  timestamptz NOT NULL DEFAULT now()
);

-- สรุปบทสนทนาสำหรับฝ่ายขาย หนึ่งแถวต่อหนึ่งบทสนทนา
CREATE TABLE IF NOT EXISTS crm_conversations (
  session_id     text PRIMARY KEY,
  customer_name  text,
  phone          text,
  summary        text,
  interest_score integer,          -- 1 ถึง 5
  products       text,
  next_action    text,
  updated_at     timestamptz NOT NULL DEFAULT now()
);
