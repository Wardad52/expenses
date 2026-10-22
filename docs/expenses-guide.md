# Expenses — Simplified Guide (EZBookkeeping)

EZBookkeeping ("Expenses") is a lightweight, self-hosted personal finance app for recording daily spending and income.

You access it in a web browser (in your setup: `http://localhost:9400`). Log in with your user account to start.

## 0. What Had to Happen Before "Register and Log In"

"Register user and log in" happens on the **first-run web page**, but only after this local setup:

1. **Docker installed on your machine** (Expenses runs as a container, not a normal installed app).
2. **Image downloaded:** `mayswind/ezbookkeeping:latest` pulled from Docker Hub.
3. **Container created and started** named `ezbookkeeping`, roughly:
   ```
   docker run -d --name ezbookkeeping -p 9400:8080 \
     -v ~/.local/share/ezbookkeeping/data:/ezbookkeeping/data \
     -v ~/.local/share/ezbookkeeping/storage:/ezbookkeeping/storage \
     -e EBK_SERVER_ROOT_URL=http://localhost:9400/ \
     mayswind/ezbookkeeping:latest
   ```
   - `9400:8080` = app listens on 8080 inside container, exposed as 9400 on your PC.
   - The two `-v` folders persist your database (`ezbookkeeping.db`) and receipt photos/icons, so data survives restarts.
   - Current state verified: container `ezbookkeeping` is running, port `0.0.0.0:9400->8080/tcp`.
4. **Open browser to `http://localhost:9400/`** (requires JavaScript enabled).
5. **Only then:** since no users exist yet, the app shows the **Registration page**. You create the first user (username + password + choose whether to auto-create default categories). After that, you log in with that user.

In short: Install Docker > start container > open localhost:9400 > register first user > log in.

## 1. How It Works — The Big Idea

Everything is built on 3 pieces:

1. **Accounts = Where your money lives**
   - Example: Cash, Checking, Savings, Credit Card, Debt Account
   - Cash / Checking / Savings = assets (money you own)
   - Credit Card / Debt = liabilities (money you owe, shown as positive owed balance)
   - Tip: map each account to a real-world account (e.g. "Chase Checking ...1234")

2. **Categories = What the money was for**
   - Two levels: Primary > Secondary
   - Example: `Food > Groceries`, `Food > Eating Out`, `Transport > Fuel`
   - Three types: Expense, Income, Transfer
   - You *must* pick a secondary category for every transaction

3. **Transactions = What actually happened**
   - Expense: money out (e.g. Groceries $54 from Checking)
   - Income: money in (e.g. Salary to Checking)
   - Transfer: money moved between your own accounts (e.g. Checking -> Savings, or pay credit card bill)

Optional extras per transaction: date/time, tags, notes, location/map, photos/receipt images.

Tags are useful for merchant / person / project: e.g. tags `Tesco`, `John`, `Holiday-2026`. Tags can be grouped (e.g. group "People", group "Projects").

## 2. First-Time Setup (do once)

1. Register user and log in.
2. **Create Accounts:** Accounts page > Add
   - Set: category (Cash/Checking/Credit Card...), name, currency, initial balance + date of that balance
   - Note: you can only set initial balance at creation. Later fixes = add an Expense/Income transaction.
3. **Create Categories:** Transaction Categories page
   - Create Primary first (e.g. Food), then Secondary under it (e.g. Groceries, Eating Out)
   - Or accept default categories at registration.
4. **Create Tags (optional):** Tags page > Add groups like Stores, People, Projects.

Done — you can now record.

## 3. Day-to-Day Use

### Add an expense (30 seconds)
1. Click **Add / +**
2. Type: **Expense**
3. Amount, Account (e.g. Checking), Category (e.g. Food > Groceries), Date (defaults to now)
4. Optional: tags, note ("weekly shop"), photo of receipt
5. Save

### Add income
Same as above, Type: **Income**, Category e.g. `Salary > Monthly Pay`.

### Pay credit card / move money
Type: **Transfer**, From: Checking To: Credit Card, Amount, Category e.g. `Loan & Debt > Repayment`.

### Lend money to someone
Create a `Receivables` account for that person, then Transfer from Checking -> that Receivables account with category `Loan & Debt > Lending`.

### Find something
Transaction Details page:
- List view (timeline) or Calendar view
- Filter by date range, account, category, tag, amount, keyword, with/without pictures

### Check balance / reconcile
Accounts page > select account > **Reconciliation Statement**:
- Pick date range, see balance after each transaction + trend chart
- If balance is off: use **Update Closing Balance** — it calculates the difference and creates the correcting transaction for you.

### Recurring bills
Create a **Scheduled Transaction** (e.g. Rent on 1st, Salary monthly) — it auto-creates on schedule.

## 4. Analysis
- Built-in charts: spending by category, trends over time, cash flow (in vs out)
- Insights Explorer: custom queries — group by month, category, account, tag, day-of-week, etc.

## 5. Simple Daily Habits

- Record at point of sale (phone browser) — amount + account + category is enough, add photo/note later if needed.
- Once a week: 5-min review — Transaction list for the week, fix wrong categories.
- Month-end: check Accounts balances vs real bank, reconcile, look at category chart.

## 6. Quick Rules to Avoid Errors

- Every transaction needs an Account + Secondary Category.
- You can't backdate before an account's initial-balance date.
- Don't edit initial balance later — add a correcting Expense/Income.
- Use Transfers (not Expense+Income) when moving your own money, otherwise reports double-count.
- Archive unused accounts instead of deleting, to keep history.

---
*Based on EZBookkeeping (mayswind/ezbookkeeping). Local instance runs in Docker as `ezbookkeeping` on port 9400.*
# auto import function

A launcher script — ~/.config/omarchy/plugins/io.github.wardad52.expenses/bin/expenses-import-now
It runs your existing auto-import script, then pops a desktop notification telling you what happened:
- "3 receipt(s) imported" (or "No new receipts found" if nothing's waiting)
- If anything failed or needs your review, the existing critical notification still shows, and you get a summary
It also has a guard so if you press the key exactly when the every-minute timer is already running, it just says "already running" instead of doing the work twice.
The keybinding — added to ~/.config/hypr/bindings.lua:
SUPER + SHIFT + I  →  Import receipts now
Hyprland reloaded cleanly with no config errors, and I ran the script once to confirm it works (nothing was waiting in the folder, so it correctly would have told you that).
What's unchanged

So now you have both: it grabs receipts automatically every minute, and SUPER+SHIFT+I gives you instant control with a notification confirming what happened.

## Duplicate receipt names (added 2026-10-22)

If a queued receipt has the same filename as one already filed in a month folder (e.g. re-saving `Freds1020.pdf` while `Oct Receipts/Freds1020.pdf` exists), the import **skips it and pops a desktop notification once now, then re-nags every 5 minutes** while the duplicate sits in the queue. The toast is persistent (critical urgency — it never auto-expires): **left-click opens `2026 Receipts` in Omafile** so you can see the folder the copy clashes with; **right-click dismisses** it (it re-appears at the next 5-minute nag). Current list lives in `~/.local/share/warren.expenses/dupes.log` (`name|folder`), history in `auto-import.log` (`DUPLICATE-NAME nag:`). Both copies are kept — review them and delete/merge in ezBookkeeping; the queued copy blocks nothing but itself.