## Troubleshooting Expenses

Run in this order:
1. Check: ~/.config/omarchy/plugins/io.github.wardad52.expenses/bin/ezb-status status
   - HTTP 200 = server fine -> hard-refresh browser (Ctrl+Shift+R) or reopen http://localhost:9400
   - Anything else (e.g. 000) = container issue -> step 2
2. Restart: .../ezb-status restart — wait ~10s, re-run status
3. Recreate (last resort, data safe on volume): .../ezb-status recreate — wait ~15s
4. Still broken? Send output of status incl. log lines.
#auto-import to ez via docker

~/.config/systemd/user/warren-expenses-import.timer — checks for new receipts every minute (currently active and waiting)
- ~/.config/systemd/user/warren-expenses-import.service — runs the script (oneshot)
What it does
1. Watches assets/receipts/2026 Receipts in your Financal workspace (top level only), looking for new .jpg and .pdf files it hasn't already processed
2. PDFs get their first page rendered to JPG; JPGs get photo rotation fixed up
3. Reads the receipt with tesseract OCR, then pulls out:
- the date (first MM/DD/YY it finds, falls back to file date)
- the amount (biggest $x.xx near "total"/"balance", else biggest number)
- a store name guess
- a category guess (gas → Auto/Fuel, groceries/restaurant → Food & Drink, else Misc)
4. Uploads the image to ezBookkeeping and creates the transaction through its API, using a login token stored in ~/.local/share/warren.expenses/ez.conf
5. On success it moves the file into that month's folder (e.g. Oct Receipts); if anything looks off (no amount found, bad date) it flags it and pops a critical notification so you can review it in ezBookkeeping
One small correction to what you remembered: it doesn't send receipts to the internet — it talks to your local ezBookkeeping running in Docker at http://localhost:9400. 