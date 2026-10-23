"""สร้างใบแจ้งหนี้สมมุติ 6 ใบ (PDF) และภาพสแกน 1 ใบ สำหรับบทที่ 11 ด้วย Chrome headless
ใบที่ 1 ถึง 3 ถูกต้อง ใบที่ 4 ผลรวมรายการไม่ตรงยอด ใบที่ 5 VAT ผิด ใบที่ 6 เลขที่ซ้ำกับใบที่จ่ายไปแล้ว"""
import json, os, subprocess, sys

HERE = os.path.dirname(os.path.abspath(__file__))
# วางสคริปต์นี้ในโฟลเดอร์ scripts ของชุดไฟล์ประกอบ ไฟล์ที่สร้างจะไปอยู่ในโฟลเดอร์ invoices ข้างกัน
OUT = os.path.join(HERE, "..", "invoices")
# ตำแหน่งโปรแกรม Chrome หรือ Chromium เปลี่ยนได้ด้วยตัวแปร CHROME เช่น CHROME=/usr/bin/chromium
CHROME = os.environ.get("CHROME", r"C:\Program Files\Google\Chrome\Application\chrome.exe")


def tax_id(base12):
    """เติมหลักตรวจสอบของเลขประจำตัวผู้เสียภาษี 13 หลัก"""
    s = sum(int(d) * (13 - i) for i, d in enumerate(base12))
    return base12 + str((11 - s % 11) % 10)


VENDORS = {
    "V1": {"name": "บริษัท ไทยแบริ่ง เทรดดิ้ง จำกัด", "tax_id": tax_id("010555812345"), "addr": "88 ถนนพระราม 2 แขวงแสมดำ เขตบางขุนเทียน กรุงเทพฯ 10150"},
    "V2": {"name": "ห้างหุ้นส่วนจำกัด เกษตรภัณฑ์ยางไทย", "tax_id": tax_id("030355700871"), "addr": "12/4 หมู่ 3 ตำบลในเมือง อำเภอเมือง จังหวัดนครราชสีมา 30000"},
    "V3": {"name": "บริษัท สยามฟิลเตอร์ อินดัสทรี จำกัด", "tax_id": tax_id("010556104420"), "addr": "301 นิคมอุตสาหกรรมบางปู ตำบลแพรกษา อำเภอเมือง จังหวัดสมุทรปราการ 10280"},
}
BUYER = "บริษัท สยามพาร์ท ซัพพลาย จำกัด (สำนักงานใหญ่) เลขประจำตัวผู้เสียภาษี 0405561000127"

INVOICES = [
    {"file": "inv1-thaibearing.pdf", "v": "V1", "no": "IV6810-0231", "date": "15/10/2569", "font": "Tahoma",
     "lines": [("ลูกปืน 6204 ZZ", 200, 52.00), ("ลูกปืน 6205 ZZ", 100, 68.00)], "error": None},
    {"file": "inv2-kasetyang.pdf", "v": "V2", "no": "KY-2569/1187", "date": "16/10/2569", "font": "TH Sarabun New",
     "lines": [("สายพานร่อง B เบอร์ 52", 60, 112.00), ("ยางรถไถเดินตาม 6-12", 10, 980.00)], "error": None},
    {"file": "inv3-siamfilter.pdf", "v": "V3", "no": "SF25691020-07", "date": "20/10/2569", "font": "Tahoma",
     "lines": [("ไส้กรองน้ำมันเครื่อง ดีเซล 14 แรงม้า", 150, 58.00), ("ไส้กรองอากาศ ดีเซล 14 แรงม้า", 40, 101.50)], "error": None},
    {"file": "inv4-thaibearing-sum.pdf", "v": "V1", "no": "IV6810-0244", "date": "18/10/2569", "font": "Tahoma",
     "lines": [("ลูกปืน 6204 ZZ", 100, 52.00), ("ลูกปืน 6205 ZZ", 80, 68.00)], "error": "sum", "subtotal_override": 11040.00},
    {"file": "inv5-kasetyang-vat.pdf", "v": "V2", "no": "KY-2569/1201", "date": "19/10/2569", "font": "Tahoma",
     "lines": [("สายพานร่อง B เบอร์ 60", 40, 125.00), ("สายพานร่อง B เบอร์ 52", 30, 112.00)], "error": "vat", "vat_override": 581.00},
    {"file": "inv6-thaibearing-dup.pdf", "v": "V1", "no": "IV6809-0153", "date": "17/10/2569", "font": "Tahoma",
     "lines": [("ลูกปืน 6204 ZZ", 150, 52.00)], "error": "duplicate"},
]


