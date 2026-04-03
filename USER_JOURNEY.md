# FFill - User Journey

## First-Time Setup

1. **Install FFill** — download and open the macOS app.
2. **Enable the Safari extension** — the app's Settings page guides you to Safari > Settings > Extensions, where you toggle on "FFill".
3. **Add your data** — in the app, go to "Form Data" and add key-value pairs:
   - Key: `First Name` → Value: `John`
   - Key: `Last Name` → Value: `Doe`
   - Key: `Email` → Value: `john.doe@example.com`
   - Key: `Phone` → Value: `+1 555 123 4567`
4. **Organize into folders** (optional) — go to "Folders", create folders like "Personal" and "Work", then assign items to them.

---

## Daily Usage: Filling a Form

1. **Open a webpage** with a form in Safari (e.g., a job application).
2. **Right-click** on any input field (text input, textarea, etc.).
3. **Hover over "FFill"** in the context menu.
4. **See your saved data** organized as:
   - Top-level items (not in any folder): `First Name`, `Last Name`, `Email`, `Phone`
   - Folders as submenus: `Personal >`, `Work >` — each containing their assigned items
5. **Click the item** you want to fill (e.g., "First Name").
6. **The field is instantly filled** with the stored value ("John").
7. **Repeat** for each field on the form.

---

## Managing Data

### Adding a New Item
1. Open FFill app → "Form Data" tab.
2. Click the **+** button in the toolbar.
3. Enter a **Key** (label shown in the context menu) and **Value** (what gets filled).
4. Optionally assign it to a **Folder**.
5. Click **Save**.

### Editing an Item
1. Click the **edit** icon on any item row, or double-click it.
2. Modify the key, value, or folder assignment.
3. Click **Save**.

### Deleting an Item
1. Swipe left on an item, or select it and press Delete.
2. Confirm deletion.

### Reordering Items
1. Drag and drop items in the list to reorder them.
2. The new order is immediately reflected in the Safari context menu.

---

## Managing Folders

### Creating a Folder
1. Open FFill app → "Folders" tab.
2. Enter a folder name in the text field at the top.
3. Click **Add Folder**.

### Editing a Folder
1. Click the **edit** icon on a folder row.
2. Change the name.
3. Click **Save**.

### Deleting a Folder
1. Click the **delete** icon on a folder row.
2. Items inside the folder are **not deleted** — they become top-level items.

### Viewing Folder Contents
1. Click on a folder to see all items assigned to it.
2. Drag items to reorder within the folder.

---

## Import & Export

### Exporting Data
1. Open FFill app → "Settings" tab.
2. Click **Export**.
3. Choose a save location — data is exported as a `.json` file.

### Importing Data
1. Open FFill app → "Settings" tab.
2. Click **Import**.
3. Select a previously exported `.json` file.
4. Data is merged into your existing items and folders.

---

## Example: Filling a Job Application

**Scenario**: You're applying to a job on a company's careers page.

| Form Field | Right-click → FFill → | Fills With |
|---|---|---|
| First Name | `First Name` | John |
| Last Name | `Last Name` | Doe |
| Email | `Work > Work Email` | john.doe@company.com |
| Phone | `Phone` | +1 555 123 4567 |
| LinkedIn | `Work > LinkedIn URL` | linkedin.com/in/johndoe |
| Address | `Personal > Address` | 123 Main St, City, ST 12345 |

Total time: ~10 seconds instead of 2+ minutes of manual typing.
