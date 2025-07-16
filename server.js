const express = require("express");
const fs = require("fs");
const path = require("path");
const app = express();
const port = process.env.PORT || 3000;

app.use(express.json());

// Whitelist de IDs permitidos
const whitelist = [3926198989, 1542363203, 8723750727];

// Ruta del archivo de registro
const logFilePath = path.join(__dirname, "access_log.txt");
// Ruta del archivo de script
const scriptPath = path.join(__dirname, "hitbox_script.lua");

// Función para leer el script
function readScriptFile() {
  try {
    return fs.readFileSync(scriptPath, "utf8");
  } catch (err) {
    console.error("Error al leer el archivo de script:", err);
    return null;
  }
}

// Función para registrar acceso
function logAccess(userId, isAllowed) {
  const timestamp = new Date().toISOString();
  const logEntry = `[${timestamp}] User ID: ${userId} - Acceso ${
    isAllowed ? "PERMITIDO" : "DENEGADO"
  }\n`;

  // Usamos writeFileSync con la bandera 'a' para append
  try {
    fs.writeFileSync(logFilePath, logEntry, { flag: 'a' });
  } catch (err) {
    console.error("Error al escribir en el archivo de registro:", err);
  }
}

app.post("/api/auth", (req, res) => {
  const { userId } = req.body;
  const userIdNumber = Number(userId);
  const isAllowed = whitelist.includes(userIdNumber);

  // Registrar el intento de acceso
  logAccess(userId, isAllowed);

  if (isAllowed) {
    // Leer el script del archivo
    const scriptContent = readScriptFile();
    if (!scriptContent) {
      return res.status(500).json({
        success: false,
        message: "falloo",
      });
    }

    // Si el usuario está en la whitelist, envía el script
    res.json({
      success: true,
      script: scriptContent,
    });
  } else {
    // Si NO está en la whitelist, responde con un mensaje de denegado
    res.json({
      success: false,
      script:
        'game:GetService("Players").LocalPlayer:Kick("Acceso denegado, no estás autorizado para usar este script.")',
    });
  }
});

app.get("/", (req, res) => {
  res.send("Servidor funcionando");
});

app.listen(port, () => {
  // Crear el archivo de registro si no existe
  if (!fs.existsSync(logFilePath)) {
    fs.writeFileSync(logFilePath, "");
  }
  console.log(`Servidor corriendo en puerto ${port}`);
});
