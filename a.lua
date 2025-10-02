import express from "express";
import jwt from "jsonwebtoken";
import { usersDB, producDB, siscomDB } from "../utils/db.js";
import { verificarToken } from "../middleware/middleware.js";

const router = express.Router();
const JWT_SECRET = "clave_dev_local";

// LOGIN
router.post("/login", (req, res) => {
  const { user, clave } = req.body;
  const query = `SELECT * FROM users WHERE GMAIL = '${user}' AND CLAVE = '${clave}'`;

  usersDB.all(query, (err, rows) => {
    if (err) return res.status(500).json({ error: "Error en DB (users)" });
    if (!rows?.length) return res.status(401).json({ error: "Credenciales inválidas" });

    const userData = rows[0];
    const token = jwt.sign({ id: userData.ID, user: userData.user }, JWT_SECRET, { expiresIn: "1h" });

    res.json({ ok: true, msg: "Login correcto", token });
  });
});
// ============================
// MOSTRAR TODOS LOS YAPES
// ============================
router.get("/mos", (req, res) => {
  const query = "SELECT * FROM SISCOMPRAS ORDER BY FH DESC";

  siscomDB.all(query, (err, rows) => {
    if (err) {
      console.error("❌ Error en DB (SISCOMPRAS):", err);
      return res.status(500).json({ error: "Error al leer la DB" });
    }

    res.json({
      ok: true,
      total: rows.length,
      yapes: rows
    });
  });
});

// PERFIL
router.get("/perfil", verificarToken, (req, res) => {
  const userId = req.user.id;
  usersDB.all("SELECT * FROM users WHERE ID = ?", [userId], (err, rows) => {
    if (err) return res.status(500).json({ error: "Error en DB (users)" });
    if (!rows?.length) return res.status(404).json({ error: "Usuario no encontrado" });

    const userData = rows[0];
    producDB.all("SELECT * FROM produc WHERE ID = ?", [userId], (err2, producRows) => {
      if (err2) return res.status(500).json({ error: "Error en DB (produc)" });

      // 3. Obtener yapes del usuario (siempre actualizados)
      siscomDB.all("SELECT * FROM SISCOMPRAS WHERE ID = ?", [userId], (err3, yapesRows) => {
        if (err3) return res.status(500).json({ error: "Error en DB (yapes)" });

        // ✅ Respuesta final en tiempo real
        res.json({
          ok: true,
          user: userData,
          produc: producRows,
          yapes: yapesRows
        });
      });
    });
  });
});

// LOGOUT
router.post("/logout", (req, res) => {
  res.json({ ok: true, msg: "Sesión cerrada, borra el token en cliente" });
});

export default router;
