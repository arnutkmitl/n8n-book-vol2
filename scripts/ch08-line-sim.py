"""จำลอง LINE Platform ส่ง webhook เข้า n8n แล้วรอคำตอบจาก LINE API จำลอง (บทที่ 8)

ใช้ได้โดยไม่ต้องมีบัญชี LINE OA ต้องเปิด workflow "ch08 LINE API จำลอง" และ "ch08 น้องบ้านสวน LINE OA" ไว้ก่อน
ใช้เฉพาะไลบรารีมาตรฐานของ Python 3.9 ขึ้นไป

ตัวอย่าง
  python ch08-line-sim.py --secret <channel secret> "ค่าขยะเดือนละเท่าไหร่คะ"
  python ch08-line-sim.py --secret <channel secret> --type sticker
  python ch08-line-sim.py --secret <channel secret> --time 2026-10-24T21:00 "ขยะไม่มาเก็บ 3 วันแล้ว"
  python ch08-line-sim.py --secret <channel secret> --bad-signature "ทดสอบลายเซ็นผิด"
  python ch08-line-sim.py --secret <channel secret> --tests ch08-line-tests.json --out result.json
"""
import argparse, base64, hashlib, hmac, json, os, secrets, sys, time, urllib.error, urllib.request
from datetime import datetime, timedelta, timezone

BKK = timezone(timedelta(hours=7))


def http(method, url, body=None, headers=None):
    req = urllib.request.Request(url, data=body, method=method, headers=headers or {})
    try:
        with urllib.request.urlopen(req, timeout=30) as r:
            return r.status, r.read().decode("utf-8")
    except urllib.error.HTTPError as e:
        return e.code, e.read().decode("utf-8")


def outbox(mock, after):
    status, text = http("GET", f"{mock}/outbox?after={after}")
    return json.loads(text) if status == 200 and text else []


def make_event(kind, text, user, when):
    ts = int((when or datetime.now(BKK)).timestamp() * 1000)
    # reply token จำลองฝังเวลาที่สร้างไว้ LINE API จำลองจะรับภายใน 60 วินาทีเท่านั้น
    token = f"rt-{int(time.time() * 1000)}-{secrets.token_hex(4)}"
    ev = {"type": "message", "mode": "active", "timestamp": ts, "replyToken": token,
          "webhookEventId": secrets.token_hex(13).upper(), "deliveryContext": {"isRedelivery": False},
          "source": {"type": "user", "userId": user}}
    if kind == "text":
        ev["message"] = {"id": str(ts), "type": "text", "quoteToken": secrets.token_hex(8), "text": text}
    elif kind == "sticker":
        ev["message"] = {"id": str(ts), "type": "sticker", "packageId": "446", "stickerId": "1988", "stickerResourceType": "STATIC"}
    elif kind == "image":
        ev["message"] = {"id": str(ts), "type": "image", "contentProvider": {"type": "line"}}
    elif kind == "follow":
        ev = {k: v for k, v in ev.items() if k != "message"}
        ev["type"] = "follow"
        ev["follow"] = {"isUnblocked": False}
    return ev, token


def send(args, kind, text, user, when, bad=False, wait=180):
    ev, token = make_event(kind, text, user, when)
    body = json.dumps({"destination": "U0000000000000000000000000000000", "events": [ev]},
                      ensure_ascii=False, separators=(",", ":")).encode("utf-8")
    sig = base64.b64encode(hmac.new(args.secret.encode(), body, hashlib.sha256).digest()).decode()
    if bad:
        sig = "x" + sig[1:]
    last = max([m["id"] for m in outbox(args.mock, 0)] or [0])
    t0 = time.time()
    status, _ = http("POST", args.url, body, {"Content-Type": "application/json", "x-line-signature": sig})
    result = {"http": status, "ack_seconds": round(time.time() - t0, 2), "reply_token": token}
    if status != 200:
        return result
    while time.time() - t0 < wait:
        for m in outbox(args.mock, last):
            if m.get("reply_token") == token or (m["kind"] == "push" and m.get("to_user") == user):
                result.update({"method": m["kind"], "seconds": round(time.time() - t0, 1), "answer": m["text"]})
                return result
        time.sleep(1)
    result["method"] = "timeout"
    return result


def parse_time(s):
    return datetime.fromisoformat(s).replace(tzinfo=BKK) if s else None


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("text", nargs="?", default="")
    ap.add_argument("--secret", default=os.environ.get("LINE_CHANNEL_SECRET"), help="channel secret (หรือตั้ง LINE_CHANNEL_SECRET)")
    ap.add_argument("--url", default="http://localhost:5678/webhook/line-bansuan")
    ap.add_argument("--mock", default="http://localhost:5678/webhook/mock-line")
    ap.add_argument("--user", default="U1000000000000000000000000000001")
    ap.add_argument("--type", default="text", choices=["text", "sticker", "image", "follow"])
    ap.add_argument("--time", help="เวลาที่ประชาชนส่งข้อความ เช่น 2026-10-24T21:00 (ใช้ทดสอบนอกเวลาราชการ)")
    ap.add_argument("--bad-signature", action="store_true")
    ap.add_argument("--tests")
    ap.add_argument("--out")
    args = ap.parse_args()
    if not args.secret:
        sys.exit("ต้องระบุ --secret หรือตั้งตัวแปร LINE_CHANNEL_SECRET")

    if not args.tests:
        r = send(args, args.type, args.text, args.user, parse_time(args.time), args.bad_signature)
        print(json.dumps(r, ensure_ascii=False, indent=2))
        return

    results = []
    for t in json.load(open(args.tests, encoding="utf-8")):
        r = send(args, t.get("type", "text"), t.get("text", ""), t["user"], parse_time(t.get("time")))
        answer = r.get("answer") or ""
        r["id"] = t["id"]
        r["text"] = t.get("text", "")
        r["expect"] = t.get("expect", [])
        r["pass"] = bool(answer) and any(k in answer for k in t.get("expect", [])) if t.get("expect") else bool(answer)
        results.append(r)
        print(f"{t['id']:>2} {r.get('method', r['http']):<7} {r.get('seconds', '-'):>6}s {'ผ่าน' if r['pass'] else 'ไม่ผ่าน':<6} {answer[:70]!r}")
    ok = sum(r["pass"] for r in results)
    push = sum(r.get("method") == "push" for r in results)
    print(f"ผ่าน {ok}/{len(results)} ข้อ ส่งแบบ push {push} ข้อ")
    if args.out:
        json.dump(results, open(args.out, "w", encoding="utf-8"), ensure_ascii=False, indent=2)


if __name__ == "__main__":
    main()
