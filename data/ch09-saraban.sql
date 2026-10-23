-- ตารางของบทที่ 9 ระบบรับเรื่องและคัดแยกหนังสือ เทศบาลเมืองบ้านสวน (ข้อมูลสมมุติ)
-- ต้องรัน ch08-bansuan-line.sql ก่อน เพราะต่อยอดตาราง citizen_requests
-- คัดลอกไฟล์นี้ไปไว้ในโฟลเดอร์ n8n-lab แล้วรัน
-- docker compose exec -T postgres psql -U n8nadmin -d lab < ch09-saraban.sql

-- กองและหน้าที่ ใช้ทั้งเป็นรายการให้โมเดลเลือก และเป็นสมุดที่อยู่อีเมลของหัวหน้ากอง
DROP TABLE IF EXISTS departments;
CREATE TABLE departments (
  code       text PRIMARY KEY,
  name       text NOT NULL,
  duties     text NOT NULL,
  head_email text NOT NULL,
  phone_ext  text
);
INSERT INTO departments VALUES
('PALAD',   'สำนักปลัดเทศบาล', 'งานสารบรรณ งานธุรการทั่วไป ข้อมูลข่าวสารของราชการ งานเทศกิจ การขายของในที่สาธารณะ ป้องกันและบรรเทาสาธารณภัย เรื่องร้องเรียนเจ้าหน้าที่ การประชุมและงานพิธี', 'palad@bansuan.test', '100'),
('FINANCE', 'กองคลัง', 'ภาษีที่ดินและสิ่งปลูกสร้าง ภาษีป้าย การรับชำระค่าธรรมเนียม การเงิน บัญชี พัสดุและการจัดซื้อจัดจ้าง', 'finance@bansuan.test', '120'),
('ENGINEER','กองช่าง', 'ถนน ทางเท้า สะพาน ท่อระบายน้ำ ไฟฟ้าส่องสว่างสาธารณะ ใบอนุญาตก่อสร้างและรื้อถอนอาคาร การก่อสร้างผิดแบบ', 'engineer@bansuan.test', '310'),
('HEALTH',  'กองสาธารณสุขและสิ่งแวดล้อม', 'การเก็บขนขยะ ความสะอาด เหตุรำคาญ กลิ่น เสียง ควัน รถดูดสิ่งปฏิกูล สุขาภิบาลอาหาร โรคติดต่อ สัตว์จรจัด', 'health@bansuan.test', '210'),
('SOCIAL',  'กองสวัสดิการสังคม', 'เบี้ยยังชีพผู้สูงอายุและคนพิการ รถรับส่งผู้ป่วย ผู้ด้อยโอกาส การพัฒนาชุมชน', 'social@bansuan.test', '410'),
('EDU',     'กองการศึกษา', 'โรงเรียนและศูนย์พัฒนาเด็กเล็กของเทศบาล กีฬา ศาสนา วัฒนธรรมและประเพณี', 'edu@bansuan.test', '510');

-- คอลัมน์ที่บทที่ 9 เพิ่มให้ตารางเรื่องรับ
ALTER TABLE citizen_requests
  ADD COLUMN IF NOT EXISTS sender      text,
  ADD COLUMN IF NOT EXISTS contact     text,
  ADD COLUMN IF NOT EXISTS subject     text,
  ADD COLUMN IF NOT EXISTS doc_type    text,      -- ร้องเรียน, หนังสือราชการ, คำขอรับบริการ, อื่น ๆ
  ADD COLUMN IF NOT EXISTS summary     text,
  ADD COLUMN IF NOT EXISTS location    text,
  ADD COLUMN IF NOT EXISTS urgency     text,      -- ด่วนมาก, ด่วน, ปกติ
  ADD COLUMN IF NOT EXISTS proposed_department text REFERENCES departments(code),
  ADD COLUMN IF NOT EXISTS department  text REFERENCES departments(code),
  ADD COLUMN IF NOT EXISTS draft_reply text,
  ADD COLUMN IF NOT EXISTS source_ref  text,      -- Message-ID ของอีเมล กันรับเรื่องเดียวซ้ำ
  ADD COLUMN IF NOT EXISTS triaged_at  timestamptz,
  ADD COLUMN IF NOT EXISTS assigned_at timestamptz,
  ADD COLUMN IF NOT EXISTS due_date    date,
  ADD COLUMN IF NOT EXISTS closed_at   timestamptz,
  ADD COLUMN IF NOT EXISTS last_alert_days int NOT NULL DEFAULT 0;
CREATE UNIQUE INDEX IF NOT EXISTS citizen_requests_source_ref ON citizen_requests (source_ref) WHERE source_ref IS NOT NULL;

-- สถานะ: new (รับเข้า) -> triaging (กำลังคัดแยก) -> triaged (AI เสนอกองแล้ว รอเจ้าหน้าที่ยืนยัน) -> assigned (ส่งกองแล้ว) -> closed (ปิดเรื่อง)
--        ถ้าเจ้าหน้าที่ส่งคืน -> returned (ให้งานสารบรรณคัดเอง)
