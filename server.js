const express = require("express");
const fs = require("fs");
const path = require("path");
const app = express();
const port = process.env.PORT || 3000;

app.use(express.json());

// Whitelist de IDs permitidos
const whitelist = [3926198989, 1542363203, 8723750727];

// Ruta del archivo de script
const scriptPath = path.join(__dirname, "hitbox_script.lua");

// Middleware para habilitar CORS
app.use((req, res, next) => {
    res.header('Access-Control-Allow-Origin', '*');
    res.header('Access-Control-Allow-Headers', 'Origin, X-Requested-With, Content-Type, Accept');
    next();
});

// Ruta de autenticación
app.post("/api/auth", (req, res) => {
    try {
        const { userId } = req.body;
        
        if (!userId) {
            return res.status(400).json({
                success: false,
                message: "Se requiere el ID de usuario"
            });
        }

        const userIdNumber = Number(userId);
        const isAllowed = whitelist.includes(userIdNumber);

        // Leer el script del archivo
        let scriptContent;
        try {
            scriptContent = fs.readFileSync(scriptPath, "utf8");
        } catch (err) {
            console.error("Error al leer el archivo de script:", err);
            return res.status(500).json({
                success: false,
                message: "Error interno del servidor al leer el script"
            });
        }

        if (isAllowed) {
            // Usuario autorizado
            res.json({
                success: true,
                message: "Acceso concedido",
                script: scriptContent
            });
        } else {
            // Usuario no autorizado
            res.status(403).json({
                success: false,
                message: "Acceso denegado. No estás autorizado para usar este script."
            });
        }
    } catch (error) {
        console.error("Error en /api/auth:", error);
        res.status(500).json({
            success: false,
            message: "Error interno del servidor"
        });
    }
});

// Ruta raíz
app.get("/", (req, res) => {
    res.json({
        status: "Servidor funcionando",
        timestamp: new Date().toISOString()
    });
});

// Iniciar el servidor
app.listen(port, () => {
    console.log(`Servidor corriendo en http://localhost:${port}`);
    console.log("Endpoints disponibles:");
    console.log(`- POST http://localhost:${port}/api/auth`);
    console.log(`- GET  http://localhost:${port}/`);
});
