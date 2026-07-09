# Daily Matrix Planner & Analytics

A premium, multi-day task manager based on the Eisenhower Matrix (urgent vs. important triage) combined with a productivity analytics dashboard. It runs locally on your machine and saves all your data directly inside a `data.json` file in the project folder.

---

## 📂 File Structure

* `daily-matrix-planner-standalone (1).html` — The main client interface (HTML, CSS, JS).
* `server.js` — The lightweight, zero-dependency Node.js backend.
* `data.json` — The database file where all your tasks, logs, and settings are stored (automatically generated on first run).

---

## ⚙️ Prerequisites

To run this application, you must have **Node.js** installed on your computer.

1. Check if you already have it by opening your terminal (Command Prompt/PowerShell) and typing:
   ```bash
   node -v
   ```
2. If it is not installed, download the **LTS (Recommended)** installer from [nodejs.org](https://nodejs.org/) and follow the installation instructions.

---

## 🚀 How to Run the Application

Follow these steps to launch the app:

### 1. Open Terminal in the Project Folder
* **On Windows**: Open the folder in File Explorer, click on the address bar at the top, type `cmd` and press **Enter**.
* Alternatively, open PowerShell/Command Prompt and navigate to the directory:
  ```powershell
  cd "F:\Mayvel\PI_Venkatesh\Daily task tracker site"
  ```

### 2. Start the Backend Server
Run the following command to start the server:
```bash
node server.js
```

You should see the confirmation message:
```txt
=======================================================
 Daily Matrix Planner server started successfully!
 Open your browser and navigate to:
   http://localhost:3000
=======================================================
 Data is saved to: [Your-Folder-Path]\data.json
```

### 3. Open in Your Browser
Open your web browser (Chrome, Edge, Firefox, Safari) and navigate to:
👉 **[http://localhost:3000](http://localhost:3000)**

---

## 🛠️ Key Features

* **Local JSON Persistence**: Keeps your tasks saved directly in your folder structure inside `data.json`.
* **Resilient Offline Fallback**: If the server is offline or you double-click the HTML file directly, it will gracefully run in **Local Browser Mode** using `localStorage`.
* **Sidebar Navigation**: Includes collapsible sidebar menu with state persistence (collapses using `<` and expands via `☰`).
* **Productivity Dashboard**: Analytics featuring streaks, circular completion rings, quadrant weight distribution, recent carry-over audits, and weekly CSS velocity charts.
* **Inline Calendar Navigator**: Select dates from a monthly calendar grid to view or retroactively update historical days.
* **Backup Management**: Export and Import JSON data files manually directly from the sidebar.

---

## 🛑 How to Stop the Application
To shut down the application server, select the terminal window running `server.js` and press:
`Ctrl + C` (on Windows/Linux) or `Cmd + .` (on macOS).