def fmt(n):
    return f"{n:,.2f}"


def html(inv):
    v = VENDORS[inv["v"]]
    lines = [(d, q, p, round(q * p, 2)) for d, q, p in inv["lines"]]
    subtotal = inv.get("subtotal_override", round(sum(a for *_, a in lines), 2))
    vat = inv.get("vat_override", round(subtotal * 0.07, 2))
    total = round(subtotal + vat, 2)
    rows = "".join(f"<tr><td>{i + 1}</td><td>{d}</td><td class=n>{q:,}</td><td class=n>{fmt(p)}</td><td class=n>{fmt(a)}</td></tr>"
                   for i, (d, q, p, a) in enumerate(lines))
    page = f"""<!doctype html><html><head><meta charset="utf-8"><style>
body{{font-family:'{inv['font']}',Tahoma,sans-serif;font-size:{'16pt' if 'Sarabun' in inv['font'] else '11pt'};margin:30px}}
table{{width:100%;border-collapse:collapse;margin-top:12px}} th,td{{border:1px solid #666;padding:4px 6px}} .n{{text-align:right}}
h1{{font-size:{'24pt' if 'Sarabun' in inv['font'] else '16pt'};margin:0 0 6px}}</style></head><body>
<h1>ใบแจ้งหนี้ / ใบกำกับภาษี</h1>
<p><b>{v['name']}</b><br>{v['addr']}<br>เลขประจำตัวผู้เสียภาษี {v['tax_id']}</p>
<p>เลขที่ {inv['no']} &nbsp;&nbsp; วันที่ {inv['date']}<br>ลูกค้า {BUYER}<br>ครบกำหนดชำระ 30 วัน</p>
<table><tr><th>ลำดับ</th><th>รายการ</th><th>จำนวน</th><th>ราคาต่อหน่วย</th><th>จำนวนเงิน</th></tr>{rows}
<tr><td colspan=4 class=n>รวมเงิน</td><td class=n>{fmt(subtotal)}</td></tr>
<tr><td colspan=4 class=n>ภาษีมูลค่าเพิ่ม 7%</td><td class=n>{fmt(vat)}</td></tr>
<tr><td colspan=4 class=n>จำนวนเงินรวมทั้งสิ้น</td><td class=n>{fmt(total)}</td></tr></table>
<p>เอกสารสมมุติเพื่อการฝึกในหนังสือ n8n เล่ม 2 ไม่ใช่เอกสารจริง</p></body></html>"""
    return page, {"invoice_no": inv["no"], "vendor": v["name"], "vendor_tax_id": v["tax_id"], "subtotal": subtotal, "vat": vat,
                  "total": total, "lines_sum": round(sum(a for *_, a in lines), 2), "error": inv["error"], "font": inv["font"]}


if __name__ == "__main__":
    os.makedirs(OUT, exist_ok=True)
    tmp = os.path.join(OUT, "_html")
    os.makedirs(tmp, exist_ok=True)
    meta = []
    for inv in INVOICES:
        page, m = html(inv)
        h = os.path.join(tmp, inv["file"].replace(".pdf", ".html"))
        open(h, "w", encoding="utf-8").write(page)
        subprocess.run([CHROME, "--headless=new", "--disable-gpu", "--no-pdf-header-footer",
                        "--print-to-pdf=" + os.path.abspath(os.path.join(OUT, inv["file"])), "file:///" + os.path.abspath(h).replace("\\", "/")],
                       check=True, capture_output=True)
        m["file"] = inv["file"]
        meta.append(m)
    # ภาพสแกนของใบที่ 1 สำหรับทดลองโมเดลที่อ่านภาพได้
    h = os.path.join(tmp, "inv1-thaibearing.html")
    subprocess.run([CHROME, "--headless=new", "--disable-gpu", "--window-size=900,1000", "--hide-scrollbars",
                    "--screenshot=" + os.path.abspath(os.path.join(OUT, "inv1-thaibearing-scan.png")), "file:///" + os.path.abspath(h).replace("\\", "/")],
                   check=True, capture_output=True)
    json.dump({"vendors": VENDORS, "invoices": meta}, open(os.path.join(OUT, "expected.json"), "w", encoding="utf-8"), ensure_ascii=False, indent=1)
    print(json.dumps(meta, ensure_ascii=False, indent=1))
