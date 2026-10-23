"""ทดสอบ MCP Server Trigger ของบทที่ 5: initialize -> tools/list -> tools/call

วิธีใช้ (Python 3.9 ขึ้นไป ไม่ต้องติดตั้งไลบรารีเพิ่ม)
    ตั้งตัวแปร MCP_TOKEN เป็นค่าเดียวกับ Credential "MCP siampart token" แล้วรัน
    Linux/macOS:  MCP_TOKEN=xxxx python3 ch05-mcp-test.py
    PowerShell:   $env:MCP_TOKEN="xxxx"; python ch05-mcp-test.py
"""
import json
import os
import re
import sys
import urllib.request

URL = sys.argv[1] if len(sys.argv) > 1 else "http://localhost:5678/mcp/siampart"
TOKEN = os.environ.get("MCP_TOKEN", "")
session_id = None


def rpc(method, params=None, msg_id=None):
    global session_id
    body = {"jsonrpc": "2.0", "method": method, "params": params or {}}
    if msg_id is not None:
        body["id"] = msg_id
    headers = {"Content-Type": "application/json",
               "Accept": "application/json, text/event-stream",
               "Authorization": "Bearer " + TOKEN}
    if session_id:
        headers["mcp-session-id"] = session_id
    req = urllib.request.Request(URL, data=json.dumps(body).encode(), headers=headers, method="POST")
    with urllib.request.urlopen(req, timeout=120) as r:
        session_id = r.headers.get("mcp-session-id") or session_id
        text = r.read().decode("utf-8")
    # server ตอบเป็น Server-Sent Events บรรทัดที่ขึ้นต้นด้วย data: คือข้อความ JSON-RPC
    data = re.findall(r"^data: (.*)$", text, re.M)
    if data:
        return json.loads(data[-1])
    return json.loads(text) if text.strip() else None


init = rpc("initialize", {"protocolVersion": "2025-03-26", "capabilities": {},
                          "clientInfo": {"name": "n8n-book-test", "version": "1"}}, 0)
print("server:", init["result"]["serverInfo"], "\ninstructions:", init["result"].get("instructions"))
rpc("notifications/initialized")

for tool in rpc("tools/list", msg_id=1)["result"]["tools"]:
    print("TOOL", tool["name"], "|", tool.get("description", "")[:70])

calc = rpc("tools/call", {"name": "calculate_price", "arguments": {"unit_price": 85, "qty": 50}}, 2)
print("calculate_price:", calc["result"]["content"][0]["text"])
search = rpc("tools/call", {"name": "search_products", "arguments": {"keyword": "6204"}}, 3)
print("search_products:", search["result"]["content"][0]["text"])
