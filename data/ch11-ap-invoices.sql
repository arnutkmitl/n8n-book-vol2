-- ตารางของบทที่ 11 ระบบรับใบแจ้งหนี้ บริษัท สยามพาร์ท ซัพพลาย (ข้อมูลสมมุติ)
-- docker compose exec -T postgres psql -U n8nadmin -d lab < ch11-ap-invoices.sql

-- ทะเบียนผู้ขาย ใบแจ้งหนี้จากผู้ขายที่ไม่อยู่ในทะเบียนจะไม่ผ่านการตรวจ
DROP TABLE IF EXISTS vendors CASCADE;
CREATE TABLE vendors (
  tax_id  text PRIMARY KEY,
  name    text NOT NULL,
  email   text
);
INSERT INTO vendors VALUES
('0105558123451', 'บริษัท ไทยแบริ่ง เทรดดิ้ง จำกัด', 'billing@thaibearing.test'),
('0303557008719', 'ห้างหุ้นส่วนจำกัด เกษตรภัณฑ์ยางไทย', 'account@kasetyang.test'),
('0105561044205', 'บริษัท สยามฟิลเตอร์ อินดัสทรี จำกัด', 'ar@siamfilter.test');

-- ใบแจ้งหนี้ที่รับเข้า หนึ่งผู้ขายใช้เลขที่ใบแจ้งหนี้ซ้ำไม่ได้
DROP TABLE IF EXISTS invoices;
CREATE TABLE invoices (
  id            serial PRIMARY KEY,
  vendor_tax_id text NOT NULL,
  invoice_no    text NOT NULL,
  invoice_date  text,
  subtotal      numeric(12,2),
  vat           numeric(12,2),
  total         numeric(12,2),
  extracted     jsonb,
  problems      text,
  status        text NOT NULL,      -- pending_approval, approved, rejected, failed_check
  source_file   text,
  created_at    timestamptz NOT NULL DEFAULT now(),
  UNIQUE (vendor_tax_id, invoice_no)
);
-- ใบที่จ่ายไปแล้วเมื่อเดือนก่อน ใช้ทดสอบการตรวจเลขที่ซ้ำ
INSERT INTO invoices (vendor_tax_id, invoice_no, invoice_date, subtotal, vat, total, status, source_file)
VALUES ('0105558123451', 'IV6809-0153', '17/09/2569', 7800.00, 546.00, 8346.00, 'approved', 'iv6809-0153.pdf');
