-- ตารางของบทที่ 8 น้องบ้านสวน LINE OA
-- คัดลอกไฟล์นี้ไปไว้ในโฟลเดอร์ n8n-lab แล้วรัน
-- docker compose exec -T postgres psql -U n8nadmin -d lab < ch08-bansuan-line.sql

-- เรื่องที่ส่งต่อเจ้าหน้าที่ (ร้องเรียน และขอคุยกับเจ้าหน้าที่) บทที่ 9 ใช้ตารางนี้ต่อ
CREATE TABLE IF NOT EXISTS citizen_requests (
  id           serial PRIMARY KEY,
  ticket_no    text GENERATED ALWAYS AS ('BS-' || lpad(id::text, 6, '0')) STORED,
  channel      text NOT NULL,              -- line, email, form
  kind         text NOT NULL,              -- complaint, staff
  line_user_id text,
  message      text NOT NULL,
  status       text NOT NULL DEFAULT 'new',
  created_at   timestamptz NOT NULL DEFAULT now()
);

-- ข้อความที่ LINE API จำลองได้รับ ใช้ตรวจผลระหว่างทดสอบเท่านั้น
CREATE TABLE IF NOT EXISTS line_mock_outbox (
  id          serial PRIMARY KEY,
  kind        text NOT NULL,               -- reply, push
  reply_token text,
  to_user     text,
  payload     jsonb,
  created_at  timestamptz NOT NULL DEFAULT now()
);
CREATE UNIQUE INDEX IF NOT EXISTS line_mock_outbox_reply_token
  ON line_mock_outbox (reply_token) WHERE reply_token IS NOT NULL;
