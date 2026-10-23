#!/bin/sh
# สำรองข้อมูลห้องทดลอง n8n (บทที่ 12) รันจากโฟลเดอร์ n8n-lab: sh ch12-backup.sh
# ทดสอบกับ n8n 2.43.7, pgvector/pgvector:pg16
set -eu
STAMP=$(date +%Y%m%d-%H%M)
DEST="backups/$STAMP"
mkdir -p "$DEST"

# 1. ฐานข้อมูล n8n (workflow, credential ที่เข้ารหัสแล้ว, ประวัติการรัน) และฐาน lab (ตารางงาน, pgvector, chat memory)
#    ใช้ตัวแปร POSTGRES_USER ภายในคอนเทนเนอร์ จึงไม่ต้องพิมพ์รหัสผ่านในสคริปต์
for DB in n8n lab; do
  docker compose exec -T postgres sh -c "pg_dump -U \"\$POSTGRES_USER\" -Fc $DB" > "$DEST/$DB.dump"
done

# 2. workflow แยกไฟล์ละตัว ไว้เทียบความเปลี่ยนแปลงหรือเก็บใน git
docker compose exec -T n8n sh -c 'rm -rf /tmp/wf && n8n export:workflow --backup --output=/tmp/wf/ >/dev/null && tar -C /tmp -cf - wf' > "$DEST/workflows.tar"

# 3. ตรวจว่าไฟล์ dump อ่านได้ (นับรายการในไฟล์)
for DB in n8n lab; do
  N=$(docker compose exec -T postgres pg_restore -l < "$DEST/$DB.dump" | grep -c "TABLE DATA" || true)
  echo "$DB.dump: $N ตาราง"
done
echo "workflows.tar: $(tar -tf "$DEST/workflows.tar" | grep -c '\.json$') workflow"

# 4. ลบชุดสำรองที่เก่ากว่า 14 วัน
find backups -mindepth 1 -maxdepth 1 -type d -mtime +14 -exec rm -rf {} +

# อย่าลืม: ไฟล์ .env ที่มี N8N_ENCRYPTION_KEY ต้องเก็บแยกไว้ในที่ปลอดภัย
# ถ้าไม่มีคีย์เดิม credential ใน n8n.dump จะถอดรหัสไม่ได้
echo "สำรองไว้ที่ $DEST"
