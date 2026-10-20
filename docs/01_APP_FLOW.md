# Chit Notebook — App Flow (v1)

## 1. Navigation model

Single deep flow, no bottom tabs. Back = Android/iOS system back.

```
Home (chit list)
 └── Group detail
      ├── Round detail  ←── CORE LOOP (daily/weekly use)
      ├── Member ledger
      └── Edit chit (NewChitScreen in edit mode)
 └── New chit (NewChitScreen, create mode)
```

Dialogs/sheets (overlay, not destinations): late-interest prompt, unmark
confirm, recipient-change reason, payout confirm sheet, restore-confirm.

## 2. Flow A — create a chit (first run)

```
Home (empty state: "முதல் சீட்டை உருவாக்குங்க" + FAB)
  → NewChitScreen
      §1 Basic:      name, contribution ₹, period (வாரம்|மாதம்),
                     start date, due day ("ஒவ்வொரு மாதமும் 5-ஆம் தேதி")
      §2 Interest:   rate %, mode radio
                     [•] தாமத வட்டி (late-fee)   [ ] recipient-pays
      §3 Members:    rows (name + phone, contacts pick = FR-19),
                     drag handle = payout order  ← this IS the rotation
      §4 Review:     auto-generated round preview
                     ("ரவுண்டு 1 — 05 Nov — Kumar · ₹5,000")
      → [உருவாக்கு]  → rounds pre-generated → opens Group detail
```

Lock rule (FR-5): once any round has transactions, §1 amount/period and
§3 members/order become read-only (🔒 + reason shown).

## 3. Flow B — the core loop (every collection period)

```
Home card ("வசூல் நடக்குது 3/5", amber chip)
  → Group detail → "collection mark பண்ணு →"
  → Round detail
       ├─ tap member row → [செலுத்தினார்] toggle → paid (timestamped)
       │     └─ after due date? → prompt: "late-ஆ? ₹20 வட்டி சேரும்"
       │           → contribution row + separate interest row written
       ├─ tap again → unmark confirm → rows removed
       ├─ "Remind ➤" → pending list → wa.me deep link opens WhatsApp
       │     message: "Anna, 4-வது ரவுண்டு சீட்டுக்கு ₹1,000 இன்னும் pending…"
       └─ all paid (or organizer decides) → [Payout →]
              confirm sheet: recipient (fixed order, changeable w/ reason),
              pot amount, interest summary
              → [Confirm] → payout row + dividend rows (recipient_pays)
                → round status: paid_out → back to Group detail
```

**Partial rule:** payout allowed with unpaid members; unpaid amounts become
arrears (member badge + ledger), visible forever.

## 4. Round state machine

```
        mark all members paid
 open ───────────────────────▶ collected ──[Payout]──▶ paid_out
  ▲                               │
  └──────── unmark / unpay ◀──────┘        (terminal; rows stay audit-visible)
```

Round status never skips: `paid_out` is terminal. Corrections after payout are
new ledger rows (reversal notes), never deletions.

## 5. Flow C — member ledger & statement

```
Group detail → tap member row → Member ledger
   header: net position (big, +green / −red)
   chips:  contributed · taken · interest · arrears
   timeline: reverse-chron rows (வசூல் / payout / வட்டி / பங்க / அபராதம்)
   sticky actions: [PDF அனுப்பு ➤ WhatsApp]  [payment mark பண்ணு → jump to round]
```

## 6. Flow D — backup & restore

```
Home app-bar → backup icon
   green:  "கடைசி backup: 2 நாள் முன்"
   red dot if > 7 days → tap → export JSON → share sheet (Drive/WhatsApp/Files)
Settings → Restore → pick file → dialog:
   "இது முழு data-ஐயும் மாத்திடும். உறுதியா?" → importJson()
```

## 7. Interest behaviour (by mode)

| Mode | When | What is written |
|---|---|---|
| late_fee | member pays after due date | `interest` row by that member = contribution × rate% (note: "auto late interest (2%)"). Group fund in v1 — not redistributed |
| recipient_pays | payout | `interest` row by recipient = pot × rate%; `dividend` rows to each other member = interest ÷ (n−1). Closed loop — group net zero |

Interest is **never** folded into the pot amount; always its own row.

## 8. Edge cases & guards

| Case | Behaviour |
|---|---|
| Mark late after due date | Auto prompt; interest row with is_late=1 |
| Unmark a paid member | Confirm dialog; deletes contribution + auto-interest rows; round reverts collected→open |
| Change recipient | Mandatory reason → zero-amount audit row (`type=penalty`, amount=0, note) |
| Change accountable | Free (one tap), no audit needed |
| Payout with pending members | Allowed; pending → arrears badge |
| Delete chit | Blocked if any transaction exists → suggest archive |
| Edit after start | Only name / rate / due day / status (FR-5) |
| Restore backup | Replace-all inside one DB transaction; abort on parse error |
