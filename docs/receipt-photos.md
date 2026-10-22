## Receipt photo tips (for clean OCR)

Rotation gotcha: phone gallery rotation may only set EXIF orient flag — tesseract reads raw pixels. Fix with: mogrify -auto-orient file.JPG

1. Top-down, fill frame — flat on dark table, all 4 corners visible, no fingers
2. Even light, no flash/glare
3. Hold steady / tap to focus, wipe lens
4. Shoot portrait, text upright
5. One receipt per photo, lay curled receipts flat

## Category leaf mapping (expenses-auto-import)
Food & Drink->Groceries, Clothing & Apparel->Clothing, Housing->Houseware, Transportation->Personal Car Expense, Auto/Fuel->Fuel, Coms->Telephone Bill, Entertainment->Movies & Shows, Education->Training Courses, Gifts & Donate->Gifts, Medical->Diagnosis & Treatment, Finance->Insurance Expense, Misc->Other. (Vacation has no leaves, kept as-is.)
