
# 🔐 Random String Generator (Bash)

A lightweight Bash utility for generating random strings interactively or via command-line arguments. Useful for passwords, API keys, tokens, or any quick random data.

---

## ✨ Features

* Interactive **manual mode** (default)

  * Choose character sets
  * Regenerate strings endlessly with Enter
* **Automatic mode** via CLI arguments
* Supports:

  * Letters (`a–zA–Z`)
  * Numbers (`0–9`)
  * Special characters
  * Full mixed set

---

## 📦 Usage

### **Manual Mode (no arguments)**

```bash
./random.sh
```

You will be prompted for:

* Desired string length
* Character type:

  1. Letters
  2. Numbers
  3. Special characters
  4. Full mix

Press **Enter** to generate new strings continuously.

---

## ⚡ Automatic Mode

```bash
./random.sh <length> <type>
```

### **Arguments**

| Argument   | Description                         |
| ---------- | ----------------------------------- |
| `<length>` | Length of the random string         |
| `<type>`   | Character set selection (see below) |

### **Types**

| Type | Charset                                         |           |
| ---- | ----------------------------------------------- | --------- |
| `1`  | Letters (`a-zA-Z`)                              |           |
| `2`  | Numbers (`0-9`)                                 |           |
| `3`  | Special characters (`@#$%^&*()_+[]{}            | ;:,.<>?`) |
| `4`  | Full mix of letters, numbers, and special chars |           |

### Example

```bash
./random.sh 32 4
```

Generates a 32-character string using the full mixed charset.

---

## 🛠 Requirements

* GNU `tr`
* `/dev/urandom` (standard on Linux/Unix systems)
