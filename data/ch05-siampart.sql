-- ข้อมูลตัวอย่างบทที่ 5: บริษัท สยามพาร์ท ซัพพลาย จำกัด (ข้อมูลสมมุติ)
-- คัดลอกไฟล์นี้ไปไว้ในโฟลเดอร์ n8n-lab แล้วรันด้วย: docker compose exec -T postgres psql -U n8nadmin -d lab < ch05-siampart.sql

DROP TABLE IF EXISTS products;
CREATE TABLE products (
  sku        text PRIMARY KEY,
  name       text NOT NULL,
  fits       text,            -- ใช้กับเครื่องรุ่นใด
  unit       text NOT NULL,
  price      numeric(10,2) NOT NULL,  -- ราคาต่อหน่วย ยังไม่รวม VAT
  stock      integer NOT NULL
);

INSERT INTO products VALUES
('BR-6204',  'ลูกปืน 6204 ZZ',                         'รถไถเดินตาม, ปั๊มน้ำ',         'ตัว',   85.00, 320),
('BR-6205',  'ลูกปืน 6205 ZZ',                         'รถไถเดินตาม, เครื่องสีข้าว',   'ตัว',   110.00, 140),
('BT-B52',   'สายพานร่อง B เบอร์ 52',                  'รถไถเดินตาม 10 ถึง 14 แรงม้า', 'เส้น',  180.00, 75),
('BT-B60',   'สายพานร่อง B เบอร์ 60',                  'เครื่องสีข้าวขนาดเล็ก',        'เส้น',  210.00, 0),
('FL-OIL14', 'ไส้กรองน้ำมันเครื่อง ดีเซล 14 แรงม้า',   'เครื่องยนต์ดีเซลสูบเดียว 14 แรงม้า', 'ลูก', 95.00, 210),
('FL-AIR14', 'ไส้กรองอากาศ ดีเซล 14 แรงม้า',           'เครื่องยนต์ดีเซลสูบเดียว 14 แรงม้า', 'ลูก', 160.00, 48),
('BL-GR10',  'ใบมีดตัดหญ้า 10 นิ้ว ฟันเลื่อย',         'เครื่องตัดหญ้าสะพายบ่า',       'ใบ',    120.00, 500),
('BL-NY30',  'เอ็นตัดหญ้า 3 มม. ม้วน 15 เมตร',         'เครื่องตัดหญ้าสะพายบ่า',       'ม้วน',  65.00, 260),
('PM-SEAL1', 'ซีลปั๊มน้ำ 1 นิ้ว',                      'ปั๊มน้ำหอยโข่ง 1 นิ้ว',        'ชุด',   145.00, 33),
('PL-SPK7',  'หัวเทียนเครื่องยนต์เบนซินเล็ก',          'เครื่องตัดหญ้า, เครื่องพ่นยา', 'หัว',   45.00, 600),
('NZ-SPR01', 'หัวฉีดพ่นยาทองเหลือง ปรับได้',           'เครื่องพ่นยาแรงดันสูง',        'หัว',   75.00, 12),
('TR-RT14',  'ยางรถไถเดินตาม 6-12',                    'รถไถเดินตาม 10 ถึง 14 แรงม้า', 'เส้น',  1450.00, 8);

DROP TABLE IF EXISTS leads;
CREATE TABLE leads (
  id          serial PRIMARY KEY,
  created_at  timestamptz DEFAULT now(),
  customer    text NOT NULL,
  phone       text,
  sku         text,
  qty         integer,
  note        text
);

DROP TABLE IF EXISTS orders;
CREATE TABLE orders (
  order_no   text PRIMARY KEY,
  customer   text,
  status     text,
  carrier    text,
  eta        date
);
INSERT INTO orders VALUES
('SO-2569-0412', 'ร้านเกษตรรุ่งเรือง', 'จัดส่งแล้ว', 'ขนส่งเอกชน', '2026-10-21'),
('SO-2569-0415', 'สหกรณ์การเกษตรหนองบัว', 'กำลังแพ็กสินค้า', NULL, '2026-10-23'),
('SO-2569-0420', 'คุณวิไล ไร่อ้อย', 'รอชำระเงิน', NULL, NULL);
