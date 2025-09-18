import express from "express";
import session from "express-session";
import cors from "cors";
import duckdb from "duckdb";

const app = express();
app.use(express.json());

// ============================
// Configuración de CORS
// ============================
const todos = true; // si es true, todas las páginas pueden acceder
const paginas = ["https://skrifna.uk"];

app.use(
  cors({
    origin: (origin, callback) => {
      if (todos || !origin || paginas.includes(origin)) {
        callback(null, true);
      } else {
        callback(new Error("No permitido por CORS"));
      }
    },
    credentials: true,
  })
);

// ============================
// Sesiones en memoria
// ============================
app.use(
  session({
    secret: "supersecreto",
    resave: false,
    saveUninitialized: true,
  })
);

// ============================
// Conexión a DB
// ============================
const usersDB = new duckdb.Database("./db/users.duckdb");

// ============================
// LOGIN
// ============================
app.post("/login", (req, res) => {
  const { user, clave } = req.body;
  console.log("📩 Datos recibidos (login):", req.body);

  try {
    const query = `SELECT * FROM users WHERE USER = '${user}' AND CLAVE = '${clave}'`;

    usersDB.all(query, (err, rows) => {
      if (err) {
        console.error("❌ Error en DB:", err);
        return res.status(500).json({ error: "Error en DB" });
      }

      if (!rows || rows.length === 0) {
        console.log("⚠️ Login fallido -> Usuario o clave inválidos");
        return res.status(401).json({ error: "Credenciales inválidas" });
      }

      const userData = rows[0]; // contiene USER, CLAVE, VCM, etc.

      console.log("✅ Login correcto -> Datos completos:", userData);

      // Guardar en sesión
      req.session.user = userData;

      // Enviar todos los datos
      res.json({
        ok: true,
        msg: "Login correcto",
        user: userData,
      });
    });
  } catch (e) {
    console.error("❌ Error inesperado:", e);
    res.status(500).json({ error: "Error inesperado" });
  }
});

// ============================
// Servidor
// ============================
const PORT = 25502;
app.listen(PORT, () => {
  console.log(`🚀 Servidor corriendo en http://localhost:${PORT}`);
});
